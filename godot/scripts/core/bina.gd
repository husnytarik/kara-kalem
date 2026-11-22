@tool
extends Node3D
# Haritadaki bir bina. Şimdilik küp; ileride "Model" adında bir alt düğüm eklersen
# (kendi 3D modelin) küp gizlenir. Değerleri Inspector'dan değiştirebilirsin.
# Konum (position) binanın TABAN ORTASIDIR.

static var _sh: Shader

@export var ad := "":
	set(v):
		ad = v
		_yenile()
@export var bolge := ""
@export var ozel := false:
	set(v):
		ozel = v
		_yenile()
@export var boyut := Vector3(12.0, 10.0, 12.0):   # genişlik, yükseklik, derinlik
	set(v):
		boyut = v
		_yenile()
@export var dolgu := false   # true: süs bina (işletme/özel mekân değil, adı ve etiketi yok)
@export var renk := Color(0.5, 0.4, 0.3):
	set(v):
		renk = v
		_yenile()

var _kutu: MeshInstance3D
var _govde: StaticBody3D
var _etiket: Label3D
var _hat: Node3D

func _ready() -> void:
	add_to_group("bina")
	_yenile()

func _yenile() -> void:
	if not is_inside_tree():
		return
	if get_node_or_null("Model") == null:
		if _kutu == null:
			_kutu = MeshInstance3D.new()
			_kutu.mesh = BoxMesh.new()
			_kutu.visibility_range_end = 520.0   # kameradan çok uzaktaki binalar çizilmez
			add_child(_kutu)
		var dm: ArrayMesh = _doku_mesh() if not Engine.is_editor_hint() or true else null
		if dm != null:
			_kutu.mesh = dm
			_kutu.position = Vector3.ZERO
			_kutu.material_override = null
		else:
			if not (_kutu.mesh is BoxMesh):
				_kutu.mesh = BoxMesh.new()
			(_kutu.mesh as BoxMesh).size = boyut
			_kutu.position = Vector3(0, boyut.y / 2.0, 0)
			_kutu.material_override = _malzeme(renk)
			(_kutu.material_override as ShaderMaterial).set_shader_parameter("taban", global_position.y)
			(_kutu.material_override as ShaderMaterial).set_shader_parameter("yukseklik", boyut.y)
	elif _kutu != null:
		_kutu.queue_free()
		_kutu = null
	if not Engine.is_editor_hint():
		if _govde == null:
			_govde = StaticBody3D.new()
			var cs := CollisionShape3D.new()
			cs.shape = BoxShape3D.new()
			_govde.add_child(cs)
			add_child(_govde)
		((_govde.get_child(0) as CollisionShape3D).shape as BoxShape3D).size = boyut
		_govde.position = Vector3(0, boyut.y / 2.0, 0)
	if dolgu:
		return
	if _etiket == null:
		_etiket = Label3D.new()
		_etiket.font_size = 40
		_etiket.pixel_size = 0.03
		_etiket.outline_size = 10
		_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_etiket.no_depth_test = true
		_etiket.visibility_range_end = 220.0
		add_child(_etiket)
	_etiket.text = ad
	_etiket.modulate = Color(1.0, 0.85, 0.4) if ozel else Color(0.95, 0.95, 0.95)
	_etiket.position = Vector3(0, boyut.y + 3.0, 0)

# assets/textures/bina/<ad>_cephe|_yan|_cati.png varsa: ön yüz (+Z) cephe, yanlar/arka yan doku, üst çatı dokusuyla kutu.
static var _dokular := {}

static func _doku(yol: String) -> Texture2D:
	if not _dokular.has(yol):
		_dokular[yol] = load(yol) if ResourceLoader.exists(yol) else null
	return _dokular[yol]

func _doku_mesh() -> ArrayMesh:
	var taban := String(ad).to_lower().replace("'", "").replace(" ", "_").replace("&", "").replace("__", "_")
	for ek in ["_iii", "_ii"]:
		if not ResourceLoader.exists("res://assets/textures/bina/%s_cephe.png" % taban):
			taban = taban.trim_suffix(ek)
	var tc := _doku("res://assets/textures/bina/%s_cephe.png" % taban)
	if tc == null:
		return null
	var ty := _doku("res://assets/textures/bina/%s_yan.png" % taban)
	var tt := _doku("res://assets/textures/bina/%s_cati.png" % taban)
	var hx := boyut.x / 2.0
	var hz := boyut.z / 2.0
	var h := boyut.y
	var mesh := ArrayMesh.new()
	# [doku, köşeler(4), uv tekrarı]
	var yuzler := [
		[tc, [Vector3(-hx, 0, hz), Vector3(hx, 0, hz), Vector3(hx, h, hz), Vector3(-hx, h, hz)], Vector2(1, 1), Vector3(0, 0, 1)],
		[ty, [Vector3(hx, 0, -hz), Vector3(-hx, 0, -hz), Vector3(-hx, h, -hz), Vector3(hx, h, -hz)], Vector2(boyut.x / 12.0, h / 12.0), Vector3(0, 0, -1)],
		[ty, [Vector3(hx, 0, hz), Vector3(hx, 0, -hz), Vector3(hx, h, -hz), Vector3(hx, h, hz)], Vector2(boyut.z / 12.0, h / 12.0), Vector3(1, 0, 0)],
		[ty, [Vector3(-hx, 0, -hz), Vector3(-hx, 0, hz), Vector3(-hx, h, hz), Vector3(-hx, h, -hz)], Vector2(boyut.z / 12.0, h / 12.0), Vector3(-1, 0, 0)],
		[tt, [Vector3(-hx, h, hz), Vector3(hx, h, hz), Vector3(hx, h, -hz), Vector3(-hx, h, -hz)], Vector2(1, 1), Vector3(0, 1, 0)],
	]
	for f in yuzler:
		var dk: Texture2D = f[0] if f[0] != null else tc
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var q: Array = f[1]
		var uvs := [Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]
		var rp: Vector2 = f[2]
		st.set_normal(f[3])
		for k in [0, 2, 1, 0, 3, 2]:
			st.set_uv(Vector2(uvs[k].x * rp.x, uvs[k].y * rp.y))
			st.add_vertex(q[k])
		var m := StandardMaterial3D.new()
		m.albedo_texture = dk
		m.roughness = 1.0
		m.texture_repeat = true
		if dk == tc:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
			m.alpha_scissor_threshold = 0.5
		st.set_material(m)
		st.commit(mesh)
	return mesh

func _malzeme(c: Color) -> ShaderMaterial:
	if _sh == null:
		_sh = load("res://assets/environment/shaders/cephe.gdshader")
	var m := ShaderMaterial.new()
	m.shader = _sh
	m.set_shader_parameter("renk", c)
	return m

# Dünya koordinatlarında kutu (yön döndürülmüşse onu kapsar).
func dunya_aabb() -> AABB:
	var t := global_transform
	var yari := Vector3(boyut.x / 2.0, 0, boyut.z / 2.0)
	var a := AABB(t * Vector3(-yari.x, 0, -yari.z), Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for y in [0.0, boyut.y]:
				a = a.expand(t * Vector3(sx * yari.x, y, sz * yari.z))
	return a

# Fare üstüne gelince binanın 12 kenarına ince altın çerçeve çizer. kalinlik: kamera uzaklığına göre ölçek.
func vurgu(acik: bool, kalinlik := 1.0) -> void:
	if not acik:
		if _hat != null:
			_hat.visible = false
		return
	if _hat == null:
		_hat = Node3D.new()
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(1.0, 0.82, 0.3)
		for _i in 12:
			var mi := MeshInstance3D.new()
			mi.mesh = BoxMesh.new()
			mi.material_override = m
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_hat.add_child(mi)
		add_child(_hat)
	var t := 0.12 * kalinlik
	var hx := boyut.x / 2.0
	var hz := boyut.z / 2.0
	var k := _hat.get_children()
	var n := 0
	for y in [0.0, boyut.y]:
		for z in [-hz, hz]:
			var e: MeshInstance3D = k[n]
			n += 1
			(e.mesh as BoxMesh).size = Vector3(boyut.x + t, t, t)
			e.position = Vector3(0, y, z)
		for x in [-hx, hx]:
			var e2: MeshInstance3D = k[n]
			n += 1
			(e2.mesh as BoxMesh).size = Vector3(t, t, boyut.z + t)
			e2.position = Vector3(x, y, 0)
	for x in [-hx, hx]:
		for z in [-hz, hz]:
			var e3: MeshInstance3D = k[n]
			n += 1
			(e3.mesh as BoxMesh).size = Vector3(t, boyut.y + t, t)
			e3.position = Vector3(x, boyut.y / 2.0, z)
	_hat.visible = true
