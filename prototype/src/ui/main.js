// Tarayıcı arayüzü. Oyun kuralı içermez: durumu okur, act() ile eylem yollar, advance() ile zamanı ilerletir.
import {
  C, newGame, advance, act, cardView, canHire, marketShare, attention, attentionLines, secrecy,
  dailyIz, detectP, stageName, launderInfo, estimateBribe, PLACES, ROAD_Y, GATE, here, walkerAt, walkMinutes,
} from '../core/sim.js';
import { dateOf, fmtTime, fmtDate, money, opinion, SEASONS, DAY, clamp, staff, informed } from '../core/util.js';
import {
  BASAMAK, CEVRE, NEDEN, S0, perceived, gucPuani, lakap, listeler, bond, tehdit, asamaAd, memnuniyet,
  tazminatP, krediInfo, hisseDegeri,
} from '../core/social.js';
import { TRAITS, blocked } from '../core/traits.js';

const SAVE_KEY = 'kara_kalem_v03';
const $ = (id) => document.getElementById(id);
const SVGNS = 'http://www.w3.org/2000/svg';

const fresh = (seed) => { const g = newGame(seed); g.mesafe = true; return g; }; // arayüzde karakter konumu önemlidir
let s = load() || fresh();
// Hata ayıklama: ?skip=25 → sabit tohumla yeni oyun açıp 25 gün ileri sarar (kayda dokunmaz).
const DEBUG_SKIP = +new URLSearchParams(location.search).get('skip') || 0;
if (DEBUG_SKIP) { s = fresh(1923); advance(s, DEBUG_SKIP * DAY); }
const ui = { tab: 'mekan', sel: 'meyhane', person: null, modal: null, bribe: 150, pauseSeen: s.pauseReq, lastHour: -1, overShown: false, dHedef: 'kazim', dNeden: 'Hakaret', dAg: 2 };

function load() {
  try {
    const raw = localStorage.getItem(SAVE_KEY);
    if (!raw) return null;
    const st = JSON.parse(raw);
    if (st.v !== 3) return null;
    st.speed = 0; st.mesafe = true;
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
    st('Mevki', `${BASAMAK[s.unvan.basamak].ad}${lakap(s) ? ` · "${lakap(s)}"` : ''} <small>GP ${gucPuani(s).gp.toFixed(0)}</small>`, 'blue') +
    st('Stres', Math.round(s.patron.stres), s.patron.stres >= 60 ? 'bad' : '') +
    (s.raid && informed(s) ? st('Baskın', `${Math.max(1, Math.ceil((s.raid.at - s.t) / DAY))} gün içinde`, 'bad') : '');
}

// ---------- harita ----------
const B = {
  tefeci: { x: 20, y: 76, w: 120, h: 94, fill: '#4a3d2e', name: 'Tefeci Şakir' },
  meyhane: { x: 175, y: 70, w: 160, h: 100, fill: '#7a4a2a', name: 'Meyhanen' },
  ev: { x: 385, y: 76, w: 120, h: 94, fill: '#5a5040', name: 'Evin' },
  karakol: { x: 565, y: 76, w: 120, h: 94, fill: '#3c4a5c', name: 'Karakol' },
  camasir: { x: 20, y: 240, w: 120, h: 90, fill: '#4f5a55', name: 'Çamaşırhane' },
  liman: { x: 175, y: 240, w: 160, h: 90, fill: '#2f4a58', name: 'Liman A.Ş.' },
  rakip: { x: 395, y: 240, w: 120, h: 90, fill: '#5d4038', name: "Kâzım'ın Yeri" },
  karaca: { x: 575, y: 240, w: 120, h: 90, fill: '#4a2f3a', name: 'Karaca Ailesi' },
};
const MAP_W = 720, MAP_H = 440;
const PATROL = [[10, ROAD_Y - 8], [MAP_W - 10, ROAD_Y - 8]]; // gidip gelir
const ROAD_TOP = 172, ROAD_BOT = 238;

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
  el('rect', { width: MAP_W, height: MAP_H, fill: '#3b3528' }, svg);
  el('rect', { y: 372, width: MAP_W, height: MAP_H - 372, fill: '#1f3a4a' }, svg); // liman suyu
  el('rect', { x: 232, y: 330, width: 46, height: 52, fill: '#5b4a35' }, svg); // iskele
  el('rect', { y: ROAD_TOP, width: MAP_W, height: ROAD_BOT - ROAD_TOP, fill: '#57503f' }, svg); // tek ana sokak
  el('line', { x1: 0, y1: ROAD_Y, x2: MAP_W, y2: ROAD_Y, stroke: '#6d6552', 'stroke-width': 2, 'stroke-dasharray': '14 12' }, svg);
  M.haze = el('circle', { cx: 255, cy: 120, r: 0, fill: '#c9a24b', opacity: 0.12 }, svg);
  M.b = {};
  for (const [id, b] of Object.entries(B)) {
    const g = el('g', { class: 'bld', 'data-b': id }, svg);
    el('rect', { class: 'body', x: b.x, y: b.y, width: b.w, height: b.h, fill: b.fill, rx: 3 }, g);
    el('rect', { x: b.x, y: b.y, width: b.w, height: 10, fill: '#0003' }, g);
    const wins = [];
    for (let i = 0; i < Math.floor(b.w / 34); i++) wins.push(el('rect', { x: b.x + 14 + i * 34, y: b.y + 22, width: 14, height: 14, fill: '#1c1812' }, g));
    const dr = PLACES[id], top = dr.y > ROAD_Y ? 0 : 1;
    el('rect', { x: dr.x - 9, y: top ? b.y + b.h - 7 : b.y, width: 18, height: 7, fill: '#cfa84f', opacity: 0.85 }, g); // kapı
    const t = el('text', { x: b.x + b.w / 2, y: b.y + b.h / 2 + 8 }, g); t.textContent = b.name;
    const sub = el('text', { class: 'sub', x: b.x + b.w / 2, y: b.y + b.h / 2 + 27 }, g);
    M.b[id] = { g, wins, sub };
  }
  M.cellar = el('g', {}, svg);
  el('rect', { x: 288, y: 174, width: 30, height: 9, fill: '#1a120b', stroke: '#c9a24b', 'stroke-width': 1 }, M.cellar); // bodrum kapağı
  M.smoke = [0, 1, 2].map(() => el('circle', { r: 4, fill: '#bbb', opacity: 0 }, svg));
  M.dots = Array.from({ length: 14 }, () => el('circle', { r: 3.5, fill: '#e9dec9', opacity: 0, 'pointer-events': 'none' }, svg));
  M.route = el('polyline', { fill: 'none', stroke: '#cfa84f', 'stroke-width': 2, 'stroke-dasharray': '5 5', opacity: 0.8, 'pointer-events': 'none' }, svg);
  M.night = el('rect', { width: MAP_W, height: MAP_H, fill: '#070b20', opacity: 0, 'pointer-events': 'none' }, svg);
  M.glow = el('g', { 'pointer-events': 'none' }, svg);
  M.patrolLight = el('circle', { r: 16, fill: '#7da0c4', opacity: 0.18, 'pointer-events': 'none' }, svg);
  M.patrol = el('circle', { r: 6, fill: '#7da0c4', stroke: '#0b1220', 'stroke-width': 1.5, 'pointer-events': 'none' }, svg);
  M.me = el('g', { class: 'me', 'pointer-events': 'none' }, svg);
  el('circle', { r: 13, fill: '#cfa84f', opacity: 0.25 }, M.me);
  el('circle', { r: 7.5, fill: '#cfa84f', stroke: '#1a1408', 'stroke-width': 2 }, M.me);
  const lbl = el('text', { y: -14 }, M.me); lbl.textContent = 'Sen';
  M.raid = el('text', { x: MAP_W / 2, y: 36, 'text-anchor': 'middle', fill: '#cf5c45', 'font-size': 18, 'font-family': 'Georgia, serif', 'pointer-events': 'none' }, svg);
  svg.addEventListener('click', (e) => {
    const g = e.target.closest && e.target.closest('.bld');
    if (g) { ui.sel = g.dataset.b; ui.tab = 'mekan'; goTo({ b: g.dataset.b }); return; }
    if (!svg.getScreenCTM) return;
    const pt = svg.createSVGPoint(); pt.x = e.clientX; pt.y = e.clientY;
    const p = pt.matrixTransform(svg.getScreenCTM().inverse());
    if (p.y >= ROAD_TOP - 6 && p.y <= ROAD_BOT + 6) goTo({ x: p.x });
  });
}

// Karakteri yürüt. Zaman durmuşken yürümez; oyuncuya söyle.
function goTo(a) {
  const r = act(s, { type: 'goto', ...a });
  if (!r.ok) toast(r.msg);
  else if (s.speed === 0 && s.walk) toast('Yola çıktın — yürümen için zamanı başlat (1 / 2 / 3)');
  renderAll();
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
  const open = { meyhane: MEY_OPEN(d.hour), rakip: MEY_OPEN(d.hour), karakol: true, camasir: d.hour >= 8 && d.hour < 18 && !!s.biz.camasir, tefeci: d.hour >= 9 && d.hour < 18, ev: d.hour >= 18 && d.hour < 23, liman: d.hour >= 9 && d.hour < 18, karaca: d.hour >= 17 || d.hour < 4 };
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
  M.b.liman.sub.textContent = s.kurum.liman.hisse > 0 ? `payın %${s.kurum.liman.hisse}` : 'ortak değilsin';
  M.b.karaca.sub.textContent = s.unvan.ahit ? 'Ahit var' : asamaAd[s.kurum.karaca.asama].toLowerCase();

  // bodrum
  const di = s.dist;
  const hidden = s.t < di.hiddenUntil;
  M.cellar.setAttribute('opacity', di.built ? 1 : 0);
  M.haze.setAttribute('r', di.built ? Math.min(110, di.iz * 1.2) : 0);
  const prod = di.built && di.volume > 0 && !hidden && !!staff(s, 'usta');
  M.smoke.forEach((c, i) => {
    const u = ((tf / 50) + i / 3) % 1;
    c.setAttribute('cx', 303 + Math.sin(u * 6 + i) * 5); c.setAttribute('cy', 172 - u * 34);
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
    const door = toMe ? PLACES.meyhane : PLACES.rakip;
    const fromX = i % 2 ? MAP_W : 0, run = Math.abs(door.x - fromX), rise = Math.abs(door.y - ROAD_Y), dist = Math.min(1, u / 0.8) * (run + rise);
    const x = dist <= run ? fromX + Math.sign(door.x - fromX) * dist : door.x;
    const y = dist <= run ? ROAD_Y + (i % 2 ? 5 : -5) : (ROAD_Y + (i % 2 ? 5 : -5)) + (door.y - ROAD_Y - (i % 2 ? 5 : -5)) * ((dist - run) / rise);
    c.setAttribute('cx', x); c.setAttribute('cy', y);
    c.setAttribute('opacity', u > 0.8 ? ((1 - u) / 0.2).toFixed(2) : 0.9);
  });

  // devriye
  // karakter
  const frac = s.speed > 0 ? Math.max(0, Math.min(1, tf - s.t)) : 0, me = walkerAt(s, frac);
  M.me.setAttribute('transform', `translate(${me.x.toFixed(1)} ${me.y.toFixed(1)})`);
  if (me.path.length) M.route.setAttribute('points', [[me.x, me.y], ...me.path.map((q) => [q.x, q.y])].map((q) => q.join(',')).join(' ')); else M.route.removeAttribute('points');
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
  return walkBar(ui.sel) + panelMekanIc(d);
}

function walkBar(id) {
  const pl = PLACES[id];
  if (!pl) return '';
  const gated = Object.values(GATE).includes(id);
  const orada = here(s) === id, yolda = s.walk && s.walk.to === id;
  const d = orada ? `<span class="good">Buradasın.</span>` : yolda ? `<span class="gold">Yoldasın…</span>` : `<button class="primary" data-walk="${id}">Yürü → ${pl.ad} <small>(~${walkMinutes(s, id)} dk)</small></button>`;
  return `<div class="box">${d}${gated && !orada ? `<div class="note">Bu yerdeki işler için orada bulunman gerekir.</div>` : ''}</div>`;
}

function panelMekanIc(d) {
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
    case 'liman': return panelLiman();
    case 'karaca': return panelKaraca();
    default: return '';
  }
}

function panelLiman() {
  const L = s.kurum.liman, kr = s.kredi, banka = listeler(s).find((l) => l.id === 'banka').on;
  let h = `<h3>Liman A.Ş.</h3><p class="note">Limanın yük ve depo şirketi. Müdürü Selahattin Bey. Hissesi alınabilir, kredi verir; ama kayıtlı bir kurumdur: kirli parayı sevmez.</p>` +
    row('Senin payın', `%${L.hisse} <small>(${money(hisseDegeri(s))})</small>`) + row('Pay fiyatı', `${money(S0.HISSE_FIYAT)} / %1`) +
    row('Aylık temettün', money(Math.round(L.hisse / 100 * S0.LIMAN_KAR))) +
    `<div class="note">%25 pay yönetim kurulunda koltuk verir: kredi onayı kolaylaşır, Güç Puanı artar. Kirli parayla pay alırsan %30 komisyon ödersin ve Mali Şüphe artar. En çok %${S0.HISSE_MAX}.</div>` +
    `<div class="btns"><button ${A({ type: 'hisse', pct: 5, kirli: false })}>%5 al (${money(5 * S0.HISSE_FIYAT)} temiz)</button>` +
    `<button ${A({ type: 'hisse', pct: 5, kirli: true })}>%5 al (${money(5 * S0.HISSE_FIYAT * 1.3)} kirli)</button>` +
    `<button class="danger" ${A({ type: 'hisseSat', pct: 5 })} ${L.hisse < 5 ? 'disabled' : ''}>%5 sat</button></div>`;
  h += `<h3>Kredi</h3>`;
  if (kr.principal > 0) {
    h += row('Kalan borç', money(kr.principal)) + row('Aylık taksit', money(kr.installment)) + row('Aylık faiz', pct(S0.KREDI_FAIZ)) +
      `<div class="note">Taksit temiz parayla ödenir. 3 taksit üst üste kaçarsa meyhane haczedilir.</div>`;
  } else if (banka) {
    h += `<div class="note bad">Banka kara listesindesin: Liman A.Ş. kredi vermez.</div>`;
  } else {
    h += `<p class="note">6 taksit, aylık faiz %${(S0.KREDI_FAIZ * 100).toFixed(1)}. Onay ihtimali; teminatına, müdürün görüşüne ve semtteki iyiliğine bağlı. Reddedilirsen 10 gün beklemelisin.</p><div class="btns">` +
      [1000, 2000, 4000].map((a) => `<button ${A({ type: 'kredi', amount: a })}>${money(a)} iste (%${Math.round(krediInfo(s, a).p * 100)})</button>`).join('') + `</div>`;
    const e = krediInfo(s, 2000);
    h += `<div class="box"><div class="t">2.000 ₺ için tahmin kartı</div>${e.factors.map((f) => `<div class="row"><span class="dim">${f.k}</span><span class="${cls(f.x)}">${f.x >= 0 ? '+' : ''}${f.x.toFixed(2)}</span></div>`).join('')}</div>`;
  }
  return h + personLink('selahattin');
}

function panelKaraca() {
  const u = s.unvan, K = s.kurum.karaca, a = u.ahit, t = tehdit(s);
  let h = `<h3>Karaca Ailesi</h3><p class="note">Limanın yarısını elinde tutan eski aile. Başı Reis Orhan Karaca. Bu semtin üstünde bir basamak.</p>` +
    row('Güçleri', `${S0.KARACA_GP} GP`) + row('Senin gücün', `${gucPuani(s).gp.toFixed(1)} GP`) +
    row('Seni nasıl görüyorlar', `<b class="${K.asama === 2 ? 'bad' : K.asama === 1 ? 'gold' : ''}">${asamaAd[K.asama]}</b>`) +
    row('Tehdit', `${t.toFixed(2)} <small>(0,3 fark eder · 0,6 baskı)</small>`) + meter(t, 1, t >= 0.6 ? 'red' : '', [0.3, 0.6]) +
    (K.redd ? `<div class="note bad">Teklifi reddettin: tehdit ×1,6.</div>` : '');
  if (a) {
    const m = memnuniyet(s);
    h += `<h3>Ahit</h3>` + row('Haraç', `gelirinin %${a.harac} <small>(~${money(Math.round(a.harac / 100 * s.gelirAy))}/ay, kirli)</small>`) +
      row('Himaye', a.himaye ? '<span class="good">var (Polis Dikkati −8)</span>' : '<span class="bad">yok</span>') +
      `<div class="box"><div class="t">Orhan'ın memnuniyeti: ${Math.round(m.v)}</div>${m.lines.map((l) => `<div class="row"><span class="dim">${l.k}</span><span class="${cls(l.v)}">${sign(l.v)}</span></div>`).join('')}</div>` +
      `<div class="note">Haracı ödemezsen ya da Orhan'ın görüşü −10'un altına düşerse himaye biter.</div>` +
      `<button class="danger" ${A({ type: 'ahitBoz' })}>Ahdi boz</button>`;
  } else {
    h += `<h3>Ahit</h3><p class="note">Ahit: onlara bağlanırsın; aylık gelirinin %${S0.HARAC}'ı haraç gider, karşılığında himaye gelir.</p>` +
      `<button class="primary" ${A({ type: 'ahitIste' })}>Orhan'a git, Ahit iste</button>`;
  }
  return h + personLink('orhan');
}

const chips = (c) => (c.traits || []).map((t) => `<span class="chip ${TRAITS[t] ? TRAITS[t].kind : ''}" title="${TRAITS[t] ? TRAITS[t].hint : ''}">${t}</span>`).join('');

function panelGuc() {
  const g = gucPuani(s), u = s.unvan, nxt = BASAMAK[u.basamak + 1];
  let h = `<h3>Mevki: ${BASAMAK[u.basamak].ad}${lakap(s) ? ` · "${lakap(s)}"` : ''}</h3>` +
    `<div class="box"><div class="t">Güç Puanı: ${g.gp.toFixed(1)}${nxt ? ` / ${nxt.gp} (${nxt.ad})` : ''}</div>` +
    g.parts.map((p) => `<div class="row"><span class="dim">${p.k}</span><span class="good">+${p.v.toFixed(1)}</span></div>`).join('') +
    (nxt ? meter(g.gp, nxt.gp, '', []) : '') +
    (nxt && u.basamak === 0 ? `<div class="note">Ağa olmak için: Güç Puanı ${nxt.gp}+ (3 ay üst üste: ${u.ay}/3) ve semt halkında Tanınırlık 30+ (şu an ${Math.round(perceived(s, 'halk').T)}).</div>` : '') + `</div>`;
  h += `<h3>Ün</h3><div class="note">Üç sayı: <b>Tanınırlık</b> (seni tanıyor mu), <b>İyilik</b> (iyi mi kötü mü), <b>Korku</b>. Her çevrede <b>Cephe</b> (herkesin gördüğü) ile <b>Gölge</b> (gerçekte olan) ayrı tutulur; çevre ne kadar "sızıntı" bilirse o kadar gölgeyi görür.</div>` +
    `<table><tr><th>Çevre</th><th>Tanınırlık</th><th>İyilik</th><th>Korku</th><th>Sızıntı</th></tr>` +
    Object.keys(CEVRE).map((c) => { const p = perceived(s, c), un = s.un[c]; return `<tr><td>${CEVRE[c]}</td><td>${Math.round(p.T)}</td><td class="${cls(p.I)}">${Math.round(p.I)}</td><td>${Math.round(p.K)}</td><td>${pct(p.S)}</td></tr>` +
      `<tr class="sub"><td>↳ cephe / gölge</td><td>${Math.round(un.cephe.T)} / ${Math.round(un.golge.T)}</td><td>${Math.round(un.cephe.I)} / ${Math.round(un.golge.I)}</td><td>${Math.round(un.cephe.K)} / ${Math.round(un.golge.K)}</td><td></td></tr>`; }).join('') + `</table>` +
    `<h3>Mahalleye bağış</h3><div class="note">Kirli parayı iyiliğe çevirir: semt halkında İyilik artar. Yükseldikçe etkisi azalır (kolay alınan ün, kolay gider). 5 günde bir.</div>` +
    `<div class="btns">${[150, 300, 600].map((a_) => `<button ${A({ type: 'donate', amount: a_ })}>${a_} ₺ bağış</button>`).join('')}</div>`;
  const ls = listeler(s);
  h += `<h3>Sana karşı tutulan listeler</h3>` + ls.map((l) => `<div class="box ${l.on ? 'on' : ''}"><div class="row"><span><b>${l.ad}</b></span><span class="${l.on ? 'bad' : 'good'}">${l.on ? 'listedesin' : 'temiz'}</span></div>` +
    (l.on ? `<div class="note">${l.etki}<br>Çıkış: ${l.cikis}</div>` : `<div class="note">${l.etki}</div>`) + `</div>`).join('');
  const dost = s.bonds.filter((b) => b.tur === 'dost');
  h += `<h3>Dostların</h3>` + (dost.length ? dost.map((b) => personLink(b.id)).join('') : `<p class="note">Henüz kimse. Dost olmak için: görüşü 40+ ve birlikte 3 olay (hediye, ziyafet, ortak karar). Dost, iyilik borcunu yarı fiyata öder; kaybı seni yorar.</p>`);
  return h;
}

function panelKara() {
  const d = s.kara.defter;
  const adaylar = Object.keys(s.chars).filter((id) => !s.chars[id].dead && id !== 'leyla' && !d.some((k) => k.hedef === id));
  if (!adaylar.includes(ui.dHedef)) ui.dHedef = adaylar[0];
  let h = `<h3>Kara Defter</h3><p class="note">Sana yapılan haksızlığı kayda geçirirsin; kayıt bedava, ama kin seni yorar. Kapatmanın üç yolu var: <b>af</b> (görüşü artar), <b>tazminat</b> (Yeraltı Korkun yeterliyse öder), <b>hesaplaşma</b> (adamın ve 200 ₺ gerekir; riskli).</p>`;
  if (!d.length) h += `<p class="note">Defter boş.</p>`;
  for (const k of d) {
    const c = s.chars[k.hedef], p = tazminatP(s, k.agirlik);
    h += `<div class="box"><div class="row"><span><b>${c.ad}</b> <small>${k.neden} · ağırlık ${k.agirlik}</small></span><span class="${k.kin >= 20 ? 'bad' : 'dim'}">kin ${Math.round(k.kin)}</span></div>` +
      `<div class="btns"><button ${A({ type: 'defterKapat', id: k.id, yol: 'af' })} ${blocked(s.patron, 'af') ? 'disabled title="Kindarsın"' : ''}>Affet</button>` +
      `<button ${A({ type: 'defterKapat', id: k.id, yol: 'tazminat' })}>Tazminat iste (%${Math.round(p * 100)})</button>` +
      `<button class="danger" ${A({ type: 'defterKapat', id: k.id, yol: 'hesap' })} ${staff(s, 'koruma') ? '' : 'disabled'}>Hesaplaş (200 ₺)</button></div></div>`;
  }
  h += `<h3>Deftere yaz</h3><div class="box"><div class="row"><span>Kim</span><select data-ui="dHedef">${adaylar.map((id) => `<option value="${id}" ${ui.dHedef === id ? 'selected' : ''}>${s.chars[id].ad}</option>`).join('')}</select></div>` +
    `<div class="row"><span>Neden</span><select data-ui="dNeden">${NEDEN.map((n) => `<option ${ui.dNeden === n ? 'selected' : ''}>${n}</option>`).join('')}</select></div>` +
    `<div class="row"><span>Ağırlık</span><select data-ui="dAg">${[1, 2, 3].map((n) => `<option value="${n}" ${+ui.dAg === n ? 'selected' : ''}>${n}${n === 1 ? ' (küçük)' : n === 3 ? ' (büyük)' : ''}</option>`).join('')}</select></div>` +
    `<button class="primary" id="defterAc" ${adaylar.length ? '' : 'disabled'}>Deftere yaz</button><div class="note">Ağırlık büyüdükçe tazminat zorlaşır, hesaplaşma gerekçesi güçlenir. Küçük kayıtlar zamanla (yaklaşık 5 ayda) unutulur — Kindar değilsen.</div></div>`;
  return h;
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
  return h + `<h3>Komşu</h3><p class="note">Bodrumun penceresi Hacer Hanım'ın mutfağına bakar.</p>` + personLink('hacer');
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
  const b = bond(s, id), inDefter = s.kara.defter.some((k) => k.hedef === id);
  h += `<div style="margin-top:6px">${chips(c)}</div>` +
    (c.traits || []).map((t) => (TRAITS[t] ? `<div class="note"><b>${t}:</b> ${TRAITS[t].hint}</div>` : '')).join('') +
    `<div class="row"><span>Bağ</span><span>${b === 'dost' ? '<b class="gold">Dostun</b>' : `tanıdık <small>(ortak olay ${c.ortak || 0}/3${o.total >= 40 ? '' : ', görüş 40 olmalı'})</small>`}</span></div>`;
  if (c.employed) {
    h += `<div class="row" style="margin-top:8px"><span>Sadakat</span><span>${Math.round(c.sadakat)}</span></div>${meter(c.sadakat, 100, c.sadakat < 35 ? 'red' : 'green', [20])}` +
      `<div class="note">Sadakat her gün görüşe doğru %10 kayar. 20'nin altında işi bırakabilir.</div>` +
      `<div class="row"><span>Maaş</span>${live('sal_' + id)}</div>${range('setSalary', Math.round(c.piyasa * 0.5), c.piyasa * 2, 5, c.maas, { id })}`;
  }
  h += `<div class="btns">`;
  if (canHire(s, id)) h += `<button class="primary" ${A({ type: 'hire', id })}>İşe al (ayda ${c.maas} ₺)</button>`;
  if (c.employed && id !== 'nuri') h += `<button class="danger" ${A({ type: 'fire', id })}>İşten çıkar</button>`;
  h += `<button ${A({ type: 'gift', id })}>Hediye gönder (${b === 'dost' ? 25 : 50} ₺ · görüş +8)</button>` +
    `<button ${A({ type: 'feast', id })}>Sofrana çağır (150 ₺ · görüş +6)</button>` +
    (inDefter || id === 'leyla' ? '' : `<button data-go='${JSON.stringify({ tab: 'kara', dHedef: id })}'>Deftere yaz</button>`) + `</div>`;
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

const TABS = [['mekan', 'Mekân'], ['defter', 'Hesap'], ['kisiler', 'Kişiler'], ['guc', 'Güç'], ['kara', 'Kara Defter'], ['kararlar', 'Kararlar']];
function renderPanel() {
  $('tabs').innerHTML = TABS.map(([id, n]) => `<button data-tab="${id}" class="${ui.tab === id ? 'on' : ''}">${n}${id === 'kararlar' && s.cards.length ? `<span class="badge">${s.cards.length}</span>` : ''}</button>`).join('');
  const p = $('panel');
  const top = p.scrollTop;
  p.innerHTML = { mekan: panelMekan, defter: panelDefter, kisiler: panelKisiler, guc: panelGuc, kara: panelKara, kararlar: panelKararlar }[ui.tab]();
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
  if (t.dataset.walk) return goTo({ b: t.dataset.walk });
  if (t.dataset.a) return doAct(JSON.parse(t.dataset.a));
  if (t.dataset.go) { const g = JSON.parse(t.dataset.go); ui.tab = g.tab; if (g.dHedef) ui.dHedef = g.dHedef; return renderPanel(); }
  if (t.id === 'defterAc') return doAct({ type: 'defterAc', hedef: ui.dHedef, neden: ui.dNeden, agirlik: +ui.dAg });
  if (t.dataset.p) { ui.person = t.dataset.p; ui.tab = 'kisiler'; renderPanel(); $('panel').scrollTop = 0; return; }
  if (t.dataset.card) { ui.modal = +t.dataset.card; setSpeed(0); return renderModal(); }
  if (t.id === 'later') { ui.modal = null; return renderAll(); }
  if (t.id === 'restart' || t.id === 'newgame') {
    if (t.id === 'newgame' && !confirm('Kayıt silinip baştan başlanacak. Emin misin?')) return;
    s = fresh(); ui.modal = null; ui.person = null; ui.sel = 'meyhane'; ui.tab = 'mekan'; ui.pauseSeen = s.pauseReq; acc = 0;
    setSpeed(0); save(); renderAll();
  }
});
document.addEventListener('input', (e) => {
  const t = e.target;
  if (t.dataset.r) { act(s, { ...JSON.parse(t.dataset.r), v: +t.value }); refreshLive(); }
  else if (t.dataset.ui === 'bribe') { ui.bribe = +t.value; refreshLive(); }
  else if (t.dataset.ui) ui[t.dataset.ui] = t.value;
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
    if (!(ae && (ae.type === 'range' || ae.tagName === 'SELECT'))) renderPanel(); else refreshLive();
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
