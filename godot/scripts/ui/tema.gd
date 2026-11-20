extends RefCounted
# Tek yerden arayüz görünümü: sade, koyu gri + tek yumuşak vurgu rengi. Renk/boyut değiştirmek için burayı değiştir.

const OLCEK := 0.75   # tüm yazı boyutları bununla çarpılır (arayüzü küçültmek için düşür)

const ARKA := Color(0.105, 0.075, 0.052, 0.94)    # koyu deri/kahve
const ARKA2 := Color(0.15, 0.108, 0.075, 0.96)
const KENAR := Color(0.40, 0.29, 0.15)                # pirinç kenar
const YAZI := Color("e6d9bd")                         # krem
const SOLUK := Color("a8977a")
const VURGU := Color("e0a93a")                        # altın
const IYI := Color("74c260")
const KOTU := Color("e0513a")
const UYARI := Color("e6a52e")
const BILGI := Color("9dbbdc")
const DUGME := Color(0.16, 0.115, 0.078)
const DUGME_UZERI := Color(0.24, 0.17, 0.10)
const DUGME_BASILI := Color(0.33, 0.23, 0.10)
const KAGIT := Color("d8c39a")                        # eski kâğıt (karar kartı)
const KAGIT_YAZI := Color("2b1d10")
const KAGIT_KENAR := Color("7a5a30")

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
