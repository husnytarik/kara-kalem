extends Node3D
# Şehir canlılığı: yayalar KALDIRIMDA yürür, arabalar ASFALTTA sağ şeritte sürer.
# Ağ: data/yol_ag.json (yol eksenleri, ~2 m aralıklı noktalar). Kavşaklarda rastgele dönülür.
const YAYA_SAYI := 60
const ARABA_SAYI := 22
const KALDIRIM := 2.2
const MENZIL := 110.0
const HUCRE := 8.0
var harita: Node
var oyuncu: Node3D
var oyun: Node
var kamera: Node
var _yol: Array = []           # {p: PackedVector2Array, w}
var _hash := {}                # Vector2i -> Array[Vector2i(yol, nokta)]
var _noktalar: Array = []      # tüm (yol, nokta) çiftleri
var _ajan: Array = []
var _far_mat: StandardMaterial3D

func kur(h: Node, o: Node3D, oy: Node, ka: Node) -> void:
	harita = h
	oyuncu = o
	oyun = oy
	kamera = ka
	_agi_yukle()
	if _yol.is_empty():
		return
	_gorselleri_kur()

func _agi_yukle() -> void:
	var f := FileAccess.open("res://data/yol_ag.json", FileAccess.READ)
	if f == null:
		return
	var d: Array = JSON.parse_string(f.get_as_text())
	for y in d:
		var p := PackedVector2Array()
		for q in y["pts"]:
			p.append(Vector2(q[0], q[1]))
		if p.size() < 3:
			continue
		var yi := _yol.size()
		_yol.append({"p": p, "w": float(y["w"])})
		for i in p.size():
			var key := Vector2i(int(floor(p[i].x / HUCRE)), int(floor(p[i].y / HUCRE)))
			if not _hash.has(key):
				_hash[key] = []
			_hash[key].append(Vector2i(yi, i))
			_noktalar.append(Vector2i(yi, i))

func _gorselleri_kur() -> void:
	var gov_renk := ["8a6a50", "9a7a58", "5a7aa0", "b04a40", "6a9a6a", "c8b48a", "55555e"]
	var yaya_g := CapsuleMesh.new()
	yaya_g.radius = 0.3
	yaya_g.height = 1.5
	var yaya_k := SphereMesh.new()
	yaya_k.radius = 0.2
	yaya_k.height = 0.4
	var ten := StandardMaterial3D.new()
	ten.albedo_color = Color("c9a083")
	var gov_mat: Array = []
	for c in gov_renk:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(c)
		m.roughness = 0.9
		gov_mat.append(m)
	for i in YAYA_SAYI:
		var n := Node3D.new()
		var g := MeshInstance3D.new()
		g.mesh = yaya_g
		g.material_override = gov_mat[i % gov_mat.size()]
		g.position.y = 0.75
		n.add_child(g)
		var k := MeshInstance3D.new()
		k.mesh = yaya_k
		k.material_override = ten
		k.position.y = 1.7
		n.add_child(k)
		n.scale = Vector3.ONE * 2.0
		n.visible = false
		add_child(n)
		_ajan.append({"n": n, "araba": false, "yol": -1, "s": 0.0, "yon": 1, "taraf": 1.0, "hiz": randf_range(1.2, 1.9),
			"kay": Vector3.ZERO, "faz": randf() * 6.28, "bekle": 0.0, "serbest": 0.0, "yaw": 0.0, "id": i})
	# arabalar
	_far_mat = StandardMaterial3D.new()
	_far_mat.albedo_color = Color(1, 0.9, 0.6)
	_far_mat.emission_enabled = true
	_far_mat.emission = Color(1, 0.85, 0.5)
	_far_mat.emission_energy_multiplier = 0.0
	var govde := BoxMesh.new()
	govde.size = Vector3(1.9, 0.9, 4.4)
	var kabin := BoxMesh.new()
	kabin.size = Vector3(1.7, 0.75, 2.2)
	var far := SphereMesh.new()
	far.radius = 0.22
	far.height = 0.44
	var renkler := ["1c1c20", "2a3a2a", "4a1c1c", "3a3a44", "5a4a30", "20303f"]
	for i in ARABA_SAYI:
		var n := Node3D.new()
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(renkler[i % renkler.size()])
		m.roughness = 0.45
		m.metallic = 0.3
		var g := MeshInstance3D.new()
		g.mesh = govde
		g.material_override = m
		g.position.y = 0.75
		n.add_child(g)
		var kb := MeshInstance3D.new()
		kb.mesh = kabin
		kb.material_override = m
		kb.position = Vector3(0, 1.45, -0.2)
		n.add_child(kb)
		for sx in [-0.65, 0.65]:
			var fl := MeshInstance3D.new()
			fl.mesh = far
			fl.material_override = _far_mat
			fl.position = Vector3(sx, 0.8, 2.2)
			n.add_child(fl)
		n.visible = false
		add_child(n)
		_ajan.append({"n": n, "araba": true, "yol": -1, "s": 0.0, "yon": 1, "taraf": 1.0, "hiz": randf_range(7.0, 11.0),
			"kay": Vector3.ZERO, "faz": 0.0, "bekle": 0.0, "serbest": 0.0, "yaw": 0.0, "id": i})

# Ajanı oyuncunun yakınında rastgele bir yol noktasına koyar.
func _yerlestir(a: Dictionary) -> bool:
	var c: Vector3 = oyuncu.global_position
	for deneme in 25:
		var q: Vector2i = _noktalar[randi() % _noktalar.size()]
		var p: Vector2 = (_yol[q.x]["p"] as PackedVector2Array)[q.y]
		var uz: float = Vector2(p.x - c.x, p.y - c.z).length()
		if uz < 25.0 or uz > MENZIL:
			continue
		a["yol"] = q.x
		a["s"] = float(q.y)
		a["yon"] = 1 if randf() < 0.5 else -1
		a["taraf"] = 1.0 if randf() < 0.5 else -1.0
		a["kay"] = Vector3.ZERO
		a["serbest"] = 0.0
		return true
	return false

func _konum(a: Dictionary) -> Dictionary:
	var yl: Dictionary = _yol[a["yol"]]
	var p: PackedVector2Array = yl["p"]
	var s: float = clampf(a["s"], 0.0, float(p.size() - 1) - 0.001)
	var i := int(s)
	var f := s - float(i)
	var t: Vector2 = (p[i + 1] - p[i]).normalized() * float(a["yon"])   # gidiş yönü
	var sag := Vector2(-t.y, t.x)
	var yan: float
	if a["araba"]:
		yan = float(yl["w"]) * 0.25
	else:
		yan = float(yl["w"]) * 0.5 + KALDIRIM * 0.5
		sag *= signf(a["taraf"])
	var m: Vector2 = p[i].lerp(p[i + 1], f) + sag * yan
	return {"x": m.x, "z": m.y, "t": t}

func _kavsak(a: Dictionary) -> void:
	var p: PackedVector2Array = _yol[a["yol"]]["p"]
	var i: int = clampi(int(round(a["s"])), 0, p.size() - 1)
	var m: Vector2 = p[i]
	var key := Vector2i(int(floor(m.x / HUCRE)), int(floor(m.y / HUCRE)))
	var aday: Array = []
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var k := key + Vector2i(dx, dz)
			if not _hash.has(k):
				continue
			for q in _hash[k]:
				if q.x != a["yol"] and (_yol[q.x]["p"] as PackedVector2Array)[q.y].distance_to(m) < 3.0:
					aday.append(q)
	if aday.is_empty():
		return
	if randf() > 0.55:
		a["serbest"] = 8.0
		return
	var q: Vector2i = aday[randi() % aday.size()]
	var onceki: Dictionary = _konum(a)
	a["yol"] = q.x
	a["s"] = float(q.y)
	a["yon"] = 1 if randf() < 0.5 else -1
	a["taraf"] = 1.0 if randf() < 0.5 else -1.0
	var yeni: Dictionary = _konum(a)
	a["kay"] = Vector3(float(onceki["x"]) - float(yeni["x"]), 0, float(onceki["z"]) - float(yeni["z"]))
	a["serbest"] = 8.0

func _process(delta: float) -> void:
	if oyuncu == null or _yol.is_empty():
		return
	var uz: float = kamera.mesafe
	var saat: float = fmod(float(oyun.t), float(oyun.DAY)) / 60.0
	var kis: float = 0.35 if (saat < 5.5 or saat > 22.0) else 1.0
	var gizle: bool = uz > 260.0
	_far_mat.emission_energy_multiplier = 3.0 if (saat < 6.5 or saat > 18.5) else 0.0
	var c: Vector3 = oyuncu.global_position
	var hesap := 0
	var yk := 0
	var ak := 0
	for a in _ajan:
		var n: Node3D = a["n"]
		var araba: bool = a["araba"]
		var sira: int = ak if araba else yk
		if araba:
			ak += 1
		else:
			yk += 1
		var kota: int = int(float(ARABA_SAYI if araba else YAYA_SAYI) * kis)
		if gizle or sira >= kota:
			n.visible = false
			a["yol"] = -1
			continue
		if a["yol"] < 0 or n.global_position.distance_to(c) > MENZIL * 1.5:
			if hesap < 4 and _yerlestir(a):
				hesap += 1
				var k0: Dictionary = _konum(a)
				var x0: float = k0["x"]
				var z0: float = k0["z"]
				n.global_position = Vector3(x0, harita.yuk(x0, z0), z0)
				n.visible = true
				a["bekle"] = 0.0
			else:
				n.visible = false
			continue
		if a["bekle"] > 0.0:
			a["bekle"] -= delta
			continue
		var hiz: float = a["hiz"]
		if araba:
			# önündeki daha düşük numaralı arabaya çarpma
			var yaw: float = a["yaw"]
			var ileri := Vector3(sin(yaw), 0, cos(yaw))
			for b in _ajan:
				if b["araba"] and b["id"] < a["id"] and (b["n"] as Node3D).visible:
					var fark: Vector3 = (b["n"] as Node3D).global_position - n.global_position
					fark.y = 0
					var d: float = fark.length()
					if d < 7.0 and d > 0.01 and fark.dot(ileri) / d > 0.8:
						hiz = 0.0
						break
		var p: PackedVector2Array = _yol[a["yol"]]["p"]
		var onceki_i := int(a["s"])
		a["s"] += float(a["yon"]) * hiz * delta / 2.0
		a["serbest"] = maxf(0.0, float(a["serbest"]) - hiz * delta)
		if a["s"] <= 0.0 or a["s"] >= float(p.size() - 1):
			a["yon"] = -int(a["yon"])
			a["s"] = clampf(a["s"], 0.01, float(p.size() - 1) - 0.01)
			if not araba and randf() < 0.5:
				a["taraf"] = -float(a["taraf"])
		elif int(a["s"]) != onceki_i and a["serbest"] <= 0.0:
			_kavsak(a)
		var k: Dictionary = _konum(a)
		a["kay"] = (a["kay"] as Vector3).move_toward(Vector3.ZERO, 4.0 * delta)
		var hx: float = float(k["x"]) + (a["kay"] as Vector3).x
		var hz: float = float(k["z"]) + (a["kay"] as Vector3).z
		var t: Vector2 = k["t"]
		n.global_position = Vector3(hx, harita.yuk(hx, hz), hz)
		var hedef_yaw: float = atan2(t.x, t.y)
		if araba:
			a["yaw"] = lerp_angle(a["yaw"], hedef_yaw, 6.0 * delta)
			n.rotation.y = a["yaw"]
		else:
			n.rotation.y = lerp_angle(n.rotation.y, hedef_yaw, 8.0 * delta)
			a["faz"] += delta * 9.0
			n.get_child(0).position.y = 0.75 + absf(sin(a["faz"])) * 0.07
		n.visible = true
