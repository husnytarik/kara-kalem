extends Node3D
# Harita sahnesinin (scenes/city/harita.tscn) çalışma zamanı beyni. Haritayı sen düzenlersin:
#   • Arazi: assets/environment/terrain/yukseklik.png ve renk.png (resim programında boya)
#   • Binalar: sahnede "Binalar" altındaki Bina düğümleri (taşı, çoğalt, boyutlandır, model ekle)
#   • Mahalleler: data/bolgeler.json (adı ve sınırları)
# Bu betik sahneyi okuyup yol ızgarasını, bina listesini ve mahalle sınırlarını kurar.

var bolgeler := {}                     # id -> {ad, x0, z0, x1, z1}
var yerler: Array[Dictionary] = []     # {ad, bolge, ozel, pos, aabb}
var _arazi: Node3D
var _iskeleler: Array[AABB] = []
var dolgu: Array[AABB] = []            # süs binalar (işletme değil; yine de engel ve görüş kesici)
var _dolgu_obb: Array = []             # {xf, yerel}: dönük süs binalar için tam kutu
var _izgara: AStarGrid2D
var _gx0 := 0
var _gz0 := 0

func _ready() -> void:
	_arazi = get_node("Arazi")
	_bolgeleri_oku()
	# Sokak donanımı (köprü/iskele güverteleri, su, lamba, ağaç) yol bulmadan ÖNCE kurulur.
	var dekor := Node3D.new()
	dekor.set_script(load("res://scripts/core/sehir_dekor.gd"))
	dekor.harita = self
	add_child(dekor)
	for n in get_tree().get_nodes_in_group("bina"):
		var a: AABB = n.dunya_aabb()
		var yerel := AABB(Vector3(-n.boyut.x / 2.0, 0, -n.boyut.z / 2.0), n.boyut)
		if n.dolgu:
			dolgu.append(a)
			_dolgu_obb.append({"xf": n.global_transform, "ters": n.global_transform.affine_inverse(), "yerel": yerel, "aabb": a})
			continue
		var mb: String = bolge_at(n.global_position)
		yerler.append({"ad": n.ad, "bolge": mb if mb != "" else n.bolge, "ozel": n.ozel, "pos": n.global_position, "aabb": a,
			"xf": n.global_transform, "ters": n.global_transform.affine_inverse(), "yerel": yerel})
	for n in get_tree().get_nodes_in_group("iskele"):
		var m := n as MeshInstance3D
		_iskeleler.append(m.global_transform * m.mesh.get_aabb())
	_izgara_kur()

func _bolgeleri_oku() -> void:
	var f := FileAccess.open("res://data/bolgeler.json", FileAccess.READ)
	if f == null:
		push_error("data/bolgeler.json okunamadı")
		return
	bolgeler = JSON.parse_string(f.get_as_text())

# ---------- yükseklik, mahalle ----------
func yuk(x: float, z: float, iskele: bool = true) -> float:
	if iskele:
		for a in _iskeleler:
			if x >= a.position.x and x <= a.end.x and z >= a.position.z and z <= a.end.z:
				return a.end.y
	return _arazi.yuk(x, z)

func merkez(id: String) -> Vector3:
	var b: Dictionary = bolgeler[id]
	var c := poly_agirlik(b)
	return Vector3(c.x, yuk(c.x, c.y), c.y)

# Mahalle çokgeninin ağırlık merkezi (çokgen yoksa dikdörtgen merkezi).
func poly_agirlik(b: Dictionary) -> Vector2:
	var pl: Array = b.get("poly", [])
	if pl.size() < 3:
		return Vector2((b["x0"] + b["x1"]) / 2.0, (b["z0"] + b["z1"]) / 2.0)
	var A := 0.0
	var cx := 0.0
	var cz := 0.0
	for i in pl.size():
		var p: Array = pl[i]
		var q: Array = pl[(i + 1) % pl.size()]
		var cr: float = p[0] * q[1] - q[0] * p[1]
		A += cr
		cx += (p[0] + q[0]) * cr
		cz += (p[1] + q[1]) * cr
	if absf(A) < 0.001:
		return Vector2((b["x0"] + b["x1"]) / 2.0, (b["z0"] + b["z1"]) / 2.0)
	return Vector2(cx / (3.0 * A), cz / (3.0 * A))

func bolge_at(p: Vector3) -> String:
	for id in bolgeler:
		var b: Dictionary = bolgeler[id]
		if p.x >= b["x0"] and p.x < b["x1"] and p.z >= b["z0"] and p.z < b["z1"]:
			var pl: Array = b.get("poly", [])
			if pl.size() < 3 or _poly_ici(pl, p.x, p.z):
				return id
	return ""

func _poly_ici(pl: Array, x: float, z: float) -> bool:
	var ic := false
	var j := pl.size() - 1
	for i in pl.size():
		var a: Array = pl[i]
		var c: Array = pl[j]
		if (a[1] > z) != (c[1] > z) and x < (c[0] - a[0]) * (z - a[1]) / (c[1] - a[1]) + a[0]:
			ic = not ic
		j = i
	return ic

# ---------- yol bulma (1 m'lik ızgara, A*) ----------
# Yürünür: mahalle sınırları içi. Kapalı: binalar, kaideler. Açık: iskeleler.
func _rect(a: AABB, pay: float) -> Rect2i:
	var x0 := int(floor(a.position.x - pay)) - _gx0
	var z0 := int(floor(a.position.z - pay)) - _gz0
	var x1 := int(ceil(a.end.x + pay)) - _gx0
	var z1 := int(ceil(a.end.z + pay)) - _gz0
	return Rect2i(x0, z0, x1 - x0, z1 - z0)

const SU_ESIK := 0.3

# Dönük bir binanın taban izini (1 m pay ile) ızgarada kapat.
func _kutu_kapat(xf: Transform3D, yerel: AABB, kaba: Variant) -> void:
	var ters := xf.affine_inverse()
	var a: AABB = kaba if kaba != null else xf * yerel
	if kaba == null:
		a = AABB(xf * Vector3(yerel.position.x, 0, yerel.position.z), Vector3.ZERO)
		for sx in [0.0, 1.0]:
			for sz in [0.0, 1.0]:
				a = a.expand(xf * Vector3(yerel.position.x + sx * yerel.size.x, 0, yerel.position.z + sz * yerel.size.z))
	var r := _rect(a, 1.0)
	for gz in range(r.position.y, r.end.y):
		for gx in range(r.position.x, r.end.x):
			if not _izgara.is_in_boundsv(Vector2i(gx, gz)):
				continue
			var l := ters * Vector3(_gx0 + gx + 0.5, 0, _gz0 + gz + 0.5)
			if absf(l.x - (yerel.position.x + yerel.size.x / 2.0)) <= yerel.size.x / 2.0 + 1.0 and absf(l.z - (yerel.position.z + yerel.size.z / 2.0)) <= yerel.size.z / 2.0 + 1.0:
				_izgara.set_point_solid(Vector2i(gx, gz), true)

func _izgara_kur() -> void:
	_gx0 = int(floor(_arazi.x0))
	_gz0 = int(floor(_arazi.z0))
	_izgara = AStarGrid2D.new()
	_izgara.region = Rect2i(0, 0, int(_arazi.genislik), int(_arazi.derinlik))
	_izgara.cell_size = Vector2.ONE
	_izgara.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_izgara.default_compute_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_izgara.default_estimate_heuristic = AStarGrid2D.HEURISTIC_EUCLIDEAN
	_izgara.update()
	_izgara.fill_solid_region(_izgara.region, true)
	for id in bolgeler:
		var b: Dictionary = bolgeler[id]
		_izgara.fill_solid_region(Rect2i(int(b["x0"]) - _gx0, int(b["z0"]) - _gz0, int(b["x1"] - b["x0"]), int(b["z1"] - b["z0"])), false)
	# su (göl, nehir) yürünmez; iskele ve köprüler aşağıda yeniden açılır
	var yim: Image = _arazi.yukseklik_resmi()
	var yw := yim.get_width()
	var yh := yim.get_height()
	var yv := yim.get_data()
	var esik := int(ceil((SU_ESIK - _arazi.min_h) / (_arazi.max_h - _arazi.min_h) * 255.0))
	for gz in int(_arazi.derinlik):
		var j := mini(int((gz + 0.5) / _arazi.derinlik * yh), yh - 1) * yw
		for gx in int(_arazi.genislik):
			if yv[j + mini(int((gx + 0.5) / _arazi.genislik * yw), yw - 1)] < esik:
				_izgara.set_point_solid(Vector2i(gx, gz), true)
	for n in get_tree().get_nodes_in_group("kaide"):
		var m := n as MeshInstance3D
		_izgara.fill_solid_region(_rect(m.global_transform * m.mesh.get_aabb(), 1.0), true)
	for y in yerler:
		_kutu_kapat(y["xf"], y["yerel"], y["aabb"])
	for o in _dolgu_obb:
		_kutu_kapat(o["xf"], o["yerel"], null)
	for a in _iskeleler:
		var r := _rect(a, -0.5)
		r.position.y -= 1
		r.size.y += 1
		_izgara.fill_solid_region(r, false)

# Görüş/yürüme için: bu nokta bina, kaide ya da mahalle dışı mı?
func engelli(p: Vector3) -> bool:
	return _izgara.is_point_solid(_hucre(p))

func _hucre(p: Vector3) -> Vector2i:
	var r := _izgara.region.size
	return Vector2i(clampi(int(floor(p.x)) - _gx0, 0, r.x - 1), clampi(int(floor(p.z)) - _gz0, 0, r.y - 1))

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

# Verilen noktaya en yakın yürünebilir nokta (başlangıç/ışınlama için).
func serbest_nokta(p: Vector3) -> Vector3:
	var c := _acik(_hucre(p))
	var x := _gx0 + c.x + 0.5
	var z := _gz0 + c.y + 0.5
	return Vector3(x, yuk(x, z), z)

# Dünya koordinatından dünya koordinatına yol (köşe noktaları). Boşsa ulaşılamaz.
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
		var x := _gx0 + p.x + 0.5
		var z := _gz0 + p.y + 0.5
		cikti.append(Vector3(x, yuk(x, z), z))
	return cikti

# ---------- savaş alanı seçimi ----------
# Konuma en yakın savaş seviyesi. Önce sahnede senin koyduğun "savas_alani" düğümleri (150 m içinde),
# yoksa kural: iskele/liman mahallesi -> liman, bir binanın kapısındaysan -> ic, aksi halde sokak.
func savas_alani(p: Vector3) -> Dictionary:
	var en: Node = null
	var en_uz := 150.0
	for n in get_tree().get_nodes_in_group("savas_alani"):
		var d: float = (n as Node3D).global_position.distance_to(p)
		if d < en_uz:
			en_uz = d
			en = n
	if en != null:
		return {"tur": en.tur, "sahne": en.sahne.resource_path if en.sahne else ""}
	if bolge_at(p) == "docks":
		return {"tur": "liman", "sahne": ""}
	for y in yerler:
		if (y["aabb"] as AABB).grow(3.0).has_point(Vector3(p.x, y["aabb"].position.y + 1.0, p.z)):
			return {"tur": "ic", "sahne": ""}
	return {"tur": "sokak", "sahne": ""}

# ---------- seçim (fare) ----------
# Işının çarptığı bina (yerler indeksi) ya da -1.
func yer_isinla(o: Vector3, n: Vector3) -> int:
	var en := -1
	var en_d := 1e9
	for i in yerler.size():
		var y: Dictionary = yerler[i]
		if (y["aabb"] as AABB).intersects_ray(o, n) == null:   # ucuz ön eleme (dünya kutusu)
			continue
		var ters: Transform3D = y["ters"]
		var h = (y["yerel"] as AABB).intersects_ray(ters * o, ters.basis * n)
		if h != null:
			var d := (ters * o).distance_to(h)
			if d < en_d:
				en_d = d
				en = i
	for ob in _dolgu_obb:   # süs bina önündeyse tıklama ona çarpar
		if (ob["aabb"] as AABB).intersects_ray(o, n) == null:
			continue
		var t2: Transform3D = ob["ters"]
		var h2 = (ob["yerel"] as AABB).intersects_ray(t2 * o, t2.basis * n)
		if h2 != null and (t2 * o).distance_to(h2) < en_d:
			return -1
	return en

# Işının araziyle kesiştiği nokta (adım adım ilerleyerek).
func arazi_isinla(o: Vector3, n: Vector3) -> Variant:
	var t := 0.0
	var onceki := 0.0
	while t < 1500.0:
		var p := o + n * t
		if p.y <= yuk(p.x, p.z, false):
			var lo := onceki
			var hi := t
			for k in 12:
				var mid := (lo + hi) / 2.0
				var q := o + n * mid
				if q.y <= yuk(q.x, q.z, false):
					hi = mid
				else:
					lo = mid
			var r := o + n * hi
			return Vector3(r.x, yuk(r.x, r.z), r.z)
		onceki = t
		t += 2.0
	return null
