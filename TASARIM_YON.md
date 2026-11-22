# Kara Kalem — Yeni Yön (2026-11-22)

## 1. Sabit başlangıç
- Menüde köken / aile / geçmiş seçimi **kalkıyor**. Herkes **havaalanında** başlar.
- Elde: dededen kalan bir daire (Home), havaalanı, alt üst olmuş bir geçmiş, sıfırdan hayat. Vice City tadında; kim olunacağı oyuncunun kararı.
- Karakter yaratma yerine kısa bir açılış: havaalanı → daire anahtarı → ilk gün hedefleri. Stat/geçmiş ilk günlerdeki seçimlerle şekillenir (ne iş yaptığın, kime yaklaştığın).
- Kodda dokunulacak yerler: `profil.gd` (KOKENLER/AILELER/GECMISLER), `menu.gd`, `oyun.gd` başlangıç, `harita.gd` (Home ve Airport yerleri).

## 2. Mafya-merkezli değil, "kendi yolun"
Oyuncu seçebilir:
| Yol | Gelir kaynağı | Baskı kaynağı |
|---|---|---|
| Tüccar / zincir dükkân | mal alım-satım, dükkân kurma, tedarik | haraç, rakip esnaf, ruhsat |
| İşletmeci | bar, lokanta, nalbur, atölye | mafya koruması, yozlaşmış polis, vergi |
| Mahalle adamı | iş, borç, bilgi | tefeci, polis dosyası |
| Suç yolu | mevcut sistem (haraç, adam, silah) | polis, rakip aile |

**Dış baskı** oyuncuyu aksiyona çeker: başarılı olan herkes dikkat çeker. Mafya "koruma" ister, yozlaşmış polis "arama/ruhsat" ister, rakip esnaf sabotaj yapar. Oyuncu: öde, pazarlık et, karşı koy, müttefik bul, ya da silahlan. Çizgisini korumak oyunun sürekli kararıdır.

## 3. Sea Dogs II'den alınacak dersler
(Akella/Bethesda, 2003; kaynak: Wikipedia ve oyun önizlemeleri. Ayrıntılı sistem verisi yoksa seri bilgisine dayanır, doğrulanmadı.)
- **Serbest rol:** tüccar, korsan ya da serbest kaptan; hiçbirine zorlanmazsın. → bizde: tüccar, işletmeci, mahalle adamı, suçlu.
- **Fraksiyon duruşu:** her güçle (İngiliz/İspanyol/…) ilişkin ayrı ölçülür, tek bir "iyi/kötü" yok. → bizde: Marchetti, O'Brien, Belediye, Polis, Esnaf, Mahalle (zaten `gerginlik.gd` / `gorus.gd` var).
- **Beceri puanı + rütbe:** → `yetenek.gd` (ikna, korku, pazarlık, sürücülük).
- **Görevler her yerden:** meyhane/liman söylentisi, valilik görevleri. → bizde: Murphy's Tavern söylentisi, sivil sakinlerden ipucu, kartlarla gelen olaylar.
- **Mürettebat / subay:** → adam kiralama (zaten var).
- **Kara + deniz döngüsü:** → bizde sokak + iç mekân + sürüş.
Yapılmayacak: deniz savaşı kopyası; sadece "rol özgürlüğü + fraksiyon baskısı" alınır.

## 4. Şehir sakinleri (YAPILDI — ilk sürüm)
- `scripts/core/sakinler.gd`: 36 isimli kişi (bölge başına 6). Her biri sabit bölgede, sabit saat aralıklarında, sabit işyerlerinde. Aralık dışında evde (haritada yok).
- Oyun mekaniğine etkisi yok; panel, not ya da kayıt YOK (RAM/dosya şişmesin). Sadece rutin: aynı bölge, aynı saatler, aynı yerler. Üzerine gelince ad + iş.
- Sonraki adımlar: sivillerin binalar içinde görünmesi, sohbet/dedikodu, ses/animasyon, haftalık rutin (pazar kilise), hava durumuna göre rutin.

## 5. Easter egg'ler (NOT — henüz yapılmadı)
- **Zaman yolcusu:** farklı kıyafet/obje, hep belirli saatte belirli köşede.
- **Uzaylı:** insan gibi davranan, çok ince ipuçları olan bir sakin.
- Aynı `sakinler.gd` sistemiyle eklenir: rutinli, ama bir "not" yerine gizli tepki/diyalog.
- Kural: ana oyunu bölmez, yalnızca dikkatli oyuncu fark eder.

## 6. Sıra (öneri)
1. Havaalanında sabit başlangıç + menüyü sadeleştirme.
2. Dükkân kurma/işletme döngüsü (ilk iş: küçük bir tezgâh veya bakkal).
3. Dış baskı: haraç/ruhsat/arama olayları oyuncu büyüdükçe tetiklensin.
4. KARAKTERLER.md'deki isimli kadroyu aile üyelerine bağlama.
5. Easter egg'ler.

## 7. Uygulama durumu (2026-11-23)
- **Sabit başlangıç (YAPILDI):** menüde köken/aile/geçmiş seçimi kalktı; yalnızca ad ve yaş. Herkes havaalanında, $350 ve dedenden kalan daireyle (kira yok) başlar. Eski köken/aile kodu test komutları ve eski kayıtlar için duruyor.
- **Açılış (YAPILDI):** HEDEF paneli sırayla yönlendirir: havaalanı → daire (H) → çalış ya da tezgâh kur → ilk iş → büyüme. Başlıkta gidişattan türeyen yol adı görünür (Yolun belli değil / Mahalle adamı / İşletmeci / Tüccar / Suç yolu).
- **Dükkân kurma (YAPILDI):** tezgâh sınıfı (Produce Stand, Pushcart, Cobbler, Shoe Repair) $300; normal dükkânlar $500+.
- **Dış baskı (YAPILDI):** dükkân sahibi olunca üç yeni karar kartı gelir: Koruma parası (mafya), Ruhsat ve arama (yozlaşmış polis), Rakip esnaf (sabotaj). Her birinde öde / pazarlık / karşı koy / yasal yol seçenekleri ve yol puanı etkisi var.
- **Easter egg (YAPILDI):** `Sakinler.GIZLI`: zaman yolcusu (Elias Vane, Union Station, 11:00-11:24) ve uzaylı (Mr. Smith, Corner Diner, 03:00-04:30). Yakınından geçince günde bir kez ince bir ipucu mesajı düşer.
- **Açık kalanlar:** KARAKTERLER.md kadrosunun aile üyelerine bağlanması; tüccar yoluna özel tedarik/zincir mekaniği; sakinlerin bina içinde görünmesi.
