extends RefCounted
# Tek yerden arayüz görünümü: sade, koyu gri + tek yumuşak vurgu rengi. Renk/boyut değiştirmek için burayı değiştir.

const OLCEK := 0.85   # tüm yazı boyutları bununla çarpılır (arayüzü küçültmek için düşür)

const ARKA := Color(0.09, 0.10, 0.12, 0.93)
const ARKA2 := Color(0.13, 0.14, 0.16, 0.95)
const KENAR := Color(0.24, 0.26, 0.29)
const YAZI := Color("d9dbde")
const SOLUK := Color("8e939b")
const VURGU := Color("c4ad83")   # tek vurgu: yumuşak kum rengi
const IYI := Color("8fb596")
const KOTU := Color("c98080")
const UYARI := Color("c9a86e")
const BILGI := Color("b4b9c0")
const DUGME := Color(0.15, 0.16, 0.18)
const DUGME_UZERI := Color(0.21, 0.22, 0.25)
const DUGME_BASILI := Color(0.30, 0.29, 0.26)

static func boyut(n: int) -> int:
	return maxi(10, int(round(n * OLCEK)))

static func stil(arka: Color = ARKA, kenar: Color = KENAR, marj: int = 10, yuvarlak: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = arka
	sb.border_color = kenar
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(yuvarlak)
	sb.set_content_margin_all(marj)
	return sb

static func dugme_stil(arka: Color, kenar: Color = KENAR) -> StyleBoxFlat:
	var sb := stil(arka, kenar, 6, 3)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	return sb

static var _tema: Theme

# Panellere/kök kontrollere atanır; içindeki düğme, seçim kutusu, ilerleme çubuğu aynı görünümü alır.
static func tema() -> Theme:
	if _tema != null:
		return _tema
	var t := Theme.new()
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
	var fill := stil(Color(0.55, 0.56, 0.6), Color(0, 0, 0, 0), 0, 2)
	var bg := stil(Color(1, 1, 1, 0.08), Color(0, 0, 0, 0), 0, 2)
	t.set_stylebox("fill", "ProgressBar", fill)
	t.set_stylebox("background", "ProgressBar", bg)
	t.set_font_size("font_size", "ProgressBar", boyut(13))
	t.set_stylebox("separator", "HSeparator", StyleBoxLine.new())
	(t.get_stylebox("separator", "HSeparator") as StyleBoxLine).color = KENAR
	t.set_constant("separation", "HSeparator", 6)
	return t
