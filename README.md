# Kara Kalem

> 1920'ler, Yasak dönemi. Yeni bir şehir, bir daire, sıfırdan bir hayat. Ne olacağın sana kalmış.

**Kara Kalem**, Yasak dönemi Amerikası'nda geçen, 3B haritalı bir suç / işletme yönetimi oyunudur. Şehirde yürürsün, binalara girersin, adam tutarsın, işyerlerini ele geçirir ya da dürüstçe büyütürsün. Mafya, yozlaşmış polis ve rakip esnaf, başarılı olan herkese er ya da geç el atar. Asıl oyun, bu baskı altında kendi çizgini korumaktır.

> **Durum: erken geliştirme (alfa).** Oynanabilir, ama bitmemiş. Hatalar, eksik sistemler ve yer tutucu içerik var.

---

## İndir ve oyna (Windows)

**[⬇ KaraKalem.zip'i indir](https://github.com/husnytarik/kara-kalem/releases/latest/download/KaraKalem.zip)**  ·  [Tüm sürümler](https://github.com/husnytarik/kara-kalem/releases)

1. Zip'i bir klasöre çıkar.
2. `KaraKalem.exe`'yi çalıştır. Kurulum gerekmez.
3. Oyun **tam ekran** açılır. `F11` ile pencere / tam ekran arasında geçersin.

Windows SmartScreen "bilinmeyen yayıncı" uyarısı verebilir; exe imzasızdır. "Ek bilgi → Yine de çalıştır" ile açabilirsin. İstersen kaynaktan kendin de derleyebilirsin (aşağıda).

### Kontroller

| Tuş / fare | İşlev |
|---|---|
| Sol tık | Yere: yürü · Binaya: gir · Gruba: yanına git |
| Sağ tık | Bina ya da adam bilgisi (basılı tutup sürükle: kamerayı döndür) |
| Tekerlek | Yakınlaş / uzaklaş |
| `WASD` | Kamerayı kaydır · `C`: karakterde ortala |
| `Boşluk` | Duraklat · `1` `2` `3`: oyun hızı |
| `T` Adamlar · `F` Defter · `B` Bölgeler · `H` Eve git | Paneller |
| `V` | Sis aç / kapa |
| `F6` / `F9` | Kaydet / yükle |
| `F11` | Tam ekran aç / kapa |

---

## Dünya

Şehir altı bölgeden oluşur, her birinin kendi karakteri, ailesi ve işyerleri vardır:

| Bölge | Havası |
|---|---|
| **Southside** | İşçi mahallesi. Meyhane, bakkal, berber, boks salonu. Oyunun evi. |
| **Eastside** | Göçmen sokakları, pazar yeri, sinagog, matbaa, terzi atölyeleri. |
| **Hilltop** | Zenginlerin tepesi: kulüp, galeri, kuyumcu, köşkler. |
| **Downtown** | Banka, belediye, gazete, karakol, mahkeme. Paranın ve siyasetin merkezi. |
| **The Flats** | Fabrikalar, dökümhane, demiryolu deposu, hurdalık. |
| **Docks** | Liman, gümrük, sendika, kaçakçılık ve gemi işleri. |

Şehir sen yokken de yaşar: saat işler, mevsimler değişir, gün doğup batar, rakipler hareket eder. Sokaklarda yayalar yürür, arabalar şeritlerinde akar, polis devriye gezer, rakip ekipler birbirini kollar.

### Güçler

- **Marchetti Family**: disiplinli İtalyan ailesi (Flats / Docks).
- **O'Brien Çetesi**: kavgacı İrlandalı çete (Eastside).
- **Belediye Makinesi**: temiz görünüşlü siyasi örgüt (Downtown / Hilltop).
- **Polis**: devriyeler, dosya, arama emri; bir kısmı yozlaşmış.
- **Esnaf ve mahalle**: seni sevebilir, korkabilir ya da seni polise bildirebilir.

### Yaşayan sakinler

Şehirde **36 isimli sakin** yaşar (bölge başına 6): bakkal Rosa, berber Gus, Peder Brennan, komiser Brogan, gümrük memuru Pete... Her biri hep **aynı bölgede, aynı saat aralıklarında, aynı işyerlerinde** görünür; gün içinde işine, öğle yemeğine, akşam mekânına gider, gece evine çekilir. Üzerine tıklayınca işini, kısa notunu ve günlük rutinini görürsün. Şimdilik oyun mekaniğine etkileri yoktur; dedikodu ve görev kaynağı olmaları hedeflenir.

---

## Mevcut mekanikler

**Hareket ve harita**
- 3B şehir, yol ağı üzerinde A* ile yürüme, bina hover'ı (ince altın çerçeve) ve bina üstü ikonlar
- Gün/gece, mevsimler, hız kontrolü; yaya, araba ve devriye trafiği
- Haritadaki karakterler ince figürlerdir; yaya ve arabaların üzerine gelince isim çıkar

**Karakter ve ilerleme**
- Güç, Nişan, Zekâ, Karizma; beceri ağacı ve 24 huy (davranışlarınla gelişir, kullanılmazsa solar)
- Açlık, yorgunluk, stres, sıkıntı, hastalık
- Ün, korku ve iyilik gibi toplumsal itibar ölçüleri
- Meslekler (taksi şoförü ve diğerleri): mesai, maaş, beceri, kovulma

**Ekonomi**
- Binalar: satın alma, gelir, haraç toplama, işletme (fiyat, personel, itibar, olaylar)
- Bodrum içki imalatı, gizli oda, stok; aklama (çamaşırhane gibi cepheler) ve vergi şüphesi
- Borç ve tefeci: aylık taksit, faiz, kaçırırsan oyun biter
- Arabalar (Ford Model T, Buick, Packard): yakıt, arıza, bakım, hız

**Adamlar ve silahlar**
- Adam pazarı (bar, bilardo, boks salonu, dernek), görev atama, yaralanma
- Yumruktan Colt M1911 ve pompalıya dönem silahları
- Savaş: 3B sahnede çatışma ya da otomatik çözüm

**Yasa ve çatışma**
- Polis dosyası ve dikkat, arama emri, baskın, rüşvet
- Aileler arası gerginlik, savaş ve evde güvenli bölge
- Polisin yasadışı ekipleri kovalaması, mafya gruplarının birbirine saldırması
- Karar kartları ve dört yükseliş yolu (Yasal, Gölge, Korku, Kulis); dönem olayları (reform, skandal, çete savaşı...)

**Oyun sonları**
- Dürüst iş imparatorluğu · Belediye başkanlığı · Bölge hâkimiyeti · Ya da dosyan dolar, borcun batar, adamın düşer.

---

## Hedeflenen yön

Oyun, yalnızca mafya oyunu olmaktan çıkıyor.

- **Sabit başlangıç:** Herkes **havaalanında** başlar. Elinde dedenden kalma bir daire, alt üst olmuş bir geçmiş ve sıfırdan bir hayat vardır. Köken seçimi kalkıyor. Kim olacağına sen karar verirsin (GTA Vice City tadında).
- **Kendi yolun:** Tüccar ol, dükkân zinciri kur, bir mahallenin esnafı ol ya da suça bulaş. Hiçbir yol seni zorlamaz.
- **Başarının bedeli:** Ne yaparsan yap büyüdükçe dikkat çekersin. Mafya "koruma" ister, yozlaşmış polis arama ve ruhsat bahanesiyle gelir, rakip esnaf sabotaj yapar. Ödersin, pazarlık edersin, ittifak ararsın ya da silahlanırsın. Çizgini korumak oyunun sürekli kararıdır.
- **Sea Dogs II esini:** Serbest rol, güçlerle ayrı ayrı ilişki, beceri ve rütbe, taverna söylentilerinden doğan görevler.
- **Daha fazla yaşayan şehir:** Sakinlerin binaların içinde görünmesi, dedikodu ve görev kaynakları, haftalık rutinler, hava durumuna bağlı davranış.
- **Küçük sürprizler:** Dikkatli oyuncuların keşfedeceği gizli detaylar ve yumurtalar (easter egg). Ana oyunu bölmeyecek.
- **Cila:** Ses ve müzik, animasyonlu karakterler, iç mekân görünümleri, daha fazla yan görev.

Ayrıntılı notlar için: [GDD.md](GDD.md) (tasarım dokümanı), [TASARIM_YON.md](TASARIM_YON.md) (güncel yön), [KARAKTERLER.md](KARAKTERLER.md) (karakter kitapçığı taslağı).

---

## Kaynaktan derleme

Gereksinim: [Godot 4.7](https://godotengine.org/) (Forward Plus).

```bash
git clone https://github.com/husnytarik/kara-kalem.git
cd kara-kalem/godot
godot --editor --path .        # editörde aç
godot --path .                 # doğrudan çalıştır
```

Windows exe için: Godot'ta *Project → Export → Windows Desktop* ön ayarı hazırdır (`godot/export_presets.cfg`).

`prototype/` klasörü oyunun ilk web prototipidir (kural testleri ve tasarım doğrulaması için).

## Notlar

- Oyun görselleri (bina fotoğrafları, paneller, ikonlar) yapay zekâ yardımıyla üretilmiştir.
- Kod geliştirmesi yapay zekâ yardımıyla yapılmaktadır.
- Oyundaki kişiler, işletmeler ve olaylar kurgusaldır; gerçek kişi ve kurumlarla ilgisi yoktur.
- Henüz bir lisans seçilmedi; tüm haklar saklıdır. Lisans, oyun olgunlaştığında belirlenecek.
