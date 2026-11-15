// İş yeri ve adam testi: node test/isyeri.mjs
import { newGame, advance, act } from '../src/core/sim.js';
import { TURLER, turOf, kontrol, haftalik, adamEsitle } from '../src/core/isyeri.js';
import { PLACES } from '../src/core/world.js';
import { DAY } from '../src/core/util.js';
let bad = 0;
const check = (c, m) => { if (!c) { bad++; console.log('  HATA:', m); } };
{ // türler
  const tur = {}; for (const id of Object.keys(newGame(1).isy.list)) tur[turOf(PLACES[id].ad)] = (tur[turOf(PLACES[id].ad)] || 0) + 1;
  console.log('  tür dağılımı', JSON.stringify(tur));
  check(Object.keys(TURLER).every((t) => t === 'resmi' || tur[t] > 0), 'bir tür hiç yok');
  check(newGame(1).isy.list.a12 === undefined && newGame(1).isy.list.meyhane === undefined, 'özel bina iş yeri oldu');
}
const southside = (s) => Object.values(PLACES).filter((p) => p.bolge === 'southside' && s.isy.list[p.id]);
{ // adam senkronu ve haraç
  const s = newGame(5); s.cash.dirty = 5000;
  const hedef = southside(s).find((p) => s.isy.list[p.id].tur === 'esnaf').id;
  check(!act(s, { type: 'gorev', hedef, gorev: 'haraclan' }).ok, 'adamsız görev kabul edildi');
  s.bolge.ekip = 3; adamEsitle(s);
  check(s.isy.adam.length === 3, 'adam listesi ekiple eşitlenmedi');
  check(!act(s, { type: 'gorev', hedef: 'a12', gorev: 'haraclan' }).ok, 'karakola haraç');
  const r = act(s, { type: 'gorev', hedef, gorev: 'haraclan' }); check(r.ok, 'görev verilemedi ' + r.msg);
  check(!act(s, { type: 'gorev', hedef, gorev: 'haraclan' }).ok, 'aynı yere iki görev');
  advance(s, 600);
  console.log('  haraç sonucu', s.isy.list[hedef].haracli, s.isy.gorevler.length, 'kontrol', kontrol(s, hedef));
  check(s.isy.gorevler.length === 0, 'görev çözülmedi');
}
{ // çok deneme: yüksek becerili adam haraç bağlar, gelir birikir ve toplanır
  const s = newGame(6); s.cash.dirty = 50000; s.bolge.ekip = 4; adamEsitle(s);
  for (const a of s.isy.adam) { a.yumruk = 80; a.bicak = 70; a.zeka = 70; }
  const ids = southside(s).filter((p) => s.isy.list[p.id].tur === 'esnaf').slice(0, 3).map((p) => p.id);
  let ok = 0;
  for (const id of ids) { act(s, { type: 'gorev', hedef: id, gorev: 'haraclan' }); }
  advance(s, 600);
  for (const id of ids) if (s.isy.list[id].haracli) ok++;
  check(ok >= 2, `usta adamlar haraç bağlayamadı ${ok}/3`);
  const hid = ids.find((id) => s.isy.list[id].haracli);
  advance(s, 10 * DAY);
  const c0 = s.cash.dirty, bk = s.isy.list[hid].birikim;
  check(s.isy.list[hid].birikim > 5, 'haraç birikmedi');
  const r = act(s, { type: 'gorev', hedef: hid, gorev: 'topla' }); check(r.ok, 'toplama görevi ' + r.msg);
  advance(s, 300);
  check(s.cash.dirty > c0 - 100 && s.isy.list[hid].birikim < bk, `para gelmedi ${c0} -> ${s.cash.dirty}`);
  console.log(`  haraç ${ok}/3 · 10 günde birikim sonrası kirli para ${Math.round(c0)} → ${Math.round(s.cash.dirty)}`);
}
{ // satın alma
  const s = newGame(7); s.cash.clean = 9000;
  const id = southside(s)[0].id;
  check(act(s, { type: 'isyeriAl', hedef: id }).ok, 'satın alınamadı');
  const c0 = s.cash.clean; advance(s, 7 * DAY);
  check(s.cash.clean > c0, 'sahip olunan yer gelir vermedi');
  check(!act(s, { type: 'isyeriAl', hedef: id }).ok, 'iki kez satın alındı');
  check(!act(s, { type: 'isyeriAl', hedef: 'a12' }).ok, 'karakol satın alındı');
}
{ // eksik beceri: zayıf adam lüks yere karşı genelde kaybeder
  let kaz = 0;
  for (let sd = 1; sd <= 30; sd++) {
    const s = newGame(sd); s.cash.dirty = 5000; s.bolge.ekip = 1; adamEsitle(s);
    Object.assign(s.isy.adam[0], { yumruk: 20, bicak: 20, zeka: 20 });
    const id = Object.values(PLACES).find((p) => p.bolge === 'southside' && s.isy.list[p.id] && ['luks', 'depo'].includes(s.isy.list[p.id].tur));
    if (!id) continue;
    act(s, { type: 'gorev', hedef: id.id, gorev: 'haraclan' }); advance(s, 600);
    if (s.isy.list[id.id].haracli) kaz++;
  }
  console.log('  zayıf adam zor yerde başarı', kaz, '/ 30');
  check(kaz < 15, 'zayıf adam fazla başarılı');
}
console.log(bad ? `${bad} hata` : 'isyeri testi temiz');
