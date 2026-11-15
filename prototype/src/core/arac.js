// Araba: yürüyüş yerine sürmek hızlıdır ama araç, yakıt ve bakım ister.
// Güç (hakim olunan bölgeler), ekip ve para büyüdükçe yakıt, bakım ve arıza derdi azalır: "kolaylık".
import { clamp, DAY, log, spend, money } from './util.js';
import { oyuncuBolgeleri, brnd } from './bolge.js';

export const ARACLAR = {
  ford: { ad: 'Ford Model T', fiyat: 600, hiz: 2.0, tank: 30, tuk: 0.9, bakim: 30, guv: 1.0, pusu: 0.9, ac: 'Ucuz ve dayanıklı ama yavaş. Arızaya yatkın.' },
  buick: { ad: 'Buick Master Six', fiyat: 1800, hiz: 2.6, tank: 45, tuk: 1.1, bakim: 70, guv: 0.6, pusu: 0.8, ac: 'Hızlı, rahat. Pusuya karşı biraz daha korunaklı.' },
  packard: { ad: 'Packard Twin Six', fiyat: 4200, hiz: 3.2, tank: 60, tuk: 1.5, bakim: 140, guv: 0.35, pusu: 0.65, ac: 'Şehrin en gösterişli arabası: çok hızlı, sağlam, pusuya zor yakalanır. Yakıt içer.' },
};
export const YAKIT_FIYAT = 1.8; // litre başına, kolaylık yokken
const hata = (msg) => ({ ok: false, msg });
const TAMAM = { ok: true };

export const newArac = (seed) => ({ seed: (seed ^ 0x2545f491) | 0, tip: null, yakit: 0, kullan: false, ariza: 0, yol: 0 });

// 0..1: ekibin, paran ve bölgelerin büyüdükçe işler "halledilir" (kendi benzin deposu, bakım ustası, şoför...)
export function kolaylik(s) {
  const ek = Math.min(1, s.bolge.ekip / 8), pa = Math.min(1, (s.cash.clean + s.cash.dirty) / 15000), bo = Math.min(1, oyuncuBolgeleri(s).length / 4);
  return clamp(0.4 * ek + 0.3 * pa + 0.3 * bo, 0, 1);
}
export const yakitFiyat = (s) => YAKIT_FIYAT * (1 - 0.6 * kolaylik(s));
export const bakimGider = (s) => (s.arac.tip ? Math.round(ARACLAR[s.arac.tip].bakim * (1 - 0.5 * kolaylik(s))) : 0);
export const arizaP100 = (s) => (s.arac.tip ? 0.004 * ARACLAR[s.arac.tip].guv * (1 - 0.8 * kolaylik(s)) * 100 : 0); // 100 px'te
export const aracSurulur = (s) => !!(s.arac.tip && s.arac.kullan && s.arac.yakit > 0 && s.t >= s.arac.ariza);
export const aracHiz = (s) => (aracSurulur(s) ? ARACLAR[s.arac.tip].hiz : 1);
export const aracPusu = (s) => (aracSurulur(s) ? ARACLAR[s.arac.tip].pusu : 1);

// Her dakika yürüyüş adımından sonra: yakıt yanar, arıza çıkabilir.
export function aracAdim(s, dist) {
  const a = s.arac;
  if (!aracSurulur(s)) return;
  const T = ARACLAR[a.tip];
  a.yakit = Math.max(0, a.yakit - T.tuk * dist / 100);
  a.yol += dist;
  if (a.yakit <= 0) { log(s, `${T.ad}'in benzini bitti; yürümeye devam ediyorsun. Bir yerden yakıt almalısın.`, 'warn'); return; }
  if (brnd(a) < arizaP100(s) / 100 * dist) {
    const masraf = Math.round(30 * (1 - 0.5 * kolaylik(s)));
    a.ariza = s.t + 90;
    spend(s, masraf, 'dirty');
    log(s, `${T.ad} yolda bozuldu: 90 dakika yürüyeceksin. Tamir ${money(masraf)}.`, 'bad', 'Güçlü, kalabalık ve zengin bir adamın arabası daha az bozulur: ustası, yedek parçası hazırdır.');
  }
}

export function aracAl(s, a) {
  const T = ARACLAR[a.tip];
  if (!T) return hata('Böyle bir araba yok.');
  if (s.arac.tip) return hata('Zaten bir araban var. Önce sat.');
  if (!spend(s, T.fiyat, 'clean')) return hata(`Temiz para yetmiyor (${money(T.fiyat)}).`);
  s.arac.tip = a.tip; s.arac.yakit = T.tank * 0.5; s.arac.kullan = true; s.arac.ariza = 0;
  log(s, `${T.ad} aldın (${money(T.fiyat)}). Depoda yarım benzin var; artık sokakta arabayla gidebilirsin.`, 'good');
  return TAMAM;
}
export function aracSat(s) {
  if (!s.arac.tip) return hata('Araban yok.');
  const T = ARACLAR[s.arac.tip], g = Math.round(T.fiyat * 0.6);
  s.cash.clean += g;
  log(s, `${T.ad} satıldı (${money(g)}).`, 'info');
  s.arac.tip = null; s.arac.yakit = 0; s.arac.kullan = false;
  return TAMAM;
}
export function aracSur(s, a) {
  if (!s.arac.tip) return hata('Araban yok.');
  s.arac.kullan = !!a.v;
  return TAMAM;
}
export function benzinAl(s) {
  if (!s.arac.tip) return hata('Araban yok.');
  const T = ARACLAR[s.arac.tip], f = yakitFiyat(s), eksik = T.tank - s.arac.yakit;
  if (eksik < 1) return hata('Depo zaten dolu.');
  const para = s.cash.dirty + s.cash.clean, l = Math.min(Math.floor(eksik), Math.floor(para / f));
  if (l < 1) return hata('Benzin için para yetmiyor.');
  spend(s, l * f, 'dirty');
  s.arac.yakit += l;
  log(s, `${l} litre benzin aldın (${money(l * f)}).`, 'info');
  return TAMAM;
}
export function aracAy(s, R) {
  if (!s.arac.tip) return;
  const g = bakimGider(s);
  if (spend(s, g, 'dirty')) R.push(`ARABA  ${ARACLAR[s.arac.tip].ad} bakım ${money(g)}`);
  else { s.arac.ariza = s.t + 3 * DAY; R.push('ARABA  bakım parası çıkmadı: araba 3 gün serviste.'); }
}
