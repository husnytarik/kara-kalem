// Şehir yerleşimi ve yürüme yolu. Çizim yok: yalnızca koordinatlar ve yol bulma.
// Üç yatay sokak (ROWS) ve beş dikey bağlantı (V). Her binanın kapısı bir sokağa açılır.
export const W = 1380, H = 930;
export const ROWS = [230, 480, 730];
export const V = [20, 357.5, 687.5, 1017.5, 1355];
export const ROAD_HALF = 28;
export const WALK = 10; // oyun dakikası başına harita birimi
const BH = 90;

// p: satır öneki, row: hangi sokak, side: -1 sokağın üstünde / +1 altında
const LAYOUT = [
  { p: 't', row: 0, side: -1, n: 8, w: 140, step: 165 },
  { p: 'a', row: 0, side: 1, n: 8, w: 140, step: 165 },
  { p: 'b', row: 1, side: -1, n: 8, w: 140, step: 165 },
  { p: 'c', row: 1, side: 1, n: 8, w: 140, step: 165 },
  { p: 'd', row: 2, side: -1, n: 8, w: 140, step: 165 },
  { p: 'h', row: 2, side: 1, n: 10, w: 110, step: 135 },
];

// Oyunla bağlı 8 yer
const FN = {
  a6: { id: 'karakol', ad: 'Precinct House', fill: '#3c4a5c', saat: [0, 24] },
  b1: { id: 'ev', ad: 'Home', fill: '#5a5040', saat: [18, 23] },
  b3: { id: 'meyhane', ad: "Murphy's Tavern", fill: '#7a4a2a', saat: [11, 25] },
  c0: { id: 'camasir', ad: 'Laundromat', fill: '#4f5a55', saat: [8, 18] },
  c3: { id: 'rakip', ad: "Duffy's Bar", fill: '#5d4038', saat: [11, 25] },
  c6: { id: 'tefeci', ad: 'Sal the Shark', fill: '#4a3d2e', saat: [9, 18] },
  d5: { id: 'karaca', ad: 'Marchetti Family', fill: '#4a2f3a', saat: [17, 28] },
  h4: { id: 'liman', ad: 'Harbor Trust', fill: '#2f4a58', saat: [9, 18] },
};

// Süs / mahalle dokusu: şimdilik yalnızca hikâye ve coğrafya (v0.3'te iş ve olay getirecek).
const GEN = [
  // Hilltop (t0-t3, a0-a3)
  ['Hotel Belmont', 'Resepsiyondaki adam her şeyi görür, hiçbir şeyi hatırlamaz.', [0, 24]],
  ['Jeweler', 'Kasası geceleri iki kilitle kapanır.', [10, 18]],
  ['Attorney', 'Genç, aç ve her işi alır.', [9, 18]],
  ['Watchmaker', 'Vitrinindeki saatlerin hiçbiri aynı vakti göstermez.', [9, 18]],
  ['Grand Theater', 'Locaları şehrin eşrafı tutar.', [18, 24]],
  ['Florist', 'Düğüne de cenazeye de aynı güller gider.', [8, 19]],
  ['Tailor', 'Dikiş makinesinin sesi kapıdan taşar.', [8, 19]],
  ['Dentist', 'Kapıdaki levha: "Sıra numarası bekleyiniz".', [9, 17]],
  // Downtown (t4-t7, a4, a5, a7)
  ['City Hall', 'Mühürlü kâğıt ve uzun sıralar.', [9, 17]],
  ['First National Bank', 'Kayıtlı paranın yeri; kirli parayı sevmez.', [9, 16]],
  ['Daily Courier', 'Yarının manşeti bu gece yazılıyor.', [10, 23]],
  ['Post Office', 'Telgraf memuru sorulmadan bilgi vermez.', [9, 17]],
  ['Orpheum Cinema', 'Sessiz film, canlı piyano.', [17, 24]],
  ['Drugstore', 'Gece nöbetçi tabelası sönük; kapı zili çalışır.', [8, 20]],
  ["St. Mary's Hospital", 'Gece gündüz açık. Yaralıları sorgusuz alırlar, kayıt tutarlar.', [0, 24]],
  // Southside (b0, b2, c1, c2)
  ['Corner Grocer', 'Veresiye defteri kalın, kulağı daha da kalındır.', [7, 21]],
  ['Barber Shop', 'Traş olurken en çok söz duyulan yer.', [8, 20]],
  ['Bakery', 'Sabahları ilk o açar; ekmek kokusu bütün sokağı tutar.', [5, 15]],
  ["St. Patrick's Church", 'Çanı mahalleye saati bildirir.', [6, 21]],
  // Eastside (b4-b7, c4, c5, c7)
  ['Synagogue', 'Cumartesi sabahları avlusu dolar taşar.', [5, 22]],
  ['Corner Diner', 'Kahve, gazete ve fısıltı.', [6, 24]],
  ['Boarding House', 'Yük arabaları ve yol yorgunu adamlar.', [0, 24]],
  ['Print Shop', 'Mürekkep kokusu; bu ay dört ilan bastılar.', [8, 18]],
  ['Bakeshop', 'Şeker kıtlığında bile turta çıkar.', [7, 21]],
  ['Shoe Repair', 'Her gün biri yeni tabana, biri yeni dedikoduya gelir.', [8, 19]],
  ['Public School 12', 'Dört yüz çocuk, iki öğretmen.', [8, 16]],
  // The Flats (d0-d4, d6, d7)
  ['Blacksmith', 'Ocak sabahtan akşama yanar.', [7, 18]],
  ['Carpenter', 'İskele tahtası, tabut, beşik: hepsini yapar.', [7, 18]],
  ['Junk Yard', 'Eski ne varsa onda yeni bir hayat bulur.', [8, 18]],
  ['Tenement', 'Beş kat, kırk kiracı, bir kapıcı.', [0, 24]],
  ['Turkish Bath', 'Konuşulanlar buharla birlikte dışarı sızmaz.', [7, 22]],
  ['Produce Stand', 'Tezgâhta ne varsa mahalleli o gün onu yer.', [7, 19]],
  ['Butcher', 'Biftek fiyatı bu semtin gerçek ekonomi göstergesidir.', [7, 18]],
  // Docks (h0-h3, h5-h9)
  ['Warehouse 1', 'Kilitli ambar; içindekiler kayıtta başka türlü yazılı.', [8, 18]],
  ['Warehouse 2', 'Gümrüklü mal burada bekler.', [8, 18]],
  ['Fish Market', 'Sabah beşte açık artırma, öğlen koku.', [4, 14]],
  ['Customs House', 'Mühür bunun elinde, uğraşan çok.', [8, 17]],
  ['Harbor Master', 'Hangi gemi ne zaman girip çıkacak, burada bilinir.', [7, 19]],
  ['Shipyard', 'Bir gövde iskelede yarım duruyor.', [7, 18]],
  ['Rope Works', 'Kenevir kokusu ve çıplak ayaklı çocuklar.', [7, 18]],
  ['Dock Hiring Hall', 'Hamallar buradan iş alır.', [6, 18]],
  ['Coal Yard', 'Kara toz her şeye siner.', [6, 18]],
];
const TONES = ['#5b4e3c', '#4d5a4c', '#5a4a4a', '#4a5260', '#605641', '#4e4458', '#564c40', '#44564f'];

const dizi = (p, a, b) => Array.from({ length: b - a + 1 }, (_, i) => p + (a + i));
export const BOLGELER = {
  hilltop: { ad: 'Hilltop', ac: 'Villalar, bankerler ve siyasetçiler. Para burada konuşur, ses çıkarmaz.', slots: [...dizi('t', 0, 3), ...dizi('a', 0, 3)], komsu: ['downtown', 'southside'] },
  downtown: { ad: 'Downtown', ac: 'Belediye, banka, karakol ve gazete. Şehrin resmî yüzü.', slots: [...dizi('t', 4, 7), ...dizi('a', 4, 7)], komsu: ['hilltop', 'eastside'] },
  southside: { ad: 'Southside', ac: 'Senin semtin. Dar sokaklar, sadık halk, eski borçlar.', slots: [...dizi('b', 0, 3), ...dizi('c', 0, 3)], komsu: ['hilltop', 'eastside', 'flats'] },
  eastside: { ad: 'Eastside', ac: 'Göçmen mahalleleri, pazar yerleri, kalabalık apartmanlar.', slots: [...dizi('b', 4, 7), ...dizi('c', 4, 7)], komsu: ['downtown', 'southside', 'flats'] },
  flats: { ad: 'The Flats', ac: 'Demiryolu, depo ve atölyeler. Kimse ne yüklendiğini sormaz.', slots: dizi('d', 0, 7), komsu: ['southside', 'eastside', 'docks'] },
  docks: { ad: 'Docks', ac: "Liman. Kaçakçılık, işçi sendikaları ve yarısı Marchetti'nin olan ambarlar.", slots: dizi('h', 0, 9), komsu: ['flats'] },
};
// Süs binalar: GEN dizisi bölge sırasıyla (hilltop, downtown, ...) ve bölge içinde slot sırasıyla dağıtılır.
const GENSLOT = {};
{ let i = 0; for (const B of Object.values(BOLGELER)) for (const k of B.slots) if (!FN[k]) GENSLOT[k] = GEN[i++]; }

export const PLACES = {};
{
  let gi = 0;
  for (const L of LAYOUT) {
    for (let i = 0; i < L.n; i++) {
      const key = L.p + i, bx = 40 + L.step * i, rowY = ROWS[L.row];
      const doorY = L.side < 0 ? rowY - ROAD_HALF : rowY + ROAD_HALF;
      const by = L.side < 0 ? doorY - BH : doorY;
      const fn = FN[key];
      let rec;
      if (fn) rec = { slot: key, id: fn.id, fn: true, ad: fn.ad, fill: fn.fill, saat: fn.saat, flavor: '' };
      else {
        const g = GENSLOT[key]; gi++;
        rec = { slot: key, id: key, fn: false, ad: g[0], fill: TONES[(gi * 3 + L.row) % TONES.length], saat: g[2], flavor: g[1] };
      }
      Object.assign(rec, { x: bx + L.w / 2, y: doorY, bx, by, bw: L.w, bh: BH, row: L.row, side: L.side });
      PLACES[rec.id] = rec;
    }
  }
}

// ---------- yol bulma ----------
const rowOf = (n) => { let bi = 0, bd = Infinity; ROWS.forEach((r, i) => { const d = Math.abs(n.y - r); if (d < bd) { bd = d; bi = i; } }); return bi; };
const nearestV = (ax, bx) => {
  let best = V[0], bc = Infinity;
  for (const v of V) { const c = Math.abs(ax - v) + Math.abs(v - bx) + Math.abs(v - ax) * 0.001; if (c < bc) { bc = c; best = v; } }
  return best;
};
export const snapRow = (y) => ROWS[rowOf({ y })];

// A'dan B'ye düğümler (A hariç). A ve B bir sokak noktası ya da bir kapıdır.
export function route(A, B) {
  const ra = rowOf(A), rb = rowOf(B), ya = ROWS[ra], yb = ROWS[rb], out = [];
  const push = (x, y) => { const l = out.length ? out[out.length - 1] : A; if (Math.hypot(x - l.x, y - l.y) > 0.01) out.push({ x, y }); };
  push(A.x, ya);
  if (ra !== rb) { const v = nearestV(A.x, B.x); push(v, ya); push(v, yb); }
  push(B.x, yb);
  push(B.x, B.y);
  return out;
}
export const pathLen = (from, path) => path.reduce((a, q, i) => a + Math.hypot(q.x - (i ? path[i - 1].x : from.x), q.y - (i ? path[i - 1].y : from.y)), 0);

// dist birim ilerle; yeni konum, kalan yol ve son geçilen düğüm
export function advanceAlong(pos, path, dist) {
  let x = pos.x, y = pos.y, left = dist, i = 0, last = null;
  while (left > 0 && i < path.length) {
    const n = path[i], d = Math.hypot(n.x - x, n.y - y);
    if (d <= left) { x = n.x; y = n.y; left -= d; last = n; i++; } else { x += (n.x - x) / d * left; y += (n.y - y) / d * left; left = 0; }
  }
  return { x, y, rest: path.slice(i), last };
}

// ---------- bölgeler ----------
// Her bölge bir grup binadır. Hakimlik, nüfuz ve büyüme bolge.js'te; burada yalnızca coğrafya.
{
  const bySlot = {};
  for (const p of Object.values(PLACES)) bySlot[p.slot] = p;
  for (const [id, B] of Object.entries(BOLGELER)) {
    B.id = id;
    B.binalar = B.slots.map((k) => bySlot[k].id);
    for (const k of B.slots) bySlot[k].bolge = id;
    const bs = B.slots.map((k) => bySlot[k]);
    const x0 = Math.min(...bs.map((b) => b.bx)) - 10, x1 = Math.max(...bs.map((b) => b.bx + b.bw)) + 10;
    const y0 = Math.min(...bs.map((b) => b.by)) - 10, y1 = Math.max(...bs.map((b) => b.by + b.bh)) + 10;
    B.kutu = { x: x0, y: y0, w: x1 - x0, h: y1 - y0 };
    // yürüyüş hedefi: bölgenin ortasına en yakın bina kapısı
    const cx = (x0 + x1) / 2, cy = (y0 + y1) / 2;
    B.merkez = bs.reduce((m, b) => (Math.hypot(b.x - cx, b.y - cy) < Math.hypot(m.x - cx, m.y - cy) ? b : m)).id;
  }
}
// Bir konumun bölgesi: en yakın bina kapısı.
export function bolgeAt(pos) {
  let best = null, bd = Infinity;
  for (const p of Object.values(PLACES)) { const d = Math.hypot(p.x - pos.x, p.y - pos.y); if (d < bd) { bd = d; best = p; } }
  return best ? best.bolge : null;
}
