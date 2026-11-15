# Kara Kalem 3D — Asset Hazırlık Rehberi

Motor: **Godot 4.3 veya daha yenisi (stable)**. Proje `godot/` klasöründe; Godot'ta "Import" ile `project.godot` dosyasını seç.

## 1. Render motoru

Godot 4'te üç render yolu var:

| Yol | Ne zaman |
|---|---|
| **Forward+** (seçili) | Masaüstü, Vulkan. En iyi görüntü: gerçek zamanlı gölge, SDFGI/VoxelGI, SSAO, SSR, volumetrik sis. Hedefimiz bu. |
| Mobile | Daha hafif Vulkan. Gerekirse düşük donanım için. |
| Compatibility | OpenGL. Eski kartlar, web. Özellikleri kısıtlı. |

Sonradan değiştirmek mümkün ama malzeme ve ışık ayarları etkilenir; baştan Forward+ ile çalış.

## 2. Malzeme (texture map) sistemi

Godot **PBR metallic-roughness** kullanır (`StandardMaterial3D`). Texture'ları bu haritalarla hazırla:

| Harita | Godot'taki yeri | Not |
|---|---|---|
| **Albedo / Base Color** | Albedo | sRGB. Işık/gölge boyama, saf renk. |
| **Normal** | Normal Map | **OpenGL (Y+)** biçimi. DirectX (Y−) normal map'i Godot'ta ters görünür; Substance'ta "OpenGL" seç. Linear. |
| **Roughness** | Roughness | Gri tonlama. Kumaş/deri yüksek (0.7–1), metal düşük. |
| **Metallic** | Metallic | Çoğu kumaş/deri için 0. Silah ve toka metali için 1. |
| **Ambient Occlusion** | AO | İsteğe bağlı. |
| **Emission** | Emission | Lamba, neon, namlu ateşi. |
| **Height** | Heightmap | Nadiren (zemin). |

**Kanal paketleme (ORM):** AO, Roughness, Metallic'i tek texture'a koyabilirsin: **R = AO, G = Roughness, B = Metallic**. Godot'ta "Orm" seçeneği vardır. Çok sayıda karakterde bellek ve performans için bunu öneririm. Dosya adı eki: `_orm`.

Ek özellikler: Subsurface scattering (cilt), Rim, Clearcoat (cilalı deri/araba boyası), Anisotropy (saç), Detail. Kumaşta "Fuzz" yerine Rim ve düşük Metallic yeterli.

## 3. Model biçimi ve ayarlar

- **Biçim:** `.glb` (glTF 2.0). Godot'un en iyi desteklediği biçim. Blender'dan: File → Export → glTF 2.0 → "glTF Binary".
- `.fbx` de açılır (Godot 4.3+ yerleşik içe aktarır) ama glTF tercih.
- **Ölçek:** 1 birim = 1 metre. İnsan boyu yaklaşık 1.75–1.85.
- **Eksen:** Blender'dan glTF dışa aktarırken "+Y Up" açık kalsın. Godot'ta ileri yön −Z. Karakterlerin yüzü **−Z**'ye baksın.
- **Uygulanmış dönüşümler:** Dışa aktarmadan önce Ctrl+A → All Transforms.
- **Pivot:** Karakter ve prop'larda pivot ayak tabanının ortasında.

## 4. Karakter ve modüler kıyafet sistemi

Kıyafet değiştirme mantığı: **tek ortak iskelet + ayrı mesh parçaları.** Ceket değiştirmek, ceket mesh'ini değiştirmek demek; animasyon hepsinde ortak çalışır.

- **İskelet:** Humanoid, Mixamo uyumlu kemik adları (`mixamorig:Hips` vb.) veya Godot humanoid profili. Tüm vücut ve kıyafet parçaları **aynı iskelet ve aynı rig ile** dışa aktarılmalı. Parça başına ayrı .glb olabilir.
- **Parçalar** (`assets/characters/clothing/` altında): şapka, üst, dış giyim, alt, ayakkabı, aksesuar. Başlık: `headwear`, `tops`, `outerwear`, `bottoms`, `shoes`, `accessories`.
- **Vücut gizleme:** Kıyafet altında vücudun görünmesi (clipping) sorun olur. Çözüm: vücut mesh'inde bölge kesikleri veya her kıyafette "gizlenecek bölge" bilgisi. İlk aşamada vücudu bölgelere ayır (gövde, kol, bacak, ayak).
- **Yüz:** Ayrı kafa mesh'i, blend shape (shape key) ile yüz çeşitliliği ve ifade.
- **Saç/sakal:** Ayrı mesh. Saç için alfa kesme (Alpha Scissor/Hash) materyali.
- **Renk çeşitliliği:** Aynı kıyafet birden fazla renk istiyorsan albedo'yu gri yapıp renk Godot'ta materyal parametresiyle verilir (maske texture ile).

**Poligon bütçesi (öneri, ekranda çok kişi olacağı için):**

| Parça | Üçgen |
|---|---|
| Tam karakter (yakın, LOD0) | 20–30 bin |
| LOD1 | 8–12 bin |
| LOD2 (uzak) | 2–4 bin |
| Silah | 3–8 bin |
| Araba | 40–80 bin |

Texture boyutu: karakter başına toplam 2K (2048²) yeterli; uzak karakterde 1K. Çevre için modüler 1K–2K tile'lar.

## 5. Animasyon

- Her animasyon `.glb` veya `.fbx` olarak, aynı iskeletle. İlk kaynak: **Mixamo** (ücretsiz, hesap gerekir).
- `locomotion`: idle, yürü, koş, çömel, siper. `melee`: yumruk, bıçak, tekme. `firearms`: nişan, ateş, tabanca/pompalı/Thompson tutuşu, dolum. `social`: konuşma, el sallama. `vehicle`: arabaya binme, sürme. `reactions`: vurulma, düşme, ölme.
- Döngü animasyonlarının ilk ve son karesi aynı olmalı (loop).

## 6. Klasör yapısı

```
godot/
  project.godot
  ASSET_REHBERI.md
  _source/                  Godot'un görmediği ham dosyalar (.gdignore var)
    blender/ substance_painter/ photoshop/ reference/
  assets/                   Godot'a aktarılan nihai dosyalar
    characters/
      base/                 Vücut mesh'i, iskelet
      faces_hair/           heads/ hair/ facial_hair/
      clothing/             headwear/ tops/ outerwear/ bottoms/ shoes/ accessories/
      animations/           locomotion/ melee/ firearms/ social/ vehicle/ reactions/
    weapons/                firearms/ melee/ throwables/
    vehicles/
    environment/            buildings/ interiors/ streets/ props/ vegetation/ skybox/
    materials/              Ortak .tres materyaller
    textures/               shared/ decals/
    audio/                  sfx/ music/ voice/
    ui/                     fonts/ icons/
  scenes/                   .tscn sahneler: characters/ battle/ city/ ui/
  scripts/                  .gd kodlar: core/ battle/ characters/ ui/
  tests/
```

## 7. İsimlendirme

Küçük harf, alt çizgi, İngilizce (motor ve araçlar için sorunsuz):

- Mesh: `tops_vest_wool_01.glb`, `headwear_fedora_01.glb`
- Texture: `<mesh_adi>_albedo.png`, `_normal.png`, `_orm.png`, `_emission.png`
- Animasyon: `anim_pistol_fire.glb`
- Sahne: `gangster_base.tscn`

## 8. Dosya boyutu ve Git

GitHub tek dosyada 100 MB sınırı koyar. `.glb`, `.png`, `.wav` gibi ikili dosyalar çoğalınca **Git LFS** gerekir. Ham `.blend`/`.psd` dosyaları büyük olur; onları `_source/` içinde tut (`.psd` ve `.spp` `.gitignore`'da). Başlangıç aşamasında önce küçük örnek modellerle ilerleyelim; asset hacmi büyüyünce LFS'i ben kurarım.

## 9. Dönem (1920'ler Prohibition)

Referans için `_source/reference/`'a koy: fötr şapka (fedora, newsboy), yelek ve kravat, çizgili takım, geniş paça pantolon, spats ayakkabı, trençkot; silahlar: Colt 1911, Thompson M1921, çift namlulu pompalı, Browning; arabalar: Ford Model T/A, Cadillac Type 51, Packard.
