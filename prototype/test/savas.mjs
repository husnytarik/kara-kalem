// Savaş katmanı testi: node test/savas.mjs
// Ekip, tanınırlık, pusu, baskın, düşman baskını, yaralanma/kapanma, determinizm.
import { newGame, advance, act, cardView, PLACES, BOLGELER } from '../src/core/sim.js';
import { hakimOf } from '../src/core/bolge.js';
import { pusuP, pusuBedel } from '../src/core/savas.js';
import { DAY } from '../src/core/util.js';

let bad = 0;
const BOLGE_NOKTA = { flats: PLACES[BOLGELER.flats.merkez] || BOLGELER.flats.merkez };
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };
const fin = (s, tag) => {
  check(Number.isFinite(s.cash.clean) && Number.isFinite(s.cash.dirty), `${tag}: para NaN`);
  for (const [id, b] of Object.entries(s.bolge.list)) {
    check(b.tan >= 0 && b.tan <= 100 && Number.isFinite(b.tan), `${tag} ${id}: tan ${b.tan}`);
    check(Object.values(b.inf).reduce((a, x) => a + x, 0) <= 100.0001, `${tag} ${id}: nüfuz toplamı`);
  }
  check(s.bolge.ekip >= 0 && s.bolge.ekip <= 8, `${tag}: ekip ${s.bolge.ekip}`);
};
const kartlari = (s) => { for (const c of [...s.cards]) { const v = cardView(s, c); act(s, { type: 'choose', card: c.id, opt: v.options[v.def]?.enabled ? v.def : v.options.findIndex((o) => o.enabled) }); } };

// 1) ekip alma/salma
{
  const s = newGame(5); s.mesafe = true; s.cash.dirty = 2000;
  const r = act(s, { type: 'ekipAl', d: 1 });
  check(r.ok && s.bolge.ekip === 1, 'ekip alınamadı: ' + r.msg);
  for (let i = 0; i < 12; i++) act(s, { type: 'ekipAl', d: 1 });
  check(s.bolge.ekip === 8, 'ekip tavanı: ' + s.bolge.ekip);
  act(s, { type: 'ekipAl', d: -1 });
  check(s.bolge.ekip === 7, 'ekip salma');
  fin(s, 'ekip');
}

// 2) pusu riski: ekip büyüdükçe düşer, düşman bölgede > 0
{
  const s = newGame(5); s.mesafe = true;
  const p0 = pusuP(s, 'flats').p;
  s.bolge.ekip = 6;
  const p6 = pusuP(s, 'flats').p;
  check(p0 > 0, 'düşman bölgede pusu riski yok');
  check(p6 < p0 / 2, `ekip riski azaltmıyor ${p0} → ${p6}`);
  check(pusuP(s, 'hilltop').p >= 0, 'hilltop riski negatif');
}

// 3) pusu çözümleri: her seçenek terminal sonuç verir, kart kalmaz, sonsuz döngü yok
for (const sec of [0, 1, 2]) {
  let ölüm = 0, yaralı = 0, ok = 0;
  for (let seed = 1; seed <= 60; seed++) {
    const s = newGame(seed); s.mesafe = true; s.cash.dirty = 3000; s.bolge.ekip = seed % 5;
    s.pos = { x: PLACES.ev.x + 400, y: PLACES.ev.y }; // uzak
    // pusuyu elle kurmak için uygun bir düşman bölge
    // zaman ilerleterek doğal pusu bekle (düşman bölgede)
    for (let g = 0; g < 400 && !s.cards.some((c) => c.ev === 'pusu') && !s.over; g++) {
      s.pos = { ...BOLGE_NOKTA.flats };
      advance(s, 1 * 3600);
    }
    const c = s.cards.find((x) => x.ev === 'pusu');
    if (!c) continue;
    s.cash.dirty = Math.max(s.cash.dirty, 3000);
    const r = act(s, { type: 'choose', card: c.id, opt: sec });
    check(r.ok !== false, `pusu seçenek ${sec}: ${r.msg}`);
    check(!s.cards.some((x) => x.ev === 'pusu'), 'pusu kartı kalmadı');
    if (s.over && s.over.kind === 'olum') ölüm++; else if (s.bolge.yarali > s.t) yaralı++; else ok++;
    fin(s, `pusu${sec}#${seed}`);
  }
  console.log(`pusu seçenek ${sec}: sağ ${ok}, yaralı ${yaralı}, ölüm ${ölüm}`);
}

// 4) oyuncu baskını + düşman baskını, uzun mesafe fuzz
let baskinKazan = 0, baskinKaybet = 0, ölümler = 0, kapanma = 0;
for (let seed = 1; seed <= 30; seed++) {
  const s = newGame(seed); s.mesafe = false; s.cash.dirty = 5000; s.cash.clean = 3000;
  const hedefler = ['downtown', 'eastside', 'flats'];
  for (let ay = 0; ay < 24 && !s.over; ay++) {
    advance(s, 10 * DAY);
    kartlari(s);
    s.cash.dirty = Math.max(s.cash.dirty, 1500);
    if (s.bolge.ekip < 5) act(s, { type: 'ekipAl', d: 1 });
    act(s, { type: 'bolgeIs', b: 'southside', kind: 'himaye' });
    const h = hedefler[ay % hedefler.length];
    const önce = s.bolge.list[h].inf.oyuncu;
    if (s.bolge.ekip < 8) { s.bolge.ekip = Math.min(8, s.bolge.ekip + 1); }
    const r = act(s, { type: 'bolgeBaskin', b: h });
    if (r.ok) { if (s.bolge.list[h].inf.oyuncu > önce) baskinKazan++; else baskinKaybet++; }
    if (s.t < s.bolge.kapali) kapanma++;
    fin(s, `baskın#${seed} ay${ay}`);
  }
  if (s.over && s.over.kind === 'olum') ölümler++;
}
console.log(`oyuncu baskını: kazanılan ${baskinKazan}, kaybedilen ${baskinKaybet} · ölüm ${ölümler} · kapanma gözlemi ${kapanma}`);
check(baskinKazan + baskinKaybet > 20, 'baskın hiç yapılamadı');

// 5) determinizm
{
  const koş = () => { const s = newGame(77); s.mesafe = true; s.cash.dirty = 4000; s.bolge.ekip = 3; for (let g = 0; g < 60; g++) { s.pos = { ...BOLGE_NOKTA.flats }; advance(s, DAY); kartlari(s); } return JSON.stringify(s); };
  check(koş() === koş(), 'determinizm bozuk');
}

console.log(bad ? `SORUN: ${bad}` : 'savaş testi temiz');
process.exit(bad ? 1 : 0);
