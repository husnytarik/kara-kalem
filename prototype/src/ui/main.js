// Tarayıcı arayüzü. Oyun kuralı içermez: durumu okur, act() ile eylem yollar, advance() ile zamanı ilerletir.
import {
  C, newGame, advance, act, cardView, canHire, marketShare, attention, attentionLines, secrecy,
  dailyIz, detectP, stageName, launderInfo, estimateBribe,
} from '../core/sim.js';
import { dateOf, fmtTime, fmtDate, money, opinion, SEASONS, DAY, clamp, staff, informed } from '../core/util.js';

const SAVE_KEY = 'eski_mahalle_v01';
const $ = (id) => document.getElementById(id);
const SVGNS = 'http://www.w3.org/2000/svg';

let s = load() || newGame();
// Hata ayıklama: ?skip=25 → sabit tohumla yeni oyun açıp 25 gün ileri sarar (kayda dokunmaz).
const DEBUG_SKIP = +new URLSearchParams(location.search).get('skip') || 0;
if (DEBUG_SKIP) { s = newGame(1923); advance(s, DEBUG_SKIP * DAY); }
const ui = { tab: 'mekan', sel: 'meyhane', person: null, modal: null, bribe: 150, pauseSeen: s.pauseReq, lastHour: -1, overShown: false };

function load() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    const st = JSON.parse(raw);
    if (st.v !== 1) return null;
    st.speed = 0;
    return st;
  } catch { return null; }
}
const save = () => { if (DEBUG_SKIP) return; try { localStorage.setItem(SAVE_KEY, JSON.stringify(s)); } catch { /* kota dolu olabilir */ } };

// ---------- küçük yardımcılar ----------
const pct = (x) => `%${Math.round(x * 100)}`;
const sign = (v) => (v > 0 ? `+${v}` : `${v}`);
const cls = (v) => (v > 0 ? 'good' : v < 0 ? 'bad' : 'dim');
const A = (obj) => `data-a='${JSON.stringify(obj)}'`;
const meter = (v, max = 100, kind = '', marks = []) =>
  `<div class="meter ${kind}"><i style="width:${clamp(v / max * 100, 0, 100)}%"></i>${marks.map((m) => `<u style="left:${m / max * 100}%"></u>`).join('')}</div>`;
const row = (k, v) => `<div class="row"><span>${k}</span><span>${v}</span></div>`;
const lines = (ls) => ls.map((l) => `<div class="row"><span class="dim">${l.k}</span><span class="${cls(l.v)}">${sign(l.v)}</span></div>`).join('');

let toastTimer = 0;
function toast(msg) {
  const t = $('toast');
  t.textContent = msg; t.hidden = false;
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => (t.hidden = true), 2600);
}

function setSpeed(v) {
  if (s.over) v = 0;
  s.speed = v;
  document.querySelectorAll('#speed button').forEach((b) => b.classList.toggle('on', +b.dataset.speed === v));
  if (v === 0) save();
}

// ---------- üst şerit ----------
function renderTop() {
  const d = dateOf(s.t);
  $('clock').innerHTML = `<b>${fmtTime(s.t)}</b>${fmtDate(s.t)} · ${SEASONS[d.season]}${d.dayInMonth === 10 ? ' · <span class="gold">Hesap Günü</span>' : ''}`;
  const st = (k, v, c = '') => `<div class="st"><small>${k}</small><b class="${c}">${v}</b></div>`;
  $('stats').innerHTML =
    st('Temiz para', money(s.cash.clean), 'good') +
    st('Kirli para', money(s.cash.dirty), 'gold') +
    st('Borç', s.debt.principal > 0 ? `${money(s.debt.principal)}${s.debt.missed ? ` <span class="bad">(${s.debt.missed}/3)</span>` : ''}` : 'yok') +
    st('Dosya', `${Math.round(s.dosya)} · ${stageName(s)}`, s.dosya >= 50 ? 'bad' : s.dosya >= 25 ? 'gold' : '') +
    st('Stres', Math.round(s.patron.stres), s.patron.stres >= 60 ? 'bad' : '') +
    (s.raid && informed(s) ? st('Baskın', `${Math.max(1, Math.ceil((s.raid.at - s.t) / DAY))} gün içinde`, 'bad') : '');
}

// ---------- harita ----------
const B = {
  meyhane: { x: 240, y: 150, w: 130, h: 78, fill: '#7a4a2a', name: 'Meyhanen', door: [305, 240] },
  rakip: { x: 470, y: 292, w: 120, h: 70, fill: '#5d4038', name: "Kâzım'ın Yeri", door: [530, 280] },
  karakol: { x: 620, y: 140, w: 110, h: 88, fill: '#3c4a5c', name: 'Karakol' },
  camasir: { x: 100, y: 292, w: 110, h: 64, fill: '#4f5a55', name: 'Çamaşırhane' },
  tefeci: { x: 80, y: 160, w: 100, h: 68, fill: '#4a3d2e', name: 'Tefeci Şakir' },
  ev: { x: 470, y: 60, w: 100, h: 70, fill: '#5a5040', name: 'Evin' },
  hacer: { x: 262, y: 62, w: 84, h: 52, fill: '#55483c', name: 'Hacer Hanım' },
};
const FILLER = [[30, 60, 90, 60], [130, 40, 90, 70], [610, 40, 120, 60], [640, 292, 110, 80], [260, 292, 130, 72], [440, 150, 130, 78], [30, 380, 150, 46], [620, 392, 130, 40]];
const PATROL = [[20, 260], [400, 260], [400, 130], [780, 130], [780, 260], [400, 260], [400, 440], [20, 440]];

function el(tag, attrs = {}, parent) {
  const e = document.createElementNS(SVGNS, tag);
  for (const k in attrs) e.setAttribute(k, attrs[k]);
  if (parent) parent.appendChild(e);
  return e;
}

const M = {};
function buildMap() {
  const svg = $('map');
  svg.innerHTML = '';
  el('rect', { width: 800, height: 520, fill: '#3b3528' }, svg);
  el('rect', { y: 460, width: 800, height: 60, fill: '#1f3a4a' }, svg); // liman
  el('rect', { x: 330, y: 452, width: 140, height: 26, fill: '#5b4a35' }, svg); // iskele
  // sokaklar
  for (const r of [[0, 240, 800, 40], [380, 0, 40, 460], [0, 122, 800, 16], [0, 432, 800, 20]]) el('rect', { x: r[0], y: r[1], width: r[2], height: r[3], fill: '#57503f' }, svg);
  for (const f of FILLER) el('rect', { x: f[0], y: f[1], width: f[2], height: f[3], fill: '#463e31', stroke: '#0004' }, svg);
  M.haze = el('circle', { cx: 305, cy: 190, r: 0, fill: '#c9a24b', opacity: 0.12 }, svg);
  M.b = {};
  for (const [id, b] of Object.entries(B)) {
    const g = el('g', { class: 'bld', 'data-b': id }, svg);
    el('rect', { class: 'body', x: b.x, y: b.y, width: b.w, height: b.h, fill: b.fill, rx: 3 }, g);
    el('rect', { x: b.x, y: b.y, width: b.w, height: 10, fill: '#0003' }, g);
    const wins = [];
    for (let i = 0; i < Math.floor(b.w / 28); i++) wins.push(el('rect', { x: b.x + 12 + i * 28, y: b.y + 20, width: 10, height: 13, fill: '#1c1812' }, g));
    const t = el('text', { x: b.x + b.w / 2, y: b.y + b.h / 2 + 12 }, g); t.textContent = b.name;
    const sub = el('text', { class: 'sub', x: b.x + b.w / 2, y: b.y + b.h / 2 + 27 }, g);
    M.b[id] = { g, wins, sub };
  }
  M.cellar = el('g', {}, svg);
  el('rect', { x: 250, y: 214, width: 34, height: 10, fill: '#1a120b', stroke: '#c9a24b', 'stroke-width': 1 }, M.cellar);
  M.smoke = [0, 1, 2].map(() => el('circle', { r: 4, fill: '#bbb', opacity: 0 }, svg));
  M.dots = Array.from({ length: 14 }, () => el('circle', { r: 3, fill: '#e9dec9', opacity: 0 }, svg));
  M.night = el('rect', { width: 800, height: 520, fill: '#070b20', opacity: 0, 'pointer-events': 'none' }, svg);
  M.glow = el('g', { 'pointer-events': 'none' }, svg);
  M.patrolLight = el('circle', { r: 16, fill: '#7da0c4', opacity: 0.18, 'pointer-events': 'none' }, svg);
  M.patrol = el('circle', { r: 5, fill: '#7da0c4', stroke: '#0b1220', 'stroke-width': 1.5, 'pointer-events': 'none' }, svg);
  M.raid = el('text', { x: 400, y: 32, 'text-anchor': 'middle', fill: '#cf5c45', 'font-size': 18, 'font-family': 'Georgia, serif', 'pointer-events': 'none' }, svg);
  svg.addEventListener('click', (e) => {
    const g = e.target.closest('.bld');
    if (!g) return;
    ui.sel = g.dataset.b; ui.tab = 'mekan';
    renderAll();
  });
}

function pathPoint(pts, u) {
  const seg = [];
  let total = 0;
  for (let i = 0; i < pts.length; i++) {
    const a = pts[i], b = pts[(i + 1) % pts.length];
    const l = Math.hypot(b[0] - a[0], b[1] - a[1]);
    seg.push(l); total += l;
  }
  let dist = (u % 1) * total;
  for (let i = 0; i < pts.length; i++) {
    if (dist <= seg[i]) {
      const a = pts[i], b = pts[(i + 1) % pts.length], k = dist / seg[i];
      return [a[0] + (b[0] - a[0]) * k, a[1] + (b[1] - a[1]) * k];
    }
    dist -= seg[i];
  }
  return pts[0];
}

const MEY_OPEN = (h) => h >= 11 || h < 1;
function renderMap(tf) {
  const d = dateOf(s.t);
  const hf = (tf % DAY) / 60;
  // gece
  let n = 0;
  if (hf >= 21 || hf < 4.5) n = 0.6; else if (hf >= 18.5) n = 0.6 * (hf - 18.5) / 2.5; else if (hf < 7) n = 0.6 * (7 - hf) / 2.5;
  M.night.setAttribute('opacity', n.toFixed(3));
  const lit = n > 0.25;
  const open = { meyhane: MEY_OPEN(d.hour), rakip: MEY_OPEN(d.hour), karakol: true, camasir: d.hour >= 8 && d.hour < 18 && !!s.biz.camasir, tefeci: d.hour >= 9 && d.hour < 18, ev: d.hour >= 18 && d.hour < 23, hacer: d.hour >= 18 && d.hour < 21 };
  for (const [id, m] of Object.entries(M.b)) {
    m.g.classList.toggle('sel', ui.sel === id);
    for (const w of m.wins) w.setAttribute('fill', open[id] && lit ? '#f2c96a' : open[id] ? '#8a7a55' : '#1c1812');
  }
  const sh = marketShare(s);
  M.b.meyhane.sub.textContent = MEY_OPEN(d.hour) ? `pay ${pct(sh.me)}` : 'kapalı';
  M.b.rakip.sub.textContent = MEY_OPEN(d.hour) ? `pay ${pct(sh.rival)}` : 'kapalı';
  M.b.camasir.sub.textContent = s.biz.camasir ? 'senin' : 'başkasının';
  M.b.karakol.sub.textContent = `dikkat ${Math.round(attention(s))}`;
  M.b.tefeci.sub.textContent = s.debt.principal > 0 ? money(s.debt.principal) : 'borç yok';
  M.b.hacer.sub.textContent = s.chars.hacer.dead ? 'boş ev' : '';

  // bodrum
  const di = s.dist;
  const hidden = s.t < di.hiddenUntil;
  M.cellar.setAttribute('opacity', di.built ? 1 : 0);
  M.haze.setAttribute('r', di.built ? Math.min(150, di.iz * 1.6) : 0);
  const prod = di.built && di.volume > 0 && !hidden && !!staff(s, 'usta');
  M.smoke.forEach((c, i) => {
    const u = ((tf / 50) + i / 3) % 1;
    c.setAttribute('cx', 267 + Math.sin(u * 6 + i) * 5); c.setAttribute('cy', 212 - u * 34);
    c.setAttribute('opacity', prod ? (0.35 * (1 - u) * (0.3 + di.volume / 60)).toFixed(2) : 0);
  });

  // müşteriler
  const w = MEY_OPEN(d.hour) ? (d.hour >= 18 ? 1 : d.hour === 0 ? 0.8 : 0.45) : 0;
  const count = Math.round(w * M.dots.length);
  const mine = sh.me / (sh.me + sh.rival);
  M.dots.forEach((c, i) => {
    if (i >= count) { c.setAttribute('opacity', 0); return; }
    const u = ((tf / 45) + i * 0.377) % 1;
    const toMe = (i * 0.618) % 1 < mine;
    const door = toMe ? B.meyhane.door : B.rakip.door;
    const from = i % 2 ? [800, 262] : [0, 258];
    const k = Math.min(1, u / 0.8);
    const x = from[0] + (door[0] - from[0]) * k;
    const y = from[1] + (door[1] - from[1]) * Math.pow(k, 4);
    c.setAttribute('cx', x); c.setAttribute('cy', y);
    c.setAttribute('opacity', u > 0.8 ? ((1 - u) / 0.2).toFixed(2) : 0.9);
  });

  // devriye
  const p = pathPoint(PATROL, tf / 300);
  M.patrol.setAttribute('cx', p[0]); M.patrol.setAttribute('cy', p[1]);
  M.patrolLight.setAttribute('cx', p[0]); M.patrolLight.setAttribute('cy', p[1]);
  M.patrolLight.setAttribute('r', 10 + attention(s) * 0.35);
  M.raid.textContent = hidden ? 'Mal saklı — üretim durdu' : '';
}

// ---------- paneller ----------
const LIVE = {
  price: () => `×${s.biz.meyhane.price.toFixed(2)}`,
  share: () => { const sh = marketShare(s); return `Pazar payın ${pct(sh.me)} · Kâzım ${pct(sh.rival)} · evde oturan ${pct(1 - sh.me - sh.rival)}`; },
  volume: () => `${s.dist.volume} şişe/gün`,
  izcalc: () => {
    const dz = dailyIz(s), eq = dz / C.IZ_DECAY, p = detectP(s, eq);
    const net = s.dist.volume * (C.LIQ_PRICE - C.LIQ_COST);
    return `Günlük iz <b>${dz.toFixed(1)}</b> → denge izi <b>${Math.round(eq)}</b> → günlük yakalanma ihtimali <b class="${p > 0.12 ? 'bad' : p > 0.06 ? 'gold' : 'good'}">${pct(p)}</b><br>` +
      `Beklenen kazanç: günde ${money(net)} kirli (talep günde ~${Math.round(C.LIQ_DEMAND * C.SEAS_LIQ[dateOf(s.t).season])} şişe)`;
  },
  launder: () => `%${s.launderPct}`,
  laundercalc: () => {
    const li = launderInfo(s);
    const over = s.launderPct > 100;
    return `Bu ayın şimdiye kadarki kapasitesi <b>${money(li.cap)}</b>. Hesap Günü'nde <b>${money(li.amt)}</b> kirli → <b>${money(li.amt * (1 - li.fee))}</b> temiz (kesinti ${pct(li.fee)}).` +
      (over ? `<br><span class="bad">Kapasitenin %${s.launderPct - 100} üstü: Mali Şüphe +${Math.round(0.02 * (s.launderPct - 100) ** 2 * (staff(s, 'muhasebeci') ? 0.5 : 1))} / ay. 50'ye varınca maliye defterleri açar.</span>` : '');
  },
  bribe: () => `${ui.bribe} ₺`,
  bribecalc: () => {
    const e = estimateBribe(s, ui.bribe);
    return `<div class="t">Tahmin kartı</div>` +
      e.factors.map((f) => `<div class="row"><span class="dim">${f.k}</span><span class="${cls(f.x)}">${f.x >= 0 ? '+' : ''}${f.x.toFixed(2)}</span></div>`).join('') +
      row('<b>Kabul ihtimali</b>', `<b>${pct(e.p)}</b>`) +
      `<div class="note">Kabul ederse Dosya −${Math.round(e.effect)}. Reddederse görüşü −8, Polis Dikkati +5. Ayda bir kez denenebilir.</div>`;
  },
};
for (const id of ['halil', 'fatma', 'nuri', 'aziz', 'cemal', 'ihsan', 'selim']) LIVE['sal_' + id] = () => `${s.chars[id].maas} ₺ <small>(piyasa ${s.chars[id].piyasa})</small>`;
const live = (k) => `<span data-live="${k}">${LIVE[k]()}</span>`;
const range = (act_, min, max, step, val, extra = {}) => `<input type="range" min="${min}" max="${max}" step="${step}" value="${val}" data-r='${JSON.stringify({ type: act_, ...extra })}'>`;

function panelMekan() {
  const d = dateOf(s.t);
  switch (ui.sel) {
    case 'meyhane': return panelMeyhane();
    case 'rakip': {
      const r = s.biz.rakip;
      return `<h3>Kâzım'ın Yeri</h3><p class="note">Aynı sokağın öbür meyhanesi. Müşteri aynı, pasta aynı.</p>` +
        row('Fiyat', `×${r.price.toFixed(2)}${s.rivalCutUntil ? ' <span class="bad">(indirimde)</span>' : ''}`) + row('Kalite', r.quality) + row('İtibar', Math.round(r.rep)) +
        `<div class="box">${LIVE.share()}</div>${personLink('kazim')}`;
    }
    case 'karakol': return `<h3>Karakol</h3>` +
      `<div class="box"><div class="t">Polis Dikkati: ${Math.round(attention(s))}</div>${lines(attentionLines(s))}</div>` +
      `<div class="box"><div class="t">Dosyan: ${Math.round(s.dosya)} / 100 · ${stageName(s)}</div>${meter(s.dosya, 100, 'red', [25, 50, 75])}` +
      `<div class="note">25 Gözetim (iz ×1,5) · 50 Soruşturma (dikkat +10) · 75 Arama emri (1–3 gün içinde baskın) · 100 Dava (oyun biter).<br>Yeni kanıt girmeyen her gün dosya ${C.DOSYA_DECAY} puan soğur.</div></div>` +
      panelBribe() + personLink('rifat');
    case 'camasir': return `<h3>Köşe Çamaşırhanesi</h3>` + (s.biz.camasir
      ? row('Bu ay ciro', money(s.biz.camasir.mRev)) + row('Bu ay gider', money(s.biz.camasir.mCost)) + `<p class="note">Senin. Nakit işi: cironun %50'si kadar kirli parayı aklayabilir (meyhanede bu oran %30).</p>`
      : `<p class="note">Başkasının. Sahibi bir gün satmak isteyebilir; kulağın açık olsun.</p>`);
    case 'tefeci': return `<h3>Tefeci Şakir</h3>` +
      row('Kalan borç', money(s.debt.principal)) + row('Aylık taksit', money(s.debt.installment)) + row('Aylık faiz', pct(C.INTEREST)) + row('Kaçan taksit', `<span class="${s.debt.missed ? 'bad' : ''}">${s.debt.missed} / 3</span>`) +
      `<p class="note">Taksit yalnızca temiz parayla ödenir. Sonraki Hesap Günü: ${11 - d.dayInMonth > 10 ? 0 : 10 - d.dayInMonth} gün sonra.</p>` +
      (s.debt.principal > 0 ? `<div class="btns">${[200, 500, 1000].map((a) => `<button ${A({ type: 'payDebt', amount: a })} ${s.cash.clean < a ? 'disabled' : ''}>Erken öde: ${a} ₺</button>`).join('')}</div>` : '') + personLink('sakir');
    case 'ev': return `<h3>Evin</h3>` + row('Yaşın', s.patron.yas) + row('Özelliklerin', s.patron.traits.join(', ')) +
      `<div class="box"><div class="t">Stres: ${Math.round(s.patron.stres)}</div>${meter(s.patron.stres, 100, 'red', [80])}<div class="note">Özelliklerine ters düşen kararlar stres yapar. 80'in üstünde sağlığın bozulur.</div>` +
      `<button ${A({ type: 'rest' })}>Leyla'yla sahile in (100 ₺ · Stres −20)</button></div>` +
      `<p class="note">Bu dünyada herkes ayda bir yaş alır. Leyla şu an ${s.chars.leyla.yas} yaşında.</p>` + personLink('leyla') + personLink('zehra') + personLink('selim');
    case 'hacer': return `<h3>Hacer Hanım'ın evi</h3><p class="note">Arka sokak. Bodrumunun penceresi onun mutfağına bakıyor.</p>` + personLink('hacer');
    default: return '';
  }
}

function panelMeyhane() {
  const m = s.biz.meyhane, di = s.dist;
  let h = `<h3>${m.name}</h3>` +
    row('Bugünkü ciro', money(s.today.rev)) + row('Bu ay ciro / gider', `${money(m.mRev)} / ${money(m.mCost)}`) +
    row('Kalite', `${m.quality}${staff(s, 'asci') ? '' : ' <span class="bad">(aşçı yok)</span>'}`) + row('İtibar', Math.round(m.rep)) +
    (staff(s, 'garson') ? '' : `<div class="note bad">Garson yok: servis kapasitesi %70.</div>`) +
    `<div class="box"><div class="row"><span>Fiyat</span>${live('price')}</div>${range('setPrice', 0.7, 1.3, 0.05, m.price)}` +
    `<div class="note">${live('share')}<br>Pahalı satarsan masa başı kâr artar ama müşteri kaçar ve itibarın zamanla düşer.</div></div>`;

  h += `<h3>Bodrum</h3>`;
  if (!s.flags.ustaKnown) h += `<p class="note">Boş, rutubetli bir bodrum. Fıçı kokusu hâlâ duvarlarda.</p>`;
  else if (!di.built) h += `<p class="note">Aziz Usta "bana bir kazan, bir de kapalı kapı yeter" diyor.</p><button class="primary" ${A({ type: 'buildDist' })}>İmalathane kur (${money(C.BUILD)})</button>`;
  else {
    const usta = staff(s, 'usta');
    const hidden = s.t < di.hiddenUntil;
    h += (usta ? row('Usta', `${usta.ad} · sadakat ${Math.round(usta.sadakat)}`) : `<div class="note bad">Usta yok: kazan kaynamıyor. ${canHire(s, 'aziz') ? `<button ${A({ type: 'hire', id: 'aziz' })}>Kör Aziz'i işe al (ayda 120 ₺)</button>` : ''}</div>`) +
      row('Stok', `${Math.round(di.stock)} / ${C.STOCK_MAX} şişe`) + row('Bu gece satış', money(s.today.liq)) + row('Gizlilik', secrecy(s).toFixed(2)) +
      (hidden ? `<div class="note bad">Mal saklı. ${Math.ceil((di.hiddenUntil - s.t) / 60)} saat sonra yeniden kurulur.</div>` : '') +
      `<div class="box"><div class="row"><span>Üretim hacmi</span>${live('volume')}</div>${range('setVolume', 0, C.VOL_MAX, 5, di.volume)}<div class="note">${live('izcalc')}</div></div>` +
      `<div class="box"><div class="t">Biriken iz: ${Math.round(di.iz)}</div>${meter(di.iz, 120, di.iz > 50 ? 'red' : '')}<div class="note">İz her gün %15 solar. Dünkü yakalanma ihtimali: ${pct(di.lastP)}.</div></div>` +
      `<div class="btns">` +
      (di.hiddenRoom ? '' : `<button ${A({ type: 'upgradeHidden' })}>Çift duvar ör (${money(C.HIDDEN_ROOM)}) — gizlilik 0,75</button>`) +
      `<button class="danger" ${A({ type: 'hideGoods' })} ${hidden ? 'disabled' : ''}>Malı sakla (3 gün üretim yok)</button></div>`;
  }
  return h;
}

function panelBribe() {
  const r = s.chars.rifat;
  if (r.dead) return '';
  const wait = Math.ceil((r.bribeAt + 10 * DAY - s.t) / DAY);
  return `<div class="box"><div class="row"><span>Rıfat'a zarf uzat</span>${live('bribe')}</div>` +
    `<input type="range" min="20" max="600" step="10" value="${ui.bribe}" data-ui="bribe">` +
    `<div data-live="bribecalc">${LIVE.bribecalc()}</div>` +
    `<button class="primary" ${A({ type: 'bribe', amount: ui.bribe })} id="bribeBtn" ${wait > 0 ? 'disabled' : ''}>${wait > 0 ? `${wait} gün sonra` : 'Teklif et'}</button></div>`;
}

function personLink(id) {
  const c = s.chars[id], o = opinion(s, id).total;
  return `<div class="person" data-p="${id}"><span class="${c.dead ? 'dead' : ''}">${c.ad} <small>${c.rol}, ${c.yas}</small></span><span class="${cls(o)}">${c.dead ? '†' : sign(o)}</span></div>`;
}

function panelKisiler() {
  const ids = Object.keys(s.chars);
  const grp = (title, f) => { const l = ids.filter(f); return l.length ? `<h3>${title}</h3>${l.map(personLink).join('')}` : ''; };
  const fam = ['zehra', 'selim', 'leyla'];
  let h = '';
  if (ui.person && s.chars[ui.person]) h += personDetail(ui.person);
  h += grp('Ekibin', (id) => s.chars[id].employed) +
    grp('İşe alınabilir', (id) => canHire(s, id)) +
    grp('Ailen', (id) => fam.includes(id) && !s.chars[id].employed) +
    grp('Şehir', (id) => !s.chars[id].employed && !canHire(s, id) && !fam.includes(id));
  return h;
}

function personDetail(id) {
  const c = s.chars[id], o = opinion(s, id);
  let h = `<div class="box"><div class="t">${c.ad} · ${c.rol} · ${c.yas} yaşında${c.dead ? ' · öldü' : ''}${c.jailed ? ' · içeride' : ''}</div>` +
    `<div class="row"><span><b>Sana görüşü</b></span><span class="${cls(o.total)}"><b>${sign(o.total)}</b></span></div>${lines(o.lines)}`;
  if (c.dead) return h + '</div>';
  if (c.employed) {
    h += `<div class="row" style="margin-top:8px"><span>Sadakat</span><span>${Math.round(c.sadakat)}</span></div>${meter(c.sadakat, 100, c.sadakat < 35 ? 'red' : 'green', [20])}` +
      `<div class="note">Sadakat her gün görüşe doğru %10 kayar. 20'nin altında işi bırakabilir.</div>` +
      `<div class="row"><span>Maaş</span>${live('sal_' + id)}</div>${range('setSalary', Math.round(c.piyasa * 0.5), c.piyasa * 2, 5, c.maas, { id })}`;
  }
  h += `<div class="btns">`;
  if (canHire(s, id)) h += `<button class="primary" ${A({ type: 'hire', id })}>İşe al (ayda ${c.maas} ₺)</button>`;
  if (c.employed && id !== 'nuri') h += `<button class="danger" ${A({ type: 'fire', id })}>İşten çıkar</button>`;
  h += `<button ${A({ type: 'gift', id })}>Hediye gönder (50 ₺ · görüş +8)</button></div>`;
  if (id === 'aziz' && !s.flags.ustaKnown) h += `<div class="note">Henüz tanışmadınız.</div>`;
  if (c.hire === 'muhasebeci') h += `<div class="note">Muhasebeci: aklama kesintisi %20 → %12, Mali Şüphe yarı hızla birikir.</div>`;
  if (c.hire === 'koruma') h += `<div class="note">Koruma: meyhanedeki kavgaları polis çağırmadan bitirir.</div>`;
  if (id === 'rifat') h += `<div class="note">${c.payroll ? 'Aylıkta: ayda 60 ₺. Baskından önce haber uçurur.' : 'Aylıkta değil. Görüşü +30\'u geçerse yine haber uçurur.'}</div>`;
  return h + '</div>';
}

function panelDefter() {
  const m = s.biz.meyhane, cm = s.biz.camasir, d = dateOf(s.t);
  let legal = 0, other = s.chars.rifat.payroll ? 60 : 0;
  for (const c of Object.values(s.chars)) if (c.employed) { if (c.legal) legal += c.maas; else other += c.maas; }
  const rev = m.mRev + (cm ? cm.mRev : 0), cost = m.mCost + (cm ? cm.mCost : 0);
  let h = `<h3>Bu ay (${d.dayInMonth}. gün / 10)</h3>` +
    row('Yasal ciro', money(rev)) + row('Mal ve işletme gideri', `−${money(cost)}`) +
    row('İçki satışı (kirli)', `<span class="gold">${money(s.month.liqRev)}</span>`) + row('Hammadde (kirli)', `−${money(s.month.prodCost)}`) +
    `<h3>Hesap Günü'nde ödenecek</h3>` +
    row('Maaşlar (kayıtlı)', money(legal)) + (other ? row('Maaşlar ve aylıklar (kayıt dışı)', money(other)) : '') +
    row('Kira', money(C.RENT)) + row('Vergi (yasal kârın %10\'u)', `~${money(Math.max(0, (rev - cost - legal - C.RENT) * C.TAX))}`) +
    (s.debt.principal > 0 ? row('Borç taksiti (temiz)', money(Math.min(s.debt.installment, s.debt.principal))) : '') +
    `<h3>Aklama</h3><div class="box"><div class="row"><span>Kapasitenin ne kadarı kullanılsın?</span>${live('launder')}</div>${range('setLaunder', 0, 150, 10, s.launderPct)}` +
    `<div class="note">${live('laundercalc')}</div>${row('Mali Şüphe', Math.round(s.maliSuphe))}${meter(s.maliSuphe, 50, 'red')}</div>`;
  if (s.history.length) {
    h += `<h3>Geçmiş aylar</h3><table><tr><th>Ay</th><th>Temiz</th><th>Kirli</th><th>Borç</th><th>Dosya</th></tr>` +
      s.history.slice(-8).reverse().map((r) => `<tr><td>${r.month + 1}</td><td>${Math.round(r.clean)}</td><td>${Math.round(r.dirty)}</td><td>${Math.round(r.debt)}</td><td>${Math.round(r.dosya)}</td></tr>`).join('') + `</table>`;
  }
  return h;
}

function panelKararlar() {
  if (!s.cards.length) return `<p class="note">Bekleyen karar yok. Sen karar vermezsen, süre dolunca Nuri Efendi senin yerine en temkinli yolu seçer.</p>`;
  return s.cards.map((c) => { const v = cardView(s, c); return `<div class="box"><div class="t">${v.title}</div><div class="note">Kalan süre: ${v.hoursLeft >= 24 ? `${Math.floor(v.hoursLeft / 24)} gün ${v.hoursLeft % 24} saat` : `${v.hoursLeft} saat`}</div><button data-card="${c.id}">Aç</button></div>`; }).join('');
}

const TABS = [['mekan', 'Mekân'], ['defter', 'Defter'], ['kisiler', 'Kişiler'], ['kararlar', 'Kararlar']];
function renderPanel() {
  $('tabs').innerHTML = TABS.map(([id, n]) => `<button data-tab="${id}" class="${ui.tab === id ? 'on' : ''}">${n}${id === 'kararlar' && s.cards.length ? `<span class="badge">${s.cards.length}</span>` : ''}</button>`).join('');
  const p = $('panel');
  const top = p.scrollTop;
  p.innerHTML = { mekan: panelMekan, defter: panelDefter, kisiler: panelKisiler, kararlar: panelKararlar }[ui.tab]();
  p.scrollTop = top;
}

function refreshLive() {
  document.querySelectorAll('[data-live]').forEach((e) => { const f = LIVE[e.dataset.live]; if (f) e.innerHTML = f(); });
  const bb = $('bribeBtn');
  if (bb) bb.setAttribute('data-a', JSON.stringify({ type: 'bribe', amount: ui.bribe }));
}

// ---------- olay akışı ----------
let logLen = -1, logLast = null;
function renderLog() {
  const last = s.log[s.log.length - 1];
  if (s.log.length === logLen && last === logLast) return;
  logLen = s.log.length; logLast = last;
  $('log').innerHTML = s.log.slice(-70).reverse().map((l) => {
    const d = dateOf(l.t);
    return `<div class="lg k-${l.kind}"><time>${d.monthInYear}/${d.dayInMonth} ${fmtTime(l.t)}</time>${l.text}${l.why ? `<span class="why">Neden: ${l.why}</span>` : ''}</div>`;
  }).join('');
}

// ---------- kart penceresi ----------
function renderModal() {
  const mo = $('modal');
  if (s.over) {
    mo.hidden = false;
    mo.innerHTML = `<div class="card"><h2>${{ dava: 'Dava', borc: 'İflas', olum: 'Son' }[s.over.kind]}</h2><div class="when">${fmtDate(s.t)}</div><p>${s.over.text}</p>` +
      `<p class="mono">Temiz ${money(s.cash.clean)} · kirli ${money(s.cash.dirty)} · borç ${money(s.debt.principal)} · Dosya ${Math.round(s.dosya)}</p>` +
      `<button class="opt" id="restart">Baştan başla</button></div>`;
    return;
  }
  const card = s.cards.find((c) => c.id === ui.modal);
  if (!card) { ui.modal = null; mo.hidden = true; return; }
  const v = cardView(s, card);
  mo.hidden = false;
  mo.innerHTML = `<div class="card"><h2>${v.title}</h2><div class="when">${fmtDate(s.t)} · ${fmtTime(s.t)}</div>` +
    `<p class="${v.ev === 'rapor' ? 'mono' : ''}">${v.text}</p>` +
    v.options.map((o, i) => `<button class="opt" ${A({ type: 'choose', card: v.id, opt: i })} ${o.enabled ? '' : 'disabled'}>${o.label}${o.hint ? `<small>${o.hint}</small>` : ''}</button>`).join('') +
    (v.ev === 'rapor' ? '' : `<div class="foot"><span>${v.hoursLeft} saat içinde karar vermezsen ${s.chars.nuri.dead ? 'iş sahipsiz kalır' : `Nuri Efendi seçer: "${v.options[v.def].label}"`}</span><button id="later">Kenara al</button></div>`) +
    `</div>`;
}

function renderAll() { renderTop(); renderPanel(); renderLog(); renderModal(); }

function doAct(a) {
  const r = act(s, a);
  if (!r.ok) toast(r.msg);
  if (a.type === 'choose' && r.ok) {
    ui.modal = null;
    const next = s.cards[0];
    if (next && s.pauseReq !== ui.pauseSeen) ui.modal = next.id;
    ui.pauseSeen = s.pauseReq;
  }
  save();
  renderAll();
}

// ---------- girdiler ----------
document.addEventListener('click', (e) => {
  const t = e.target.closest('button, .person');
  if (!t) return;
  if (t.dataset.speed !== undefined) return setSpeed(+t.dataset.speed);
  if (t.dataset.tab) { ui.tab = t.dataset.tab; return renderPanel(); }
  if (t.dataset.a) return doAct(JSON.parse(t.dataset.a));
  if (t.dataset.p) { ui.person = t.dataset.p; ui.tab = 'kisiler'; renderPanel(); $('panel').scrollTop = 0; return; }
  if (t.dataset.card) { ui.modal = +t.dataset.card; setSpeed(0); return renderModal(); }
  if (t.id === 'later') { ui.modal = null; return renderAll(); }
  if (t.id === 'restart' || t.id === 'newgame') {
    if (t.id === 'newgame' && !confirm('Kayıt silinip baştan başlanacak. Emin misin?')) return;
    s = newGame(); ui.modal = null; ui.person = null; ui.sel = 'meyhane'; ui.tab = 'mekan'; ui.pauseSeen = s.pauseReq; acc = 0;
    setSpeed(0); save(); renderAll();
  }
});
document.addEventListener('input', (e) => {
  const t = e.target;
  if (t.dataset.r) { act(s, { ...JSON.parse(t.dataset.r), v: +t.value }); refreshLive(); }
  else if (t.dataset.ui === 'bribe') { ui.bribe = +t.value; refreshLive(); }
});
document.addEventListener('change', (e) => { if (e.target.dataset.r) { save(); renderTop(); } });
document.addEventListener('keydown', (e) => {
  if (e.target.tagName === 'INPUT') return;
  if (e.code === 'Space') { e.preventDefault(); if (!$('modal').hidden) return; setSpeed(s.speed ? 0 : (ui.prevSpeed || 1)); }
  else if (['Digit1', 'Digit2', 'Digit3'].includes(e.code) && $('modal').hidden) setSpeed(+e.code.slice(5));
  else if (e.code === 'Escape' && ui.modal && !s.over) { ui.modal = null; renderAll(); }
});
window.addEventListener('beforeunload', save);

// ---------- ana döngü ----------
let prev = performance.now(), acc = 0, lastTop = 0;
function frame(now) {
  const dt = Math.min(0.25, (now - prev) / 1000); // sekme arka plandayken zaman akmaz
  prev = now;
  if (s.speed > 0 && !s.over && $('modal').hidden) {
    ui.prevSpeed = s.speed;
    acc += dt * s.speed * C.MIN_PER_SEC;
    const whole = Math.floor(acc);
    if (whole > 0) { acc -= whole; advance(s, whole); }
  }
  // otomatik duraklatma: yeni kart ya da kritik gelişme
  if (s.pauseReq !== ui.pauseSeen) {
    ui.pauseSeen = s.pauseReq;
    setSpeed(0);
    if (!ui.modal && s.cards.length) ui.modal = s.cards[s.cards.length - 1].id;
    renderAll();
  }
  if (s.over && !ui.overShown) { ui.overShown = true; setSpeed(0); renderAll(); }
  if (!s.over) ui.overShown = false;

  const hour = Math.floor(s.t / 60);
  if (hour !== ui.lastHour) {
    ui.lastHour = hour;
    const ae = document.activeElement;
    if (!(ae && ae.type === 'range')) renderPanel(); else refreshLive();
    renderLog();
    if (hour % 24 === 0) save();
  }
  if (now - lastTop > 200) { lastTop = now; renderTop(); }
  renderMap(s.t + acc);
  requestAnimationFrame(frame);
}

buildMap();
setSpeed(0);
renderAll();
if (s.cards.length) { ui.modal = s.cards[0].id; renderModal(); }
requestAnimationFrame(frame);
