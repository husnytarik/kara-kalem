// Zafer yolları testi: node test/zafer.mjs
import { newGame, advance, act } from '../src/core/sim.js';
import { PLACES } from '../src/core/world.js';
import { DAY } from '../src/core/util.js';
let bad = 0;
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };
{ // dürüst iş
  const s = newGame(3); s.cash.clean = 60000; s.debt.principal = 0; s.debt.installment = 0;
  const ids = Object.values(PLACES).filter((p) => s.isy.list[p.id] && p.bolge === 'southside').slice(0, 4).map((p) => p.id);
  for (const id of ids) check(act(s, { type: 'isyeriAl', hedef: id }).ok, 'alınamadı');
  advance(s, 25 * DAY);
  check(s.over && s.over.kind === 'zafer', 'dürüst zafer gelmedi: ' + JSON.stringify(s.over) + ' dosya ' + s.dosya);
  console.log('  dürüst iş:', s.over ? s.over.text.slice(0, 40) : '-');
}
{ // hâkimiyet
  const s = newGame(3); s.cash.clean = 5000;
  for (const id of ['southside', 'eastside', 'flats', 'docks', 'downtown']) s.bolge.list[id].inf = { oyuncu: 70 };
  advance(s, 30 * DAY);
  check(s.over && s.over.kind === 'zafer', 'hâkimiyet gelmedi');
}
{ // başkanlık: 2. yıl 12. ay
  const s = newGame(3); s.cash.clean = 20000; s.debt.principal = 0; s.debt.installment = 0;
  for (const id of ['southside', 'eastside']) { s.bolge.list[id].inf = { oyuncu: 70 }; s.bolge.list[id].sev = 90; }
  check(act(s, { type: 'kampanya', amount: 6000 }).ok, 'kampanya fonu');
  check(!act(s, { type: 'kampanya', amount: 999999 }).ok, 'fon fazla');
  const ay0 = s.t;
  advance(s, 12 * 24 * 10 * DAY / 1 * 0 + 24 * 30 * DAY); // 2 yıl
  console.log('  başkanlık sonucu:', s.over ? s.over.kind : 'ayakta');
}
console.log(bad ? `${bad} hata` : 'zafer testi temiz');
