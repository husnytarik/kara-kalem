// Çatışma katmanı: ekip, düşman bölgede pusu, baskınlar, yaralanma. DOM'a dokunmaz; durum s.bolge altında düz JSON.
// bolge.js ile karşılıklı içe aktarır (yalnızca çağrı anında kullanılır).
import { clamp, DAY, log, spend, staff, addStress } from './util.js';
import { fame, perceived } from './social.js';
import { BOLGELER, PLACES, bolgeAt } from './world.js';
import { pusuCarpan } from './meslek.js';
import { aracPusu } from './arac.js';
import { etki, aileDeg, hakimOf, hakimAd, addInf, kudret, erisim, brnd, hakimDegisti, yaraliMi, FAK } from './bolge.js';

export const EKIP_MAX = 8;
export const EKIP_FIYAT = 100;      // işe alım ($ kirli)
export const EKIP_MAAS = 40;        // ayda adam başı ($ kirli)
export const BASKIN_MALIYET = 200;  // silah, araç, rüşvet ($ kirli)
export const MEKAN_BOLGE = PLACES.meyhane.bolge; // meyhane ve çamaşırhane burada
const NPC = ['marchetti', 'obrien', 'tammany'];
const kazanP = (P, E) => Math.pow(P, 1.5) / (Math.pow(P, 1.5) + Math.pow(E, 1.5));
const hata = (msg) => ({ ok: false, msg });

// ---------- ekip ----------
// Yanında yürüyen adamların savaş gücü: ekip + sen + yanındaki koruma + sokaktaki korkun.
export function ekipGuc(s) {
  let g = s.bolge.ekip + 0.5;
  if (s.patron.traits.includes('Gözüpek')) g += 0.5;
  if (staff(s, 'koruma')) g += 1;
  g += perceived(s, 'yeralti').K / 40;
  return g;
}
export function ekipDetay(s) {
  const l = [{ k: `Ekip (${s.bolge.ekip} adam)`, v: s.bolge.ekip }, { k: 'Sen', v: 0.5 }];
  if (s.patron.traits.includes('Gözüpek')) l.push({ k: 'Gözüpek', v: 0.5 });
  if (staff(s, 'koruma')) l.push({ k: 'Koruman yanında', v: 1 });
  l.push({ k: 'Yeraltı korkusu', v: +(perceived(s, 'yeralti').K / 40).toFixed(1) });
  return l;
}

export function ekipAl(s, a) {
  const st = s.bolge;
  if (yaraliMi(s)) return hata('Yaralısın; iyileşene kadar adam toplayamazsın.');
  if (+a.d > 0) {
    if (st.ekip >= EKIP_MAX) return hata(`Ekip en fazla ${EKIP_MAX} kişi olabilir.`);
    if (!spend(s, EKIP_FIYAT, 'dirty')) return hata(`Para yetmiyor ($${EKIP_FIYAT} kirli).`);
    st.ekip++;
    log(s, `Ekibe bir adam katıldı (${st.ekip}). Ayda $${EKIP_MAAS}.`, 'info', 'Ekip seninle yürür: düşman bölgede pusu ihtimalini ve çatışma kayıplarını belirler.');
  } else {
    if (st.ekip <= 0) return hata('Ekipte adam yok.');
    st.ekip--;
    log(s, `Ekipten bir adamı saldın (${st.ekip}).`, 'info');
  }
  return { ok: true };
}

// ---------- tehlike ----------
// Bu bölgede en baskın rakip aile ve baskısı (0-100). Hakimi olmayan bölgede, ancak rakip bariz güçlüyse tehlike vardır.
export function dusman(s, id) {
  const b = s.bolge.list[id], hk = hakimOf(s.bolge, id);
  if (hk === 'oyuncu') return { f: null, v: 0 };
  let f = null, top = 0;
  for (const k of NPC) if ((b.inf[k] || 0) > top) { top = b.inf[k]; f = k; }
  return { f, v: hk ? top : Math.max(0, top - 25) * 0.5 };
}

// Bu bölgede şu an bir saat dolaşırsan pusuya düşme ihtimali.
export function pusuP(s, id) {
  const st = s.bolge, b = st.list[id], { f, v } = dusman(s, id);
  if (!f || v < 10) return { p: 0, f };
  const ofke = 1 + st.ofke[f] / 30;
  const bende = 1 - Math.min(0.7, (b.inf.oyuncu || 0) / 100);
  const taninma = 0.3 + b.tan / 100;
  const koruma = 1 + 0.6 * (st.ekip + (staff(s, 'koruma') ? 1 : 0));
  const iliski = (1 - Math.min(0.4, b.sev / 250)) * (1 - Math.min(0.3, b.kor / 300)) * clamp(1 - st.aile[f].g / 200, 0.6, 1.5) * (1 - st.aile[f].k / 250);
  const ahit = f === 'marchetti' && s.unvan.ahit ? 0.1 : 1;
  return { p: clamp(0.014 * v * taninma * bende * ofke * ahit * iliski * pusuCarpan(s) * aracPusu(s) / koruma, 0, 0.6), f, v };
}

// ---------- yaralanma ----------
function yaralan(s, id, f, ekipVardi) {
  const st = s.bolge, ad = BOLGELER[id].ad;
  if (brnd(st) < (ekipVardi ? 0.05 : 0.2)) {
    s.over = { kind: 'olum', text: `${ad}'da ${hakimAd(f)} adamları seni vurdu. ${ekipVardi ? 'Adamların seni taşıyamadan' : 'Yanında kimse yokken'} kaldırımda son nefesini verdin. Bu şehirde tanınmak, yanında adam olmadan pahalıya mal olur.` };
    return 'oldu';
  }
  const gun = 4 + Math.floor(brnd(st) * 5);
  st.yarali = s.t + gun * DAY;
  s.walk = null; s.pos = { x: PLACES.ev.x, y: PLACES.ev.y };
  const ucret = Math.min(250, Math.max(0, s.cash.clean));
  s.cash.clean -= ucret;
  addStress(s, 20, 'Vuruldun.');
  log(s, `Vuruldun. ${ad}'dan zor çıktın; ${gun} gün yatakta kalacaksın (tedavi $${ucret}).`, 'bad', 'Yaralıyken yürüyemez, bölgede iş yapamazsın; meyhane de seni göremeyince %25 az kazanır.');
  return 'yarali';
}

// ---------- çarpışma ----------
function carpisma(s, id, f, n, carpan, tur, pushCard) {
  const st = s.bolge, bd = st.list[id], ad = BOLGELER[id].ad, fad = hakimAd(f);
  const ek = st.ekip, P = ekipGuc(s) * carpan, E = n + 0.5, w = kazanP(P, E);
  const detay = `Güçler: sen ${P.toFixed(1)}, onlar ${E.toFixed(1)} → kazanma ihtimali %${Math.round(w * 100)}.`;
  if (brnd(st) < w) {
    const kayip = Math.min(ek, Math.floor(n * 0.35 * (0.4 + brnd(st))));
    st.ekip -= kayip;
    const ganimet = Math.round(40 * n);
    s.cash.dirty += ganimet;
    st.ofke[f] = Math.min(60, st.ofke[f] + 12);
    addInf(bd, f, -4); addInf(bd, 'oyuncu', 3);
    bd.tan = clamp(bd.tan + 8, 0, 100); bd.kor = clamp(bd.kor + 3, 0, 100);
    aileDeg(st, f, -5, 4);
    fame(s, 'yeralti', 'cephe', { t: 3, k: 3 }, 1);
    log(s, `${ad}: ${fad}'ın ${n} adamını ${tur === 'pusu' ? 'pusuda' : ''} yendin${kayip ? `, ${kayip} adamını kaybettin` : ', kayıpsız'}. Üzerlerinden $${ganimet} çıktı.`, 'good', detay);
    return { win: true };
  }
  const kayip = Math.min(ek, Math.ceil(ek * (0.5 + brnd(st) * 0.4)));
  st.ekip -= kayip;
  st.ofke[f] = Math.min(60, st.ofke[f] + 8);
  addInf(bd, 'oyuncu', -3); bd.kor = clamp(bd.kor - 2, 0, 100);
  aileDeg(st, f, -2, -2);
  const soyulan = Math.round(Math.min(s.cash.dirty, 500) * 0.3); s.cash.dirty -= soyulan;
  fame(s, 'yeralti', 'cephe', { k: -2 }, 1);
  log(s, `${ad}: ${fad} adamları seni ezdi${kayip ? `, ${kayip} adamını kaybettin` : ''}${soyulan ? `, $${soyulan} soydular` : ''}.`, 'bad', detay);
  if (brnd(st) < 0.3 + (ek === 0 ? 0.35 : 0)) {
    const r = yaralan(s, id, f, ek > 0);
    bildirim(s, pushCard, r === 'oldu' ? 'Son' : 'Vuruldun', r === 'oldu' ? s.over.text : `${ad}'da ${fad} adamları seni vurdu. ${detay}`);
  }
  return { win: false };
}

function bildirim(s, pushCard, title, text) { if (pushCard) pushCard(s, 'bildirim', { title, text }); }

// ---------- pusu (kart seçimi) ----------
export const pusuBedel = (n) => 100 + 60 * n;
export function pusuKur(s, pushCard) {
  const st = s.bolge, id = bolgeAt(s.pos), { f, v } = pusuP(s, id);
  const n = clamp(Math.round(1 + v / 35 + brnd(st) * 2), 1, 6);
  pushCard(s, 'pusu', { b: id, f, n });
}
export function pusuCoz(s, card, sec, pushCard) {
  const { b: id, f, n } = card.data, st = s.bolge, bd = st.list[id], ad = BOLGELER[id].ad, fad = hakimAd(f);
  let carpan = 1;
  if (sec === 2) {
    spend(s, pusuBedel(n), 'dirty');
    if (brnd(st) < 0.75 - bd.tan / 400) {
      fame(s, 'yeralti', 'cephe', { k: -2 }, 1);
      log(s, `${ad}: ${fad} adamlarına para sayıp geçtin ($${pusuBedel(n)}).`, 'warn', 'Seni tanımalarına rağmen parayı aldılar; ama bu sana korkak dedirtir.');
      return;
    }
    log(s, `${fad} adamları parayı aldı ve yine de üzerine geldi.`, 'bad');
    carpan = 0.8;
  } else if (sec === 1) {
    if (brnd(st) < clamp(0.55 + 0.06 * st.ekip - bd.tan / 400, 0.2, 0.9)) {
      s.walk = null; s.pos = { x: PLACES.ev.x, y: PLACES.ev.y };
      fame(s, 'yeralti', 'cephe', { k: -2 }, 1);
      log(s, `${ad}'dan kaçıp eve döndün.`, 'warn', 'Düşman bölgede kimse seni korumuyor; ekibin ya da nüfuzun büyüyene kadar o sokaklara girme.');
      return;
    }
    log(s, `Kaçamadın: ${fad} adamları yetişti.`, 'bad');
    carpan = 0.7;
  }
  carpisma(s, id, f, n, carpan, 'pusu', pushCard);
}

// ---------- baskın (sen) ----------
export function baskinTahmin(s, id) {
  const st = s.bolge, b = st.list[id], hk = hakimOf(st, id);
  if (!hk || hk === 'oyuncu') return null;
  const D = 2 + (b.inf[hk] || 0) / 15 + b.servet * 0.6 + (st.ofke[hk] > 20 ? 1 : 0);
  const P = ekipGuc(s) + (b.inf.oyuncu || 0) / 25;
  return { P, D, w: kazanP(P * 1.15, D), hk };
}

export function bolgeBaskin(s, a, pushCard) {
  const st = s.bolge, b = st.list[a.b];
  if (!b) return hata('Böyle bir bölge yok.');
  if (yaraliMi(s)) return hata('Yaralısın.');
  const tah = baskinTahmin(s, a.b);
  if (!tah) return hata(hakimOf(st, a.b) === 'oyuncu' ? 'Kendi bölgene baskın yapılmaz.' : 'Sahipsiz bölgede basılacak kimse yok: nüfuz kazan.');
  if (!erisim(s, a.b)) return hata(`${BOLGELER[a.b].ad}'a girmek için önce komşu bir bölgeye hakim olmalısın.`);
  if (st.ekip < 2) return hata('Baskın için en az 2 adam lazım.');
  const gun = Math.floor(s.t / DAY);
  if ((b.sonIs.baskin ?? -99) + 4 > gun) return hata('Aynı bölgeye 4 günde bir baskın yapılabilir.');
  if (!spend(s, BASKIN_MALIYET, 'dirty')) return hata(`Para yetmiyor ($${BASKIN_MALIYET} kirli).`);
  b.sonIs.baskin = gun;
  const ad = BOLGELER[a.b].ad, hk = tah.hk, fad = hakimAd(hk), onceki = hk, ek = st.ekip;
  const detay = `Güçler: sen ${(tah.P * 1.15).toFixed(1)} (baskın avantajı dahil), onlar ${tah.D.toFixed(1)} → kazanma ihtimali %${Math.round(tah.w * 100)}.`;
  s.attBoost += 5;
  s.pendingEvidence.push({ v: 6, why: `${ad}'daki silahlı baskını biri karakola bildirdi.` });
  fame(s, 'halk', 'golge', { k: 2, i: -2 }, 1);
  if (brnd(st) < tah.w) {
    const kayip = Math.min(ek - 1, Math.floor(tah.D * 0.25 * (0.3 + brnd(st))));
    st.ekip -= Math.max(0, kayip);
    const dusus = 16 + brnd(st) * 8;
    addInf(b, hk, -dusus);
    addInf(b, 'oyuncu', (10 + brnd(st) * 6) * (1 - (b.inf.oyuncu || 0) / 140));
    b.tan = clamp(b.tan + 10, 0, 100);
    b.huzur = clamp(b.huzur - 10, 0, 100);
    b.kor = clamp(b.kor + 12, 0, 100); b.sev = clamp(b.sev - 6, 0, 100);
    aileDeg(st, hk, -12, 8);
    st.ofke[hk] = Math.min(60, st.ofke[hk] + 25);
    const ganimet = Math.round(b.servet * 120);
    s.cash.dirty += ganimet;
    fame(s, 'yeralti', 'cephe', { t: 4, k: 4 }, 1);
    log(s, `BASKIN: ${ad}'da ${fad} adamlarını bastın; nüfuzları −${Math.round(dusus)}${kayip > 0 ? `, ${kayip} adam kaybettin` : ''}, $${ganimet} ganimet.`, 'good', detay + ` ${fad} bunu unutmayacak: bölgelerine baskı artar.`);
    hakimDegisti(s, a.b, onceki);
    bildirim(s, pushCard, 'Baskın başarılı', `${ad} baskını: ${fad} adamları dağıldı. ${detay}\nNüfuzun ${Math.round(b.inf.oyuncu || 0)}%${hakimOf(st, a.b) === 'oyuncu' ? ': bölge artık senin.' : '.'} ${fad} misilleme yapacaktır.`);
  } else {
    const kayip = Math.min(ek, Math.ceil(ek * (0.4 + brnd(st) * 0.4)));
    st.ekip -= kayip;
    addInf(b, 'oyuncu', -3); b.kor = clamp(b.kor - 6, 0, 100);
    aileDeg(st, hk, -4, -4);
    st.ofke[hk] = Math.min(60, st.ofke[hk] + 10);
    fame(s, 'yeralti', 'cephe', { k: -3 }, 1);
    log(s, `BASKIN: ${ad}'da ${fad} seni püskürttü; ${kayip} adamını kaybettin.`, 'bad', detay);
    let metin = `${ad} baskını battı: ${kayip} adamın düştü. ${detay}`;
    if (brnd(st) < 0.25) {
      const r = yaralan(s, a.b, hk, ek > kayip);
      metin += r === 'oldu' ? `\n${s.over.text}` : '\nKaçarken vuruldun.';
    }
    bildirim(s, pushCard, 'Baskın başarısız', metin);
  }
  return { ok: true };
}

// ---------- düşman baskını (aylık) ----------
// Rakip aile senin bölgene ya da mekanlarının bulunduğu bölgeye adam yollar.
export function dusmanBaskin(s, f, id, kazan, hk, pushCard) {
  const st = s.bolge, bd = st.list[id], ad = BOLGELER[id].ad, fad = hakimAd(f), k = kudret(st, f);
  const n = (2 + k / 4 + brnd(st) * 2) * (1 - st.aile[f].k / 250);
  const orada = s.mesafe && !s.walk && !yaraliMi(s) && bolgeAt(s.pos) === id;
  const mekan = id === MEKAN_BOLGE;
  const ek = st.ekip;
  const D = 1 + bd.garnizon * 1.1 + (orada ? ekipGuc(s) : 0) + perceived(s, 'yeralti').K / 30 + (bd.inf.oyuncu || 0) / 25 + etki(bd, id).s * 1.2; // halk sevdiği hakimi uyarır
  const w = kazanP(n, D);
  const detay = `Saldıranlar ${n.toFixed(1)}, savunman ${D.toFixed(1)} (garnizon ${bd.garnizon}${orada ? `, yanındaki ekip ${ek}` : ''}) → baskının tutma ihtimali %${Math.round(w * 100)}.`;
  if (brnd(st) < w) {
    addInf(bd, f, kazan);
    bd.huzur = clamp(bd.huzur - 10, 0, 100);
    bd.sev = clamp(bd.sev - 5, 0, 100); bd.kor = clamp(bd.kor - 4, 0, 100);
    const gitti = Math.min(bd.garnizon, Math.ceil(n * 0.3));
    bd.garnizon -= gitti;
    let metin = `${fad}, ${ad}'a baskın düzenledi. Savunma çöktü; nüfuzun düşüyor${gitti ? `, garnizondan ${gitti} adam ölüp kaçtı` : ''}.`;
    if (mekan) {
      const gun = 1 + Math.floor(brnd(st) * 3);
      st.kapali = Math.max(st.kapali, s.t + gun * DAY);
      const hasar = Math.min(Math.max(0, s.cash.clean), 100 + Math.round(brnd(st) * 200));
      s.cash.clean -= hasar;
      metin += ` Mekanların ${gun} gün kapalı kalacak; $${hasar} zarar.`;
    }
    if (orada) {
      const kayip = Math.min(ek, Math.floor(n * 0.3));
      st.ekip -= kayip;
      if (kayip) metin += ` Ekipten ${kayip} adam düştü.`;
      if (brnd(st) < 0.35 / (1 + 0.3 * ek)) { const r = yaralan(s, id, f, ek > 0); metin += r === 'oldu' ? `\n${s.over.text}` : ' Sen de vuruldun.'; }
    }
    log(s, metin, 'bad', detay);
    bildirim(s, pushCard, 'Baskın yedin', `${metin}\n${detay}`);
  } else {
    addInf(bd, f, kazan * 0.3);
    bd.tan = clamp(bd.tan + 3, 0, 100);
    bd.sev = clamp(bd.sev + 3, 0, 100); bd.kor = clamp(bd.kor + 2, 0, 100);
    aileDeg(st, f, -3, 4);
    const gitti = Math.min(bd.garnizon, Math.floor(n * 0.15));
    bd.garnizon -= gitti;
    fame(s, 'yeralti', 'cephe', { k: 2 }, 1);
    log(s, `${fad}, ${ad}'a baskın düzenledi; adamların püskürttü${gitti ? ` (${gitti} kayıp)` : ''}.`, 'good', detay);
  }
}

