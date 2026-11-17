extends Control
# Ekran üstü yön göstergesi: evin konumu. Ekrandaysa işaret + mesafe, dışındaysa kenarda ok.

var oyun: Node
var sokak: Node
var _zaman := 0.0
const KENAR := 36.0
const UST := 84.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(d: float) -> void:
	_zaman += d
	queue_redraw()

func _draw() -> void:
	if oyun == null or sokak == null or oyun._ev < 0 or oyun.harita == null:
		return
	var kam: Camera3D = sokak.kamera.kamera()
	if kam == null:
		return
	var yer: Vector3 = oyun.harita.yerler[oyun._ev]["pos"]
	var mesafe: float = sokak.oyuncu.global_position.distance_to(yer)
	var dunya := yer + Vector3(0, 14, 0)
	var boy := get_viewport_rect().size
	var p := kam.unproject_position(dunya)
	var arkada := kam.is_position_behind(dunya)
	var alan := Rect2(KENAR, UST, boy.x - 2.0 * KENAR - 360.0, boy.y - UST - KENAR - 40.0)   # sağ panelin soluna kadar
	var renk := Color("e0b24a")
	var font := ThemeDB.fallback_font
	var yazi := "Ev · %d m" % int(mesafe)
	if not arkada and alan.has_point(p):
		var s := 1.0 + 0.08 * sin(_zaman * 4.0)
		# ev simgesi: çatı + gövde
		var ust := p + Vector2(0, -6)
		draw_colored_polygon(PackedVector2Array([ust + Vector2(-14, 0) * s, ust + Vector2(0, -13) * s, ust + Vector2(14, 0) * s]), renk)
		draw_rect(Rect2(ust + Vector2(-9, 0) * s, Vector2(18, 13) * s), renk)
		draw_rect(Rect2(ust + Vector2(-3, 5) * s, Vector2(6, 8) * s), Color(0.1, 0.08, 0.05))
		draw_string_outline(font, p + Vector2(-34, 26), yazi, HORIZONTAL_ALIGNMENT_CENTER, 68, 14, 6, Color.BLACK)
		draw_string(font, p + Vector2(-34, 26), yazi, HORIZONTAL_ALIGNMENT_CENTER, 68, 14, renk)
		return
	# ekran dışında: oyuncudan eve yönde, alan kenarına kenetlenmiş ok
	var merkez := alan.get_center()
	var yon := p - merkez
	if arkada:
		yon = -yon
	if yon.length() < 1.0:
		yon = Vector2.UP
	yon = yon.normalized()
	var t := 1e9
	if absf(yon.x) > 0.0001:
		t = minf(t, (alan.size.x * 0.5) / absf(yon.x))
	if absf(yon.y) > 0.0001:
		t = minf(t, (alan.size.y * 0.5) / absf(yon.y))
	var k := merkez + yon * t
	var dik := Vector2(-yon.y, yon.x)
	draw_colored_polygon(PackedVector2Array([k + yon * 16.0, k - yon * 10.0 + dik * 12.0, k - yon * 10.0 - dik * 12.0]), renk)
	var yp := k - yon * 30.0 + Vector2(-34, 5)
	draw_string_outline(font, yp, yazi, HORIZONTAL_ALIGNMENT_CENTER, 68, 14, 6, Color.BLACK)
	draw_string(font, yp, yazi, HORIZONTAL_ALIGNMENT_CENTER, 68, 14, renk)
