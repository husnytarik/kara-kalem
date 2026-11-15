// İş yerleri ve adamlar: her bina bir işletmedir; adamlar (yumruk/bıçak/zekâ) binalara görevle gönderilir.
// Haraç bağlamak, tahsil etmek, korumak, satın almak. Çekirdek durum s.isy altında düz JSON; DOM'a dokunmaz.
import { clamp, sigmoid, DAY, log, spend, money, dateOf } from './util.js';
import { PLACES, BOLGELER, route, pathLen, WALK } from './world.js';
import { hakimOf, hakimAd, erisim, brnd, etki, aileDeg, yaraliMi, FAK } from './bolge.js';

// Bina türleri. gelir: haftalık haraç tabanı ($, servet 2 bölge için); direnc: sahibin boyun eğdirilme zorluğu (0-10).
export const TURLER = {
  esnaf: { ad: 'Esnaf', gelir: 14, direnc: 3, fiyat: 700 },
  eglence: { ad: 'Eğlence yeri', gelir: 28, direnc: 5, fiyat: 1500 },
  luks: { ad: 'Lüks işletme', gelir: 42, direnc: 6, fiyat: 2400 },
  atolye: { ad: 'Atölye / fabrika', gelir: 22, direnc: 5, fiyat: 1100 },
  depo: { ad: 'Depo / liman işi', gelir: 32, direnc: 6, fiyat: 1700 },
  konut: { ad: 'Apartman / pansiyon', gelir: 11, direnc: 2, fiyat: 500 },
  resmi: { ad: 'Resmî kurum', gelir: 0, direnc: 99, fiyat: 0 },
};
const KURAL = [
  ['resmi', /Hall$|Bank|Courier|Post Office|Hospital|Church|Synagogue|School|Courthouse|Station|Exchange|Customs|Harbor Master|Chamber|Stevedore|Precinct|Hiring/i],
  ['luks', /Hotel|Jeweler|Club|Gallery|Mansion|Perfumery|Department|Theater|Cinema|Attorney|Library|Chauffeur|Watchmaker/i],
  ['eglence', /Pool|Bar\b|Sailors|Social|Soda|Boxing|Bath|Diner/i],
  ['depo', /Warehouse|Cold Storage|Grain|Rail Depot|Coal|Ship|Cannery|Fish Market|Rope/i],
  ['atolye', /Smith|Carpenter|Foundry|Brick|Tool|Sweatshop|Junk|Print|Dentist|Tailor/i],
  ['konut', /Tenement|Boarding|Laundry/i],
];
export const turOf = (ad) => { for (const [t, re] of KURAL) if (re.test(ad)) return t; return 'esnaf'; };

export const GOREVLER = {
  haraclan: { ad: 'Haraç bağla', is: 60 },
  topla: { ad: 'Haracı topla', is: 25 },
  koru: { ad: 'Koru', is: 40 },
};
const ISIMLER = ['Vinnie', 'Moe', 'Sully', 'Bugsy', 'Lenny', 'Sal', 'Dutch', 'Frankie', 'Mickey', 'Nate', 'Ray', 'Hank', 'Joey', 'Tommy', 'Lou', 'Abe'];
const hata = (msg) => ({ ok: false, msg });
const TAMAM = { ok: true };

export function newIsy(seed) {
  const list = {};
  for (const p of Object.values(PLACES)) if (!p.fn) { const tur = turOf(p.ad); if (tur !== 'resmi') list[p.id] = { tur, sahip: null, haracli: false, birikim: 0, korumaBitis: 0 }; }
  return { seed: (seed ^ 0x51ed270b) | 0, list, adam: [], gorevler: [], sayac: 0 };
}

export const isyeri = (s, id) => s.isy.list[id] || null;
export const haftalik = (s, id) => {
  const p = PLACES[id], t = TURLER[s.isy.list[id].tur], b = s.bolge.list[p.bolge];
  return Math.round(t.gelir * (0.5 + 0.25 * b.servet) * (0.6 + 0.4 * b.huzur / 100));
};
export const fiyatOf = (s, id) => TURLER[s.isy.list[id].tur].fiyat;
// Bu binanın koruma parasını şu an kim alıyor: oyuncu (haraçlı ya da sahibi), bölgenin hakimi ya da kimse
export function kontrol(s, id) {
  const r = s.isy.list[id];
  if (!r) return null;
  if (r.sahip === 'oyuncu') return 'sahip';
  if (r.haracli) return 'haraci';
  return hakimOf(s.bolge, PLACES[id].bolge) || null;
}

// ---------- adamlar ----------
const beceri = (a) => Math.round(0.5 * a.yumruk + 0.3 * a.bicak + 0.2 * a.zeka);
export const adamBeceri = beceri;
function yeniAdam(s) {
  const I = s.isy, r = () => 20 + Math.floor(brnd(I) * 55);
  const kullanilan = new Set(I.adam.map((a) => a.ad));
  let ad = ISIMLER[Math.floor(brnd(I) * ISIMLER.length)];
  for (let i = 0; kullanilan.has(ad) && i < 40; i++) ad = ISIMLER[(ISIMLER.indexOf(ad) + 1) % ISIMLER.length];
  return { id: ++I.sayac, ad, yumruk: r(), bicak: r(), zeka: r(), gorev: null };
}
// ekip sayısı (savas.js) ile adam listesini eşitle
export function adamEsitle(s) {
  const I = s.isy, n = s.bolge.ekip;
  while (I.adam.length < n) I.adam.push(yeniAdam(s));
  while (I.adam.length > n) {
    let i = I.adam.findIndex((a) => !a.gorev);
    if (i < 0) i = I.adam.length - 1;
    const [ç] = I.adam.splice(i, 1);
    I.gorevler = I.gorevler.filter((g) => g.adam !== ç.id);
  }
}
const bosAdamlar = (s) => s.isy.adam.filter((a) => !a.gorev);
function adamSec(s, hedefId, gorev, id) {
  if (id && id !== 'auto') { const a = s.isy.adam.find((x) => x.id === +id); return a && !a.gorev ? a : null; }
  const bos = bosAdamlar(s);
  if (!bos.length) return null;
  const puan = (a) => gorev === 'haraclan' ? beceri(a) - Math.max(0, a.bicak - a.yumruk - 20) : gorev === 'koru' ? a.yumruk : a.zeka;
  return bos.reduce((m, a) => (puan(a) > puan(m) ? a : m));
}
export const adamSecOnizle = (s, hedef, gorev) => adamSec(s, hedef, gorev, 'auto');

// ---------- görevler ----------
const evKapisi = () => PLACES.meyhane;
export function yolDakika(s, id) {
  const A = evKapisi(), B = PLACES[id];
  return Math.max(5, Math.round(pathLen(A, route(A, B)) / WALK));
}
export function gorevVer(s, a) {
  adamEsitle(s);
  const id = a.hedef, r = s.isy.list[id], p = PLACES[id], G = GOREVLER[a.gorev];
  if (!G) return hata('Bilinmeyen görev.');
  if (!r) return hata('Bu yer iş yeri değil.');
  if (yaraliMi(s)) return hata('Yaralıyken adam yollayamazsın.');
  if (!erisim(s, p.bolge)) return hata(`${BOLGELER[p.bolge].ad}'da henüz ayağın yok: önce komşu bir bölgeye hakim ol.`);
  const k = kontrol(s, id);
  if (a.gorev === 'haraclan' && (k === 'haraci' || k === 'sahip')) return hata('Bu yer zaten senin.');
  if (a.gorev === 'topla' && k !== 'haraci') return hata('Toplanacak haraç yok.');
  if (a.gorev === 'topla' && r.birikim < 1) return hata('Henüz biriken para yok.');
  if (a.gorev === 'koru' && k !== 'haraci' && k !== 'sahip') return hata('Önce haraç bağla ya da satın al.');
  if (s.isy.gorevler.some((g) => g.hedef === id)) return hata('Bu yere zaten bir adam gidiyor.');
  const adam = adamSec(s, id, a.gorev, a.adam);
  if (!adam) return hata(s.isy.adam.length ? 'Boşta adam yok.' : 'Ekibinde adam yok. Önce adam tut (Adamlar sekmesi).');
  const yol = yolDakika(s, id);
  adam.gorev = a.gorev;
  s.isy.gorevler.push({ adam: adam.id, hedef: id, gorev: a.gorev, basla: s.t, yol, bitis: s.t + yol + G.is });
  log(s, `${adam.ad} ${p.ad}'a gidiyor: ${G.ad.toLowerCase()} (~${yol + G.is} dk).`, 'info');
  return TAMAM;
}
export function satinAl(s, a) {
  const id = a.hedef, r = s.isy.list[id], p = PLACES[id];
  if (!r) return hata('Bu yer iş yeri değil.');
  if (!erisim(s, p.bolge)) return hata(`${BOLGELER[p.bolge].ad}'da henüz ayağın yok.`);
  if (r.sahip === 'oyuncu') return hata('Zaten senin.');
  const f = fiyatOf(s, id);
  if (!spend(s, f, 'clean')) return hata(`Temiz para yetmiyor (${money(f)}).`);
  r.sahip = 'oyuncu'; r.haracli = false; r.birikim = 0;
  log(s, `${p.ad}'ı satın aldın (${money(f)}). Haftalık meşru gelir akacak.`, 'good', 'Sahibi olduğun yerden haraç değil, temiz kâr alırsın; polis de seni bu yüzden daha az sorgular.');
  return TAMAM;
}

function coz(s, g) {
  const I = s.isy, adam = I.adam.find((x) => x.id === g.adam), r = I.list[g.hedef], p = PLACES[g.hedef], b = s.bolge.list[p.bolge];
  if (adam) adam.gorev = null;
  if (!adam || !r) return;
  const ad = p.ad, T = TURLER[r.tur];
  if (g.gorev === 'haraclan') {
    const hk = hakimOf(s.bolge, p.bolge), rakip = hk && hk !== 'oyuncu' ? hk : null;
    const need = T.direnc * 10;
    const e = etki(b, p.bolge);
    const pw = clamp(0.38 + (beceri(adam) - need) / 60 + 0.15 * e.k + 0.1 * e.s - (b.huzur > 80 ? 0.05 : 0), 0.08, 0.95);
    if (brnd(I) < pw) {
      r.haracli = true; r.birikim = 0;
      b.kor = clamp(b.kor + 1.5, 0, 100); b.sev = clamp(b.sev - 1.5, 0, 100);
      b.tan = clamp(b.tan + 1.5, 0, 100);
      let extra = '';
      if (adam.bicak - adam.yumruk > 25 && brnd(I) < 0.3) {
        extra = ` ${adam.ad} bıçağı fazla kullandı; sahibi yaralandı.`;
        b.sev = clamp(b.sev - 5, 0, 100);
        s.pendingEvidence.push({ v: 5, why: `${ad}'da sahibi bıçaklanan esnafın dükkânını birisi gözetliyor.` });
      } else if (brnd(I) < 0.07) s.pendingEvidence.push({ v: 3, why: `${ad}'ın sahibi karakola gidip şikâyet etti.` });
      if (rakip) { aileDeg(s.bolge, rakip, -3, 2); s.bolge.ofke[rakip] = Math.min(60, s.bolge.ofke[rakip] + 6); }
      s.attBoost += 1;
      log(s, `${ad}: ${adam.ad} haraç bağladı. Haftalık ~${money(haftalik(s, g.hedef))}.${extra}`, 'good', `${T.ad} sahibi boyun eğdi (direnç ${T.direnc * 10}, adamın becerisi ${beceri(adam)}).${rakip ? ` ${hakimAd(rakip)} bunu duyacak.` : ''}`);
    } else {
      b.sev = clamp(b.sev - 1, 0, 100);
      if (brnd(I) < 0.35) {
        adam.gorev = 'tutuklu'; g.tutuk = true;
        s.pendingEvidence.push({ v: 4, why: `${adam.ad} ${ad}'da esnafı sıkıştırırken yakalandı.` });
        log(s, `${ad}: ${adam.ad} esnafı ikna edemedi ve karakola götürüldü. Üç gün sonra çıkar.`, 'bad', `Adamın becerisi (${beceri(adam)}) bu yerin direncinin (${need}) altında kaldı.`);
        g.bos = s.t + 3 * DAY; I.tutuklar = (I.tutuklar || []).concat([{ adam: adam.id, bitis: s.t + 3 * DAY }]);
      } else log(s, `${ad}: ${adam.ad} sahibi ikna edemedi. Daha becerikli bir adam gönder.`, 'warn', `Adamın becerisi (${beceri(adam)}) direncin (${need}) altında.`);
    }
  } else if (g.gorev === 'topla') {
    if (!r.haracli) { log(s, `${ad}: haraç artık sende değil.`, 'warn'); return; }
    const direnir = brnd(I) < clamp(0.25 - 0.3 * etki(b, p.bolge).k - 0.001 * adam.yumruk, 0.02, 0.4);
    const al = Math.round(r.birikim * (direnir ? 0.5 : 1));
    r.birikim = 0; s.cash.dirty += al;
    log(s, `${ad}: ${adam.ad} ${money(al)} topladı${direnir ? ' (sahibi yarısını ödedi, gerisini sonra dedi)' : ''}.`, direnir ? 'warn' : 'good');
  } else if (g.gorev === 'koru') {
    r.korumaBitis = s.t + 7 * DAY;
    b.sev = clamp(b.sev + 1, 0, 100);
    log(s, `${ad}: ${adam.ad} bir hafta boyunca kapıda nöbet tutacak.`, 'info', 'Korunan yer rakip baskısına ve soyguna karşı daha dayanıklıdır.');
  }
}
// her saat: biten görevleri çöz, tutuklular çıksın
export function isyeriSaat(s) {
  const I = s.isy;
  adamEsitle(s);
  for (const g of [...I.gorevler]) if (s.t >= g.bitis) { I.gorevler.splice(I.gorevler.indexOf(g), 1); coz(s, g); }
  if (I.tutuklar && I.tutuklar.length) {
    for (const t of [...I.tutuklar]) if (s.t >= t.bitis) {
      I.tutuklar.splice(I.tutuklar.indexOf(t), 1);
      const a = I.adam.find((x) => x.id === t.adam);
      if (a) { a.gorev = null; log(s, `${a.ad} karakoldan çıktı.`, 'info'); }
    }
  }
}
// her gün: haraç birikir, sahip olduğun yerler temiz gelir verir, rakipler haracı kapabilir
export function isyeriGun(s) {
  const I = s.isy;
  for (const [id, r] of Object.entries(I.list)) {
    const w = haftalik(s, id);
    if (r.sahip === 'oyuncu') { s.cash.clean += w * 1.5 / 7; continue; }
    if (!r.haracli) continue;
    r.birikim = Math.min(w * 3, r.birikim + w / 7);
    const p = PLACES[id], hk = hakimOf(s.bolge, p.bolge);
    if (hk && hk !== 'oyuncu' && s.t >= r.korumaBitis && brnd(I) < 0.012) {
      r.haracli = false; r.birikim = 0;
      log(s, `${p.ad}: ${hakimAd(hk)} adamları esnafı geri aldı; haracı artık onlara ödüyor.`, 'bad', 'Nöbetçi koymadığın, rakip hakimin bölgesindeki haraçlı yerler kapılabilir.');
    }
  }
}
export const sahipSayisi = (s) => Object.values(s.isy.list).filter((r) => r.sahip === 'oyuncu').length;
export const haracSayisi = (s) => Object.values(s.isy.list).filter((r) => r.haracli).length;
// harita için: adamın şimdiki konumu (görevi varsa meyhaneden binaya yürüyor)
export function adamKonum(s, g) {
  const A = PLACES.meyhane, B = PLACES[g.hedef];
  const f = clamp((s.t - g.basla) / g.yol, 0, 1);
  const r = route(A, B), pts = [{ x: A.x, y: A.y }, ...r];
  let L = pathLen(A, r) * f, i = 1;
  while (i < pts.length) {
    const d = Math.hypot(pts[i].x - pts[i - 1].x, pts[i].y - pts[i - 1].y);
    if (L <= d || i === pts.length - 1) { const t = d > 0 ? Math.min(1, L / d) : 1; return { x: pts[i - 1].x + (pts[i].x - pts[i - 1].x) * t, y: pts[i - 1].y + (pts[i].y - pts[i - 1].y) * t }; }
    L -= d; i++;
  }
  return { x: B.x, y: B.y };
}
