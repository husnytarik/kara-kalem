extends Control
# Ekranın alt köşesinde çeyrek daire (pie) menü. sol=true: sol alt köşe, değilse sağ alt köşe.
const Tema := preload("res://scripts/ui/tema.gd")
const Dugme := preload("res://scripts/ui/pie_dugme.gd")
const BOY := 190.0
const YARICAP := 128.0
var sol := true

# ogeler: [[glif, ad, Callable], ...]
func kur(sol_mu: bool, ogeler: Array) -> void:
	sol = sol_mu
	custom_minimum_size = Vector2(BOY, BOY)
	size = Vector2(BOY, BOY)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var n: int = ogeler.size()
	for i in n:
		var aci: float = deg_to_rad(10.0 + 70.0 * float(i) / float(maxi(1, n - 1)))
		var ofs := Vector2(cos(aci), sin(aci)) * YARICAP
		var m: Vector2 = Vector2(ofs.x, BOY - ofs.y) if sol else Vector2(BOY - ofs.x, BOY - ofs.y)
		var d: Control = Dugme.new()
		d.kur(ogeler[i][0], ogeler[i][1], 1 if sol else -1, ogeler[i][2])
		d.position = m - Vector2(Dugme.CAP / 2.0, Dugme.CAP / 2.0)
		add_child(d)

func _draw() -> void:
	# çeyrek daire arka planı: koyu deri + parlayan altın yay çizgileri
	var kose := Vector2(0, BOY) if sol else Vector2(BOY, BOY)
	var bas: float = -PI / 2.0 if sol else PI
	var son: float = 0.0 if sol else 3.0 * PI / 2.0
	var pts := PackedVector2Array([kose])
	var adim := 28
	for k in range(adim + 1):
		var a: float = bas + (son - bas) * float(k) / float(adim)
		pts.append(kose + Vector2(cos(a), sin(a)) * 178.0)
	draw_colored_polygon(pts, Color(0.07, 0.05, 0.03, 0.62))
	for r in [178.0, 72.0]:
		for g in 3:
			draw_arc(kose, r, bas, son, 40, Color(1.0, 0.78, 0.3, 0.06 + 0.04 * g), 7.0 - g * 2.5, true)
		draw_arc(kose, r, bas, son, 40, Color("c9972c"), 1.5, true)

func hepsini_ac() -> void:   # test: tüm kâğıtları aç
	var k := get_children()
	if k.size() > 2:
		k[2]._hover(true)
