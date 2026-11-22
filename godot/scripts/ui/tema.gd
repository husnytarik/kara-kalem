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

# Art Deco çerçeve: kesik (pahlı) köşeler, çift ince çizgi, köşede küçük baklava. Mat pirinç; parlak altın yok.
static var _deco_onb := {}
static func deco_tex(fill: Color, cizgi: Color, pah: int = 6, kose: int = 8) -> ImageTexture:
	var anahtar := "%s_%s_%d_%d" % [fill.to_html(), cizgi.to_html(), pah, kose]
	if _deco_onb.has(anahtar):
		return _deco_onb[anahtar]
	var N := 2 * (kose + 6) + 4
	var img := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var koyu := Color(fill.r * 0.35, fill.g * 0.35, fill.b * 0.35, maxf(fill.a, 0.95))
	var soluk := Color(cizgi.r * 0.7, cizgi.g * 0.7, cizgi.b * 0.7, 0.95)
	var parlak := cizgi.lightened(0.3)
	for y in N:
		for x in N:
			var kx := mini(x, N - 1 - x)
			var ky := mini(y, N - 1 - y)
			var e := mini(mini(kx, ky), kx + ky - pah)
			var c := fill
			if e < 0:
				c = Color(0, 0, 0, 0)
			elif e <= 1:
				c = cizgi
			elif e == 2:
				c = koyu
			elif e == 4:
				c = soluk
			var dx := absi(kx - (pah + 3))
			var dy := absi(ky - (pah + 3))
			if dx + dy <= 1 and kx < kose + 6 and ky < kose + 6:
				c = parlak
			img.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(img)
	_deco_onb[anahtar] = t
	return t

static func stil(arka: Color = ARKA, kenar: Color = KENAR, marj: int = 10, _yuvarlak: int = 4) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = deco_tex(arka, kenar, 6, 8)
	sb.set_texture_margin_all(14)
	sb.set_content_margin_all(maxi(marj, 12))
	return sb

# Düz dolgu/çubuk için (çerçevesiz)
static func duz_stil(arka: Color, kenar: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = arka
	sb.border_color = kenar
	if kenar.a > 0.0:
		sb.set_border_width_all(1)
	return sb

static func kagit_stil() -> StyleBoxTexture:
	return kagit_panel()

static func dugme_stil(arka: Color, kenar: Color = KENAR) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = deco_tex(arka, kenar, 3, 4)
	sb.set_texture_margin_all(9)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
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
	var fill := duz_stil(VURGU)
	var bg := duz_stil(Color(0, 0, 0, 0.55), KENAR)
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
			var kx := mini(x, w - 1 - x)
			var ky := mini(y, h - 1 - y)
			var d := mini(mini(kx, ky), kx + ky - 7)
			var v: float = 0.92 + 0.10 * n.get_noise_2d(x, y) + 0.03 * n2.get_noise_2d(x, y)
			var c := Color(tint.r * v, tint.g * v, tint.b * v, 1.0)
			if d < 0:
				c = Color(0, 0, 0, 0)
			else:
				if d < 14:
					c = c.darkened(0.30 * (1.0 - d / 14.0))
				if d <= 1:
					c = kenar
				elif d == 4:
					c = Color(0.50, 0.42, 0.28, 0.95).lerp(c, 0.25)   # ince mat pirinç çizgi
				if absi(kx - 10) + absi(ky - 10) <= 2:
					c = Color(0.50, 0.42, 0.28)
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

static func koyu_tex(_w: int = 96, _h: int = 96) -> ImageTexture:
	return deco_tex(Color(0.085, 0.08, 0.075, 0.96), Color(0.62, 0.53, 0.36), 8, 8)

static func koyu_panel(marj: int = 10) -> StyleBoxTexture:
	var sb := StyleBoxTexture.new()
	sb.texture = koyu_tex()
	sb.set_texture_margin_all(14)
	sb.set_content_margin_all(marj + 4)
	return sb

static func yuvarlak_stil(arka: Color, kenar: Color = Color("8f7c52"), r: int = 16) -> StyleBoxFlat:
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
