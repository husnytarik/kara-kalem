# Web prototipi → Godot: eksik özellik envanteri

Kaynak: `prototype/src/core/*.js` (kurallar) ve `prototype/src/ui/main.js` (sekmeler: mekan, defter, bolge, is, adam, garaj, kisiler, guc, kara, kararlar).
Durum: `[x]` Godot'ta var · `[~]` kısmen/farklı biçimde var · `[ ]` yok.

## Var olanlar
- [x] Bölgeler, nüfuz, hakimlik, servet, haraç, komşuluk, rakip aileler (bolge.js → oyun.gd)
- [x] İşyerleri satın alma/haraç/görev, adam tutma/silah/yaralanma (isyeri.js → oyun.gd)
- [x] İşletme işleyişi: itibar, fiyat, personel, olaylar, rakip ajanı, muhbir (isletme.gd)
- [x] Ekip, savaş/baskın (3B savaş sahnesi + otomatik çözüm), aile üyeleri/rütbe
- [x] Mevsim/tarih, kayıt/yükleme, karakter profili (yeni, prototipte yok)

## Eksikler (öncelik sırasıyla)
### Faz A — oyunun amacı ve temel sistemler
- [x] **Zafer yolları** (zafer.js): dürüst iş (4 sahip, $12k temiz, dosya ≤15, 0 haraç, ekip ≤2, 2 ay), belediye başkanlığı (2 bölge, kampanya fonu $6000, yıllık seçim, oy oranı), hâkimiyet (5 bölge, 2 ay). Oyun sonu ekranı.
- [x] **Araba** (arac.js): Ford/Buick/Packard, yakıt, arıza, bakım gideri, "kolaylık", hız ve pusu çarpanı; garaj paneli (arac.gd, Garaj paneli, harita_oyuncu hız/yakıt; test: `--arac-testi`). Pusu çarpanı `pusu_carpan()` hazır, pusu sistemi Faz D'de
- [x] **Meslekler** (meslek.js → meslek.gd, "İş" paneli, test `--meslek-testi`): kabul puanı, beceri, günlük maaş, kovulma, işletme, perk'ler (yürüme hızı bağlı; pusu/aklama/berber kancaları: pusu_carpan, aklama_ucret/kapasite hazır, Faz B/D'de bağlanacak)
- [x] **Borç / tefeci** (borc.gd, yalnız "yerli" başlangıç): $3000 borç (web: 6000), aylık $300 taksit, %1 faiz, 3 kaçırılırsa oyun biter, erken ödeme ("İş" paneli). Kredi (liman) ve hisse Faz C'de (Harbor Trust)
### Faz B — yasa ve para
- [ ] **Polis dosyası/izi**: dosya, aşama (Temiz/Gözetim/Soruşturma/Arama emri), baskın, rüşvet, dedektif Dolan
- [ ] **Bodrum içki imalatı**: kazan, gizli oda, hacim, stok, iz; meyhane talebi/rakip Duffy
- [x] **Aklama + maliye şüphesi, çamaşırhane, vergi** (aklama.gd, "İş" paneli): kapasite = yasal ciro×%30 (çamaşırhane %50, katip avantajı), %20 kesinti, şüphe 50'de müfettiş ($300 + arama +10). Oda kirası zaten vardı. Yasal gelir `oyun.yasal()` ile toplanır
### Faz C — toplum
- [ ] **Ün sistemi** (social.js): Tanınırlık/İyilik/Korku × halk/yeraltı/polis, cephe/gölge, sızıntı; lakap (Ağa/Reis/Baba/Kıyı Başı/Sendika Başkanı), Güç Puanı
- [ ] **Kara Defter**: hedef, neden, ağırlık, tazminat/kapatma yolları, vendetta
- [ ] **Bağlar/kişiler**: 15 karakter, özellikler (traits), görüş/sadakat, stres, yaş ve ölüm
- [ ] **Ahit / Karaca ailesi**, Harbor Trust (kredi/hisse)
### Faz D — dünya olayları
- [ ] **Kararlar (kartlar)**: devriye, kavga, yangın, komşu, tefeci, yılbaşı, terfi, Karaca teklifi/baskısı, arama emri, pusu...
- [ ] **Şehir olayları, hava, haber** (sehir.js): sokak kartları, bölge işaretleri
- [ ] **Pusu** (savas.js pusuKur/pusuCoz): düşman bölgede yolda pusu

Kural: her faz sonunda JS testlerinin (`prototype/test/*.mjs`) sayıları Godot'ta aynı çıkmalı (bkz. `denge_testi.gd`).
