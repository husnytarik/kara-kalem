extends Control
# Pie menü düğmesi: yuvarlak deri/altın düğme. Fare yaklaşınca içinden eski bir kâğıt çıkar, adı yazar.
const Tema := preload("res://scripts/ui/tema.gd")
const CAP := 46.0
var glif := "?"
var etiket := ""
var yon := 1            # +1: kâğıt sağa, -1: sola açılır
var eylem: Callable
var _kagit: Control      # kırpılan kâğıt kutusu (genişliği animasyonla açılır)
var _ic: Control         # kâğıdın içindeki sabit genişlikli içerik
var _kw := 0.0
var _daire: Control
var _t := 0.0
var _tw: Tween
var _ikon: Texture2D
const IKONLAR := {"Aileler": "aileler", "Adamlar": "adamlar", "Mahalleler": "bolgeler", "Polis": "polis", "Defter": "bilgi", "Hedefler": "emir", "Silahlar": "guc", "Beceri": "saygi", "İş": "is", "Garaj": "garaj"}

func kur(g: String, e: String, y: int, fn: Callable) -> void:
	glif = g
	etiket = e
	yon = y
	if IKONLAR.has(e):
		var yol: String = "res://assets/ui/icons/%s.png" % IKONLAR[e]
		if ResourceLoader.exists(yol):
			_ikon = load(yol)
	eylem = fn
	custom_minimum_size = Vector2(CAP, CAP)
	size = Vector2(CAP, CAP)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var f: Font = Tema.yazi_tipi()
	var ts: Vector2 = f.get_string_size(e, HORIZONTAL_ALIGNMENT_LEFT, -1, 17)
	_kw = ts.x + 34.0 + CAP / 2.0
	_kagit = Control.new()
	_kagit.clip_contents = true
	_kagit.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_kagit)
	_ic = Control.new()
	_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.size = Vector2(_kw, 30)
	_kagit.add_child(_ic)
	var sb := StyleBoxTexture.new()
	sb.texture = Tema.kagit_tex(int(_kw / 2.0), 15, Tema.KAGIT, Color("2b1b0c"))
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", sb)
	panel.size = Vector2(_kw, 30)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.add_child(panel)
	var l := Label.new()
	l.text = e
	l.add_theme_font_override("font", f)
	l.add_theme_font_size_override("font_size", 17)
	l.add_theme_color_override("font_color", Tema.KAGIT_YAZI)
	l.size = Vector2(_kw - CAP / 2.0, 30)
	l.position = Vector2(CAP / 2.0 if yon > 0 else 0.0, 0)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ic.add_child(l)
	_daire = Control.new()
	_daire.size = Vector2(CAP, CAP)
	_daire.pivot_offset = Vector2(CAP / 2.0, CAP / 2.0)
	_daire.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_daire.draw.connect(_ciz)
	add_child(_daire)
	_ayarla(0.0)
	mouse_entered.connect(_hover.bind(true))
	mouse_exited.connect(_hover.bind(false))

func _hover(ac: bool) -> void:
	z_index = 10 if ac else 0
	if _tw != null:
		_tw.kill()
	_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_tw.tween_method(_ayarla, _t, 1.0 if ac else 0.0, 0.22)

func _ayarla(v: float) -> void:
	_t = v
	var w: float = _kw * v
	_kagit.visible = v > 0.01
	_kagit.size = Vector2(w, 30)
	# kâğıt düğmenin merkezinden çıkıp dışarı doğru uzar
	if yon > 0:
		_kagit.position = Vector2(CAP / 2.0, CAP / 2.0 - 15.0)
		_ic.position = Vector2(0, 0)
	else:
		_kagit.position = Vector2(CAP / 2.0 - w, CAP / 2.0 - 15.0)
		_ic.position = Vector2(w - _kw, 0)
	_daire.scale = Vector2.ONE * (1.0 + 0.12 * v)
	_daire.queue_redraw()

func _gui_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		if eylem.is_valid():
			eylem.call()
		accept_event()

func _ciz() -> void:
	var c := Vector2(CAP / 2.0, CAP / 2.0)
	var f: Font = Tema.yazi_tipi()
	for g in 3:
		_daire.draw_circle(c, CAP / 2.0 + 5.0 - g * 1.6, Color(1.0, 0.78, 0.3, (0.04 + 0.07 * _t) * (g + 1)))
	_daire.draw_circle(c, CAP / 2.0, Color("2a1c08"))
	_daire.draw_circle(c, CAP / 2.0 - 1.5, Color("b8872a").lerp(Color("f0cf7a"), _t))
	_daire.draw_circle(c, CAP / 2.0 - 4.0, Color("2b1d12").lerp(Color("4a3216"), _t))
	if _ikon != null:
		var bo := 32.0
		_daire.draw_texture_rect(_ikon, Rect2(c - Vector2(bo, bo) / 2.0, Vector2(bo, bo)), false, Color.WHITE.lerp(Color(1.15, 1.1, 1.0), _t))
		return
	var ts: Vector2 = f.get_string_size(glif, HORIZONTAL_ALIGNMENT_LEFT, -1, 22)
	_daire.draw_string(f, c + Vector2(-ts.x / 2.0, 7.5), glif, HORIZONTAL_ALIGNMENT_LEFT, -1, 22, Color("f0cf7a").lerp(Color.WHITE, _t * 0.4))
