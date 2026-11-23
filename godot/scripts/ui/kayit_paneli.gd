extends CanvasLayer
const Menu := preload("res://scripts/ui/menu.gd")
const Kayitlar := preload("res://scripts/core/kayitlar.gd")
# Kayıt yuvası seçimi. mod "kaydet": 5 yuva; mod "yukle": 5 yuva + otomatik kayıt. cb(slot) çağrılır.

func kur(mod: String, cb: Callable) -> void:
	layer = 40
	var perde := ColorRect.new()
	perde.color = Color(0, 0, 0, 0.65)
	perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(perde)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Menu.panel_stil())
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.custom_minimum_size = Vector2(520, 0)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var b := Menu.etiket(v, "KAYDET" if mod == "kaydet" else "YÜKLE", 24, Menu.ALTIN)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for s in Kayitlar.SLOTLAR:
		if s == "oto" and mod == "kaydet":
			continue
		var dolu: bool = Kayitlar.var_mi(s)
		var d := Menu.dugme(v, "%s\n%s" % [Kayitlar.ad(s), Kayitlar.ozet(s)], func():
			queue_free()
			cb.call(s), 16)
		d.alignment = HORIZONTAL_ALIGNMENT_LEFT
		d.custom_minimum_size = Vector2(0, 58)
		if mod == "yukle" and not dolu:
			d.disabled = true
	Menu.dugme(v, "Geri", func(): queue_free(), 18)

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
