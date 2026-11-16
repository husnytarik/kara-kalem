# Savaş seviyeleri (3D, TPS)

Savaş, oyuncunun o anki konumuna en yakın seviyede yapılır:
- Haritaya `scenes/city/savas_alani.tscn` (ya da `scripts/core/savas_alani.gd` taşıyan bir Node3D) koy,
  `Tur` ve `Sahne` alanlarını doldur. 150 m içindeki en yakın işaret seçilir.
- İşaret yoksa kural: Docks bölgesi -> `liman`, özel bir binanın kapısı -> `ic`, diğer her yer -> `sokak`.
- Sahne boşsa gri kutulardan geçici bir seviye üretilir (`scripts/battle/savas_seviye.gd`).

## Bir seviye sahnesinin sözleşmesi
- Kök: Node3D. Zemin/duvarlar/siperler `StaticBody3D` + çarpışma, **layer 1**.
- Oyuncu tarafı başlangıç noktaları: `Marker3D`, grup **`spawn_oyuncu`** (en az 1, ekip kadar olması iyi).
- Düşman başlangıç noktaları: `Marker3D`, grup **`spawn_dusman`**.
- (İleride) `NavigationRegion3D`: yapay zekâ yol bulması için. Şimdilik düz hareket + duvarda kayma.
- Seviye sahnesi kendi ışığını/ortamını koymaz; savaş yöneticisi ekler.
- Seviye boyutları: sokak ~70x36 m, iç mekân ~26x20 m, liman ~130x90 m (kabaca).
