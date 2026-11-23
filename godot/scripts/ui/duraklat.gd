extends CanvasLayer
const Menu := preload("res://scripts/ui/menu.gd")
# Esc ile açılan duraklatma menüsü: devam, kaydet, yükle, ana menü, çık.

func kur(sokak: Node) -> void:
	layer = 30
	var perde := ColorRect.new()
	perde.color = Color(0, 0, 0, 0.6)
	perde.set_anchors_preset(Control.PRESET_FULL_RECT)
	perde.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(perde)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Menu.panel_stil())
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.custom_minimum_size = Vector2(290, 0)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var b := Label.new()
	b.text = "DURAKLATILDI"
	b.add_theme_font_size_override("font_size", Menu.Tema.boyut(24))
	b.add_theme_color_override("font_color", Menu.ALTIN)
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(b)
	Menu.dugme(v, "Devam", func(): queue_free())
	Menu.dugme(v, "Kaydet (F6 hızlı)", func():
		var kp: CanvasLayer = load("res://scripts/ui/kayit_paneli.gd").new()
		add_child(kp)
		kp.kur("kaydet", func(s: String):
			sokak.kaydet(s)
			queue_free()))
	Menu.dugme(v, "Yükle (F9 hızlı)", func():
		var kp: CanvasLayer = load("res://scripts/ui/kayit_paneli.gd").new()
		add_child(kp)
		kp.kur("yukle", func(s: String):
			sokak.yukle(s)
			queue_free()))
	Menu.dugme(v, "Ana menü", func():
		Engine.time_scale = 1.0
		sokak.get_tree().change_scene_to_file("res://scenes/menu.tscn"))
	Menu.dugme(v, "Oyundan çık", func(): sokak.get_tree().quit())

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		queue_free()
