extends CanvasLayer
# F10: görüntü efektleri ayar paneli. Değerler sokak.efekt sözlüğünde; her değişiklik anında uygulanır.

var sokak: Node
var _kok: PanelContainer
var _canli: Label
var _satirlar := {}   # anahtar -> HSlider / CheckBox / OptionButton

# [anahtar, etiket, min, maks, adım]
const KAYDIRICILAR := [
	["_baslik", "RENK"],
	["palet_guc", "Palet etkisi", 0.0, 1.0, 0.01],
	["ton", "Gök/sis tonu", 0.0, 1.0, 0.01],
	["doygunluk", "Doygunluk", 0.0, 2.0, 0.01],
	["kontrast", "Kontrast", 0.5, 1.6, 0.01],
	["parlaklik", "Parlaklık", 0.6, 1.5, 0.01],
	["_baslik", "IŞIK / ATMOSFER"],
	["parilti", "Parıltı (glow)", 0.0, 2.0, 0.01],
	["bloom", "Bloom", 0.0, 0.6, 0.01],
	["sis", "Sis yoğunluğu", 0.0, 4.0, 0.05],
	["_baslik", "KARAKALEM ÇİZGİ"],
	["_cizgi"],
	["kalinlik", "Kalınlık (piksel)", 0.5, 4.0, 0.1],
	["d_esik", "Derinlik hassasiyeti (düşük = çok çizgi)", 0.002, 0.06, 0.001],
	["r_esik", "Renk hassasiyeti (düşük = çok çizgi)", 0.04, 0.5, 0.01],
	["koyuluk", "Çizgi koyuluğu", 0.1, 1.0, 0.01],
	["tane", "Kömür grenleri", 0.0, 0.8, 0.01],
	["_baslik", "RENK RUHU (kariyer → renk)"],
	["_kutu", "ruh_acik", "Renk ruhu açık"],
	["_kutu", "ruh_elle", "Elle önizle (oyun verisi yerine aşağıdakileri kullan)"],
	["o_servet", "Önizleme: servet (0 yoksul → 1 milyoner)", 0.0, 1.0, 0.01],
	["o_yas", "Önizleme: yaş (0 genç → 1 ihtiyar)", 0.0, 1.0, 0.01],
	["o_stres", "Önizleme: stres", 0.0, 1.0, 0.01],
	["o_yenilgi", "Önizleme: yenilgi (kırmızı)", 0.0, 1.0, 0.01],
	["r_servet", "Etki gücü: servet → parlaklık", 0.0, 2.0, 0.05],
	["r_yas", "Etki gücü: yaş → grileşme", 0.0, 2.0, 0.05],
	["r_stres", "Etki gücü: stres → kasvet", 0.0, 2.0, 0.05],
	["r_yenilgi", "Etki gücü: yenilgi → kırmızı", 0.0, 2.0, 0.05],
]

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_kok = PanelContainer.new()
	_kok.theme = load("res://scripts/ui/tema.gd").tema()
	_kok.position = Vector2(20, 320)
	var sbx := StyleBoxFlat.new()
	sbx.bg_color = Color(0.07, 0.06, 0.05, 0.94)
	sbx.border_color = Color(0.75, 0.6, 0.3)
	sbx.set_border_width_all(2)
	sbx.set_content_margin_all(10)
	_kok.add_theme_stylebox_override("panel", sbx)
	_kok.custom_minimum_size = Vector2(420, 0)
	_kok.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_kok)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(420, 580)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_kok.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	sc.add_child(v)
	var b := Label.new()
	b.text = "GÖRÜNTÜ EFEKTLERİ  (F10: kapat)"
	v.add_child(b)
	# palet
	var pr := HBoxContainer.new()
	var pl := Label.new()
	pl.text = "Palet"
	pl.custom_minimum_size.x = 140
	pr.add_child(pl)
	var ob := OptionButton.new()
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for p in sokak._PALETLER:
		ob.add_item(p[0])
	ob.item_selected.connect(func(i: int) -> void:
		sokak._palet_sec(i)
		_yenile())
	pr.add_child(ob)
	v.add_child(pr)
	_satirlar["palet"] = ob
	for d in KAYDIRICILAR:
		if d[0] == "_baslik":
			var h := Label.new()
			h.text = "— " + d[1] + " —"
			h.modulate = Color(1.0, 0.85, 0.5)
			v.add_child(h)
		elif d[0] == "_cizgi" or d[0] == "_kutu":
			var kk: String = "cizgi" if d[0] == "_cizgi" else d[1]
			var cb := CheckBox.new()
			cb.text = "Çizgi (outline) açık" if d[0] == "_cizgi" else d[2]
			cb.toggled.connect(func(on: bool) -> void:
				sokak.efekt[kk] = on
				sokak.efekt_uygula())
			v.add_child(cb)
			_satirlar[kk] = cb
		else:
			_slider(v, d)
	_canli = Label.new()
	_canli.modulate = Color(0.8, 0.9, 1.0)
	v.add_child(_canli)
	var sb := Button.new()
	sb.text = "Varsayılana sıfırla"
	sb.pressed.connect(func() -> void:
		sokak.efekt_sifirla()
		_yenile())
	v.add_child(sb)
	visible = false

func _slider(v: Node, d: Array) -> void:
	var l := Label.new()
	l.text = d[1]
	v.add_child(l)
	var r := HBoxContainer.new()
	var s := HSlider.new()
	s.min_value = d[2]
	s.max_value = d[3]
	s.step = d[4]
	s.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s.custom_minimum_size.y = 20
	var n := Label.new()
	n.custom_minimum_size.x = 56
	n.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var key: String = d[0]
	s.value_changed.connect(func(x: float) -> void:
		sokak.efekt[key] = x
		n.text = "%.3f" % x if d[4] < 0.01 else "%.2f" % x
		sokak.efekt_uygula())
	r.add_child(s)
	r.add_child(n)
	v.add_child(r)
	_satirlar[key] = s

func _yenile() -> void:
	for k in _satirlar:
		var w = _satirlar[k]
		if w is HSlider:
			w.set_value_no_signal(float(sokak.efekt[k]))
			# etiketi güncellemek için sinyali elle tetikle
			w.value_changed.emit(w.value)
		elif w is CheckBox:
			w.set_pressed_no_signal(bool(sokak.efekt[k]))
		elif w is OptionButton:
			w.select(int(sokak.efekt[k]))

func degistir() -> void:
	visible = not visible
	if visible:
		_yenile()
	else:
		sokak.efekt_kaydet()

func _process(_d: float) -> void:
	if visible and _canli != null:
		var g: Dictionary = sokak.ruh_gercek()
		_canli.text = "Oyundaki gerçek değerler: servet %.2f · yaş %.2f · stres %.2f · yenilgi %.2f" % [g["servet"], g["yas"], g["stres"], g["yenilgi"]]
