// Yaşayan şehir: bölgelerde kendiliğinden gelişen sokak olayları, hava ve haberler.
// Kendi tohumlu RNG'sini kullanır (s.sehir.seed); oyunun geri kalan rastgele akışını bozmaz.
import { clamp, dateOf, DAY, log, spend, money } from './util.js';
import { fame } from './social.js';
import { PLACES, BOLGELER } from './world.js';
import { brnd, hakimOf, addInf, aileDeg, FAK } from './bolge.js';

export function newSehir(seed) {
  return { seed: (seed ^ 0x5bd1e995) | 0, isaret: [], hava: { tip: 'acik', bit: 0 }, haber: [], kart: 0, sayi: 0 };
}

export const HAVA_AD = { acik: 'Açık', yagmur: 'Yağmurlu', kar: 'Karlı', sis: 'Sisli', sicak: 'Bunaltıcı sıcak' };
const HAVA_HAVUZ = [
  [['acik', 5], ['yagmur', 3], ['sis', 2]],
  [['acik', 7], ['sicak', 2], ['yagmur', 1]],
  [['yagmur', 4], ['sis', 2.5], ['acik', 3.5]],
  [['kar', 4.5], ['acik', 3], ['sis', 2.5]],
];
const pick = (st, list) => {
  const tot = list.reduce((a, x) => a + x[1], 0);
  let r = brnd(st) * tot;
  for (const x of list) { r -= x[1]; if (r <= 0) return x[0]; }
  return list[list.length - 1][0];
};

const B = (s, b) => s.bolge.list[b];
const kl = (x) => clamp(x, 0, 100);
const sev = (b, d) => { b.sev = kl(b.sev + d); };
const kor = (b, d) => { b.kor = kl(b.kor + d); };
const huzur = (b, d) => { b.huzur = kl(b.huzur + d); };
const ilerle = (b, d) => { b.ilerleme = clamp(b.ilerleme + d, 0, 100); };

// Otomatik olaylar: oyuncu karışmaz, şehir kendi kendine yaşar. yer: bölgeye göre ağırlık.
export const OLAYLAR = {
  dugun: { ikon: '💍', gun: 3, yer: { southside: 3, eastside: 3, hilltop: 1.5, downtown: 1, flats: 1, docks: 0.5 },
    metin: (ad) => `${ad}'da büyük bir düğün var; mahalle şenlendi.`, uygula: (s, b) => { sev(b, 4); huzur(b, 3); } },
  cenaze: { ikon: '🕯', gun: 2, yer: { southside: 2, eastside: 2, flats: 2, docks: 1.5, hilltop: 1, downtown: 1 },
    metin: (ad) => `${ad}'da saygın bir adamın cenazesi kalktı; sokaklar sessiz.`, uygula: (s, b) => { huzur(b, 2); kor(b, -2); } },
  pazar: { ikon: '🛒', gun: 4, yer: { eastside: 4, southside: 2, downtown: 2, flats: 1, hilltop: 0.5, docks: 1 },
    metin: (ad) => `${ad}'da pazar yeri canlandı; esnaf iyi kazanıyor.`, uygula: (s, b) => { ilerle(b, 8); sev(b, 1); } },
  festival: { ikon: '🎺', gun: 3, yer: { eastside: 3, southside: 3, downtown: 2, hilltop: 1, flats: 0.7, docks: 0.7 },
    metin: (ad) => `${ad}'da sokak festivali: bando, fener, kalabalık.`, uygula: (s, b) => { sev(b, 5); huzur(b, 4); ilerle(b, 6); } },
  yangin: { ikon: '🔥', gun: 4, yer: { flats: 3, docks: 3, eastside: 2, southside: 1.5, downtown: 1, hilltop: 0.5 },
    metin: (ad) => `${ad}'da bir binada yangın çıktı; itfaiye geç kaldı.`, uygula: (s, b) => { ilerle(b, -10); huzur(b, -5); if (b.servet > 1 && brnd(s.sehir) < 0.15) b.servet--; } },
  polis: { ikon: '🚓', gun: 3, yer: { downtown: 3, hilltop: 1.5, eastside: 2, southside: 2, flats: 1.5, docks: 1.5 },
    metin: (ad) => `Polis ${ad}'da toplu tarama yaptı; kapı kapı arıyorlar.`, uygula: (s, b) => { huzur(b, -3); kor(b, 3); if (hakimOf(s.bolge, b.id) === 'oyuncu') s.attBoost += 4; } },
  secim: { ikon: '🗳', gun: 6, yer: { hilltop: 3, downtown: 3, eastside: 1.5, southside: 1, flats: 0.5, docks: 0.5 },
    metin: (ad) => `${ad}'da seçim propagandası: Belediye Makinesi mahalleye yemek dağıtıyor.`, uygula: (s, b) => { addInf(b, 'tammany', 3); sev(b, 2); } },
  grip: { ikon: '🤒', gun: 5, yer: { eastside: 2.5, flats: 2.5, southside: 2, docks: 1.5, downtown: 1, hilltop: 0.5 }, mevsim: [3, 0],
    metin: (ad) => `${ad}'da grip yayılıyor; evler kapalı, dükkânlar boş.`, uygula: (s, b) => { huzur(b, -4); ilerle(b, -4); } },
  acilis: { ikon: '🏪', gun: 4, yer: { downtown: 2, eastside: 2, southside: 1.5, hilltop: 1, flats: 1, docks: 1 },
    metin: (ad) => `${ad}'da yeni bir dükkân açıldı; semt biraz canlandı.`, uygula: (s, b) => { ilerle(b, 10); } },
  kavga: { ikon: '👊', gun: 2, yer: { docks: 3, flats: 3, eastside: 2, southside: 1.5, downtown: 1, hilltop: 0.3 },
    metin: (ad) => `${ad}'da sokak kavgası: iki grup birbirine girdi, bıçaklar çekildi.`, uygula: (s, b) => { huzur(b, -5); kor(b, 3); sev(b, -1); } },
  hirsiz: { ikon: '🥷', gun: 3, yer: { downtown: 2, hilltop: 2, eastside: 2, flats: 2, southside: 1, docks: 1.5 },
    metin: (ad) => `${ad}'da hırsızlık dalgası: pencereler, arabalar, cüzdanlar.`, uygula: (s, b) => { huzur(b, -6); sev(b, -2); } },
  gemi: { ikon: '🚢', gun: 3, yer: { docks: 6 },
    metin: (ad) => `${ad}'a büyük bir yük gemisi yanaştı; hamallar gece vardiyasında.`, uygula: (s, b) => { ilerle(b, 8); kor(b, 1); } },
};

// Karar isteyen sokak olayları: pusu gibi system kartlar; oyuncu bölgeyle bağlı olduğunda gelir.
const ad = (card) => BOLGELER[card.data.b].ad;
const bd = (s, card) => s.bolge.list[card.data.b];
const dir = (s, card) => hakimOf(s.bolge, card.data.b);
const pay = (s, n, mode) => spend(s, n, mode);
const can = (n, mode = 'dirty') => (s) => (mode === 'clean' ? s.cash.clean >= n : s.cash.dirty + s.cash.clean >= n);
const kanit = (s, v, why) => s.pendingEvidence.push({ v, why });

export const SOKAK_KARTLARI = {
  grev_k: {
    title: 'Grev', system: true, window: 3, def: 2,
    text: (s, c) => `${ad(c)}'da işçiler iş bıraktı. Kapıda nöbet tutuyorlar; patronlar sana haber yolladı: "Bu işi çözebilecek bir sen varsın."`,
    options: () => [
      { label: 'İşçilerin yanında dur ($150 temiz bağış).', hint: 'Halk sevgisi +10, huzur +2. Patronlar sana soğuk bakar.', can: can(150, 'clean'),
        run: (s, c) => { pay(s, 150, 'clean'); const b = bd(s, c); sev(b, 10); kor(b, -3); huzur(b, 2); fame(s, 'halk', 'cephe', { i: 3, t: 2 }, 1); } },
      { label: 'Grev kırıcı tut ($200 kirli).', hint: 'Grev biter; halk sevgisi −8, korku +8, huzur −4.', can: can(200),
        run: (s, c) => { pay(s, 200, 'dirty'); const b = bd(s, c); sev(b, -8); kor(b, 8); huzur(b, -4); b.tan = kl(b.tan + 3); fame(s, 'halk', 'golge', { k: 3, i: -3 }, 1); } },
      { label: 'Karışma.', hint: 'Huzur −4.', run: (s, c) => huzur(bd(s, c), -4) },
    ],
  },
  hirsizlik_k: {
    title: 'Hırsızlık dalgası', system: true, window: 3, def: 2,
    text: (s, c) => `${ad(c)}'da esnafın camı kırılıyor, kasalar boşalıyor. "Sen buranın hakimisin," diyor dükkâncılar, "sokağa kimin çıktığına bakmayacak mısın?"`,
    options: () => [
      { label: 'Adamlarını sokağa sal ($80 kirli).', hint: 'Huzur +8, halk sevgisi +3.', can: can(80),
        run: (s, c) => { pay(s, 80, 'dirty'); const b = bd(s, c); huzur(b, 8); sev(b, 3); kor(b, 2); } },
      { label: 'Hırsızı bulup herkesin önünde cezalandır.', hint: 'Korku +6, huzur +4, halk sevgisi −2. Polis duyabilir.',
        run: (s, c) => { const b = bd(s, c); kor(b, 6); huzur(b, 4); sev(b, -2); fame(s, 'halk', 'golge', { k: 3 }, 1); if (brnd(s.sehir) < 0.2) kanit(s, 4, 'Sokakta bir adamı dövdüğün bir tanık tarafından ifade edildi.'); } },
      { label: 'Önemseme.', hint: 'Huzur −5, halk sevgisi −3.', run: (s, c) => { const b = bd(s, c); huzur(b, -5); sev(b, -3); } },
    ],
  },
  esnaf_k: {
    title: 'Esnaf yardım istiyor', system: true, window: 3, def: 2,
    text: (s, c) => `${ad(c)}'da bir bakkal elindeki şapkayı yoğuruyor: "${FAK[dir(s, c) && dir(s, c) !== 'oyuncu' ? dir(s, c) : 'marchetti'].ad} adamları haftalık pay istiyor. Biz zor geçiniyoruz. Bize bir kapı ol."`,
    options: () => [
      { label: 'Korumana al ($100 kirli).', hint: 'Halk sevgisi +8, bölgede nüfuzun +3. Bölgenin hakimi hoşlanmaz.', can: can(100),
        run: (s, c) => { pay(s, 100, 'dirty'); const b = bd(s, c); sev(b, 8); addInf(b, 'oyuncu', 3); const h = dir(s, c); if (h && h !== 'oyuncu') aileDeg(s.bolge, h, -4, 0); } },
      { label: 'Polise gitmelerini söyle.', hint: 'Halk sevgisi −2. Polis tanır.', run: (s, c) => { sev(bd(s, c), -2); fame(s, 'polis', 'cephe', { t: 1 }, 1); } },
      { label: 'Elimden bir şey gelmez.', hint: 'Halk sevgisi −5.', run: (s, c) => sev(bd(s, c), -5) },
    ],
  },
  gazeteci_k: {
    title: 'Gazeteci soruyor', system: true, window: 3, def: 2,
    text: (s, c) => `${ad(c)}'da Chronicle'dan genç bir muhabir seni durdurdu: "Bu semtte işlerin sana göre yürüdüğünü söylüyorlar. Birkaç soru?"`,
    options: () => [
      { label: 'Röportaj ver.', hint: 'Tanınırlık +8, halkın gözünde iyi biri ol (+). Polis seni daha yakından izler.',
        run: (s, c) => { const b = bd(s, c); b.tan = kl(b.tan + 8); sev(b, 3); fame(s, 'halk', 'cephe', { t: 3, i: 2 }, 1); s.attBoost += 3; } },
      { label: 'Hikâyeyi gömdür ($150 kirli).', hint: 'Haber çıkmaz; ağzı kapalı kalır.', can: can(150),
        run: (s, c) => { pay(s, 150, 'dirty'); } },
      { label: 'Kovala.', hint: 'Korku +3. %35 ihtimalle düşman bir yazı çıkar (Dosya +4).',
        run: (s, c) => { kor(bd(s, c), 3); if (brnd(s.sehir) < 0.35) kanit(s, 4, 'Gazetede seni kötüleyen bir yazı çıktı.'); } },
    ],
  },
  kayip_k: {
    title: 'Kayıp çocuk', system: true, window: 2, def: 2,
    text: (s, c) => `${ad(c)}'da bir kadın ağlayarak yanına geldi: oğlu akşamdan beri yok. Polis ilgilenmedi.`,
    options: () => [
      { label: 'Adamlarınla ara ($60 kirli).', hint: 'Çocuk bulunur. Halk sevgisi +12.', can: can(60),
        run: (s, c) => { pay(s, 60, 'dirty'); const b = bd(s, c); sev(b, 12); huzur(b, 2); fame(s, 'halk', 'cephe', { i: 4, t: 2 }, 1); } },
      { label: 'Polise bırak.', hint: 'Bir şey değişmez.', run: () => {} },
      { label: 'Umursama.', hint: 'Halk sevgisi −4.', run: (s, c) => sev(bd(s, c), -4) },
    ],
  },
  kumar_k: {
    title: 'Sokak kumarı', system: true, window: 3, def: 2,
    text: (s, c) => `${ad(c)}'da bir arka sokakta zar ve iskambil masası kurulmuş. Başındaki adam seni tanıyor: "Pay istersen, pay veririz."`,
    options: () => [
      { label: 'Pay iste (+$150 kirli).', hint: 'Para gelir; huzur −3. %25 ihtimalle ihbar (Dosya +3).',
        run: (s, c) => { s.cash.dirty += 150; huzur(bd(s, c), -3); if (brnd(s.sehir) < 0.25) kanit(s, 3, 'Sokak kumarından pay aldığın bir ihbarla duyuldu.'); } },
      { label: 'Dağıt.', hint: 'Korku +4, halk sevgisi +2, huzur +3.', run: (s, c) => { const b = bd(s, c); kor(b, 4); sev(b, 2); huzur(b, 3); } },
      { label: 'Görmezden gel.', hint: 'Bir şey olmaz.', run: () => {} },
    ],
  },
  gemi_k: {
    title: 'Kaçak gemi', system: true, window: 3, def: 2,
    text: () => `Docks'ta geceleyin sönük fenerli bir gemi yanaştı. Mürettebattan biri sana yaklaştı: "Yükün bir kısmı konuşulmadan inebilir. Gözünü yumarsan payın var."`,
    options: () => [
      { label: 'Yükten pay al (+$300 kirli).', hint: 'Marchetti görüşü −3. %30 ihtimalle liman soruşturması (Dosya +6).',
        run: (s, c) => { s.cash.dirty += 300; aileDeg(s.bolge, 'marchetti', -3, 0); bd(s, c).tan = kl(bd(s, c).tan + 3); if (brnd(s.sehir) < 0.3) kanit(s, 6, 'Limandaki kaçak yük soruşturmasında adın geçti.'); } },
      { label: 'Marchetti\'ye haber ver.', hint: 'Marchetti görüşü +8; ama liman gözünde "ispiyoncu" olursun (halk sevgisi −3).',
        run: (s, c) => { aileDeg(s.bolge, 'marchetti', 8, 0); sev(bd(s, c), -3); } },
      { label: 'Karışma.', hint: 'Bir şey olmaz.', run: () => {} },
    ],
  },
};
// Hangi olayların kartı var, hangi bölgelerde geçerli
const KART_KOS = {
  grev_k: (s, b) => ['flats', 'docks'].includes(b),
  hirsizlik_k: (s, b) => hakimOf(s.bolge, b) === 'oyuncu',
  esnaf_k: (s, b) => (B(s, b).inf.oyuncu || 0) >= 5 || hakimOf(s.bolge, b) === 'oyuncu',
  gazeteci_k: (s, b) => b === 'downtown' && (B(s, b).tan >= 15 || hakimOf(s.bolge, 'southside') === 'oyuncu'),
  kayip_k: (s, b) => hakimOf(s.bolge, b) === 'oyuncu' || b === 'southside',
  kumar_k: (s, b) => ['flats', 'eastside', 'docks', 'southside'].includes(b) && (B(s, b).inf.oyuncu || 0) >= 5,
  gemi_k: (s, b) => b === 'docks' && s.kurum.liman.hisse >= 0,
};

function haber(s, text, b, ikon) {
  const h = s.sehir.haber;
  h.push({ t: s.t, text, b, ikon });
  if (h.length > 40) h.shift();
  log(s, `${ikon || '📰'} ${text}`, 'info');
}

function bolgeIsaret(s, b, tip, bit) {
  const st = s.sehir;
  const bina = Object.values(PLACES).filter((p) => p.bolge === b);
  const p = bina[Math.floor(brnd(st) * bina.length)];
  st.isaret.push({ id: ++st.sayi, b, tip, ikon: (OLAYLAR[tip] || {}).ikon || '❗', x: p.x, y: p.by + p.bh / 2, bit });
  if (st.isaret.length > 14) st.isaret.shift();
}

export function sehirGun(s, pushCard) {
  const st = s.sehir, day = Math.floor(s.t / DAY), season = dateOf(s.t).season;
  // süresi dolan işaretler
  st.isaret = st.isaret.filter((i) => i.bit > s.t);
  // hava
  if (s.t >= st.hava.bit) {
    st.hava = { tip: pick(st, HAVA_HAVUZ[season]), bit: s.t + DAY * (1 + Math.floor(brnd(st) * 3)) };
    if (st.hava.tip !== 'acik') haber(s, `Hava: ${HAVA_AD[st.hava.tip].toLowerCase()}.`, null, { yagmur: '🌧', kar: '❄', sis: '🌫', sicak: '☀' }[st.hava.tip]);
  }
  // sokak olayı: günde ~0,7
  if (brnd(st) < 0.7) {
    const ids = Object.keys(BOLGELER);
    const w = [];
    for (const b of ids) for (const [tip, o] of Object.entries(OLAYLAR)) {
      let a = o.yer[b] || 0;
      if (o.mevsim && !o.mevsim.includes(season)) a *= 0.2;
      if (tip === 'yangin' && B(s, b).huzur < 40) a *= 1.5;
      if ((tip === 'hirsiz' || tip === 'kavga') && B(s, b).huzur < 50) a *= 1.6;
      if (st.isaret.some((i) => i.b === b && i.tip === tip)) a = 0;
      if (a > 0) w.push([[b, tip], a]);
    }
    const [b, tip] = pick(st, w);
    const o = OLAYLAR[tip], bl = B(s, b);
    bl.id = b;
    o.uygula(s, bl);
    haber(s, o.metin(BOLGELER[b].ad), b, o.ikon);
    bolgeIsaret(s, b, tip, s.t + o.gun * DAY);
  }
  // karar isteyen olay: 3 günde en çok bir
  if (day >= st.kart && brnd(st) < 0.35 && !s.cards.some((c) => SOKAK_KARTLARI[c.ev])) {
    const adaylar = [];
    for (const [id, kos] of Object.entries(KART_KOS)) for (const b of Object.keys(BOLGELER)) if (kos(s, b) && (s.cool[id] || 0) <= dateOf(s.t).day) adaylar.push([[id, b], 1]);
    if (adaylar.length) {
      const [id, b] = pick(st, adaylar);
      st.kart = day + 3;
      pushCard(s, id, { b, title: `${SOKAK_KARTLARI[id].title} — ${BOLGELER[b].ad}` });
      s.cool[id] = dateOf(s.t).day + 8;
    }
  }
}
