extends Control
# Sol üstte eski köstekli cep saati: oyun saatini akrep/yelkovanla gösterir, gece kadranı kararır.
const Tema := preload("res://scripts/ui/tema.gd")
var oyun: Node
const C := Vector2(60, 72)
const R := 50.0

func kur(o: Node) -> void:
	oyun = o
	custom_minimum_size = Vector2(130, 130)
	size = Vector2(130, 130)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_d: float) -> void:
	queue_redraw()

func _draw() -> void:
	if oyun == null:
		return
	var f: Font = Tema.yazi_tipi()
	var d: Dictionary = oyun.tarih()
	var saat: float = float(d["saat"]) + float(d["dk"]) / 60.0
	var gece: bool = saat < 6.0 or saat >= 19.5
	var altin := Color("c9972c")
	var altin_a := Color("8a6416")
	var altin_p := Color("f0cf7a")
	# zincir: kurgudan sağa doğru sarkan halkalar (künyenin gazete başlığına bağlanışı)
	var onceki := Vector2(68, 18)
	for k in range(1, 13):
		var t := float(k) / 12.0
		var p := Vector2(68.0 + t * 62.0, 18.0 + sin(t * PI) * 12.0 + t * 6.0)
		draw_line(onceki, p, altin_a, 3.0)
		draw_circle(p, 2.6, altin if k % 2 == 0 else altin_p)
		onceki = p
	# kurgu ve halka
	draw_rect(Rect2(C.x - 6, 10, 12, 12), altin_a)
	draw_rect(Rect2(C.x - 5, 11, 10, 10), altin)
	draw_arc(Vector2(C.x, 8), 8.0, 0.0, TAU, 20, altin_p, 2.5, true)
	# parıltı + kasa
	for g in 3:
		draw_circle(C, R + 6.0 - g * 2.0, Color(1.0, 0.8, 0.35, 0.05 + g * 0.03))
	draw_circle(C, R + 1.0, Color("2a1c08"))
	draw_circle(C, R, altin_a)
	draw_circle(C, R - 2.5, altin_p)
	draw_circle(C, R - 5.0, altin)
	var kadran: Color = Color("e8dcc0") if not gece else Color("1a1f30")
	var murek: Color = Color("2b1d10") if not gece else Color("d8c8a0")
	draw_circle(C, R - 7.5, kadran)
	draw_arc(C, R - 9.5, 0.0, TAU, 48, murek.lerp(kadran, 0.5), 1.0, true)
	# dakika çizgileri ve akrep sayıları
	for m in 60:
		var a := float(m) / 60.0 * TAU - PI / 2.0
		var dir := Vector2(cos(a), sin(a))
		var uz: float = 5.0 if m % 5 == 0 else 2.0
		draw_line(C + dir * (R - 9.5), C + dir * (R - 9.5 - uz), murek, 1.6 if m % 5 == 0 else 0.8)
	var roma := ["XII", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI"]
	for h in 12:
		if h % 3 != 0:
			continue
		var a := float(h) / 12.0 * TAU - PI / 2.0
		var yz: String = roma[h]
		var ts: Vector2 = f.get_string_size(yz, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
		var pos: Vector2 = C + Vector2(cos(a), sin(a)) * (R - 21.0) - Vector2(ts.x / 2.0, -ts.y / 4.0)
		draw_string(f, pos, yz, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, murek)
	# sayısal saat (kadranın alt yarısında)
	var yaz: String = oyun.saat_yazi()
	var ys: Vector2 = f.get_string_size(yaz, HORIZONTAL_ALIGNMENT_LEFT, -1, 12)
	draw_string(f, C + Vector2(-ys.x / 2.0, 20.0), yaz, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, murek)
	# akrep ve yelkovan
	var ha: float = fmod(saat, 12.0) / 12.0 * TAU - PI / 2.0
	var ma: float = (saat - floorf(saat)) * TAU - PI / 2.0
	var hd := Vector2(cos(ha), sin(ha))
	var md := Vector2(cos(ma), sin(ma))
	draw_line(C - hd * 4.0, C + hd * 19.0, murek, 3.4, true)
	draw_line(C - md * 5.0, C + md * 30.0, murek, 2.0, true)
	draw_circle(C, 3.5, altin_a)
	draw_circle(C, 2.0, altin_p)
