// Şehir yerleşimi ve yürüme yolu. Çizim yok: yalnızca koordinatlar ve yol bulma.
// Altı yatay sokak (ROWS) ve dokuz dikey bağlantı (V). Her binanın kapısı bir sokağa açılır.
// Şehir üç kuşak (her biri iki sokak) × iki yarıdan oluşur: 6 bölge, ~196 bina.
export const W = 2760, H = 1830;
export const ROWS = [230, 510, 790, 1070, 1350, 1630];
export const V = [20, 357.5, 687.5, 1017.5, 1347.5, 1677.5, 2007.5, 2337.5, 2667.5];
export const ROAD_HALF = 28;
export const WALK = 14; // oyun dakikası başına harita birimi
const BH = 90;

// p: satır öneki, row: hangi sokak, side: -1 sokağın üstünde / +1 altında
const LAYOUT = [
  { p: 't', row: 0, side: -1, n: 16, w: 140, step: 165 },
  { p: 'a', row: 0, side: 1, n: 16, w: 140, step: 165 },
  { p: 'b', row: 1, side: -1, n: 16, w: 140, step: 165 },
  { p: 'c', row: 1, side: 1, n: 16, w: 140, step: 165 },
  { p: 'd', row: 2, side: -1, n: 16, w: 140, step: 165 },
  { p: 'e', row: 2, side: 1, n: 16, w: 140, step: 165 },
  { p: 'f', row: 3, side: -1, n: 16, w: 140, step: 165 },
  { p: 'g', row: 3, side: 1, n: 16, w: 140, step: 165 },
  { p: 'i', row: 4, side: -1, n: 16, w: 140, step: 165 },
  { p: 'j', row: 4, side: 1, n: 16, w: 140, step: 165 },
  { p: 'k', row: 5, side: -1, n: 16, w: 140, step: 165 },
  { p: 'h', row: 5, side: 1, n: 20, w: 110, step: 135 },
];

// Oyunla bağlı 8 yer
const FN = {
  a12: { id: 'karakol', ad: 'Precinct House', fill: '#3c4a5c', saat: [0, 24] },
  d1: { id: 'ev', ad: 'Home', fill: '#5a5040', saat: [18, 23] },
  d3: { id: 'meyhane', ad: "Murphy's Tavern", fill: '#7a4a2a', saat: [11, 25] },
  e0: { id: 'camasir', ad: 'Laundromat', fill: '#4f5a55', saat: [8, 18] },
  e3: { id: 'rakip', ad: "Duffy's Bar", fill: '#5d4038', saat: [11, 25] },
  e9: { id: 'tefeci', ad: 'Sal the Shark', fill: '#4a3d2e', saat: [9, 18] },
  j5: { id: 'karaca', ad: 'Marchetti Family', fill: '#4a2f3a', saat: [17, 28] },
  h4: { id: 'liman', ad: 'Harbor Trust', fill: '#2f4a58', saat: [9, 18] },
};

// Süs / mahalle dokusu: her bölgenin havuzu; boş slotlar sırayla doldurulur, tekrarlar numaralanır.
const POOL = {
  hilltop: [
    ['Hotel Belmont', 'Resepsiyondaki adam her şeyi görür, hiçbir şeyi hatırlamaz.', [0, 24]],
    ['Jeweler', 'Kasası geceleri iki kilitle kapanır.', [10, 18]],
    ['Attorney', 'Genç, aç ve her işi alır.', [9, 18]],
    ['Watchmaker', 'Vitrinindeki saatlerin hiçbiri aynı vakti göstermez.', [9, 18]],
    ['Grand Theater', 'Locaları şehrin eşrafı tutar.', [18, 24]],
    ['Florist', 'Düğüne de cenazeye de aynı güller gider.', [8, 19]],
    ['Tailor', 'Dikiş makinesinin sesi kapıdan taşar.', [8, 19]],
    ['Dentist', 'Kapıdaki levha: "Sıra numarası bekleyiniz".', [9, 17]],
    ['Country Club', 'Üyelik için üç referans, bir de soyadı gerekir.', [10, 24]],
    ['Art Gallery', 'Tablolar pahalı, alıcılar sessiz.', [10, 18]],
    ['Mansion', 'Perdeler hep inik; bahçıvan bile içeri girmez.', [0, 24]],
    ['Private Library', 'Kitapların yarısı hiç açılmamış.', [9, 20]],
    ['Chauffeur Garage', 'Cilalı arabalar, bekleyen şoförler.', [7, 21]],
    ['Perfumery', 'Fransız şişeler, İtalyan fiyatlar.', [10, 19]],
  ],
  downtown: [
    ['City Hall', 'Mühürlü kâğıt ve uzun sıralar.', [9, 17]],
    ['First National Bank', 'Kayıtlı paranın yeri; kirli parayı sevmez.', [9, 16]],
    ['Daily Courier', 'Yarının manşeti bu gece yazılıyor.', [10, 23]],
    ['Post Office', 'Telgraf memuru sorulmadan bilgi vermez.', [9, 17]],
    ['Orpheum Cinema', 'Sessiz film, canlı piyano.', [17, 24]],
    ['Drugstore', 'Gece nöbetçi tabelası sönük; kapı zili çalışır.', [8, 20]],
    ["St. Mary's Hospital", 'Gece gündüz açık. Yaralıları sorgusuz alırlar, kayıt tutarlar.', [0, 24]],
    ['Department Store', 'Dört kat, bir asansör, yüz tezgâh.', [9, 19]],
    ['Courthouse', 'Merdivenlerde avukatlar, avluda şahitler.', [9, 17]],
    ['Union Station', 'Her tren yeni bir yüz, yeni bir bavul.', [0, 24]],
    ['Stock Exchange', 'Bağırışlar camdan taşar.', [9, 16]],
    ['Telephone Exchange', 'Kızlar her konuşmayı duyar, hiçbirini anlatmaz.', [0, 24]],
    ['Hat Shop', 'Fötr şapka, bir de takibe uygun gölge.', [9, 19]],
    ['Chamber of Commerce', 'Kokteyl ve kontrat, sırasıyla.', [9, 18]],
  ],
  southside: [
    ['Corner Grocer', 'Veresiye defteri kalın, kulağı daha da kalındır.', [7, 21]],
    ['Barber Shop', 'Traş olurken en çok söz duyulan yer.', [8, 20]],
    ['Bakery', 'Sabahları ilk o açar; ekmek kokusu bütün sokağı tutar.', [5, 15]],
    ["St. Patrick's Church", 'Çanı mahalleye saati bildirir.', [6, 21]],
    ['Pool Hall', 'Bilardo topu ve borç sesi.', [12, 26]],
    ['Pawn Shop', 'Her yüzük bir hikâye, her saat bir pişmanlık.', [9, 19]],
    ['Butcher Row', 'Zincirler ve sessiz pazarlıklar.', [7, 18]],
    ['Laundry Tenement', 'İp üstünde çarşaflar, avluda dedikodu.', [0, 24]],
    ['Soda Fountain', 'Çocuklar limonata içer, büyükler haber toplar.', [10, 22]],
    ['Boxing Gym', 'Terli eldivenler, kırık burunlar.', [9, 22]],
    ['Cobbler', 'Çivi ağızda, kulak kapıda.', [8, 19]],
    ['Social Hall', 'Cumartesi düğünleri, pazar toplantıları.', [10, 24]],
  ],
  eastside: [
    ['Synagogue', 'Cumartesi sabahları avlusu dolar taşar.', [5, 22]],
    ['Corner Diner', 'Kahve, gazete ve fısıltı.', [6, 24]],
    ['Boarding House', 'Yük arabaları ve yol yorgunu adamlar.', [0, 24]],
    ['Print Shop', 'Mürekkep kokusu; bu ay dört ilan bastılar.', [8, 18]],
    ['Bakeshop', 'Şeker kıtlığında bile turta çıkar.', [7, 21]],
    ['Shoe Repair', 'Her gün biri yeni tabana, biri yeni dedikoduya gelir.', [8, 19]],
    ['Public School 12', 'Dört yüz çocuk, iki öğretmen.', [8, 16]],
    ['Open Market', 'Pazarlık dört dilde yapılır.', [6, 18]],
    ['Garment Sweatshop', 'Makineler gece yarısına dek durmaz.', [7, 23]],
    ['Yiddish Theater', 'Salon küçük, alkış büyük.', [17, 24]],
    ['Deli', 'Turşu, pastırma ve eski dostlar.', [7, 21]],
    ['Pushcart Alley', 'Her arabanın bir sahibi, her sahibin bir borcu.', [6, 18]],
  ],
  flats: [
    ['Blacksmith', 'Ocak sabahtan akşama yanar.', [7, 18]],
    ['Carpenter', 'İskele tahtası, tabut, beşik: hepsini yapar.', [7, 18]],
    ['Junk Yard', 'Eski ne varsa onda yeni bir hayat bulur.', [8, 18]],
    ['Tenement', 'Beş kat, kırk kiracı, bir kapıcı.', [0, 24]],
    ['Turkish Bath', 'Konuşulanlar buharla birlikte dışarı sızmaz.', [7, 22]],
    ['Produce Stand', 'Tezgâhta ne varsa mahalleli o gün onu yer.', [7, 19]],
    ['Butcher', 'Biftek fiyatı bu semtin gerçek ekonomi göstergesidir.', [7, 18]],
    ['Rail Depot', 'Vagonlar gece boşalır, kimse içindekini sormaz.', [0, 24]],
    ['Foundry', 'Kızgın demir, çıplak kollar.', [6, 18]],
    ['Brick Yard', 'Kırmızı toz, kırmızı gözler.', [6, 18]],
    ['Cold Storage', 'Buz blokları ve kilitli kapılar.', [7, 19]],
    ['Tool & Die', 'Küçük atölye, büyük siparişler.', [7, 18]],
  ],
  docks: [
    ['Warehouse', 'Kilitli ambar; içindekiler kayıtta başka türlü yazılı.', [8, 18]],
    ['Bonded Warehouse', 'Gümrüklü mal burada bekler.', [8, 18]],
    ['Fish Market', 'Sabah beşte açık artırma, öğlen koku.', [4, 14]],
    ['Customs House', 'Mühür bunun elinde, uğraşan çok.', [8, 17]],
    ['Harbor Master', 'Hangi gemi ne zaman girip çıkacak, burada bilinir.', [7, 19]],
    ['Shipyard', 'Bir gövde iskelede yarım duruyor.', [7, 18]],
    ['Rope Works', 'Kenevir kokusu ve çıplak ayaklı çocuklar.', [7, 18]],
    ['Dock Hiring Hall', 'Hamallar buradan iş alır.', [6, 18]],
    ['Coal Yard', 'Kara toz her şeye siner.', [6, 18]],
    ['Sailors Bar', 'Her gece başka bir bayrak, aynı kavga.', [12, 27]],
    ['Cannery', 'Teneke sesi ve balık kokusu.', [6, 18]],
    ['Ship Chandler', 'Zincir, halat, fener ve sorulmayan sorular.', [7, 19]],
    ['Stevedore Union', 'Rozetli adamlar, kapalı kapı toplantıları.', [8, 20]],
    ['Grain Elevator', 'Silo uğultusu; fareler de sendikalı.', [6, 18]],
  ],
};
const TONES = ['#5b4e3c', '#4d5a4c', '#5a4a4a', '#4a5260', '#605641', '#4e4458', '#564c40', '#44564f'];
const ROMAN = ['', ' II', ' III', ' IV', ' V', ' VI'];

const dizi = (p, a, b) => Array.from({ length: b - a + 1 }, (_, i) => p + (a + i));
const blok = (lines, a, b) => lines.flatMap((p) => dizi(p, a, b));
export const BOLGELER = {
  hilltop: { ad: 'Hilltop', ac: 'Villalar, bankerler ve siyasetçiler. Para burada konuşur, ses çıkarmaz.', slots: blok(['t', 'a', 'b', 'c'], 0, 7), komsu: ['downtown', 'southside'] },
  downtown: { ad: 'Downtown', ac: 'Belediye, banka, karakol ve gazete. Şehrin resmî yüzü.', slots: blok(['t', 'a', 'b', 'c'], 8, 15), komsu: ['hilltop', 'eastside'] },
  southside: { ad: 'Southside', ac: 'Senin semtin. Dar sokaklar, sadık halk, eski borçlar.', slots: blok(['d', 'e', 'f', 'g'], 0, 7), komsu: ['hilltop', 'eastside', 'flats'] },
  eastside: { ad: 'Eastside', ac: 'Göçmen mahalleleri, pazar yerleri, kalabalık apartmanlar.', slots: blok(['d', 'e', 'f', 'g'], 8, 15), komsu: ['downtown', 'southside', 'flats'] },
  flats: { ad: 'The Flats', ac: 'Demiryolu, depo ve atölyeler. Kimse ne yüklendiğini sormaz.', slots: blok(['i', 'j'], 0, 15), komsu: ['southside', 'eastside', 'docks'] },
  docks: { ad: 'Docks', ac: "Liman. Kaçakçılık, işçi sendikaları ve yarısı Marchetti'nin olan ambarlar.", slots: [...dizi('k', 0, 15), ...dizi('h', 0, 19)], komsu: ['flats'] },
};
// Süs binalar: bölge havuzundan sırayla; havuz biterse "II", "III" eklenir.
const GENSLOT = {};
for (const [id, B] of Object.entries(BOLGELER)) {
  let i = 0;
  for (const k of B.slots) {
    if (FN[k]) continue;
    const [ad, fl, saat] = POOL[id][i % POOL[id].length];
    GENSLOT[k] = [ad + ROMAN[Math.floor(i / POOL[id].length)], fl, saat];
    i++;
  }
}

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
