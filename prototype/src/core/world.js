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
  t1: { id: 'ev', ad: 'Evin', fill: '#5a5040', saat: [18, 23] },
  a6: { id: 'karakol', ad: 'Karakol', fill: '#3c4a5c', saat: [0, 24] },
  b3: { id: 'meyhane', ad: 'Meyhanen', fill: '#7a4a2a', saat: [11, 25] },
  c0: { id: 'camasir', ad: 'Çamaşırhane', fill: '#4f5a55', saat: [8, 18] },
  c3: { id: 'rakip', ad: "Kâzım'ın Yeri", fill: '#5d4038', saat: [11, 25] },
  c6: { id: 'tefeci', ad: 'Tefeci Şakir', fill: '#4a3d2e', saat: [9, 18] },
  d5: { id: 'karaca', ad: 'Karaca Ailesi', fill: '#4a2f3a', saat: [17, 28] },
  h4: { id: 'liman', ad: 'Liman A.Ş.', fill: '#2f4a58', saat: [9, 18] },
};

// Süs / mahalle dokusu: şimdilik yalnızca hikâye ve coğrafya (v0.3'te iş ve olay getirecek).
const GEN = [
  ['Fırın', 'Sabahları ilk o açar; ekmek kokusu bütün sokağı tutar.', [5, 15]],
  ['Bakkal', 'Veresiye defteri kalın, kulağı daha da kalındır.', [7, 21]],
  ['Manav', 'Tezgâhta ne varsa mahalleli o gün onu yer.', [7, 19]],
  ['Kasap', 'Pirzola fiyatı bu semtin gerçek ekonomi göstergesidir.', [7, 18]],
  ['Berber', 'Traş olurken en çok söz duyulan yer.', [8, 20]],
  ['Kunduracı', 'Her gün biri yeni tabana, biri yeni dedikoduya gelir.', [8, 19]],
  ['Terzi', 'Dikiş makinesinin sesi kapıdan taşar.', [8, 19]],
  ['Eczane', 'Gece nöbetçi tabelası sönük; kapı zili çalışır.', [8, 20]],
  ['Postane', 'Telgraf memuru sorulmadan bilgi vermez.', [9, 17]],
  ['Belediye', 'Mühürlü kâğıt ve uzun sıralar.', [9, 17]],
  ['Banka Şubesi', 'Kayıtlı paranın yeri; kirli parayı sevmez.', [9, 16]],
  ['Hastane', 'Gece gündüz açık. Yaralıları sorgusuz alırlar, kayıt tutarlar.', [0, 24]],
  ['Cami', 'Cuma günleri avlusu dolar taşar.', [5, 22]],
  ['Kilise', 'Çanı mahalleye saati bildirir.', [6, 21]],
  ['Okul', 'Dört yüz çocuk, iki öğretmen.', [8, 16]],
  ['Hamam', 'Konuşulanlar buharla birlikte dışarı sızmaz.', [7, 22]],
  ['Kahvehane', 'Tavla zarları, gazete ve fısıltı.', [6, 24]],
  ['Gazete İdaresi', 'Yarının manşeti bu gece yazılıyor.', [10, 23]],
  ['Sinema', 'Sessiz film, canlı piyano.', [17, 24]],
  ['Tiyatro', 'Locaları semtin eşrafı tutar.', [18, 24]],
  ['Otel', 'Resepsiyondaki adam her şeyi görür, hiçbir şeyi hatırlamaz.', [0, 24]],
  ['Han', 'Yük arabaları ve yol yorgunu adamlar.', [0, 24]],
  ['Saatçi', 'Vitrinindeki saatlerin hiçbiri aynı vakti göstermez.', [9, 18]],
  ['Kuyumcu', 'Kasası geceleri iki kilitle kapanır.', [10, 18]],
  ['Çiçekçi', 'Düğüne de cenazeye de aynı güller gider.', [8, 19]],
  ['Matbaa', 'Mürekkep kokusu; bu ay dört ilan bastılar.', [8, 18]],
  ['Demirci', 'Ocak sabahtan akşama yanar.', [7, 18]],
  ['Marangoz', 'İskele tahtası, tabut, beşik: hepsini yapar.', [7, 18]],
  ['Hurdacı', 'Eski ne varsa onda yeni bir hayat bulur.', [8, 18]],
  ['Pastane', 'Şeker kıtlığında bile baklava çıkar.', [7, 21]],
  ['Dişçi', 'Kapıdaki levha: "Sıra numarası bekleyiniz".', [9, 17]],
  ['Avukat', 'Genç, aç ve her işi alır.', [9, 18]],
  ['Apartman', 'Beş kat, kırk kiracı, bir kapıcı.', [0, 24]],
  // liman sırası (son dokuz)
  ['Ambar 1', 'Kilitli ambar; içindekiler kayıtta başka türlü yazılı.', [8, 18]],
  ['Ambar 2', 'Gümrüklü mal burada bekler.', [8, 18]],
  ['Balık Hali', 'Sabah beşte açık artırma, öğlen koku.', [4, 14]],
  ['Gümrük', 'Mühür bunun elinde, uğraşan çok.', [8, 17]],
  ['Kaptanlık', 'Hangi gemi ne zaman girip çıkacak, burada bilinir.', [7, 19]],
  ['Tersane', 'Bir gövde iskelede yarım duruyor.', [7, 18]],
  ['Halat Atölyesi', 'Kenevir kokusu ve çıplak ayaklı çocuklar.', [7, 18]],
  ['Yük Ofisi', 'Hamallar buradan iş alır.', [6, 18]],
  ['Kömür Deposu', 'Kara toz her şeye siner.', [6, 18]],
];
const TONES = ['#5b4e3c', '#4d5a4c', '#5a4a4a', '#4a5260', '#605641', '#4e4458', '#564c40', '#44564f'];

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
      if (fn) rec = { id: fn.id, fn: true, ad: fn.ad, fill: fn.fill, saat: fn.saat, flavor: '' };
      else {
        const g = GEN[gi++];
        rec = { id: key, fn: false, ad: g[0], fill: TONES[(gi * 3 + L.row) % TONES.length], saat: g[2], flavor: g[1] };
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
