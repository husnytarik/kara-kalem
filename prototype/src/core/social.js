// Toplum katmanı (GDD 24): ün, bağlar, Kara Defter, Güç Puanı, Ahit, büyük kurumlar.
// DOM'a dokunmaz; durum düz JSON'dur. Aylık/günlük kancalar sim.js'ten çağrılır.
import { clamp, sigmoid, dateOf, DAY, log, addMod, opinion, spend, rnd, addStress, staff } from './util.js';
import { stressFor, blocked } from './traits.js';

export const BASAMAK = [
  { ad: 'Esnaf', gp: 0 }, { ad: 'Ağa', gp: 15 }, { ad: 'Reis', gp: 35 },
  { ad: 'Baba', gp: 60 }, { ad: 'Kıyı Başı', gp: 85 }, { ad: 'Sendika Başkanı', gp: 110 },
];
export const CEVRE = { halk: 'Semt halkı', yeralti: 'Yeraltı', polis: 'Polis ve adliye' };
export const NEDEN = ['Borç', 'Hakaret', 'İhanet', 'İhbar', 'Kan'];
export const S0 = {
  HISSE_FIYAT: 600, LIMAN_KAR: 3600, HISSE_MAX: 40, KREDI_FAIZ: 0.015,
  KARACA_GP: 48, HARAC: 10,
};

export function newSocial() {
  return {
    un: {
      halk: { cephe: { T: 30, I: 10, K: 0 }, golge: { T: 5, I: 0, K: 0 }, S: 0.1 },
      yeralti: { cephe: { T: 10, I: 0, K: 0 }, golge: { T: 5, I: 0, K: 0 }, S: 0.9 },
      polis: { cephe: { T: 15, I: 5, K: 0 }, golge: { T: 0, I: 0, K: 0 }, S: 0 },
    },
    bonds: [],
    kara: { defter: [], seq: 1 },
    unvan: { basamak: 0, ay: 0, tanindi: false, ahit: null },
    kurum: {
      karaca: { asama: 0, redd: false, teklifAy: -99, baskiAy: -99 },
      liman: { hisse: 0 },
    },
    kredi: { principal: 0, installment: 0, missed: 0 },
    gelirAy: 3000, tedarikZamUntil: 0,
  };
}

// ---------- ün (T tanınırlık, I iyilik, K korku) ----------
export const sLeak = (s, c) => (c === 'polis' ? clamp(0.3 + s.dosya / 200, 0, 1) : s.un[c].S);

export function perceived(s, c) {
  const u = s.un[c], S = sLeak(s, c);
  const mix = (k) => u.cephe[k] * (1 - S) + u.golge[k] * S;
  return { T: mix('T'), I: mix('I'), K: mix('K'), S };
}

// Kamuya açık bir olay: doyan/yerleşen sayılar yavaş değişir (GDD 24.3).
export function fame(s, c, side, d, V = 1) {
  const sides = side === 'both' ? ['cephe', 'golge'] : [side];
  for (const sd of sides) {
    const u = s.un[c][sd];
    if (d.t) u.T = clamp(u.T + V * d.t * (d.t > 0 ? 1 - u.T / 100 : 1), 0, 100);
    if (d.i) u.I = clamp(u.I + V * d.i * (1 - Math.abs(u.I) / 120), -100, 100);
    if (d.k) u.K = clamp(u.K + V * d.k * (d.k > 0 ? 1 - u.K / 100 : 1), 0, 100);
  }
}
export function leak(s, c, v) { if (c !== 'polis') s.un[c].S = clamp(s.un[c].S + v, 0, 1); }

export function lakap(s) {
  const y = perceived(s, 'yeralti'), h = perceived(s, 'halk');
  if (y.T < 40) return '';
  if (y.K >= 40 && h.I <= -20) return 'Kasap';
  if (y.K >= 40) return 'Korkulan';
  if (h.I >= 30) return 'Hayırsever';
  if (h.I <= -30) return 'Kötü Ağızlı';
  return 'Şehir Adamı';
}

// ---------- güç puanı ve basamak ----------
export function gucPuani(s) {
  const adam = Object.values(s.chars).filter((c) => c.employed && !c.dead).length;
  const parts = [
    { k: `Aylık gelir ($${Math.round(s.gelirAy)})`, v: 6 * Math.log(1 + s.gelirAy / 1000) },
    { k: `Adamların (${adam})`, v: 0.5 * adam },
    { k: 'Semt (yarım semt)', v: 4 * 0.5 },
    { k: 'Yeraltında tanınırlık', v: 0.1 * perceived(s, 'yeralti').T },
  ];
  if (s.kurum.liman.hisse > 0) parts.push({ k: `Harbor Trust payı (%${s.kurum.liman.hisse})`, v: 0.1 * s.kurum.liman.hisse });
  return { gp: parts.reduce((a, p) => a + p.v, 0), parts };
}

// Sana karşı tutulan listeler (türetilmiş; durum tutmaz)
export function listeler(s) {
  return [
    { id: 'aranan', ad: 'Aranan listesi', on: s.dosya >= 50, etki: 'Rüşvet kabul ihtimali −1,0 (kabul eden azdır).', cikis: 'Dosyayı 50\'nin altına indir.' },
    { id: 'banka', ad: 'Banka kara listesi', on: s.debt.missed >= 2 || s.kredi.missed > 0, etki: 'Harbor Trust kredi vermez.', cikis: 'Geciken taksitleri kapat.' },
    { id: 'esnaf', ad: 'Esnaf birliği: güvenilmez', on: perceived(s, 'halk').I <= -25, etki: 'Tedarikçi fiyatı +%15 (mal gideri).', cikis: 'Semt halkındaki iyiliğini −25\'in üstüne çıkar (bağış, iyi iş).' },
  ];
}
export const listede = (s, id) => listeler(s).find((l) => l.id === id).on;

// ---------- bağlar ----------
export const bond = (s, id) => (s.bonds.find((b) => b.id === id) || {}).tur || null;
export const dostlar = (s) => s.bonds.filter((b) => b.tur === 'dost').map((b) => b.id);
export function addOrtak(s, id, n = 1) { const c = s.chars[id]; c.ortak = (c.ortak || 0) + n; }

function checkBonds(s) {
  for (const [id, c] of Object.entries(s.chars)) {
    if (c.dead) continue;
    const o = opinion(s, id).total;
    const b = bond(s, id);
    if (!b && (c.ortak || 0) >= 3 && o >= 40) {
      s.bonds.push({ id, tur: 'dost' });
      log(s, `${c.ad} artık senin dostun.`, 'good', `Görüşü ${o}, birlikte yaşadığınız olay sayısı ${c.ortak}. Dostluk iyilik borcunu ucuzlatır; kaybı ağır gelir.`);
    } else if (b === 'dost' && o < 10) {
      s.bonds = s.bonds.filter((x) => x.id !== id);
      log(s, `${c.ad} ile dostluğunuz soğudu.`, 'bad', `Görüşü ${o}'a düştü.`);
      addStress(s, 5, 'Bir dostluk bitti.');
    }
  }
}
export function loseDost(s, id, why) {
  if (bond(s, id) !== 'dost') return;
  s.bonds = s.bonds.filter((x) => x.id !== id);
  addStress(s, 10, `${s.chars[id].ad} gibi bir dostu ${why}.`);
}

// ---------- Kara Defter ----------
export function defterAc(s, hedef, neden, agirlik) {
  const c = s.chars[hedef];
  if (!c || c.dead) return { ok: false, msg: 'Geçersiz hedef.' };
  if (s.kara.defter.some((k) => k.hedef === hedef)) return { ok: false, msg: 'Bu kişi zaten defterde.' };
  agirlik = clamp(Math.round(agirlik), 1, 3);
  s.kara.defter.push({ id: s.kara.seq++, hedef, neden, agirlik, t0: s.t, kin: 10 * agirlik });
  fame(s, 'yeralti', 'golge', { k: 1.5 * agirlik }, 0.5);
  log(s, `Kara Defter'e yazıldı: ${c.ad} (${neden}, ağırlık ${agirlik}).`, 'warn', 'Kayıt açmak bedava; ama ekip "kin tutan adam" olduğunu öğrenir ve kayıt seni de yorar.');
  return { ok: true };
}

export function tazminatP(s, agirlik) {
  return sigmoid((perceived(s, 'yeralti').K - 20 - 12 * agirlik) / 10);
}

export function defterKapat(s, id, yol) {
  const k = s.kara.defter.find((x) => x.id === id);
  if (!k) return { ok: false, msg: 'Kayıt yok.' };
  const c = s.chars[k.hedef];
  const close = () => { s.kara.defter = s.kara.defter.filter((x) => x.id !== id); };
  if (yol === 'af') {
    if (blocked(s.patron, 'af')) return { ok: false, msg: 'Kindarsın; af senin işin değil.' };
    close();
    addMod(s, k.hedef, 'Onu affettin', 25, 2);
    fame(s, 'yeralti', 'golge', { k: -1.5 }, 1);
    const st = stressFor(s.patron, 'af');
    if (st.total < 0) addStress(s, st.total, '');
    log(s, `${c.ad} kaydını affettin.`, 'good', st.why.length ? `Özelliğin: ${st.why.join(', ')}.` : 'Görüşü +25, ama bir miktar korku kaybettin.');
    return { ok: true };
  }
  if (yol === 'tazminat') {
    const p = tazminatP(s, k.agirlik);
    if (rnd(s) < p) {
      const amt = 200 * k.agirlik;
      s.cash.dirty += amt; close();
      addMod(s, k.hedef, 'Tazminat ödedi', -5, 2);
      log(s, `${c.ad} tazminat ödedi: $${amt} kirli para. Kayıt kapandı.`, 'good', `Yeraltında korkunla kabul ihtimali %${Math.round(p * 100)} idi.`);
    } else {
      addMod(s, k.hedef, 'Ondan tazminat istedin', -10, 2);
      fame(s, 'yeralti', 'golge', { k: -2 }, 1);
      log(s, `${c.ad} tazminatı reddetti ve güldü.`, 'bad', `Kabul ihtimali %${Math.round(p * 100)} idi. Boş tehdit korkunu düşürdü.`);
      const st = stressFor(s.patron, 'talep'); if (st.total) addStress(s, st.total, st.why.join(', '));
    }
    return { ok: true };
  }
  if (yol === 'hesap') {
    if (!staff(s, 'koruma')) return { ok: false, msg: 'Hesaplaşmak için adamın (koruma) olmalı.' };
    if (!spend(s, 200, 'dirty')) return { ok: false, msg: 'Para yetmiyor ($200).' };
    close();
    addMod(s, k.hedef, 'Onunla hesaplaştın', -30, 1);
    fame(s, 'yeralti', 'golge', { k: 6 }, 1);
    fame(s, 'polis', 'golge', { t: 3 }, 1);
    const st = stressFor(s.patron, 'hesap'); if (st.total) addStress(s, st.total, st.why.join(', '));
    if (st.total < 0) s.patron.stres = clamp(s.patron.stres + st.total, 0, 100);
    if (k.hedef === 'kazim') { s.biz.rakip.rep = Math.max(5, s.biz.rakip.rep - 8); }
    if (k.hedef === 'sakir') { s.debt.principal += 400; log(s, 'Sal sert karşılık verdi: borcuna $400 işlendi.', 'bad'); }
    if (k.hedef === 'hacer') { fame(s, 'halk', 'golge', { i: -8 }, 1); leak(s, 'halk', 0.05); }
    log(s, `${c.ad} ile hesaplaştın. Kayıt kapandı.`, 'warn', 'Yeraltında Korku +6, polis seni bir kez daha duydu.');
    if (rnd(s) < 0.35) s.pendingEvidence.push({ v: 8, why: `Hesaplaşmayı gören biri karakolda ifade verdi (${c.ad}).` });
    return { ok: true };
  }
  return { ok: false, msg: 'Bilinmeyen yol.' };
}

function defterMonth(s) {
  const kindar = s.patron.traits.includes('Kindar');
  const ay = dateOf(s.t).month;
  let kinStres = 0;
  for (const k of [...s.kara.defter]) {
    if (!kindar) k.kin *= 0.991;
    if (k.kin >= 20) kinStres++;
    const yas = (s.t - k.t0) / (DAY * 120);
    if (k.agirlik >= 3 && yas > 1) { fame(s, 'yeralti', 'golge', { k: -1 }, 1); }
    if (k.agirlik === 1 && yas > 5 && !kindar) {
      s.kara.defter = s.kara.defter.filter((x) => x.id !== k.id);
      log(s, `${s.chars[k.hedef].ad} kaydı zamanaşımına uğradı.`, 'info');
    }
  }
  if (kinStres) addStress(s, Math.min(3, kinStres), 'Kara Defter\'deki kinler seni yoruyor.');
  void ay;
}

// ---------- Marchetti Ailesi ve Ahit ----------
export function tehdit(s) {
  const k = s.kurum.karaca;
  return (gucPuani(s).gp / S0.KARACA_GP) * (1 + perceived(s, 'yeralti').K / 100) * (k.redd ? 1.6 : 1);
}
export const asamaAd = ['Seni görmüyorlar', 'Seni fark ettiler', 'Seni tehdit sayıyorlar'];

export function memnuniyet(s) {
  const a = s.unvan.ahit;
  if (!a) return null;
  const o = opinion(s, 'orhan').total;
  const himaye = a.himaye ? 10 : 0;
  const lines = [
    { k: 'Taban', v: 50 },
    { k: 'Vincent\'in sana görüşü (×0,5)', v: Math.round(0.5 * o) },
    { k: `Haraç %${a.harac} (her %1 fazlası −1,5)`, v: Math.round(-1.5 * (a.harac - 10)) },
    { k: `Özerklik ${a.ozerklik}`, v: 10 * a.ozerklik },
    { k: 'Himaye gördün mü', v: himaye },
  ];
  return { v: lines.reduce((x, l) => x + l.v, 0), lines };
}

export function kabulAhit(s, harac, kaynak) {
  s.unvan.ahit = { ust: 'karaca', harac, ozerklik: 1, t0: s.t, geciken: 0, himaye: false };
  s.unvan.tanindi = true;
  addMod(s, 'orhan', 'Ahit verdin', 20, 2);
  log(s, `Marchetti Ailesi'ne Ahit verdin: aylık gelirinin %${harac}'ı haraç; karşılığında himaye.`, 'good', kaynak);
}

// ---------- Harbor Trust: hisse ve kredi ----------
export const hisseDegeri = (s) => s.kurum.liman.hisse * S0.HISSE_FIYAT;

export function krediInfo(s, amt) {
  const teminat = s.cash.clean + 3 * s.gelirAy + hisseDegeri(s);
  const sel = opinion(s, 'selahattin').total;
  const fx = [
    { k: `Teminat ($${Math.round(teminat)}) / istenen`, x: 1.2 * Math.log(1 + teminat / amt) },
    { k: 'Müdürün sana görüşü', x: sel / 40 },
    { k: 'Semt halkında iyiliğin', x: perceived(s, 'halk').I / 80 },
    { k: 'Yönetim kurulunda koltuğun', x: s.kurum.liman.hisse >= 25 ? 1 : 0 },
    { k: 'Banka kara listesi', x: listede(s, 'banka') ? -2 : 0 },
    { k: 'Riskin tabanı', x: -0.5 },
  ];
  return { p: sigmoid(fx.reduce((a, f) => a + f.x, 0)), factors: fx, installment: Math.ceil(amt / 6) };
}

// ---------- aylık / günlük kancalar ----------
export function socialDay(s) {
  checkBonds(s);
}

export function socialMonth(s, R, ctx) {
  const { legalRev, liqRev, legalCost, pushCard } = ctx;
  const ayNo = dateOf(s.t).month;

  // ün: meyhanenin başarısı mahalleye yayılır; bodrum yeraltında konuşulur; sönümler
  fame(s, 'halk', 'cephe', { t: 4 * (s.share / 0.36) }, 0.5);
  if (s.month.liqSold > 0) {
    const f = Math.min(1, s.month.liqSold / 300);
    fame(s, 'yeralti', 'golge', { t: 8 * f }, 0.5);
    fame(s, 'polis', 'golge', { t: 3 * f }, 0.5);
  }
  for (const u of Object.values(s.un)) for (const sd of [u.cephe, u.golge]) {
    sd.T = Math.max(0, sd.T - 0.3); sd.I *= 0.97; sd.K *= 0.95;
  }
  for (const u of [s.un.halk]) u.S = Math.max(0.05, u.S - 0.005); // kısmen unutulur

  defterMonth(s);

  // gelir (güç puanı için)
  s.gelirAy = legalRev + liqRev;

  // Ahit: haraç
  const a = s.unvan.ahit;
  if (a) {
    const due = Math.round(a.harac / 100 * s.gelirAy);
    if (due > 0 && spend(s, due, 'dirty')) {
      R.push(`AHİT  Marchetti Ailesi'ne haraç $${due} (%${a.harac})`);
      addMod(s, 'orhan', 'Haracını ödedin', 3, 2); a.geciken = 0;
    } else if (due > 0) {
      a.geciken++; addMod(s, 'orhan', 'Haracı geciktirdin', -15, 2);
      R.push(`AHİT  ! Haraç ödenemedi (${a.geciken})`);
      log(s, 'Marchetti\'ye haraç ödenemedi. Vincent bunu unutmaz.', 'bad');
    }
    a.himaye = opinion(s, 'orhan').total >= -10 && a.geciken === 0; // koruma yalnızca ilişki ve haraç düzgünse sürer
  }

  // Harbor Trust: temettü ve kredi
  const L = s.kurum.liman;
  if (L.hisse > 0) {
    const tem = Math.round(L.hisse / 100 * S0.LIMAN_KAR);
    s.cash.clean += tem;
    R.push(`LİMAN A.Ş.  %${L.hisse} payından temettü $${tem} (temiz)`);
  }
  const kr = s.kredi;
  if (kr.principal > 0) {
    kr.principal *= 1 + S0.KREDI_FAIZ;
    const pay = Math.min(kr.installment, kr.principal);
    if (s.cash.clean >= pay) {
      s.cash.clean -= pay; kr.principal -= pay; kr.missed = 0;
      R.push(`LİMAN KREDİSİ  taksit $${Math.round(pay)} · kalan $${Math.round(kr.principal)}`);
      if (kr.principal < 1) { kr.principal = 0; log(s, 'Harbor Trust kredisini kapattın.', 'good'); }
    } else {
      kr.missed++;
      R.push(`LİMAN KREDİSİ  ! Taksit ödenemedi (${kr.missed}/3)`);
      log(s, `Liman kredisi taksiti ödenemedi (${kr.missed}/3). Banka kara listesindesin.`, 'bad');
      addMod(s, 'selahattin', 'Taksitini ödemedin', -12, 2);
      if (kr.missed >= 3 && !s.over) s.over = { kind: 'borc', text: 'Harbor Trust kredi teminatını, meyhaneni haczetti. Üç taksit üst üste ödenmedi.' };
    }
  }

  // Güç puanı: basamak ilerlemesi
  const g = gucPuani(s);
  const u = s.unvan;
  const nxt = BASAMAK[u.basamak + 1];
  if (u.basamak === 0 && nxt) {
    if (g.gp >= nxt.gp) u.ay++; else u.ay = 0;
    if (u.ay >= 3 && perceived(s, 'halk').T >= 30 && !s.cards.some((c) => c.ev === 'terfi')) pushCard(s, 'terfi');
  }
  R.push(`GÜÇ  ${BASAMAK[u.basamak].ad} · Güç Puanı ${g.gp.toFixed(1)}${nxt ? ` / ${nxt.gp} (${nxt.ad}${u.basamak === 0 ? `, ${u.ay}/3 ay` : ''})` : ''}`);

  // Marchetti Ailesi seni fark ediyor mu?
  const K = s.kurum.karaca;
  if (!u.ahit) {
    const t = tehdit(s);
    const st = t < 0.3 ? 0 : t < 0.6 ? 1 : 2;
    if (st !== K.asama) log(s, `Marchetti Ailesi: ${asamaAd[st]}. (Tehdit ${t.toFixed(2)})`, st > K.asama ? 'warn' : 'info');
    K.asama = st;
    if (st === 1 && ayNo - K.teklifAy >= 3 && !s.cards.some((c) => c.ev === 'karaca_teklif')) { K.teklifAy = ayNo; pushCard(s, 'karaca_teklif'); }
    if (st === 2 && ayNo - K.baskiAy >= 2 && !s.cards.some((c) => c.ev === 'karaca_baski')) { K.baskiAy = ayNo; pushCard(s, 'karaca_baski', { flavor: Math.floor(rnd(s) * 3) }); }
  } else K.asama = 0;
  void legalCost;
}
