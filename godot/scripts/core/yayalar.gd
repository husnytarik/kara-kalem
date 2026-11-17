extends Node3D
# Süs yayalar: oyuncunun etrafında dolaşan figürler (sokağa hayat verir). Gece sayıları azalır, uzak kamerada gizlenir.
const SAYI := 70
const MENZIL := 60.0
var harita: Node
var oyuncu: Node3D
var oyun: Node
var kamera: Node
var _y: Array = []
var _mat: Array = []
var _g_mesh: Mesh
var _k_mesh: Mesh
var _bas_mat: StandardMaterial3D
var _sira := 0

func kur(h: Node, o: Node3D, oy: Node, ka: Node) -> void:
	harita = h
	oyuncu = o
	oyun = oy
	kamera = ka
	_g_mesh = CapsuleMesh.new()
	(_g_mesh as CapsuleMesh).radius = 0.3
	(_g_mesh as CapsuleMesh).height = 1.5
	_k_mesh = SphereMesh.new()
	(_k_mesh as SphereMesh).radius = 0.2
	(_k_mesh as SphereMesh).height = 0.4
	_bas_mat = StandardMaterial3D.new()
	_bas_mat.albedo_color = Color("c9a083")
	for c in ["8a6a50", "9a7a58", "5a7aa0", "b04a40", "6a9a6a", "c8b48a", "55555e"]:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(c)
		m.roughness = 0.9
		_mat.append(m)
	for i in SAYI:
		var n := Node3D.new()
		var g := MeshInstance3D.new()
		g.mesh = _g_mesh
		g.material_override = _mat[i % _mat.size()]
		g.position.y = 0.75
		n.add_child(g)
		var k := MeshInstance3D.new()
		k.mesh = _k_mesh
		k.material_override = _bas_mat
		k.position.y = 1.7
		n.add_child(k)
		n.visible = false
		n.scale = Vector3.ONE * 2.2
		add_child(n)
		_y.append({"n": n, "yol": PackedVector3Array(), "i": 0, "hiz": randf_range(1.2, 1.9), "bekle": randf() * 3.0, "faz": randf() * 6.28})

func _yeni_rota(d: Dictionary) -> void:
	var c: Vector3 = oyuncu.global_position
	var a: Vector3 = harita.serbest_nokta(c + Vector3(randf_range(-MENZIL, MENZIL), 0, randf_range(-MENZIL, MENZIL)))
	var b: Vector3 = harita.serbest_nokta(a + Vector3(randf_range(-45, 45), 0, randf_range(-45, 45)))
	var yol: PackedVector3Array = harita.yol_bul(a, b)
	if yol.size() < 2:
		return
	d["yol"] = yol
	d["i"] = 1
	d["n"].global_position = a

func _process(delta: float) -> void:
	if oyuncu == null:
		return
	var uz: float = kamera.mesafe
	var saat: float = fmod(float(oyun.t), float(oyun.DAY)) / 60.0
	var gece: bool = saat < 5.5 or saat > 22.0
	var aktif: int = SAYI / 3 if gece else SAYI
	if uz > 230.0:
		aktif = 0
	var c: Vector3 = oyuncu.global_position
	# her karede yalnızca birkaç yayaya rota hesabı yaptır (A* maliyeti)
	var hesap := 0
	for idx in SAYI:
		var d: Dictionary = _y[idx]
		var n: Node3D = d["n"]
		if idx >= aktif:
			n.visible = false
			continue
		var uzak: bool = (d["yol"] as PackedVector3Array).is_empty() or n.global_position.distance_to(c) > MENZIL * 1.4
		if d["bekle"] > 0.0:
			d["bekle"] -= delta
			continue
		if uzak or d["i"] >= (d["yol"] as PackedVector3Array).size():
			if hesap < 2:
				hesap += 1
				d["yol"] = PackedVector3Array()
				_yeni_rota(d)
				d["bekle"] = randf() * 2.0 if not (d["yol"] as PackedVector3Array).is_empty() else 0.3
				n.visible = not (d["yol"] as PackedVector3Array).is_empty()
			continue
		n.visible = true
		var yol: PackedVector3Array = d["yol"]
		var hedef: Vector3 = yol[d["i"]]
		var fark: Vector3 = hedef - n.global_position
		fark.y = 0.0
		var adim: float = float(d["hiz"]) * delta
		if fark.length() <= adim:
			n.global_position = hedef
			d["i"] += 1
			if d["i"] >= yol.size() and randf() < 0.5:
				d["bekle"] = randf_range(2.0, 7.0)
		else:
			var dir: Vector3 = fark.normalized()
			n.global_position += dir * adim
			n.global_position.y = harita.yuk(n.global_position.x, n.global_position.z)
			n.rotation.y = lerp_angle(n.rotation.y, atan2(dir.x, dir.z), 8.0 * delta)
			d["faz"] += delta * 9.0
			n.get_child(0).position.y = 0.75 + absf(sin(d["faz"])) * 0.07
