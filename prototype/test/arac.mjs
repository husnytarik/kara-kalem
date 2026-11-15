// Araba testi: node test/arac.mjs
import { newGame, advance, act, walkMinutes } from '../src/core/sim.js';
import { kolaylik, yakitFiyat, bakimGider, arizaP100 } from '../src/core/arac.js';
import { DAY } from '../src/core/util.js';
let bad = 0;
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };
{
  const s = newGame(4); s.mesafe = true; s.cash.clean = 3000;
  const yaya = walkMinutes(s, 'karakol');
  check(!act(s, { type: 'aracAl', tip: 'packard' }).ok, 'paran yetmeden packard');
  check(act(s, { type: 'aracAl', tip: 'ford' }).ok, 'ford alınamadı');
  const araba = walkMinutes(s, 'karakol');
  check(araba < yaya * 0.6, `araba hızlandırmadı ${yaya}->${araba}`);
  const y0 = s.arac.yakit;
  act(s, { type: 'goto', b: 'karakol' }); advance(s, 300);
  check(s.arac.yakit < y0, 'yakıt yanmadı');
  console.log(`  yaya ${yaya} dk, araba ${araba} dk, yakıt ${y0}->${s.arac.yakit.toFixed(1)}`);
  s.arac.yakit = 20; const ar = walkMinutes(s, 'ev');
  act(s, { type: 'aracSur', v: false });
  check(walkMinutes(s, 'ev') > ar * 1.7, 'yaya moduna geçmedi');
  s.arac.yakit = 0; act(s, { type: 'aracSur', v: true });
  const w = walkMinutes(s, 'karakol');
  check(w >= yaya - 1, 'yakıtsız araba hızlı');
  check(act(s, { type: 'benzinAl' }).ok && s.arac.yakit > 5, 'benzin alınamadı');
  const sat = s.cash.clean; check(act(s, { type: 'aracSat' }).ok && s.cash.clean > sat, 'satılamadı');
}
{ // kolaylık: güç, ekip, para büyüdükçe azalır
  const a = newGame(4); a.arac.tip = 'ford';
  const b = newGame(4); b.arac.tip = 'ford'; b.bolge.ekip = 8; b.cash.clean = 20000;
  for (const id of ['southside', 'eastside', 'flats', 'downtown']) b.bolge.list[id].inf = { oyuncu: 60 };
  check(kolaylik(b) > kolaylik(a) + 0.7, `kolaylık ${kolaylik(a)} ${kolaylik(b)}`);
  check(yakitFiyat(b) < yakitFiyat(a) * 0.5, 'yakıt ucuzlamadı');
  check(bakimGider(b) < bakimGider(a) && arizaP100(b) < arizaP100(a) * 0.4, 'bakım/arıza azalmadı');
  console.log(`  kolaylık ${kolaylik(a).toFixed(2)} → ${kolaylik(b).toFixed(2)} · yakıt ${yakitFiyat(a).toFixed(2)}→${yakitFiyat(b).toFixed(2)} · bakım ${bakimGider(a)}→${bakimGider(b)}`);
}
{ // aylık bakım ve uzun koşu
  const s = newGame(6); s.mesafe = true; s.cash.clean = 3000; act(s, { type: 'aracAl', tip: 'buick' });
  const c0 = s.cash.clean + s.cash.dirty;
  for (let i = 0; i < 30; i++) { act(s, { type: 'goto', b: i % 2 ? 'karakol' : 'ev' }); advance(s, DAY); }
  check(Number.isFinite(s.arac.yakit) && s.arac.yakit >= 0, 'yakıt bozuk');
  console.log('  30 günde yol', Math.round(s.arac.yol), 'px, yakıt', s.arac.yakit.toFixed(1));
}
console.log(bad ? `araba testi ${bad} HATA` : 'araba testi temiz');
process.exit(bad ? 1 : 0);
