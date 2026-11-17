extends Node3D
# Haritadaki karakterin işareti: tıklanan yere yol bulup yürür.

var harita: Node3D
var oyun: Node   # araba hız çarpanı ve yakıt için
var hiz := 9.0                       # m/s (oyun hızıyla çarpılır)
var _yol := PackedVector3Array()
var _govde: Node3D
var _cizgi: MeshInstance3D
var _im := ImmediateMesh.new()
var _isaret: MeshInstance3D

func _ready() -> void:
	_govde = Node3D.new()
	add_child(_govde)
	var m := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	cm.material = _renk(Color(0.85, 0.2, 0.15), false)
	m.mesh = cm
	m.position.y = 0.9
	_govde.add_child(m)
	_govde.scale = Vector3.ONE * 3.0   # yukarıdan görünür olsun
	var halka := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 4.0
	cyl.bottom_radius = 4.0
	cyl.height = 0.15
	cyl.material = _renk(Color(0.9, 0.75, 0.3, 0.7), true)
	halka.mesh = cyl
	halka.position.y = 0.2
	add_child(halka)
	_cizgi = MeshInstance3D.new()
	_cizgi.mesh = _im
	_cizgi.material_override = _renk(Color(0.95, 0.85, 0.3), true)
	_cizgi.top_level = true
	add_child(_cizgi)
	_isaret = MeshInstance3D.new()
	var ic := CylinderMesh.new()
	ic.top_radius = 0.0
	ic.bottom_radius = 2.0
	ic.height = 5.0
	ic.material = _renk(Color(0.95, 0.85, 0.3), true)
	_isaret.mesh = ic
	_isaret.top_level = true
	_isaret.visible = false
	add_child(_isaret)

func _renk(c: Color, ismesiz: bool) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	if ismesiz:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.no_depth_test = true   # arazi altında kalmasın
	if c.a < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return m

var kilitli := false   # çalışırken yürüyemezsin
var iceride := -1      # bir binanın içindeysen bina indeksi (haritada görünmezsin)

func gir(i: int) -> void:
	iceride = i
	_yol = PackedVector3Array()
	visible = false

func cik() -> void:
	if iceride < 0:
		return
	global_position = harita.serbest_nokta(harita.yerler[iceride]["pos"])
	iceride = -1
	visible = true

func git(hedef: Vector3) -> bool:
	if kilitli:
		return false
	cik()
	var y: PackedVector3Array = harita.yol_bul(global_position, hedef)
	if y.size() < 2:
		return false
	_yol = y
	_yol.remove_at(0)
	_isaret.global_position = y[y.size() - 1] + Vector3(0, 2.5, 0)
	_isaret.rotation_degrees.x = 180
	_isaret.visible = true
	return true

func _process(delta: float) -> void:
	var kalan: float = hiz * delta * (oyun.arac_k.hiz_carpan() * oyun.meslek.yurume_carpan() if oyun != null else 1.0)
	var once := global_position
	while kalan > 0.0 and _yol.size() > 0:
		var p := _yol[0]
		var fark := p - global_position
		fark.y = 0
		var uz := fark.length()
		if uz <= kalan:
			global_position = Vector3(p.x, 0, p.z)
			kalan -= uz
			_yol.remove_at(0)
		else:
			var yon := fark / uz
			global_position += yon * kalan
			_govde.rotation.y = lerp_angle(_govde.rotation.y, atan2(-yon.x, -yon.z), 10.0 * delta)
			kalan = 0.0
	if oyun != null and kalan >= 0.0:
		oyun.arac_k.adim(global_position.distance_to(once))
	global_position.y = harita.yuk(global_position.x, global_position.z)   # araziyi izle
	_isaret.visible = _yol.size() > 0
	_im.clear_surfaces()
	if _yol.size() > 0:
		_im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		_im.surface_add_vertex(global_position + Vector3(0, 0.4, 0))
		for p in _yol:
			_im.surface_add_vertex(p + Vector3(0, 0.4, 0))
		_im.surface_end()
