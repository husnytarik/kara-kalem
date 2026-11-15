// Üç zafer yolu (Gangsters'taki gibi): dürüst iş, belediye başkanlığı, hâkimiyet. Aylık kontrol edilir.
import { clamp, dateOf, spend, money, log } from './util.js';
import { oyuncuBolgeleri, brnd } from './bolge.js';
import { sahipSayisi, haracSayisi } from './isyeri.js';

export const KAMPANYA_HEDEF = 6000;
const hata = (msg) => ({ ok: false, msg });
export const newZafer = (seed) => ({ seed: (seed ^ 0x1b873593) | 0, kampanya: 0, durustAy: 0, hakimAy: 0, kayip: 0 });

const ortSev = (s) => {
  const l = oyuncuBolgeleri(s);
  return l.length ? l.reduce((a, id) => a + s.bolge.list[id].sev, 0) / l.length : 0;
};
export function oyOrani(s) {
  const n = oyuncuBolgeleri(s).length;
  return clamp(12 + 0.3 * ortSev(s) + 22 * Math.min(1, s.zafer.kampanya / KAMPANYA_HEDEF) + 4 * n - 0.3 * s.dosya, 0, 100);
}
export function zaferDurum(s) {
  const n = oyuncuBolgeleri(s).length, temiz = s.cash.clean, d = dateOf(s.t);
  const durust = [
    { k: 'Sahip olduğun yer', v: `${sahipSayisi(s)} / 4`, ok: sahipSayisi(s) >= 4 },
    { k: 'Temiz para', v: `${money(temiz)} / $12.000`, ok: temiz >= 12000 },
    { k: 'Polis dosyası', v: `${Math.round(s.dosya)} / en çok 15`, ok: s.dosya <= 15 },
    { k: 'Haraç bağlı yer', v: `${haracSayisi(s)} / 0`, ok: haracSayisi(s) === 0 },
    { k: 'Ekip', v: `${s.bolge.ekip} / en çok 2`, ok: s.bolge.ekip <= 2 },
  ];
  const baskan = [
    { k: 'Hakim olduğun bölge', v: `${n} / en az 2`, ok: n >= 2 },
    { k: 'Seçim', v: `her yıl 12. ay (${d.year >= 2 ? 'açık' : '2. yıldan sonra'})`, ok: d.year >= 2 },
    { k: 'Kampanya fonu', v: `${money(s.zafer.kampanya)} / ${money(KAMPANYA_HEDEF)}`, ok: s.zafer.kampanya >= KAMPANYA_HEDEF },
    { k: 'Tahmini oy', v: `%${Math.round(oyOrani(s))} / %50`, ok: oyOrani(s) >= 50 },
  ];
  const hakim = [
    { k: 'Hakim olduğun bölge', v: `${n} / 5`, ok: n >= 5 },
  ];
  return { durust, baskan, hakim, durustAy: s.zafer.durustAy, hakimAy: s.zafer.hakimAy };
}
export function kampanyaFon(s, a) {
  const v = Math.round(+a.amount);
  if (!(v > 0)) return hata('Geçersiz tutar.');
  if (!spend(s, v, 'clean')) return hata(`Temiz para yetmiyor (${money(v)}).`);
  s.zafer.kampanya += v;
  log(s, `Seçim kampanyasına ${money(v)} aktardın (toplam ${money(s.zafer.kampanya)}).`, 'info', 'Afişler, aşevi, mitingler: oy oranını yükseltir. Kazanamazsan para gider.');
  return { ok: true };
}
const kazan = (s, kind, text) => { s.over = { kind, text }; };
export function zaferAy(s, R) {
  const Z = s.zafer, d = dateOf(s.t), D = zaferDurum(s);
  Z.durustAy = D.durust.every((x) => x.ok) ? Z.durustAy + 1 : 0;
  Z.hakimAy = D.hakim.every((x) => x.ok) ? Z.hakimAy + 1 : 0;
  if (Z.durustAy >= 2) return kazan(s, 'zafer', 'İki ay üst üste temiz kasa, temiz dosya, sıfır haraç ve küçük bir ekip. Meyhaneyi, dükkânları ve apartmanları olan saygın bir iş adamısın; polisin dosyası kapandı. Karanlık geçmişin gazete arşivlerinde kaldı. DÜRÜST İŞ ZAFERİ.');
  if (Z.hakimAy >= 2) return kazan(s, 'zafer', 'Şehrin bölgelerinin neredeyse hepsi senin. Rakip aileler çekildi ya da boyun eğdi; kimse senden izin almadan şehirde iş yapamaz. HÂKİMİYET ZAFERİ.');
  if (d.monthInYear === 12 && d.year >= 2 && oyuncuBolgeleri(s).length >= 2) {
    const oy = oyOrani(s) + (brnd(Z) - 0.5) * 10;
    if (oy >= 50) return kazan(s, 'zafer', `Seçim gecesi sayım bitti: oyların %${Math.round(oy)}'ini aldın. Belediye başkanısın; Courthouse'ın merdivenlerinde alkışlanıyorsun. Polis şefi şapkasını çıkardı. BAŞKANLIK ZAFERİ.`);
    R.push(`SEÇİM  oyların %${Math.round(oy)}'ini aldın; kazanamadın. Kampanya parası gitti.`);
    log(s, `Belediye seçimini kaybettin (%${Math.round(oy)}). Kampanya fonu eridi.`, 'bad', 'Oy için bölge halkının sevgisi, kampanya fonu ve temiz dosya gerekir.');
    Z.kampanya = 0;
  }
}
