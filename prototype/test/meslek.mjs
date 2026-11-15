// Meslek testi: node test/meslek.mjs
import { newGame, advance, act, walkMinutes, launderInfo } from '../src/core/sim.js';
import { MESLEKLER, kabul, maasGun, isletmeGelir, etkiGuc } from '../src/core/meslek.js';
import { DAY } from '../src/core/util.js';
let bad = 0;
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };

// 1) işe girme, maaş, beceri
{
  const s = newGame(7); s.mesafe = false;
  const r = act(s, { type: 'isGir', j: 'taksi', b: 'eastside' });
  check(r.ok, 'taksi işine girilemedi: ' + r.msg);
  const c0 = s.cash.clean;
  for (let i = 0; i < 30; i++) advance(s, DAY);
  check(s.meslek.beceri.taksi > 15, 'beceri artmadı ' + s.meslek.beceri.taksi);
  check(s.cash.clean !== c0, 'maaş yok');
  check(act(s, { type: 'isGir', j: 'hamal', b: 'docks' }).ok === false, 'çift iş');
  console.log('  30 günde taksi becerisi', s.meslek.beceri.taksi.toFixed(1));
}
// 2) tanınırlık engeli; korku hamalı sever
{
  const s = newGame(7);
  s.bolge.list.flats.tan = 90; s.bolge.list.flats.kor = 80; s.bolge.list.flats.sev = 20;
  const t = kabul(s, 'taksi', 'flats'), h = kabul(s, 'hamal', 'flats');
  check(!t.ok && h.ok, `tanınmış adam: taksi ${t.puan} hamal ${h.puan}`);
  check(act(s, { type: 'isGir', j: 'taksi', b: 'flats' }).ok === false, 'tanınmış taksici alındı');
}
// 3) kovulma
{
  const s = newGame(7); s.mesafe = false;
  act(s, { type: 'isGir', j: 'taksi', b: 'eastside' });
  s.bolge.list.eastside.tan = 100; s.bolge.list.eastside.sev = 0; s.bolge.list.eastside.kor = 90;
  advance(s, DAY * 2);
  check(!s.meslek.is, 'kovulmadı');
}
// 4) işletme
{
  const s = newGame(7); s.mesafe = false;
  check(!act(s, { type: 'isletmeAl', j: 'taksi' }).ok, 'tecrübesiz işletme alındı');
  s.meslek.beceri.taksi = 80; s.cash.clean = 5000;
  const w0 = walkMinutes(s, 'karakol'), g0 = etkiGuc(s, 'taksi');
  check(act(s, { type: 'isletmeAl', j: 'taksi' }).ok, 'işletme alınamadı');
  check(etkiGuc(s, 'taksi') > g0 * 3.9, 'işletme etkiyi katlamadı');
  check(walkMinutes(s, 'karakol') < w0, 'yürüme hızlanmadı');
  const c0 = s.cash.clean; advance(s, DAY * 10);
  check(s.cash.clean > c0 - 100, 'işletme geliri yok');
  s.meslek.beceri.katip = 90; s.cash.clean = 5000; s.cash.dirty = 3000;
  const l0 = launderInfo(s);
  act(s, { type: 'isletmeAl', j: 'katip' });
  const l1 = launderInfo(s);
  check(l1.fee < l0.fee && l1.cap > l0.cap, `büro aklamayı iyileştirmedi ${l0.fee}->${l1.fee} ${l0.cap}->${l1.cap}`);
}
console.log(bad ? `meslek testi ${bad} HATA` : 'meslek testi temiz');
process.exit(bad ? 1 : 0);
