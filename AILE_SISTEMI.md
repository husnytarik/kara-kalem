# Kara Kalem — Aile Sistemi (hanedan, gelenekler, özellikler, beceriler, etkenler)

Bu belge [TASARIM_YASAM.md](TASARIM_YASAM.md)'deki "özgür yaşam" fikrinin **aile** bölümüdür. Rakamlar ilk denge önerisidir; oynarken ayarlanır. Hiçbir şey koda geçmedi.

## 0. Temel fikir
- Oyuncu tek bir kişi değil, bir **hanedanın** (ailenin) o anki başıdır. Oyun bir kişinin ölümüyle bitmez: **"Devam edelim mi?"** diye sorulur.
  - **Evet** → bir **mirasçı** seçilir, oyun onunla sürer. Aile servetinin, borcunun, düşmanlarının ve gelenek bonuslarının tamamı devredilir.
  - **Hayır** → "hayat özeti" ekranı (unvanın, serveti, çocukların, kimlerin hatırladığı) ve oyun biter.
- Aile, CK3'teki hanedan gibi bir **kültür kimliği** taşır: köken, inanç, değerler, gelenekler. Bunlar bonus **ve** bedel verir (hiçbir seçim bedelsiz değildir).
- Her seçim, [üç hayatı](TASARIM_YASAM.md) (Baba / İş adamı / Rezil haraççı) farklı yönlere iter.

### Etkileşim şeması
```
Aile kültürü (köken + inanç + gelenekler)      -> aileye ait kalıcı bonus/bedel
        |
Karakter (özellikler + beceriler + statlar)    -> kişiye ait; çocuğa kısmen geçer (kalıtım)
        |
Etkenler (hasta, yaralı, borçlu, aranıyor...)  -> geçici ya da kalıcı durumlar
        |
Kazanımlar (unvan, anı, miras)                 -> ailenin tarihi; yeni gelenek/özellik açabilir
```

## 1. Etki sözlüğü (bütün listelerde ortak)
Her bonus/bedel aşağıdaki anahtarlardan biridir. Yüzdeler çarpandır; "+" iyi, "−" kötü yönde değil, **değerin kendi yönünde** (maliyet −% = ucuzlar).

| Grup | Anahtar | Anlamı |
|---|---|---|
| **Adam / örgüt** | `adam_maliyet` | adam kiralama bedeli |
| | `adam_secenek` | karşına çıkan aday sayısı/niteliği |
| | `sadakat` | adamların sadakati (darbe riskini azaltır) |
| | `adam_kayip` | savaşta/olayda ölen adam oranı |
| **Para** | `gelir_mesru` | meşru işletme geliri |
| | `gelir_haram` | haraç, kaçak, tefecilik geliri |
| | `gider` | aylık sabit giderler |
| | `rusvet` | rüşvet bedeli (polis/yargıç/siyasetçi) |
| | `aklama` | kara para aklama verimi |
| | `borc_faiz` | faiz yükü |
| **Ticaret** | `alkol_maliyet` | içki ticareti masrafı |
| | `alkol_gizli` | içki ticaretinde gizlilik (yüksek = az yakalanır) |
| | `kumar_gelir`, `fuhus_gelir` vb. | ilgili suç kolunun verimi |
| | `mal_fiyat` | alım fiyatı |
| **Güç** | `isabet`, `yakin_hasar`, `can` | savaş |
| | `silah_fiyat` | silah/mermi bedeli |
| | `kacis` | kovalamadan sıyrılma |
| **Sosyal** | `ikna`, `korku`, `sevgi`, `saygi` | ilgili ün eksenine kazanç hızı |
| | `pazarlik` | her tür pazarlıkta |
| | `dikkat` | fark edilme hızı (yüksek = polis/federal erken görür) |
| | `gizlilik` | genel gizlilik |
| **Aile** | `dogurganlik`, `cocuk_sans` | çocuk sahibi olma |
| | `cocuk_gelisim` | çocukların beceri/özellik kazanma hızı |
| | `miras_kayip` | devirde servet/itibar kaybı |
| | `evlilik_secenek` | uygun eş seçeneği |
| **Sağlık / ruh** | `iyilesme`, `stres`, `yaslanma` | sağlık, ruh, ömür |
| **Dış** | `polis_ilgi`, `federal_ilgi`, `ilce_destek` | dış güçlerin tavrı |

## 2. Kültürel kuruluş (oyun başında + mirasçıda yeniden)
Üç katman. Hepsi aile paneli ("Aile" sekmesi) altında.

### 2.1 Köken (kültürel kök) — 1 seçim
Bonuslar ufak; asıl etkisi hangi geleneklerin **ucuz** olduğunu belirlemesi.
| Köken | Bonus | Bedel | Ucuz gelenekler |
|---|---|---|---|
| **İrlandalı göçmen** | `adam_secenek` +%15, `sadakat` +%8 | `rusvet` +%10 (polis saymaz) | Kan Bağı, Meyhane Ocağı, Sokak Kavgacıları |
| **İtalyan / Sicilyalı** | `korku` +%12, `sadakat` +%10 | `dikkat` +%10 | Aile Önce, Sessizlik Yemini, Don'a Saygı |
| **Yahudi tüccar ailesi** | `gelir_mesru` +%10, `pazarlik` +%12 | `adam_secenek` −%10 | Hesap Kitap, Toplum Dayanışması, Bilgi Ağı |
| **Eski Amerikalı (WASP)** | `rusvet` −%10, `ilce_destek` +%8 | `adam_maliyet` +%10, `sevgi` −%5 | Köklü Soy, Siyaset Bağı, Kulüp Kültürü |
| **Doğu Avrupalı işçi** | `can` +%8, `gider` −%8 | `saygi` −%5 | Emek Onuru, Sendika Ruhu, Sert Kış |
| **Zenci Güney göçmeni (Great Migration)** | `sevgi` +%10, `ilce_destek` +%10 | `polis_ilgi` +%12 | Cemaat Bağı, Müzik ve Gece, Mahalle Kalkanı |
| **Çinli / Uzakdoğu** | `gizlilik` +%12, `kacis` +%6 | `adam_secenek` −%10 | Sessiz Aile, Hesap Kitap, Kapalı Kapı |
| **Dışarıdan gelen, kökü belirsiz** | hiçbir bonus yok, hiçbir bedel yok | — | (tüm gelenekler normal fiyat) — varsayılan, "havaalanından gelen" |

### 2.2 İnanç — 1 seçim
Aile inancı toplumdaki duruşunu ve bazı ticaretleri etkiler.
| İnanç | Bonus | Bedel |
|---|---|---|
| **Dindar (Katolik/Protestan/Yahudi vb. cemaat)** | `adam_maliyet` −%15, `adam_secenek` +%15, `sevgi` +%10 | `alkol_maliyet` +%25, `alkol_gizli` −%15, `kumar_gelir` −%20 |
| **Ilımlı inanç** | `stres` −%5, `ilce_destek` +%5 | yok |
| **İnançsız / dünyevi** | `kumar_gelir` +%10, `alkol_gizli` +%8 | `sevgi` −%5, `sadakat` −%5 |
| **Batıl / folklorcu** | `kacis` +%5, `stres` −%8 | `gelir_mesru` −%5 |
| **İnançla dolu ama yüzeysel** | `rusvet` −%10 (ruhban bağı) | `saygi` −%5 (ikiyüzlü diye anılır) |

### 2.3 Değerler (bir kez seçilir, aile kimliği) — 2 seçim
Her değer çifti zıt uçlar. Seçtiğin uç, ailenin "kuralı" olur (dışına çıkan adam/çocuk `skandal` kazanır).
| Değer çifti | Sol uç | Sağ uç |
|---|---|---|
| Namus ↔ Çıkar | `saygi` +%10, `sevgi` +%5 / `gelir_haram` −%5 | `gelir_haram` +%10 / `saygi` −%5 |
| Sert ↔ Merhametli | `korku` +%12 / `sevgi` −%10 | `sevgi` +%12 / `korku` −%10 |
| Gelenek ↔ Yenilik | `sadakat` +%8 / `gelir_mesru` −%5 | `gelir_mesru` +%8 / `sadakat` −%8 |
| Sessiz ↔ Gösterişli | `dikkat` −%10 / `saygi` −%5 | `saygi` +%10 / `dikkat` +%10 |

## 3. Aile gelenekleri
Aile başlangıçta **3 gelenek slotuna** sahip; **Hanedan İtibarı** ve kazanımlarla (bölüm 7) slot sayısı 6'ya kadar çıkar. Gelenek listesi aşağıda. Her biri: **Bonus / Bedel / Çatışır** (aynı anda seçilemeyen). Hepsi bedelli, hiçbiri bedava değil.

### Kutsal ve cemaat
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Dindar Hane** | `adam_maliyet` −%15, `adam_secenek` +%15 | `alkol_maliyet` +%25, `alkol_gizli` −%15 | Meyhane Ocağı |
| **Cemaat Bağı** | `ilce_destek` +%12, `sevgi` +%8 | `dikkat` +%5 (kilise önünde herkes bilir) | Sessiz Aile |
| **Vaftiz Babası Geleneği** | `sadakat` +%12 (çocuk vaftizi ile bağ), `evlilik_secenek` +%10 | `gider` +%6 (her vaftiz hediyesi) | — |
| **Hayırsever Hane** | `sevgi` +%15, `saygi` +%6 | `gider` +%10 (düzenli bağış) | Haraç Soyu |
| **Cenaze Onuru** | `saygi` +%10, `sadakat` +%8 | her ölümde `gider` +%15 (görkemli cenaze) | — |

### Kan ve sadakat
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Kan Bağı** | `sadakat` +%15, `adam_kayip` −%8 | `adam_secenek` −%10 (yabancıdan çekinir) | Açık Kapı |
| **Aile Önce** | `sadakat` +%12, `cocuk_gelisim` +%10 | iş için aileyi riske atmak `skandal` | Hesap Kitap |
| **Don'a Saygı** | `korku` +%10, darbe riski −%20 | `adam_secenek` −%8, yeni fikre kapalı | Açık Kapı |
| **Açık Kapı** | `adam_secenek` +%20, `adam_maliyet` −%8 | `sadakat` −%10 | Kan Bağı, Don'a Saygı |
| **İntikam Yemini** | `korku` +%12, düşmana savaşta `isabet` +%5 | `gerginlik` yükselmesi +%25 (kolay kavga), `dikkat` +%8 | Barışçıl Hane |

### Ticaret ve para
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Hesap Kitap** | `gelir_mesru` +%10, `borc_faiz` −%10 | `korku` −%5 (yumuşak görülür) | Aile Önce |
| **Meyhane Ocağı** | `alkol_maliyet` −%15, `alkol_gizli` +%10 | `sevgi` −%5 (dindarlar uzak durur) | Dindar Hane |
| **Tüccar Soyu** | `mal_fiyat` −%10, `pazarlik` +%10 | `adam_secenek` −%5 | Haraç Soyu |
| **Haraç Soyu** | `gelir_haram` +%12 (haraç ve tefecilik) | `sevgi` −%8, `dikkat` +%8 | Tüccar Soyu, Hayırsever Hane |
| **Sessiz Para** | `aklama` +%15 | `gelir_haram` −%5 | Gösterişli Zenginlik |
| **Gösterişli Zenginlik** | `saygi` +%12, `evlilik_secenek` +%12 | `dikkat` +%12, `federal_ilgi` +%10 | Sessiz Para, Sessiz Aile |
| **Sendika Ruhu** | `adam_maliyet` −%10, grev riski −%15 | `gelir_mesru` −%5 | — |

### Güç ve savaş
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Silah Geleneği** | `silah_fiyat` −%12, `isabet` +%5 | `polis_ilgi` +%8 | Barışçıl Hane |
| **Sokak Kavgacıları** | `yakin_hasar` +%12, `can` +%6 | `dikkat` +%6 | — |
| **Barışçıl Hane** | `sevgi` +%10, `polis_ilgi` −%10 | `korku` −%10, `isabet` −%4 | Silah Geleneği, İntikam Yemini |
| **Sert Kış** | `can` +%10, `stres` −%6 | `gider` +%4 | — |

### Gizlilik ve bilgi
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Sessizlik Yemini (Omertà)** | `muhbir` riski −%25, `gizlilik` +%12 | `sevgi` −%5 | Açık Kapı |
| **Sessiz Aile** | `dikkat` −%12, `gizlilik` +%8 | `saygi` −%6, `evlilik_secenek` −%8 | Gösterişli Zenginlik, Cemaat Bağı |
| **Bilgi Ağı** | `ipucu` +%20 (görev/olay erken sezilir) | `gider` +%8 (muhbir maaşı) | — |
| **Kapalı Kapı** | düşman casusu/ajanı −%20 | `adam_secenek` −%8 | Açık Kapı |

### Siyaset ve toplum
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Siyaset Bağı** | `rusvet` −%12, `federal_ilgi` −%8 | seçim zamanı `gider` +%10 | — |
| **Köklü Soy** | `saygi` +%10, `ilce_destek` +%8 | `adam_maliyet` +%8 (kibir) | Göçmen Ruhu |
| **Göçmen Ruhu** | `adam_secenek` +%12, `sevgi` +%6 | `ilce_destek` −%4 (elit uzak durur) | Köklü Soy |
| **Mahalle Kalkanı** | mahalle ihbarı −%20, `ilce_destek` +%10 | `gider` +%5 | — |

### Aile hayatı
| Gelenek | Bonus | Bedel | Çatışır |
|---|---|---|---|
| **Kalabalık Sofra** | `dogurganlik` +%20, `sevgi` +%6 | `gider` +%10 | — |
| **Çocuk Okur** | `cocuk_gelisim` +%12 (zeka/ikna), eğitimli çocuk | `gider` +%8 | Erken Çalışan |
| **Erken Çalışan** | çocuk 14 yaşında `gelir` getirir, `cocuk_gelisim` (beceri) +%8 | çocuk `stres` +%10, `sevgi` −%4 | Çocuk Okur |
| **Büyükler Konseyi** | `miras_kayip` −%15, darbe/kavga erken çözülür | karar süresi +%15 | — |
| **Soyağacı Yemini** | mirasçı seçimi sadece kanından, `sadakat` +%10 | evlatlık/yabancı varis yasak | Açık Kapı |

## 4. Karakter özellikleri
Her kişinin (oyuncu, eş, çocuk, adam) **en çok 5 özelliği** olur. Türler: **doğuştan** (D), **çocuklukta** (Ç), **edinilen** (E), **kalıtsal** (K, çocuğa %30–60 şansla geçer). Zıt çiftler birlikte olamaz.

### 4.1 Kişilik (zıt çiftler; çocuklukta şekillenir)
| Özellik | Etki | Zıttı |
|---|---|---|
| **Cesur** (K) | `isabet` +%4, korkuya direnç, `stres` −%8 | Korkak |
| **Korkak** | `kacis` +%8, `stres` +%6, `saygi` −%5 | Cesur |
| **Sabırlı** | `gelir_mesru` +%4, `pazarlik` +%4 | Sabırsız |
| **Sabırsız** | savaşta hızlı karar, `gelir_mesru` −%3, hata +%5 | Sabırlı |
| **Hırslı** (K) | `gelir` +%5, `dikkat` +%5, ihanet riski +%8 | Kanaatkâr |
| **Kanaatkâr** | `stres` −%8, `gider` −%5 | Hırslı |
| **Cömert** | `sevgi` +%10, `gider` +%6 | Cimri |
| **Cimri** | `gider` −%8, `sevgi` −%8 | Cömert |
| **Sadık** (K) | `sadakat` +%12 | İhanetkâr |
| **İhanetkâr** | `ikna` +%5, `sadakat` −%12, gizlice ihanet riski | Sadık |
| **Merhametli** | `sevgi` +%10, `korku` −%6 | Acımasız |
| **Acımasız** | `korku` +%12, `sevgi` −%10, `stres` −%4 | Merhametli |
| **Zeki** (D,K) | `ikna` +%5, `pazarlik` +%5, beceri kazanma +%10 | Yavaş |
| **Yavaş** | beceri kazanma −%10, `stres` −%3 | Zeki |
| **Çekici** (D,K) | `ikna` +%8, `evlilik_secenek` +%10 | Sevimsiz |
| **Sevimsiz** | `ikna` −%6, `korku` +%4 | Çekici |
| **Dürüst** | `sevgi` +%6, `rusvet` bedeli +%8 (kimse güvenmez) | Düzenbaz |
| **Düzenbaz** | `pazarlik` +%8, `sevgi` −%6, `gizlilik` +%5 | Dürüst |

### 4.2 Doğuştan yetenekler (D / K)
| Özellik | Etki |
|---|---|
| **Güçlü** | `yakin_hasar` +%12, `can` +%8 |
| **Çevik** | `kacis` +%10, `isabet` +%3 |
| **Nişancı gözü** | `isabet` +%8 |
| **Hesap dehası** | `gelir_mesru` +%8, `aklama` +%8 |
| **Doğuştan lider** | `sadakat` +%10, `adam_secenek` +%10 |
| **Hafıza** | beceri körelme −%30 |
| **Şans yıldızı** | olayların kötü sonucu −%10 |
| **Demir bünye** | hastalık/yara iyileşme +%20 |
| **Sezgisel** | `ipucu` +%10, tuzağı sezme +%10 |
| **Müzik kulağı** | gece kulübü/eğlence yeri geliri +%10 |

### 4.3 Kusurlar ve zayıflıklar (D / E)
| Özellik | Etki |
|---|---|
| **Cılız** | `can` −%8, `yakin_hasar` −%8 |
| **Titrek el** | `isabet` −%8 |
| **Kısa görüşlü** | uzak mesafede `isabet` −%10 (gözlükle azalır) |
| **Alkolik** (E) | `stres` −%10 ama her ay `gider` +, ağır hata riski +%12 |
| **Kumar düşkünü** (E) | `kumar_gelir` +%6 ama `borc_faiz` +%15, yüksek paraya el atma |
| **Afyon bağımlısı** (E) | sağlık, `isabet` −%10, `gizlilik` −%10 |
| **Kibirli** | `saygi` +%6, `sevgi` −%8, hata kabul etmez |
| **Öfkeli** | `korku` +%8, ani kavga riski +%12 |
| **Paranoyak** (E) | `sadakat` −%8, ama darbe/muhbiri erken sezme +%8 |
| **Vicdanlı** | `stres` +%8 (kötü işte), `sevgi` +%6 |

### 4.4 Edinilen özellikler (olaylardan, kazanımlardan)
| Özellik | Nasıl edinilir | Etki |
|---|---|---|
| **Gaddar** | çok kişiyi infaz/işkence | `korku` +%15, `sevgi` −%15 |
| **Kurtarıcı** | hayat kurtarma, hayır | `sevgi` +%10, `saygi` +%8 |
| **Savaş gazisi** | büyük çatışmadan sağ çıkmak | `isabet` +%5, `stres` +%5 |
| **Hapis çıkışlı** | tutukluluk | `korku` +%6, `polis_ilgi` +%10, kapana kısılma korkusu |
| **Soygun ustası** | çok vurgun | `kumar_gelir` +%8, soygun planı verimi +%12 |
| **Kayıp çocuk acısı** | çocuğun ölümü | `stres` +%10, `gelir` −%3 (uzun süre) |
| **Dul** | eşin ölümü | `evlilik_secenek` +, `stres` +%6 |
| **Kara koyun** | ailenin değerine ihanet | `saygi` −%12, aileden dışlanma riski |
| **Efsane** | büyük kazanımlar zinciri | `saygi` +%15, `dikkat` +%10 |
| **Rezil** | art arda başarısızlık | `saygi` −%15, `korku` −%10 |
| **Dedikoducu** | çok sohbet | `ipucu` +%10, `gizlilik` −%8 |
| **Hayırsever** | çok bağış | `sevgi` +%12, `rusvet` bedeli −%5 |

## 5. Beceriler
Mevcut beceri ağacı korunur ([yetenek.gd](godot/scripts/core/yetenek.gd): puan 0–100, seviye = puan/20, her eylem becerileri besler ve kullanılmayan körelir). Aşağıdaki **iki yeni dal** eklenir; mevcut dallar aynı kalır.

### 5.1 Mevcut (3 dal, 13 beceri)
- **Silah:** Nişancılık, Tabanca ustalığı, Uzun namlu, Hafif otomatik, Hızlı el, Yakın dövüş, Silah bakımı.
- **Yol & Direksiyon:** Direksiyon, Kaçış sürüşü.
- **Sokak & Söz:** İkna, Gözdağı, Pazarlık, Sokak aklı.

### 5.2 Yeni dal — **İş ve Ticaret**
| Beceri | Üst | Etki |
|---|---|---|
| **Muhasebe** | — | `gelir_mesru` +, hata/dolandırılma −, vergi dairesi önünde `dikkat` −. |
| **Aklama** | Muhasebe 15 | `aklama` +, kara paranın izi kaybolur. |
| **Tedarik** | Muhasebe 10 | `mal_fiyat` −, zincir kurma, stok hatası −. |
| **Yönetim** | Muhasebe 15 | personel/adam başına verim +, şirket büyütmede ceza −. |
| **Faiz ve Borç** | Muhasebe 20 | tefecilik kolu: `borc_faiz` ayarı, alacak tahsil verimi +. |
| **Kaçakçılık** | Tedarik 15 | `alkol_maliyet` −, `alkol_gizli` +, rota/depo bilgisi. |
| **Gösteri ve Gece** | — | gece kulübü/bar/eğlence gelirleri +, müşteri çekme. |

### 5.3 Yeni dal — **Yönetim ve Aile**
| Beceri | Üst | Etki |
|---|---|---|
| **Liderlik** | İkna 15 | `sadakat` +, `adam_secenek` +, ekip morali. |
| **Diplomasi** | İkna 20 | gerginlik azaltma, ittifak/barış anlaşması başarı +. |
| **Gizli İlişkiler** | Sokak aklı 15 | polis/yargıç/siyasetçi ile bağ kurma, `rusvet` −. |
| **İstihbarat** | Sokak aklı 20 | muhbir ağı, `ipucu`, ihaneti erken sezme. |
| **Eğitim (Çocuk)** | Liderlik 10 | `cocuk_gelisim` + (mirasçıyı eğitme). |
| **Tören ve Temsil** | İkna 10 | düğün, cenaze, parti etkinliklerinden itibar kazancı +. |
| **Hukuk** | Muhasebe 10 | dava/tutuklamada ceza −, avukat bedeli −. |
| **Şifa (İlkyardım)** | — | yara/hastalıkta `iyilesme` +, adamların ölümü −. |

### 5.4 Kalıtım
Çocuklar, ebeveynin en yüksek **2 becerisinden** birini "ilk puan" olarak alır (%25–50 oranında). Çocuğun doğuştan özelliği ve ailenin gelenekleri (Çocuk Okur, Erken Çalışan) hangi dalda gelişeceğini belirler.

## 6. Etkenler (durumlar)
Etken = bir kişiye ya da aileye **bağlı, süreli ya da kalıcı** durum. Kaynağı olay/hastalık/yasal sistemdir. Kalıcı olanlar özellik gibi görünür (kör, topal); geçici olanlar bir süre sonra geçer ya da tedavi edilir.

### 6.1 Beden (hasta, yaralı, engelli)
| Etken | Süre | Etki | Tedavi |
|---|---|---|---|
| **Yaralı (hafif)** | 3–7 gün | `can` −%10, `isabet` −%5 | dinlenme, ilkyardım |
| **Yaralı (ağır)** | 2–6 hafta | `can` −%35, hareket yavaş, görev yapamaz | hastane, doktor ücreti |
| **Kanama** | savaşta anlık | süre içinde ölüm riski | ilkyardım/doktor |
| **Kırık** | 3–5 hafta | `kacis` −%30, `yakin_hasar` −%25 | alçı, dinlenme |
| **Hasta (grip, zatürre)** | 5–14 gün | `can` −%15, `stres` +, yorgunluk hızlı | ilaç, dinlenme |
| **Verem (TB)** | uzun, ölümcül olabilir | `can` −%25, öksürük (gizlilik −%10), yayılır | sanatoryum, uzun tedavi |
| **İspanyol Gribi / salgın** | olay tabanlı (1918–20 dalgası) | tüm ailede hastalık riski, işletme geliri −%20 | karantina, doktor |
| **Zehirlenme** | 2–5 gün | `can` −%25, görev yapamaz | panzehir/mide yıkama |
| **Kör (tek göz)** | kalıcı | `isabet` −%20, uzak görüş azalır | yok (cerrahi proteze yardımcı) |
| **Kör (iki göz)** | kalıcı | silah kullanımı kapalı, dışarı yürümek yardım ister | yok; `Hesap dehası` gibi özellik açar |
| **Sağır / duyma kaybı** | kalıcı | sezgi/ses −, savaşta yön bulma güç | yok |
| **Topal (bacak kaybı)** | kalıcı | hız −%25, `kacis` −%30 | baston/protez |
| **Kol kaybı** | kalıcı | iki elli silahlar kapalı, `yakin_hasar` −%30 | protez, uyum |
| **Yaşlılık** | 55+ yaşta artan | `can` −, `yaslanma` +, ölüm riski | yok |
| **Bağımlı (alkol/afyon)** | kalıcı/azalan | bağımlılık özelliği ile aynı | tedavi, sanatoryum |

### 6.2 Zihin
| Etken | Süre | Etki |
|---|---|---|
| **Yüksek stres** | süresiz | `isabet` −, hata +, uyku bozukluğu |
| **Travma (savaş şoku)** | haftalarca | çatışmaya girmede ceza, kabus |
| **Yas** | 2–4 hafta | `stres` +, `gelir` −%5 |
| **Aşk** | süresiz | `stres` −%5, bazı kararlar akıl dışı |
| **Öfke nöbeti** | kısa | `korku` +, kontrol kaybı riski |
| **Cesaret (uyuşmuş)** | tek savaş | `isabet` +%5 (içki/yüksek adrenalin) |

### 6.3 Hukuk ve toplum
| Etken | Süre | Etki |
|---|---|---|
| **Aranıyor** | `arama` seviyesine bağlı | polis kovalar, `dikkat` +, evde güvenli |
| **Tutuklu** | hüküm süresi | görevler/iş yok; avukat ve rüşvetle kısalabilir |
| **Hapis** | ay/yıl | kişi çıkar; gelir yok, `saygi`/`korku` hapis tecrübesine göre değişir |
| **Şartlı tahliye** | süreli | belirli bölgelerden uzak kalma, polis denetimi |
| **Dava (federal/vergi)** | haftalarca | büyük `gider`, mal varlığı dondurma riski |
| **Skandal** | aylarca | `saygi` −, `evlilik_secenek` −, basın |
| **Dışlanmış** | süresiz | cemaat/mahalle desteği kaybolur |
| **Gözde (halkın sevgilisi)** | süreli | `sevgi` +, polis `ilgi` −, bağış/etkinlik bonusu |
| **Aforoz / lanet** | süresiz | dindar ailelerde `adam_maliyet` +, cemaat tepkisi |

### 6.4 Ekonomi
| Etken | Etki |
|---|---|
| **Borçlu** | `borc_faiz` yükü; vadede mallara el koyma |
| **İflas** | işletmeler kapanır, itibar −, `gelir` 0 |
| **Zengin (patlama)** | `gider` +, `dikkat` +, evlilik/iş teklifleri |
| **Kıtlık / kriz (1929)** | tüm gelirlerde −%20–40, adam sadakati düşer |
| **Kaçak mal elinde** | satış beklerken yakalanma riski |
| **Şantaj altında** | bir sırrı bilen kişi sana baskı yapar |

### 6.5 Aile durumu
| Etken | Etki |
|---|---|
| **Evli** | `stres` −, `evlilik` bağı; eşin aileye katkısı ve riski |
| **Hamile / bebek** | `dogurganlik` kullanımı, `gider` +, ev zorunluluğu |
| **Çocuk hasta** | `stres` +, yüksek tedavi masrafı |
| **Kayıp çocuk / kaçırılma** | görev zinciri, fidye, savaş tetikleyici |
| **Varis anlaşmazlığı** | birden fazla mirasçı adayı varken aile ikiye bölünür |
| **Hanedan şöhreti** | kazanımlarla artar, miras devrinde taşınır |

## 7. Kazanımlar (ailenin tarihi)
Kazanım = bir hedefe ulaşınca açılan kalıcı unvan/anı. Sebep: oyuna *amaç* ve devire *miras* kazandırır. Üç türü var:

### 7.1 Hanedan kazanımları (aile slotu/gelenek açar)
| Kazanım | Koşul | Ödül |
|---|---|---|
| **İlk Kan** | ilk haraç/ilk çatışma | `Sokak Kavgacıları` açık, `Hanedan İtibarı` +1 |
| **Mahalle Sahibi** | tek bir mahallenin hakimi olmak | `Mahalle Kalkanı` açık, slot +1 |
| **Karargâh** | bir karargâh/malikâne edinmek | `Köklü Soy` açık, `Hanedan İtibarı` +2 |
| **Altın Çocuk** | çocuk 18'de `Zeki`+`Doğuştan lider` | `Çocuk Okur`/`Büyükler Konseyi` açık |
| **Üç Kuşak** | torun doğurmak | slot +1, `Hanedan İtibarı` +3 |
| **Sessiz Zafer** | `Dikkat` düşük, `Servet` yüksek | `Sessiz Para` açık |
| **Halkın Dostu** | `Sevgi` çok yüksek | `Hayırsever Hane` açık, slot +1 |
| **Şehrin Efendisi** | tüm rakip aileler yenilmiş | zafer yolu: Hakimiyet |

### 7.2 Kişisel kazanımlar (özellik/unvan)
| Kazanım | Koşul | Ödül |
|---|---|---|
| **Hayatta Kalan** | ağır yaradan sağ çıkmak | `Savaş gazisi` |
| **Efsane** | 5 büyük zafer | `Efsane` özelliği, `saygi` +15 |
| **Dönüşen** | S3'ten (rezil) S2'ye ya da S1'e geçiş | `Yeniden Doğuş`: `stres` −%10, yeni gelenek slotu |
| **Kefaret** | bir yıl bağışla yaşamak | `Hayırsever` |
| **Yeraltı Kralı** | tüm suç kollarında kontrol | `Hesap dehası`/`Doğuştan lider` benzeri özel bonus |

### 7.3 Son kazanım (hayat özeti)
Bölüm 0'daki hayat özeti ekranı bu kazanımları listeler: **hangi unvanlarla anıldın**, **kaç çocuğun var**, **kaç nesil sürdü**, **hangi gelenekler** ve **kimler seni hatırlıyor** (dost/düşman/mahalle). Bu özet bir sonraki nesil için bir "hanedan günlüğü" olarak kalır.

## 8. Miras ve mirasçı seçimi
Ölüm (yaşlılık, hastalık, öldürülme, hapis ömrü) gerçekleşince oyun durur:
1. **"Devam edelim mi?"** diye sorulur. Hayır ise hayat özeti, oyun biter.
2. Evet ise **mirasçı adayları** listelenir: çocuklar (18+ yaşında), eş, kardeş, yeğen, ve (gelenek izin veriyorsa) evlatlık veya sadık bir adam. Aday kartı: özellikler, beceriler, etkenler, aile içindeki sevgi/sadakat.
3. Oyuncu bir mirasçı seçer. **Seçim sonuçları:**
   - Servet, işletmeler, borçlar, düşmanlar ve ittifaklar aynen devreder. `miras_kayip` kadar (%10 başlangıç, Büyükler Konseyi vb. ile azalır) servet/itibar kaybolur.
   - Mirasçı seçilmeyenler **küser** (`sevgi`/`sadakat` ceza, bazen kavga ya da ayrılık).
   - Mirasçı aileden birden fazla kişi arasındaysa **"Varis anlaşmazlığı"** etkeni olabilir.
   - Mirasçı çok genç ise (18'den küçük) bir **vasi** gerekir; vasi başka bir aile üyesidir ve kısa süre aile başı gibi hareket eder.
4. Aile kültürü (köken, inanç, değerler, gelenekler) **devam eder**; yeni aile başı bir gelenek değiştirebilir ama `Hanedan İtibarı` cezası ve geçiş süresi vardır.
5. Hiç mirasçı yoksa: oyun biter (hayat özeti), ya da dışarıdan bir akraba/aday "uzaktan varis" olarak çıkar (düşük itibarla).

## 9. Uygulama notları (koda geçerken)
- Gelenekler, özellikler, becerinin yeni dalları ve etkenler birer **JSON/dict tablo** olacak: `data/gelenek.json`, `data/ozellik.json`, `data/etken.json`. Her satır: `id`, `ad`, `etki: {anahtar: değer}`, `cakisir: [id]`, `aciklama`.
- **Etki toplayıcı:** tek bir `etki("anahtar")` fonksiyonu kişi + aile + etken değerlerini toplar (şu an `yetenek.gd` bunu beceriler için yapıyor; genişler).
- **Mevcut kodla bağlantı:** `profil.gd` (köken/geçmiş eski kodu duruyor), `yol.gd` (yol puanı → ün eksenine), `oyun.gd` (ay/gün tiki), `kartlar.gd` (olay kartları: hastalık, kayıp çocuk, skandal), `isletme.gd` ve `isler.gd` (maliyet çarpanları), `silahlik.gd` (silah fiyatı), `polis.gd` (dikkat/arama).
- **UI:** "Aile" sekmesi: köken/inanç/değerler, gelenek slotları, aile üyeleri (kart), soyağacı, kazanımlar, hanedan günlüğü.
- Sıra önerisi: (1) etki toplayıcı + tablolar, (2) gelenek seçimi ve etkileri (adam maliyeti, alkol, gizlilik gibi mevcut sistemlere bağlanır), (3) özellikler/etkenler (hasta/yaralı), (4) evlilik/çocuk/yaşlanma, (5) miras ve devam sorusu, (6) kazanımlar ve hayat özeti.

## 10. Kararlar ve açık sorular
- **Karar:** takvim süresiz; 1920'de başlar, sabit bir bitiş yılı yok. Dönem olayları (Yasak'ın kalkması 1933, 1929 krizi) takvimde gerçek tarihinde olur ama oyunu bitirmez; oyun, hanedan sürdükçe devam eder.
- Aile başlangıçta kaç gelenek slotu ile başlasın (öneri: 3)?
- **Karar:** eş ve çocuklar konuşulabilir isimli kişiler olacak (sahneli); evde/sokakta yanlarına gidilip diyalog açılır, olaylar sahne olarak oynanır. Diyalog tonu özelliklere, sevgi/sadakat değerine ve etkenlere bağlı.
- **Karar:** 3 gelenek slotuyla başlanır. Gelenek değiştirme bedeli: `Hanedan İtibarı` −1, yeni geleneğin ilk 3 ayında yarım etki (alışma süresi) ve aynı slot 1 yıl tekrar değiştirilemez. Aile başı değişince (miras) ilk değişiklik itibar kaybı olmadan yapılabilir.
- Çocuklar sahneli (konuşma/olay) mı olsun, yoksa yıllık özet kartlarıyla mı ilerlesin?
- Etkenlerin görsel gösterimi: karakter portresinde mi, ayrı bir durum çubuğunda mı?
