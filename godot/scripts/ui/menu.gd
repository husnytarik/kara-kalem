extends Control
# Ana menü ve karakter yaratma. Her şey kodla kuruluyor (arayuz.gd gibi).
# Komut satırı argümanı varsa (test/doğrulama) menü atlanır; --menu ana menüyü, --kur karakter ekranını açar.

const Profil := preload("res://scripts/core/profil.gd")
const Tema := preload("res://scripts/ui/tema.gd")
const ALTIN := Tema.VURGU
const SOLUK := Tema.SOLUK
const OYUN := "res://scenes/main.tscn"

var _ana: Control
var _kur: Control
var _p := {"ad": "", "yas": 28, "koken": "yerli", "aile": "marchetti", "gecmis": "isci"}
var _ad_giris: LineEdit
var _yas_etiket: Label
var _koken_acik: Label
var _gecmis_acik: Label
var _aile_satir: Control
var _ozet_kutu: VBoxContainer
var _t := 0.0
var _ekran_yol := ""

# ---------- ortak görünüm yardımcıları (duraklat.gd de kullanır; renkler tema.gd'den) ----------
static func panel_stil(arka: Color = Tema.ARKA) -> StyleBox:
	return Tema.stil(arka, Tema.KENAR, 16, 6)

static func _dugme_stil(c: Color, kenar: Color = Tema.KENAR) -> StyleBox:
	var sb := Tema.dugme_stil(c, kenar)
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

static func dugme_giydir(b: Button, boyut: int = 22) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", Tema.boyut(boyut))
	b.add_theme_stylebox_override("normal", _dugme_stil(Tema.DUGME))
	b.add_theme_stylebox_override("hover", _dugme_stil(Tema.DUGME_UZERI, Tema.VURGU))
	b.add_theme_stylebox_override("pressed", _dugme_stil(Tema.DUGME_BASILI, Tema.VURGU))
	b.add_theme_stylebox_override("disabled", _dugme_stil(Color(0.11, 0.12, 0.13), Color(0.18, 0.19, 0.21)))
	b.add_theme_color_override("font_color", Tema.YAZI)
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))

static func dugme(ebeveyn: Node, metin: String, fn: Callable, boyut: int = 22) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = Vector2(0, 36)
	dugme_giydir(b, boyut)
	b.pressed.connect(fn)
	ebeveyn.add_child(b)
	return b

static func etiket(ebeveyn: Node, metin: String, boyut: int = 16, renk: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", Tema.boyut(boyut))
	l.add_theme_color_override("font_color", renk)
	ebeveyn.add_child(l)
	return l

# ---------- kurulum ----------
func _ready() -> void:
	Engine.time_scale = 1.0
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--menuekran="):
			_ekran_yol = a.substr(12).split(",")[0]
			if a.ends_with(",kur"):
				args.append("--kur")
			args.append("--menu")
	if args.size() > 0 and not args.has("--menu") and not args.has("--kur"):
		get_tree().change_scene_to_file.call_deferred(OYUN)   # doğrulama modu: doğrudan oyun
		return
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_ana_kur()
	_kur_kur()
	_kur.visible = args.has("--kur")
	_ana.visible = not _kur.visible
	_p["ad"] = Profil.rastgele_ad()
	_ad_giris.text = _p["ad"]
	_guncelle()

func _process(d: float) -> void:
	_t += d
	queue_redraw()
	if _ekran_yol != "" and _t > 3.0:
		get_viewport().get_texture().get_image().save_png(_ekran_yol)
		get_tree().quit()

var _arka_tex: Texture2D = load("res://assets/ui/menu_arka.png")

func _draw() -> void:
	var b := size
	if _arka_tex != null:
		var ts := _arka_tex.get_size()
		var o := maxf(b.x / ts.x, b.y / ts.y)
		var d := ts * o
		draw_texture_rect(_arka_tex, Rect2((b - d) * 0.5, d), false)
		_yagmur(b, b.y / 720.0)
		_vinyet(b)
		return
	var s := b.y / 720.0
	var ufuk := b.y * 0.74
	_gokyuzu(b, ufuk)
	_ay(b, s)
	_huzmeler(b, s, ufuk)
	_siluet(b, s, ufuk - 4.0 * s, Color(0.16, 0.13, 0.17), 150.0 * s, 330.0 * s, 40.0 * s, 90.0 * s, 11, false)
	_sis(b, s, ufuk, 0.55)
	_siluet(b, s, ufuk + 6.0 * s, Color(0.075, 0.06, 0.09), 130.0 * s, 400.0 * s, 52.0 * s, 120.0 * s, 77, true)
	_sis(b, s, ufuk + 10.0 * s, 0.4)
	_sokak(b, s, ufuk)
	_arac(Vector2(b.x * 0.56, ufuk + 62.0 * s), b.x * 0.20, s)
	_adam(Vector2(b.x * 0.80, b.y - 26.0 * s), b.y * 0.44, s)
	_yagmur(b, s)
	_vinyet(b)

func _gokyuzu(b: Vector2, ufuk: float) -> void:
	var renkler := [Color(0.02, 0.02, 0.05), Color(0.07, 0.06, 0.12), Color(0.24, 0.14, 0.14), Color(0.55, 0.33, 0.2)]
	var adim := 36
	for i in adim:
		var f := float(i) / float(adim - 1)
		var k := f * 3.0
		var a := mini(int(k), 2)
		var c: Color = renkler[a].lerp(renkler[a + 1], k - a)
		draw_rect(Rect2(0, ufuk * i / adim, b.x, ufuk / adim + 1.0), c)
	draw_rect(Rect2(0, ufuk, b.x, b.y - ufuk), Color(0.05, 0.04, 0.06))
	# yıldızlar
	var r := RandomNumberGenerator.new()
	r.seed = 5
	for i in 110:
		var p := Vector2(r.randf() * b.x, r.randf() * ufuk * 0.55)
		var par := 0.35 + 0.65 * (0.5 + 0.5 * sin(_t * r.randf_range(0.6, 2.0) + i))
		draw_circle(p, r.randf_range(0.6, 1.5), Color(1, 0.96, 0.85, 0.5 * par))

func _ay(b: Vector2, s: float) -> void:
	var c := Vector2(b.x * 0.74, b.y * 0.19)
	for k in 9:
		draw_circle(c, (52.0 + k * 20.0) * s, Color(0.95, 0.82, 0.6, 0.045 * (1.0 - k / 9.0)))
	draw_circle(c, 52.0 * s, Color(0.96, 0.9, 0.74))
	for kr in [[-14.0, -10.0, 9.0], [12.0, 8.0, 13.0], [-4.0, 22.0, 7.0], [20.0, -14.0, 6.0]]:
		draw_circle(c + Vector2(kr[0], kr[1]) * s, kr[2] * s, Color(0.82, 0.74, 0.58, 0.55))
	draw_circle(c + Vector2(18, -8) * s, 48.0 * s, Color(0.08, 0.06, 0.1, 0.25))

func _huzmeler(b: Vector2, s: float, ufuk: float) -> void:
	for i in 2:
		var taban := Vector2(b.x * (0.18 + 0.30 * i), ufuk)
		var aci := sin(_t * 0.22 + i * 2.1) * 0.5 + (-0.4 if i == 0 else 0.25)
		var yon := Vector2(sin(aci), -cos(aci))
		var dik := Vector2(-yon.y, yon.x)
		var uc := taban + yon * b.y * 1.1
		draw_polygon(PackedVector2Array([taban - dik * 8.0 * s, taban + dik * 8.0 * s, uc + dik * 90.0 * s, uc - dik * 90.0 * s]),
			PackedColorArray([Color(1, 0.95, 0.78, 0.11), Color(1, 0.95, 0.78, 0.11), Color(1, 0.95, 0.78, 0.0), Color(1, 0.95, 0.78, 0.0)]))

# Art Deco silüet: kademeli gövde, ince kule, sağ kenarda ay ışığı, yanan pencereler.
func _siluet(b: Vector2, s: float, taban: float, renk: Color, hmin: float, hmax: float, wmin: float, wmax: float, tohum: int, pencere: bool) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = tohum
	var x := -30.0 * s
	while x < b.x:
		var w := r.randf_range(wmin, wmax)
		var h := r.randf_range(hmin, hmax)
		draw_rect(Rect2(x, taban - h, w, h + 200.0), renk)
		var ust := taban - h
		var cx := x
		var cw := w
		var kademe := r.randi_range(0, 3)
		for i in kademe:
			var nw := cw * r.randf_range(0.6, 0.82)
			var nx := cx + (cw - nw) * 0.5
			var nh := r.randf_range(0.04, 0.10) * b.y
			draw_rect(Rect2(nx, ust - nh, nw, nh + 1.0), renk)
			draw_rect(Rect2(nx + nw - 2.0 * s, ust - nh, 2.0 * s, nh), Color(0.8, 0.82, 1.0, 0.07))
			ust -= nh
			cx = nx
			cw = nw
		if kademe >= 2 and r.randf() < 0.75:
			var kh := r.randf_range(0.08, 0.17) * b.y
			draw_polygon(PackedVector2Array([Vector2(cx + cw * 0.36, ust), Vector2(cx + cw * 0.5, ust - kh), Vector2(cx + cw * 0.64, ust)]), PackedColorArray([renk, renk, renk]))
			draw_line(Vector2(cx + cw * 0.5, ust - kh), Vector2(cx + cw * 0.5, ust - kh - 16.0 * s), renk, 1.5 * s)
			if pencere:
				var yan := 0.5 + 0.5 * sin(_t * 2.0 + x)
				draw_circle(Vector2(cx + cw * 0.5, ust - kh - 16.0 * s), 2.2 * s, Color(1.0, 0.25, 0.2, 0.35 + 0.6 * yan))
		draw_rect(Rect2(x + w - 2.0 * s, taban - h, 2.0 * s, h), Color(0.8, 0.82, 1.0, 0.08))
		if pencere:
			var wy := taban - h + 14.0 * s
			while wy < taban - 14.0 * s:
				var wx := x + 8.0 * s
				while wx < x + w - 12.0 * s:
					if r.randf() < 0.24:
						var sicak := r.randf()
						var pr := Color(1.0, 0.8 + 0.1 * sicak, 0.42 + 0.2 * sicak)
						var titre := 0.8 + 0.2 * sin(_t * 1.4 + wx * 0.13 + wy)
						draw_rect(Rect2(wx - 2.0 * s, wy - 2.0 * s, 10.0 * s, 12.0 * s), Color(pr.r, pr.g, pr.b, 0.07 * titre))
						draw_rect(Rect2(wx, wy, 6.0 * s, 8.0 * s), Color(pr.r, pr.g, pr.b, 0.72 * titre))
					else:
						r.randf()
					wx += 16.0 * s
				wy += 22.0 * s
		x += w + r.randf_range(0.0, 6.0 * s)

func _sis(b: Vector2, s: float, y: float, guc: float) -> void:
	for i in 12:
		var f := float(i) / 12.0
		draw_rect(Rect2(0, y - (60.0 * s) * f, b.x, 60.0 * s / 12.0 + 1.0), Color(0.85, 0.58, 0.36, 0.05 * guc * (1.0 - f)))
	for i in 5:
		var cx := fposmod(b.x * 0.2 * i + _t * (6.0 + 3.0 * i), b.x + 600.0 * s) - 300.0 * s
		draw_set_transform(Vector2(cx, y - 14.0 * s * (i % 3)), 0.0, Vector2(5.0, 0.7))
		draw_circle(Vector2.ZERO, 70.0 * s, Color(0.9, 0.65, 0.45, 0.045 * guc))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _sokak(b: Vector2, s: float, ufuk: float) -> void:
	# ıslak asfalt: yukarıdan aşağıya kararan, sıcak yansımalı
	for i in 16:
		var f := float(i) / 15.0
		var c := Color(0.13, 0.09, 0.09).lerp(Color(0.02, 0.02, 0.03), f)
		draw_rect(Rect2(0, ufuk + (b.y - ufuk) * i / 16.0, b.x, (b.y - ufuk) / 16.0 + 1.0), c)
	# kaldırım çizgisi
	draw_rect(Rect2(0, ufuk, b.x, 3.0 * s), Color(0.35, 0.27, 0.2, 0.5))
	# sokak lambaları + ıslak zeminde ışık havuzu
	for lx in [b.x * 0.42, b.x * 0.93]:
		var top := Vector2(lx, ufuk - 150.0 * s)
		draw_rect(Rect2(lx - 2.5 * s, top.y, 5.0 * s, 150.0 * s + 40.0 * s), Color(0.03, 0.03, 0.04))
		draw_rect(Rect2(lx - 14.0 * s, top.y - 3.0 * s, 28.0 * s, 6.0 * s), Color(0.03, 0.03, 0.04))
		var titre := 0.9 + 0.1 * sin(_t * 7.0 + lx)
		for k in 7:
			draw_circle(top + Vector2(0, 6.0 * s), (10.0 + k * 11.0) * s, Color(1.0, 0.78, 0.4, 0.05 * titre * (1.0 - k / 7.0)))
		draw_circle(top + Vector2(0, 5.0 * s), 5.0 * s, Color(1.0, 0.93, 0.7))
		draw_set_transform(Vector2(lx, ufuk + 70.0 * s), 0.0, Vector2(3.4, 0.5))
		for k in 6:
			draw_circle(Vector2.ZERO, (14.0 + k * 14.0) * s, Color(1.0, 0.75, 0.38, 0.05 * titre * (1.0 - k / 6.0)))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_polygon(PackedVector2Array([Vector2(lx - 4.0 * s, ufuk + 8.0 * s), Vector2(lx + 4.0 * s, ufuk + 8.0 * s), Vector2(lx + 14.0 * s, b.y), Vector2(lx - 14.0 * s, b.y)]),
			PackedColorArray([Color(1, 0.8, 0.45, 0.16 * titre), Color(1, 0.8, 0.45, 0.16 * titre), Color(1, 0.8, 0.45, 0.0), Color(1, 0.8, 0.45, 0.0)]))

func _arac(taban: Vector2, uzun: float, s: float) -> void:
	var L := uzun
	var koyu := Color(0.02, 0.02, 0.03)
	var govde := [Vector2(-0.50, -0.10), Vector2(-0.50, -0.20), Vector2(-0.38, -0.24), Vector2(-0.20, -0.26), Vector2(-0.15, -0.40),
		Vector2(0.05, -0.42), Vector2(0.20, -0.40), Vector2(0.28, -0.26), Vector2(0.48, -0.22), Vector2(0.50, -0.10)]
	var pts := PackedVector2Array()
	for p in govde:
		pts.append(taban + p * L)
	# yansıma (ıslak yol)
	var yans := PackedVector2Array()
	for p in govde:
		yans.append(taban + Vector2(p.x, -p.y * 0.35 + 0.02) * L)
	draw_colored_polygon(yans, Color(0.9, 0.6, 0.3, 0.05))
	# far ışığı
	var far := taban + Vector2(-0.50, -0.18) * L
	var pt := 0.85 + 0.15 * sin(_t * 3.0)
	draw_polygon(PackedVector2Array([far, far + Vector2(-1.7, -0.10) * L, far + Vector2(-1.7, 0.14) * L]),
		PackedColorArray([Color(1, 0.9, 0.6, 0.30 * pt), Color(1, 0.9, 0.6, 0.0), Color(1, 0.9, 0.6, 0.0)]))
	draw_colored_polygon(pts, koyu)
	for p in [Vector2(-0.31, 0.0), Vector2(0.30, 0.0)]:
		draw_circle(taban + p * L + Vector2(0, -0.07) * L, 0.075 * L, Color(0.01, 0.01, 0.015))
		draw_arc(taban + p * L + Vector2(0, -0.07) * L, 0.075 * L, 0.0, TAU, 20, Color(0.5, 0.4, 0.3, 0.35), 1.2 * s)
	# camlar
	draw_colored_polygon(PackedVector2Array([taban + Vector2(-0.13, -0.28) * L, taban + Vector2(-0.115, -0.385) * L, taban + Vector2(0.04, -0.395) * L, taban + Vector2(0.04, -0.28) * L]), Color(0.35, 0.25, 0.18, 0.5))
	draw_colored_polygon(PackedVector2Array([taban + Vector2(0.07, -0.28) * L, taban + Vector2(0.07, -0.395) * L, taban + Vector2(0.19, -0.38) * L, taban + Vector2(0.25, -0.28) * L]), Color(0.35, 0.25, 0.18, 0.5))
	draw_polyline(pts, Color(0.7, 0.55, 0.4, 0.25), 1.2 * s)
	draw_circle(far, 4.0 * s, Color(1, 0.95, 0.75))
	draw_circle(far, 10.0 * s, Color(1, 0.85, 0.5, 0.25 * pt))

func _adam(ayak: Vector2, H: float, s: float) -> void:
	var koyu := Color(0.012, 0.012, 0.02)
	var palto := [Vector2(-0.075, -0.665), Vector2(-0.16, -0.62), Vector2(-0.165, -0.45), Vector2(-0.14, -0.36), Vector2(-0.19, -0.20),
		Vector2(-0.21, -0.17), Vector2(0.21, -0.17), Vector2(0.19, -0.20), Vector2(0.14, -0.36), Vector2(0.165, -0.45), Vector2(0.16, -0.62), Vector2(0.075, -0.665)]
	var pts := PackedVector2Array()
	for p in palto:
		pts.append(ayak + p * H)
	draw_colored_polygon(pts, koyu)
	# bacaklar
	draw_colored_polygon(PackedVector2Array([ayak + Vector2(-0.15, -0.18) * H, ayak + Vector2(-0.01, -0.18) * H, ayak + Vector2(-0.02, 0.0) * H, ayak + Vector2(-0.13, 0.0) * H]), koyu)
	draw_colored_polygon(PackedVector2Array([ayak + Vector2(0.01, -0.18) * H, ayak + Vector2(0.15, -0.18) * H, ayak + Vector2(0.13, 0.0) * H, ayak + Vector2(0.02, 0.0) * H]), koyu)
	# yaka, kemer, cep
	draw_line(ayak + Vector2(-0.075, -0.665) * H, ayak + Vector2(0.0, -0.55) * H, Color(0.22, 0.18, 0.15, 0.7), 1.6 * s)
	draw_line(ayak + Vector2(0.075, -0.665) * H, ayak + Vector2(0.0, -0.55) * H, Color(0.22, 0.18, 0.15, 0.7), 1.6 * s)
	draw_line(ayak + Vector2(0.0, -0.55) * H, ayak + Vector2(0.0, -0.18) * H, Color(0.2, 0.17, 0.15, 0.35), 1.2 * s)
	draw_line(ayak + Vector2(-0.14, -0.36) * H, ayak + Vector2(0.14, -0.36) * H, Color(0.22, 0.18, 0.15, 0.4), 1.6 * s)
	# boyun + kafa
	draw_rect(Rect2(ayak + Vector2(-0.025, -0.70) * H, Vector2(0.05, 0.05) * H), koyu)
	draw_circle(ayak + Vector2(0, -0.735) * H, 0.05 * H, koyu)
	# fötr şapka
	draw_colored_polygon(PackedVector2Array([ayak + Vector2(-0.125, -0.772) * H, ayak + Vector2(0.125, -0.782) * H, ayak + Vector2(0.10, -0.758) * H, ayak + Vector2(-0.10, -0.758) * H]), koyu)
	draw_colored_polygon(PackedVector2Array([ayak + Vector2(-0.058, -0.77) * H, ayak + Vector2(-0.05, -0.842) * H, ayak + Vector2(0.05, -0.842) * H, ayak + Vector2(0.058, -0.77) * H]), koyu)
	draw_line(ayak + Vector2(-0.056, -0.787) * H, ayak + Vector2(0.056, -0.787) * H, Color(0.5, 0.2, 0.15, 0.85), 2.0 * s)
	# kenar ışığı (lamba solda)
	draw_polyline(PackedVector2Array([ayak + Vector2(-0.13, 0.0) * H, ayak + Vector2(-0.15, -0.18) * H, ayak + Vector2(-0.19, -0.20) * H, ayak + Vector2(-0.14, -0.36) * H, ayak + Vector2(-0.165, -0.45) * H, ayak + Vector2(-0.16, -0.62) * H, ayak + Vector2(-0.075, -0.665) * H]), Color(1.0, 0.75, 0.4, 0.38), 1.6 * s)
	# sigara + duman
	var ates := ayak + Vector2(-0.066, -0.722) * H
	draw_circle(ates, 2.4 * s, Color(1.0, 0.45, 0.1, 0.9))
	draw_circle(ates, 6.0 * s, Color(1.0, 0.45, 0.1, 0.18))
	for i in 14:
		var f := fposmod(_t * 0.35 + i / 14.0, 1.0)
		var p := ates + Vector2(sin(f * 7.0 + i) * 10.0 * s - f * 22.0 * s, -f * 120.0 * s)
		draw_circle(p, (3.0 + f * 11.0) * s, Color(0.8, 0.78, 0.75, 0.16 * (1.0 - f)))
	# ıslak zemine yansıma
	draw_set_transform(ayak, 0.0, Vector2(1.0, -0.22))
	draw_colored_polygon(PackedVector2Array([Vector2(-0.19, 0.0) * H, Vector2(0.19, 0.0) * H, Vector2(0.15, -0.5) * H, Vector2(-0.15, -0.5) * H]), Color(0.9, 0.6, 0.3, 0.05))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _yagmur(b: Vector2, s: float) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 31
	for i in 150:
		var hiz := r.randf_range(520.0, 900.0) * s
		var x := fposmod(r.randf() * b.x - _t * 60.0 * s, b.x)
		var y := fposmod(r.randf() * b.y + _t * hiz, b.y)
		draw_line(Vector2(x, y), Vector2(x - 5.0 * s, y + 18.0 * s), Color(0.75, 0.82, 1.0, 0.14), 1.0)

func _vinyet(b: Vector2) -> void:
	var adim := 10
	var kal := b.y * 0.05
	for i in adim:
		var a := 0.55 * pow(1.0 - float(i) / adim, 2.0)
		var c := Color(0, 0, 0, a)
		draw_rect(Rect2(0, i * kal * 0.6, b.x, kal * 0.6), c)
		draw_rect(Rect2(0, b.y - (i + 1) * kal * 0.6, b.x, kal * 0.6), c)
		draw_rect(Rect2(i * kal * 0.9, 0, kal * 0.9, b.y), c)
		draw_rect(Rect2(b.x - (i + 1) * kal * 0.9, 0, kal * 0.9, b.y), c)
	# soldan koyulaştır: menü okunaklı olsun
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(b.x * 0.55, 0), Vector2(b.x * 0.55, b.y), Vector2(0, b.y)]),
		PackedColorArray([Color(0, 0, 0, 0.62), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.0), Color(0, 0, 0, 0.62)]))

func _ana_kur() -> void:
	_ana = Control.new()
	_ana.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ana)
	var vp := get_viewport_rect().size
	var kutu := VBoxContainer.new()
	kutu.position = Vector2(vp.x * 0.07, vp.y * 0.13)
	kutu.custom_minimum_size = Vector2(400, 0)
	kutu.add_theme_constant_override("separation", 12)
	_ana.add_child(kutu)
	_sus(kutu)
	var bas := etiket(kutu, "KARA KALEM", 64, ALTIN)
	bas.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	bas.add_theme_constant_override("outline_size", 12)
	_sus(kutu)
	etiket(kutu, "Şehir seninle büyür. Ya da seni yutar.", 18, Color(0.85, 0.78, 0.65))
	var bosluk := Control.new()
	bosluk.custom_minimum_size = Vector2(0, 30)
	kutu.add_child(bosluk)
	var d1 := dugme(kutu, "Yeni oyun", _yeni, 26)
	var dev := dugme(kutu, "Devam et", _devam, 26)
	dev.disabled = not FileAccess.file_exists("user://kayit.dat")
	var d3 := dugme(kutu, "Çıkış", func(): get_tree().quit(), 26)
	for d in [d1, dev, d3]:
		d.custom_minimum_size = Vector2(320, 44)
		d.alignment = HORIZONTAL_ALIGNMENT_LEFT
	var alt := etiket(_ana, "CHICAGO  ·  1920  ·  YASAK DÖNEMİ", 14, Color(1, 0.85, 0.55, 0.55))
	alt.position = Vector2(vp.x * 0.07, vp.y - 48.0)

# Başlık altı/üstü: ince altın çizgi, ortada baklava.
func _sus(ebeveyn: Node) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	h.custom_minimum_size = Vector2(380, 10)
	ebeveyn.add_child(h)
	for i in 3:
		if i == 1:
			var l := etiket(h, "◆", 11, ALTIN)
			l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		else:
			var c := ColorRect.new()
			c.color = Color(ALTIN.r, ALTIN.g, ALTIN.b, 0.7)
			c.custom_minimum_size = Vector2(0, 1.5)
			c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			h.add_child(c)

func _kur_kur() -> void:
	_kur = Control.new()
	_kur.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_kur)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", panel_stil())
	pc.position = Vector2(140, 50)
	pc.custom_minimum_size = Vector2(1000, 600)
	pc.size = Vector2(1000, 600)
	_kur.add_child(pc)
	var dis := VBoxContainer.new()
	dis.add_theme_constant_override("separation", 10)
	pc.add_child(dis)
	etiket(dis, "KARAKTERİNİ OLUŞTUR", 30, ALTIN)
	var orta := HBoxContainer.new()
	orta.add_theme_constant_override("separation", 28)
	orta.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dis.add_child(orta)
	# sol: seçimler
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(600, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	orta.add_child(sc)
	var sol := VBoxContainer.new()
	sol.custom_minimum_size = Vector2(590, 0)
	sol.add_theme_constant_override("separation", 8)
	sc.add_child(sol)
	etiket(sol, "Adın", 18, ALTIN)
	var satir := HBoxContainer.new()
	sol.add_child(satir)
	_ad_giris = LineEdit.new()
	_ad_giris.custom_minimum_size = Vector2(320, 34)
	_ad_giris.max_length = 28
	_ad_giris.add_theme_font_size_override("font_size", Tema.boyut(20))
	_ad_giris.text_changed.connect(func(m: String):
		_p["ad"] = m
		_guncelle())
	satir.add_child(_ad_giris)
	var zar := dugme(satir, "Rastgele", _zar, 16)
	zar.custom_minimum_size = Vector2(110, 34)
	var yas_satir := HBoxContainer.new()
	yas_satir.add_theme_constant_override("separation", 12)
	sol.add_child(yas_satir)
	etiket(yas_satir, "Yaşın", 18, ALTIN)
	var sl := HSlider.new()
	sl.min_value = 18
	sl.max_value = 60
	sl.step = 1
	sl.value = _p["yas"]
	sl.custom_minimum_size = Vector2(260, 24)
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.focus_mode = Control.FOCUS_NONE
	sl.value_changed.connect(func(v: float):
		_p["yas"] = int(v)
		_guncelle())
	yas_satir.add_child(sl)
	_yas_etiket = etiket(yas_satir, "", 20)
	etiket(sol, "Kökenin", 18, ALTIN)
	var kg := ButtonGroup.new()
	var kh := HBoxContainer.new()
	kh.add_theme_constant_override("separation", 8)
	sol.add_child(kh)
	for id in Profil.KOKENLER:
		var k: Dictionary = Profil.KOKENLER[id]
		var b := _secim_dugmesi(kh, k["ad"], kg, _p["koken"] == id, func():
			_p["koken"] = id
			_guncelle())
		b.custom_minimum_size = Vector2(190, 44)
	_koken_acik = etiket(sol, "", 16, SOLUK)
	_koken_acik.custom_minimum_size = Vector2(580, 44)
	_koken_acik.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_aile_satir = VBoxContainer.new()
	sol.add_child(_aile_satir)
	etiket(_aile_satir, "Hangi aile?", 18, ALTIN)
	var ag := ButtonGroup.new()
	var ah := HBoxContainer.new()
	ah.add_theme_constant_override("separation", 8)
	_aile_satir.add_child(ah)
	for id in Profil.AILELER:
		var a: Dictionary = Profil.AILELER[id]
		var b := _secim_dugmesi(ah, a["ad"], ag, _p["aile"] == id, func():
			_p["aile"] = id
			_guncelle())
		b.custom_minimum_size = Vector2(190, 38)
		b.add_theme_color_override("font_color", a["renk"])
		b.add_theme_color_override("font_pressed_color", a["renk"])
		b.add_theme_color_override("font_hover_color", a["renk"])
		b.tooltip_text = a["ozet"]
	etiket(sol, "Geçmişin", 18, ALTIN)
	var gg := ButtonGroup.new()
	var gh := HFlowContainer.new()
	gh.add_theme_constant_override("h_separation", 8)
	gh.add_theme_constant_override("v_separation", 8)
	gh.custom_minimum_size = Vector2(580, 0)
	sol.add_child(gh)
	for id in Profil.GECMISLER:
		var g: Dictionary = Profil.GECMISLER[id]
		var b := _secim_dugmesi(gh, g["ad"], gg, _p["gecmis"] == id, func():
			_p["gecmis"] = id
			_guncelle())
		b.custom_minimum_size = Vector2(180, 36)
	_gecmis_acik = etiket(sol, "", 16, SOLUK)
	_gecmis_acik.custom_minimum_size = Vector2(580, 28)
	_gecmis_acik.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# sağ: özet
	var sag := PanelContainer.new()
	sag.add_theme_stylebox_override("panel", panel_stil(Tema.ARKA2))
	sag.custom_minimum_size = Vector2(330, 0)
	orta.add_child(sag)
	_ozet_kutu = VBoxContainer.new()
	_ozet_kutu.add_theme_constant_override("separation", 6)
	sag.add_child(_ozet_kutu)
	# alt: düğmeler
	var alt := HBoxContainer.new()
	alt.add_theme_constant_override("separation", 14)
	dis.add_child(alt)
	var geri := dugme(alt, "Geri", _geri, 20)
	geri.custom_minimum_size = Vector2(140, 38)
	var bos := Control.new()
	bos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alt.add_child(bos)
	var basla := dugme(alt, "Oyuna başla", _basla, 24)
	basla.custom_minimum_size = Vector2(220, 42)

func _yeni() -> void:
	_ana.visible = false
	_kur.visible = true

func _geri() -> void:
	_kur.visible = false
	_ana.visible = true

func _devam() -> void:
	Profil.yukle_basta = true
	get_tree().change_scene_to_file(OYUN)

func _zar() -> void:
	_p["ad"] = Profil.rastgele_ad()
	_ad_giris.text = _p["ad"]
	_guncelle()

func _secim_dugmesi(ebeveyn: Node, metin: String, grup: ButtonGroup, acik: bool, fn: Callable) -> Button:
	var b := Button.new()
	b.text = metin
	b.toggle_mode = true
	b.button_group = grup
	b.button_pressed = acik
	dugme_giydir(b, 18)
	b.add_theme_stylebox_override("pressed", _dugme_stil(Tema.DUGME_BASILI, ALTIN))
	b.add_theme_stylebox_override("hover_pressed", _dugme_stil(Tema.DUGME_BASILI, ALTIN))
	b.pressed.connect(fn)
	ebeveyn.add_child(b)
	return b

func _guncelle() -> void:
	var p := _p.duplicate()
	var o := Profil.ozet(p)
	_yas_etiket.text = "%d" % p["yas"]
	var k: Dictionary = Profil.KOKENLER[p["koken"]]
	_koken_acik.text = k["ozet"]
	_aile_satir.visible = p["koken"] == "aile"
	if Profil.GECMISLER.has(p["gecmis"]):
		_gecmis_acik.text = Profil.GECMISLER[p["gecmis"]]["ozet"]
	for c in _ozet_kutu.get_children():
		c.queue_free()
	var ad: String = p["ad"].strip_edges()
	etiket(_ozet_kutu, ad if ad != "" else "(adsız)", 26, ALTIN)
	etiket(_ozet_kutu, "%d yaşında · %s" % [p["yas"], Profil.GECMISLER[p["gecmis"]]["ad"]], 16, SOLUK)
	etiket(_ozet_kutu, "", 6)
	var s: Dictionary = o["stat"]
	for st in [["guc", "Güç"], ["nisan", "Nişan"], ["zeka", "Zekâ"], ["karizma", "Karizma"]]:
		var h := HBoxContainer.new()
		_ozet_kutu.add_child(h)
		var l := etiket(h, st[1], 17)
		l.custom_minimum_size = Vector2(90, 0)
		var bar := ProgressBar.new()
		bar.min_value = 0
		bar.max_value = 10
		bar.value = s[st[0]]
		bar.show_percentage = false
		bar.add_theme_stylebox_override("fill", _dugme_stil(Color(0.55, 0.56, 0.6), Color(0.55, 0.56, 0.6)))
		bar.add_theme_stylebox_override("background", _dugme_stil(Color(0.16, 0.17, 0.19), Color(0.16, 0.17, 0.19)))
		bar.custom_minimum_size = Vector2(170, 12)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bar)
		etiket(h, " %d" % s[st[0]], 17, ALTIN)
	etiket(_ozet_kutu, "", 6)
	etiket(_ozet_kutu, "Başlangıç", 18, ALTIN)
	etiket(_ozet_kutu, "Yer: %s" % o["konum"], 16)
	etiket(_ozet_kutu, "Para: $%d temiz · $%d kirli" % [o["temiz"], o["kirli"]], 16)
	if o["kira"] > 0:
		etiket(_ozet_kutu, "Oda kirası: $%d / ay (iş bulmalısın)" % o["kira"], 16, Tema.UYARI)
	if p["koken"] == "aile":
		etiket(_ozet_kutu, "Aylık aile payı: $80 kirli", 16, Tema.IYI)
	if p["koken"] == "yerli":
		etiket(_ozet_kutu, "Meyhane geliri: günlük ~$50", 16, Tema.IYI)
	etiket(_ozet_kutu, "Can: %d" % int(o["hp"]), 16, SOLUK)

func _basla() -> void:
	var ad: String = _p["ad"].strip_edges()
	if ad == "":
		ad = Profil.rastgele_ad()
	var p := _p.duplicate()
	p["ad"] = ad
	Profil.aktif = p
	get_tree().change_scene_to_file(OYUN)
