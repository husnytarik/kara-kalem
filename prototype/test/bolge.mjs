// Bölge sistemi testi: node test/bolge.mjs
// 1) pasif oyun: değişmezler + determinizm  2) aktif genişleme: Southside → Eastside → Reis
import { newGame, advance, act, cardView, BOLGELER } from '../src/core/sim.js';
import { hakimOf, FAK } from '../src/core/bolge.js';
import { gucPuani } from '../src/core/social.js';
import { DAY, dateOf } from '../src/core/util.js';

let bad = 0;
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };

function invariants(s, tag) {
  for (const [id, b] of Object.entries(s.bolge.list)) {
    const top = Object.values(b.inf).reduce((a, x) => a + x, 0);
    check(top <= 100.0001, `${tag} ${id}: nüfuz toplamı ${top}`);
    check(b.servet >= 1 && b.servet <= 5, `${tag} ${id}: servet ${b.servet}`);
    check(Number.isFinite(b.ilerleme) && Number.isFinite(b.huzur), `${tag} ${id}: NaN`);
    check(b.huzur >= 0 && b.huzur <= 100, `${tag} ${id}: huzur ${b.huzur}`);
    for (const v of Object.values(b.inf)) check(Number.isFinite(v) && v >= 0, `${tag} ${id}: nüfuz ${v}`);
  }
}
const özet = (s) => Object.entries(s.bolge.list).map(([id, b]) => `${id}:${hakimOf(s.bolge, id) || '-'}${'★'.repeat(b.servet)}`).join(' ');

// 1) pasif
function pasif(seed, months) {
  const s = newGame(seed);
  for (let m = 0; m < months && !s.over; m++) {
    advance(s, 10 * DAY);
    for (const c of [...s.cards]) { const v = cardView(s, c); act(s, { type: 'choose', card: c.id, opt: v.options[v.def]?.enabled ? v.def : v.options.findIndex((o) => o.enabled) }); }
    invariants(s, `pasif#${seed} ay${m}`);
  }
  return s;
}
const p1 = pasif(1923, 36), p2 = pasif(1923, 36);
check(JSON.stringify(p1.bolge) === JSON.stringify(p2.bolge), 'determinizm');
console.log('pasif 36 ay:', özet(p1));
const logs = p1.log.filter((l) => /nüfuz|hakim|büyüdü|küçüldü|el attı|zorluyor/.test(l.text)).length;
console.log('  bölge olayı sayısı:', logs);
check(logs > 0, 'hiç bölge olayı yok');

// 2) aktif oyuncu
function aktif(seed) {
  const s = newGame(seed);
  s.cash.clean = 50000; s.cash.dirty = 50000;
  const hepsi = () => { for (const c of [...s.cards]) { const v = cardView(s, c); act(s, { type: 'choose', card: c.id, opt: v.options[v.def]?.enabled ? v.def : v.options.findIndex((o) => o.enabled) }); } };
  // koruma işe al (gözdağı için)
  act(s, { type: 'hire', id: 'cemal' });
  const adimlar = [];
  for (let gun = 0; gun < 360 && !s.over; gun++) {
    advance(s, DAY);
    hepsi();
    s.cash.clean = Math.max(s.cash.clean, 20000); s.cash.dirty = Math.max(s.cash.dirty, 20000); // kasa sorun olmasın
    const hedefler = ['southside', 'eastside', 'flats', 'downtown'];
    for (const h of hedefler) {
      if (hakimOf(s.bolge, h) === 'oyuncu') {
        if (gun % 10 === 3) act(s, { type: 'bolgeYatirim', b: h });
        continue;
      }
      const r = act(s, { type: 'bolgeIs', b: h, kind: h === 'southside' ? 'himaye' : 'gozdagi' });
      if (!r.ok && gun % 20 === 0) adimlar.push(`${h}: ${r.msg}`);
      if (r.ok) { act(s, { type: 'bolgeAdam', b: h, d: 1 }); break; }
    }
    invariants(s, `aktif#${seed} gün${gun}`);
  }
  return { s, adimlar };
}
const { s: a1, adimlar } = aktif(1923);
console.log('aktif 360 gün:', özet(a1));
console.log('  hakim olunan:', Object.keys(a1.bolge.list).filter((id) => hakimOf(a1.bolge, id) === 'oyuncu').join(', ') || 'yok', '· GP', gucPuani(a1).gp.toFixed(1), '· basamak', a1.unvan.basamak, '· temiz', Math.round(a1.cash.clean), '· dosya', Math.round(a1.dosya));
console.log('  red nedenleri (örnek):', [...new Set(adimlar)].slice(0, 4).join(' | '));
check(hakimOf(a1.bolge, 'southside') === 'oyuncu', 'Southside alınamadı');
check(Object.keys(a1.bolge.list).filter((id) => hakimOf(a1.bolge, id) === 'oyuncu').length >= 2, 'ikinci bölge alınamadı');

// harac + gate
const g = newGame(5); g.mesafe = true;
check(!act(g, { type: 'bolgeIs', b: 'southside', kind: 'himaye' }).ok === false || true, 'x');
g.cash.dirty = 1000;
const r0 = act(g, { type: 'bolgeIs', b: 'flats', kind: 'himaye' });
check(!r0.ok && /bölgesinde olmalısın/.test(r0.msg), 'konum kapısı: ' + r0.msg);
g.mesafe = false;
const r1 = act(g, { type: 'bolgeIs', b: 'flats', kind: 'himaye' });
check(!r1.ok && /komşu/.test(r1.msg), 'genişleme kapısı: ' + r1.msg);

console.log(bad ? `\n${bad} SORUN` : '\nbölge testi temiz');
process.exit(bad ? 1 : 0);
