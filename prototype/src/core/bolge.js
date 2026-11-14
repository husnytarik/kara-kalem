// Bölgeler: kim hakim, bölge ne kadar büyük, kim nereye genişliyor. DOM'a dokunmaz; durum düz JSON'dur.
// Kendi tohumlu RNG'sini kullanır (s.bolge.seed): bölge sistemi oyunun geri kalanının rastgele akışını bozmaz.
import { clamp, dateOf, DAY, log, spend, staff } from './util.js';
import { fame, perceived } from './social.js';
import { BOLGELER } from './world.js';
import { EKIP_MAAS, MEKAN_BOLGE, dusmanBaskin } from './savas.js';

export const HAKIM_ESIK = 35;       // hakim olmak için en az nüfuz
export const SERVET_MAX = 5;
export const HAVUZ = 600;           // servet başına aylık haraç tabanı ($)
export const ADAM_MAAS = 40;        // garnizondaki adam başına aylık gider (kirli)
export const GARNIZON_MAX = 6;
export const HARAC = [
  { ad: 'Yok', oran: 0 },
  { ad: 'Hafif %8', oran: 0.08 },
  { ad: 'Orta %15', oran: 0.15 },
  { ad: 'Ağır %25', oran: 0.25 },
];
export const FAK = {
  oyuncu: { ad: 'Sen', renk: '#e0b24a' },
  marchetti: { ad: 'Marchetti Family', renk: '#c2506b', saldirgan: 1.0 },
  obrien: { ad: "O'Brien Çetesi", renk: '#58a866', saldirgan: 1.25 },
  tammany: { ad: 'Belediye Makinesi', renk: '#5f8fc4', saldirgan: 0.35 },
};
const NPC = ['marchetti', 'obrien', 'tammany'];
const BEKLEME = { himaye: 3, hediye: 3, gozdagi: 5 }; // aynı bölgede aynı iş için gün
const IS_AD = { himaye: 'Esnafa himaye sat', hediye: 'Mahalleye ziyafet ver', gozdagi: 'Rakip adamları sindir' };

const B0 = {
  hilltop: { inf: { tammany: 70, marchetti: 10 }, servet: 4, ilerleme: 40, huzur: 80, tan: 3 },
  downtown: { inf: { tammany: 55, obrien: 15, marchetti: 10 }, servet: 4, ilerleme: 20, huzur: 70, tan: 8 },
  southside: { inf: { oyuncu: 25, obrien: 15, marchetti: 15 }, servet: 2, ilerleme: 30, huzur: 60, tan: 55 },
  eastside: { inf: { obrien: 60, marchetti: 15 }, servet: 3, ilerleme: 50, huzur: 65, tan: 12 },
  flats: { inf: { marchetti: 65, obrien: 10 }, servet: 3, ilerleme: 10, huzur: 70, tan: 6 },
  docks: { inf: { marchetti: 45, tammany: 20, obrien: 10 }, servet: 4, ilerleme: 60, huzur: 60, tan: 6 },
};

export function newBolge(seed) {
  const list = {};
  for (const [id, b] of Object.entries(B0)) list[id] = { inf: { ...b.inf }, servet: b.servet, ilerleme: b.ilerleme, huzur: b.huzur, garnizon: 0, harac: 1, sonIs: {}, yatirimAy: -99, hakim: null, tan: b.tan };
  const st = { seed: (seed * 7919 + 13) | 0, ofke: { marchetti: 0, obrien: 0, tammany: 0 }, ekip: 0, yarali: 0, kapali: 0, list };
  for (const id of Object.keys(list)) list[id].hakim = hakimOf(st, id);
  return st;
}

export const yaraliMi = (s) => s.t < s.bolge.yarali;
export function brnd(st) {
  st.seed = (st.seed + 0x6d2b79f5) | 0;
  let t = st.seed;
  t = Math.imul(t ^ (t >>> 15), t | 1);
  t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
  return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
}

// ---------- okuma ----------
export function hakimOf(st, id) {
  const inf = st.list[id].inf;
  let best = null, bv = HAKIM_ESIK - 1e-9;
  for (const f of Object.keys(FAK)) if ((inf[f] || 0) > bv) { bv = inf[f]; best = f; }
  return best;
}
export const havuz = (b) => HAVUZ * b.servet;
export const hakimAd = (f) => (f ? FAK[f].ad : 'Sahipsiz');
export const oyuncuBolgeleri = (s) => Object.keys(s.bolge.list).filter((id) => hakimOf(s.bolge, id) === 'oyuncu');

// Güç Puanı terimi: her bölgede nüfuzun yarısı ölçüsünde (50 ve üstü tam) 4 puan.
export function bolgeGP(s) {
  const toplam = Object.values(s.bolge.list).reduce((a, b) => a + Math.min(1, (b.inf.oyuncu || 0) / 50), 0);
  return { n: oyuncuBolgeleri(s).length, v: 4 * toplam };
}

// Bu bölgede iş yapabilir misin? Orada bir ayağın olmalı ya da komşu bölgeye hakim olmalısın: genişleme böyle olur.
export function erisim(s, id) {
  const st = s.bolge;
  if ((st.list[id].inf.oyuncu || 0) >= 15) return true;
  return BOLGELER[id].komsu.some((k) => hakimOf(st, k) === 'oyuncu');
}

export function ikinci(b, f) {
  let v = 0;
  for (const k of Object.keys(b.inf)) if (k !== f && b.inf[k] > v) v = b.inf[k];
  return v;
}

export function kudret(st, f) {
  let k = 2;
  for (const id of Object.keys(st.list)) if (hakimOf(st, id) === f) k += st.list[id].servet;
  return k;
}

// ---------- nüfuz ----------
// f'nin nüfuzu d kadar artar; toplam 100'ü geçerse diğerleri orantılı küçülür. (d < 0 ise f küçülür.)
export function addInf(b, f, d) {
  b.inf[f] = clamp((b.inf[f] || 0) + d, 0, 100);
  let top = 0;
  for (const k of Object.keys(b.inf)) top += b.inf[k];
  if (top > 100) {
    const others = top - b.inf[f];
    const k = others > 0 ? (100 - b.inf[f]) / others : 0;
    for (const o of Object.keys(b.inf)) if (o !== f) b.inf[o] *= k;
  }
  for (const k of Object.keys(b.inf)) if (b.inf[k] < 0.05) delete b.inf[k];
}

export function hakimDegisti(s, id, onceki) {
  const st = s.bolge, ad = BOLGELER[id].ad, yeni = hakimOf(st, id);
  if (yeni === onceki) return;
  st.list[id].hakim = yeni;
  if (yeni === 'oyuncu') log(s, `${ad} artık senin. Bölgenin hakimisin.`, 'good', 'Nüfuzun bölgedeki herkesinkinden yüksek ve %35\'in üstünde. Haraç toplayabilir, yatırım yapıp bölgeyi büyütebilirsin.');
  else if (onceki === 'oyuncu') log(s, `${ad}'ı kaybettin: artık ${hakimAd(yeni)} hakim.`, 'bad', 'Nüfuzun %35\'in altına düştü ya da biri seni geçti. Garnizon ve himaye işleriyle geri alabilirsin.');
  else if (yeni) log(s, `${ad}: ${hakimAd(yeni)} bölgeyi ${onceki ? hakimAd(onceki) + "'ten" : 'sahipsizlikten'} aldı.`, 'info');
  else log(s, `${ad} sahipsiz kaldı: ${hakimAd(onceki)} nüfuzunu yitirdi.`, 'info');
}

// ---------- oyuncu eylemleri (sonuç: {ok, msg}) ----------
const hata = (msg) => ({ ok: false, msg });
const TAMAM = { ok: true };

export function bolgeIs(s, a) {
  const st = s.bolge, b = st.list[a.b];
  if (!b) return hata('Böyle bir bölge yok.');
  if (!IS_AD[a.kind]) return hata('Bilinmeyen iş.');
  if (yaraliMi(s)) return hata('Yaralısın; iyileşene kadar sokağa çıkamazsın.');
  if (!erisim(s, a.b)) return hata(`${BOLGELER[a.b].ad}'a girmek için önce komşu bir bölgeye hakim olmalısın.`);
  const gun = dateOf(s.t).day;
  if ((b.sonIs[a.kind] ?? -99) + BEKLEME[a.kind] > gun) return hata(`Bu işi bu bölgede ${BEKLEME[a.kind]} günde bir yapabilirsin.`);
  const onceki = hakimOf(st, a.b);
  const kayip = 1 - (b.inf.oyuncu || 0) / 120; // nüfuz yükseldikçe her ek puan pahalılaşır
  const rakip = onceki && onceki !== 'oyuncu' ? onceki : null;
  const direnc = (rakip ? 1 - (b.inf[rakip] || 0) / 150 : 1) * (0.6 + 0.6 * b.tan / 100); // sağlam bir hakimi yerinden etmek zordur; tanınmayan birine kimse güvenmez
  let kazan;
  if (a.kind === 'himaye') {
    if (!spend(s, 120, 'dirty')) return hata('Para yetmiyor ($120).');
    kazan = 7 * kayip * direnc;
    fame(s, 'halk', 'golge', { k: 1.5 }, 1);
    s.attBoost += 1.5;
    log(s, `${BOLGELER[a.b].ad}: esnafa "himaye" sattın (nüfuz +${kazan.toFixed(1)}).`, 'info', 'Karşılığında bir şey istemedin. Henüz.');
  } else if (a.kind === 'hediye') {
    if (!spend(s, 200, 'clean')) return hata('Temiz para yetmiyor ($200).');
    kazan = 4 * kayip * direnc;
    b.huzur = clamp(b.huzur + 8, 0, 100);
    fame(s, 'halk', 'cephe', { i: 3, t: 1 }, 1);
    log(s, `${BOLGELER[a.b].ad}: mahalleye ziyafet verdin (nüfuz +${kazan.toFixed(1)}, huzur +8).`, 'good');
  } else {
    if (!staff(s, 'koruma')) return hata('Bu iş için bir koruman olmalı (İri Tony gibi).');
    if (!spend(s, 150, 'dirty')) return hata('Para yetmiyor ($150).');
    kazan = 11 * kayip * direnc;
    b.huzur = clamp(b.huzur - 8, 0, 100);
    fame(s, 'halk', 'golge', { k: 3, i: -2 }, 1);
    s.attBoost += 4;
    if (rakip) st.ofke[rakip] = Math.min(60, st.ofke[rakip] + 20);
    log(s, `${BOLGELER[a.b].ad}: ${rakip ? hakimAd(rakip) + ' adamlarını' : 'sokak çetelerini'} sindirdin (nüfuz +${kazan.toFixed(1)}, huzur −8).`, 'warn', rakip ? `${hakimAd(rakip)} bunu unutmayacak: bölgelerine baskı artar.` : 'Polis dikkati artar.');
    if (brnd(st) < 0.25) s.pendingEvidence.push({ v: 4, why: `${BOLGELER[a.b].ad}'da sindirme işini birisi gördü ve karakola anlattı.` });
  }
  addInf(b, 'oyuncu', kazan);
  b.tan = clamp(b.tan + { himaye: 3, hediye: 4, gozdagi: 6 }[a.kind] * (1 - b.tan / 120), 0, 100);
  b.sonIs[a.kind] = gun;
  hakimDegisti(s, a.b, onceki);
  return TAMAM;
}

export function bolgeAdam(s, a) {
  const b = s.bolge.list[a.b];
  if (!b) return hata('Böyle bir bölge yok.');
  if (!erisim(s, a.b)) return hata('Bu bölgede henüz ayağın yok.');
  if (+a.d > 0) {
    if (b.garnizon >= GARNIZON_MAX) return hata(`En fazla ${GARNIZON_MAX} adam.`);
    if (!spend(s, 100, 'dirty')) return hata('Para yetmiyor ($100).');
    b.garnizon++;
    log(s, `${BOLGELER[a.b].ad}'a bir adam yerleştirdin (${b.garnizon}). Ayda $${ADAM_MAAS}.`, 'info', 'Her adam rakip baskısını azaltır ve huzuru yükseltir.');
  } else {
    if (b.garnizon <= 0) return hata('Çekilecek adam yok.');
    b.garnizon--;
    log(s, `${BOLGELER[a.b].ad}'dan bir adamını çektin (${b.garnizon}).`, 'info');
  }
  return TAMAM;
}

export function bolgeYatirim(s, a) {
  const st = s.bolge, b = st.list[a.b];
  if (!b) return hata('Böyle bir bölge yok.');
  if (hakimOf(st, a.b) !== 'oyuncu') return hata('Yalnızca hakim olduğun bölgeye yatırım yaparsın.');
  const ay = dateOf(s.t).month;
  if (b.yatirimAy === ay) return hata('Bu bölgeye bu ay zaten yatırım yaptın.');
  if (b.servet >= SERVET_MAX && b.ilerleme >= 99) return hata('Bölge zaten en büyük hâlinde.');
  if (!spend(s, 400, 'clean')) return hata('Temiz para yetmiyor ($400).');
  b.yatirimAy = ay;
  ilerlet(s, a.b, 35, 'yatırımla');
  addInf(b, 'oyuncu', 2 * (1 - (b.inf.oyuncu || 0) / 120));
  fame(s, 'halk', 'cephe', { i: 2 }, 1);
  return TAMAM;
}

export function bolgeHarac(s, a) {
  const st = s.bolge, b = st.list[a.b];
  if (!b) return hata('Böyle bir bölge yok.');
  if (hakimOf(st, a.b) !== 'oyuncu') return hata('Yalnızca hakim olduğun bölgeden haraç toplarsın.');
  const v = Math.round(+a.v);
  if (!(v >= 0 && v < HARAC.length)) return hata('Geçersiz haraç.');
  b.harac = v;
  return TAMAM;
}

// ---------- büyüme ----------
function ilerlet(s, id, miktar, neden) {
  const b = s.bolge.list[id], ad = BOLGELER[id].ad;
  b.ilerleme += miktar;
  while (b.ilerleme >= 100 && b.servet < SERVET_MAX) {
    b.ilerleme -= 100; b.servet++;
    log(s, `${ad} büyüdü (${'★'.repeat(b.servet)}).`, hakimOf(s.bolge, id) === 'oyuncu' ? 'good' : 'info', neden ? `Büyüme ${neden}.` : 'Huzurlu bölgeler büyür: daha çok dükkân, daha çok para, daha çok haraç.');
  }
  if (b.servet >= SERVET_MAX) b.ilerleme = Math.min(b.ilerleme, 99);
  while (b.ilerleme < 0 && b.servet > 1) {
    b.ilerleme += 100; b.servet--;
    log(s, `${ad} küçüldü (${'★'.repeat(b.servet)}).`, hakimOf(s.bolge, id) === 'oyuncu' ? 'bad' : 'info', 'Huzursuz bölgeden dükkânlar ve insanlar çekilir.');
  }
  if (b.servet <= 1) b.ilerleme = Math.max(b.ilerleme, 0);
}

// ---------- aylık işleyiş ----------
export function bolgeMonth(s, R, pushCard) {
  const st = s.bolge, ayNo = dateOf(s.t).month;
  const onceki = {};
  for (const id of Object.keys(st.list)) onceki[id] = hakimOf(st, id);

  // oyuncunun bölgeleri: garnizon gideri, haraç, huzur
  let haracToplam = 0, maasToplam = 0;
  for (const id of Object.keys(st.list)) {
    const b = st.list[id], hk = hakimOf(st, id);
    if (b.garnizon > 0) {
      const gider = b.garnizon * ADAM_MAAS;
      if (spend(s, gider, 'dirty')) maasToplam += gider;
      else { b.garnizon--; log(s, `${BOLGELER[id].ad}: adamların maaşını ödeyemedin, biri çekip gitti.`, 'bad'); }
    }
    if (hk === 'oyuncu') {
      const t = HARAC[b.harac];
      const gelir = Math.round(havuz(b) * t.oran * (0.6 + 0.4 * b.huzur / 100));
      if (gelir > 0) { s.cash.dirty += gelir; haracToplam += gelir; }
      if (b.harac === 3) fame(s, 'halk', 'golge', { k: 2, i: -3 }, 1);
      else if (b.harac === 2) fame(s, 'halk', 'golge', { i: -1 }, 1);
      else if (b.harac === 0) fame(s, 'halk', 'cephe', { i: 1 }, 1);
      if (b.harac >= 2) s.attBoost += 0.5 * b.harac;
    }
  }
  // ekip maaşı
  if (st.ekip > 0) {
    const gider = st.ekip * EKIP_MAAS;
    if (spend(s, gider, 'dirty')) maasToplam += gider;
    else { st.ekip--; log(s, 'Ekibin maaşını ödeyemedin, bir adam çekip gitti.', 'bad'); }
  }
  // mekanların bulunduğu bölgeyi rakip yönetiyorsa himaye bedeli keser
  const mh = hakimOf(st, MEKAN_BOLGE);
  if (mh && mh !== 'oyuncu') {
    const bedel = Math.round(0.04 * (s.biz.meyhane.mRev + (s.biz.camasir ? s.biz.camasir.mRev : 0)));
    if (bedel > 0) {
      s.cash.clean -= bedel;
      R.push(`  ! ${BOLGELER[MEKAN_BOLGE].ad}'ı ${hakimAd(mh)} yönetiyor: mekanların himaye bedeli −${money0(bedel)}`);
    }
  }
  // tanınırlık: hakim olduğun yerde artar, uzak kaldığın yerde solar
  for (const id of Object.keys(st.list)) {
    const b = st.list[id];
    if (hakimOf(st, id) === 'oyuncu') b.tan = clamp(b.tan + 1.5, 0, 100);
    else b.tan = Math.max(id === MEKAN_BOLGE ? 30 : 0, b.tan * 0.94);
  }
  if (haracToplam > 0 || maasToplam > 0) {
    const a = s.unvan.ahit;
    let ust = 0;
    if (a && haracToplam > 0) { ust = Math.round(haracToplam * a.harac / 100); s.cash.dirty -= ust; }
    R.push(`BÖLGELER  haraç ${money0(haracToplam)}${ust ? ` (Marchetti payı −${money0(ust)})` : ''} · garnizon gideri ${money0(maasToplam)}`);
  }

  // huzur ve büyüme
  for (const id of Object.keys(st.list)) {
    const b = st.list[id], hk = hakimOf(st, id), ik = ikinci(b, hk || '');
    const ceza = hk === 'oyuncu' ? [-4, 0, 5, 12][b.harac] : 0;
    const hedef = clamp(65 + 4 * Math.min(b.garnizon, GARNIZON_MAX) - (ik > 20 ? (ik - 20) * 0.8 : 0) - ceza, 0, 100);
    b.huzur = clamp(b.huzur + (hedef - b.huzur) * 0.35, 0, 100);
    let g = b.huzur < 30 ? -8 : 4.5 + (b.huzur - 50) / 10 + (brnd(st) - 0.5) * 5;
    if (hk === 'oyuncu' && b.harac === 3) g -= 3;
    ilerlet(s, id, g, null);
  }

  // yapay zeka hakimleri: pekiştirir, komşuya genişler
  for (const f of NPC) {
    const ofkeCarpan = 1 + st.ofke[f] / 30;
    const k = kudret(st, f);
    for (const id of Object.keys(st.list)) if (hakimOf(st, id) === f) addInf(st.list[id], f, 1.2);
    const adaylar = [];
    for (const id of Object.keys(st.list)) {
      if (hakimOf(st, id) === f) continue;
      if (!BOLGELER[id].komsu.some((n) => hakimOf(st, n) === f)) continue;
      const b = st.list[id], hk = hakimOf(st, id);
      let w = (1 / (1 + (hk ? b.inf[hk] : 0) / 30)) * (0.7 + b.servet * 0.15);
      if (hk === 'oyuncu') {
        w *= ofkeCarpan;
        if (f === 'marchetti' && s.unvan.ahit && s.unvan.ahit.himaye) w *= 0.15; // Ahit: Marchetti seni kollar
      }
      adaylar.push([id, w]);
    }
    if (!adaylar.length) continue;
    const p = clamp(0.1 + 0.012 * k, 0, 0.5) * FAK[f].saldirgan * ofkeCarpan;
    if (brnd(st) >= p) continue;
    const top = adaylar.reduce((a, x) => a + x[1], 0);
    let r = brnd(st) * top, hedef = adaylar[0][0];
    for (const [id, w] of adaylar) { r -= w; if (r <= 0) { hedef = id; break; } }
    const b = st.list[hedef], hk = hakimOf(st, hedef);
    let kazan = 4 + brnd(st) * 5 + k / 6;
    if (hk === 'oyuncu' || (b.inf.oyuncu || 0) > 0) {
      const savunma = 1.8 * b.garnizon + perceived(s, 'yeralti').K / 12;
      kazan = Math.max(1.5, kazan - savunma);
    }
    if (hk === 'oyuncu' || (hedef === MEKAN_BOLGE && !hk && brnd(st) < 0.3)) { dusmanBaskin(s, f, hedef, kazan, hk, pushCard); continue; }
    addInf(b, f, kazan);
    b.huzur = clamp(b.huzur - 5, 0, 100);
    if (hk) log(s, `${hakimAd(f)}, ${hakimAd(hk)}'in ${BOLGELER[hedef].ad}'daki hâkimiyetini zorluyor.`, 'info');
    else log(s, `${hakimAd(f)} sahipsiz ${BOLGELER[hedef].ad}'a el attı.`, 'info');
  }
  for (const f of NPC) st.ofke[f] *= 0.8;

  for (const id of Object.keys(st.list)) hakimDegisti(s, id, onceki[id]);
  void ayNo;
}

const money0 = (x) => `$${Math.round(x).toLocaleString('en-US')}`;
export { IS_AD, BEKLEME };
