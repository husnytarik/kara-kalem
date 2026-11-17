extends Node3D
# Haritada bölge sınırlarında ışıklı altın çizgiler ve kâğıt üstünde bölge adı tabelaları.
# Sahibine göre renk değişir: oyuncu altın, aileler kendi renginde, sahipsiz soluk.

const Tema := preload("res://scripts/ui/tema.gd")
const SIMGE := {"oyuncu": "♛", "marchetti": "♛", "obrien": "☘", "tammany": "✦"}

var oyun: Node
var harita: Node
var sokak: Node
var _cizgi: Dictionary = {}    # id -> StandardMaterial3D
var _tabela: Dictionary = {}   # id -> {"l": Label3D, "s": Sprite3D}
var _sure := 0.0

func kur(o: Node, h: Node, s: Node) -> void:
	oyun = o
	harita = h
	sokak = s
	for id in harita.bolgeler:
		_cizgi_kur(id)
		_tabela_kur(id)
	_renk_guncelle()

func _cizgi_kur(id: String) -> void:
	var b: Dictionary = harita.bolgeler[id]
	var pts: Array = []
	var x0: float = b["x0"]
	var z0: float = b["z0"]
	var x1: float = b["x1"]
	var z1: float = b["z1"]
	var adim := 8.0
	var x := x0
	while x < x1:
		pts.append(Vector2(x, z0))
		x += adim
	var z := z0
	while z < z1:
		pts.append(Vector2(x1, z))
		z += adim
	x = x1
	while x > x0:
		pts.append(Vector2(x, z1))
		x -= adim
	z = z1
	while z > z0:
		pts.append(Vector2(x0, z))
		z -= adim
	pts.append(pts[0])
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.no_depth_test = false
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP, m)
	var w := 1.8
	for i in pts.size():
		var p: Vector2 = pts[i]
		var q: Vector2 = pts[(i + 1) % pts.size()] if i < pts.size() - 1 else pts[i - 1]
		var dir := (q - p).normalized() if i < pts.size() - 1 else (p - q).normalized()
		var nrm := Vector2(-dir.y, dir.x)
		var y: float = harita.yuk(p.x, p.y, false) + 0.5
		im.surface_add_vertex(Vector3(p.x + nrm.x * w, y, p.y + nrm.y * w))
		im.surface_add_vertex(Vector3(p.x - nrm.x * w, y, p.y - nrm.y * w))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	_cizgi[id] = m

func _tabela_kur(id: String) -> void:
	var ad: String = harita.bolgeler[id]["ad"]
	var l := Label3D.new()
	l.font_size = 120
	l.pixel_size = 0.1
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.modulate = Tema.KAGIT_YAZI
	l.outline_size = 0
	l.no_depth_test = true
	l.fixed_size = false
	l.render_priority = 2
	l.text = ad
	var sz := ThemeDB.fallback_font.get_string_size("♛ " + ad, HORIZONTAL_ALIGNMENT_LEFT, -1, 120)
	var gw := sz.x * 0.1 + 16.0
	var gh := 26.0
	var k := 4.0
	var sp := Sprite3D.new()
	sp.texture = Tema.kagit_tex(int(gw / (0.1 * k)), int(gh / (0.1 * k)), Tema.KAGIT, Color("2b1b0c"))
	sp.pixel_size = 0.1 * k
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.no_depth_test = true
	sp.render_priority = 1
	sp.shaded = false
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var c: Vector3 = harita.merkez(id) + Vector3(0, 60, 0)
	sp.position = c
	l.position = c
	for n in [sp, l]:
		n.visibility_range_begin = 150.0
		n.scale = Vector3.ONE * 0.5
	add_child(sp)
	add_child(l)
	_tabela[id] = {"l": l, "s": sp}

func _process(d: float) -> void:
	_sure += d
	if _sure > 1.0:
		_sure = 0.0
		_renk_guncelle()

func _renk_guncelle() -> void:
	var oyuncu_b: String = harita.bolge_at(sokak.oyuncu.global_position)
	for id in _cizgi:
		var sahip: String = oyun.hakim_of(id) if oyun.bolge.has(id) else ""
		var r := Color(0.9, 0.7, 0.3)
		var a := 0.22
		if sahip == "oyuncu":
			a = 0.9
		elif sahip != "" and oyun.FAK.has(sahip):
			r = oyun.FAK[sahip]["renk"]
			a = 0.55
		if id == oyuncu_b:
			a = minf(1.0, a + 0.3)
		(_cizgi[id] as StandardMaterial3D).albedo_color = Color(r.r, r.g, r.b, a)
		var t: Dictionary = _tabela[id]
		var simge: String = SIMGE.get(sahip, "")
		(t["l"] as Label3D).text = ("%s " % simge if simge != "" else "") + String(harita.bolgeler[id]["ad"])
