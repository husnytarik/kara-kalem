# GÖLGE ŞEHİR (çalışma adı) — Oyun Tasarım Dokümanı

**Sürüm:** 0.1 (ilk taslak) · **Tarih:** 14.11.2026
**Durum:** Konsept derinleştirme. `[VARSAYIM]` etiketli her şey senin onayını bekleyen bir tercihtir; liste Bölüm 19'da.

---

## 1. Tek cümlede oyun

Saati, mevsimleri ve insanları kendi kendine işleyen, yaşayan bir şehirde; yasal işlerinin arkasına gizlediğin yasa dışı imparatorluğu büyütürken ifşa olmamaya çalıştığın, her sonucun arkasında okunabilir bir matematik olan bir mafya yaşam/strateji simülasyonu.

## 2. Tasarım sütunları

Her özellik bu altı sütundan en az birine hizmet etmeli; etmiyorsa oyuna girmez.

| # | Sütun | Anlamı |
|---|---|---|
| 1 | **Çifte hayat** | Her varlığın bir görünen yüzü, bir de gizli yüzü var. Oyunun gerilimi bu ikisinin arasındaki farktan doğar. |
| 2 | **Her şey sayıdır** | Hiçbir sonuç "senaryo gereği" olmaz. Her olay; durum değişkenlerinden, formüllerden ve tohumlu rastgelelikten çıkar. Oyuncu nedenini her zaman geriye doğru izleyebilir. |
| 3 | **Şehir sensiz de yaşar** | Saat, mevsim, ekonomi, seçimler, rakipler oyuncudan bağımsız ilerler. Oyuncu şehre uyum sağlar, şehir oyuncuya değil. |
| 4 | **Bilgi güçtür** | Oyuncu dünyayı kesin değerlerle değil, tahminlerle görür. İstihbarat tahmini daraltır. Bilgi satın alınır, çalınır, sızar. |
| 5 | **Yavaş yanan gerilim** | Tempo refleks değil öngörü ister. Tehlike aniden değil, aşama aşama ve görünür şekilde yaklaşır. |
| 6 | **Önce insanlar** | Oyuncu bir şirketi değil, bir insanı ve ailesini oynar. Her sistemin girdisi ve çıktısı bir karakterdir (Bölüm 22). |

## 3. Zaman modeli

### 3.1 Temel kural

**Oyun zamanı yalnızca oyun açıkken akar.** Oyun kapalıyken dünya durur; çevrimdışı ilerleme yoktur. Oyuncu döndüğünde her şey bıraktığı andadır.

*(Karar, 14.11.2026. Önceki "gerçek saate bağlı kalıcı dünya" modelinin yerine geçti. O modeldeki "24 saatte 3 oyun günü" oranı oynama süresine uygulanırsa 1 oyun ayı 72 saat oyun demek olurdu; bu yüzden ölçek yeniden kuruldu.)*

### 3.2 Ölçek `[VARSAYIM]`

Normal hızda:

| Oyun zamanı | Oynama süresi |
|---|---|
| 1 saat | 20 saniye |
| 1 gün | 8 dakika |
| 1 ay (10 gün) = 1 yaş | 80 dakika |
| 1 mevsim (3 ay, 30 gün) | 4 saat |
| 1 yıl (12 ay, 120 gün) | 16 saat |

Gün içi akış (sabah, akşam, gece) haritada izlenebilecek kadar yavaş; bir ay tek oturumda bitecek kadar hızlıdır. Bu sayılar ilk öneridir ve prototipte ayarlanacaktır.

### 3.3 Duraklatma ve hız

*(Karar, 14.11.2026: duraklatma + ×1, ×2, ×3.)*

| Hız | 1 saat | 1 gün | 1 ay | Ne için |
|---|---|---|---|---|
| **Duraklat** | — | — | — | Durumu okumak, emir vermek, olay kartını düşünmek |
| **×1** | 20 sn | 8 dk | 80 dk | Şehri izlemek, gergin anlar |
| **×2** | 10 sn | 4 dk | 40 dk | Olağan akış |
| **×3** | ≈7 sn | 2 dk 40 sn | ≈27 dk | Sakin dönemler, bekleme |

- Emirler duraklatılmışken verilebilir.
- Olay kartı, kritik uyarı ve karar penceresinin açılması oyunu **kendiliğinden duraklatır** (Bölüm 21.13); hangilerinin duraklatacağını oyuncu ayarlar.
- En yüksek hız bilinçli olarak ×3'te tutulur: oyunun olayları saat ve gün ölçeğinde yaşanır (Bölüm 23.3); daha hızlı akışta gün içi ritim okunmaz hâle gelir.

### 3.4 Gün içi ritim

| Dilim | Oyun saati | Şehirde ne olur |
|---|---|---|
| Sabah | 06–12 | Dükkânlar açılır, teslimatlar, resmî daireler açık (ruhsat, vergi, mahkeme) |
| Öğleden sonra | 12–18 | Ticaretin zirvesi, görüşmeler, banka işlemleri |
| Akşam | 18–24 | Meyhane/kumar zirvesi, sosyal etkinlikler, ilişki kurma fırsatları |
| Gece | 00–06 | Üretim, sevkiyat, sabotaj; devriye az ama her hareket daha dikkat çekici |

### 3.5 Takvim

- **Ayın 10. günü = Hesap Günü:** maaşlar, kiralar, vergiler, haraçlar, borç taksitleri tek seferde kapanır; herkes 1 yaş alır (Bölüm 23.2). Ayın doğal doruk noktasıdır.
- **Mevsimler** (Bölüm 13) talebi, maliyetleri ve riskleri değiştirir.
- **Seçimler** 2 takvim yılında bir: siyasi ağın yeniden kurulması gereken büyük dönüm noktası.

### 3.6 Devir araçları: vekil ve talimatlar

Bu araçlar artık "sen yokken" için değil, **ölçek ve hız** içindir: aile büyüdükçe ve oyun hızlı akarken her küçük kararla tek tek uğraşmamak için.

1. **Aşamalı tehdit:** Hiçbir yıkıcı sonuç tek adımda gelmez (bkz. Dosya aşamaları, 8.3).
2. **Karar pencereleri:** Her olayın, ağırlığına göre oyun zamanıyla ölçülen bir süresi vardır (Bölüm 23.4).
3. **Vekil:** Pencere dolarsa veya oyuncu o tür kararları devrettiyse kararı sağ kolun verir — kendi yetenek ve kişiliğine göre (Bölüm 23.5).
4. **Talimatlar:** Önceden yazılan "eğer–ise" kuralları. Örnek: *"Dosya 50'yi geçerse bodrumdaki üretimi durdur"*, *"Baskın ihbarı gelirse malı 2 numaralı depoya taşı"*. Talimat yuvası sayısı danışmanın Zekâ değerine bağlıdır (3–8).

## 4. Oyuncu deneyimi ve döngüler

**Bir oyun günü (normal hızda 8 dk):** duraklat → haritayı ve olay akışını tara → açık kararları ver → patronun ve adamların kuyruğunu doldur → akıt → olay gelince dur.

| Döngü | Süre | İçerik |
|---|---|---|
| An | saniyeler | Karar ver, emir gönder, görüşmeye git |
| Gün | 8 dk | Üretim–satış akışı, nakit, küçük olaylar |
| Ay | 80 dk | Hesap Günü, bilanço, Yıl Dönümü, büyüme kararı |
| Mevsim | 4 saat | Talep kayması, strateji değişimi |
| Yıl / seçim | 16–32 saat | Güç dengelerinin yeniden dağılımı |
| Nesil | ≈35–40 saat | Yükseliş, miras, vârise devir |

### 4.1 Kıt kaynak: Patronun zamanı

Oyuncuyu sınırlayan şey tıklama hızı değil, **patronun ajandasıdır**:

- Patron aynı anda tek yerde olabilir. Yüz yüze görüşme 1–3 oyun saati, şehir içi yol 0,5–1 saat sürer.
- Patronun bizzat yaptığı iş daha etkilidir (ilişki bonusu, sadakat bonusu) ama görünürlüğünü ve kişisel riskini artırır.
- Emirler adamlar aracılığıyla iletilir ve **gecikmeyle** uygulanır; adamın yeteneği sonucu belirler.
- Günde ≈16 uyanık saat var. Neye zaman ayırmadığın da bir karardır.

## 5. Dünya: Şehir

Kurgusal bir liman kenti, **Roaring Twenties** atmosferi: içki yasağı, caz, gizli meyhaneler, ilk otomobiller, telefonun yeni yaygınlaşması, gazetelerin gücü. Gerçek ülke/şehir/kişi yok. Simülasyon çekirdeği döneme bağlı değildir (dönem; veri tablolarıyla — operasyon türleri, teknoloji, olay havuzu — tanımlanır), bu yüzden dönem ve yer ileride farklılaşabilir.

### 5.1 Semtler

Şehir 8–12 semtten oluşur (MVP'de 3). Her semtin durumu:

| Değişken | Aralık | Etkisi |
|---|---|---|
| Nüfus | kişi | Talep tabanı, tanık yoğunluğu |
| Refah | 0–100 | Harcama gücü, kira, lüks talebi |
| Polis Dikkati | 0–100 | İfşa olasılığı çarpanı |
| Suç Düzeyi | 0–100 | Arttıkça Dikkat de artar, Refah düşer |
| Nüfuz (aile başına) | 0–100 | O semtte kimin sözü geçer; haraç, tanık sessizliği, işe alım |
| Halk Memnuniyeti | 0–100 | Düşükse ihbar artar, yüksekse halk seni korur |

Semtlerin karakteri farklıdır: Liman (kaçakçılık, işçi), Çarşı (ticaret), Eski Mahalle (sadık halk, dar sokaklar), Tepeler (villalar, siyasetçiler), Sanayi (depolar), Belediye çevresi (bürokrasi).

### 5.2 Parseller ve binalar

Semtler parsellerden oluşur. Her bina: tür, sahip, kiracı, durum, değer, **görünen işlev** ve varsa **gizli işlev**. Bina özellikleri: Kapasite, Görünürlük (ana cadde / ara sokak), Bodrum var/yok, Arka çıkış, Güvenlik.

## 6. Varlıklar

### 6.1 Yasal işletmeler

| Tür | Gelir profili | Paravan değeri | Not |
|---|---|---|---|
| Meyhane / lokanta | Akşam zirveli, mevsimsel | Yüksek (nakit yoğun) | İçki dağıtımı için doğal kanal |
| Çamaşırhane / berber | Düşük ama istikrarlı | Çok yüksek (nakit, ölçülemez hizmet) | Klasik aklama cephesi |
| Bakkal / şarküteri | İstikrarlı | Orta | Hammadde alımını gizler (şeker, maya, tahıl) |
| Nakliye / depo | Sözleşmeye bağlı | Orta | Sevkiyatı gizler, liman bağlantısı |
| Otel / pansiyon | Yaz zirveli | Yüksek | Buluşma, saklanma |
| İnşaat / müteahhitlik | Büyük, siyasete bağlı | Çok yüksek | Geç oyun; ihale ve rüşvet ekonomisi |

Her işletmenin: müdürü, çalışanları, kalitesi (0–100), itibarı (0–100), fiyat politikası, çalışma saatleri, ruhsat durumu vardır.

### 6.2 Yasa dışı operasyonlar

| Operasyon | Gereken | Kâr | İz üretimi |
|---|---|---|---|
| Kaçak içki üretimi | Bodrum, usta, hammadde | Yüksek | Orta (koku, duman, hammadde alımı) |
| Kaçak içki dağıtımı | Araç, sürücü, satış noktası | — | Orta–yüksek (sokakta hareket) |
| Kumarhane | Arka oda, kasa adamı | Yüksek, dalgalı | Orta (gece trafiği) |
| Koruma haracı | Tahsildar, Korku itibarı | Orta, istikrarlı | Düşük ama mağdur ihbarı riski |
| Tefecilik | Sermaye, tahsildar | Orta | Düşük |
| Kaçakçılık (liman) | Gümrük bağlantısı, depo | Çok yüksek, partili | Tek seferde yüksek |
| Çalıntı mal ticareti | Depo, alıcı ağı | Orta | Orta |

`[VARSAYIM]` Kapsam dışı: uyuşturucu ve insan ticareti gibi temalar ilk sürümde yok.

### 6.3 Kişisel varlıklar

- **Villa:** Güvenlik (0–100), Gizli kasa, Prestij. Patronun güvenliği = Villa Güvenliği + korumalar + rutin öngörülemezliği.
- **Güvenli ev:** Soruşturma/savaş sırasında saklanma.
- **Araçlar:** Yol süresi, kaçış, sevkiyat kapasitesi.

## 7. Ekonomi

### 7.1 İki para: Temiz ve Kirli

Oyunun merkezî ekonomik mekaniği. **Kirli para** yasa dışı işten gelir; sadece nakit işlerde (rüşvet, yasa dışı maaş, karaborsa) harcanabilir. **Temiz para** ile mülk alınır, vergi ödenir, resmî maaş verilir. Kirli parayı büyük alımlarda kullanmak Mali Şüphe üretir.

**Aklama:** Her paravan işletmenin aylık aklama kapasitesi vardır:

```
AklamaKapasitesi = GerçekCiro × AklamaOranı(tür)        # berber 0,50 · meyhane 0,30 · bakkal 0,20
AklamaMaliyeti   = AklananTutar × (VergiOranı + MuhasebeciPayı)   # tipik %20
```

Kapasite aşılırsa beyan edilen ciro, o işletmeden beklenenin üzerine çıkar:

```
Sapma        = BeyanCiro / BeklenenCiro − 1 − Tolerans(muhasebeci yeteneği)
MaliŞüphe   += k × max(0, Sapma)²        # karesel: küçük aşım ucuz, büyük aşım felaket
```

### 7.2 Talep ve rekabet

Semt `d`, ürün kategorisi `k` için saatlik talep:

```
Talep(d,k) = Nüfus × KişiBaşıHarcama(k, Refah) × Mevsim(k) × EkonomiDöngüsü × SaatProfili(k)
```

Aynı işi yapan işletmeler bu talebi çekicilikleri oranında paylaşır:

```
Çekicilik_i = Kalite^1,0 × İtibar^0,5 × Fiyat^(−1,5) × KonumÇarpanı
Pay_i       = Çekicilik_i / Σ Çekicilik_j
Ciro_i      = Talep × Pay_i × Fiyat_i      (kapasiteyle sınırlı)
```

Sonuç: fiyat kırmak pay kazandırır ama marjı eritir; rakibin itibarını düşürmek (söylenti, sabotaj, denetim göndermek) senin payını büyütür. Yasal rekabet ile yasa dışı araçlar aynı formülde buluşur.

### 7.3 Giderler

Maaşlar, kira/bakım, hammadde (fiyatı dalgalanır), vergi, rüşvet ve "hediye"ler, avukat/muhasebeci ücretleri, borç faizi, patronun yaşam standardı (düşürülürse Prestij düşer).

### 7.4 Makro ekonomi

Şehrin 3–5 oyun yıllık bir ekonomi döngüsü vardır (canlanma → zirve → durgunluk). Durgunlukta yasal ciro düşer, işsizlik artar (ucuz adam, daha çok suç), tefecilik ve kumar talebi artar.

### 7.5 Örnek kesit — senin hayal ettiğin durumun aylık bilançosu

*(Rakamlar ölçek göstermek içindir, denge değerleri değildir.)*

| Kalem | Ciro | Gider | Net |
|---|---|---|---|
| Meyhane | 4.200 | 3.100 | +1.100 |
| Nakliye deposu | 3.500 | 2.700 | +800 |
| Bakkal | 2.400 | 1.900 | +500 |
| Çamaşırhane | 1.800 | 1.300 | +500 |
| **Yasal toplam** | **11.900** | **9.000** | **+2.900 (temiz)** |
| Bodrum imalathanesi (400 şişe × 12) | 4.800 | 1.600 | **+3.200 (kirli)** |

| Genel gider | Tutar |
|---|---|
| 2 koruma | 500 |
| Villa bakım ve güvenlik | 400 |
| İlişkiler (rüşvet, hediye, davet) | 600 |
| Avukat (sabit ücret) | 200 |
| Yaşam standardı | 300 |
| **Toplam** | **2.000** |

- Aklama kapasitesi ≈ 11.900 × 0,30 = **3.570** → 3.200 kirli paranın tamamı sığar.
- Aklama maliyeti %20 = 640 → **2.560 temiz**.
- Ay sonu net: 2.900 + 2.560 − 2.000 = **+3.460 temiz**.

Çıkarım: Üretimi ikiye katlarsan 6.400 kirli para olur ama kapasite 3.570. Ya yeni paravan açarsın, ya fazlayı kirli tutarsın, ya da Mali Şüphe'yi göze alırsın. **Büyüme kararı kendiliğinden bir ikilem üretir** — tasarımın istediği tam olarak bu.

## 8. Gizlilik ve kanun

Üç katmanlı model: operasyon **İz** bırakır → polis İz'i **Kanıt**a çevirir → kanıt **Dosya**da birikir.

### 8.1 İz (operasyon başına, 0–100)

```
GünlükİzÜretimi = Tabanİz(tür) × (Hacim / RefHacim)^0,7 × (1 − Gizlilik)
İz(t+1)         = İz(t) × (1 − 0,15) + GünlükİzÜretimi + Olayİzi
```

- **Gizlilik** (0–1): bina özellikleri (bodrum, arka çıkış, ara sokak), paravanın inandırıcılığı, çalışanların Ketumluğu, gece çalışma.
- **Olay izi:** kavga, yangın, sarhoş çalışan, yakalanan sevkiyat, küsmüş eski eleman.

Örnek: 40 şişe/gün, RefHacim 20, Tabanİz 8, Gizlilik 0,5 → üretim = 8 × 2^0,7 × 0,5 ≈ **6,5/gün**; kararlı durum İz ≈ 6,5 / 0,15 ≈ **43**.

### 8.2 Tespit

Her gün, her operasyon için:

```
P(kanıt) = 1 − exp(−0,0001 × İz × SemtPolisDikkati)
```

Örnek: İz 43, Dikkat 40 → P ≈ **%16/gün**. Tespit doğrudan baskın değildir; Dosya'ya 3–10 puan kanıt ekler (kanıt türüne göre: söylenti 3, gözlem 5, tanık ifadesi 8, fiziksel delil 10).

Semt Polis Dikkati; suç düzeyi, şiddet olayları, basın haberleri ve siyasi baskıyla artar; rüşvetli amirle, sakin geçen günlerle düşer.

### 8.3 Dosya (kişi ve aile başına, 0–100)

| Eşik | Aşama | Olan | Oyuncunun hamlesi |
|---|---|---|---|
| 0–24 | Radar altı | Hiçbir şey | — |
| 25 | **Gözetim** | Sivil ekipler; İz üretimi ×1,5 sayılır | Hacmi kıs, rutini değiştir |
| 50 | **Soruşturma** | Savcı atanır; çalışanlar sorguya çekilebilir (sadakat testi) | Avukat, tanık ikna, delil karartma, siyasi baskı |
| 75 | **Arama emri** | 1–3 oyun günü içinde baskın | Malı taşı, operasyonu kapat, ihbar kaynağını bul |
| 100 | **Dava** | Tutuklama ve mahkeme | Savunma, hâkim/jüri, anlaşma, firar |

Dosya kendiliğinden yavaş söner (kanıt eskir), aktif önlemlerle hızlı düşer. İçeride adamın varsa aşamaları önceden haber alırsın (Bölüm 11).

### 8.4 Mahkeme ve ceza

Dava sonucu: kanıt gücü − avukat yeteneği − tanık durumu − hâkim eğilimi üzerinden Bölüm 14'teki çözümleme formülüyle. Sonuçlar: beraat, para cezası, mülke el koyma, hapis. Patron hapisteyken oyun sürer: emirler daha gecikmeli ve kayıplı iletilir, vekil öne çıkar, sadakat her gün sınanır.

## 9. İnsanlar

Şehirdeki önemli herkes (adamların, rakipler, memurlar, siyasetçiler) aynı karakter modeliyle simüle edilir.

### 9.1 Nitelikler (0–100)

| Yetenek | Kişilik |
|---|---|
| Zekâ, Güç, İkna, Ticaret, Zanaat (üretim), Ketumluk | Hırs, Açgözlülük, Cesaret, Dürüstlük, Yozlaşabilirlik |

Ayrıca: yaş, sağlık, aile bağları, borçlar, zaaflar (kumar, içki, sevgili) — zaaflar hem senin kullanabileceğin hem rakibin kullanabileceği kaldıraçlardır.

### 9.2 Roller

Koruma, müdür, usta (üretici), sürücü, tahsildar, muhasebeci, avukat, muhbir, danışman (vekil), tetikçi. Her rol belirli yetenekleri formüllere sokar (ör. muhasebecinin Zekâsı → aklama toleransı; ustanın Zanaati → ürün kalitesi ve fire).

### 9.3 Sadakat

```
HedefSadakat = 50
             + 25 × clamp(Maaş/PiyasaMaaşı − 1, −1, +1)
             + 0,20 × PatronSaygı + 0,10 × PatronKorku
             + KişiselBağ (iyilikler, kurtarılma, akrabalık)
             − 0,25 × Hırs × (TerfiBeklentisi karşılanmadıysa 1, yoksa 0)
             − SonOlaylar (hakaret, arkadaşının harcanması, ödenmemiş maaş)

Sadakat(t+1) = Sadakat(t) + 0,10 × (HedefSadakat − Sadakat(t))      # günlük
```

Sadakat sorgu, rakip teklifi ve kriz anlarında **sınanır**. Düşük sadakatin sonuçları kademelidir: verim düşer → kasadan çalar → bilgi sızdırır → taraf değiştirir / itirafçı olur. Oyuncu sadakati kesin değil, **tahmini** görür (Bölüm 11).

### 9.4 Patron

Üç itibar ekseni: **Saygı** (adil, sözünün eri), **Korku** (acımasız), **Kamu İmajı** (hayırsever iş insanı ↔ bilinen gangster). Bunlar birbirinin yerine geçmez: Korku haracı kolaylaştırır ama Kamu İmajını ve siyasetçi ilişkilerini zorlaştırır.

Patron ölür veya müebbet alırsa: önceden belirlenmiş **vâris** ile devam (varlıkların ve ilişkilerin bir kısmı kaybolur). Vâris yoksa oyun biter.

## 10. İlişkiler ve siyaset

### 10.1 İlişki ağı

Her kişi çifti arasında **İlişki** (−100…+100) ve **Borç** (kim kime iyilik borçlu) tutulur. İlişkiler ilgisizlikle söner (ayda ≈ −2); canlı tutmak patronun zamanını ister.

Temas türleri: karakol amiri, savcı, hâkim, belediye meclis üyesi, belediye başkanı, gümrük müdürü, gazete sahibi, sendika lideri, banka müdürü, din/kanaat önderi.

### 10.2 İyilik ekonomisi

Para her kapıyı açmaz. İkinci para birimi **iyiliktir**: birinin oğluna iş bulmak, borcunu kapatmak, rakibini susturmak. İyilik borcu sonra talep edilir: ruhsat, ihale, baskın ihbarı, dosyanın "kaybolması". Borcu büyük olandan istenen şey reddedilirse ilişki çöker.

### 10.3 Rüşvet

Bölüm 14'teki genel formülün bir uygulaması:

```
x = 1,2 × ln(1 + Rüşvet/AylıkMaaşı) + İlişki/40 + (Yozlaşabilirlik − 50)/20 − Dosya/50
P(kabul) = 1 / (1 + e^(−x))
```

Örnek: 300 rüşvet (maaşı 150), İlişki 20, Yozlaşabilirlik 60, Dosya 40 →
x = 1,32 + 0,50 + 0,50 − 0,80 = 1,52 → **P ≈ %82**.

Ret hâlinde: ilişki düşer. Kritik ret (dürüst memur): teklifi rapor eder, Dosya'ya kanıt eklenir. Kabul eden kişi artık **bağlıdır** — onun yakalanması seni de yakar.

### 10.4 Siyaset

- Meclis ve başkan, şehir politikalarını belirler: polis bütçesi (Dikkat tabanı), yasak denetimlerinin sıkılığı, vergi, ruhsat, ihaleler.
- **Seçim kampanyası:** adaylara bağış (temiz para görünür, kirli para riskli), semt Nüfuzunla oy getirme, rakip adayı karalama.
- Kazanan aday sana borçludur; kaybeden adayı desteklediysen yeni yönetim sana düşmandır.
- **Basın:** Kamu İmajını ve siyasi baskıyı yönlendirir. Gazete skandal yazarsa Polis Dikkati artar; gazete sahibi dostunsa haber çıkmaz.

## 11. Bilgi ve istihbarat

Oyuncu **kendi** varlıklarını bile yalnızca raporlandığı kadar bilir.

- Her gizli değer oyuncuya `tahmin ± belirsizlik` olarak gösterilir: *"Kemal'in sadakati: 55–80"*, *"Rakip meyhanenin cirosu: ≈3.000–5.000"*, *"Dosya: Soruşturma aşamasına yakın (kaynak: karakoldaki adamın, güvenilirlik orta)"*.
- Belirsizlik; kaynak sayısı, kaynağın güvenilirliği ve bilginin yaşıyla daralır/genişler.
- **Kaynaklar:** muhbirler (maaşlı), satın alınmış memurlar, kendi adamlarının gözlemi, söylentiler (bedava ama gürültülü, bazen rakibin kasıtlı yalanı).
- **Karşı istihbarat:** Rakipler ve polis de seni aynı sistemle izler. Çalışanların Ketumluğu, sızıntı olasılığını belirler. Köstebek avı bir oyun içi soruşturmadır: yanlış kişiyi cezalandırmak sadakati çökertir.
- Müdürler kasadan çalıyorsa bunu rapor etmezler; fark, beklenen ciro ile raporlanan ciro arasındaki sapmadan **senin fark etmen** gereken bir şeydir (muhasebeci yeteneği yardımcı olur).

## 12. Rakipler ve çatışma

### 12.1 Rakip türleri

- **Yasal rakipler:** Aynı işi yapan esnaf. Çoğu masumdur; bazıları başka bir ailenin paravanıdır.
- **Aileler:** 3–5 yapay zekâ kontrollü suç örgütü. Oyuncuyla **aynı kurallara** tabidir (para, iz, dosya, sadakat). Her patronun kişiliği stratejisini belirler: tüccar, kasap, siyasetçi, hayalet.
- **Devlet:** Rakip değil, ortamdır; ama hırslı bir savcı kişisel düşman olabilir.

### 12.2 Araçlar (hafiften ağıra)

Fiyat savaşı → eleman ayartma → söylenti → denetim/ihbar gönderme → sabotaj (yangın, sevkiyat baskını) → gözdağı → suikast → açık savaş.

Her adım daha etkili ama daha çok İz, Dikkat ve misilleme üretir. **Şiddet pahalıdır:** tek bir cinayet semt Dikkatini +20–30, Dosya'yı +10–25 artırır ve basına düşer. Oyun şiddeti yasaklamaz, bedelini hesaplatır.

### 12.3 Çatışma çözümü

Taktik dövüş ekranı yok. Çatışmalar soyut çözülür: tarafların Güç toplamı, silah, hazırlık, sürpriz, mekân güvenliği → Bölüm 14 formülü → sonuç dağılımı (başarı / kısmi / fiyasko) + kayıplar + tanık sayısı.

### 12.4 Diplomasi

Görüşme (sit-down), bölge paylaşımı, ateşkes, haraç, ortak iş, evlilik bağı, ihanet. Anlaşmaya uymamak tüm ailelerle "Söz" itibarını düşürür.

## 13. Mevsimler ve olaylar

| Mevsim | Etkiler |
|---|---|
| **Kış** | Isınma gideri ↑, içki ve kumar talebi ↑, liman trafiği ↓ (kaçakçılık zor), yılbaşı döneminde talep zirvesi, sokak boş (tanık ↓, ama hareket dikkat çekici) |
| **İlkbahar** | İnşaat ve ticaret canlanır, ruhsat/ihale dönemi, seçim yılıysa kampanya |
| **Yaz** | Turizm: otel/meyhane cirosu ↑, kalabalık (tanık ↑, kamuflaj ↑), sıcakta üretim firesi ve koku ↑ (İz ↑) |
| **Sonbahar** | Hasat: hammadde ucuz (stok fırsatı), vergi denetimleri yoğunlaşır, liman en yoğun dönemde |

**Olay sistemi:** Olaylar senaryo değil, **koşullu olasılıklardır**. Her olay şablonunun bir ön koşulu ve durum değişkenlerine bağlı günlük olasılığı vardır. Örnekler: grev (sendika ilişkisi düşük + ekonomi durgun), yangın (eski bina + sabotaj riski), salgın, yeni emniyet müdürü ataması, banka iflası, gazetede ifşa dizisi, sert kış, büyük maç/festival, rakip patronun ölümü ve taht kavgası.

## 14. Simülasyon çekirdeği

### 14.1 İlkeler

1. **Tek kaynak durum:** Dünyanın tamamı sayısal durum değişkenleridir. Olaylar durumu değiştirir, durum olayların olasılığını.
2. **Evrensel çözümleme:** Sonucu belirsiz her eylem aynı kalıpla çözülür:
   ```
   x = Σ (ağırlık_i × etken_i)          # lehte olanlar +, aleyhte olanlar −
   P(başarı) = 1 / (1 + e^(−x))
   ```
   Sonuç ikili değildir: zar, x'e göre **kritik başarı / başarı / kısmi / başarısızlık / fiyasko** bantlarına düşer.
3. **Şeffaflık:** Karar ekranı etkenleri listeler (*"İlişki +0,5 · Dosya −0,8 · …"*) ve tahmini olasılığı verir. Tahminin kesinliği istihbarata bağlıdır (gizli etkenler "?" görünür).
4. **Nedensellik kaydı:** Her olay, onu tetikleyen etkenlerle birlikte loglanır. Oyuncu "bu neden oldu?" sorusunu zincir hâlinde geriye izleyebilir (bilgisi yettiği kadar).
5. **Geri besleme sönümü:** Her birikimli değişkenin (İz, Dosya, Dikkat, İlişki) doğal bir sönümü vardır; sistem ne patlar ne donar.
6. **Deterministik + tohumlu RNG:** Aynı durum + aynı tohum = aynı sonuç. Test, denge ve çok oyunculu eşzamanlama için şart.

### 14.2 Tik yapısı

| Sıklık | Hesaplananlar |
|---|---|
| Olay kuyruğu (dakika hassasiyeti) | Zamanlanmış eylemler: görüşme bitişi, sevkiyat varışı, karar penceresi kapanışı |
| Her oyun saati (20 sn) | Talep, satış, üretim, kişilerin konumu/rutini |
| Her oyun günü (8 dk) | İz, tespit, sadakat, ilişki sönümü, olay olasılıkları, YZ aile kararları |
| Hesap Günü (10 gün) | Bilanço, maaş, vergi, Mali Şüphe, semt değişkenleri |
| Mevsim / yıl | Mevsim çarpanları, ekonomi döngüsü, yaşlanma, seçimler |

Süreler normal hız içindir. Çevrimdışı ilerleme yoktur; tikler yalnızca oyun açıkken ve duraklatılmamışken koşar.

## 15. Arayüz ve sunum

- **Ana ekran: taktik şehir haritası.** Üstten/izometrik, stilize, okunabilir. Binalar tıklanabilir; kişiler ve araçlar haritada hareket eder; gece–gündüz ve mevsim görsel olarak yansır.
- **Harita katmanları:** Mülkiyet · Nüfuz · Polis Dikkati · Ekonomi (talep/ciro) · İstihbarat (ne kadar bildiğin).
- **Paneller:** Defter (temiz/kirli nakit akışı, bilanço) · Kişiler (dosya kartları, ilişki ağı grafiği) · Operasyonlar · Ajanda (patronun günü) · Talimatlar · Olay akışı / nedensellik kaydı · Takvim (yaklaşan Hesap Günü, seçim, mevsim).
- **Üst bar:** oyun saati/tarih, mevsim, temiz nakit, kirli nakit, Dosya aşaması (tahmini), bekleyen karar sayısı.
- **Ton:** Ciddi, kuru, gazete/defter estetiği. Ses: şehir ambiyansı, dönem müziği.

## 16. İlerleme ve hedefler

Sabit bir "kazanma" ekranı yok; **hırslar** var (oyuncu seçer, oyun önerir): bir semtin tek hâkimi olmak, belediye başkanını cebe koymak, tamamen yasallaşıp aklanmak, rakip aileyi bitirmek, mirası vârise temiz devretmek.

**Güç basamakları (yaklaşık):** sokak girişimcisi → mahalle patronu → semt hâkimi → şehir çapında aile → siyasetin arkasındaki el. Her basamak yeni araçlar ve yeni tehdit türleri açar (ör. şehir çapında aile olunca devlet düzeyi soruşturma).

**Kaybetme:** vârissiz ölüm/müebbet, tam iflas. Kısmi çöküşler (hapis, mülk kaybı) oyunu bitirmez, hikâyenin parçasıdır.

## 17. Teknik yaklaşım

- **Tek oyunculu başlar, çok oyunculuya açık kalır.** İlk sürüm YZ rakipli; zaman yalnızca oyun açıkken akar. Çok oyunculuya geçişi mümkün kılan kurallar baştan uygulanır:
  - YZ aileler oyuncuyla aynı eylem arayüzünü kullanır; bir aileyi YZ yerine insan yönetebilmelidir.
  - Çekirdek, "eylem girer → durum değişir" biçiminde çalışır ve arayüzden ayrıdır; ileride sunucuda koşabilir.
  - Zaman yalnızca oynarken aktığı için çok oyunculu **oturum tabanlı** olur: oyuncular aynı anda bağlanır, hız ve duraklatma ortaktır. Herkesin ayrı saatlerde girdiği kalıcı ortak şehir bu zaman modeliyle uyumlu değildir.
  - Oyun saati tek bir oturum saatinden türetilir; oyuncuya özel saat yoktur.
- **Simülasyon çekirdeği motordan bağımsız** saf bir kütüphane: deterministik, tamsayı/sabit noktalı aritmetik, tohumlu RNG, arayüzsüz koşabilir (denge testleri için binlerce oyun günü saniyeler içinde simüle edilebilmeli).
- **Veri güdümlü:** işletme türleri, olay şablonları, formül katsayıları kod dışında tablolarda. Denge ayarı kod değişikliği gerektirmez.
- **Arayüzsüz hızlı koşu** denge testleri içindir (binlerce oyun günü saniyeler içinde).
- `[VARSAYIM]` Platform: PC. Uzun oturumlu, yoğun arayüzlü bir oyun; mobil öncelik değil.

## 18. MVP ve yol haritası

### 18.1 Dikey kesit (ilk oynanabilir sürüm)

Senin anlattığın kesitin kendisi:

- 3 semt, ≈60 parsel
- 4 yasal işletme türü + 1 yasa dışı operasyon (içki üretimi ve dağıtımı)
- Temiz/kirli para ve aklama
- İz → Kanıt → Dosya zinciri (baskına kadar; mahkeme basit)
- ≈30 isimli kişi, sadakat, 5 rol
- 5 temas (amir, savcı, meclis üyesi, gazeteci, gümrükçü), rüşvet ve iyilik
- 1 YZ aile + yasal rakipler
- Zaman, gün dilimleri, 4 mevsim, Hesap Günü
- Duraklatma ve hız kontrolü, otomatik duraklatma, vekil, 3 talimat yuvası
- Harita + Defter + Kişiler + Olay akışı

**Başarı ölçütü:** Oyuncu ilk oyun yılını (≈16 saat, ×2 hızla ≈8 saat) bitirmek istiyor mu, ve başına gelen her kötü şeyin nedenini anlayabiliyor mu?

### 18.2 Aşamalar

| Aşama | İçerik |
|---|---|
| 0 — Kâğıt/tablo prototipi | Ekonomi ve Dosya formüllerini e-tabloda 1 oyun yılı koştur; sayılar anlamlı mı? |
| 1 — Arayüzsüz çekirdek | Simülasyon kütüphanesi + otomatik denge testleri |
| 2 — Dikey kesit | 18.1 |
| 3 — Derinlik | Seçimler, tüm operasyon türleri, çoklu aile, diplomasi, mahkeme, vâris |
| 4 — Genişlik | Tam şehir, olay havuzu, cila, (opsiyonel) çok oyunculu |

## 19. Açık kararlar

**Verilmiş kararlar (14.11.2026):**

| Karar | Sonuç |
|---|---|
| Oyuncu sayısı | Tek oyunculu başlar; mimari çok oyunculuya açık (Bölüm 17) |
| Dönem ve yer | Roaring Twenties, kurgusal liman kenti; ileride farklılaşabilir |
| Zaman akışı | Yalnızca oynarken akar; çevrimdışı ilerleme yok (Bölüm 3.1) |
| Oyuncu sayısı notu | Çok oyunculu olursa oturum tabanlı olur (Bölüm 17) |
| Oyun yönü | Karakter odaklı hanedan stratejisi (Bölüm 22) |
| Hız kontrolü | Duraklat + ×1, ×2, ×3 (Bölüm 3.3) |
| Yaşam ölçeği | Karakterler her oyun ayında 1 yaş alır (Bölüm 22.8) |

**Hâlâ açık:**

| # | Karar | Taslaktaki varsayım | Neden önemli |
|---|---|---|---|
| 1 | Platform | PC | Arayüz yoğunluğu, oturum uzunluğu |
| 2 | Şiddetin sunumu | Soyut, metin/rapor düzeyi | Yaş sınırı, ton |
| 3 | Motor | Karar verilmedi | Çekirdek bağımsız olduğu için ertelenebilir |
| 4 | Kapsam dışı temalar | Uyuşturucu ve insan ticareti yok | Ton, operasyon listesi |
| 5 | Zaman ölçeği | 1 gün = 8 dk, 1 ay = 80 dk (normal hız) | Oyunun bütün temposu |
| 6 | Olay yoğunluğu | Bölüm 23.3'teki sıklıklar | Şehir ölçeğinin "her gün bir şey olur" hissi; prototipte ayarlanacak |
| 7 | Kayıt düzeni | Tek kayıt, geri yükleme yok | Kararların ağırlığı; istenirse serbest kayıt açılabilir |

## 20. Riskler

1. **Tempo:** Gün içi akışı izlenebilir kılacak kadar yavaş, nesil geçişini yaşatacak kadar hızlı bir ölçek dar bir aralıktır. Bölüm 3.2'deki sayılar tahmindir; prototipte ilk ayarlanacak şeydir.
2. **Hızlı akışta kaçan olay:** ×3 hızda oyuncunun fark etmeden zarar görmesi. Otomatik duraklatma ve yavaşlatma (Bölüm 23.6) bunun içindir; en çok test edilmesi gereken alan.
3. **Bekleme boşluğu:** Sakin dönemlerde "yapacak bir şey yok" anları. Karşılığı: hız kontrolü, olay bütçesi ve her oyun gününde anlamlı en az bir karar hedefi.
4. **Matematiğin görünmezliği:** Derin simülasyon oyuncuya okunmazsa rastgele görünür. Nedensellik kaydı ve etken dökümü zorunlu özelliktir, süs değil.
5. **Kapsam:** Bu doküman büyük bir oyunu tarif ediyor. Dikey kesit dışındaki her şey, kesit eğlenceli çıkana kadar bekler.
6. **Denge patlaması:** Birbirini besleyen döngüler (para → rüşvet → güvenlik → daha çok para). Karşılığı: sönümler, karesel maliyetler, büyüdükçe artan devlet ilgisi; arayüzsüz çekirdekle toplu simülasyon testi.

---

## 21. Oynanış: oyuncu fiilen ne yapar?

Bölüm 4 döngüleri tarif eder; bu bölüm ekranın başındaki oyuncunun elindeki işi tarif eder.

### 21.1 Başlangıç `[VARSAYIM]`

Oyuncu hazır bir imparatorlukla değil, **miras kalan tek bir meyhaneyle** başlar. İçki yasağı yeni yürürlüğe girmiştir: meyhanenin asıl geliri bir gecede yasa dışı olmuştur.

| Başlangıç varlığı | Değer |
|---|---|
| Meyhane (Eski Mahalle, bodrumlu, ara sokakta) | Cirosu yasak yüzünden yarıya düşmüş |
| Sadık bir adam (amcanın eski ortağı) | İlk danışman/vekil; öğreticinin sesi |
| Nakit | 1 aylık gideri karşılar |
| Borç | Amcadan kalan, her Hesap Günü taksitli |
| Boş bodrum | İlk büyük kararın mekânı |

Borç, ilk ayın motorudur: yasal kalarak ödemek mümkün ama çok zordur. Oyun oyuncuyu suça **zorlamaz, iter**.

Senin anlattığın kesit (4 işyeri, imalathane, 2 koruma, villa) yaklaşık 1 oyun yılı (≈16 saat oyun) sonunda ulaşılan "mahalle patronu" basamağıdır.

### 21.2 Fiiller: oyuncunun eylem sözlüğü

| Fiil | Eylemler | Kim yapar |
|---|---|---|
| **İşlet** | Fiyat, çalışma saati, kalite yatırımı, işe alma/çıkarma, maaş | Oyuncu doğrudan (anında) |
| **Kur** | Satın al, kirala, tadilat, gizli bölme, güvenlik | Oyuncu karar verir; inşaat gün sürer |
| **Üret / Dağıt** | Hacim, hammadde alımı, stok, rota, teslimat saati | Usta ve sürücüler |
| **Görüş** | Ziyaret, yemek, davet, pazarlık, rüşvet, tehdit | Patron bizzat veya elçi |
| **Emret** | Gözetle, takip et, ikna et, gözdağı ver, taşı, koru, sabote et | Adamlar |
| **Öğren** | Muhbir tut, defter denetle, söylenti satın al, birini araştır | Adamlar, muhasebeci |
| **Gizle** | Operasyonu durdur, malı taşı, sahte defter, delil yok et, ortadan kaybol | Adamlar; acil durumda patron |
| **Planla** | Ajanda, talimatlar, bütçe, vâris | Oyuncu doğrudan |

"İşlet" ve "Planla" anında gerçekleşir. Diğer her şey **bir kişi, bir süre ve bir risk** gerektirir.

### 21.3 Bir eylemin anatomisi

1. **Hedef seç** — haritada bina/kişi veya panelde kayıt.
2. **Eylemi seç** — yalnızca o hedefe o an mümkün olanlar listelenir; mümkün olmayanlar nedeniyle birlikte soluk görünür (*"Savcıyla görüşme: tanışmıyorsunuz — aracı gerekli"*).
3. **Kim, ne zaman** — patron mu, hangi adam mı; hemen mi, belirli bir oyun saatinde mi.
4. **Tahmin kartı** — olasılık, süre, maliyet, üreteceği İz, lehte/aleyhte etkenler. Bilinmeyen etkenler "?" olarak görünür.
5. **Onay** — eylem kuyruğa girer; kişi haritada yola çıkar.
6. **Bekleme** — eylem oyun saatinde sürer (2 oyun saatlik görüşme = normal hızda 40 saniye).
7. **Sonuç raporu** — ne oldu, neden oldu, ne değişti. Raporun doğruluğu, raporu verenin dürüstlüğüne bağlıdır.

### 21.4 Ajanda ve kuyruklar

- Patronun ve her adamın bir **görev kuyruğu** vardır. Oyuncu **3 oyun günü ilerisine** kadar plan yapabilir; kuyruk dolu oldukça oyun hızlı akıtılabilir.
- Kuyruktaki işler koşula bağlanabilir (*"görüşme olumlu biterse sevkiyatı başlat"*).
- Beklenmedik olay kuyruğu bozarsa (adam yaralandı, yol kapalı) vekil yeniden düzenler veya karar penceresi açar.
- Kural: **her oyun günü en az bir anlamlı karar sunmalı.** Sunamıyorsa dünya yeterince fırsat/tehdit üretmiyordur; bu bir denge hatasıdır.

### 21.5 İletişim: telefon ve ulak

Dönemin teknolojisi bir mekaniktir:

| Kanal | Hız | Risk |
|---|---|---|
| **Telefon** (hattı olan binalar arası) | Anında | Soruşturma aşamasında dinlenebilir; söylenen her şey kanıt olabilir |
| **Ulak** (adam gönderme) | Yol süresi kadar gecikme | Ulağın sadakati ve yakalanma riski |
| **Yüz yüze** (patron gider) | Patronun zamanı | En güvenli, en etkili; patronu görünür kılar |

Hat çektirmek bir yatırımdır; hattı kullanmamak bir disiplindir.

### 21.6 Canlı akış ve müdahale

Saat akarken şehir haritada canlı işler: sevkiyat kamyonu yolda, devriye köşede, müşteriler meyhanede. Oyuncu olan biteni görür, **duraklatıp emir değiştirebilir** (rotayı çevir, teslimatı iptal et); ama emir yine 21.5'teki kanallardan geçer ve gecikmeyle ulaşır. Refleks oyunu yoktur: duraklatma düşünmek içindir, emrin yolda geçen süresini kısaltmaz.

### 21.7 Fırsatlar: "Kulağına Gelenler"

Dünya sürekli, süreli fırsatlar üretir; hepsi simülasyon durumundan doğar:

- İflasın eşiğinde bir rakip dükkânını satıyor (rakibin nakdi gerçekten tükendiği için).
- Limana sahipsiz bir parti geldi (gümrükçü dostun haber verdi; 2 oyun günü geçerli).
- Kumar borcu olan bir komiser yardım arıyor (zaafı olduğu için).
- Usta bir imalatçı hapisten çıktı, iş arıyor.
- Meclis üyesi kampanyası için bağışçı arıyor.

Fırsatların kaçı kulağına gelir, ne kadar erken gelir: istihbarat ağına ve ilişkilerine bağlıdır. İyi ağ = rakipten önce haber.

### 21.8 İkilem kalıpları

Her karar bir bedel içermeli. Oyunun tekrar eden gerilimleri:

| İkilem | Bir yanda | Diğer yanda |
|---|---|---|
| Büyüme ↔ Gizlilik | Daha çok üretim, daha çok para | Daha çok İz, aklama kapasitesi aşımı |
| Hız ↔ Güvenlik | Telefon, gündüz sevkiyat, patron bizzat | Ulak, gece, aracı |
| Sadakat ↔ Maliyet | Yüksek maaş, terfi, iyilik | Nakit; ucuz adam ucuz konuşur |
| Korku ↔ İmaj | Haraç ve itaat kolaylaşır | Siyasetçi ve basın kapıları kapanır |
| Bugün ↔ Yarın | Nakdi şimdi kâra yatır | İlişkiye, istihbarata, yedek plana yatır |
| Bilmek ↔ Yapmak | Emin olana kadar araştır | Fırsat penceresi kapanır |

### 21.9 Örnek oyun kesiti (bir oyun günü)

Oyuncu kaydı açıyor; oyun duraklatılmış, saat 14:00, ayın 7. günü.

1. **Kaldığın Yer özeti:** *"Dün gece sevkiyat sorunsuz. Bakkalın cirosu beklenenden %12 düşük — müdür 'yağmurdan' diyor. Vekilin kararı: karakol amirinin doğum günü hediyesi gönderildi (40 ₺)."*
2. **Tarama:** Polis Dikkati katmanında Eski Mahalle sarıya dönmüş. Olay akışına bakıyor: iki gece önce sokakta bir kavga çıkmış, kendisiyle ilgisi yok ama devriye artmış.
3. **Karar 1:** Bu gece üretimi %50 kıs (İz düşsün). Kayıp: ≈240 ₺.
4. **Karar 2:** Bakkal müdürüne muhasebeciyi gönder, defteri denetlesin (1 oyun günü sürer).
5. **Fırsat:** *"Çarşı'da bir çamaşırhane satılık, 2 gün geçerli."* Aklama kapasitesi lazım ama Hesap Günü'ne 3 gün var ve nakit sınırda. Banka müdürüyle yarın sabah 10:00'a görüşme koyuyor.
6. **Ajanda:** Patron bu akşam meclis üyesinin davetine gidecek (3 oyun saati, ilişki bakımı).
7. **Talimat güncelle:** *"Eski Mahalle Dikkati 60'ı geçerse üretimi tamamen durdur."*
8. Duraklatmayı kaldırıp ×2 hızda akşamı izliyor. Davet bitince oyun olay kartıyla kendiliğinden duruyor.

### 21.10 Örnek kriz zinciri (senaryo değil, sistemden doğan)

| Oyun günü | Olan | Mekanik |
|---|---|---|
| 1 | Usta, maaşı piyasanın altında kaldığı için mutsuz; işte içiyor | Sadakat ↓ → verim ↓, zaaf tetiklendi |
| 2 | Bodrumda küçük yangın; komşular duman gördü | Olay İzi +15 → İz 43'ten 58'e |
| 3 | Devriye komşuyla konuşuyor | Tespit olasılığı %16'dan %21'e; zar tuttu → Dosya +8 (tanık) |
| 5 | Dosya 25'i geçti: **Gözetim** | Karakoldaki adamın haber verdi (vermeseydi bilmeyecektin) |
| 5 | **Karar penceresi (1 oyun günü):** üretimi durdur / başka binaya taşı / amire rüşvet / komşuyu ikna et / ustayı gönder | Her seçeneğin tahmin kartı var |
| 6+ | Seçimin sonucu yeni durum yaratır | Örn. ustayı kovdun → küskün eski eleman, sızıntı riski |

Zincirin kökü 1. gündeki küçük bir maaş kararıdır ve oyuncu nedensellik kaydından bunu geri izleyebilir. Oyunun vaat ettiği his budur.

### 21.11 İlk oyun ayı (ilk ≈80 dakika) — öğrenme eğrisi

Sistemler tek tek açılır; öğretici ayrı bir mod değil, vekilin ağzından gelen tavsiyelerdir.

| Oyun günü | Açılan sistem | Olay |
|---|---|---|
| 1–2 | Harita, işletme yönetimi, defter | Meyhaneyi devral; ciro düşük, borç taksiti görünür |
| 3 | Kişiler, ajanda | Vekil seni mahalledeki üç kişiyle tanıştırır |
| 4 | Yasa dışı üretim | Eski bir imalatçı kapıya gelir: "Bodrumun boş duruyor" |
| 5–6 | Dağıtım, kirli para | İlk parti; ilk kirli nakit; harcayamadığını fark edersin |
| 7 | Aklama | Vekil kasaya "fazladan müşteri" yazmayı öğretir |
| 8 | İz ve polis | Devriye memuru meyhaneye uğrar; ilk rüşvet/ilişki kararı |
| 9 | Fırsatlar, rakip | Karşı sokaktaki meyhaneci fiyat kırar |
| 10 | **İlk Hesap Günü** | Maaş, borç taksiti, ilk bilanço. Ay kapanır, hırs seçimi sunulur |

### 21.12 Kalıcılık ve kaybın ağırlığı `[VARSAYIM]`

- **Tek akış, geri yükleme yok.** Zaman geri sarılamaz; kararlar kalıcıdır. Bu, her kararı ağırlaştıran şeydir.
- Buna karşılık oyun **adil olmak zorundadır:** yıkıcı sonuçlar aşamalı gelir, önceden görülebilir ve en az bir çıkış yolu bırakır.
- Düşüş oyunun sonu değildir: hapis, mülk kaybı, sürgün oynanabilir durumlardır. Geri dönüş hikâyesi tasarımın parçasıdır.
- Patron ölümü kalıcıdır; vâris ile devam edilir (Bölüm 9.4).

### 21.13 Uyarılar ve otomatik duraklatma

| Seviye | Örnek | Davranış |
|---|---|---|
| Kritik | Arama emri çıktı, patrona suikast girişimi, adam tutuklandı | Oyunu duraklatır |
| Önemli | Karar penceresi açıldı, fırsat geldi, Hesap Günü yarın | Hızı ×1'e düşürür, uyarı gösterir |
| Bilgi | Sevkiyat tamamlandı, görüşme bitti | Olay akışına düşer |

Hangi olayın oyunu duraklatacağını oyuncu kendisi ayarlar.

---

## 22. Karakter odaklı tasarım

**Yön kararı (14.11.2026):** Oyun, karakter odaklı hanedan stratejisi türünün (ilham: Crusader Kings) yaklaşımını benimser. Bu türden alınan şey mekanik fikirlerdir; dünya, karakterler, arayüz ve içerik özgündür.

Bunun anlamı: **oyuncu bir şirketi değil, bir insanı ve onun ailesini oynar.** Şehir haritası sahnedir; oyun, insanlar arasında geçer. İşletmeler, para ve Dosya hâlâ oradadır ama hepsi birer insan meselesi olarak yaşanır: ciro düşmez, *müdür çalar*; baskın gelmez, *biri konuşur*.

Bu, Bölüm 2'ye altıncı sütunu ekler: **Önce insanlar** — her sistemin girdisi ve çıktısı bir karakterdir.

### 22.1 Zaten uyumlu olanlar ve değişenler

| Konu | Önceki taslak | Bu yönle |
|---|---|---|
| Kişiler | Nitelikli, sadakatli NPC'ler | Aynı; ama oyunun **ana ekranı** artık karakter kartıdır |
| İlişki | Tek sayı (−100…+100) | **Görüş**: nedenleri tek tek listelenen değiştiricilerin toplamı (22.2) |
| Patron | İtibar eksenleri olan boş avatar | Kişiliği, stresi, ailesi, yaşlanması olan tam bir karakter (22.3) |
| Yönetim | Oyuncu her işletmeyi yönetir | Doğrudan yönetim sınırı + kaptanlara devir (22.4) |
| Zaaf ve iyilik borcu | Ayrı mekanikler | **Sır ve Koz** sisteminde birleşir (22.5) |
| Rakiple mücadele | Araç listesi | Uzun soluklu, gizli **Entrikalar** (22.6) |
| Olaylar | Koşullu olasılıklı dünya olayları | Buna ek: kişisel, seçenekli **olay kartları** (22.7) |
| Vâris | Yedek mekanik | Oyunun uzun vadeli omurgası: **Aile** (22.8) |
| Aileler arası düzen | İkili diplomasi | **Komisyon**: kuralları ve oylaması olan üst meclis (22.9) |

### 22.2 Görüş

Her karakterin diğer her önemli karakter hakkında bir Görüşü vardır. Görüş bir sayı değil, bir **dökümdür**:

```
Kemal'in senin hakkındaki görüşü: +34
  +15  Maaşı piyasanın üstünde
  +20  Kardeşini hapisten çıkardın          (yılda −2 söner)
  +10  Kişilik uyumu (ikiniz de Temkinli)
  −15  Terfi beklentisi karşılanmadı
  −8   Arkadaşı Rıza'yı harcadın            (yılda −4 söner)
  +12  Korku
```

- Bölüm 9.3'teki Sadakat, astların patrona Görüşünün özel hâlidir; formül aynı kalır, artık döküm olarak gösterilir.
- Döküm oyuncuya ancak o kişiyi tanıdığı kadar görünür (Bölüm 11): az tanıdığın birinin satırları "?" ile gizlidir.
- Her eylem tahmin kartında kimin Görüşünü ne kadar değiştireceğini gösterir. "Her şey sayıdır" sütununun insan ilişkilerindeki karşılığı budur.

### 22.3 Patron bir karakterdir

- **Kişilik özellikleri (3–4 adet):** Temkinli, Öfkeli, Cömert, Açgözlü, Sözünün Eri, Kindar, Merhametli, Gözüpek… Özellikler formüllere girer ve bazı seçenekleri açar/kapatır.
- **Stres (0–100):** Kişiliğine aykırı davranmak (Merhametli bir patronun infaz emri vermesi), kayıplar, soruşturma baskısı stres üretir. 33/66/100 eşiklerinde kriz olayı: yeni bir zaaf (içki, kumar), sağlık sorunu, öfke patlaması. Stres; aileyle vakit, tatil, zaafına teslim olmakla düşer — hepsi patronun zamanını yer.
- **Odak:** Patron bir uzmanlık yolu seçer (Tüccar, Entrikacı, Siyasetçi, Sokak Adamı). Odak, zamanla o alanda yetenek ve özel eylemler açar; istenirse değiştirilir ama birikim sıfırlanır.
- **Yaşlanma ve sağlık:** Patron her oyun ayında 1 yaş alır (Bölüm 22.8); sağlık düşer; ölüm doğal da gelebilir.

Sonuç: aynı durumda iki farklı patron farklı oynanır. Oyuncu "en iyi hamleyi" değil, **bu adamın yapacağı hamleyi** tartar.

### 22.4 Hiyerarşi: doğrudan yönetim ve kaptanlar

```
Patron
 ├─ Danışman (vekil)
 ├─ Kaptan — Liman ekibi ── adamlar, işletmeler, operasyonlar
 ├─ Kaptan — Çarşı ekibi ── …
 └─ Doğrudan yönetilen varlıklar (sınırlı)
```

- **Doğrudan yönetim sınırı:** Patron bizzat `3 + Ticaret/20` varlık yönetebilir (tipik 4–8). Sınırı aşan her varlık hepsinin verimini düşürür ve İz üretimini artırır. Senin anlattığın kesit (4 işyeri + imalathane) tam bu sınırdadır: **oyunun ilk perdesi** orada biter.
- **Kaptan:** Bir bölgeyi ve içindeki varlıkları kendi adına yönetir; kazancın belirlenen **payını** yukarı gönderir. Patron kaptanın işine karışmaz; yalnızca özet rapor görür (ve raporun doğruluğunu sorgulayabilir).
- **Kaptanın ayarları:** pay oranı, özerklik (kendi başına genişleyebilir mi, şiddet kullanabilir mi), bölge sınırı.
- **Tampon:** Kaptan, patron ile suç arasındaki mesafedir. Kaptanın ekibindeki bir baskın patronun Dosyasına ancak kaptan konuşursa ulaşır. Sadık kaptan = kalkan; küskün kaptan = itirafçı adayı.
- **Hizipler:** Hoşnutsuz kaptanlar birleşir ve talep sunar: daha düşük pay, daha fazla özerklik, vârisin değişmesi, patronun çekilmesi. Hizbin gücü (adam + para + nüfuz) patronunkine yaklaşınca **ültimatom** gelir: kabul, pazarlık veya iç savaş.

Büyüdükçe oyun işletme yönetiminden insan yönetimine kayar. Kapsam sorununu da çözer: 40 işletmeyi oyuncu değil, 5 kaptan yönetir.

### 22.5 Sırlar ve Koz

- Her karakterin **sırları** olabilir: zimmet, yasak ilişki, kumar borcu, işlenmiş bir suç, gizli sadakat, muhbirlik. Patronun da sırları vardır — en büyüğü yasa dışı işleridir.
- Bir sırrı öğrenen kişi **Koz** kazanır:

| Koz | Kaynak | Kullanım |
|---|---|---|
| **Zayıf koz** | İyilik borcu, küçük sır | Bir kez kullanılır; bir teklifin kabul olasılığını büyük ölçüde artırır |
| **Güçlü koz** | Hapse/ölüme götürecek sır | Kullanıldıkça tükenmez; kişi reddedemez — ama Görüşü çöker ve kurtulmak için entrika kurabilir |

- Koz; rüşvetin yetmediği yerde iş görür (dürüst savcı para almaz ama oğlunun sırrı vardır).
- Sır ifşa edilebilir: hedefin itibarı/özgürlüğü yanar, koz da biter. Tehdit, kullanılmadığı sürece değerlidir.
- Bölüm 10.2'deki iyilik borcu = zayıf koz. Bölüm 9.1'deki zaaflar = sır kaynağı.

### 22.6 Entrikalar

Tek hamlede bitmeyen, gizli yürüyen, zamanla olgunlaşan planlar. Oyuncu da kurar, oyuncuya da kurulur; YZ karakterler birbirine de kurar.

**Türler:** suikast · darbe (bir kaptanı/patronu devirme) · adam ayartma · sır avı · şantaj · iftira/karalama · kaçırma · sahte delil yerleştirme · dostluk kurma · nişan/evlilik ayarlama.

```
Güç      = Kurucunun Zekâsı + ajanların katkısı + hedefe yakın ajan bonusu
Direnç   = Hedefin güvenliği + korumalarının sadakati + karşı istihbaratı
Günlük ilerleme = max(0,5 ; 2 + (Güç − Direnç)/10)          # 100'e ulaşınca uygulanır
Günlük keşif    = %0,5 × ajan sayısı × (1 − ortalama Ketumluk/100) × hedefin karşı istihbarat çarpanı
```

- **Ajanlar:** Hedefin çevresinden kişiler entrikaya katılmaya ikna edilir (görüş, rüşvet veya kozla). Her ajan gücü artırır ama keşif riskini de.
- İlerleme 100 olunca **uygulama zarı** atılır (Bölüm 14); başarı ve gizlilik ayrı sonuçlanır: başarılı ama ifşa olmuş bir suikast mümkündür.
- **Savunma:** Oyuncu kendisine kurulan entrikayı ancak karşı istihbaratı yakalarsa görür: *"Biri etrafındakilere seninle ilgili sorular soruyor (kaynak: şoförün)."*
- Aynı anda yürütülebilecek entrika sayısı sınırlıdır (1 düşmanca + 1 dostane; Entrikacı odağıyla artar).

Entrikalar oyun günleri ve ayları içinde olgunlaşır; arka planda yürür, olgunlaşınca oyunu durdurur.

### 22.7 Olay kartları

Dünya olaylarına (Bölüm 13) ek olarak, **kişisel** ve seçenekli olaylar:

> **Yeğenin kapında.** Kız kardeşinin oğlu Selim iş istiyor. Hevesli ama eli ağır, dili gevşek.
> - *Yanıma alırım.* — Kız kardeşin +20 · Selim ekibe girer (Ketumluk 25) · Kemal −5 ("torpil")
> - *Meyhanede garsonluk versin.* — Kız kardeşin +5 · Selim −10 (Hırslı)
> - *Bu işler ona göre değil.* — Kız kardeşin −15 · **Stres +10** (Cömert'sin)

- Olaylar senaryo değildir: ön koşulları (bir yeğenin var, 16 yaşını geçti, işsiz) ve olasılıkları durumdan gelir.
- Seçenekler patronun kişiliğine, odağına, elindeki kozlara ve paraya göre açılır/kapanır.
- Her seçenek sonuçlarını sayıyla gösterir; belirsiz sonuçlar olasılıkla.
- Karar penceresi ve vekil kuralı (Bölüm 23.4) olay kartları için de geçerlidir: pencere dolarsa vekil seçer.

### 22.8 Aile: kan bağı ve yemin bağı

- **Aile ağacı:** eş, çocuklar, kardeşler, yeğenler, kayınlar. Akrabalar da tam birer karakterdir.
- **Kan bağı:** Akrabalar Görüşte kalıcı bonus alır ve ihanet eşiği yüksektir; ama yetenekleri neyse odur. Yeteneksiz bir oğul mu, yetenekli bir yabancı mı — türün klasik ikilemi.
- **Evlilik:** Aileler arası ittifak, ateşkes güvencesi, siyasi/ticari bir aileye açılan kapı. Evlenen kişinin kendi görüşü ve sırları vardır.
- **Yemin bağı:** Kan bağı olmayanların aileye alınması (yemin töreni). Yeminli üye kaptan olabilir; yemini bozmak tüm ailelerde itibar yakar.
- **Vâris:** Patron vâris belirler. Kaptanların vârise Görüşü düşükse, devir anında hizip savaşı çıkar. Vârisi önceden yetiştirmek (görev vermek, tanıştırmak, itibarını kurmak) uzun vadeli bir projedir.
- **Aile dokunulmazlığı:** Suça karışmamış aile bireylerine dokunmak yazısız kuralı çiğner (22.9). Çiğneyen kazanır ama herkesin düşmanı olur.

**Yaşam ölçeği:** İnsanlar takvimden hızlı yaşlanır. **Her karakter her Hesap Günü'nde 1 yaş alır** (1 oyun ayı = 1 yaş). Takvim, mevsimler ve ekonomi kendi hızında akar; yalnızca insan ömrü sıkıştırılır.

| Yaşam olayı | Yaş karşılığı | ×1 hızda | ×3 hızda |
|---|---|---|---|
| Hamilelik | — | 80 dk | ≈27 dk |
| Çocuğun işe alınabilir olması | 16 yaş | ≈21 saat | ≈7 saat |
| Bir patronun tipik saltanatı | 25–30 yıl | 33–40 saat | 11–13 saat |
| Yetişkin ömrü (20 → 70) | 50 yıl | ≈67 saat | ≈22 saat |

- Hapis cezaları, yaşlanma, sağlık ve görüş değiştiricilerinin "yıllık" sönümü **yaş-yılı** ile ölçülür (5 yıl hapis = 5 oyun ayı).
- Takvim yılı şehrin saatidir: mevsimler, ekonomi, seçimler. Yaş-yılı insanların saatidir. İkisi bilinçli olarak ayrıdır; arayüzde yaş her zaman sayı olarak, tarih her zaman takvim olarak gösterilir.
- Patron değişimi yine de çoğunlukla **şiddet, hapis ve çekilmeden** gelir; yaşlılık yalnızca üst sınırı koyar.
- Patron hapisteyken vâris "naip" olarak oynanır; devir kalıcı olmak zorunda değildir.
- Oyun başında aile hazır gelir (kardeşler, yeğenler, bir-iki çocuk) ki ilk saatler boş geçmesin.
- Nesiller hâlâ yavaş gelirse ayar düğmesi bellidir: ayda 2 yaş (çocuk normal hızda ≈11 saatte büyür).

### 22.9 Komisyon

Şehirdeki ailelerin patronlarından oluşan gayriresmî meclis.

- **Yazısız kurallar:** polis/savcı/gazeteci öldürülmez · aile bireylerine dokunulmaz · görüşme masasında silah çekilmez · başka ailenin yeminli adamı izinsiz alınmaz. Kurallar oylamayla değişebilir.
- **Kural çiğneme:** Kanıtlanırsa Komisyon yaptırım oylar: tazminat, bölge kaybı, "açık av" ilanı.
- **Oylama:** Her patronun oyu; ağırlığı ailesinin gücü ve Saygısıyla orantılı. Oylar görüş, koz ve pazarlıkla kazanılır.
- **Gündem:** bölge anlaşmazlıkları, savaş izni, yeni ailenin tanınması, Komisyon başkanlığı.
- **Tanınma:** Oyuncu başta Komisyon'da yoktur; "tanınmış aile" olmak orta oyunun büyük hedefidir. Başkanlık geç oyunun hedefidir.

### 22.10 Arayüze etkisi

- Her isim tıklanabilir ve **karakter kartını** açar: portre, yaş, özellikler, yetenekler, aile, görüş dökümü, bilinen sırlar, hakkındaki entrikalar, ona yapılabilecek eylemler.
- Harita katmanlarına **Kişiler** katmanı eklenir: kim nerede, kim kimin adamı.
- **Aile ağacı** ve **hiyerarşi şeması** ayrı ekranlardır.
- Olay kartları ekranın ortasında açılır; bekleyenler üst barda birikir.

### 22.11 Yön değişikliğinin MVP'ye etkisi

Bölüm 18.1'deki dikey kesite eklenenler: Görüş dökümü, patron kişiliği ve stres, 10–15 olay kartı, sır/koz (yalnızca zayıf koz), 2 entrika türü (sır avı, adam ayartma), hazır gelen küçük bir aile ağacı.

Sonraki aşamaya kalanlar: kaptanlar ve hizipler (MVP ölçeği doğrudan yönetim sınırının altında), evlilik, tam entrika listesi, Komisyon, vâris devri.

---

## 23. Saat akarken: olaylar ve yaşlar

Bölüm 3'ün ayrıntısıdır: saat akarken yaşların ve olayların nasıl işlendiğini tarif eder.

### 23.1 İki saat

| Saat | Birimi | Neyi sürer | Ne zaman hesaplanır |
|---|---|---|---|
| **Şehir saati** | dakika → saat → gün | Üretim, satış, sevkiyat, görüşmeler, İz, Dosya, entrika ilerlemesi | Sürekli (saatlik ve günlük tikler) |
| **Yaşam saati** | yaş-yılı (= 1 oyun ayı) | Yaşlanma, sağlık, ölüm, doğum, çocukların büyümesi, hapis süresi, uzun vadeli görüş sönümü | Yalnızca Hesap Günü'nde, toplu |

İnsan hayatına dair her şey ayda bir, tek bir anda işlenir. Böylece yaşam olayları güne yayılıp kaybolmaz; her ay sonunda **"Yıl Dönümü"** adlı tek bir özet olarak gelir.

### 23.2 Hesap Günü'nün işleyiş sırası

Hesap Günü oyunu kendiliğinden duraklatır ve sırayla şunları işler:

1. **Mali kapanış:** maaş, kira, vergi, borç, kaptan payları, bilanço.
2. **Yaş:** herkes +1.
3. **Sağlık ve ölüm zarı** (aşağıda).
4. **Çocuklar:** 6, 12 ve 16 yaşlarında kişilik özelliği/yetenek kazanımı; 16'da işe alınabilir olur.
5. **Doğumlar ve gebelikler.**
6. **Yıllık sönümler:** eski iyilikler, eski kırgınlıklar, eski kanıtlar.
7. **Yıl Dönümü raporu:** *"41 yaşındasın. Kızın Leyla 12 oldu: 'Zeki' özelliğini kazandı. Amcan Hasan hastalandı."*

Doğal ölüm olasılığı (yaş-yılı başına):

```
P(ölüm) = %0,2 × 2^((Yaş − 30) / 8) × SağlıkÇarpanı        # sağlıklı 1,0 · hasta 2–4
```

| Yaş | 30 | 46 | 54 | 62 | 70 | 78 | 86 |
|---|---|---|---|---|---|---|---|
| Yıllık olasılık | %0,2 | %0,8 | %1,6 | %3,2 | %6,4 | %12,8 | %25,6 |

Ölüm ani gelmez: önce "Hasta" durumu (çarpan artar) ve en az 1 yaş-yılı uyarı süresi. Patronun hastalığı, vâris hazırlığı için görünür bir geri sayımdır.

### 23.3 Olay temposu

| Olay türü | Hedef sıklık | Normal hızda |
|---|---|---|
| Akış haberi (karar gerektirmez) | Oyun günü başına 3–6 | 1–3 dakikada bir |
| Küçük karar | Oyun günü başına ≈1 | ≈8 dakikada bir |
| Orta karar | Oyun ayı başına 4–6 | 15–20 dakikada bir |
| Büyük karar | Oyun ayı başına 0–2 | Saatte bir veya daha seyrek |

- Olay olasılıkları "yaş-yılı başına" tanımlanır ve günlük zara çevrilir: `p_gün = 1 − (1 − p_yıl)^(1/10)`.
- Bir **olay bütçesi** aynı anda açık karar sayısını sınırlar (en fazla 5); bütçe doluysa yeni olaylar ertelenir. Oyuncu ne boğulur ne boş kalır.
- Olaylar senaryo değil, durumdan doğan koşullu olasılıklardır (Bölüm 13 ve 22.7).

**Olay ölçeği: saatler ve günler.** Ülke yöneten strateji oyunlarında olaylar aylara ve yıllara yayılır; burada sahne bir şehir, birim bir insan olduğu için olaylar **saatler ve günler** içinde yaşanır. Bu, oyunun kendine özgü temposudur:

| Ölçek | Süre (oyun zamanı) | Örnek |
|---|---|---|
| **Sahne** | 1–6 saat | Bir görüşme, bir sevkiyat, bir baskın, bir gece |
| **Mesele** | 1–5 gün | Küskün bir adam, fiyat kıran rakip, peşine düşen bir muhabir |
| **Dönem** | 1–3 ay | Bir soruşturma, bir entrika, bir seçim kampanyası, bir aile savaşı |
| **Hayat** | yıllar | Yükseliş, evlilik, vâris, miras |

- **Olay zincirleri:** Bir sahne bir sonrakini tetikler ve hepsi aynı gün içinde olabilir. Örnek bir gece: 22:00 sevkiyat yola çıkar → 23:10 devriye kamyonu durdurur (karar: rüşvet / kaç / teslim ol) → 23:40 sürücü karakolda (karar: avukat gönder / amiri ara / bekle) → 03:00 sürücü ya çıkar ya konuşur. ×1 hızda beş dakikalık, üç kararlı bir gerilim.
- Zincir içindeki kararlar "Acil" sınıfındadır (Bölüm 23.4): oyun durur, karar o an verilir.
- Gergin bir sahne başladığında oyun kendiliğinden ×1'e düşer; sahne bitince önceki hıza döner.
- Sonuç: sakin günler ×3'te hızla geçer, olaylı bir gece ×1'de dakika dakika yaşanır. Tempo sabit değil, **nabız gibidir**.

### 23.4 Karar pencereleri

Oyuncu istediği an duraklatabildiği için pencereler gerçek zaman baskısı değil, **oyun dünyasının sabrıdır**: karşı taraf ne kadar bekler?

| Sınıf | Örnek | Pencere (oyun zamanı) | Süre dolarsa |
|---|---|---|---|
| **Küçük** | Müdür zam istiyor, devriye bahşiş bekliyor | 1 gün | Vekil karar verir |
| **Orta** | Satılık dükkân, kaptanın şikâyeti, rüşvet teklifi | 4 gün | Vekil karar verir veya fırsat kaçar |
| **Büyük** | Evlilik teklifi, ültimatom, savaş ilanı, vâris değişimi, Komisyon oyu | 10 gün | Karşı taraf sessizliği cevap sayar (çoğunlukla ret) |
| **Acil** | Baskın şu an, suikast girişimi | Yok | Oyun duraklar; oyuncu o an karar verir |

- Olay kartı açıldığında oyun durur. Oyuncu hemen cevaplayabilir ya da kartı **kenara alıp** oyunu sürdürebilir; pencere işlemeye devam eder.
- Bekletmenin bedeli vardır: geç verilen cevap küçük bir görüş kaybı getirir.
- Bekletmenin faydası da vardır: araya bir görüşme, bir istihbarat, bir koz sığdırıp daha iyi koşullarda cevap verebilirsin.

### 23.5 Vekil nasıl karar verir

- Vekil, seçenekleri **kendi** yetenek ve kişiliğiyle değerlendirir; Zekâsı yüksekse iyi seçer, Açgözlüyse kendine yontar.
- Oyuncu hangi sınıftaki kararların vekile **devredildiğini** seçer (ör. "küçük kararların hepsi vekilde"). Devredilen kararlar kart açmaz, olay akışına gerekçesiyle düşer.
- Oyuncu vekile bir **duruş** verir: *Temkinli* · *Dengeli* · *Fırsatçı*.
- Vekil geri alınamaz seçeneklerden kaçınır: kimseyi öldürtmez, mülk satmaz, evlilik onaylamaz, savaş açmaz. Bunları yalnızca önceden yazılmış bir talimat varsa yapar.
- Son 1 oyun günü içinde verilmiş ve henüz sonuçlanmamış vekil kararları **geri çevrilebilir**.

### 23.6 Hızlı akışta güvenlik

- ×2 ve ×3 hızda, orta ve üstü bir olay olduğunda oyun kendiliğinden ×1'e düşer veya durur (ayarlanabilir).
- Dosya bir aşama atladığında, bir karakter öldüğünde, bir entrika keşfedildiğinde oyun her hızda durur.
- Hiçbir yıkıcı sonuç, oyuncu en az bir kez durup karar verme fırsatı bulmadan gerçekleşmez.

### 23.7 Oturum sınırları

- Çıkışta oyun kaydedilir; dünya o anda donar.
- Açılışta **"Kaldığın Yer"** özeti gösterilir, çünkü oyuncu günler sonra dönmüş ve bağlamı unutmuş olabilir: tarih ve saat, açık kararlar ve kalan süreleri, patronun ve adamların kuyruktaki işleri, son 3 oyun gününün öne çıkan olayları, yürüyen entrikalar.
- Oyun duraklatılmış açılır.
