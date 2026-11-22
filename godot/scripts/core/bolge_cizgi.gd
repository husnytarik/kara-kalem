extends Node3D
# Haritada mahalle sınırlarında ışıklı altın çizgiler ve kâğıt üstünde mahalle adı tabelaları.
# Sahibine göre renk değişir: oyuncu altın, aileler kendi renginde, sahipsiz soluk.

const Tema := preload("res://scripts/ui/tema.gd")
const SIMGE := {"oyuncu": "♛", "marchetti": "♛", "obrien": "☘", "tammany": "✦"}

var oyun: Node
var harita: Node
var sokak: Node
var _cizgi: Dictionary = {}    # id -> [bant ShaderMaterial, perde ShaderMaterial]
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
	_goster(false)

# Mahalle sınırı: haritacı/mülk çizimi gibi. Yerde mürekkep çizgisi (kesik kesik akan) + içe doğru taralı bant,
# yukarıda sınır boyunca direkler ve solan bir "perde". Sahibin rengi, oyuncunun bulunduğu mahalle parlak.
const BANT := 16.0     # içe doğru tarama bandı (m)
const PERDE := 90.0    # ışık hüzmesinin yüksekliği (m)

const BANT_SH := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 renk : source_color = vec4(0.9, 0.7, 0.3, 1.0);
uniform float guc = 0.5;
uniform float bant = 16.0;
void fragment() {
	float x = UV.x;
	float d = UV.y;
	float kenar = smoothstep(0.0, 0.25, d) * (1.0 - smoothstep(0.9, 1.3, d));
	float kesik = step(0.38, fract((x - TIME * 2.0) / 7.0));
	float ince = smoothstep(2.3, 2.45, d) * (1.0 - smoothstep(2.65, 2.8, d));
	float sol = 1.0 - smoothstep(2.0, bant, d);
	float tarama = step(0.84, fract((x + d) / 2.4)) * sol * 0.85;
	float dolgu = pow(1.0 - clamp(d / bant, 0.0, 1.0), 2.0) * 0.28;
	float a = max(max(kenar * mix(0.55, 1.0, kesik), ince * 0.7), max(tarama, dolgu));
	ALBEDO = renk.rgb;
	ALPHA = clamp(a * guc, 0.0, 1.0);
}
"""

const PERDE_SH := """
shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled, fog_disabled;
uniform vec4 renk : source_color = vec4(0.9, 0.7, 0.3, 1.0);
uniform float guc = 0.5;
uniform float yuk = 90.0;
void fragment() {
	float x = UV.x;
	float h = clamp(UV.y / yuk, 0.0, 1.0);
	float sol = pow(1.0 - h, 1.7);
	// yerden yükselen ışık hüzmesi: dikey şeritler + yukarı kayan parıltı paketleri
	float serit = 0.55 + 0.45 * sin(x * 1.7 + sin(x * 0.31) * 2.0);
	float paket = smoothstep(0.0, 0.5, fract(h * 2.2 - TIME * 0.22 + x * 0.013)) * (1.0 - smoothstep(0.5, 1.0, fract(h * 2.2 - TIME * 0.22 + x * 0.013)));
	float perde = sol * (0.26 + 0.18 * serit + 0.35 * paket * serit);
	// sınır boyunca her 24 m'de parlak ışık sütunu
	float c = abs(fract(x / 24.0) - 0.5) * 24.0;
	float sutun = (1.0 - smoothstep(0.0, 1.1, c)) * pow(1.0 - h, 1.2) * 0.95;
	float taban = (1.0 - smoothstep(0.0, 0.035, h)) * 0.9;
	ALBEDO = renk.rgb;
	ALPHA = clamp((perde + sutun + taban) * guc, 0.0, 1.0);
}
"""

func _cizgi_kur(id: String) -> void:
	var b: Dictionary = harita.bolgeler[id]
	var pl: Array = b.get("poly", [])
	if pl.size() < 3:
		pl = [[b["x0"], b["z0"]], [b["x1"], b["z0"]], [b["x1"], b["z1"]], [b["x0"], b["z1"]]]
	var mrk: Vector2 = harita.poly_agirlik(b)
	# kenarlar: [başlangıç, bitiş, içe doğru birim vektör]
	var kenarlar := []
	for i in pl.size():
		var pa: Array = pl[i]
		var pc: Array = pl[(i + 1) % pl.size()]
		var ea := Vector2(pa[0], pa[1])
		var ec := Vector2(pc[0], pc[1])
		var dd := (ec - ea).normalized()
		var nn := Vector2(-dd.y, dd.x)
		if nn.dot(mrk - ea) < 0.0:
			nn = -nn
		kenarlar.append([ea, ec, nn])
	var bsh := Shader.new()
	bsh.code = BANT_SH
	var psh := Shader.new()
	psh.code = PERDE_SH
	var bm := ShaderMaterial.new()
	bm.shader = bsh
	bm.render_priority = -1
	var pm := ShaderMaterial.new()
	pm.shader = psh
	pm.render_priority = -1
	var bim := ImmediateMesh.new()
	var pim := ImmediateMesh.new()
	for k in kenarlar:
		var a: Vector2 = k[0]
		var c: Vector2 = k[1]
		var inw: Vector2 = k[2]
		var uz := a.distance_to(c)
		var dir := (c - a) / uz
		var n := int(ceil(uz / 8.0))
		bim.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		pim.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		for i in n + 1:
			var m := minf(float(i) * 8.0, uz)
			var p: Vector2 = a + dir * m
			var q: Vector2 = p + inw * BANT
			var y0: float = harita.yuk(p.x, p.y, false) + 0.45
			var y1: float = harita.yuk(q.x, q.y, false) + 0.45
			bim.surface_set_uv(Vector2(m, 0.0))
			bim.surface_add_vertex(Vector3(p.x, y0, p.y))
			bim.surface_set_uv(Vector2(m, BANT))
			bim.surface_add_vertex(Vector3(q.x, y1, q.y))
			pim.surface_set_uv(Vector2(m, 0.0))
			pim.surface_add_vertex(Vector3(p.x, y0, p.y))
			pim.surface_set_uv(Vector2(m, PERDE))
			pim.surface_add_vertex(Vector3(p.x, y0 + PERDE, p.y))
		bim.surface_end()
		pim.surface_end()
	for i in kenarlar.size():
		bim.surface_set_material(i, bm)
		pim.surface_set_material(i, pm)
	for im in [bim, pim]:
		var mi := MeshInstance3D.new()
		mi.mesh = im
		_meshler.append(mi)
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	_cizgi[id] = [bm, pm]

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

# Hüzmeler yalnızca mahalleler paneli açıkken görünür; seçili mahalle daha parlak.
var _acik := false
var _meshler: Array = []

func _goster(a: bool) -> void:
	for m in _meshler:
		(m as MeshInstance3D).visible = a
var _secili := ""

func _process(d: float) -> void:
	_sure += d
	var ar: Node = sokak.arayuz
	var ac: bool = ar != null and ar._mod == "bolge" and ar._sag.visible
	var sec: String = str(ar._hedef) if ac else ""
	if ac != _acik or sec != _secili:
		_acik = ac
		_secili = sec
		_goster(ac)
		_sure = 2.0
	if _acik and _sure > 1.0:
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
		if id == _secili:
			a = 1.0
		for mt in _cizgi[id]:
			(mt as ShaderMaterial).set_shader_parameter("renk", Color(r.r, r.g, r.b, 1.0))
			(mt as ShaderMaterial).set_shader_parameter("guc", a * 2.4)
		var t: Dictionary = _tabela[id]
		var simge: String = SIMGE.get(sahip, "")
		(t["l"] as Label3D).text = ("%s " % simge if simge != "" else "") + String(harita.bolgeler[id]["ad"])
