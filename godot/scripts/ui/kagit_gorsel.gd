extends Control
# Panel başlığındaki çerçeveli fotoğraf (gazete şablonu). assets/ui/panel/<anahtar>.png|jpg|webp dosyasını okur,
# gri tona çevirip kâğıda sepya mürekkep gibi basar. Anahtar sırası: [özel ad, tür, genel]; ilk bulunan kullanılır.
# Hiçbiri yoksa ayarla() false döner ve başlık görselsiz çizilir.

const KLASOR := "res://assets/ui/panel/"
const UZANTILAR := ["png", "jpg", "jpeg", "webp"]
const GEN := 660
const YUK := 440                          # 3:2 yatay çerçeve
const MUREKKEP := Color(0.22, 0.14, 0.07) # sepya toner
const YOGUNLUK := 0.92

static var _onb := {}
var _tex: ImageTexture

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size_flags_vertical = Control.SIZE_SHRINK_BEGIN

static func slug(s: String) -> String:
	var t := s.to_lower()
	for p in [["ı", "i"], ["ğ", "g"], ["ü", "u"], ["ş", "s"], ["ö", "o"], ["ç", "c"], ["â", "a"], ["î", "i"], ["û", "u"]]:
		t = t.replace(p[0], p[1])
	var r := ""
	for ch in t:
		r += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	while r.contains("__"):
		r = r.replace("__", "_")
	return r.trim_prefix("_").trim_suffix("_")

func ayarla(anahtarlar: Array) -> bool:
	_tex = null
	for k in anahtarlar:
		var t := _yukle(str(k))
		if t != null:
			_tex = t
			break
	queue_redraw()
	return _tex != null

static func _yukle(k: String) -> ImageTexture:
	if k == "":
		return null
	if _onb.has(k):
		return _onb[k]
	var sonuc: ImageTexture = null
	for u in UZANTILAR:
		var yol: String = KLASOR + k + "." + u
		if ResourceLoader.exists(yol):
			var kaynak = load(yol)
			if kaynak is Texture2D:
				sonuc = _fotokopi((kaynak as Texture2D).get_image())
			break
	_onb[k] = sonuc
	return sonuc

# Kaynak görseli kırp (yatay, üstten ~%30) -> gri -> kontrast aç -> hafif toner dokusu; sepya + alfa döndürür.
static func _fotokopi(kaynak: Image) -> ImageTexture:
	if kaynak == null:
		return null
	var img := kaynak.duplicate() as Image
	if img.is_compressed():
		img.decompress()
	img.convert(Image.FORMAT_RGBA8)
	var oran := float(GEN) / float(YUK)
	var kw := img.get_width()
	var kh := img.get_height()
	var cw := kw
	var ch := int(round(kw / oran))
	if ch > kh:
		ch = kh
		cw = int(round(kh * oran))
	img = img.get_region(Rect2i((kw - cw) / 2, int((kh - ch) * 0.3), cw, ch))
	img.resize(GEN, YUK, Image.INTERPOLATE_LANCZOS)
	var gri := PackedFloat32Array()
	gri.resize(GEN * YUK)
	var hist := PackedInt32Array()
	hist.resize(256)
	for y in YUK:
		for x in GEN:
			var c := img.get_pixel(x, y)
			var l := 0.299 * c.r + 0.587 * c.g + 0.114 * c.b
			l = lerpf(1.0, l, c.a)
			gri[y * GEN + x] = l
			hist[clampi(int(l * 255.0), 0, 255)] += 1
	var topla := 0
	var alt := 0.0
	var ust := 1.0
	var esik_a := int(GEN * YUK * 0.02)
	var esik_u := int(GEN * YUK * 0.98)
	var bulundu_a := false
	for i in 256:
		topla += hist[i]
		if not bulundu_a and topla >= esik_a:
			alt = i / 255.0
			bulundu_a = true
		if topla >= esik_u:
			ust = i / 255.0
			break
	if ust - alt < 0.1:
		ust = alt + 0.1
	var gur := FastNoiseLite.new()
	gur.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	gur.frequency = 0.09
	var cikti := Image.create(GEN, YUK, false, Image.FORMAT_RGBA8)
	for y in YUK:
		for x in GEN:
			var l := clampf((gri[y * GEN + x] - alt) / (ust - alt), 0.0, 1.0)
			var mur := pow(1.0 - l, 1.1)
			var doku := 0.88 + 0.12 * gur.get_noise_2d(x, y)
			var a := clampf(mur * doku, 0.0, 1.0) * YOGUNLUK
			cikti.set_pixel(x, y, Color(MUREKKEP.r, MUREKKEP.g, MUREKKEP.b, a))
	return ImageTexture.create_from_image(cikti)

func _draw() -> void:
	if _tex == null or size.x < 8.0:
		return
	draw_texture_rect(_tex, Rect2(Vector2.ZERO, Vector2(size.x, size.x * float(YUK) / float(GEN))), false)
