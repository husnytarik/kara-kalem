extends Node3D
# Küplerden şehir: 6 bölge, JS prototipteki komşuluğa uygun yerleşim.
#   Hilltop | Downtown
#   Southside | Eastside
#   The Flats (geniş)
#   Docks (geniş) + deniz
# Yollar blokların arasındaki boşluklar; her bölge blok ızgarası.

const BLOK := 28.0
const YOL := 10.0
const ADIM := BLOK + YOL
const KOK := Vector3(-152.0, 0.0, -228.0)   # şehrin sol-üst köşesi

var bolgeler := {}
var _mat := {}
var _rng := RandomNumberGenerator.new()

func _init() -> void:
	bolgeler = {
		"hilltop":   {"ad": "Hilltop",   "gx": 0, "gz": 0,  "w": 4, "h": 4, "tip": "villa",  "zemin": Color(0.30, 0.40, 0.26)},
		"downtown":  {"ad": "Downtown",  "gx": 4, "gz": 0,  "w": 4, "h": 4, "tip": "kule",   "zemin": Color(0.40, 0.40, 0.42)},
		"southside": {"ad": "Southside", "gx": 0, "gz": 4,  "w": 4, "h": 4, "tip": "konut",  "zemin": Color(0.38, 0.35, 0.31), "kat": Vector2(6, 14)},
		"eastside":  {"ad": "Eastside",  "gx": 4, "gz": 4,  "w": 4, "h": 4, "tip": "konut",  "zemin": Color(0.36, 0.34, 0.33), "kat": Vector2(10, 22)},
		"flats":     {"ad": "The Flats", "gx": 0, "gz": 8,  "w": 8, "h": 3, "tip": "depo",   "zemin": Color(0.34, 0.33, 0.30)},
		"docks":     {"ad": "Docks",     "gx": 0, "gz": 11, "w": 8, "h": 2, "tip": "liman",  "zemin": Color(0.32, 0.33, 0.34)},
	}

func kur() -> void:
	var gen: float = 8 * ADIM
	var son_z: float = KOK.z + 13 * ADIM
	# Yol zemini (asfalt): tüm şehir.
	_kutu(Vector3(KOK.x + gen / 2.0, -0.5, (KOK.z + son_z) / 2.0), Vector3(gen, 1.0, son_z - KOK.z), Color(0.13, 0.13, 0.14), true)
	for id in bolgeler:
		_bolge(id)
	_deniz(son_z, gen)
	_duvarlar(son_z, gen)
	_izgara_kur(son_z, gen)

# ---------- yol bulma (1 m'lik ızgara üzerinde A*) ----------
# Bloklar (binalar) kapalı, yollar ve iskeleler açık, deniz kapalı.
var _izgara: AStarGrid2D

func _izgara_kur(son_z: float, gen: float) -> void:
	var w := int(gen)
	var h := int(son_z - KOK.z) + 40
	_izgara = AStarGrid2D.new()
	_izgara.region = Rect2i(0, 0, w, h)
	_izgara.cell_size = Vector2.ONE
	_izgara.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_izgara.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_izgara.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_izgara.update()
	for id in bolgeler:
		var b: Dictionary = bolgeler[id]
		for i in int(b["w"]):
			for j in int(b["h"]):
				var x0 := int((b["gx"] + i) * ADIM + YOL / 2.0) - 1
				var z0 := int((b["gz"] + j) * ADIM + YOL / 2.0) - 1
				_kapat(x0, z0, x0 + int(BLOK) + 2, z0 + int(BLOK) + 2)
	var su_z := int(son_z - KOK.z)
	for k in 6:   # iskeleler açık kalır
		var ix := int(30 + k * 48.0)
		if k == 0:
			_kapat(0, su_z, ix - 2, h)
		if k == 5:
			_kapat(ix + 3, su_z, w, h)
		else:
			_kapat(ix + 3, su_z, int(30 + (k + 1) * 48.0) - 2, h)

func _kapat(x0: int, z0: int, x1: int, z1: int) -> void:
	for x in range(maxi(x0, 0), mini(x1, _izgara.region.size.x)):
		for z in range(maxi(z0, 0), mini(z1, _izgara.region.size.y)):
			_izgara.set_point_solid(Vector2i(x, z), true)

func _hucre(p: Vector3) -> Vector2i:
	var r := _izgara.region.size
	return Vector2i(clampi(int(floor(p.x - KOK.x)), 0, r.x - 1), clampi(int(floor(p.z - KOK.z)), 0, r.y - 1))

func _acik(c: Vector2i) -> Vector2i:
	if not _izgara.is_point_solid(c):
		return c
	for r in range(1, 60):
		var en := Vector2i(-1, -1)
		var en_d := 1e9
		for dx in range(-r, r + 1):
			for dz in range(-r, r + 1):
				if maxi(absi(dx), absi(dz)) != r:
					continue
				var q := c + Vector2i(dx, dz)
				if _izgara.is_in_boundsv(q) and not _izgara.is_point_solid(q) and float(dx * dx + dz * dz) < en_d:
					en = q
					en_d = float(dx * dx + dz * dz)
		if en.x >= 0:
			return en
	return c

# Dünya koordinatından dünya koordinatına yol. Boşsa ulaşılamaz.
func yol_bul(a: Vector3, b: Vector3) -> PackedVector3Array:
	var cikti := PackedVector3Array()
	var ga := _acik(_hucre(a))
	var gb := _acik(_hucre(b))
	var ham := _izgara.get_id_path(ga, gb)
	for i in ham.size():
		var p: Vector2i = ham[i]
		if i > 0 and i < ham.size() - 1:
			var sonraki: Vector2i = ham[i + 1]
			if sonraki - p == p - ham[i - 1]:
				continue   # düz giden noktaları at
		cikti.append(Vector3(KOK.x + p.x + 0.5, 0.0, KOK.z + p.y + 0.5))
	return cikti

func merkez(id: String) -> Vector3:
	var b: Dictionary = bolgeler[id]
	return KOK + Vector3((b["gx"] + b["w"] / 2) * ADIM, 0.0, (b["gz"] + b["h"] / 2) * ADIM)

func bolge_at(p: Vector3) -> String:
	for id in bolgeler:
		var b: Dictionary = bolgeler[id]
		var x0: float = KOK.x + b["gx"] * ADIM
		var z0: float = KOK.z + b["gz"] * ADIM
		if p.x >= x0 and p.x < x0 + b["w"] * ADIM and p.z >= z0 and p.z < z0 + b["h"] * ADIM:
			return id
	return ""

func _bolge(id: String) -> void:
	var b: Dictionary = bolgeler[id]
	_rng.seed = hash(id)
	for i in int(b["w"]):
		for j in int(b["h"]):
			var o: Vector3 = KOK + Vector3((b["gx"] + i) * ADIM + YOL / 2.0, 0.0, (b["gz"] + j) * ADIM + YOL / 2.0)
			var c: Vector3 = o + Vector3(BLOK / 2.0, 0.0, BLOK / 2.0)
			var zemin: Color = b["zemin"]
			if b["tip"] == "villa":
				zemin = Color(0.27, 0.38, 0.24)
			_kutu(c + Vector3(0, 0.03, 0), Vector3(BLOK, 0.06, BLOK), zemin.lightened(_rng.randf() * 0.06), false)
			match b["tip"]:
				"villa": _villa(c)
				"kule": _kule(c)
				"konut": _konut(c, b["kat"])
				"depo": _depo(c)
				"liman": _liman(c)
	var m: Vector3 = merkez(id)
	var l := Label3D.new()
	l.text = b["ad"]
	l.font_size = 220
	l.pixel_size = 0.05
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.outline_size = 40
	l.position = m + Vector3(0, 80, 0)
	add_child(l)

func _villa(c: Vector3) -> void:
	var w := _rng.randf_range(12, 17)
	var d := _rng.randf_range(12, 16)
	var h := _rng.randf_range(5, 9)
	_bina(c + Vector3(_rng.randf_range(-2, 2), 0, _rng.randf_range(-2, 2)), w, d, h, Color(0.62, 0.55, 0.45).darkened(_rng.randf() * 0.25))
	for k in 4:
		var p := c + Vector3(_rng.randf_range(-12, 12), 0, _rng.randf_range(-12, 12))
		_kutu(p + Vector3(0, 1.2, 0), Vector3(0.5, 2.4, 0.5), Color(0.3, 0.2, 0.12), true)
		_kutu(p + Vector3(0, 3.6, 0), Vector3(3, 3, 3), Color(0.16, 0.32, 0.14), false)

func _kule(c: Vector3) -> void:
	if _rng.randf() < 0.3:
		_bina(c, 22, 22, _rng.randf_range(25, 55), _gri(0.45))
		return
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			_bina(c + Vector3(sx * 7.0, 0, sz * 7.0), 12, 12, _rng.randf_range(12, 38), _gri(0.5))

func _konut(c: Vector3, kat: Vector2) -> void:
	for sx in [-1, 1]:
		for sz in [-1, 1]:
			if _rng.randf() < 0.1:
				continue
			var renk := Color(0.5, 0.28, 0.2).lerp(Color(0.55, 0.47, 0.34), _rng.randf())
			_bina(c + Vector3(sx * 7.0, 0, sz * 7.0), 12, 12, _rng.randf_range(kat.x, kat.y), renk.darkened(_rng.randf() * 0.2))

func _depo(c: Vector3) -> void:
	for sz in [-1, 1]:
		_bina(c + Vector3(0, 0, sz * 7.0), 26, 11, _rng.randf_range(6, 9), Color(0.38, 0.36, 0.32).darkened(_rng.randf() * 0.2))

func _liman(c: Vector3) -> void:
	_bina(c + Vector3(0, 0, -7.0), 26, 11, _rng.randf_range(7, 10), Color(0.30, 0.34, 0.38).darkened(_rng.randf() * 0.2))
	var renkler := [Color(0.6, 0.25, 0.2), Color(0.2, 0.35, 0.5), Color(0.3, 0.45, 0.28)]
	for k in 3:
		_kutu(c + Vector3(-8 + k * 8.0, 1.3, 8.0), Vector3(6, 2.6, 2.4), renkler[_rng.randi() % 3], true)

func _gri(a: float) -> Color:
	return Color(a, a, a + 0.04).darkened(_rng.randf() * 0.2)

func _bina(c: Vector3, w: float, d: float, h: float, renk: Color) -> void:
	_kutu(c + Vector3(0, h / 2.0, 0), Vector3(w, h, d), renk, true)

func _deniz(son_z: float, gen: float) -> void:
	_kutu(Vector3(KOK.x + gen / 2.0, -1.5, son_z + 35), Vector3(gen + 60, 1.0, 70), Color(0.1, 0.2, 0.3), true)
	_kutu(Vector3(KOK.x + gen / 2.0, -0.4, son_z + 35), Vector3(gen + 60, 0.1, 70), Color(0.12, 0.30, 0.42), false)
	for k in 6:   # iskeleler (yürünür)
		_kutu(Vector3(KOK.x + 30 + k * 48.0, -0.5, son_z + 20), Vector3(6, 1.0, 40), Color(0.35, 0.25, 0.16), true)

func _duvarlar(son_z: float, gen: float) -> void:
	var x0 := KOK.x - 30
	var x1 := KOK.x + gen + 30
	var z0 := KOK.z - 30
	var z1 := son_z + 70
	var orta_x := (x0 + x1) / 2.0
	var orta_z := (z0 + z1) / 2.0
	_duvar(Vector3(x0, 25, orta_z), Vector3(2, 50, z1 - z0))
	_duvar(Vector3(x1, 25, orta_z), Vector3(2, 50, z1 - z0))
	_duvar(Vector3(orta_x, 25, z0), Vector3(x1 - x0, 50, 2))
	_duvar(Vector3(orta_x, 25, z1), Vector3(x1 - x0, 50, 2))

func _duvar(p: Vector3, boyut: Vector3) -> void:
	var b := StaticBody3D.new()
	var c := CollisionShape3D.new()
	var s := BoxShape3D.new()
	s.size = boyut
	c.shape = s
	b.add_child(c)
	b.position = p
	add_child(b)

func _malzeme(renk: Color) -> StandardMaterial3D:
	var k := renk.to_html()
	if not _mat.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = renk
		m.roughness = 0.9
		_mat[k] = m
	return _mat[k]

func _kutu(p: Vector3, boyut: Vector3, renk: Color, carpisma: bool) -> Node3D:
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = boyut
	bm.material = _malzeme(renk)
	m.mesh = bm
	m.position = p
	if carpisma:
		var b := StaticBody3D.new()
		var c := CollisionShape3D.new()
		var s := BoxShape3D.new()
		s.size = boyut
		c.shape = s
		b.add_child(c)
		b.position = p
		m.position = Vector3.ZERO
		b.add_child(m)
		add_child(b)
		return b
	add_child(m)
	return m
