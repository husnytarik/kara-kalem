extends Control
# Ana menü ve karakter yaratma. Her şey kodla kuruluyor (arayuz.gd gibi).
# Komut satırı argümanı varsa (test/doğrulama) menü atlanır; --menu ana menüyü, --kur karakter ekranını açar.

const Profil := preload("res://scripts/core/profil.gd")
const ALTIN := Color("e0b24a")
const SOLUK := Color(1, 1, 1, 0.6)
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

# ---------- ortak görünüm yardımcıları (duraklat.gd de kullanır) ----------
static func panel_stil(arka: Color = Color(0.06, 0.06, 0.08, 0.94)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = arka
	sb.border_color = Color(0.7, 0.55, 0.2, 0.9)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(18)
	return sb

static func _dugme_stil(c: Color, kenar: Color = Color(0.55, 0.42, 0.16)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = c
	sb.border_color = kenar
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(5)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

static func dugme_giydir(b: Button, boyut: int = 22) -> void:
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", boyut)
	b.add_theme_stylebox_override("normal", _dugme_stil(Color(0.12, 0.11, 0.13)))
	b.add_theme_stylebox_override("hover", _dugme_stil(Color(0.2, 0.17, 0.1), ALTIN))
	b.add_theme_stylebox_override("pressed", _dugme_stil(Color(0.45, 0.33, 0.1), ALTIN))
	b.add_theme_stylebox_override("disabled", _dugme_stil(Color(0.09, 0.09, 0.1), Color(0.25, 0.25, 0.27)))
	b.add_theme_color_override("font_color", Color(0.92, 0.88, 0.8))
	b.add_theme_color_override("font_disabled_color", Color(1, 1, 1, 0.25))

static func dugme(ebeveyn: Node, metin: String, fn: Callable, boyut: int = 22) -> Button:
	var b := Button.new()
	b.text = metin
	b.custom_minimum_size = Vector2(0, 46)
	dugme_giydir(b, boyut)
	b.pressed.connect(fn)
	ebeveyn.add_child(b)
	return b

static func etiket(ebeveyn: Node, metin: String, boyut: int = 16, renk: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_color", renk)
	ebeveyn.add_child(l)
	return l

# ---------- kurulum ----------
func _ready() -> void:
	Engine.time_scale = 1.0
	var args := OS.get_cmdline_user_args()
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

func _draw() -> void:
	var b := size
	# gece gökyüzü
	var ust := Color(0.03, 0.03, 0.06)
	var alt := Color(0.16, 0.10, 0.09)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(b.x, 0), Vector2(b.x, b.y), Vector2(0, b.y)]),
		PackedColorArray([ust, ust, alt, alt]))
	draw_circle(Vector2(b.x * 0.78, b.y * 0.2), 46.0, Color(0.9, 0.86, 0.7, 0.9))
	draw_circle(Vector2(b.x * 0.78 + 14, b.y * 0.2 - 8), 40.0, Color(0.06, 0.05, 0.08, 0.35))
	# silüet: iki katman bina + yanan pencereler
	var r := RandomNumberGenerator.new()
	for katman in 2:
		r.seed = 77 + katman
		var x := -20.0
		var taban := b.y * (0.88 if katman == 0 else 1.0)
		var renk := Color(0.07, 0.06, 0.09) if katman == 0 else Color(0.035, 0.03, 0.05)
		while x < b.x:
			var w := r.randf_range(50.0, 130.0)
			var h := r.randf_range(90.0, 330.0 if katman == 0 else 200.0)
			draw_rect(Rect2(x, taban - h, w, h + 60), renk)
			if katman == 0:
				var wy := taban - h + 14
				while wy < taban - 16:
					var wx := x + 8
					while wx < x + w - 12:
						if r.randf() < 0.28:
							var titre := 0.75 + 0.25 * sin(_t * 1.5 + wx * 0.13 + wy)
							draw_rect(Rect2(wx, wy, 6, 8), Color(1.0, 0.82, 0.45, 0.65 * titre))
						wx += 16
					wy += 22
			x += w + r.randf_range(0.0, 8.0)
	draw_rect(Rect2(0, 0, b.x, b.y), Color(0, 0, 0, 0.18))

func _ana_kur() -> void:
	_ana = Control.new()
	_ana.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_ana)
	var kutu := VBoxContainer.new()
	kutu.position = Vector2(96, 120)
	kutu.custom_minimum_size = Vector2(420, 0)
	kutu.add_theme_constant_override("separation", 12)
	_ana.add_child(kutu)
	var bas := etiket(kutu, "KARA KALEM", 72, ALTIN)
	bas.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	bas.add_theme_constant_override("outline_size", 12)
	etiket(kutu, "Şehir seninle büyür. Ya da seni yutar.", 20, SOLUK)
	var bosluk := Control.new()
	bosluk.custom_minimum_size = Vector2(0, 34)
	kutu.add_child(bosluk)
	dugme(kutu, "Yeni oyun", _yeni, 28)
	var dev := dugme(kutu, "Devam et", _devam, 28)
	dev.disabled = not FileAccess.file_exists("user://kayit.dat")
	dugme(kutu, "Çıkış", func(): get_tree().quit(), 28)
	var alt := etiket(_ana, "Chicago · 1920'ler · Yasak dönemi", 15, Color(1, 1, 1, 0.35))
	alt.position = Vector2(96, 680)

func _kur_kur() -> void:
	_kur = Control.new()
	_kur.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_kur)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", panel_stil())
	pc.position = Vector2(60, 36)
	pc.custom_minimum_size = Vector2(1160, 648)
	pc.size = Vector2(1160, 648)
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
	sc.custom_minimum_size = Vector2(700, 0)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	orta.add_child(sc)
	var sol := VBoxContainer.new()
	sol.custom_minimum_size = Vector2(690, 0)
	sol.add_theme_constant_override("separation", 8)
	sc.add_child(sol)
	etiket(sol, "Adın", 18, ALTIN)
	var satir := HBoxContainer.new()
	sol.add_child(satir)
	_ad_giris = LineEdit.new()
	_ad_giris.custom_minimum_size = Vector2(380, 40)
	_ad_giris.max_length = 28
	_ad_giris.add_theme_font_size_override("font_size", 20)
	_ad_giris.text_changed.connect(func(m: String):
		_p["ad"] = m
		_guncelle())
	satir.add_child(_ad_giris)
	var zar := dugme(satir, "Rastgele", _zar, 16)
	zar.custom_minimum_size = Vector2(130, 40)
	var yas_satir := HBoxContainer.new()
	yas_satir.add_theme_constant_override("separation", 12)
	sol.add_child(yas_satir)
	etiket(yas_satir, "Yaşın", 18, ALTIN)
	var sl := HSlider.new()
	sl.min_value = 18
	sl.max_value = 60
	sl.step = 1
	sl.value = _p["yas"]
	sl.custom_minimum_size = Vector2(300, 28)
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
		b.custom_minimum_size = Vector2(220, 56)
	_koken_acik = etiket(sol, "", 16, SOLUK)
	_koken_acik.custom_minimum_size = Vector2(680, 50)
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
		b.custom_minimum_size = Vector2(220, 48)
		b.add_theme_color_override("font_color", a["renk"])
		b.add_theme_color_override("font_pressed_color", a["renk"])
		b.add_theme_color_override("font_hover_color", a["renk"])
		b.tooltip_text = a["ozet"]
	etiket(sol, "Geçmişin", 18, ALTIN)
	var gg := ButtonGroup.new()
	var gh := HFlowContainer.new()
	gh.add_theme_constant_override("h_separation", 8)
	gh.add_theme_constant_override("v_separation", 8)
	gh.custom_minimum_size = Vector2(680, 0)
	sol.add_child(gh)
	for id in Profil.GECMISLER:
		var g: Dictionary = Profil.GECMISLER[id]
		var b := _secim_dugmesi(gh, g["ad"], gg, _p["gecmis"] == id, func():
			_p["gecmis"] = id
			_guncelle())
		b.custom_minimum_size = Vector2(210, 44)
	_gecmis_acik = etiket(sol, "", 16, SOLUK)
	_gecmis_acik.custom_minimum_size = Vector2(680, 30)
	_gecmis_acik.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	# sağ: özet
	var sag := PanelContainer.new()
	sag.add_theme_stylebox_override("panel", panel_stil(Color(0.1, 0.09, 0.1, 0.95)))
	sag.custom_minimum_size = Vector2(380, 0)
	orta.add_child(sag)
	_ozet_kutu = VBoxContainer.new()
	_ozet_kutu.add_theme_constant_override("separation", 6)
	sag.add_child(_ozet_kutu)
	# alt: düğmeler
	var alt := HBoxContainer.new()
	alt.add_theme_constant_override("separation", 14)
	dis.add_child(alt)
	var geri := dugme(alt, "Geri", _geri, 20)
	geri.custom_minimum_size = Vector2(160, 46)
	var bos := Control.new()
	bos.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	alt.add_child(bos)
	var basla := dugme(alt, "Oyuna başla", _basla, 24)
	basla.custom_minimum_size = Vector2(260, 52)

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
	b.add_theme_stylebox_override("pressed", _dugme_stil(Color(0.42, 0.31, 0.09), ALTIN))
	b.add_theme_stylebox_override("hover_pressed", _dugme_stil(Color(0.48, 0.35, 0.1), ALTIN))
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
		bar.add_theme_stylebox_override("fill", _dugme_stil(ALTIN, ALTIN))
		bar.add_theme_stylebox_override("background", _dugme_stil(Color(0.18, 0.17, 0.18), Color(0.3, 0.3, 0.3)))
		bar.custom_minimum_size = Vector2(190, 18)
		bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(bar)
		etiket(h, " %d" % s[st[0]], 17, ALTIN)
	etiket(_ozet_kutu, "", 6)
	etiket(_ozet_kutu, "Başlangıç", 18, ALTIN)
	etiket(_ozet_kutu, "Yer: %s" % o["konum"], 16)
	etiket(_ozet_kutu, "Para: $%d temiz · $%d kirli" % [o["temiz"], o["kirli"]], 16)
	if o["kira"] > 0:
		etiket(_ozet_kutu, "Oda kirası: $%d / ay (iş bulmalısın)" % o["kira"], 16, Color("f0b060"))
	if p["koken"] == "aile":
		etiket(_ozet_kutu, "Aylık aile payı: $80 kirli", 16, Color("7ed07e"))
	if p["koken"] == "yerli":
		etiket(_ozet_kutu, "Meyhane geliri: günlük ~$50", 16, Color("7ed07e"))
	etiket(_ozet_kutu, "Can: %d" % int(o["hp"]), 16, SOLUK)

func _basla() -> void:
	var ad: String = _p["ad"].strip_edges()
	if ad == "":
		ad = Profil.rastgele_ad()
	var p := _p.duplicate()
	p["ad"] = ad
	Profil.aktif = p
	get_tree().change_scene_to_file(OYUN)
