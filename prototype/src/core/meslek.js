// Meslekler: düz bir işe girmek, o işi öğrenmek, sonra işletmesini alıp tecrübeden pay almak.
// Tanınırlık ve korkunçluk işe kabulü etkiler; bazı işler korkuyu sever (liman), bazıları yüzünü saklamanı ister (taksi, büro).
import { clamp, DAY, log, spend, money } from './util.js';
import { fame } from './social.js';
import { etki, yaraliMi } from './bolge.js';

export const MESLEKLER = {
  taksi: {
    ad: 'Taksi şoförü', isletme: 'Taksi filosu', maas: 9, fiyat: 1800, ciro: 0.07,
    sevW: 0.6, korW: 0.0, tanC: 0.55, taban: 60,
    ac: 'Şehrin sokaklarını ezbere öğrenirsin. Tecrübeyle yürüyüş hızın artar. Yüzü tanınan şoförü kimse çağırmaz.',
    perk: 'Yürüyüş hızı', max: '+%40 hız',
  },
  hamal: {
    ad: 'Liman hamalı', isletme: 'Nakliye şirketi', maas: 8, fiyat: 1600, ciro: 0.07,
    sevW: 0.1, korW: 0.8, tanC: 0.1, taban: 62,
    ac: 'Sendika adamlarıyla omuz omuza çalışırsın. Korkulan adam rahat iş bulur. Tecrübeyle yolda pusu kurmak zorlaşır.',
    perk: 'Pusu riski', max: '−%25 pusu',
  },
  berber: {
    ad: 'Berber çırağı', isletme: 'Berber salonu', maas: 7, fiyat: 1200, ciro: 0.08,
    sevW: 0.9, korW: -0.3, tanC: 0.2, taban: 60,
    ac: 'Mahallenin dedikodusu koltuğundan akar. Sevilen adam burada tutunur. Tecrübeyle halkın sevgisi ve ihbar duyumun artar.',
    perk: 'Halk sevgisi', max: 'ayda +3 sevgi',
  },
  katip: {
    ad: 'Defter katibi', isletme: 'Muhasebe bürosu', maas: 10, fiyat: 2000, ciro: 0.06,
    sevW: 0.3, korW: -0.2, tanC: 0.6, taban: 62,
    ac: 'Rakamlarla uğraşırsın. Temiz isim ister. Tecrübeyle aklama ücretin düşer ve aklama kapasiten büyür.',
    perk: 'Aklama', max: '−%30 ücret, +%40 kapasite',
  },
};
export const BECERI_AD = ['Çaylak', 'Tecrübeli', 'Usta', 'Üstat'];
export const seviye = (xp) => (xp >= 75 ? 3 : xp >= 50 ? 2 : xp >= 25 ? 1 : 0);

const hata = (msg) => ({ ok: false, msg });
const TAMAM = { ok: true };

export function newMeslek() {
  return { is: null, beceri: { taksi: 0, hamal: 0, berber: 0, katip: 0 }, isletme: {} };
}

// İşe kabul puanı (≥ eşik ise alınırsın): bölgenin sana bakışı ve tecrüben.
export function kabul(s, j, bid) {
  const m = MESLEKLER[j], b = s.bolge.list[bid], e = etki(b, bid);
  const puan = m.taban + 0.3 * s.meslek.beceri[j] + 35 * e.s * m.sevW + 30 * e.k * m.korW - m.tanC * b.tan;
  return { puan: Math.round(puan), esik: 50, ok: puan >= 50 };
}
export const tecrube = (s, j) => s.meslek.beceri[j] / 100;
// Becerinin etkisi: işletmesi sendeyse tam, değilse çeyreği.
export const etkiGuc = (s, j) => tecrube(s, j) * (s.meslek.isletme[j] ? 1 : 0.25);

export function maasGun(s, j, bid) {
  const m = MESLEKLER[j], b = s.bolge.list[bid];
  return Math.round(m.maas * (0.7 + 0.8 * tecrube(s, j)) * (0.8 + 0.08 * b.servet) * 10) / 10;
}
export const isletmeGelir = (s, j) => {
  const m = MESLEKLER[j];
  return Math.round(m.fiyat * m.ciro * (0.6 + 0.8 * tecrube(s, j)));
};

// --- diğer sistemlere kancalar ---
export const yurumeCarpan = (s) => 1 + 0.4 * etkiGuc(s, 'taksi');
export const pusuCarpan = (s) => 1 - 0.25 * etkiGuc(s, 'hamal');
export const akalamaUcret = (s, fee) => fee * (1 - 0.3 * etkiGuc(s, 'katip'));
export const akalamaKapasite = (s) => 1 + 0.4 * etkiGuc(s, 'katip');
export const aklamaEk = (s) => (s.meslek.isletme.katip ? isletmeGelir(s, 'katip') * 3 : 0);
export const calisiyor = (s) => !!s.meslek.is;
export const mesaiCarpan = (s) => (s.meslek.is ? 0.9 : 1); // mesai: meyhaneye daha az bakarsın

// --- eylemler ---
export function isGir(s, a) {
  const M = s.meslek, j = a.j, bid = a.b;
  if (!MESLEKLER[j]) return hata('Böyle bir meslek yok.');
  if (!s.bolge.list[bid]) return hata('Böyle bir bölge yok.');
  if (M.is) return hata('Zaten bir işte çalışıyorsun. Önce ayrıl.');
  if (yaraliMi(s)) return hata('Yaralıyken işe alınmazsın.');
  const k = kabul(s, j, bid);
  if (!k.ok) return hata(`${MESLEKLER[j].ad} olarak seni almadılar (puan ${k.puan}/${k.esik}). ${s.bolge.list[bid].tan > 50 ? 'Yüzün fazla tanınıyor.' : 'Bölge sana güvenmiyor.'}`);
  M.is = { j, b: bid, since: Math.floor(s.t / DAY), gun: 0 };
  log(s, `${MESLEKLER[j].ad} olarak işe girdin (${bid}). Günlük ~${maasGun(s, j, bid)}$ temiz.`, 'good', 'Düz iş: temiz gelir, tecrübe ve meşru bir yüz. Ama meyhaneye daha az vakit kalır.');
  return TAMAM;
}
export function isBirak(s) {
  if (!s.meslek.is) return hata('Zaten işsizsin.');
  log(s, `${MESLEKLER[s.meslek.is.j].ad} işinden ayrıldın.`, 'info');
  s.meslek.is = null;
  return TAMAM;
}
export function isletmeAl(s, a) {
  const M = s.meslek, j = a.j, m = MESLEKLER[j];
  if (!m) return hata('Böyle bir meslek yok.');
  if (M.isletme[j]) return hata('Bu işletme zaten senin.');
  if (M.beceri[j] < 20) return hata(`${m.isletme} almak için bu işte en az "Tecrübeli" olmalısın (beceri 20).`);
  if (!spend(s, m.fiyat, 'clean')) return hata(`Temiz para yetmiyor (${money(m.fiyat)}).`);
  M.isletme[j] = { since: Math.floor(s.t / DAY) };
  fame(s, 'halk', 'cephe', { t: 2, i: 2 }, 1);
  log(s, `${m.isletme} satın aldın (${money(m.fiyat)}). Tecrüben (%${Math.round(M.beceri[j])}) gelirini ve avantajını belirler.`, 'good');
  return TAMAM;
}

// --- zaman ---
export function meslekGun(s) {
  const M = s.meslek, is = M.is;
  if (!is || yaraliMi(s)) return;
  const m = MESLEKLER[is.j], b = s.bolge.list[is.b];
  const k = kabul(s, is.j, is.b);
  if (k.puan < 35) { // bölge artık sana iş vermiyor
    log(s, `${m.ad} işinden kovuldun: ${b.tan > 50 ? 'herkes yüzünü tanıyor' : 'bölge sana sırt çevirdi'} (puan ${k.puan}).`, 'bad');
    M.is = null; return;
  }
  const w = maasGun(s, is.j, is.b);
  s.cash.clean += w; s.today.rev += 0;
  is.gun++;
  const xp = M.beceri[is.j];
  M.beceri[is.j] = Math.min(100, xp + 1.2 * (1 - xp / 115));
  if (seviye(M.beceri[is.j]) > seviye(xp)) log(s, `${m.ad} işinde "${BECERI_AD[seviye(M.beceri[is.j])]}" oldun.`, 'good');
  fame(s, 'halk', 'cephe', { i: 0.25 }, 1);
}
export function meslekAy(s, R) {
  const M = s.meslek;
  let top = 0;
  for (const j of Object.keys(M.isletme)) {
    const g = isletmeGelir(s, j);
    s.cash.clean += g; top += g;
    if (j === 'berber') for (const b of Object.values(s.bolge.list)) b.sev = clamp(b.sev + 3 * tecrube(s, 'berber') * (b.hakim === 'oyuncu' ? 1 : 0.4), 0, 100);
  }
  if (top > 0) R.push(`İŞLETMELER  ${Object.keys(M.isletme).map((j) => MESLEKLER[j].isletme).join(', ')} · temiz gelir ${money(top)}`);
  // işletmesi olan, çalışmasa da usta kalır; işsiz kalan beceri çok yavaş körelir
  for (const j of Object.keys(M.beceri)) if (!(M.is && M.is.j === j) && !M.isletme[j]) M.beceri[j] = Math.max(0, M.beceri[j] - 0.3);
}
