# KARA KALEM — Karakter Kitapçığı

*Şehir: kurgusal bir liman kenti. Yıl: 1927. İçki yasağının dördüncü kışı.*

Bu kitapçık oyundaki herkesi tanıtır: kim olduğunu, nereden geldiğini, seninle bağını ve **oyun içinde değişebilen** her şeyi. Her kartın sonundaki "Değişir" satırı, o karakterin hangi olaylarla farklı bir insana dönüşebileceğini söyler.

> **Not (tasarım/kod durumu):** Oyunda şu an adam (`yumruk, bicak, zeka, sadakat, silah`), aile üyesi (`rutbe, iliski, hp, isabet`) ve oyuncu özellikleri (`kisisel.gd → OZ`) kodlu. Bu kitapçıktaki isimli kadro, hikâyeler ve kişisel direnç/etken alanları **tasarım önerisidir**; son bölümdeki şema ile koda geçirilir. Oyun şu an aile üyelerine rastgele isim verir, buradaki isimler varsayılan (sabit) kadro olarak önerilir.

---

## 0. Nasıl okunur

### 0.1 Her kartta ne var

| Alan | Anlamı | Aralık |
|---|---|---|
| **Görüş** | Karakterin sana duyduğu his. Tek sayı değil, nedenleri olan bir döküm (GDD 22.2). Kodda `iliski`. | −100 … +100 |
| **Sadakat** | Sana (ya da patronuna) bağlılığı. Adamlarda kodlu. | 0 … 100 |
| **Savaş** | Yumruk / Bıçak / Zekâ (adamlar, 15–90) ya da rütbe gücü: HP ve isabet. | — |
| **Stres** | Baskı altında ne kadar dayandığı. Eşikler 33/66/100 (GDD 22.3). | 0 … 100 |
| **Dosya** | Polis dosyasında ne kadar yandığı. | 0 … 100 |
| **Sır / Koz** | Elindeki ya da hakkındaki gizli bilgi. Koz kullanmak iknayı neredeyse garanti eder ama Görüşü çökertir. | — |
| **Özellikler** | 2–4 huy. Etkileri aşağıdaki tabloda. | — |
| **Direnç** | O kişiye karşı **ikna / korku / rüşvet** şansını artıran ya da düşüren kalıcı etken. | −30 … +30 puan |

### 0.2 Etken tablosu (kişisel özellikler)

Aşağıdaki özellikler bir karakterin **ikna edilme**, **korkutulma** ve **satın alınma** ihtimalini değiştirir. Etkiler puan olarak karşındaki kişinin direncine eklenir. Satırlarda (oyun) yazanlar kodda zaten oyuncu özelliği olarak vardır; (yeni) olanlar bu kitapçığın önerisidir.

| Özellik | İkna | Korku | Rüşvet | Not |
|---|---|---|---|---|
| Sözünün eri (yeni) | −10 | −10 | −25 | Söz verirsen tutarsın, o da tutar. Zor satın alınır. |
| Açgözlü (yeni) | +5 | 0 | +25 | Para her kapıyı açar; ama bir sonraki teklife de açıktır. |
| Kindar (yeni) | −10 | +5 | −5 | Eski bir ihaneti unutmaz. Görüş toparlanması yavaştır. |
| Merhametli (yeni) | +10 | −10 | 0 | Acıma ile ikna edilir, korkutmak ters tepebilir. |
| Gözüpek (yeni) | −5 | −25 | 0 | Korkutmak neredeyse imkânsız. |
| Temkinli (`korkak`) | 0 | +15 | +5 | Risk almaz; tehdit çabuk işler, ama sana da kolay güvenmez. |
| Sinirli (`sinirli`) | −10 | +5 | 0 | Çabuk parlar; stres hızlı birikir. |
| Soğukkanlı (`soguk_kanli`) | 0 | −15 | 0 | Baskı altında paniklemez. |
| Cömert (`comert`) | +10 | 0 | −10 | Adamları ona sadıktır; parayla pek oynanmaz. |
| Cimri (`cimri`) | −5 | 0 | +15 | Harcamayı sevmez, kasası boş kalmaz. |
| Dilbaz (`dilbaz`) | +15 | 0 | −10 | Seni o ikna eder, sen onu zor. |
| Vicdanlı (`vicdanli`) | +10 | −5 | −15 | Yaptıkları içine işler; güven verir. |
| Acımasız (`acimasiz`) | −10 | −10 | +5 | Korkunun dilini bilir, sana da öyle davranır. |
| Alkole düşkün (`alkolik`) | +10 | +5 | +15 | Sarhoşken ikna kolay; sabaha pişman olur. |
| Kumarbaz (`kumarbaz`) | +5 | 0 | +20 | Borç ve risk onu satın alınabilir yapar. |
| Polisle iyi (`polis_dostu`) | 0 | +5 | −5 | Karakolda dostu var, ama kendi dosyası yavaş kabarır. |
| Muhbir ağı (`muhbir_agi`) | 0 | +5 | 0 | Her şeyi bilir; seni de bilir. Sır saklamak zor. |
| Mahalleli (`mahalleli`) | +5 | −5 | −5 | Mahallede sevilir; ona dokunmak sevgiyi eritir. |

### 0.3 Bir konuşma nasıl hesaplanır (öneri)

```
İkna şansı  % = 50 + 0,4 × İkna(sen) + Görüş/4 − Direnç(ikna)  [+ Koz, + Dilbaz ...]
Korku şansı % = 50 + 0,4 × Gözdağı(sen) + Güç farkı/4 − Direnç(korku)
Satın alma  % = 40 + √(rüşvet $) × 3 − Direnç(rüşvet) − Sadakat/3
```

Oyuncu tarafında karşılığı: `ikna`, `korku`, `pazarlik` becerileri (`yetenek.gd`), özelliklerden `cilveli`, `dilbaz`, `sert_bakis`, `acimasiz`. **Korku, sevgiyi düşürür.** Bir karakter seni korkarak sever (Görüş yüksek, Sadakat orta) ya da severek korkar (Sadakat yüksek, Görüş orta); ikisi aynı şey değildir.

### 0.4 Görüş neden değişir

Her kartta bu tetikleyiciler tekrar eder:
- **Yardım / iyilik** (+): borç bırakmak, hapisten çıkarmak, kurtarmak.
- **Maaş, prim, ziyafet** (+, özellikle Cömert).
- **Gözdağı, baskın, sert konuşma** (−, korkulanlarda Sadakat +).
- **Sözünü tutmamak** (−, Sözünün Eri'de ağır).
- **Arkadaşına / akrabasına zarar vermek** (−, Kindar'da kalıcı).
- **İlgisizlik** (ayda ≈ −2, GDD 22.2).

---

## 1. SEN

### Baban — *(geride kalan)*

Bir dönem Southside'ın en çok tanınan işçilerinden biriydi: liman çuvalcısıydı, sonra kendi küçük işine girdi, meyhanede bahse girip şansını denerdi. Öldükten sonra herkes onu "iyi adamdı" diye anar, ama kimse "borcunu ödeyecek mi" diye sormaz. Çünkü cevabı biliyorlar.

- **Oyuna etkisi:** $2.400 borç ve aylık $150 taksit, Sal the Shark'a. (Yalnız "Southside'lı" başlangıcında.)
- **Sır:** Baban Sal'dan fazlasını borçlandı. Marchetti Family'den de bir "iyilik" aldı. Bunu henüz bilmiyorsun.
- **Değişir:** Borç eridikçe Sal'ın Görüşü artar; taksit atlanırsa Sal'ın adamları "oturmaz".

### Sen — *(oyuncu)*

Kim olduğunu menüde sen seçersin: **Southside'lı** (mahalleli, borçlu), **Bir ailenin adamı** (soldato, patronlar seni izler) ya da **Dışarıdan gelen** (cebinde 45 dolar). Geçmişin: liman işçisi, eski boksör, savaş gazisi, muhasebeci, kaçakçı çırağı.

- **Stat:** Güç, Nişan, Zekâ, Karizma (geçmişe göre ±2).
- **Başlangıç özellikleri:** geçmişinden gelen küçük eğilimler; zamanla davranışların yenisini ekler (`oz` puanı 0–100, kullanılmazsa solar).
- **Etken olarak:** Karizma ve Zekâ ikna şansını, Güç ve Gözdağı korku şansını belirler. Ama bu iki yol birbirini yer: ikna eden korkutamaz, korkutan sevilemez.
- **Değişir:** Her şey. Bu kitapçığın amacı senin kime dönüşeceğini kontrol etmek değil, çevrendekilerin sana nasıl tepki vereceğini önceden göstermek.

---

## 2. SOUTHSIDE: Mahalle

### Sal "The Shark" Pescatore — *Tefeci* (54)

**Hikâye:** Liman ambarlarında bir sevkiyat katibiydi, rakamlara sığınan sessiz bir adam. Yasak gelince ilk kez bir sandık viskinin rakamlarını görünce anladı: bu şehirde en çok para tutan şey borç. Şimdi küçük bir rehinci dükkânın arkasında, kendisine "Köpekbalığı" denmesine ses çıkarmadan oturuyor. Kimseye bağırmaz. Kimseyi dövmez. Sadece **tarih verir**.

- **Seninle bağı:** Babana borç vermişti; şimdi o borcun sahibisin. Resmen düşmanın değil, "alacaklın".
- **Görüş: −5.** (+10 babanla eski ilişkisi, −15 borç)
- **Savaş:** Yumruk 25 · Bıçak 30 · Zekâ 85. HP düşük; dövüşü adamlarına bırakır.
- **Stres:** 25. Paranın kaybından değil, **kontrolü kaybetmekten** korkar.
- **Dosya:** 15 (Marchetti ona dokunmaz, çünkü Sal onların küçük borçlularını yönetir).
- **Özellikler:** Hesapçı · Açgözlü · Sözünün eri (borç sözünde) · Soğukkanlı.
- **Direnç:** İkna −5 · **Korku −20** (tehdit onu etkilemez: onun adamları var) · **Rüşvet +10** (ama sadece borç silmeyi kabul eder, nakit değil).
- **Sır:** Borçlularına bildirmediği bir gizli ortağı var: Tammany'den Meclis Üyesi Ashworth. Dükkân sahiden onun adına açıldı.
- **Koz:** Ashworth'u ifşa etmek Sal'ı çökertir ama Belediye Makinesi seni hedef alır.
- **Değişir:** Taksit düzenliyse Sal "iyi müşteri" der, faiz konuşulabilir; üç taksit üst üste atlanırsa oyun biter (borç sistemi). Seninle ilgili bir söz kesin tutulur: **"Sana kefil olan adamı bilirim."**

### Moe — *Sal'ın tahsildarı* (31)

**Hikâye:** Eskiden boksördü; sağ kulağı kalıcı çınlar. Sal onu ringin dışına, bir sandığın üstüne oturtmuştu: "Bu işte vurmazsın, durursun." Moe bunu seviyor. Kapıda bekler, borçlular sessizlik içinde ödemeyi bilir.

- **Görüş: −10.** (−15 "borçlu", +5 aynı eski ringden bildiği için)
- **Savaş:** Yumruk 78 · Bıçak 40 · Zekâ 32 · HP 110.
- **Sadakat (Sal'a):** 85.
- **Özellikler:** Kavgacı · Sert bakış · Sözünün eri · Alkole düşkün (nadiren, ringde yenildiğinde).
- **Direnç:** İkna +5 · **Korku −15** · Rüşvet −10.
- **Değişir:** Sal'ın Görüşü düşerse Moe "ev ziyareti"ne gelir. Eğer onu bir kez yenersen (ya da zekice atlatırsan) saygısı artar: dövüşte yenilmek Moe için utanç değil, **işin parçası**.

### Paddy Murphy — *Murphy's Tavern sahibi* (61)

**Hikâye:** Cork'tan çocukken geldi. Meyhane önce babasınındı, ama Murphy'nin kendisi bir tek şeyden ayrılmadı: kapıdaki alüminyum tabela ve arka odadaki masa. Yasak geldiğinde "soft drink parlor" yazdırdı, bodrum kapağından fıçı indirdi. Mahalledeki **herkesin bir şeyini bilir** ve bunu hiçbir zaman söylemez. Baban onun en eski müşterisiydi; senin hesabını hâlâ defterde tutuyor: "Daniel'in oğlu". (Soyad oyuncudan gelir.)

- **Seninle bağı:** Mahalledeki ilk ve en güvenli dost. "Baban öldü, ama mektubu bende."
- **Görüş: +35.** (+25 babanın dostu, +10 mahalleli geçmişin)
- **Savaş:** Yumruk 55 · Bıçak 40 · Zekâ 60 (kasanın altında bir sopa vardır).
- **Stres:** 40, ama göstermez.
- **Dosya:** 20 (haftalık rüşvet polise gider).
- **Özellikler:** Mahalleli · Cömert · Muhbir ağı · Alkole düşkün.
- **Direnç:** **İkna −10 (kolay)** · Korku +10 (mahallesini korumak için direnir) · Rüşvet +5.
- **Sır:** Polis rüşvetinin bir kısmı Sal'ın borçlularından gelir; yani **babanın borcundan** de bir pay almıştır.
- **Koz:** Bunu öğrenirsen Murphy'yi susturabilirsin ama mahalle seni ayrı bir gözle görür.
- **Değişir:** Eğer mahalleye saygılı kalırsan Murphy sana "iş yeri" verir (bar işi), müşteri ve bilgi sağlar. Mahalleye zarar verirsen en önce o kapıyı kapar.

### Frank Duffy — *Duffy's Bar* (47)

**Hikâye:** Murphy'nin rakibi, daha gürültülü. Duffy's Bar bilardo ve rulet masalarıyla yarı-yasal bir yer; müşterisi gençler, işçiler, vardiya çıkışı gemiciler. Bir gün Marchetti'ye haraç vermeyi reddetti, ertesi sabah camı kırıldı. Hâlâ ödemiyor ama gece kapıyı kilitliyor.

- **Görüş: 0.** (Tarafsız; seni "Murphy'nin kuzusu" olarak görür.)
- **Savaş:** Yumruk 62 · Bıçak 45 · Zekâ 48.
- **Özellikler:** Kumarbaz · Sinirli · Gözüpek · Cömert.
- **Direnç:** İkna +5 · **Korku −15** · Rüşvet +10 (borcu var).
- **Sır:** Rulet masasının altına gizli bir cep. Müşteri kazanırsa kapanır.
- **Değişir:** Marchetti baskısı arttıkça Duffy sana yakınlaşır; Marchetti'ye yaklaşırsan Duffy bir gün kapıyı yüzüne kapatır.

### Rosa Esposito — *Corner Grocer* (58)

**Hikâye:** Napoli doğumlu, üç oğlu savaşta, biri dönmedi. Köşe bakkalı sokağın gazetesi: kimin ne aldığını, kimin borç yazdırdığını, kimin gece geç kaldığını bilir. Tek bir kuralı var: **kimse aç yatmaz**.

- **Görüş: +20.**
- **Savaş:** Yumruk 15 · Bıçak 20 · Zekâ 72.
- **Özellikler:** Mahalleli · Merhametli · Muhbir ağı · Sözünün eri.
- **Direnç:** **İkna −15 (kolay)** · Korku +20 (ağır ters tepki: mahalle senden çekinir) · Rüşvet +25.
- **Etki:** Rosa'nın Görüşü, **Southside sevgisini** doğrudan çeker.
- **Değişir:** Yemek yardımı, borç silme, bakkala saldırının önlenmesi +; haraç kesmek ya da bakkalı tehdit etmek mahalledeki sevgiyi sert düşürür.

### Gus Kalogeropoulos — *Berber* (49)

**Hikâye:** Giritli. Bıçağını bir tıraşta bırakıp bir sırrı alır. Koltuğunda oturan herkes konuşur: polis, hamal, sarhoş, vaiz. Gus ağzını sıkı tutar ama **kime ne zaman bir şey söyleyeceğini** iyi bilir.

- **Görüş: +10.**
- **Savaş:** Yumruk 35 · Bıçak 80 · Zekâ 70.
- **Özellikler:** Dilbaz · Muhbir ağı · Soğukkanlı · Polisle iyi.
- **Direnç:** **İkna −15** · Korku +5 · Rüşvet −5 (bilgi satar ama kimseyi ele vermez).
- **Etki:** Bilgi satın alma: "kim ne biliyor" sorusunun fiyatı onda.
- **Değişir:** Gus'a sık gidersen "arkadaş"; seni polisle gördüğünde **başka yöne** bakar.

### Peder Brennan — *Kilise* (66)

**Hikâye:** Eskiden askerdi, sonra Tanrı'ya döndü. Mahalleli ona günahını anlatır, borcunu, kocasının dövdüğünü. Brennan her şeyi bilir ve hiçbir şeyi söylemez. Ama **bir kez** insanları uyarır: "Bu adamdan uzak durun." Sen o adam olmak istemezsin.

- **Görüş: +15.**
- **Savaş:** Yumruk 40 · Bıçak 20 · Zekâ 75.
- **Özellikler:** Vicdanlı · Merhametli · Soğukkanlı · Sözünün eri.
- **Direnç:** İkna +10 (günah çıkarma zor) · **Korku −20** · **Rüşvet −30 (yok)**.
- **Etki:** Sevgi/huzur, Southside'da en büyük çarpanlardan biri.
- **Değişir:** Bağış ve yardım Görüşü yükseltir; kan dökmek Brennan'ı sana karşı bir sese çevirir.

---

## 3. MARCHETTI FAMILY: *Flats ve Docks'un sessiz gücü*

> Disiplinli, İtalyan, aile içi hiyerarşiye düşkün. Kurallar yazılı değildir ama **herkes bilir**. Saldırganlık ×1,0.

### Don Vito Marchetti — *Don* (62)

**Hikâye:** Sicilya'dan 1903'te, on sekiz yaşında geldi. Önce limanda çuval taşıdı, sonra çuvalları taşıyanların patronu oldu. Bir sandık viskinin ve bir bakanın kızının nikâhının arasında şehri "evlat edindi". Vito'ya göre aile, kurallar ve hatırlanan iyiliklerdir. **Öldürmeyi sevmez; ama gerekliyse bir kez ve temiz yapar.**

- **Seninle bağı:** Babanın borcundan haberdar. Seni "ilginç" bulur.
- **Görüş: +5** (aile başlangıcında +20; "Southside'lı"da 0; "Dışarıdan gelen"de −10).
- **Savaş:** HP 140 · İsabet %62 · Silah: Tommy.
- **Stres:** 55 (yaş, vâris sorunu, Marchetti'nin Docks üstündeki iç çekişmesi).
- **Dosya:** 35.
- **Özellikler:** Sözünün eri · Temkinli · Kindar · Cömert (aileye).
- **Direnç:** İkna −5 · **Korku −25** (Gözüpek: seni değerlendirir, korkmaz) · **Rüşvet −30** (para onu hakaret sayar; iyilik borcu dili anlar).
- **Sır:** Oğlu yok. Vârisi olarak yeğenini düşünüyor, ama yeğen (Carlo) aileye yeterince sadık değil.
- **Koz:** Sicilya'daki akrabasına gönderilen para, Marchetti'nin dışında bir hesapta.
- **Değişir:** **Saygı** Don için tek para birimidir. Aile içinde başarın Görüşü yükseltir; ailenin düşmanıyla bağın onu yok eder. Don ölürse (ya da öldürülürse) Underboss kuralı devralır.

### Carlo Bruno — *Underboss* (44)

**Hikâye:** Vito'nun eski şoförünün oğlu; "yeğen" değil ama Vito'ya yeğen gibi bakar. Öfkelidir, hırslıdır, her sözde **bir tehdit** arar. Don'un sağ kolu olarak bölgeleri yönetir. Bir gün Don'un yerine geçeceğini düşünür, ama bunun hakkı olduğuna emin değildir.

- **Görüş: −10.** (Seni rakip görür.)
- **Savaş:** HP 115 · İsabet %58 · Tommy / pompalı.
- **Stres:** 60.
- **Dosya:** 40.
- **Özellikler:** Sinirli · Acımasız · Açgözlü · Gözüpek.
- **Direnç:** İkna −10 · **Korku −20** · **Rüşvet +25**.
- **Sır:** Tammany'den bir arabulucuyla gizli görüşüyor (Don'a haber vermeden).
- **Değişir:** Don'un sana verdiği değer arttıkça Carlo'nun Görüşü düşer. Onun yanında olursan Don'a karşı kullanabilirsin; ama bir gün senden de kurtulur.

### Enzo Conti — *Consigliere* (58)

**Hikâye:** Eski bir noter katibi. Kitap okur, satranç oynar, bir odanın en sessiz adamıdır. Marchetti'nin "yasal yüzü": belediyeyle, banka ile, avukatlarla konuşan sesi. **Silah taşımaz**; sözünün ağırlığı yeter.

- **Görüş: +10.**
- **Savaş:** HP 80 · İsabet %55 · Tabanca (taşımaz).
- **Stres:** 35.
- **Dosya:** 20.
- **Özellikler:** Hesapçı · Dilbaz · Temkinli · Sözünün eri.
- **Direnç:** **İkna −5** (mantıkla) · Korku +10 · Rüşvet −15.
- **Sır:** Belediye Başkanı ile ailesi arasında "kefil" olarak yer aldığı bir anlaşma.
- **Değişir:** Yasal yola girmeni destekler. Ailenin sert tarafına girersen seni gerçekçi biçimde uyarır, ama bir kez.

### Rocco Rizzo — *Capo, Docks* (46)

**Hikâye:** Limanı bilir: hangi gemi ne zaman girer, hangi sendika hangi gün kapı kapar. Eski bir kaçakçıdır; işçiyle dövüşür ama onları sever. **Docks halkı Marchetti'yi onun yüzünden tanır.**

- **Görüş: 0.**
- **Savaş:** HP 95 · İsabet %55 · Pompalı.
- **Özellikler:** Mahalleli · Kavgacı · Sert bakış · Cömert.
- **Direnç:** İkna −5 · Korku −10 · Rüşvet +5.
- **Değişir:** Docks'ta sevgiyi artırırsan sana iş açar. Haracı artırırsan Marchetti'nin sesi olur ve seni uyarır.

### Paulie Gallo — *Capo, Flats* (39)

**Hikâye:** Demiryolu, depo, atölye: Flats'in sahibi. Kimse sorusu olmayan adam. Sessiz, hızlı, soğuk; gece konuşur, gündüz görünmez.

- **Görüş: −5.**
- **Savaş:** HP 95 · İsabet %56 · Tommy.
- **Özellikler:** Acımasız · Soğukkanlı · Gizli (iz bırakmaz) · Kindar.
- **Direnç:** İkna +5 · **Korku −15** · Rüşvet +10.
- **Değişir:** Flats'te Marchetti'ye saygı gösterirsen seni görmezden gelir; bölgesine girersen sessiz bir uyarı gelir, ikincisi gelmez.

### Gino Fontana — *Capo, Southside* (41)

**Hikâye:** Southside'ın haraç toplayıcısı. Esnaf onu tanır ve sevmez, ama kapıdan geçerken saygıyla başını eğer. Sende babasını görür ("o da borçluydu").

- **Görüş: +5.** (Mahalleli olduğunu bilir; sen onun bölgesindesin.)
- **Savaş:** HP 95 · İsabet %55 · Pompalı.
- **Özellikler:** Sert bakış · Cimri · Polisle iyi · Sözünün eri.
- **Direnç:** İkna +5 · Korku −10 · **Rüşvet +15**.
- **Değişir:** Haraç miktarı ve mahalledeki sevginle ilgili baskı yaratır; sen daha iyi toplarsan senin yanında olur.

### Nico Greco — *Capo, Eastside* (36)

**Hikâye:** Genç, hırslı, modern. Eastside'ın pazar yerini ve sinema salonlarını yönetir. **Eski kuşakla** (Vito) çatışır; bir gün düzenin değişmesi gerektiğini düşünür.

- **Görüş: +10.**
- **Savaş:** HP 95 · İsabet %55 · Tabanca.
- **Özellikler:** Dilbaz · Gözüpek · Açgözlü · Kumarbaz.
- **Direnç:** **İkna −10** · Korku −10 · Rüşvet +10.
- **Değişir:** Carlo'ya karşı doğal müttefik; ama aile içi bir çatlak gelirse taraf değiştirebilir.

### Soldato *(tip)*

Marchetti'nin yüzlerce askeri: takım elbise, melon şapka, bıçak ya da tabanca. **Hepsi ailesi için ölür**; ama biri önceden bir hata yaptıysa Don onu affetmez.
- **Savaş:** HP 70 · İsabet %50 · Tabanca / bıçak.
- **Direnç:** İkna +5 · **Korku −10** · Rüşvet +10.

---

## 4. O'BRIEN ÇETESİ: *Eastside'ın gürültülü sahibi*

> İrlandalı, kavgacı, topluluk bağları sıkı. Saldırganlık ×1,25 (en yüksek).

### Seamus O'Brien — *Patron* (57)

**Hikâye:** Belfast'tan, Meyhane duvarına çivilenmiş yeşil bir bayrak gibi. Marchetti sessiz kazanır, O'Brien gürültüyle. Seamus **her gece** barda, her sabah mezarlıkta (oğlu). Dostluk ona bir yemin, düşmanlık bir borçtur.

- **Görüş: −5.** (Murphy ile akrabalığın nedeniyle ılımlı.)
- **Savaş:** HP 140 · İsabet %62 · Tommy.
- **Stres:** 65.
- **Dosya:** 50.
- **Özellikler:** Sinirli · Cömert · Alkole düşkün · Kindar.
- **Direnç:** İkna −5 (içerken) · **Korku −25** · Rüşvet +5.
- **Sır:** Oğlunun ölümünden Marchetti'yi sorumlu tutuyor (haksız mı haklı mı belli değil).
- **Koz:** O gece tanık: eski bir tavernacı.
- **Değişir:** Cömertliğe cömertlikle karşılık verir; hakarete anında; içkiyle bir arada **sadakat de öfke de büyür**.

### Declan Doyle — *Sağ Kol* (43)

**Hikâye:** Seamus'un en eski dostunun oğlu. Planlayan odur: gürültü Seamus'un, hesap Declan'ın. Bazen Seamus'un yanlışlarını gizler.

- **Görüş: 0.**
- **Savaş:** HP 115 · İsabet %58 · Tommy / pompalı.
- **Özellikler:** Hesapçı · Sözünün eri · Soğukkanlı · Kindar.
- **Direnç:** İkna 0 · Korku −15 · Rüşvet −10.
- **Değişir:** Seamus'un sağlığı ya da öfkesi arttıkça Declan'ın söz hakkı artar.

### Finn Keane — *Muhasebeci* (50)

**Hikâye:** Defteri O'Brien'ın gerçek patronu. Kim ne kadar öder, kim ne kadar çalar: hepsi onun kafasında.
- **Görüş: +5.**
- **Savaş:** HP 80 · İsabet %55 · Tabanca (taşımaz).
- **Özellikler:** Hesapçı · Cimri · Temkinli · Kumarbaz (gizlice).
- **Direnç:** İkna 0 · Korku +15 · **Rüşvet +20**.
- **Sır:** Çetenin parasından küçük bir pay çekiyor.
- **Koz:** Defterin ikinci kopyası.

### Kaptanlar: **Colm Quinn** (Eastside) · **Brendan Byrne** (Docks) · **Rory Kelly** (Hilltop çevresi) · **Liam Walsh** (Downtown çevresi)

Dördü de farklı ve hepsi Seamus'a farklı sebeple bağlı: Colm eski bir dövüşçü, Brendan Docks'ta işçi sendikasıyla iç içe, Rory genç ve kumarbaz, Liam sakin ve temkinli.
- **Savaş:** HP 95 · İsabet %55 · Pompalı / Tommy / tabanca.
- **Özellikler (örnek):** Colm: Kavgacı · Sinirli · Sözünün eri · Gözüpek. Brendan: Mahalleli · Cömert · Muhbir ağı. Rory: Kumarbaz · Açgözlü · Dilbaz. Liam: Temkinli · Hesapçı · Soğukkanlı.
- **Direnç:** İkna 0 / Korku −10 / Rüşvet +10 (Rory +25).

### Külhanbeyi *(tip)*

O'Brien'ın askeri: yüksek kafa, ucuz içki, yüksek öfke.
- **Savaş:** HP 70 · İsabet %50 · Bıçak / tabanca.
- **Direnç:** İkna +10 (içerken) · Korku −10 · Rüşvet +15.

---

## 5. BELEDİYE MAKİNESİ: *Hilltop ve Downtown'ın temiz yüzü*

> Siyasi, görgülü, kan görmeyi sevmez. Saldırganlık ×0,35. Güçleri para, ruhsat ve gazete.

### Başkan Harold Pembroke — *Başkan* (59)

**Hikâye:** Belediye başkanı değil; ondan çok "başkanı seçen adam". Parti binasının üst katında bir ofisi, her seçimde bir kampanyası vardır. Yasak onun için bir ahlak meselesi değil, **bir vergi fırsatıdır.**

- **Görüş: 0.**
- **Savaş:** HP 140 · İsabet %62 (silahı kapıdaki iki adam taşır).
- **Stres:** 45.
- **Dosya:** 10 (yüzeyde en temiz kişi).
- **Özellikler:** Dilbaz · Açgözlü · Temkinli · Hesapçı.
- **Direnç:** **İkna −10** · **Korku +25** (şiddetten çekinir, ama polis çağırır) · **Rüşvet +30** ("bağış" kılığında).
- **Sır:** Kampanya fonu, Marchetti'den geliyor.
- **Koz:** Tamamladığı bir ihalenin sahte evrakı.
- **Değişir:** Temiz görünmek için seni hem korur hem kullanır; skandal çıkarsa seni **ilk feda eden** o olur.

### Edmund Ashworth — *Meclis Üyesi* (52)

**Hikâye:** Pembroke'un sağ kolu. Sal the Shark'ın gizli ortağı. Hilltop'ta villası, bir gül bahçesi, bir kumar borcu.
- **Görüş: −5.**
- **Özellikler:** Açgözlü · Kumarbaz · Dilbaz · Temkinli.
- **Direnç:** İkna −5 · Korku +20 · **Rüşvet +30**.
- **Sır:** Sal'ın dükkânının ortağı (bkz. Sal).
- **Koz:** Çok güçlü; ama kullanırsan Belediye'nin tamamı seni hedef alır.

### Arthur Sterling — *Avukat* (47)

**Hikâye:** Aile avukatı, ama hangi aileye? Marchetti'nin ve Belediye'nin ortak avukatı; bu çelişkiyi yıllardır yönetir. Mahkemede **dosya silmek** için en iyi seçenek; bir de **dosya kurmak** için.
- **Görüş: +10.**
- **Özellikler:** Hesapçı · Dilbaz · Sözünün eri · Vicdanlı (kendi içinde).
- **Direnç:** İkna −10 · Korku +15 · Rüşvet −5.
- **Etki:** Dosyanı düşürmenin en güvenli yolu; ücreti yüksek.

### Bölge Temsilcileri: **Clarence Vandermeer** (Hilltop) · **Chester Crane** (Downtown) · **Lloyd Talbot** (Eastside) · **Percy Whitcomb** (Southside)

Dört "temsilci", dört farklı bölge, dört farklı nezaket. Hepsi seçim zamanı kapına gelir, "oyun nasıl işliyor" diye sorar.
- **Özellikler:** Dilbaz · Temkinli · Cömert (seçim dönemi) · Muhbir ağı.
- **Direnç:** İkna −10 · Korku +20 · Rüşvet +20.
- **Percy Whitcomb** özel: Southside'da senin bölgende; seni mahalle meclisi **adayı** yapmak ya da sana ruhsat engeli çıkarmak onun elinde.

### Yardakçı *(tip)*

Belediye'nin "adamı": memur, kapıcı, zabıta, arkadaş. Kimi sıradan, kimi suçlu.
- **Savaş:** HP 60 · İsabet %40 · Tabanca (nadiren).
- **Direnç:** İkna +10 · Korku +20 · **Rüşvet +25**.

---

## 6. ŞEHRİN RESMÎ YÜZÜ

### Yüzbaşı Walter Brogan — *Karakol Amiri* (55)

**Hikâye:** Otuz yıllık polis; yasak onun için bir **haraç sezonu**. "Yasa"yı kimse kadar iyi bilir ve kimse kadar esnetir. Yine de kendi kuralı vardır: **polis öldürmek yok**.
- **Görüş: −10.**
- **Dosya (senin hakkında):** senin aramanla bağlı.
- **Özellikler:** Açgözlü · Polisle iyi · Temkinli · Sözünün eri (kendi kuralında).
- **Direnç:** İkna −5 · Korku +15 · **Rüşvet +25** (reform dönemlerinde −15).
- **Etki:** Aramanı düşürür, devriyeyi başka bölgeye çeker, ama bir gün rakibine daha fazla öder.

### Edie Marlowe — *Daily Courier Editörü* (38)

**Hikâye:** Şehrin en sert kalemi; kadın olduğu için üç kez işten atıldı, üçünde de patronu iflas etti. Kimse onu satın alamaz çünkü kimsenin parası onun kalemine yetmez. Ama **iyi bir hikâye** için gerisi önemsizdir.
- **Görüş: −5.**
- **Özellikler:** Sözünün eri · Gözüpek · Vicdanlı · Muhbir ağı.
- **Direnç:** İkna +5 · **Korku −25** · **Rüşvet −30**.
- **Etki:** Haber gömmek neredeyse imkânsız; ama bir iyilik (özellikle gerçek bir ihbar) onu kazanır.

### Yargıç Leopold Hartwell — *Mahkeme* (63)

**Hikâye:** Eski bir avukat; yasanın kendisine ihanet etmesini istemez. Ama ihaleye, kefalete, tahliyeye **kimin dosyası geldiğine** bakar.
- **Görüş: 0.**
- **Özellikler:** Vicdanlı · Temkinli · Sözünün eri · Hesapçı.
- **Direnç:** İkna +5 · Korku +25 · **Rüşvet +10** (kolaycı değil; ama imkânsız da değil).
- **Sır:** Torununun hastane masrafları.

### "Koca" Jack Kowalski — *Stevedore Union Başkanı* (51)

**Hikâye:** Liman işçilerinin sesi. Marchetti'ye grev tehdidini yıllarca sattı, yine de sendikanın sevgisini yitirmedi. Bir elinde bira, diğerinde kasadaki grev fonu.
- **Görüş: +5.**
- **Özellikler:** Mahalleli · Cömert · Gözüpek · Sinirli.
- **Direnç:** İkna −5 · Korku −15 · Rüşvet +5.
- **Etki:** Docks halkı onun sözüne bakar; sevgi/korku çarpanı Docks'ta onda.

---

## 7. İŞE ALINABİLECEK ADAMLAR: *Tipler*

Pazarda ve barlarda karşına çıkan adaylar (`pazar.gd → NOTLAR`). Her adayın Yumruk/Bıçak/Zekâ değerleri 15–90 arasında rastgele gelir; **Sadakat** 5–100. Aşağıdaki özellikler o notun getirdiği eğilimdir.

| Not | Eğilim | Sadakat | İkna | Korku | Rüşvet |
|---|---|---|---|---|---|
| Eski liman kavgacısı | Yumruk ↑ · Kavgacı · Sert bakış | 55 | +5 | −10 | +5 |
| Şehre yeni gelmiş | Düşük çevre · Temkinli | 45 | −5 | +5 | +15 |
| Hapisten yeni çıkmış | Kindar · Acımasız · Dosya var | 35 | +5 | −10 | +10 |
| Bilardo hilebazı | Zekâ ↑ · Dilbaz · Kumarbaz | 40 | −10 | +5 | +20 |
| Barın bekçisi | Yumruk ↑ · Sadık · Alkole düşkün | 70 | 0 | −5 | 0 |
| Eski denizci | Dayanıklı · Soğukkanlı · Gezgin | 60 | 0 | −10 | +5 |
| Boksör, borçlu | Yumruk ↑↑ · Borçlu (Koz) | 50 | +5 | −10 | +20 |
| Kaçakçı çırağı | Bıçak ↑ · İz bırakmaz · Muhbir ağı | 45 | −5 | +5 | +10 |
| Sessiz, işini bilen | Zekâ ↑ · Sözünün eri | 80 | 0 | −5 | −15 |
| Konuşkan ama güvenilir | Dilbaz · Cömert | 75 | −10 | +5 | −5 |
| İşsiz, aç | Dayanıklı · Açgözlü | 55 | +10 | +10 | +25 |
| Polise mahkûm olmuş | Dosyası kirli · Kindar | 35 | +5 | 0 | +15 |

**Değişir:** Maaş, prim, ziyafet ve ortak başarı Sadakati yükseltir; sert konuşma (−5), haraçla ezmek, dosya riski ve ihanet etme (−25) düşürür. Sadakati düşük bir adam **muhbir olabilir**, yüksek bir adam seni yargıçtan bile kurtarır.

---

## 8. EK: KODA GEÇİRME ŞEMASI (öneri)

Her isimli karakter tek bir sözlük (`karakterler.gd` ya da `res://data/karakterler.json`):

```json
{
  "id": "sal_pescatore",
  "ad": "Sal \"The Shark\" Pescatore",
  "rol": "tefeci",
  "fak": "",
  "yas": 54,
  "yer": "Sal the Shark",
  "gorus": -5,
  "gorus_dokum": [["Babanla eski ilişkisi", 10], ["Borç", -15]],
  "sadakat": 0,
  "yumruk": 25, "bicak": 30, "zeka": 85,
  "stres": 25, "dosya": 15,
  "oz": ["hesapci", "acgozlu", "sozunun_eri", "soguk_kanli"],
  "direnc": {"ikna": -5, "korku": -20, "rusvet": 10},
  "sir": "ashworth_ortak",
  "koz": null,
  "hikaye": "..."
}
```

**Kodda zaten var:** adam statları (`yumruk/bicak/zeka/sadakat/silah/gorev`), aile üyeleri (`rutbe`, `iliski`, `hp`, `isabet` → `oyun.gd`), oyuncu özellikleri (`kisisel.gd → OZ`), beceriler (`yetenek.gd`: `ikna`, `korku`, `pazarlik`, `sokak`), borç sistemi (`borc.gd`).
**Eklenmesi gerekenler:** `gorus_dokum` listesi, `direnc` alanı, `sir/koz` sistemi, sabit isimli kadro (şu an isimler rastgele), karakter kartı arayüzü (GDD 22.1: "oyunun ana ekranı karakter kartıdır").

### Önerilen sıra
1. Kadroyu sabitle: aile üyelerine bu kitapçıktaki isimleri ver (`oyun.gd → uye_yarat`).
2. Karakter kartı paneli: portre (profil çerçevesi), Görüş dökümü, özellikler, direnç.
3. Konuşma hesabını `karsilasma.gd` ve `kartlar.gd` seçeneklerine bağla (ikna/korku şansı karakterin direncini okur).
4. Portre artwork'leri: her isimli karakter için bir `assets/ui/karakter/<id>.png` (aynı çizim stili).
