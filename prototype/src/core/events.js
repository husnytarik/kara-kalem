// Olay kartları. Her olay senaryo değil, koşullu olasılıktır:
//   cond(s)  -> ön koşul        p -> koşul sağlanıyorsa günlük olasılık
//   window   -> karar penceresi (oyun günü)     def -> süre dolunca vekilin seçtiği seçenek
//   once / cooldown (gün)       system -> yalnızca simülasyon tarafından açılır
import { DAY, dateOf, rnd, log, addMod, opinion, spend, staff, addStress, hideGoods, money, clamp } from './util.js';
import { fame, leak, gucPuani, dostlar, addOrtak, kabulAhit } from './social.js';

const day = (s) => dateOf(s.t).day;
const has = (s, trait) => s.patron.traits.includes(trait);

export const EVENTS = {
  usta_kapida: {
    title: 'Bodrumun boş duruyor',
    once: true, p: 1, window: 4, def: 1,
    cond: (s) => day(s) >= 3 && !s.flags.ustaKnown,
    text: () => 'Walter Doyle yanında yaşlıca, tek gözü perdeli bir adamla geldi: Kör Gus. Yasaktan önce şehrin en iyi içkisini o çekermiş. "Bodrumun boş duruyor evlat," diyor Walter Doyle alçak sesle, "borç da bekliyor."',
    options: () => [
      {
        label: 'Otur Gus Usta, konuşalım.',
        hint: 'Gus işe alınabilir olur. Bodruma imalathane kurabilirsin ($400).',
        run: (s) => { s.flags.ustaKnown = true; addMod(s, 'nuri', 'Sözünü dinledin', 5, 2); log(s, 'Kör Gus ile tanıştın. Bodrum artık bir seçenek.', 'good'); },
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
    text: () => 'Dedektif Dolan kapanışa yakın içeri girdi, kasketini tezgâha koydu. Gözü rafların arkasında. "Mahallede yeni kokular var," diyor, "ben burnuma güvenirim."',
    options: () => [
      {
        label: 'Aylığa bağla (ayda $60, kirli paradan).',
        hint: 'Dolan +15. Semt Polis Dikkati −15 (ödedikçe). Sana haber uçurur. Ama artık sana bağlı: yanarsa seni de yakar.',
        can: (s) => s.cash.dirty >= 60,
        run: (s) => { spend(s, 60, 'dirty'); s.chars.rifat.payroll = true; addMod(s, 'rifat', 'Aylığa bağladın', 15, 0); log(s, 'Dolan artık aylıkta.', 'good', 'Ayda $60 karşılığında gözünü kapatıyor ve haber uçuruyor.'); },
      },
      {
        label: 'Bir kadeh ikram et, geçiştir.',
        hint: 'Dolan +3. Dikkat biraz artar.',
        run: (s) => { addMod(s, 'rifat', 'İkram ettin', 3, 3); s.attBoost += 3; },
      },
      {
        label: 'Kapıyı göster.',
        hint: 'Dolan −10. Polis Dikkati belirgin artar.',
        run: (s) => { addMod(s, 'rifat', 'Onu kapı dışarı ettin', -10, 2); s.attBoost += 8; if (has(s, 'Temkinli')) addStress(s, 5, 'Temkinli birisin; polisi karşına almak sana göre değil.'); },
      },
    ],
  },

  garson_zam: {
    title: 'Eddie zam istiyor',
    p: 0.06, cooldown: 30, window: 1, def: 1,
    cond: (s) => day(s) > 12 && !!staff(s, 'garson'),
    text: () => 'Garson Eddie önlüğünü çıkarıp karşına dikildi. "Patron, karşıdaki Duffy daha fazlasını veriyormuş diyorlar."',
    options: () => [
      { label: 'Haklısın. (+$15 maaş)', hint: 'Maaş kalıcı olarak artar; görüşü yükselir.', run: (s) => { s.chars.halil.maas += 15; addMod(s, 'halil', 'İstediği zammı verdin', 8, 3); } },
      { label: 'Ay sonunu bir görelim.', hint: 'Eddie −4.', run: (s) => addMod(s, 'halil', 'Zammı erteledin', -4, 4) },
      { label: 'Beğenmeyen gider.', hint: 'Eddie −14.', run: (s) => { addMod(s, 'halil', 'Onu tersledin', -14, 3); if (has(s, 'Cömert')) addStress(s, 6, 'Cömert birisin; adamını terslemek içine oturdu.'); } },
    ],
  },

  rakip_fiyat: {
    title: 'Duffy fiyat kırdı',
    p: 0.05, cooldown: 25, window: 2, def: 2,
    cond: (s) => day(s) > 8,
    text: () => 'Karşı sokaktaki Meyhaneci Duffy tabelasına yeni fiyatlar yazmış. Akşam müşterisinin yarısı oraya kaymış görünüyor. 10 gün sürecek gibi.',
    options: () => [
      { label: 'Biz de kıralım.', hint: 'Meyhane fiyatın 0,85\'e iner (sonra elle değiştirebilirsin).', run: (s) => { s.biz.meyhane.price = 0.85; } },
      { label: 'Mutfağa yatırım yap ($150).', hint: 'İtibar +8.', can: (s) => s.cash.clean >= 150, run: (s) => { spend(s, 150, 'clean'); s.biz.meyhane.rep = clamp(s.biz.meyhane.rep + 8, 0, 100); } },
      { label: 'Aldırma.', hint: 'Bir süre pay kaybedersin.', run: () => {} },
    ],
    onPush: (s) => { s.biz.rakip.price = 0.8; s.rivalCutUntil = s.t + 10 * DAY; },
  },

  yegen: {
    title: 'Yeğenin kapında',
    once: true, p: 0.5, window: 10, def: 1,
    cond: (s) => s.chars.selim.yas >= 16 && !s.chars.selim.employed,
    text: () => 'Kız kardeşin Maggie\'nin oğlu Danny iş istiyor. Hevesli ama eli ağır, dili gevşek.',
    options: () => [
      { label: 'Yanıma alırım.', hint: 'Maggie +20 · Danny ekibe girer (Ketumluk 25) · Eddie −5 ("torpil").', run: (s) => { const c = s.chars.selim; c.employed = true; c.job = 'cirak'; c.rol = 'Çırak'; addMod(s, 'zehra', 'Oğluna iş verdin', 20, 1); addMod(s, 'selim', 'Onu yanına aldın', 20, 1); addMod(s, 'halil', 'Yeğenini kayırdın', -5, 3); } },
      { label: 'Meyhanede bulaşığa girsin.', hint: 'Maggie +5 · Danny −10 (hırslı).', run: (s) => { addMod(s, 'zehra', 'Oğluna küçük bir iş verdin', 5, 2); addMod(s, 'selim', 'Onu bulaşığa verdin', -10, 2); } },
      { label: 'Bu işler ona göre değil.', hint: 'Maggie −15 · Cömert isen Stres +10.', run: (s) => { addMod(s, 'zehra', 'Oğlunu geri çevirdin', -15, 2); if (has(s, 'Cömert')) addStress(s, 10, 'Cömert birisin; aileni geri çevirmek sana ağır geldi.'); } },
    ],
  },

  kavga: {
    title: 'Meyhanede kavga',
    p: 0.04, cooldown: 20, window: 1, def: 0,
    cond: (s) => day(s) > 5,
    text: () => 'Gece yarısına doğru iki liman işçisi birbirine girdi. Bir masa devrildi, biri bıçak çekti.',
    options: (s) => [
      { label: 'Polis çağır.', hint: 'Güvenli. Ama polis mekânı görür: Dikkat artar.', run: (s) => { s.attBoost += (s.dist.stock > 0 ? 8 : 3); fame(s, 'polis', 'cephe', { t: 2 }, 1); } },
      { label: 'Araya kendin gir.', hint: 'İtibar +3 · Stres +5 · Mahallede adın anılır.', run: (s) => { s.biz.meyhane.rep = clamp(s.biz.meyhane.rep + 3, 0, 100); addStress(s, 5, 'Kavgayı kendin ayırdın.'); fame(s, 'halk', 'cephe', { t: 2, i: 3 }, 1); } },
      { label: 'İri Tony halletsin.', hint: 'İtibar +4. Kimse polis çağırmaz. Tony\'nin sert yöntemi duyulur (Korku +).', can: (s) => !!staff(s, 'koruma'), run: (s) => { s.biz.meyhane.rep = clamp(s.biz.meyhane.rep + 4, 0, 100); fame(s, 'halk', 'golge', { k: 3 }, 1); } },
    ],
  },

  yangin: {
    title: 'Bodrumda duman',
    p: 0.15, cooldown: 15, window: 1, def: 1,
    cond: (s) => producing(s) && !!staff(s, 'usta') && staff(s, 'usta').sadakat < 45,
    text: () => 'Gus Usta yine içmiş. Kazanın başında uyuyakalmış; bodrumdan sokağa duman sızdı. Komşu pencereleri açıldı.',
    options: () => [
      { label: 'Komşulara "soba tütmüş" de, gönüllerini al ($80).', hint: 'İz +6.', can: (s) => s.cash.clean + s.cash.dirty >= 80, run: (s) => { spend(s, 80, 'dirty'); s.izBoost += 6; } },
      { label: 'Üstünü ört, geç.', hint: 'İz +15.', run: (s) => { s.izBoost += 15; } },
    ],
  },

  komsu: {
    title: 'Bayan Kowalski rahatsız',
    p: 0.08, cooldown: 20, window: 2, def: 0,
    cond: (s) => s.dist.iz > 35,
    text: () => 'Arka sokaktaki Bayan Kowalski seni yolda çevirdi. "Geceleri o koku nedir evladım? Bir de at arabaları gidip geliyor. Ben uyuyamıyorum."',
    options: () => [
      { label: 'Gönlünü al ($50 ve bir sepet erzak).', hint: 'Kowalski +15. Susar.', can: (s) => s.cash.clean + s.cash.dirty >= 50, run: (s) => { spend(s, 50, 'dirty'); addMod(s, 'hacer', 'Gönlünü aldın', 15, 2); fame(s, 'halk', 'cephe', { i: 2 }, 1); } },
      {
        label: 'Gözdağı ver.', hint: 'Kowalski −30. Yarı ihtimalle susar; susmazsa tanık olur (Dosya +8). Cömert isen Stres +10.',
        run: (s) => { addMod(s, 'hacer', 'Onu tehdit ettin', -30, 1); fame(s, 'halk', 'golge', { k: 6, i: -6 }, 1); leak(s, 'halk', 0.05); if (has(s, 'Cömert')) addStress(s, 10, 'Yaşlı bir kadını korkuttun.'); if (rnd(s) < 0.5) s.pendingEvidence.push({ v: 8, why: 'Bayan Kowalski karakola gidip ifade verdi (onu tehdit etmiştin).' }); },
      },
      { label: 'Görmezden gel.', hint: '%40 ihtimalle ihbar eder (Dosya +5).', run: (s) => { addMod(s, 'hacer', 'Derdini dinlemedin', -8, 2); if (rnd(s) < 0.4) s.pendingEvidence.push({ v: 5, why: 'Bayan Kowalski kokudan şikâyetçi olup ihbarda bulundu (derdini dinlememiştin).' }); } },
    ],
  },

  camasirhane: {
    title: 'Çamaşırhane satılık',
    once: true, p: 0.15, window: 4, def: 1,
    cond: (s) => dateOf(s.t).month >= 1 && !s.biz.camasir,
    text: () => 'Köşedeki çamaşırhanenin sahibi memleketine dönüyor. Walter Doyle kulağına eğildi: "Nakit işi evlat. Kaç gömlek yıkandığını kim sayacak?"',
    options: () => [
      { label: 'Satın al ($1,500 temiz).', hint: 'Yeni yasal işletme. Aklama oranı %50: kirli paran için yeni bir kapı.', can: (s) => s.cash.clean >= 1500, run: (s) => { spend(s, 1500, 'clean'); s.biz.camasir = { id: 'camasir', type: 'camasir', name: 'Corner Laundromat', mRev: 0, mCost: 0 }; log(s, 'Çamaşırhaneyi satın aldın.', 'good'); } },
      { label: 'Geç.', hint: 'Fırsat kaçar.', run: () => {} },
    ],
  },

  tefeci: {
    title: 'Sal\'ın adamları',
    p: 1, cooldown: 9, window: 2, def: 0,
    cond: (s) => s.debt.missed >= 1 && s.debt.principal > 0,
    text: (s) => `Tefeci Sal'ın iki adamı öğle vakti meyhaneye oturdu, hiçbir şey sipariş etmedi. Ödenmemiş taksit: ${s.debt.missed}. Üçüncüde konuşmayacaklarını biliyorsun.`,
    options: (s) => [
      { label: 'Gecikme faizini kabul et (borca +$300).', hint: 'Zaman kazanırsın.', run: (s) => { s.debt.principal += 300; } },
      { label: `Geciken taksiti kirli parayla kapat (${money(s.debt.installment * 1.2)}).`, hint: 'Sal kirli parayı %20 fazlasıyla kabul eder. Geciken taksit silinir.', can: (s) => s.cash.dirty >= s.debt.installment * 1.2, run: (s) => { s.cash.dirty -= s.debt.installment * 1.2; s.debt.principal = Math.max(0, s.debt.principal - s.debt.installment); s.debt.missed -= 1; addMod(s, 'sakir', 'Gecikmeyi kapattın', 5, 2); } },
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
    title: 'Gus Usta payını istiyor',
    p: 0.05, cooldown: 30, window: 2, def: 1,
    cond: (s) => !!staff(s, 'usta') && dateOf(s.t).month >= 2,
    text: () => '"Kazanı ben kaynatıyorum, riski ben alıyorum," diyor Kör Gus, tek gözünü sana dikerek. "Kazanan sen oluyorsun."',
    options: () => [
      { label: 'Haklısın usta. (+$40 maaş)', hint: 'Gus +10.', run: (s) => { s.chars.aziz.maas += 40; addMod(s, 'aziz', 'Payını artırdın', 10, 3); } },
      { label: 'Bir şişe de sana ayıralım.', hint: 'Gus −5.', run: (s) => addMod(s, 'aziz', 'Onu lafla savdın', -5, 3) },
      { label: 'Senin gibi usta çok.', hint: 'Gus −18. Küskün usta tehlikelidir.', run: (s) => addMod(s, 'aziz', 'Onu küçümsedin', -18, 2) },
    ],
  },

  dost_haber: {
    title: 'Dostundan haber',
    p: 0.05, cooldown: 25, window: 3, def: 1,
    cond: (s) => dostlar(s).length > 0,
    text: (s) => {
      const c = s.chars[dostlar(s)[0]];
      return `${c.ad}, kapanışta tezgâhın yanına geldi. "Sana yük olmak istemem ama..." diyor. Yıllardır tanıdığın bir adam bu; boş yere gelmez.`;
    },
    options: (s) => [
      { label: 'Yanında olduğunu söyle ($100).', hint: 'Dostluk pekişir: görüşü +10. Mahallede de duyulur (halk İyilik +).', can: (st) => st.cash.dirty + st.cash.clean >= 100, run: (st) => { const id = dostlar(st)[0]; spend(st, 100, 'dirty'); addMod(st, id, 'Zor gününde yanındaydın', 10, 3); addOrtak(st, id); fame(st, 'halk', 'cephe', { i: 2 }, 0.8); } },
      { label: 'Dinle, sözle yetin.', hint: 'Görüşü +3.', run: (st) => { const id = dostlar(st)[0]; addMod(st, id, 'Dinledin', 3, 3); addOrtak(st, id); } },
      { label: 'Şimdi vaktim yok.', hint: 'Görüşü −8. Dostluk böyle aşınır.', run: (st) => { const id = dostlar(st)[0]; addMod(st, id, 'Yüzüne bakmadın', -8, 3); if (has(st, 'Cömert')) addStress(st, 4, 'Cömert birisin; dostunu geri çevirmek içine oturdu.'); } },
    ],
  },

  liman_sorusturma: {
    title: 'Harbor Trust\'ta denetim',
    p: 0.06, cooldown: 40, window: 2, def: 1,
    cond: (s) => s.kurum.liman.hisse >= 25 && s.maliSuphe > 10,
    text: () => 'Maliyeden iki müfettiş Harbor Trust defterlerini karıştırıyor. Yönetim kurulu üyesi olarak senin pay alım kaydın da inceleniyor. Bay Harrington terli bir yüzle yanına geldi: "Paranın kaynağını soracaklar."',
    options: () => [
      { label: 'Avukat tut ($250 temiz).', hint: 'Mali Şüphe −10. Kayıt temiz çıkar.', can: (s) => s.cash.clean >= 250, run: (s) => { spend(s, 250, 'clean'); s.maliSuphe = Math.max(0, s.maliSuphe - 10); addMod(s, 'selahattin', 'Sorunu birlikte çözdünüz', 4, 3); } },
      { label: 'Sessiz kal.', hint: 'Mali Şüphe aynı. %40 ihtimalle Dosya +6.', run: (s) => { if (rnd(s) < 0.4) s.pendingEvidence.push({ v: 6, why: 'Harbor Trust denetiminde pay alımının kaynağı sorgulandı.' }); } },
      { label: 'Payının bir kısmını sat (%10).', hint: 'Ortaklıktan uzaklaşırsın; Mali Şüphe −5.', can: (s) => s.kurum.liman.hisse >= 10, run: (s) => { s.kurum.liman.hisse -= 10; s.cash.clean += 10 * 600 * 0.8; s.maliSuphe = Math.max(0, s.maliSuphe - 5); } },
    ],
  },

  // --- Sistem kartları ---
  terfi: {
    title: 'Mahalle seni "Ağa" diyor', system: true, window: 99, def: 2,
    text: (s) => `Üç aydır sokaklar senden söz ediyor. Esnaf selam verirken şapka kaldırıyor, diner'larda adın geçiyor. Artık "Meyhaneci" olmanın ötesine geçtin: Güç Puanın ${gucPuani(s).gp.toFixed(1)}. Bu unvanı almak, birilerinin gözüne girmek demek.`,
    options: (s) => [
      {
        label: s.unvan.ahit ? 'Ağa unvanını kabul et.' : 'Ağa ol ve Marchetti Ailesi\'nden Ahit iste (haraç %10).',
        hint: s.unvan.ahit ? 'Zaten Marchetti\'ye bağlısın. İtibarın yükselir.' : 'Marchetti himayesi: Polis Dikkati −8. Ama gelirinin %10\'u her ay onlara gider.',
        run: (st) => { st.unvan.basamak = 1; st.unvan.ay = 0; if (!st.unvan.ahit) kabulAhit(st, 10, 'Ağa olurken Marchetti\'den istedin.'); fame(st, 'yeralti', 'cephe', { t: 12, i: 4 }, 1); fame(st, 'halk', 'cephe', { t: 6, i: 3 }, 1); log(st, 'Artık bir Ağa\'sın.', 'good'); },
      },
      {
        label: 'Ağa ol, kimseye bağlanma.',
        hint: 'Haraç yok, himaye de yok. Ama yeraltı seni fark eder: Marchetti Ailesi önünde ilk engel olursun.',
        run: (st) => { st.unvan.basamak = 1; st.unvan.ay = 0; st.unvan.tanindi = true; fame(st, 'yeralti', 'cephe', { t: 14, i: 0, k: 8 }, 1); fame(st, 'halk', 'cephe', { t: 6, i: 3 }, 1); log(st, 'Artık bir Ağa\'sın; kimseye bağlı değilsin.', 'good', 'Bu cesaret yeraltında not edildi (Korku +).'); },
      },
      { label: 'Henüz erken.', hint: 'Üç ay sonra yeniden önüne gelir.', run: (st) => { st.unvan.ay = 0; } },
    ],
  },

  terfi_reis: {
    title: 'Şehir seni "Reis" diyor', system: true, window: 99, def: 1,
    text: (s) => `Birden fazla bölgede sözün geçiyor. Esnaf, polis, hatta rakipler adını fısıltıyla değil, açıkça söylüyor. Güç Puanın ${gucPuani(s).gp.toFixed(1)}. "Reis" olursan artık bir mahallenin değil, bir şehrin sorunusun: Marchetti ve O'Brien seni hesaba katmak zorunda kalacak.`,
    options: () => [
      { label: 'Reis ol.', hint: 'Yeraltında ve halkta ün artar. Rakip aileler seni daha ciddiye alır.', run: (st) => { st.unvan.basamak = 2; st.unvan.ay = 0; st.unvan.tanindi = true; fame(st, 'yeralti', 'cephe', { t: 14, i: 3, k: 6 }, 1); fame(st, 'halk', 'cephe', { t: 6, i: 2 }, 1); log(st, 'Artık bir Reis\'sin.', 'good', 'Birden fazla bölgenin hakimi olmak seni şehrin güçlerinden biri yaptı.'); } },
      { label: 'Henüz erken.', hint: 'Üç ay sonra yeniden önüne gelir.', run: (st) => { st.unvan.ay = 0; } },
    ],
  },

  karaca_teklif: {
    title: 'Marchetti Ailesi seni çağırdı', system: true, window: 5, def: 2,
    text: () => 'Reis Vincent Marchetti\'nin adamı sabah dükkâna uğradı, bir zarf bıraktı: "Reis, mahallede gürültü yapan genç meyhaneciyle tanışmak istiyor." Marchetti Ailesi limanın yarısını elinde tutuyor. Teklif ortada: Ahit.',
    options: (s) => [
      { label: 'Ahit ver (haraç %10).', hint: 'Himaye: Polis Dikkati −8. Gelirinin %10\'u haraç.', run: (st) => kabulAhit(st, 10, 'Marchetti\'nin teklifini kabul ettin.') },
      {
        label: 'Pazarlık et (%5\'ten başla).', hint: 'Vincent\'e görüşün ve gücün belirler. Olmazsa Vincent küçük görülmüş hisseder.',
        run: (st) => {
          const p = clamp(0.35 + opinion(st, 'orhan').total / 150 + (gucPuani(st).gp / 60), 0.1, 0.7);
          if (rnd(st) < p) { kabulAhit(st, 5, 'Vincent\'le pazarlıkta %5\'te anlaştınız.'); }
          else { addMod(st, 'orhan', 'Pazarlıkta kafa tuttun', -12, 2); st.kurum.karaca.redd = true; log(st, 'Vincent pazarlığı reddetti. Teklif masadan kalktı.', 'bad', `Başarı ihtimali %${Math.round(p * 100)} idi.`); }
        },
      },
      { label: 'Reddet.', hint: 'Vincent −15. Marchetti seni artık "başına buyruk" sayar: tehdit ×1,6.', run: (st) => { st.kurum.karaca.redd = true; addMod(st, 'orhan', 'Teklifini reddettin', -15, 2); fame(st, 'yeralti', 'cephe', { t: 4, k: 4 }, 1); } },
    ],
  },

  karaca_baski: {
    title: 'Marchetti Ailesi baskı yapıyor', system: true, window: 4, def: 1,
    text: (s, card) => [
      'Marchetti\'nin adamları karakolda adını anıyor. Dolan arka kapıdan haber yolladı: "Biri dosyana ince ince bir şeyler ekletiyor."',
      'Marchetti\'ye yakın bir adam, İri Tony\'ye ve Gus\'a "daha iyi bir iş" teklif etmiş. Adamlarının gözü kayıyor.',
      'Tedarikçilerin birden fiyat yükseltti. "Marchetti Ailesi\'ne sormak lazım," diyorlar, başka bir şey demiyorlar.',
    ][(card.data && card.data.flavor) || 0],
    options: (s) => [
      { label: 'Ahit ver (haraç %10).', hint: 'Baskı durur; himaye gelir.', run: (st) => { kabulAhit(st, 10, 'Baskıya dayanamayıp Ahit verdin.'); addMod(st, 'orhan', 'Baskı işe yaradı', 0, 0); } },
      { label: 'Kapıyı kapat: $400 ver, aylarca rahat et.', hint: 'Vincent\'e "hediye": baskı üç ay seyrelir.', can: (st) => st.cash.dirty + st.cash.clean >= 400, run: (st) => { spend(st, 400, 'dirty'); addMod(st, 'orhan', 'Hediyeyle gönlünü aldın', 8, 3); st.kurum.karaca.baskiAy = dateOf(st.t).month + 2; } },
      {
        label: 'Dik dur.', hint: 'Baskı sürer. Dosya, adam kaybı ya da tedarik zammı riski.',
        run: (st, card) => {
          const f = (card && card.data && card.data.flavor) || 0;
          if (f === 0) st.pendingEvidence.push({ v: 8, why: 'Marchetti\'nin adamları dosyana ihbar ekledi.' });
          else if (f === 1) { for (const id of ['cemal', 'aziz']) if (st.chars[id] && st.chars[id].employed) addMod(st, id, 'Marchetti\'den cazip teklif aldı', -15, 2); }
          else st.tedarikZamUntil = st.t + 20 * DAY;
          fame(st, 'yeralti', 'cephe', { k: 2 }, 1);
        },
      },
    ],
  },

  baskin_ihbari: {
    title: 'Arama emri çıktı', system: true, window: 1, def: 0,
    text: (s) => `Dolan arka kapıdan haber yolladı: "Savcılık emri imzaladı. ${Math.max(1, Math.ceil((s.raid ? s.raid.at - s.t : DAY) / DAY))} gün içinde geliyorlar. Ben seni görmedim."`,
    options: () => [
      { label: 'Malı sakla, üretimi durdur.', hint: '3 gün üretim ve satış yok, stokun %20\'si gider. Baskın boşa çıkarsa Dosya −30.', run: (s) => hideGoods(s) },
      { label: 'Dolan\'a $200 ver, baskını ertelet.', hint: 'Baskın 3 gün ertelenir. Sorun çözülmez.', can: (s) => s.cash.dirty + s.cash.clean >= 200 && !!s.raid, run: (s) => { spend(s, 200, 'dirty'); if (s.raid) s.raid.at += 3 * DAY; addMod(s, 'rifat', 'İyi ödedin', 4, 3); } },
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
