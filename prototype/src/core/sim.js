// Simülasyon çekirdeği. DOM'a, zamanlayıcıya, tarayıcıya dokunmaz.
// Durum düz JSON'dur: kaydetmek = JSON.stringify(s). Tek giriş noktaları: newGame, advance, act.
import {
  clamp, sigmoid, DAY, SEASONS, rnd, dateOf, log, addMod, opinion, spend, staff, informed,
  addStress, hideGoods, money,
} from './util.js';
import { EVENTS, producing } from './events.js';
import {
  newSocial, perceived, fame, leak, gucPuani, listede, bond, addOrtak, loseDost, defterAc, defterKapat,
  krediInfo, hisseDegeri, kabulAhit, socialDay, socialMonth, S0,
} from './social.js';
import { stressFor, blocked } from './traits.js';
import { PLACES, BOLGELER, W, WALK, snapRow, route, pathLen, advanceAlong, bolgeAt } from './world.js';
import { brnd as brndSim, newBolge, bolgeMonth, bolgeIs, bolgeAdam, bolgeYatirim, bolgeHarac, aileHediye, yaraliMi } from './bolge.js';
import { newMeslek, isGir, isBirak, isletmeAl, meslekGun, meslekAy, yurumeCarpan, akalamaUcret, akalamaKapasite, aklamaEk, mesaiCarpan } from './meslek.js';
import { ekipAl, bolgeBaskin, pusuKur, pusuP } from './savas.js';

export const C = {
  MIN_PER_SEC: 3,          // ×1 hızda: 1 gerçek saniye = 3 oyun dakikası (1 oyun saati = 20 sn)
  MEY_DEMAND: 700,         // semtin günlük meyhane talebi ($, fiyat 1,00 iken)
  OUTSIDE: 250,            // "evde oturanlar": hiçbir meyhaneye gitmeyenlerin çekiciliği
  VAR_COST: 0.55,          // değişken maliyet (satış hacminin oranı)
  RENT: 300, TAX: 0.10, INTEREST: 0.01,
  LIQ_DEMAND: 50, LIQ_PRICE: 10, LIQ_COST: 4, STOCK_MAX: 300, VOL_MAX: 60,
  BUILD: 400, HIDDEN_ROOM: 500,
  IZ_BASE: 8, IZ_DECAY: 0.15, DETECT_K: 0.0001, DOSYA_DECAY: 0.4,
  LAUNDER: { meyhane: 0.30, camasir: 0.50 }, LAUNDER_FEE: 0.20,
  ATT_BASE: 40,
  SEAS_MEY: [1.0, 0.9, 1.05, 1.15], SEAS_LIQ: [1.0, 0.95, 1.05, 1.2],
  STAGES: [[75, 'Arama emri'], [50, 'Soruşturma'], [25, 'Gözetim'], [0, 'Temiz']],
};

// Saatlik dağılımlar (toplamları 1)
const MEY_W = {}; const LIQ_W = {};
[11, 12, 13, 14].forEach((h) => (MEY_W[h] = 0.05));
[15, 16, 17].forEach((h) => (MEY_W[h] = 0.04));
[18, 19, 20, 21, 22, 23].forEach((h) => (MEY_W[h] = 0.1));
MEY_W[0] = 0.08;
[20, 21, 22, 23, 0, 1, 2, 3].forEach((h) => (LIQ_W[h] = 0.125));

const ch = (ad, rol, yas, mods, x = {}) => ({
  ad, rol, yas, mods: mods.map(([k, v]) => ({ k, v, decay: 0 })),
  employed: false, job: null, maas: 0, piyasa: 0, sadakat: 50, dead: false, ...x,
});

// ---------- konum: karakter haritada yürür ----------
// Şehir yerleşimi ve yol bulma world.js'te. Burada: durum, hareket ve "orada mısın?" kuralı.
export { PLACES, BOLGELER, ROWS, V, W, H, WALK, bolgeAt } from './world.js';
// Bu işler için o bölgede bulunmak gerekir (arayüzde).
export const BOLGE_ISLERI = new Set(['bolgeIs', 'bolgeAdam', 'bolgeYatirim', 'bolgeBaskin']);
// Bu işler için orada bulunmak gerekir (s.mesafe açıksa; arayüz açar, bot testleri açmaz).
export const GATE = { bribe: 'karakol', kredi: 'liman', hisse: 'liman', hisseSat: 'liman', ahitIste: 'karaca', ahitBoz: 'karaca', payDebt: 'tefeci', buildDist: 'meyhane', upgradeHidden: 'meyhane', rest: 'ev' };

export function here(s) {
  if (s.walk) return null;
  for (const [id, p] of Object.entries(PLACES)) if (Math.hypot(p.x - s.pos.x, p.y - s.pos.y) < 6) return id;
  return null;
}
export const walkMinutes = (s, id) => Math.ceil(pathLen(s.pos, route(s.pos, PLACES[id])) / (WALK * yurumeCarpan(s)));
// Arayüz için akıcı konum: bir dakikanın kesri kadar ileri
export function walkerAt(s, frac = 0) {
  if (!s.walk) return { x: s.pos.x, y: s.pos.y, path: [] };
  const r = advanceAlong(s.pos, s.walk.path, WALK * yurumeCarpan(s) * Math.min(1, frac));
  return { x: r.x, y: r.y, path: r.rest };
}
function walkStep(s) {
  const r = advanceAlong(s.pos, s.walk.path, WALK * yurumeCarpan(s));
  s.pos.x = r.x; s.pos.y = r.y; s.walk.path = r.rest;
  if (r.last) s.walk.prev = { x: r.last.x, y: r.last.y };
  if (!r.rest.length) s.walk = null;
}
// Yürüyüşü yeni hedefe çevir: yolun ortasında ise önceki ya da sonraki düğümden dönmek, hangisi kısaysa.
function startWalk(s, dest, to) {
  if (!s.walk) {
    const path = route(s.pos, dest);
    s.walk = path.length ? { to, path, prev: { x: s.pos.x, y: s.pos.y } } : null;
    return;
  }
  const next = s.walk.path[0], prev = s.walk.prev || null;
  const via = (n, other) => { const p = [{ x: n.x, y: n.y }, ...route(n, dest)]; return { p, c: pathLen(s.pos, p), prev: other }; };
  const a = via(next, prev || { x: s.pos.x, y: s.pos.y });
  const b = prev ? via(prev, next) : null;
  const best = b && b.c < a.c ? b : a;
  s.walk = { to, path: best.p, prev: best.prev };
}

export function newGame(seed = (Date.now() & 0x7fffffff)) {
  const s = {
    v: 8, seed, t: 6 * 60, speed: 0, mesafe: false, pos: { x: PLACES.meyhane.x, y: PLACES.meyhane.y }, walk: null,
    cash: { clean: 1500, dirty: 0 },
    debt: { principal: 6000, installment: 600, missed: 0 },
    patron: { ad: 'Sen', yas: 34, traits: ['Temkinli', 'Cömert', 'Merhametli'], stres: 10 },
    ...newSocial(),
    bolge: newBolge(seed),
    meslek: newMeslek(),
    biz: {
      meyhane: { id: 'meyhane', type: 'meyhane', name: "Murphy's Tavern", price: 1, quality: 50, rep: 50, mRev: 0, mCost: 0 },
      rakip: { id: 'rakip', name: "Duffy'nin Yeri", price: 1, quality: 50, rep: 55 },
      camasir: null,
    },
    dist: { built: false, hiddenRoom: false, volume: 0, stock: 0, hiddenUntil: 0, iz: 0, lastP: 0 },
    dosya: 0, stage: 0, raid: null, nextRaidOk: 0, maliSuphe: 0,
    attBoost: 0, izBoost: 0, pendingEvidence: [],
    launderPct: 100, rivalCutUntil: 0, liqBoostUntil: 0, share: 0.36,
    today: { rev: 0, liq: 0 }, month: { liqSold: 0, liqRev: 0, prodCost: 0 },
    cards: [], cardSeq: 1, pauseReq: 0, evHour: 12,
    flags: {}, cool: {}, stats: { totalSold: 0 }, history: [], log: [], over: null,
    chars: {
      nuri: ch('Walter Doyle', 'Vekil (sağ kolun)', 58, [['Babanın eski dostu', 40]], { employed: true, job: 'vekil', maas: 150, piyasa: 140, sadakat: 80, legal: true, ortak: 2, traits: ['Temkinli', 'Sözünün Eri'] }),
      halil: ch('Garson Eddie', 'Garson', 26, [['Seni çocukluğundan tanır', 10]], { employed: true, job: 'garson', maas: 90, piyasa: 90, sadakat: 55, legal: true, ortak: 1, traits: ['Cömert', 'Gözüpek'] }),
      fatma: ch('Rosa Delgado', 'Aşçı', 44, [['Baban ona iş vermişti', 15]], { employed: true, job: 'asci', maas: 100, piyasa: 100, sadakat: 60, legal: true, traits: ['Merhametli', 'Sözünün Eri'] }),
      aziz: ch('Kör Gus', 'İçki ustası', 61, [['Zanaatına saygı duyuyorsun', 5]], { maas: 120, piyasa: 120, hire: 'usta', traits: ['Açgözlü', 'Alkolik'] }),
      cemal: ch('İri Tony', 'Koruma', 29, [['Sokaktan tanışırsınız', 5]], { maas: 100, piyasa: 100, hire: 'koruma', traits: ['Gözüpek', 'Zalim'] }),
      ihsan: ch('Kâtip Irving', 'Muhasebeci', 38, [], { maas: 110, piyasa: 110, hire: 'muhasebeci', legal: true, traits: ['Temkinli', 'Sözünün Eri'] }),
      rifat: ch('Dolan', 'Dedektif', 41, [['Mahallenin çocuğusun', 5]], { yoz: 65, resmiMaas: 80, payroll: false, bribeAt: -99999, traits: ['Açgözlü', 'Temkinli'] }),
      kazim: ch('Meyhaneci Duffy', 'Rakip', 47, [['Rakibisin', -20]], { traits: ['Gözüpek', 'Kindar'] }),
      sakir: ch('Tefeci Sal', 'Alacaklın', 52, [['Borçlu iyi müşteridir', 5]], { traits: ['Açgözlü', 'Zalim'] }),
      zehra: ch('Maggie', 'Kız kardeşin', 31, [['Kardeşsiniz', 40]], { traits: ['Cömert', 'Merhametli'] }),
      selim: ch('Danny', 'Yeğenin', 15, [['Dayısına hayran', 25]], { maas: 40, piyasa: 40, traits: ['Gözüpek', 'Dönek'] }),
      leyla: ch('Lily', 'Kızın', 9, [['Babası', 60]], { traits: [] }),
      hacer: ch('Bayan Kowalski', 'Arka sokak komşusu', 67, [['Eski komşu', 10]], { traits: ['Merhametli', 'Kindar'] }),
      orhan: ch('Reis Vincent Marchetti', 'Marchetti Ailesi\'nin başı', 56, [], { traits: ['Temkinli', 'Zalim'] }),
      selahattin: ch('Bay Harrington', 'Harbor Trust Müdürü', 49, [], { traits: ['Açgözlü', 'Temkinli'] }),
    },
  };
  log(s, 'Baban öldü. Sana bir meyhane, $6,000 borç ve boş bir bodrum bıraktı.', 'card');
  log(s, 'Southside\'in hakimi yok. Nüfuzun %25; %35\'e çıkarırsan bölge senin olur. Bölgeler sekmesine bak.', 'warn');
  log(s, 'Tefeci Sal her Hesap Günü (ayın 10\'u) $600 taksit bekliyor. Üç taksit kaçırırsan konuşmaya gelmeyecek.', 'warn');
  return s;
}

// ---------- türetilmiş değerler ----------
const attract = (b) => b.quality * Math.sqrt(Math.max(1, b.rep)) * Math.pow(b.price, -1.5);

export function marketShare(s) {
  const a = attract(s.biz.meyhane) * (1 + 0.2 * perceived(s, 'halk').I / 100), b = attract(s.biz.rakip);
  return { me: a / (a + b + C.OUTSIDE), rival: b / (a + b + C.OUTSIDE) };
}

export function attentionLines(s) {
  const l = [{ k: 'Semt tabanı (Southside)', v: C.ATT_BASE }];
  if (s.attBoost >= 0.5) l.push({ k: 'Son olaylar', v: Math.round(s.attBoost) });
  if (s.chars.rifat.payroll) l.push({ k: 'Dolan aylıkta', v: -15 });
  if (s.dosya >= 50) l.push({ k: 'Soruşturma açık', v: 10 });
  const tp = 0.25 * perceived(s, 'polis').T;
  if (tp >= 0.5) l.push({ k: 'Polis seni tanıyor', v: Math.round(tp) });
  if (s.unvan.ahit && s.unvan.ahit.himaye) l.push({ k: 'Marchetti himayesi', v: -8 });
  return l;
}
export const attention = (s) => clamp(attentionLines(s).reduce((a, x) => a + x.v, 0), 5, 100);

// Tedarik pahalılaşması: esnaf birliği güvenilmez diyorsa +%15; Marchetti tedarik kestiyse +%10
export const varCostMult = (s) => (listede(s, 'esnaf') ? 1.15 : 1) * (s.t < s.tedarikZamUntil ? 1.1 : 1);

export const secrecy = (s) => (s.dist.hiddenRoom ? 0.75 : 0.5);

export function dailyIz(s, vol = s.dist.volume) {
  if (vol <= 0) return 0;
  return C.IZ_BASE * Math.pow(vol / 20, 0.7) * (1 - secrecy(s)) * (s.dosya >= 25 ? 1.5 : 1);
}
export const detectP = (s, iz = s.dist.iz) => 1 - Math.exp(-C.DETECT_K * iz * attention(s));

export const stageName = (s) => C.STAGES.find(([th]) => s.dosya >= th)[1];
const stageIdx = (s) => (s.dosya >= 75 ? 3 : s.dosya >= 50 ? 2 : s.dosya >= 25 ? 1 : 0);

export function launderInfo(s) {
  const cap = (s.biz.meyhane.mRev * C.LAUNDER.meyhane + (s.biz.camasir ? s.biz.camasir.mRev * C.LAUNDER.camasir : 0)) * akalamaKapasite(s) + aklamaEk(s);
  const fee = akalamaUcret(s, staff(s, 'muhasebeci') ? 0.12 : C.LAUNDER_FEE);
  const amt = Math.min(s.cash.dirty, cap * s.launderPct / 100);
  return { cap, fee, amt };
}

export function estimateBribe(s, amount) {
  const r = s.chars.rifat;
  const factors = [
    { k: `Teklif (${money(amount)}; resmî maaşı $${r.resmiMaas})`, x: 1.2 * Math.log(1 + amount / r.resmiMaas) },
    { k: 'Sana görüşü', x: opinion(s, 'rifat').total / 40 },
    { k: 'Yozlaşabilirliği', x: (r.yoz - 50) / 20 },
    { k: 'Dosyanın kabarıklığı', x: -s.dosya / 50 },
    { k: 'Aranan listesindesin', x: listede(s, 'aranan') ? -1 : 0 },
    { k: 'Riskin tabanı', x: -1.5 },
  ];
  return { p: sigmoid(factors.reduce((a, f) => a + f.x, 0)), factors, effect: clamp(3 + amount / 50, 0, 10) };
}

// ---------- kartlar ----------
function pushCard(s, id, data = {}) {
  const ev = EVENTS[id];
  const day = dateOf(s.t).day;
  if (ev.once) s.flags['ev_' + id] = true;
  s.cool[id] = day + (ev.cooldown || 0);
  if (ev.onPush) ev.onPush(s);
  s.cards.push({ id: s.cardSeq++, ev: id, t0: s.t, expires: s.t + ev.window * DAY, data });
  s.pauseReq++;
  if (id !== 'rapor' && id !== 'bildirim') log(s, `Karar bekliyor: ${(data && data.title) || ev.title}`, 'card');
}

export function cardView(s, card) {
  const ev = EVENTS[card.ev];
  return {
    id: card.id, ev: card.ev, title: (card.data && card.data.title) || ev.title, text: ev.text(s, card),
    hoursLeft: Math.max(0, Math.ceil((card.expires - s.t) / 60)),
    def: ev.def, system: !!ev.system,
    options: ev.options(s, card).map((o) => ({ label: o.label, hint: o.hint || '', enabled: !o.can || o.can(s) })),
  };
}

function choose(s, cardId, i, byVekil = false) {
  const idx = s.cards.findIndex((c) => c.id === cardId);
  if (idx < 0) return { ok: false, msg: 'Kart yok.' };
  const card = s.cards[idx];
  const ev = EVENTS[card.ev];
  const opts = ev.options(s, card);
  let o = opts[i];
  const vekilVar = !s.chars.nuri.dead;
  if (byVekil && !vekilVar) o = null; // vekil yoksa iş sahipsiz kalır: en pasif seçenek
  if (!o || (o.can && !o.can(s))) {
    if (!byVekil) return { ok: false, msg: 'Bu seçenek şu an mümkün değil.' };
    o = [...opts].reverse().find((x) => !x.can || x.can(s));
  }
  s.cards.splice(idx, 1);
  if (card.ev !== 'rapor' && card.ev !== 'bildirim') {
    log(s, byVekil ? `${ev.title}: sen karar vermedin; ${vekilVar ? 'Walter Doyle halletti' : 'vekilin olmadığı için iş sahipsiz kaldı'} → "${o.label}"` : `${ev.title} → "${o.label}"`, byVekil ? 'warn' : 'info');
  }
  o.run(s, card, pushCard);
  checkDosya(s);
  return { ok: true };
}

// ---------- dosya / baskın ----------
function addEvidence(s, v, why) {
  s.dosya = clamp(s.dosya + v, 0, 100);
  s.evidenceToday = true;
  log(s, `Dosyana kanıt girdi: +${v} (Dosya ${Math.round(s.dosya)})`, 'bad', why);
  fame(s, 'polis', 'golge', { t: v * 0.6, i: -v * 0.3 }, 1); // kanıt, polisin seni tanımasını da artırır
  checkDosya(s);
}

function checkDosya(s) {
  if (s.over) return;
  const st = stageIdx(s);
  if (st > s.stage) {
    const msg = ['', 'Gözetim altındasın. Bıraktığın iz artık 1,5 kat sayılıyor.', 'Hakkında soruşturma açıldı. Polis Dikkati +10.', 'Savcılık arama emri hazırlıyor.'][st];
    log(s, `Dosya aşaması: ${C.STAGES[3 - st][1]}. ${msg}`, 'bad');
    s.pauseReq++;
  }
  s.stage = st;
  if (s.dosya >= 100) {
    s.over = { kind: 'dava', text: 'Dosya 100\'e ulaştı. Savcı iddianameyi yazdı; sabaha karşı kapın çalındı. Dava açıldı.' };
    return;
  }
  if (s.dosya >= 75 && !s.raid && s.t >= s.nextRaidOk) {
    s.raid = { at: s.t + (1 + Math.floor(rnd(s) * 3)) * DAY };
    if (informed(s)) pushCard(s, 'baskin_ihbari');
  }
}

function resolveRaid(s) {
  const d = s.dist;
  s.raid = null;
  s.nextRaidOk = s.t + 10 * DAY;
  s.pauseReq++;
  const hidden = s.t < d.hiddenUntil;
  if (!d.built || hidden) {
    s.dosya = Math.max(0, s.dosya - 30);
    s.stage = stageIdx(s);
    log(s, `BASKIN: Polis bodrumu aradı, hiçbir şey bulamadı. Dosya −30 (Dosya ${Math.round(s.dosya)}).`, 'good',
      d.built ? 'Malı ve imalathaneyi önceden saklamıştın.' : 'Bodrumda imalathane yoktu.');
    return;
  }
  const fine = Math.min(500, Math.max(0, s.cash.clean));
  s.cash.clean -= fine;
  const lost = Math.round(d.stock);
  d.built = false; d.hiddenRoom = false; d.volume = 0; d.stock = 0; d.iz = 0;
  log(s, `BASKIN: Polis bodrumu bastı. İmalathane söküldü, ${lost} şişeye el kondu, ${money(fine)} ceza kesildi.`, 'bad',
    informed(s) ? 'Haber almıştın ama malı saklamadın.' : 'Poliste haber uçuracak adamın yoktu; baskın habersiz geldi.');
  leak(s, 'halk', 0.1); // baskın mahallenin gözü önünde oldu: gölge yüzün sızar
  fame(s, 'halk', 'golge', { t: 10, i: -6 }, 1);
  const usta = staff(s, 'usta');
  if (usta && rnd(s) < 0.5) {
    usta.employed = false; usta.jailed = true; usta.hire = null;
    if (!usta.traits.includes('Hapis Yatmış')) usta.traits.push('Hapis Yatmış');
    log(s, `${usta.ad} kazan başında yakalandı, içeri alındı.`, 'bad');
  }
  addStress(s, 15, 'Baskın yedin.');
  addEvidence(s, 20, 'Baskında suçüstü: imalathane ve stok bulundu.');
}

// ---------- tikler ----------
function hourTick(s) {
  const d = dateOf(s.t);
  const h = d.hour;

  const kapali = s.t < s.bolge.kapali, yaral = yaraliMi(s) ? 0.75 : 1;
  const w = MEY_W[h];
  if (w && !kapali) {
    const m = s.biz.meyhane;
    const sh = marketShare(s).me;
    s.share = sh;
    const vol = C.MEY_DEMAND * C.SEAS_MEY[d.season] * w * sh * (staff(s, 'garson') ? 1 : 0.7) * yaral * mesaiCarpan(s);
    const rev = vol * m.price, cost = vol * C.VAR_COST * varCostMult(s);
    s.cash.clean += rev - cost; m.mRev += rev; m.mCost += cost; s.today.rev += rev;
  }
  if (s.biz.camasir && h >= 8 && h < 18 && !kapali) {
    const c = s.biz.camasir;
    s.cash.clean += 2; c.mRev += 6; c.mCost += 4;
  }
  const lw = LIQ_W[h];
  const di = s.dist;
  if (lw && di.built && s.t >= di.hiddenUntil && di.stock > 0 && !kapali) {
    const demand = C.LIQ_DEMAND * C.SEAS_LIQ[d.season] * (s.t < s.liqBoostUntil ? 2 : 1) * lw;
    const sold = Math.min(di.stock, demand);
    di.stock -= sold;
    const rev = sold * C.LIQ_PRICE;
    s.cash.dirty += rev; s.today.liq += rev; s.month.liqSold += sold; s.month.liqRev += rev; s.stats.totalSold += sold;
  }

  if (s.raid && s.t >= s.raid.at) resolveRaid(s);
  if (s.over) return;
  bolgeSaat(s);
  if (s.over) return;

  for (const c of [...s.cards]) if (s.t >= c.expires) choose(s, c.id, EVENTS[c.ev].def, true);

  if (h === 5) dayTick(s);
  if (h === s.evHour) rollEvents(s);
  if (d.dayInMonth === 10 && h === 20) monthTick(s);
}

// Saatlik bölge işleri: tanınırlık, yaralı iyileşmesi, düşman bölgede pusu. Konum yalnızca arayüzde (s.mesafe) anlamlıdır.
function bolgeSaat(s) {
  if (!s.mesafe) return;
  const st = s.bolge;
  if (st.yarali && s.t >= st.yarali) { st.yarali = 0; log(s, 'Yaran iyileşti; yeniden sokaktasın.', 'good'); }
  if (yaraliMi(s)) return;
  const id = bolgeAt(s.pos), b = st.list[id];
  b.tan = clamp(b.tan + 0.05 * (1 - b.tan / 120), 0, 100);
  if (s.cards.some((c) => c.ev === 'pusu')) return;
  if (Math.hypot(s.pos.x - PLACES.ev.x, s.pos.y - PLACES.ev.y) < 40) return;
  const { p } = pusuP(s, id);
  if (p > 0 && brndSim(s) < p) pusuKur(s, pushCard);
}

function rollEvents(s) {
  const day = dateOf(s.t).day;
  for (const id of Object.keys(EVENTS)) {
    const ev = EVENTS[id];
    if (ev.system) continue;
    if (ev.once && s.flags['ev_' + id]) continue;
    if ((s.cool[id] || 0) > day) continue;
    if (s.cards.some((c) => c.ev === id)) continue;
    if (!ev.cond(s)) continue;
    if (rnd(s) < ev.p) { pushCard(s, id); break; }
  }
}

function dayTick(s) {
  const di = s.dist;
  meslekGun(s);
  s.today = { rev: 0, liq: 0 };
  s.evHour = 9 + Math.floor(rnd(s) * 13);

  // üretim
  const usta = staff(s, 'usta');
  let vol = 0;
  if (producing(s) && usta) {
    vol = Math.min(di.volume, C.STOCK_MAX - di.stock);
    const cost = vol * C.LIQ_COST;
    if (vol > 0 && spend(s, cost, 'dirty')) { di.stock += vol; s.month.prodCost += cost; }
    else if (vol > 0) { vol = 0; log(s, 'Hammadde alacak para yok; bu gece kazan kaynamadı.', 'warn'); }
  }

  // iz ve kanıt
  di.iz = di.iz * (1 - C.IZ_DECAY) + dailyIz(s, vol) + s.izBoost;
  s.izBoost = 0;
  s.evidenceToday = false;
  const att = attention(s);
  const p = detectP(s);
  di.lastP = p;
  if (di.iz > 1 && rnd(s) < p) {
    const r = rnd(s);
    const v = r < 0.4 ? 3 : r < 0.7 ? 5 : r < 0.9 ? 8 : 10;
    const what = { 3: 'Devriye gece arabasını fark etti.', 5: 'Bir muhbir bodrumdaki kokuyu anlattı.', 8: 'Sivil polis arka kapıdan şişe çıkarken gördü.', 10: 'Müşterilerinden biri karakolda öttü.' }[v];
    addEvidence(s, v, `${what} İz ${Math.round(di.iz)} × Polis Dikkati ${Math.round(att)} → günlük yakalanma ihtimali %${Math.round(p * 100)}.`);
  }
  for (const e of s.pendingEvidence.splice(0)) addEvidence(s, e.v, e.why);
  if (!s.evidenceToday && s.dosya > 0) { s.dosya = Math.max(0, s.dosya - C.DOSYA_DECAY); s.stage = stageIdx(s); }
  s.attBoost *= 0.9;
  if (s.over) return;
  socialDay(s);

  // sadakat
  for (const [id, c] of Object.entries(s.chars)) {
    if (!c.employed || c.dead) continue;
    const target = clamp(50 + opinion(s, id).total * 0.6, 0, 100);
    c.sadakat += (target - c.sadakat) * 0.1;
    if (id !== 'nuri' && c.sadakat < 20 && rnd(s) < 0.15) {
      c.employed = false;
      log(s, `${c.ad} işi bıraktı.`, 'bad', `Sadakati ${Math.round(c.sadakat)} idi. Görüşü: ${opinion(s, id).lines.map((l) => `${l.k} ${l.v > 0 ? '+' : ''}${l.v}`).join(', ')}.`);
      if (c.job === 'usta' && rnd(s) < 0.4) s.pendingEvidence.push({ v: 8, why: `${c.ad} küskün ayrıldı ve bildiklerini anlattı.` });
    }
  }
  if (s.chars.selim.employed && vol > 0 && rnd(s) < 0.03) {
    s.izBoost += 8;
    log(s, 'Danny diner’da ağzından laf kaçırmış.', 'warn', 'Ketumluğu düşük (25). İz +8.');
  }

  // rakip, itibar, stres
  if (s.rivalCutUntil && s.t >= s.rivalCutUntil) { s.biz.rakip.price = 1; s.rivalCutUntil = 0; log(s, 'Duffy fiyatlarını eski hâline getirdi.', 'info'); }
  const m = s.biz.meyhane;
  m.quality = staff(s, 'asci') ? 50 : 30;
  const target = clamp(m.quality + (1 - m.price) * 60, 5, 100);
  m.rep += (target - m.rep) * 0.05;
  s.patron.stres = Math.max(0, s.patron.stres - 1);
}

function due(s, amount, name) {
  if (amount <= 0) return;
  if (s.cash.clean >= amount) { s.cash.clean -= amount; return; }
  const short = amount - Math.max(0, s.cash.clean);
  s.cash.clean = 0;
  s.debt.principal += short * 1.1;
  log(s, `${name} için temiz paran yetmedi. ${money(short)} açığı Sal kapattı; borcuna %10 fazlasıyla yazıldı.`, 'bad');
}

function monthTick(s) {
  const d = dateOf(s.t);
  const m = s.biz.meyhane, cm = s.biz.camasir;
  const R = [];
  const legalRev = m.mRev + (cm ? cm.mRev : 0), legalCost = m.mCost + (cm ? cm.mCost : 0);
  R.push(`YASAL İŞLER  ciro ${money(legalRev)} · mal/işletme gideri ${money(legalCost)}`);
  if (s.month.liqSold > 0) R.push(`BODRUM  ${Math.round(s.month.liqSold)} şişe satıldı · kirli gelir ${money(s.month.liqRev)} · hammadde ${money(s.month.prodCost)}`);

  meslekAy(s, R);

  // aklama
  const li = launderInfo(s);
  if (li.amt > 0) {
    s.cash.dirty -= li.amt; s.cash.clean += li.amt * (1 - li.fee);
    R.push(`AKLAMA  ${money(li.amt)} kirli → ${money(li.amt * (1 - li.fee))} temiz (kapasite ${money(li.cap)}, kesinti %${Math.round(li.fee * 100)})`);
    if (li.amt > li.cap * 1.001) {
      const sapma = (li.amt - li.cap) / li.cap * 100;
      const add = 0.02 * sapma * sapma * (staff(s, 'muhasebeci') ? 0.5 : 1);
      s.maliSuphe += add;
      R.push(`  ! Kapasitenin %${Math.round(sapma)} üstünde akladın: Mali Şüphe +${Math.round(add)} (şimdi ${Math.round(s.maliSuphe)})`);
    }
  }

  // maaşlar
  let legalSal = 0, otherSal = 0;
  for (const [id, c] of Object.entries(s.chars)) {
    if (!c.employed || c.dead) continue;
    const ok = c.legal ? (spend(s, c.maas, 'clean') || spend(s, c.maas, 'dirty')) : spend(s, c.maas, 'dirty');
    if (ok) { if (c.legal) legalSal += c.maas; else otherSal += c.maas; }
    else { addMod(s, id, 'Maaşı ödenmedi', -20, 2); log(s, `${c.ad} maaşını alamadı.`, 'bad'); }
  }
  const rf = s.chars.rifat;
  if (rf.payroll) {
    if (spend(s, 60, 'dirty')) otherSal += 60;
    else { rf.payroll = false; addMod(s, 'rifat', 'Aylığını kestin', -15, 1); log(s, 'Dolan\'ın aylığını ödeyemedin. Artık seni kollamıyor.', 'bad'); }
  }
  R.push(`MAAŞLAR  ${money(legalSal + otherSal)}${otherSal ? ` (${money(otherSal)} kayıt dışı)` : ''}`);

  // kira, vergi
  due(s, C.RENT, 'Kira');
  const tax = Math.max(0, (legalRev - legalCost - legalSal - C.RENT) * C.TAX);
  due(s, tax, 'Vergi');
  R.push(`KİRA ${money(C.RENT)} · VERGİ ${money(tax)}`);

  // borç
  const db = s.debt;
  if (db.principal > 0) {
    db.principal *= 1 + C.INTEREST;
    const pay = Math.min(db.installment, db.principal);
    if (s.cash.clean >= pay) {
      s.cash.clean -= pay; db.principal -= pay;
      R.push(`BORÇ  taksit ${money(pay)} ödendi · kalan ${money(db.principal)}`);
      if (db.principal < 1) { db.principal = 0; db.missed = 0; log(s, 'Babanın borcu bitti. Sal\'a artık bir şey borçlu değilsin.', 'good'); }
    } else {
      db.missed++;
      R.push(`BORÇ  ! Taksit ödenemedi (${db.missed}/3) · kalan ${money(db.principal)}`);
      log(s, `Taksiti ödeyemedin (${db.missed}/3).`, 'bad', `Temiz paran ${money(s.cash.clean)}, taksit ${money(pay)}. Kirli parayla resmî taksit ödenmez.`);
      addStress(s, 10, 'Borç boğazına dayandı.');
      if (db.missed >= 3) { s.over = { kind: 'borc', text: 'Üç taksit üst üste ödenmedi. Sal\'ın adamları bu sefer oturmadı. Meyhanenin tapusu el değiştirdi.' }; }
    }
  }

  // maliye
  if (s.maliSuphe >= 50) {
    s.maliSuphe = 20;
    due(s, 300, 'Maliye cezası');
    addEvidence(s, 10, 'Maliye müfettişi defterlerdeki ciroyu masa sayısıyla karşılaştırdı: kapasitenin çok üstünde para aklamıştın.');
    R.push('MALİYE  ! Defterler incelendi: $300 ceza, Dosya +10');
  }
  s.maliSuphe *= 0.8;

  // yaş ve ölüm: herkes 1 yaş büyür
  const died = [];
  for (const c of Object.values(s.chars)) {
    if (c.dead) continue;
    c.yas++;
    if (c.yas >= 50 && rnd(s) < 0.002 * Math.pow(2, (c.yas - 30) / 8)) {
      c.dead = true; c.employed = false; died.push(c.ad);
      loseDost(s, Object.keys(s.chars).find((k) => s.chars[k] === c), 'kaybettin');
      log(s, `${c.ad} öldü (${c.yas} yaşında).`, 'bad', 'Eceliyle. Ölüm ihtimali yaşla katlanarak artar.');
    }
  }
  s.patron.yas++;
  const pp = 0.002 * Math.pow(2, (s.patron.yas - 30) / 8) * (s.patron.stres >= 80 ? 3 : 1);
  if (!s.over && s.patron.yas >= 50 && rnd(s) < pp) s.over = { kind: 'olum', text: `${s.patron.yas} yaşında, bir sabah uyanmadın. Vâris sistemi sonraki sürümde: şimdilik hikâye burada bitiyor.` };
  R.push(`YAŞ  Sen ${s.patron.yas} oldun · Lily ${s.chars.leyla.yas}${died.length ? ` · Ölenler: ${died.join(', ')}` : ''}`);

  // görüş etkileri solar
  for (const c of Object.values(s.chars)) {
    for (const md of c.mods) if (md.decay) md.v = md.v > 0 ? Math.max(0, md.v - md.decay) : Math.min(0, md.v + md.decay);
    c.mods = c.mods.filter((md) => md.v !== 0);
  }

  bolgeMonth(s, R, pushCard);
  socialMonth(s, R, { legalRev, liqRev: s.month.liqRev, legalCost, pushCard });

  R.push(`KASA  temiz ${money(s.cash.clean)} · kirli ${money(s.cash.dirty)} · Dosya ${Math.round(s.dosya)} (${stageName(s)})`);
  s.history.push({ month: d.month, clean: s.cash.clean, dirty: s.cash.dirty, debt: db.principal, dosya: s.dosya, legalRev, liqRev: s.month.liqRev });
  m.mRev = 0; m.mCost = 0; if (cm) { cm.mRev = 0; cm.mCost = 0; }
  s.month = { liqSold: 0, liqRev: 0, prodCost: 0 };
  log(s, `Hesap Günü: ${d.year}. yıl ${d.monthInYear}. ay kapandı. Temiz ${money(s.cash.clean)}, kirli ${money(s.cash.dirty)}.`, 'card');
  if (!s.over) pushCard(s, 'rapor', { text: `${d.year}. yıl, ${d.monthInYear}. ay (${SEASONS[d.season]})\n\n${R.join('\n')}` });
}

// ---------- dış arayüz ----------
export function advance(s, minutes) {
  for (let i = 0; i < minutes && !s.over; i++) {
    s.t++;
    if (s.walk) walkStep(s);
    if (s.t % 60 === 0) hourTick(s);
  }
}

export function canHire(s, id) {
  const c = s.chars[id];
  if (!c || c.dead || c.employed || !c.hire) return false;
  if (id === 'aziz' && !s.flags.ustaKnown) return false;
  return !staff(s, c.hire);
}

const fail = (msg) => ({ ok: false, msg });
const OK = { ok: true };

export function act(s, a) {
  if (s.over) return fail('Oyun bitti.');
  const di = s.dist;
  if (s.mesafe && GATE[a.type] && here(s) !== GATE[a.type]) return fail(`Bunun için ${PLACES[GATE[a.type]].ad} yerinde olmalısın.`);
  if (s.mesafe && BOLGE_ISLERI.has(a.type)) {
    if (!BOLGELER[a.b]) return fail('Böyle bir bölge yok.');
    if (s.walk || bolgeAt(s.pos) !== a.b) return fail(`Bunun için ${BOLGELER[a.b].ad} bölgesinde olmalısın.`);
  }
  switch (a.type) {
    case 'goto': {
      if (yaraliMi(s)) return fail('Yaralısın; iyileşene kadar yataktasın.');
      const pl = a.b ? PLACES[a.b] : null;
      if (a.b && !pl) return fail('Gidilemez.');
      const dest = pl ? { x: pl.x, y: pl.y } : { x: Math.max(12, Math.min(W - 12, +a.x)), y: snapRow(Number.isFinite(+a.y) ? +a.y : s.pos.y) };
      if (!Number.isFinite(dest.x) || !Number.isFinite(dest.y)) return fail('Gidilemez.');
      startWalk(s, dest, a.b || null);
      return OK;
    }
    case 'bolgeBaskin': return bolgeBaskin(s, a, pushCard);
    case 'ekipAl': return ekipAl(s, a);
    case 'aileHediye': return aileHediye(s, a);
    case 'isGir': return isGir(s, a);
    case 'isBirak': return isBirak(s);
    case 'isletmeAl': return isletmeAl(s, a);
    case 'bolgeIs': return bolgeIs(s, a);
    case 'bolgeAdam': return bolgeAdam(s, a);
    case 'bolgeYatirim': return bolgeYatirim(s, a);
    case 'bolgeHarac': return bolgeHarac(s, a);
    case 'choose': return choose(s, a.card, a.opt);
    case 'setPrice': s.biz.meyhane.price = clamp(+a.v, 0.7, 1.3); return OK;
    case 'setLaunder': s.launderPct = clamp(+a.v, 0, 150); return OK;
    case 'buildDist':
      if (!s.flags.ustaKnown) return fail('Önce bu işi bilen biri lazım.');
      if (di.built) return fail('Zaten kurulu.');
      if (!spend(s, C.BUILD, 'dirty')) return fail('Para yetmiyor.');
      di.built = true;
      log(s, `Bodruma imalathane kuruldu (${money(C.BUILD)}).`, 'good', 'Üretim için bir usta ve hacim ayarı gerekir.');
      return OK;
    case 'upgradeHidden':
      if (!di.built || di.hiddenRoom) return fail('Yapılamaz.');
      if (!spend(s, C.HIDDEN_ROOM, 'dirty')) return fail('Para yetmiyor.');
      di.hiddenRoom = true;
      log(s, 'Bodruma çift duvar örüldü. Gizlilik 0,50 → 0,75: aynı üretim yarı yarıya iz bırakır.', 'good');
      return OK;
    case 'setVolume':
      if (!di.built) return fail('İmalathane yok.');
      di.volume = clamp(Math.round(+a.v), 0, C.VOL_MAX); return OK;
    case 'hideGoods':
      if (!di.built) return fail('Saklanacak bir şey yok.');
      if (s.t < di.hiddenUntil) return fail('Mal zaten saklı.');
      hideGoods(s); return OK;
    case 'hire': {
      if (!canHire(s, a.id)) return fail('Şu an işe alınamaz.');
      const c = s.chars[a.id];
      c.employed = true; c.job = c.hire; c.sadakat = 50;
      log(s, `${c.ad} işe alındı (${c.rol}, ayda $${c.maas}).`, 'good');
      return OK;
    }
    case 'fire': {
      const c = s.chars[a.id];
      if (!c || !c.employed || a.id === 'nuri') return fail('Yapılamaz.');
      c.employed = false;
      addMod(s, a.id, 'Onu kovdun', -30, 1);
      log(s, `${c.ad} işten çıkarıldı.`, 'warn');
      loseDost(s, a.id, 'işten çıkardın');
      if (a.id === 'selim') addMod(s, 'zehra', 'Oğlunu kovdun', -20, 1);
      if (c.job === 'usta' && rnd(s) < 0.3) s.pendingEvidence.push({ v: 8, why: `${c.ad} kovulunca bildiklerini anlattı.` });
      return OK;
    }
    case 'setSalary': {
      const c = s.chars[a.id];
      if (!c || !c.employed) return fail('Yapılamaz.');
      c.maas = clamp(Math.round(+a.v), Math.round(c.piyasa * 0.5), c.piyasa * 2); return OK;
    }
    case 'gift': {
      const c = s.chars[a.id];
      if (!c || c.dead) return fail('Yapılamaz.');
      const day = dateOf(s.t).day;
      if ((c.giftDay ?? -99) + 10 > day) return fail('Daha yeni hediye verdin; şimdi tekrarı rüşvet gibi durur.');
      const cost = bond(s, a.id) === 'dost' ? 25 : 50; // dostluk iyilik maliyetini yarıya indirir
      if (!spend(s, cost, 'dirty')) return fail('Para yetmiyor.');
      c.giftDay = day;
      addMod(s, a.id, 'Hediye gönderdin', 8, 2);
      addOrtak(s, a.id);
      return OK;
    }
    case 'feast': {
      const c = s.chars[a.id];
      if (!c || c.dead || c.jailed) return fail('Yapılamaz.');
      const day = dateOf(s.t).day;
      if ((c.feastDay ?? -99) + 8 > day) return fail('Bu kişiyle daha yeni yemek yedin.');
      if (!spend(s, 150, 'dirty')) return fail('Para yetmiyor ($150).');
      c.feastDay = day;
      addMod(s, a.id, 'Sofranda ağırladın', 6, 2);
      addOrtak(s, a.id);
      fame(s, 'yeralti', 'golge', { t: 1 }, 1);
      log(s, `${c.ad} ile yemek yedin.`, 'good', 'Birlikte yaşanan her olay dostluğa sayılır (3 ortak olay + görüş ≥ 40 = dost).');
      return OK;
    }
    case 'donate': {
      const amt = clamp(Math.round(+a.amount), 100, 600);
      const day = dateOf(s.t).day;
      if ((s.flags.donateDay ?? -99) + 5 > day) return fail('Daha yeni bağış yaptın.');
      if (!spend(s, amt, 'dirty')) return fail('Para yetmiyor.');
      s.flags.donateDay = day;
      fame(s, 'halk', 'cephe', { t: 3, i: 8 * amt / 300 }, 0.8);
      log(s, `Mahalleye ${money(amt)} bağış yaptın.`, 'good', 'Semt halkında iyiliğin yükseldi (yerleşik ün zor değişir: yükseldikçe etkisi azalır).');
      return OK;
    }
    case 'defterAc': return defterAc(s, a.hedef, a.neden, a.agirlik);
    case 'defterKapat': return defterKapat(s, a.id, a.yol);
    case 'kredi': {
      const amt = clamp(Math.round(+a.amount), 1000, 4000);
      const day = dateOf(s.t).day;
      if ((s.flags.krediDay ?? -99) + 10 > day) return fail('Başvurunun üzerinden 10 gün geçmeli.');
      if (listede(s, 'banka')) return fail('Banka kara listesindesin.');
      if (s.kredi.principal > 0) return fail('Önceki krediyi kapat.');
      const e = krediInfo(s, amt);
      s.flags.krediDay = day;
      if (rnd(s) < e.p) {
        s.cash.clean += amt; s.kredi.principal = amt; s.kredi.installment = e.installment; s.kredi.missed = 0;
        addMod(s, 'selahattin', 'Kredi aldın', 3, 2);
        log(s, `Harbor Trust ${money(amt)} kredi verdi (6 taksit, aylık faiz %${(S0.KREDI_FAIZ * 100).toFixed(1)}).`, 'good', `Onay ihtimali %${Math.round(e.p * 100)} idi.`);
      } else {
        addMod(s, 'selahattin', 'Kredi talebin reddedildi', -3, 2);
        log(s, 'Harbor Trust kredi talebini reddetti.', 'bad', `Onay ihtimali %${Math.round(e.p * 100)} idi.`);
      }
      return OK;
    }
    case 'hisse': {
      const pct = clamp(Math.round(+a.pct), 5, 20);
      const L = s.kurum.liman;
      if (L.hisse + pct > S0.HISSE_MAX) return fail(`En çok %${S0.HISSE_MAX} pay alabilirsin.`);
      const cost = pct * S0.HISSE_FIYAT * (a.kirli ? 1.3 : 1);
      if (a.kirli) {
        if (!spend(s, cost, 'dirty')) return fail('Para yetmiyor.');
        s.maliSuphe += cost / 200;
      } else if (!spend(s, cost, 'clean')) return fail('Temiz paran yetmiyor.');
      L.hisse += pct;
      addMod(s, 'selahattin', 'Ortak oldun', 6, 2);
      log(s, `Harbor Trust'tan %${pct} pay aldın (toplam %${L.hisse}, ${money(cost)}${a.kirli ? ', kirli para %30 komisyonla' : ''}).`, 'good',
        L.hisse >= 25 ? 'Yönetim kurulunda koltuğun var: kredi onayı +1,0.' : 'Her ay payın kadar temettü gelir (temiz para).');
      return OK;
    }
    case 'hisseSat': {
      const L = s.kurum.liman;
      const pct = Math.min(L.hisse, clamp(Math.round(+a.pct), 5, 20));
      if (pct <= 0) return fail('Hissen yok.');
      const got = pct * S0.HISSE_FIYAT * 0.8;
      L.hisse -= pct; s.cash.clean += got;
      log(s, `Harbor Trust payından %${pct} sattın (${money(got)}; %20 iskonto).`, 'warn');
      return OK;
    }
    case 'ahitIste': {
      if (s.unvan.ahit) return fail('Zaten Ahdin var.');
      if (s.kurum.karaca.redd && opinion(s, 'orhan').total < 0) return fail('Vincent seninle konuşmaz: önce gönlünü almalısın (görüşü 0\'ın üstüne çıkmalı).');
      kabulAhit(s, S0.HARAC, 'Marchetti Ailesi\'ne kendin gidip Ahit istedin.');
      s.kurum.karaca.redd = false;
      return OK;
    }
    case 'ahitBoz': {
      const u = s.unvan;
      if (!u.ahit) return fail('Ahdin yok.');
      const st = stressFor(s.patron, 'ahitBoz');
      u.ahit = null; u.tanindi = false;
      s.kurum.karaca.redd = true;
      addMod(s, 'orhan', 'Ahdi bozdun', -40, 1);
      fame(s, 'yeralti', 'golge', { t: 2, k: 2 }, 1);
      if (st.total) addStress(s, st.total, st.why.join(', '));
      log(s, 'Marchetti Ailesi ile Ahdi bozdun. Artık himaye yok, ama haraç da yok.', 'bad', 'Vincent bunu düşmanlık sayar: baskı artacak.');
      return OK;
    }
    case 'bribe': {
      const r = s.chars.rifat;
      const amt = clamp(Math.round(+a.amount), 20, 1000);
      if (s.t - r.bribeAt < 10 * DAY) return fail('Dolan\'la daha yeni görüştün. Sık gidersen göze batar.');
      if (s.cash.dirty + s.cash.clean < amt) return fail('Para yetmiyor.');
      const est = estimateBribe(s, amt);
      r.bribeAt = s.t;
      if (rnd(s) < est.p) {
        spend(s, amt, 'dirty');
        s.dosya = Math.max(0, s.dosya - est.effect); s.stage = stageIdx(s);
        addMod(s, 'rifat', 'Elini sıcak tuttun', 5, 2);
        log(s, `Dolan zarfı aldı. Dosyadan birkaç evrak "kayboldu": Dosya −${Math.round(est.effect)}.`, 'good', `Kabul ihtimali %${Math.round(est.p * 100)} idi.`);
      } else {
        addMod(s, 'rifat', 'Ona rüşvet teklif ettin', -8, 2);
        s.attBoost += 5;
        log(s, 'Dolan zarfı masaya geri itti. "Bunu görmemiş olayım."', 'bad', `Kabul ihtimali %${Math.round(est.p * 100)} idi. Polis Dikkati +5.`);
      }
      return OK;
    }
    case 'payDebt': {
      const amt = Math.min(+a.amount, s.debt.principal);
      if (amt <= 0 || s.cash.clean < amt) return fail('Temiz paran yetmiyor.');
      s.cash.clean -= amt; s.debt.principal -= amt;
      log(s, `Borçtan ${money(amt)} erken ödendi.`, 'good');
      if (s.debt.principal < 1) { s.debt.principal = 0; s.debt.missed = 0; log(s, 'Babanın borcu bitti.', 'good'); }
      return OK;
    }
    case 'rest': {
      const day = dateOf(s.t).day;
      if ((s.flags.restDay ?? -99) + 5 > day) return fail('Daha yeni dinlendin.');
      if (!spend(s, 100, 'clean')) return fail('Temiz paran yetmiyor.');
      s.flags.restDay = day;
      s.patron.stres = Math.max(0, s.patron.stres - 20);
      log(s, 'Lily\'yi alıp sahile indin. Stres −20.', 'good');
      return OK;
    }
    default: return fail('Bilinmeyen eylem.');
  }
}
