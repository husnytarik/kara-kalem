// Ortak yardımcılar. Arayüzden bağımsızdır; yalnızca durum (state) nesnesi üzerinde çalışır.

export const clamp = (x, a, b) => Math.max(a, Math.min(b, x));
export const sigmoid = (x) => 1 / (1 + Math.exp(-x));

export const DAY = 1440; // oyun dakikası
export const DAYS_PER_MONTH = 10;
export const SEASONS = ['İlkbahar', 'Yaz', 'Sonbahar', 'Kış'];

// Tohumlu RNG (mulberry32). Tohum durumun içinde tutulur: aynı durum + aynı eylemler = aynı sonuç.
export function rnd(s) {
  s.seed = (s.seed + 0x6d2b79f5) | 0;
  let t = s.seed;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

export function dateOf(t) {
  const day = Math.floor(t / DAY);
  const month = Math.floor(day / DAYS_PER_MONTH);
  return {
    day,
    hour: Math.floor((t % DAY) / 60),
    minute: t % 60,
    month,
    dayInMonth: (day % DAYS_PER_MONTH) + 1,
    monthInYear: (month % 12) + 1,
    year: Math.floor(month / 12) + 1,
    season: Math.floor((month % 12) / 3),
  };
}

const pad = (n) => String(n).padStart(2, '0');
export const fmtTime = (t) => { const d = dateOf(t); return `${pad(d.hour)}:${pad(d.minute)}`; };
export const fmtDate = (t) => { const d = dateOf(t); return `${d.year}. yıl · ${d.monthInYear}. ay · ${d.dayInMonth}. gün`; };
export const money = (x) => `${Math.round(x).toLocaleString('tr-TR')} ₺`;

// Olay akışı. "why" alanı nedensellik kaydıdır: bu neden oldu?
export function log(s, text, kind = 'info', why = '') {
  s.log.push({ t: s.t, text, kind, why });
  if (s.log.length > 300) s.log.shift();
}

export function addMod(s, id, k, v, decay = 0) {
  s.chars[id].mods.push({ k, v, decay });
}

// Görüş dökümü: bir karakterin patron hakkındaki görüşü, nedenleriyle.
export function opinion(s, id) {
  const c = s.chars[id];
  const lines = c.mods.map((m) => ({ k: m.k, v: Math.round(m.v) })).filter((l) => l.v !== 0);
  if (c.employed && c.piyasa) {
    const v = Math.round(25 * clamp(c.maas / c.piyasa - 1, -1, 1));
    lines.push({ k: v > 0 ? 'Maaşı piyasanın üstünde' : v < 0 ? 'Maaşı piyasanın altında' : 'Maaşı piyasa düzeyinde', v });
  }
  const total = clamp(lines.reduce((a, l) => a + l.v, 0), -100, 100);
  return { total, lines };
}

// mode 'clean': yalnızca temiz para (kira, vergi, borç). mode 'dirty': önce kirli, yetmezse temiz.
export function spend(s, amount, mode = 'clean') {
  if (mode === 'clean') {
    if (s.cash.clean < amount) return false;
    s.cash.clean -= amount;
    return true;
  }
  if (s.cash.dirty + s.cash.clean < amount) return false;
  const d = Math.min(s.cash.dirty, amount);
  s.cash.dirty -= d;
  s.cash.clean -= amount - d;
  return true;
}

export const staff = (s, job) => Object.values(s.chars).find((c) => c.job === job && c.employed && !c.dead) || null;

// Polisin haber uçurduğu durum: Rıfat aylıkta ya da görüşü yeterince iyi.
export const informed = (s) => s.chars.rifat.payroll || opinion(s, 'rifat').total >= 30;

export function addStress(s, v, why) {
  s.patron.stres = clamp(s.patron.stres + v, 0, 100);
  if (v > 0 && why) log(s, `Stres +${v}: ${why}`, 'info');
}

// Malı sakla, üretimi durdur: 3 gün boyunca üretim ve satış yok, stokun %20'si kaybolur.
export function hideGoods(s) {
  const d = s.dist;
  const lost = d.stock * 0.2;
  d.stock -= lost;
  d.hiddenUntil = s.t + 3 * DAY;
  log(s, `Mal saklandı, imalathane söküldü. 3 gün üretim ve satış yok. ${Math.round(lost)} şişe telef oldu.`, 'warn');
}
