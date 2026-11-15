# Kara Kalem 3D — PLAN

Durum: `[x]` bitti · `[~]` JS prototipte var, Godot'a taşınacak · `[ ]` yapılmadı.
Görsel harita: `plan.html` (tarayıcıda aç). Bu dosya asıl kaynaktır; ilerledikçe işaretle ve `plan.html` içindeki `DATA` listesini güncelle.

## Faz 1 — Temel (sahne, karakter, kamera)
- [ ] **Sokak** — `sokak.gd` — tek sokaklık test sahnesi, zemin, ışık, binalar (kutu)
- [ ] **Yürüme** — `oyuncu.gd` — WASD, koşma, çömelme, çarpışma
- [ ] **Kamera** — `kamera.gd` — üçüncü şahıs, omuz kamerası, nişan modu
- [ ] **Karakter** — `karakter.gd` — ortak iskelet, modüler kıyafet parçaları (şapka, üst, alt, ayakkabı)
- [ ] **Animasyon** — `animasyon.gd` — durma, yürüme, koşma, ateş etme, vurulma, ölme
- [ ] **Gün döngüsü** — `gun_dongusu.gd` — güneş, gece, sokak lambaları
- [ ] **Hava** — `hava.gd` — yağmur, sis, rüzgâr (sim'deki hava ile bağlı)

## Faz 2 — Savaş (Mount & Blade tarzı)
- [ ] **Silah** — `silah.gd` — tabanca, pompalı, Thompson, bıçak; isabet, geri tepme, şarjör
- [ ] **Siper** — `siper.gd` — siper noktaları, korunma
- [ ] **Yapay zekâ** — `yapay_zeka.gd` — adamlar ve düşmanlar: mevzilen, ilerle, geri çekil
- [ ] **Emirler** — `emirler.gd` — F1-F3 tarzı emirler, grup seçimi
- [ ] **Savaş yönetimi** — `savas.gd` — savaş başlangıcı/bitişi, moral, kayıplar, sonuç
- [ ] **Otomatik çöz** — `savas_sim.gd` — oynamadan hesaplanan sonuç (sim ile uyumlu)
- [ ] **Araba sürüşü** — `arac_surus.gd` — binme, sürme, kovalamaca

## Faz 3 — Şehir simülasyonunu taşı
- [~] **Sim çekirdeği** — `sim.gd` — zaman, saat/gün/ay tikleri, kayıt biçimi
- [~] **Bölgeler** — `bolge.gd` — nüfuz, hakimlik, huzur, servet
- [~] **İşyerleri ve adamlar** — `isyeri.gd` — haraç, satın alma, görevler, adam becerileri
- [~] **Meslekler** — `meslek.gd` — gündelik işler
- [~] **Olaylar** — `sehir.gd` — şehir olayları ve hava
- [~] **Zafer yolları** — `zafer.gd` — dürüst iş, belediye başkanlığı, hakimiyet
- [ ] **Harita geçişi** — `harita_gecisi.gd` — şehir görünümünden savaş sahnesine geçiş

## Faz 4 — Cila
- [ ] **Arayüz** — `arayuz.gd` — şehir paneli, envanter, karakter özelleştirme
- [ ] **Ses** — `ses.gd` — silah, adım, ortam, müzik
- [ ] **Kayıt** — `kayit.gd` — kaydet/yükle
- [ ] **Doğrulama** — `dogrula.gd` — başsız testler (JS testleri örnek alınır)

## Karar notları
- Motor: Godot 4.3+, Forward+. Biçim: `.glb` tercih, `.fbx` de olur.
- JS prototip (`prototype/`) kural ve denge referansıdır; Godot'a taşırken testlerin sayıları aynı çıkmalı.
