extends RefCounted
# Tek yerden arayüz görünümü: sade, koyu gri + tek yumuşak vurgu rengi. Renk/boyut değiştirmek için burayı değiştir.

const OLCEK := 0.75   # tüm yazı boyutları bununla çarpılır (arayüzü küçültmek için düşür)

const ARKA := Color(0.095, 0.086, 0.078, 0.94)    # koyu deri/kahve
const ARKA2 := Color(0.135, 0.124, 0.114, 0.96)
const KENAR := Color(0.38, 0.34, 0.27)                # pirinç kenar
const YAZI := Color("e3ddd0")                         # krem
const SOLUK := Color("a49d90")
const VURGU := Color("cdb177")                        # altın
const IYI := Color("84ab76")
const KOTU := Color("c4655a")
const UYARI := Color("d1ab5f")
const BILGI := Color("a1afc0")
const DUGME := Color(0.15, 0.137, 0.125)
const DUGME_UZERI := Color(0.22, 0.2, 0.175)
const DUGME_BASILI := Color(0.30, 0.265, 0.2)
const KAGIT := Color("d5cab3")                        # eski kâğıt (karar kartı)
const KAGIT_YAZI := Color("29231b")
const KAGIT_KENAR := Color("6f6450")

static var _yazi_tipi: Font
static func yazi_tipi() -> Font:
	if _yazi_tipi == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Cambria", "Palatino Linotype", "Times New Roman"])
		_yazi_tipi = f
	return _yazi_tipi

static func boyut(n: int) -> int:
	return maxi(10, int(round(n * OLCEK)))

static func stil(arka: Color = ARKA, kenar: Color = KENAR, marj: int = 10, yuvarlak: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = arka
	sb.border_color = kenar
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(mini(yuvarlak, 3))
	sb.set_content_margin_all(marj)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 4
	return sb

static func kagit_stil() -> StyleBoxFlat:
	var sb := stil(KAGIT, KAGIT_KENAR, 14, 2)
	sb.set_border_width_all(3)
	return sb

static func dugme_stil(arka: Color, kenar: Color = KENAR) -> StyleBoxFlat:
	var sb := stil(arka, kenar, 6, 3)
	sb.content_margin_left = 7
	sb.content_margin_right = 7
	return sb

static var _tema: Theme

# Panellere/kök kontrollere atanır; içindeki düğme, seçim kutusu, ilerleme çubuğu aynı görünümü alır.
static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
	t.default_font = yazi_tipi()
	t.default_font_size = boyut(16)
	t.set_color("font_color", "Label", YAZI)
	for tip in ["Button", "OptionButton"]:
		t.set_font_size("font_size", tip, boyut(16))
		t.set_stylebox("normal", tip, dugme_stil(DUGME))
		t.set_stylebox("hover", tip, dugme_stil(DUGME_UZERI, VURGU))
		t.set_stylebox("pressed", tip, dugme_stil(DUGME_BASILI, VURGU))
		t.set_stylebox("hover_pressed", tip, dugme_stil(DUGME_BASILI, VURGU))
		t.set_stylebox("disabled", tip, dugme_stil(Color(0.11, 0.12, 0.13), Color(0.18, 0.19, 0.21)))
		t.set_stylebox("focus", tip, StyleBoxEmpty.new())
		t.set_color("font_color", tip, YAZI)
		t.set_color("font_hover_color", tip, Color.WHITE)
		t.set_color("font_pressed_color", tip, VURGU)
		t.set_color("font_disabled_color", tip, Color(1, 1, 1, 0.25))
	var fill := stil(VURGU, Color(0, 0, 0, 0), 0, 2)
	var bg := stil(Color(0, 0, 0, 0.55), KENAR, 0, 2)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_font_size("font_size", "ProgressBar", boyut(13))
	t.set_stylebox("separator", "HSeparator", StyleBoxLine.new())
	(t.get_stylebox("separator", "HSeparator") as StyleBoxLine).color = KENAR
	t.set_constant("separation", "HSeparator", 6)
	t.set_constant("separation", "HBoxContainer", 6)
	t.set_constant("separation", "VBoxContainer", 6)
	return t

# ---------- eski kâğıt dokusu (kod ile üretilir, resim dosyası gerekmez) ----------
static var _kagit_onb := {}

# w×h kâğıt: gürültülü zemin, yanık kenar, koyu çerçeve + içte ince altın çizgi. tint: zemin rengi.
static func kagit_tex(w: int, h: int, tint: Color = KAGIT, kenar: Color = Color("2b1b0c")) -> ImageTexture:
	var anahtar := "%d_%d_%s_%s" % [w, h, tint.to_html(), kenar.to_html()]
	if _kagit_onb.has(anahtar):
		return _kagit_onb[anahtar]
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.035
	n.fractal_octaves = 3
	var n2 := FastNoiseLite.new()
	n2.noise_type = FastNoiseLite.TYPE_CELLULAR
	n2.frequency = 0.5
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			var v: float = 0.92 + 0.10 * n.get_noise_2d(x, y) + 0.03 * n2.get_noise_2d(x, y)
			var c := Color(tint.r * v, tint.g * v, tint.b * v, 1.0)
			if d < 14:
				c = c.darkened(0.38 * (1.0 - d / 14.0))
			if d < 3:
				c = kenar
			elif d == 4 or d == 5:
				c = Color(0.88, 0.66, 0.23, 0.9).lerp(c, 0.35)   # ince altın çizgi
			var kx := mini(x, w - 1 - x)
			var ky := mini(y, h - 1 - y)
			if absi(kx - 11) + absi(ky - 11) <= 3:
				c = Color(0.88, 0.66, 0.23)   # köşe baklavası
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_kagit_onb[anahtar] = t
	return t

static func kagit_panel() -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = kagit_tex(192, 192)
	sb.set_texture_margin_all(14)
	sb.set_content_margin_all(18)
	return sb

static var _tema_kagit: Theme
# Kâğıt üstündeki panellerin teması: yazılar koyu mürekkep.
static func tema_kagit() -> Theme:
	if _tema_kagit != null:
		return _tema_kagit
	var t: Theme = tema().duplicate()
	t.set_color("font_color", "Label", KAGIT_YAZI)
	t.set_color("font_color", "CheckBox", KAGIT_YAZI)
	_tema_kagit = t
	return t

# ---------- koyu deri çerçeve (üst çubuk, hedef kutusu, haber kutusu) ----------
static var _koyu_onb := {}

static func koyu_tex(w: int = 96, h: int = 96) -> ImageTexture:
	var anahtar := "%d_%d" % [w, h]
	if _koyu_onb.has(anahtar):
		return _koyu_onb[anahtar]
	var n := FastNoiseLite.new()
	n.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n.frequency = 0.06
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var altin := Color(0.86, 0.64, 0.22)
	var altin_k := Color(0.5, 0.36, 0.14)
	for y in h:
		for x in w:
			var d := mini(mini(x, y), mini(w - 1 - x, h - 1 - y))
			var v: float = 1.0 + 0.12 * n.get_noise_2d(x, y)
			var c := Color(0.085 * v, 0.058 * v, 0.042 * v, 0.97)
			if d < 1:
				c = altin_k
			elif d == 1:
				c = altin
			elif d == 2:
				c = Color(0.02, 0.012, 0.008)
			elif d == 3 or d == 4:
				c = altin_k.lerp(altin, 0.4)
			elif d == 5:
				c = Color(0.02, 0.012, 0.008)
			elif d == 6:
				c = Color(0.3, 0.21, 0.09, 0.9)
			var kx := mini(x, w - 1 - x)
			var ky := mini(y, h - 1 - y)
			if absi(kx - 10) + absi(ky - 10) <= 3:
				c = altin
			img.set_pixel(x, y, c)
	var tx := ImageTexture.create_from_image(img)
	_koyu_onb[anahtar] = tx
	return tx

static func koyu_panel(marj: int = 10) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = koyu_tex()
	sb.set_texture_margin_all(14)
	sb.set_content_margin_all(marj + 4)
	return sb

static func yuvarlak_stil(arka: Color, kenar: Color = Color("c9972c"), r: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = arka
	sb.border_color = kenar
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(r)
	sb.set_content_margin_all(0)
	return sb

# ---------- gazete şablonu yazı tipleri ----------
static var _baslik_f: Font
static func baslik_fontu() -> Font:   # dar, kalın, büyük harf manşet
	if _baslik_f == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Bahnschrift", "Impact", "Arial Narrow", "Georgia"])
		f.font_weight = 700
		f.font_stretch = 75
		_baslik_f = f
	return _baslik_f

static var _kalin_f: Font
static func kalin_fontu() -> Font:    # bölüm başlıkları
	if _kalin_f == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Cambria", "Palatino Linotype", "Times New Roman"])
		f.font_weight = 700
		_kalin_f = f
	return _kalin_f

static var _italik_f: Font
static func italik_fontu() -> Font:   # gazete adı
	if _italik_f == null:
		var f := SystemFont.new()
		f.font_names = PackedStringArray(["Georgia", "Cambria", "Palatino Linotype", "Times New Roman"])
		f.font_weight = 700
		f.font_italic = true
		_italik_f = f
	return _italik_f
