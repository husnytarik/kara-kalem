extends Control
# Sol altta mini harita: bölge çerçeveleri, işletmeler ve oyuncu noktası.

var oyun: Node
var sokak: Node
var _sin: Rect2

func kur(o: Node, s: Node) -> void:
	oyun = o
	sokak = s
	custom_minimum_size = Vector2(150, 150)
	var x0 := 1e9
	var z0 := 1e9
	var x1 := -1e9
	var z1 := -1e9
	for id in oyun.harita.bolgeler:
		var b: Dictionary = oyun.harita.bolgeler[id]
		x0 = minf(x0, b["x0"])
		z0 = minf(z0, b["z0"])
		x1 = maxf(x1, b["x1"])
		z1 = maxf(z1, b["z1"])
	_sin = Rect2(x0, z0, x1 - x0, z1 - z0)

func _process(_d: float) -> void:
	queue_redraw()

func _p(x: float, z: float) -> Vector2:
	return Vector2((x - _sin.position.x) / _sin.size.x * size.x, (z - _sin.position.y) / _sin.size.y * size.y)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.05, 0.04, 0.9))
	for id in oyun.harita.bolgeler:
		var b: Dictionary = oyun.harita.bolgeler[id]
		var a := _p(b["x0"], b["z0"])
		var c := _p(b["x1"], b["z1"])
		var sahip: String = oyun.hakim_of(id) if oyun.bolge.has(id) else ""
		var r := Color(0.4, 0.29, 0.15, 0.5)
		if sahip != "" and oyun.FAK.has(sahip):
			r = (oyun.FAK[sahip]["renk"] as Color)
			r.a = 0.8
			draw_rect(Rect2(a, c - a), Color(r.r, r.g, r.b, 0.12))
		draw_rect(Rect2(a, c - a), r, false, 1.0)
	for y in oyun.harita.yerler:
		var q := _p(y["pos"].x, y["pos"].z)
		draw_rect(Rect2(q - Vector2(1, 1), Vector2(2, 2)), Color(0.7, 0.6, 0.4, 0.55))
	var o := _p(sokak.oyuncu.global_position.x, sokak.oyuncu.global_position.z)
	draw_circle(o, 3.5, Color("e0a93a"))
	draw_arc(o, 5.5, 0, TAU, 16, Color(1, 1, 1, 0.8), 1.0)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.4, 0.29, 0.15), false, 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(6, 14), "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.9, 0.85, 0.7))
