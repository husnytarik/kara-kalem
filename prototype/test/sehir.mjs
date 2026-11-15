// Şehir olayları testi: node test/sehir.mjs
import { newGame, advance, act, cardView } from '../src/core/sim.js';
import { DAY } from '../src/core/util.js';
let bad = 0;
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };
function kos(seed, gun) {
  const s = newGame(seed); s.mesafe = false;
  const gor = {}, kartlar = {};
  for (let d = 0; d < gun && !s.over; d++) {
    advance(s, DAY);
    for (const c of [...s.cards]) { kartlar[c.ev] = (kartlar[c.ev] || 0) + 1; const v = cardView(s, c); act(s, { type: 'choose', card: c.id, opt: v.options.findIndex((o) => o.enabled) }); }
    for (const i of s.sehir.isaret) gor[i.tip] = 1;
  }
  return { s, gor, kartlar };
}
const { s, gor, kartlar } = kos(3, 360);
console.log('  görülen olay türü:', Object.keys(gor).length, Object.keys(gor).join(','));
console.log('  haber sayısı (son 40):', s.sehir.haber.length, '· kartlar:', JSON.stringify(kartlar));
check(Object.keys(gor).length >= 8, 'olay çeşidi az');
check(Object.keys(kartlar).filter((k) => k.endsWith('_k')).length >= 2, 'sokak kartı çeşidi az');
for (const [id, b] of Object.entries(s.bolge.list)) for (const k of ['sev', 'kor', 'huzur', 'tan', 'ilerleme']) check(Number.isFinite(b[k]) && b[k] >= 0 && b[k] <= 100, `${id}.${k}=${b[k]}`);
check(Number.isFinite(s.cash.clean) && Number.isFinite(s.cash.dirty), 'para');
const a = kos(9, 120).s, b2 = kos(9, 120).s;
check(JSON.stringify(a.sehir) === JSON.stringify(b2.sehir), 'determinizm');
console.log(bad ? `şehir testi ${bad} HATA` : 'şehir testi temiz');
process.exit(bad ? 1 : 0);
