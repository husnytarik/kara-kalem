# Kara Kalem — Olay Kataloğu

Amaç: olaylar **oyun süresine değil, oyuncunun durumuna** göre gelsin. Aileyi büyütmüş biri hâlâ "kaldırımda cüzdan" bulmasın; Don olmuş birine "tefecinin adamı" gelmesin, yerine şehri ilgilendiren olaylar gelsin. Güçlü bir aile, güçsüzün yardımına ihtiyaç duymasın.

Mevcut sistem (`kartlar.gd`): 17 kart, 5 seviye kapısı (Sokak çocuğu / Haraççı / Kaptan / Underboss / Don), ağırlık + bekleme + tek seferlik. Bu belge onu **genişletir**: kapıların yanına yumuşak çarpanlar ekler.

---

## 1. Tetikleme motoru

### 1.1 Formül
```
ağırlık = taban × evre_uyumu × yol_uyumu × beceri × dünya × aile_bağlamı × tazelik
```
Her gün (veya her olay aralığında) uygun olaylar toplanır, ağırlıklı çekilir. Çekim olasılığı `ritim`'e bağlıdır (varsayılan %75, yoğun dönemde düşer).

| Çarpan | Ne ölçer | Aralık |
|---|---|---|
| `evre_uyumu` | Olayın ait olduğu seviye ile oyuncunun seviyesi. Tam evre = 1.0; bir alt = 0.35; iki alt = 0.1; üstü = **0 (kapalı)** | 0–1 |
| `yol_uyumu` | Oyuncunun yol puanı (Yasal/Gölge/Korku/Kulis) ve hayat tipi. Olay hangi yola hitap ediyorsa o yol güçlüyse artar | 0.5–2.0 |
| `beceri` | İlgili statlar (zeka, güç, karizma vb.) ve beceri ağacı. Beceri olayı **sıklaştırır** ya da **kolaylaştırır** (aşağıya bak) | 0.6–1.8 |
| `dünya` | Diğer NPC ailelerin/polisin/şehrin anlık durumu (bkz. 1.3) | 0–3 |
| `aile_bağlamı` | Eş, çocuk, yaş, miras durumu | 0–2.5 |
| `tazelik` | Aynı olay yakın zamanda geldiyse düşer; seçimin sonucu "beklemeyi" gerektiriyorsa sıfırlanır | 0–1 |

### 1.2 Sert kapı mı, yumuşak çarpan mı?
- **Sert kapı (olay hiç gelmez):** evre dışı, tek seferlik zaten yaşandı, ön koşul yok (ör. eş yokken "eşin hastalandı").
- **Yumuşak çarpan:** geri kalan her şey. Böylece oyun "kapı kapı ilerleyen kilit sistemi" gibi değil, **durumuna uyan olaylara doğru yamuk yamuk akan** bir yapı gibi hissedilir.

### 1.3 Dünya (NPC) filtresi — kimin neye hakkı var
Her NPC ailenin **güç oranı** `G = ailenin gücü / oyuncunun gücü` (adam sayısı + mahalle + servet + nüfuz).

| Olay türü | Kural |
|---|---|
| **Yardım isteyen** (borç, himaye, ittifak talebi) | `G ≥ 1.5` ise **olay hiç çıkmaz** (güçlü olan yardım istemez, domine eder). `G < 0.5` ise ×2 (zayıf yardım ister). |
| **Tehdit / haraç dayatan** | `G ≥ 1.2` ise ×(G). `G < 0.4` ise ×0.2 (zayıf sana dayatamaz). |
| **Ortaklık / ittifak teklifi** | `0.6 ≤ G ≤ 1.4` ise ×2 (eşitler anlaşır). |
| **Teslim olma / bağlılık** | `G < 0.3` ve oyuncunun korkusu ≥ 40 ise çıkar. |
| **Savaş ilanı** | İki aile arasındaki gerginlik eşiğe yaklaştıysa, `gerginlik.gd` ile bağlı. |
| **Polis olayı** | O mahallenin polis yozlaşması (rüşvet seviyesi) düşükse ×1.5; yüksekse ×0.5. |
| **Federal olay** | Federal ilgi ≥ 40 ve servet ≥ 40 (ün ekseni) olmadan çıkmaz. |

Ek: **olay sahibi NPC isimli olur.** "Bir esnaf" yerine "Bay Kowalski (fırıncı, sana 3 aydır borçlu)". NPC'nin ilişkisi (dost/düşman) ağırlığı etkiler: seni sevenler yardım ister, nefret edenler kötü olay getirir.

### 1.4 Beceri ne yapar
Üç farklı etki, aynı olayda birlikte olabilir:
1. **Sıklık:** Becerin o türe yatkınsa o tür olay çok gelir (kumarbaz olay çekersin, kumarcılar seni bulur).
2. **Seçenek açar:** Bazı seçenekler beceri ister (zeka ≥ 8 → "hesapta açık yakala", karizma ≥ 8 → "ikna et").
3. **Başarı oranı:** Seçenek riskli ise zar beceriyle kayar.

### 1.5 Tazelik ve "yaşlanma"
- Her olayın `maks_evre`'si var. Oyuncu o evreyi geçince olay **emekli olur** (ya da güçlü versiyonuyla yer değiştirir: *cüzdan → şans eseri servet bulma → vasiyetnamede sürpriz*).
- Büyüme olayları: aynı tema, her evrede daha büyük bahis (**ölçekleme zinciri**): Koruma parası → Rakip esnaf → Mahalle savaşı → Şehir savaşı.
- Parasal etkiler seviyeye göre ölçeklenir (`_m()` zaten var): sokakta $50, tepede $5.000.

### 1.6 Olay biçimi
```
ID — Başlık  [evre · tür]
 Koşul: sert kapılar
 Ağırlık: taban + çarpan notları
 Seçenek → sonuç (etkiler)
```
Etki kısaltmaları: **₺**=para (temiz/kirli), **K**=korku, **S**=sevgi, **Sy**=saygı, **D**=dikkat (polis dosyası), **F**=federal ilgi, **N**=nüfuz (polis/yargıç/siyasi), **Sd**=adam sadakati, **An**=Aile Namı, **Y**=yol puanı, **St**=stres, **İl**=ilişki (NPC), **Zr**=zar (başarı şansı).

---

## 2. SOKAK ÇOCUĞU (Evre 0)
Sıfır adam, sıfır mahalle, az para. Küçük, kişisel olaylar. Bu evreyi geçince çoğu emekli olur.

**S01 — Kaldırımda cüzdan** [0–1 · şans]
- Koşul: evre ≤ 1. Ağırlık: 9. Şanslıysan ×1.3.
- A) Sahibine ver → Sy +2, S +2, ₺ −0, İl(esnaf) +; B) Paraları al, cüzdanı at → ₺ +30–80, Y.golge +1; C) Cüzdanı sahibine "bulma ücreti" karşılığı ver → ₺ +15, K +1.

**S02 — Pazarcı teklifi** [0–1 · iş]
- Koşul: pazarcı mahallede. Ağırlık: 9.
- A) Kasaya yardım et (gündelik) → ₺ +20, St +3; B) Haraç iste → ₺ +40, K +3, İl −; C) Gizlice mal çal → ₺ +60 (Zr: el çabukluğu), başarısızsa D +4.

**S03 — Dolan kapıda** [0–2 · polis]
- Koşul: D ≥ 20. Ağırlık: 10.
- A) Rüşvet ver → ₺ −, N(polis) +2; B) Kaç → Zr(hız), başarısızsa St +, D +; C) Direnç göster → K +, D +5; D) Mahalleli tanık çıkar → Sy +, S +.

**S04 — Aç çocuk** [0–1 · vicdan]
- Koşul: S ≥ 0. Ağırlık: 6.
- A) Ekmek ver → ₺ −5, S +3, Y.kanun +1; B) Görmezden gel → St +2; C) Onu "gözcü" yap → ileride bir sadık kişi (ilk adam adayı), Sy −1.

**S05 — Kavga çağrısı** [0–1 · güç]
- Koşul: güç ≥ 4. Ağırlık: 7 (güç yüksekse ×1.4).
- A) Kabul → Zr(güç), kazan: Sy +4, K +3; kaybet: yara, ₺ −; B) Reddet → Sy −1; C) Hakem ol → S +2.

**S06 — Tefecinin adamı** [0–2 · borç]
- Koşul: borç > 0. Ağırlık: 8.
- A) Öde → ₺ −, Sy +1; B) Süre iste → İl(tefeci) −, faiz ×; C) Direnç → K +3, ama yara/ölüm riski; D) Dilbazlık (karizma ≥ 6) → süre + indirim.

**S07 — Meyhane dedikodusu** [0–2 · bilgi]
- Ağırlık: 8.
- A) Dinle → ipucu açılır (bir rakip sevkiyatının yeri); B) Dedikodu uydur → S −, K +; C) Kâğıt oyununa katıl → kumar (şansa bağlı).

**S08 — İlk iş teklifi** [0 · yol seçimi]
- Koşul: hiç işletmen yok. Ağırlık: 12 (tek seferlik).
- A) Kasaba çıraklık → Y.kanun +3 (iş adamı yolu açılır); B) Kaçak mal taşı → Y.golge +3, D +3; C) Esnaftan "koruma" iste → Y.korku +3, K +4.

**S09 — Mahalle şenliği** [0–3 · topluluk]
- Ağırlık: 6.
- A) Cömertçe harca → ₺ −, S +5, Sy +2; B) Sadece izle → hiçbir şey; C) Kalabalıkta cep tara → ₺ +50, D +2, S −2.

**S10 — Gece yarısı kapı çalındı** [0–1 · gizem]
- Ağırlık: 3. Nadir.
- Yaralı bir adam sığınma ister (ileride kim olduğu ortaya çıkar: rakip bir kaptan, polis muhbiri ya da kaçak). Seç: sakla / ihbar et / geri çevir. Sonuç haftalar sonra belli olur (zincir Z02).

---

## 3. HARAÇÇI (Evre 1)
Birkaç adam, birkaç esnaf haracı. İlk gerçek büyüme.

**H01 — Esnaf şikâyeti** [1–2]
- Koşul: haraçlı veya sahip olunan iş var. Ağırlık: 8.
- A) Sert baskı → K +4, ₺ +, S −3; B) Gizlice halla → Y.golge +, D −; C) Yardım et → S +4, ₺ −; D) Çek-yap → Zr(karizma).

**H02 — Adamlar pay istiyor** [1–3 · sadakat]
- Koşul: adam ≥ 2. Ağırlık: 8, sadakat < 50 ise ×1.5.
- A) Cömertçe ver → Sd +8, ₺ −; B) Sert → K +3, Sd −6; C) Dilbazlık → Sd +3 (Zr); D) Reddet → Sd −10, darbe riski.

**H03 — İlk muhbir** [1–3 · polis]
- Koşul: D ≥ 15. Ağırlık: 7.
- A) Ağı kullan → bilgi, D −; B) Muhbirin ağzını kapat → K +, Sy −; C) Karşı yem → polisi yanlış yöne çek (zeka ≥ 7).

**H04 — Gazeteci** [1–3 · itibar]
- Koşul: D ≥ 25 veya yol seçildi. Ağırlık: 6.
- A) Röportaj ver → S/Sy ± (karizmaya göre); B) Rüşvet → ₺ −, N(siyasi) +1; C) Tehdit et → K +, D +5; D) Bilgi sat → ₺ +.

**H05 — Koruma parası** [1–4 · dış baskı]
- Koşul: dükkân sahibi. Ağırlık: 12. **Dünya:** isteyen ailenin `G ≥ 1.2`.
- A) Öde → ₺ −, İl(aile) +, rahat; B) Reddet → gerginlik +, adam kaybı riski; C) Ortak ol → pay ver, ittifağa yol açar; D) Sert karşılık → K +, savaş riski.

**H06 — Ruhsat ve arama** [1–4 · polis]
- Koşul: dükkân sahibi. Ağırlık: 10. Polis yozlaşması düşükse ×1.5.
- A) Evrakı düzelt → ₺ −, D −; B) Rüşvet → N(polis) +, D −; C) Direnç → D +, ceza; D) Avukat (varsa) → dava düşer.

**H07 — Rakip esnaf** [1–3 · rekabet]
- Koşul: dükkân sahibi. Ağırlık: 9.
- A) Fiyat kır → ₺ −, rakip çöker; B) Rakibi ez → K +, Sy −; C) Ortaklık → ₺ +, S +; D) Çalışanını kır → İl −.

**H08 — Küçük soygun teklifi** [1–2 · risk]
- Koşul: Y.golge ≥ 3. Ağırlık: 6.
- A) Katıl → ₺ +200–500 (Zr: zeka/güç), başarısızsa D +10, hapis; B) Planı düzelt → komisyon + risk azalır; C) Reddet → fırsat gider.

**H09 — Tavernada kumar** [1–2 · kumar]
- Ağırlık: 5. Kumar sevenlerde ×1.5.
- A) Küçük bahis → ₺ ±50; B) Büyük bahis → ₺ ±300; C) Hile (zeka ≥ 8) → +₺, yakalanırsan K +, hayatın tehlikede.

**H10 — Tanıdık gelir** [1–2 · aile]
- Koşul: hiç evlenmedin. Ağırlık: 5.
- A) Tanış → Evlenme adayı doğar (kisiler.gd); B) Uzak dur → St −.

**H11 — Hastalık** [1–4 · sağlık]
- Ağırlık: 4, stres yüksekse ×2.
- A) Doktor → ₺ −; B) Geçir → sağlık −; C) Kadının/erkeğin biri (şifacı) → S +.

**H12 — Sahte para** [1–2 · gölge]
- Koşul: Y.golge ≥ 4. Ağırlık: 4.
- A) Kullan → ₺ +, D +6 (sahteler izlenir); B) Sat → ₺ +, risk; C) Polise ver → N(polis) +, Y.kanun +.

---

## 4. KAPTAN (Evre 2 — 1 mahalle)
Mahallen var. Artık "kapı" sen sin, sorunlar mahalle ölçeğinde.

**K01 — Belediye ihalesi** [2–4 · iş]
- Koşul: ₺ temiz ≥ 60, sicil temiz. Ağırlık: 7.
- A) Dürüst teklif → Zr(zeka), kazan: ₺ +, Sy +; B) Rüşvetle kazan → ₺ +, N(siyasi) +, D +; C) Rakibi çek → K +.

**K02 — Mahalle toplantısı** [2–3 · topluluk]
- Koşul: mahalle sahibi. Ağırlık: 7.
- A) Dinle → S +, kararı topluluğa bırak; B) Kendi kararın → K +; C) Papaz/imam ile → inanç bonusu.

**K03 — Adamlar kıskanç** [2–3 · sadakat]
- Koşul: adam ≥ 4. Ağırlık: 6.
- A) Terfi ver → Sd +, bir "kaptan yardımcısı" açılır; B) Bölüştür → Sd ±; C) Cezalandır → K +.

**K04 — Rakip aile devriyesi** [2–3 · savaş]
- Koşul: komşu aile `G ≥ 0.6`. Ağırlık: 8.
- A) Uyar → gerginlik −; B) Çatış → gerginlik +, adam kaybı; C) Müzakere → ittifak şansı.

**K05 — Esnaf birliği** [2–3 · siyaset]
- Koşul: 3+ esnaf. Ağırlık: 5.
- A) Başkan ol → S +, Sy +, ₺ −; B) Birliği çözdür → K +; C) Haraç al → ₺ +, S −.

**K06 — Kaçak sevkiyat** [2–3 · iş]
- Koşul: Y.golge ≥ 5. Ağırlık: 7.
- A) Kendi taşı → ₺ +, risk; B) Rakibe sat → ₺ +, il −; C) Polise haber ver → N(polis) +, Y.kanun +.

**K07 — Kasap kızı** [2–3 · aile]
- Koşul: evlilik yok veya boşandın. Ağırlık: 4.
- Evlilik ve ittifak seçeneği → eşin bir aileden gelir (An +).

**K08 — Yangın** [2–3 · felaket]
- Koşul: işletme sahibi. Ağırlık: 4. Yangın sigortası ve itfaiye N varsa ×0.5.
- A) Söndür → ₺ −, Sy +; B) Rakibin işi mi? Araştır → zincir Z03; C) Sigorta → ₺ +.

**K09 — Papaz ziyaretçi** [2–3 · inanç]
- Koşul: inanç ≥ orta. Ağırlık: 4.
- A) Bağış → Sy +; B) Reddet → inanç −; C) Papaz seni çok bilir → bir sır tutar (şantaj aracı olur).

**K10 — Esnaf kızı kaçtı** [2–3 · sosyal]
- Koşul: S ≥ 10. Ağırlık: 3.
- A) Bul, ailesine götür → S +, Sy +; B) Umursama → hiçbir şey; C) Kaçıran kişiyi ez → K +.

**K11 — Yeni gelen göçmenler** [2–3 · topluluk]
- Koşul: köken göçmen. Ağırlık: 5.
- A) Yardım et → S +, sadık adam adayı; B) İşçi olarak sömür → ₺ +, S −; C) Aileden "temsilci" seç.

**K12 — Tezgâh hırsızları** [2–3 · asayiş]
- Ağırlık: 6.
- A) Dövüp teslim et → K +, N(polis) +; B) Affet → S +; C) Adam yap → adam +1, Sd +.

---

## 5. UNDERBOSS (Evre 3 — 2-3 mahalle)
İlk kez başka bir ailenin gözüne giriyorsun. "Sana yardım isteyen" aileler zayıflar.

**U01 — Aile teklifi (ittifak)** [3–4 · diplomasi]
- Koşul: mahalle sahibi. Ağırlık: 6. **Dünya:** teklif eden `0.6 ≤ G ≤ 1.4`.
- A) Kabul → gerginlik −, ortak iş; B) Şart koş → daha iyi pay (karizma ≥ 7); C) Reddet → gerginlik +; D) Ittifaka sızıp bilgi topla → casus.

**U02 — Sevkiyat savaşı** [3–4 · iş/savaş]
- Koşul: Y.golge ≥ 5. Ağırlık: 8. **Dünya:** rakip `G ≥ 0.7`.
- A) Vur → K +, savaş riski; B) Sat → ₺ +; C) Anlaş → ittifak.

**U03 — Polis şefi randevu** [3–4 · nüfuz]
- Koşul: D ≥ 30. Ağırlık: 5.
- A) Maaşa bağla → N(polis) +3, ₺ −/ay; B) Reddet → D +; C) Kozunu cebine koy (şantaj) → N(polis) +5 ama risk.

**U04 — Yeni mahalle fırsatı** [3–4 · genişleme]
- Koşul: komşu mahalle zayıf. Ağırlık: 6. **Dünya:** komşu `G ≤ 0.8`.
- A) Haraçla → K +, gerginlik +; B) Satın al → ₺ −−, S +; C) Ortak yönetim → ittifak.

**U05 — Kâhya isyanı** [3–4 · sadakat]
- Koşul: adam ≥ 6, Sd < 40. Ağırlık: 5.
- A) Para ver → Sd +; B) Sertlik → K +, darbe riski; C) Yeni biri bul → denge.

**U06 — Mahkemelik arkadaş** [3–4 · yargı]
- Koşul: adamın dava. Ağırlık: 5.
- A) Avukat tut → ₺ −; B) Yargıç ile konuş → N(yargıç) +; C) Bırak kendi başına → Sd −.

**U07 — Gazete manşeti** [3–4 · medya]
- Koşul: Sy ≥ 20. Ağırlık: 6.
- A) Gazeteciyle ittifak → Sy +, S +; B) Yalanla → K +; C) Manşeti sat → ₺ +.

**U08 — Dernek kuruluşu** [3–4 · topluluk]
- Koşul: S ≥ 30. Ağırlık: 5.
- A) Kendi derneğini kur → S +, An +; B) Rakibin derneğine katıl → İl +.

**U09 — Vergi müfettişi** [3–4 · federal]
- Koşul: servet ≥ 40. Ağırlık: 6.
- A) Defteri aç → D −, ₺ −; B) Rüşvet → N +, F +; C) Müfettişi uzaklaştır → F +8.

**U10 — Şehirden yeni aile** [3–4 · dünya]
- Koşul: dünya durumu. Ağırlık: 3.
- Yeni bir aile şehre girer: A) Karşıla; B) Uzak dur; C) Ortaklık kur.

**U11 — Okul binası** [3–4 · toplum]
- Koşul: servet ≥ 30. Ağırlık: 4.
- A) Okul bağışla → S +6, Sy +4; B) Yıktır → ₺ +, S −.

**U12 — Meyhane kavgası büyüdü** [3–4 · asayiş]
- Ağırlık: 6.
- A) Araya gir → Sy +; B) Kenarda bekle → hiçbir şey; C) Kavgayı kışkırt → rakip zayıflar.

---

## 6. DON / ŞEHİR (Evre 4 — 4+ mahalle)
Şehir ölçeği. Ufak olaylar gider; siyaset, federal, savaş ve miras olayları gelir.

**D01 — Şehir savaşı kıvılcımı** [4 · savaş]
- Koşul: 2+ aile gerginliği eşikte. Ağırlık: 8.
- A) Taraf seç → gerginlik/savaş; B) Arabulucu ol → Sy +, ittifak; C) İkisine de ihanet et → büyük kazanç/ büyük risk.

**D02 — Belediye seçimi** [4 · siyaset]
- Koşul: Y.kulis ≥ 15 veya Y.kanun ≥ 15. Ağırlık: 5.
- A) Aday ol → seçim kampanyası; B) Adayı destekle → N(siyasi) +; C) Seçimi boykot et → K +.

**D03 — Federal soruşturma** [4 · federal]
- Koşul: F ≥ 40. Ağırlık: 8, F arttıkça ×.
- A) Avukatla savun → ₺ −; B) Kâğıtları imha et → F −, D +; C) Kaç → zor yol; D) Yargıçla anlaş → N(yargıç) −60, F 50'ye iner.

**D04 — Büyük bankacı** [4 · iş]
- Koşul: servet ≥ 60. Ağırlık: 5.
- A) Ortaklık → ₺ +++, F +; B) Reddet → rakip kazanır; C) Banka kasasını hedef al → büyük soygun (zincir).

**D05 — Senatör yemeği** [4 · nüfuz]
- Koşul: N(siyasi) ≥ 30. Ağırlık: 5.
- A) Destek ver → N +; B) Şantaj → N +, F +; C) Reddet → ilişki −.

**D06 — Şehir tarihi: yıldönümü** [4 · prestij]
- Koşul: An ≥ 30. Ağırlık: 3.
- A) Büyük parti → ₺ −, An +, S +; B) Sessizce geç → ₺ +.

**D07 — Mafya Konseyi** [4 · diplomasi]
- Koşul: 3+ aile. Ağırlık: 5. **Dünya:** G ≥ 0.8 olan en az bir aile.
- A) Başkan ol → Sy +; B) Üye ol → İl +; C) Çık → ittifak kaybı.

**D08 — Kıtalar arası kaçakçılık** [4 · ticaret]
- Koşul: Y.golge ≥ 10. Ağırlık: 5.
- A) Büyük sevkiyat → ₺ +++, D +; B) Liman memurunu satın al → N +; C) Riske girme.

**D09 — Bakan ziyareti** [4 · siyaset]
- Koşul: N(siyasi) ≥ 40. Ağırlık: 3.
- A) Karşıla → N +; B) Gizle → hiçbir şey; C) Provoke et → rezalet.

**D10 — İtibar suikastı** [4 · tehdit]
- Koşul: Sy ≥ 50. Ağırlık: 4.
- A) Yalanla → Sy +; B) Rakibi bul → savaş; C) Sessiz kal → Sy −.

**D11 — Kapalı hapishane** [4 · adalet]
- Koşul: hapis geçmişi. Ağırlık: 3.
- A) Müdürle anlaş → N +; B) Hapishane isyanı → büyük olay.

**D12 — Şehir kuraklığı / kıtlık** [4 · felaket]
- Koşul: S ≥ 30. Ağırlık: 4.
- A) Gıda dağıt → S +; B) Stokla → ₺ +, S −−; C) Rakip aileye sat.

**D13 — Üniversite bursu** [4 · toplum]
- Koşul: servet ≥ 70. Ağırlık: 3.
- A) Burs ver → An +, S +; B) Reddet.

**D14 — Şehir festivali** [4 · prestij]
- Koşul: S ≥ 30. Ağırlık: 5.
- A) Ana sponsor → ₺ −, S +, Sy +; B) Rakibin sponsorluğunu engelle → K +.

---

## 7. BABA YOLU (korku ≥ 45, servet ≥ 40, saygı ≥ 35)
Güç gölgeden gelir. Olaylar sadakat, ihanet, korku yönetimi.

**B01 — İhanetin kokusu** [Baba · sadakat]
- Koşul: Sd < 40. Ağırlık: 7.
- A) Gizlice araştır → Zr(zeka), bulursan K +; B) Herkesi topla → K +, Sd −; C) Gör ama yut → Sd −.

**B02 — Cezalandırma** [Baba · sertlik]
- Koşul: ihanet kanıtı. Ağırlık: 6.
- A) Sessiz cezalandır → K +, Sy ±; B) Herkese göstererek → K +++, S −−; C) Affet → Sy +, Sd +.

**B03 — Rakip aile hediye gönderdi** [Baba · diplomasi]
- Koşul: komşu aile `G ≥ 0.6`. Ağırlık: 5.
- A) Kabul → ittifak; B) İade et → gerginlik; C) Hediyeyi izle → içine bir mesaj gizli.

**B04 — Cenaze** [Baba · ritüel]
- Koşul: yaşlı üye öldü. Ağırlık: 4.
- A) Görkemli → ₺ −, An +; B) Sade → Sy ±; C) Katılma → An −.

**B05 — Bölge tapusu** [Baba · mülk]
- Koşul: ₺ ≥ 5000. Ağırlık: 4.
- A) Satın al → mülk; B) Mülk sahibini korkut → K +; C) Başkasına sat.

**B06 — Sivil kayıp** [Baba · vicdan]
- Koşul: çatışma. Ağırlık: 4.
- A) Tazminat → S ±; B) Örtbas → D +, K +; C) Failini cezalandır → Sy +.

**B07 — Genç çete** [Baba · gelecek]
- Koşul: yaş ≥ 40. Ağırlık: 4.
- A) Himayeye al → Sd +, adam +; B) Ez → K +; C) Yok say.

**B08 — Vasiyet** [Baba · miras]
- Koşul: yaş ≥ 55. Ağırlık: 5.
- A) Eşit böl → An +; B) En yetenekliye bırak → miras seçimi netleşir; C) Hiç yazma → miras kavgası.

---

## 8. SAYGIN İŞ ADAMI YOLU (sevgi ≥ 40, servet ≥ 40, korku < 30)
Bilgi, ilişki, itibar. Silah yok; defter var.

**İ01 — Yeni ortaklık** [İş · iş]
- Koşul: Y.kanun ≥ 10. Ağırlık: 7.
- A) Kabul → ₺ +, Sy +; B) Şart pazarlığı (zeka ≥ 7) → daha iyi pay; C) Reddet.

**İ02 — Banka kredisi** [İş · finans]
- Koşul: temiz servet ≥ 500. Ağırlık: 6.
- A) Al → ₺ +, faiz; B) Rakibe kredi verme → İl +; C) Reddet.

**İ03 — Fabrika grevi** [İş · işçi]
- Koşul: fabrika sahibi. Ağırlık: 5.
- A) Zam → S +, ₺ −; B) Grevi kır → ₺ +, S −−; C) Müzakere → karizma ≥ 7 gerekir.

**İ04 — Rakip iş adamı** [İş · rekabet]
- Ağırlık: 6.
- A) Fiyat savaşı → ₺ −, rakip zayıflar; B) Ortaklık → ₺ +; C) Kulis → N(siyasi) +.

**İ05 — Vergi dairesi** [İş · federal]
- Koşul: servet ≥ 40. Ağırlık: 5.
- A) Dürüst defter → F −, ₺ −; B) Muhasebe oyunu (zeka ≥ 8) → ₺ +, F +; C) Rüşvet → N +, F +.

**İ06 — Hayır balosu** [İş · prestij]
- Koşul: Sy ≥ 30. Ağırlık: 5.
- A) Ev sahibi ol → ₺ −, S +, Sy +; B) Davet al → İl +; C) Boykot → S −.

**İ07 — Gazete satın alma** [İş · medya]
- Koşul: servet ≥ 60. Ağırlık: 3.
- A) Satın al → Sy +, N(siyasi) +; B) Reklam ver → ₺ −; C) Reddet.

**İ08 — Kabine görevi** [İş · siyaset]
- Koşul: N(siyasi) ≥ 40. Ağırlık: 3.
- A) Kabul → N +, Sy +; B) Reddet → bağımsız kal.

**İ09 — Yeni mühendis** [İş · yenilik]
- Koşul: servet ≥ 50. Ağırlık: 4.
- A) Yatırım yap → ₺ +++ (uzun vade); B) Çalıştır → ₺ +; C) Reddet.

**İ10 — Rüşvet teklifi** [İş · ahlak]
- Koşul: N(siyasi) ≥ 20. Ağırlık: 5.
- A) Reddet → Sy +, S +; B) Al → ₺ +, Y.golge +; C) Raporla → Y.kanun +, düşman kazan.

---

## 9. REZİL / DİP YOLU (rezillik ≥ 20, saygı < 20)
Dibe vurmuş birine gelen olaylar komik ve acıdır; bazen çıkış yolu da gösterir.

**R01 — Fiyasko soygun** [Rezil · komedi]
- Koşul: Y.golge ≥ 2. Ağırlık: 8.
- Plan A/B/C: farklı komik fiyasko; rezillik +, bazen yakalanma.

**R02 — Tefeci kapında** [Rezil · borç]
- Koşul: borç > 0. Ağırlık: 8.
- A) Faiz öde; B) Kaç; C) Başka tefeciden borç al (spiral).

**R03 — Eski dostun alay** [Rezil · utanç]
- Koşul: saygı < 10. Ağırlık: 5.
- A) Kavga et → St +; B) Gülüp geç → Sy ±; C) Yardım iste → İl ±.

**R04 — Çıkış fırsatı** [Rezil · umut]
- Koşul: servet < 20. Ağırlık: 4.
- A) Yeni bir iş → Y.kanun +; B) Eski yola dön → risk; C) Reddet.

**R05 — Hapis arkadaşı** [Rezil · hapis]
- Koşul: hapis geçmişi. Ağırlık: 4.
- A) Yeni bağlantı → bilgi; B) Kavga → yara; C) Kaçma planı → risk.

**R06 — Mahalle sana el uzattı** [Rezil · umut]
- Koşul: S ≥ 5. Ağırlık: 4.
- A) Kabul → S +; B) Gururunu bozma → Sy −.

**R07 — Açlık** [Rezil · hayatta kalma]
- Koşul: ₺ < 20. Ağırlık: 6.
- A) Dilen → Sy −−; B) Çal → D +; C) Aş evine git → S +.

**R08 — Son şans** [Rezil · dönüm noktası]
- Koşul: tef_kac ≥ 2. Ağırlık: 5.
- A) Tüm varlığını sat → borç kapanır; B) Kaçmayı dene → ölüm riski; C) Şeytanla anlaş.

---

## 10. AİLE OLAYLARI (eş, çocuk, miras)
Bağlam çarpanı: eş/çocuk durumuna göre. Çocuk yokken çocuk olayı çıkmaz.

**A01 — Evlilik teklifi** [Aile · evlilik]
- Koşul: bekâr, S ≥ 10. Ağırlık: 5.
- A) Evlen → An ±, ₺ −300; B) Bekle; C) Reddet.

**A02 — Eşin tehdit edildi** [Aile · risk]
- Koşul: evli, K ≥ 30. Ağırlık: 5.
- A) Koru → adam görev; B) Rakibe misilleme → savaş; C) Taşın.

**A03 — Doğum** [Aile · çocuk]
- Koşul: evli. Ağırlık: yıllık zar.
- Çocuk doğar; An +. Doğurganlık eğilimi aile etkisine bağlı.

**A04 — Çocuk okulda sorun** [Aile · gelişim]
- Koşul: çocuk 6–16. Ağırlık: 5.
- A) Öğretmenle konuş → Sy +; B) Cezalandır → çocuk gelişimi ±; C) Gizlice müdahale → N(siyasi) +.

**A05 — Genç mirasçı kavgası** [Aile · miras]
- Koşul: 2+ çocuk ≥ 12. Ağırlık: 4.
- A) Arabuluculuk → hepsi memnun; B) Kayır → biri küser; C) Bırak.

**A06 — Çocuğun suça bulaştı** [Aile · gençlik]
- Koşul: çocuk 14–20, K ≥ 40. Ağırlık: 4.
- A) Yönlendir → çocuk mirasçı olur; B) Uzaklaştır → İl −; C) Görmezden gel → risk.

**A07 — Eşin aldatması** [Aile · ihanet]
- Koşul: evli. Ağırlık: 3.
- A) Yüzleş → İl ±; B) Yut → St +; C) Misilleme.

**A08 — Eş hastalığı** [Aile · sağlık]
- Koşul: evli, yaş ≥ 40. Ağırlık: 4.
- A) Doktor → ₺ −; B) Bırak → İl −; C) Büyük hastane → ₺ −−, sağlık +.

**A09 — Torun** [Aile · nesil]
- Koşul: çocuk evli. Ağırlık: 4.
- Yeni nesil; An +.

**A10 — Yaşlı akraba** [Aile · bakım]
- Koşul: aile yaşlı üye. Ağırlık: 4.
- A) Bak → ₺ −, S +; B) Huzurevi → ₺ −; C) Görmezden gel.

**A11 — Boşanma talebi** [Aile · evlilik]
- Koşul: evli, ilişki ≤ 20. Ağırlık: 3.
- A) Kabul → An −; B) Reddet → İl −; C) Barıştır.

**A12 — Düğün** [Aile · tören]
- Koşul: çocuk evlendi. Ağırlık: 4.
- A) Büyük düğün → ₺ −, An +, ittifak; B) Sade; C) Katılma.

**A13 — Aile yadigârı** [Aile · miras]
- Koşul: nesil ≥ 2. Ağırlık: 3.
- A) Sakla → An +; B) Sat → ₺ +; C) Hediye et → İl +.

**A14 — Vasiyet açıldı** [Aile · miras]
- Koşul: ölüm sonrası. Ağırlık: 8.
- Mirasçı seçimi, servet kaybı, geleneğin devamı.

---

## 11. NÜFUZ / POLİS / FEDERAL OLAYLARI

**N01 — Polis baskını** [Polis · baskın]
- Koşul: D ≥ 40. Ağırlık: 9. Polis yozlaşması düşükse ×1.4.
- A) Önceden haberdar et (muhbir) → ₺ −; B) Direnç → K +; C) Mahalleliler sakla → S +; D) Rüşvet → N +.

**N02 — Yargıç tanışma** [Nüfuz · yargı]
- Koşul: servet ≥ 40. Ağırlık: 4.
- A) Dost ol → N(yargıç) +; B) Şantaj → N +, risk; C) Uzak dur.

**N03 — Siyasi bağış** [Nüfuz · siyaset]
- Koşul: servet ≥ 30. Ağırlık: 5.
- A) Bağış → N(siyasi) +; B) Gizli → D +; C) Reddet.

**N04 — Federal ajan masada** [Nüfuz · federal]
- Koşul: F ≥ 40. Ağırlık: 6.
- A) Konuş → Zr(karizma); B) Kaç → F +; C) Rüşvet → riskli.

**N05 — Savcı hamle** [Nüfuz · dava]
- Koşul: D ≥ 70. Ağırlık: 6.
- A) Avukat → ₺ −; B) Yargıç → N −; C) Uzlaş → ceza + hapis.

**N06 — Muhbir ele geçirildi** [Polis · iç]
- Koşul: muhbir ağı. Ağırlık: 4.
- A) Sana ver → bilgi; B) Karşı yem; C) Muhbiri cezalandır → K +.

**N07 — Basın skandalı** [Nüfuz · medya]
- Koşul: Sy ≥ 30, D ≥ 40. Ağırlık: 5.
- A) Yalanla → Zr; B) Gazeteciyi sustur → K +; C) Gerçeği kabul et → Sy ±.

**N08 — İhbar mektubu** [Polis · gizem]
- Koşul: D ≥ 30. Ağırlık: 4.
- A) Kaynağı bul; B) Yok say; C) Mektubu polise ver.

**N09 — Rüşvetin ifşası** [Polis · risk]
- Koşul: rüşvet kayıt. Ağırlık: 3.
- A) Kayıtları imha et; B) İtiraf et; C) Karşı suçla.

**N10 — Affedilme** [Nüfuz · umut]
- Koşul: hapis geçmişi, S ≥ 20. Ağırlık: 3.
- A) Affını dile → itibar; B) Reddet.

---

## 12. DÜNYA / NPC AİLELERİ

**W01 — Zayıf aile yardım istiyor** [Dünya · zayıf]
- Koşul: `G < 0.5`. Ağırlık: 6. **Güçlüyse çıkmaz.**
- A) Yardım → İl +, ittifak; B) Reddet → İl −; C) Himayeye al → bağlılık.

**W02 — Güçlü aile haraç dayatır** [Dünya · baskı]
- Koşul: `G ≥ 1.2`. Ağırlık: 8. Zayıf aile dayatamaz.
- A) Öde → ₺ −; B) Reddet → savaş riski; C) Müzakere.

**W03 — Aile içi iç savaş** [Dünya · iç]
- Koşul: NPC ailenin iç gerginliği. Ağırlık: 4.
- A) Müdahale → İl; B) Fırsattan yararlan → mahalle al; C) Bekle.

**W04 — Teslim olma** [Dünya · bağlılık]
- Koşul: `G < 0.3`, K ≥ 40. Ağırlık: 4.
- A) Kabul → adam/mahalle +; B) Reddet; C) Aşağıla.

**W05 — Yeni ticaret yolu** [Dünya · ticaret]
- Koşul: komşu aile ortak. Ağırlık: 4.
- A) Ortak → ₺ +; B) Kendin yap → risk.

**W06 — Casus** [Dünya · gölge]
- Koşul: rakip `G ≥ 0.6`. Ağırlık: 4.
- A) Yakala → K +; B) Besle → yanlış bilgi; C) Yok say.

**W07 — Aile kızı evlenme teklifi** [Dünya · evlilik]
- Koşul: `0.6 ≤ G ≤ 1.4`. Ağırlık: 4.
- A) Kabul → ittifak; B) Reddet.

**W08 — Şehirde yeni silah** [Dünya · yenilik]
- Koşul: dönem. Ağırlık: 3.
- A) Silah tüccarı → ₺ −; B) Sat; C) Yasakla.

**W09 — Rakip mahalle teklifi** [Dünya · genişleme]
- Koşul: rakip zayıf. Ağırlık: 5.
- A) Satın al → mahalle +; B) Ele geçir → savaş; C) Ortak yönet.

**W10 — Eski düşman barış** [Dünya · barış]
- Koşul: gerginlik azalıyor. Ağırlık: 3.
- A) Kabul → İl +; B) Reddet → gerginlik +.

---

## 13. ZİNCİR OLAYLAR (çok adımlı)
Zincirler tek olay değil, bir hikâye anlatır. Her adım bir önceki seçime bağlıdır.

**Z01 — Mirasın bedeli** [Aile · miras]
1) Vasiyet açılır (A14). 2) Seçmediğin çocuk kıskanır → 3) 1-2 yıl sonra ya iş ortağı olur, ya rakip, ya sürgün.

**Z02 — Yaralı yabancı** [S10]
1) Yaralıyı sakla. 2) 3 ay sonra: o kişi rakip kaptan çıkar → A) İtiraf et → ittifak; B) Rakibe sat → ₺ +; C) Sakla → ileride ihanet.

**Z03 — Yangının sırrı** [K08]
1) Yangın. 2) Araştırırsan rakip esnaf çıkar. 3) A) Yak → savaş; B) Ortaklığa çevir → ittifak; C) Polise → N +.

**Z04 — Banka soygunu** [D04]
1) Plan. 2) Ekip seç. 3) Soygun günü (zar). 4) Sonuç: başarı (₺ ++), kısmi (D +), başarısız (hapis, adam kaybı).

**Z05 — Şehir savaşı** [D01]
1) İki ailenin gerginliği. 2) Taraf seç. 3) Savaş. 4) Barış (mahalle kaybı/kazancı), kaçma, ya da bir tarafın yıkılışı.

**Z06 — Federal avcı** [N04]
1) Ajan seni izler. 2) Bilgi verirsen yanlış yola. 3) Büyük mahkeme. 4) Kâğıtla düşme ya da sürgün.

---

## 14. NADİR / ÖZEL OLAYLAR
Çok düşük ağırlık (≤ 1). Oyuna renk katar.

**X01 — Gizemli yolcu** [Nadir · zaman]
- Ağırlık: 0.5. Hiçbir koşul yok ama yılda bir kez zar atılır.
- Garip kıyafetli biri gelecekten haberler verir. A) Dinle → bir sonraki olayı önceden bilirsin; B) Alay et; C) Yardım et → şaşırtıcı hediye.

**X02 — Işık gece gökyüzünde** [Nadir · uzaylı]
- Ağırlık: 0.3.
- A) Gözetle → bilim ilgisi; B) Gazeteye ver → Sy ±; C) Görmezden gel.

**X03 — Eski tüfek** [Nadir · hazine]
- Ağırlık: 1.
- Evin çatısında gizli bir şey bulunur (para, silah, eski mektup).

**X04 — Rüya** [Nadir · atmosfer]
- Ağırlık: 1.
- Ölen bir yakınının rüyası; küçük bir ruh hali etkisi.

**X05 — Büyük kasırga / sel** [Nadir · doğa]
- Ağırlık: 0.8.
- Mahalle zarar görür. A) Yardım → S +; B) Fırsat → ₺ +, S −−.

---

## 15. UYGULAMA NOTLARI

### 15.1 Veri yapısı (öneri)
```gdscript
"id": {
  "baslik": "...", "evre": [min, max], "tur": "polis|aile|dunya|...",
  "taban": 8, "bekleme": 12, "tek": false,
  "kapi": func(): -> bool,          # sert koşullar
  "carpan": func(): -> float,       # yumuşak çarpanlar (yol, beceri, dünya, aile)
  "secenekler": [{"ad": "...", "kosul": func(), "sonuc": func()}]
}
```
`kartlar.gd` içindeki `KARTLAR`, `SEVIYE`, `uygun()` yapısına eklenir; mevcut kartlar bu şemaya taşınır.

### 15.2 Etiketler
Her olaya etiket: `[para, polis, aile, savas, siyaset, ahlak, nadir, zincir]`. Çarpan hesabı etiketlere göre yapılır (Y.golge yüksekse "gölge" etiketli olaylar artar).

### 15.3 Denge ilkeleri
- Aynı tür olay art arda gelmez (`tazelik`).
- Oyuncunun mevcut krizinde ( savaş, dava, hastalık ) yeni büyük kriz **gelmez** (kriz bütçesi).
- Her evrede en az 1 iyi, 1 kötü, 1 belirsiz olay oranı korunur.
- Büyük olaylar önceden ipucu verir ("Dedikodu: şehirde bir şeyler dönüyor").
- Oyuncu ölmeden önceki son 1 yılda "vasiyet / veda" olaylarının ağırlığı artar.

### 15.4 Sıradaki adım
1. Bu listeyi önceliklendir (hangi evre ilk).
2. `kartlar.gd` şemasını genişlet; 5 evrenin her birine ilk 5 olay yaz.
3. Dünya filtresini (`G` oranı) ekle; "yardım isteyen" olayları denetle.
4. Zincir sistemi için `oyun.zincir` durumu ve kayıt.
