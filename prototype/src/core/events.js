// Olay kartları. Her olay senaryo değil, koşullu olasılıktır:
//   cond(s)  -> ön koşul        p -> koşul sağlanıyorsa günlük olasılık
//   window   -> karar penceresi (oyun günü)     def -> süre dolunca vekilin seçtiği seçenek
//   once / cooldown (gün)       system -> yalnızca simülasyon tarafından açılır
import { DAY, dateOf, rnd, log, addMod, opinion, spend, staff, addStress, hideGoods, money, clamp } from './util.js';

const day = (s) => dateOf(s.t).day;
const has = (s, trait) => s.patron.traits.includes(trait);

export const EVENTS = {
  usta_kapida: {
    title: 'Bodrumun boş duruyor',
    once: true, p: 1, window: 4, def: 1,
    cond: (s) => day(s) >= 3 && !s.flags.ustaKnown,
    text: () => 'Nuri Efendi yanında yaşlıca, tek gözü perdeli bir adamla geldi: Kör Aziz. Yasaktan önce şehrin en iyi içkisini o çekermiş. "Bodrumun boş duruyor evlat," diyor Nuri Efendi alçak sesle, "borç da bekliyor."',
    options: () => [
      {
        label: 'Otur Aziz Usta, konuşalım.',
        hint: 'Aziz işe alınabilir olur. Bodruma imalathane kurabilirsin (400 ₺).',
        run: (s) => { s.flags.ustaKnown = true; addMod(s, 'nuri', 'Sözünü dinledin', 5, 2); log(s, 'Kör Aziz ile tanıştın. Bodrum artık bir seçenek.', 'good'); },
      },
      {
        label: 'Şimdi değil.',
        hint: 'Teklif birkaç gün sonra yeniden gelebilir.',
        run: (s) => { delete s.flags.ev_usta_kapida; s.cool.usta_kapida = day(s) + 8; },
      },
    ],
  },

  devriye: {
    title: 'Devriye kapıda',
    p: 0.25, cooldown: 12, window: 1, def: 1,
    cond: (s) => s.stats.totalSold > 50 && !s.chars.rifat.payroll,
    text: () => 'Komiser Muavini Rıfat kapanışa yakın içeri girdi, kasketini tezgâha koydu. Gözü rafların arkasında. "Mahallede yeni kokular var," diyor, "ben burnuma güvenirim."',
    options: () => [
      {
        label: 'Aylığa bağla (ayda 60 ₺, kirli paradan).',
        hint: 'Rıfat +15. Semt Polis Dikkati −15 (ödedikçe). Sana haber uçurur. Ama artık sana bağlı: yanarsa seni de yakar.',
        can: (s) => s.cash.dirty >= 60,
        run: (s) => { spend(s, 60, 'dirty'); s.chars.rifat.payroll = true; addMod(s, 'rifat', 'Aylığa bağladın', 15, 0); log(s, 'Rıfat artık aylıkta.', 'good', 'Ayda 60 ₺ karşılığında gözünü kapatıyor ve haber uçuruyor.'); },
      },
      {
        label: 'Bir kadeh ikram et, geçiştir.',
        hint: 'Rıfat +3. Dikkat biraz artar.',
        run: (s) => { addMod(s, 'rifat', 'İkram ettin', 3, 3); s.attBoost += 3; },
      },
      {
        label: 'Kapıyı göster.',
        hint: 'Rıfat −10. Polis Dikkati belirgin artar.',
        run: (s) => { addMod(s, 'rifat', 'Onu kapı dışarı ettin', -10, 2); s.attBoost += 8; if (has(s, 'Temkinli')) addStress(s, 5, 'Temkinli birisin; polisi karşına almak sana göre değil.'); },
      },
    ],
  },

  garson_zam: {
    title: 'Halil zam istiyor',
    p: 0.06, cooldown: 30, window: 1, def: 1,
    cond: (s) => day(s) > 12 && !!staff(s, 'garson'),
    text: () => 'Garson Halil önlüğünü çıkarıp karşına dikildi. "Ağabey, karşıdaki Kâzım Efendi daha fazlasını veriyormuş diyorlar."',
    options: () => [
      { label: 'Haklısın. (+15 ₺ maaş)', hint: 'Maaş kalıcı olarak artar; görüşü yükselir.', run: (s) => { s.chars.halil.maas += 15; addMod(s, 'halil', 'İstediği zammı verdin', 8, 3); } },
      { label: 'Ay sonunu bir görelim.', hint: 'Halil −4.', run: (s) => addMod(s, 'halil', 'Zammı erteledin', -4, 4) },
      { label: 'Beğenmeyen gider.', hint: 'Halil −14.', run: (s) => { addMod(s, 'halil', 'Onu tersledin', -14, 3); if (has(s, 'Cömert')) addStress(s, 6, 'Cömert birisin; adamını terslemek içine oturdu.'); } },
    ],
  },

  rakip_fiyat: {
    title: 'Kâzım fiyat kırdı',
    p: 0.05, cooldown: 25, window: 2, def: 2,
    cond: (s) => day(s) > 8,
    text: () => 'Karşı sokaktaki Meyhaneci Kâzım tabelasına yeni fiyatlar yazmış. Akşam müşterisinin yarısı oraya kaymış görünüyor. 10 gün sürecek gibi.',
    options: () => [
      { label: 'Biz de kıralım.', hint: 'Meyhane fiyatın 0,85\'e iner (sonra elle değiştirebilirsin).', run: (s) => { s.biz.meyhane.price = 0.85; } },
      { label: 'Mutfağa yatırım yap (150 ₺).', hint: 'İtibar +8.', can: (s) => s.cash.clean >= 150, run: (s) => { spend(s, 150, 'clean'); s.biz.meyhane.rep = clamp(s.biz.meyhane.rep + 8, 0, 100); } },
      { label: 'Aldırma.', hint: 'Bir süre pay kaybedersin.', run: () => {} },
    ],
    onPush: (s) => { s.biz.rakip.price = 0.8; s.rivalCutUntil = s.t + 10 * DAY; },
  },

  yegen: {
    title: 'Yeğenin kapında',
    once: true, p: 0.5, window: 10, def: 1,
    cond: (s) => s.chars.selim.yas >= 16 && !s.chars.selim.employed,
    text: () => 'Kız kardeşin Zehra\'nın oğlu Selim iş istiyor. Hevesli ama eli ağır, dili gevşek.',
    options: () => [
      { label: 'Yanıma alırım.', hint: 'Zehra +20 · Selim ekibe girer (Ketumluk 25) · Halil −5 ("torpil").', run: (s) => { const c = s.chars.selim; c.employed = true; c.job = 'cirak'; c.rol = 'Çırak'; addMod(s, 'zehra', 'Oğluna iş verdin', 20, 1); addMod(s, 'selim', 'Onu yanına aldın', 20, 1); addMod(s, 'halil', 'Yeğenini kayırdın', -5, 3); } },
      { label: 'Meyhanede bulaşığa girsin.', hint: 'Zehra +5 · Selim −10 (hırslı).', run: (s) => { addMod(s, 'zehra', 'Oğluna küçük bir iş verdin', 5, 2); addMod(s, 'selim', 'Onu bulaşığa verdin', -10, 2); } },
      { label: 'Bu işler ona göre değil.', hint: 'Zehra −15 · Cömert isen Stres +10.', run: (s) => { addMod(s, 'zehra', 'Oğlunu geri çevirdin', -15, 2); if (has(s, 'Cömert')) addStress(s, 10, 'Cömert birisin; aileni geri çevirmek sana ağır geldi.'); } },
    ],
  },

  kavga: {
    title: 'Meyhanede kavga',
    p: 0.04, cooldown: 20, window: 1, def: 0,
    cond: (s) => day(s) > 5,
    text: () => 'Gece yarısına doğru iki liman işçisi birbirine girdi. Bir masa devrildi, biri bıçak çekti.',
    options: (s) => [
      { label: 'Polis çağır.', hint: 'Güvenli. Ama polis mekânı görür: Dikkat artar.', run: (s) => { s.attBoost += (s.dist.stock > 0 ? 8 : 3); } },
      { label: 'Araya kendin gir.', hint: 'İtibar +3 · Stres +5.', run: (s) => { s.biz.meyhane.rep = clamp(s.biz.meyhane.rep + 3, 0, 100); addStress(s, 5, 'Kavgayı kendin ayırdın.'); } },
      { label: 'İri Cemal halletsin.', hint: 'İtibar +4. Kimse polis çağırmaz.', can: (s) => !!staff(s, 'koruma'), run: (s) => { s.biz.meyhane.rep = clamp(s.biz.meyhane.rep + 4, 0, 100); } },
    ],
  },

  yangin: {
    title: 'Bodrumda duman',
    p: 0.15, cooldown: 15, window: 1, def: 1,
    cond: (s) => producing(s) && !!staff(s, 'usta') && staff(s, 'usta').sadakat < 45,
    text: () => 'Aziz Usta yine içmiş. Kazanın başında uyuyakalmış; bodrumdan sokağa duman sızdı. Komşu pencereleri açıldı.',
    options: () => [
      { label: 'Komşulara "soba tütmüş" de, gönüllerini al (80 ₺).', hint: 'İz +6.', can: (s) => s.cash.clean + s.cash.dirty >= 80, run: (s) => { spend(s, 80, 'dirty'); s.izBoost += 6; } },
      { label: 'Üstünü ört, geç.', hint: 'İz +15.', run: (s) => { s.izBoost += 15; } },
    ],
  },

  komsu: {
    title: 'Hacer Hanım rahatsız',
    p: 0.08, cooldown: 20, window: 2, def: 0,
    cond: (s) => s.dist.iz > 35,
    text: () => 'Arka sokaktaki Hacer Hanım seni yolda çevirdi. "Geceleri o koku nedir evladım? Bir de at arabaları gidip geliyor. Ben uyuyamıyorum."',
    options: () => [
      { label: 'Gönlünü al (50 ₺ ve bir sepet erzak).', hint: 'Hacer +15. Susar.', can: (s) => s.cash.clean + s.cash.dirty >= 50, run: (s) => { spend(s, 50, 'dirty'); addMod(s, 'hacer', 'Gönlünü aldın', 15, 2); } },
      {
        label: 'Gözdağı ver.', hint: 'Hacer −30. Yarı ihtimalle susar; susmazsa tanık olur (Dosya +8). Cömert isen Stres +10.',
        run: (s) => { addMod(s, 'hacer', 'Onu tehdit ettin', -30, 1); if (has(s, 'Cömert')) addStress(s, 10, 'Yaşlı bir kadını korkuttun.'); if (rnd(s) < 0.5) s.pendingEvidence.push({ v: 8, why: 'Hacer Hanım karakola gidip ifade verdi (onu tehdit etmiştin).' }); },
      },
      { label: 'Görmezden gel.', hint: '%40 ihtimalle ihbar eder (Dosya +5).', run: (s) => { addMod(s, 'hacer', 'Derdini dinlemedin', -8, 2); if (rnd(s) < 0.4) s.pendingEvidence.push({ v: 5, why: 'Hacer Hanım kokudan şikâyetçi olup ihbarda bulundu (derdini dinlememiştin).' }); } },
    ],
  },

  camasirhane: {
    title: 'Çamaşırhane satılık',
    once: true, p: 0.15, window: 4, def: 1,
    cond: (s) => dateOf(s.t).month >= 1 && !s.biz.camasir,
    text: () => 'Köşedeki çamaşırhanenin sahibi memleketine dönüyor. Nuri Efendi kulağına eğildi: "Nakit işi evlat. Kaç gömlek yıkandığını kim sayacak?"',
    options: () => [
      { label: 'Satın al (1.500 ₺ temiz).', hint: 'Yeni yasal işletme. Aklama oranı %50: kirli paran için yeni bir kapı.', can: (s) => s.cash.clean >= 1500, run: (s) => { spend(s, 1500, 'clean'); s.biz.camasir = { id: 'camasir', type: 'camasir', name: 'Köşe Çamaşırhanesi', mRev: 0, mCost: 0 }; log(s, 'Çamaşırhaneyi satın aldın.', 'good'); } },
      { label: 'Geç.', hint: 'Fırsat kaçar.', run: () => {} },
    ],
  },

  tefeci: {
    title: 'Şakir\'in adamları',
    p: 1, cooldown: 9, window: 2, def: 0,
    cond: (s) => s.debt.missed >= 1 && s.debt.principal > 0,
    text: (s) => `Tefeci Şakir'in iki adamı öğle vakti meyhaneye oturdu, hiçbir şey sipariş etmedi. Ödenmemiş taksit: ${s.debt.missed}. Üçüncüde konuşmayacaklarını biliyorsun.`,
    options: (s) => [
      { label: 'Gecikme faizini kabul et (borca +300 ₺).', hint: 'Zaman kazanırsın.', run: (s) => { s.debt.principal += 300; } },
      { label: `Geciken taksiti kirli parayla kapat (${money(s.debt.installment * 1.2)}).`, hint: 'Şakir kirli parayı %20 fazlasıyla kabul eder. Geciken taksit silinir.', can: (s) => s.cash.dirty >= s.debt.installment * 1.2, run: (s) => { s.cash.dirty -= s.debt.installment * 1.2; s.debt.principal = Math.max(0, s.debt.principal - s.debt.installment); s.debt.missed -= 1; addMod(s, 'sakir', 'Gecikmeyi kapattın', 5, 2); } },
    ],
  },

  yilbasi: {
    title: 'Yılbaşı yaklaşıyor',
    p: 1, cooldown: 100, window: 1, def: 0,
    cond: (s) => { const d = dateOf(s.t); return d.monthInYear === 12 && d.dayInMonth === 7 && s.flags.ustaKnown; },
    text: () => 'Şehir yılbaşına hazırlanıyor. Yasak olsun olmasın, herkes sofrasına bir şişe koymak istiyor. Üç gün boyunca içki talebi iki katına çıkacak.',
    options: () => [{ label: 'Anlaşıldı.', hint: 'İçki talebi 3 gün ×2.', run: () => {} }],
    onPush: (s) => { s.liqBoostUntil = s.t + 3 * DAY; },
  },

  usta_zam: {
    title: 'Aziz Usta payını istiyor',
    p: 0.05, cooldown: 30, window: 2, def: 1,
    cond: (s) => !!staff(s, 'usta') && dateOf(s.t).month >= 2,
    text: () => '"Kazanı ben kaynatıyorum, riski ben alıyorum," diyor Kör Aziz, tek gözünü sana dikerek. "Kazanan sen oluyorsun."',
    options: () => [
      { label: 'Haklısın usta. (+40 ₺ maaş)', hint: 'Aziz +10.', run: (s) => { s.chars.aziz.maas += 40; addMod(s, 'aziz', 'Payını artırdın', 10, 3); } },
      { label: 'Bir şişe de sana ayıralım.', hint: 'Aziz −5.', run: (s) => addMod(s, 'aziz', 'Onu lafla savdın', -5, 3) },
      { label: 'Senin gibi usta çok.', hint: 'Aziz −18. Küskün usta tehlikelidir.', run: (s) => addMod(s, 'aziz', 'Onu küçümsedin', -18, 2) },
    ],
  },

  // --- Sistem kartları ---
  baskin_ihbari: {
    title: 'Arama emri çıktı', system: true, window: 1, def: 0,
    text: (s) => `Rıfat arka kapıdan haber yolladı: "Savcılık emri imzaladı. ${Math.max(1, Math.ceil((s.raid ? s.raid.at - s.t : DAY) / DAY))} gün içinde geliyorlar. Ben seni görmedim."`,
    options: () => [
      { label: 'Malı sakla, üretimi durdur.', hint: '3 gün üretim ve satış yok, stokun %20\'si gider. Baskın boşa çıkarsa Dosya −30.', run: (s) => hideGoods(s) },
      { label: 'Rıfat\'a 200 ₺ ver, baskını ertelet.', hint: 'Baskın 3 gün ertelenir. Sorun çözülmez.', can: (s) => s.cash.dirty + s.cash.clean >= 200 && !!s.raid, run: (s) => { spend(s, 200, 'dirty'); if (s.raid) s.raid.at += 3 * DAY; addMod(s, 'rifat', 'İyi ödedin', 4, 3); } },
      { label: 'Bekle.', hint: 'Bodrumda ne varsa onu bulurlar.', run: () => {} },
    ],
  },

  rapor: {
    title: 'Hesap Günü', system: true, window: 99, def: 0,
    text: (s, card) => card.data.text,
    options: () => [{ label: 'Tamam.', hint: '', run: () => {} }],
  },
};

export function producing(s) {
  const d = s.dist;
  return d.built && d.volume > 0 && s.t >= d.hiddenUntil;
}

export { opinion };
