// Arayüzsüz denge testi: node test/run.mjs [ay sayısı] [tohum]
// Üç bot politikası bir oyun yılı oynar; aylık özet basılır.
import { newGame, advance, act, cardView, canHire, C } from '../src/core/sim.js';
import { dateOf, DAY } from '../src/core/util.js';

const MONTHS = +(process.argv[2] || 12);
const SEED = +(process.argv[3] || 1923);

const POLICIES = {
  legal: { crime: false },
  hirsli: { crime: true, volume: 50, hidden: false, payroll: true, hide: true },
  temkinli: { crime: true, volume: 25, hidden: true, payroll: true, hide: true, accountant: true },
  pervasiz: { crime: true, volume: 60, hidden: false, payroll: false, hide: false, launder: 150 },
};

function pick(s, v, pol) {
  const want = {
    usta_kapida: pol.crime ? 0 : 1,
    devriye: pol.payroll ? 0 : 1,
    baskin_ihbari: pol.hide ? 0 : 2,
    komsu: 0, yangin: 0, garson_zam: 0, usta_zam: 0, yegen: 1, camasirhane: 0, tefeci: 1, kavga: 1, rakip_fiyat: 2,
  }[v.ev] ?? v.def;
  if (v.options[want]?.enabled) return want;
  if (v.options[v.def]?.enabled) return v.def;
  return v.options.findIndex((o) => o.enabled);
}

function run(name, pol, seed) {
  const s = newGame(seed);
  const rows = [];
  let cardCount = 0;
  if (pol.launder) act(s, { type: 'setLaunder', v: pol.launder });
  while (!s.over && dateOf(s.t).month < MONTHS) {
    advance(s, 60);
    for (const c of [...s.cards]) { cardCount++; act(s, { type: 'choose', card: c.id, opt: pick(s, cardView(s, c), pol) }); }
    if (pol.crime && s.flags.ustaKnown) {
      if (!s.dist.built) act(s, { type: 'buildDist' });
      if (canHire(s, 'aziz')) act(s, { type: 'hire', id: 'aziz' });
      if (s.dist.built && s.dist.volume !== pol.volume) act(s, { type: 'setVolume', v: pol.volume });
      if (pol.hidden && s.dist.built && !s.dist.hiddenRoom && s.cash.dirty > 700) act(s, { type: 'upgradeHidden' });
      if (pol.accountant && canHire(s, 'ihsan') && s.cash.dirty > 1500) act(s, { type: 'hire', id: 'ihsan' });
    }
    if (rows.length < s.history.length) {
      const h = s.history[s.history.length - 1];
      rows.push(`  ay ${String(h.month + 1).padStart(2)} | temiz ${String(Math.round(h.clean)).padStart(6)} | kirli ${String(Math.round(h.dirty)).padStart(6)} | borç ${String(Math.round(h.debt)).padStart(5)} | dosya ${String(Math.round(h.dosya)).padStart(3)} | yasal ciro ${Math.round(h.legalRev)} | içki ${Math.round(h.liqRev)} | iz ${Math.round(s.dist.iz)} | pay %${Math.round(s.share * 100)}`);
    }
  }
  console.log(`\n=== ${name} (tohum ${seed}) ===`);
  console.log(rows.join('\n'));
  const d = dateOf(s.t);
  console.log(`  SON: ${s.over ? `BİTTİ [${s.over.kind}] ${d.month + 1}. ay ${d.dayInMonth}. gün` : 'ayakta'} | kart sayısı ${cardCount} (${(cardCount / Math.max(1, d.day)).toFixed(2)}/gün) | stres ${Math.round(s.patron.stres)}`);
  const bad = s.log.filter((l) => l.kind === 'bad').slice(-4).map((l) => `    - ${l.text}`);
  if (bad.length) console.log(bad.join('\n'));
  return s;
}

for (const [name, pol] of Object.entries(POLICIES)) run(name, pol, SEED);

// Dağılım: her politika 30 tohumla; kaç oyun hangi sonla bitiyor?
console.log('\n=== 30 tohum özeti ===');
const quiet = console.log;
for (const [name, pol] of Object.entries(POLICIES)) {
  const out = {};
  let debtSum = 0, dosyaSum = 0;
  console.log = () => {};
  for (let i = 0; i < 30; i++) {
    const s = run(name, pol, 1000 + i * 7919);
    const k = s.over ? s.over.kind : 'ayakta';
    out[k] = (out[k] || 0) + 1; debtSum += s.debt.principal; dosyaSum += s.dosya;
  }
  console.log = quiet;
  console.log(`  ${name.padEnd(9)} ${JSON.stringify(out)} | ort. kalan borç ${Math.round(debtSum / 30)} | ort. dosya ${Math.round(dosyaSum / 30)}`);
}
void C; void DAY;
