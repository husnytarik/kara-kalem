extends Node3D
# Trafik ışıkları: yol kesişimlerinde iki eksen (A, B) sırayla yeşil -> sarı -> kırmızı olur.
# Araçlar kırmızı/sarıda durma çizgisinde bekler, yayalar kendi eksenleri yeşil değilse karşıya geçmez.

const CEMBER := 24.0
const HUCRE := 24.0

var harita: Node
var _kav: Array = []          # {p: Vector2, a: Vector2, b: Vector2, wa, wb, ofs, lamba: [[idx...]]}
var _hash := {}
var _t := 0.0
var _mm_k: MultiMesh
var _mm_s: MultiMesh
var _mm_y: MultiMesh
var _basliklar: Array = []    # {j: kavsak idx, eksen: 0/1, xf: Transform3D}
var _son: Array = []

func kur(h: Node, yol: Array, ham: Dictionary) -> void:
	harita = h
	_kavsak_bul(yol, ham)
	_gorsel_kur()

func _kavsak_bul(yol: Array, ham: Dictionary) -> void:
	for yi in yol.size():
		var p: PackedVector2Array = yol[yi]["p"]
		for i in range(1, p.size() - 1):
			var m := p[i]
			var key := Vector2i(int(floor(m.x / 8.0)), int(floor(m.y / 8.0)))
			var bulundu := false
			for dx in range(-1, 2):
				if bulundu:
					break
				for dz in range(-1, 2):
					var k := key + Vector2i(dx, dz)
					if not ham.has(k):
						continue
					for q in ham[k]:
						if q.x <= yi:
							continue
						var pb: PackedVector2Array = yol[q.x]["p"]
						if pb[q.y].distance_to(m) > 3.0:
							continue
						var a := (p[i + 1] - p[i - 1]).normalized()
						var qi0 := maxi(q.y - 1, 0)
						var qi1 := mini(q.y + 1, pb.size() - 1)
						var b := (pb[qi1] - pb[qi0]).normalized()
						if absf(a.dot(b)) > 0.85:
							continue
						_ekle(m, a, b, float(yol[yi]["w"]), float(yol[q.x]["w"]))
						bulundu = true
						break
					if bulundu:
						break

func _ekle(m: Vector2, a: Vector2, b: Vector2, wa: float, wb: float) -> void:
	for j in _yakin(m, 12.0):
		return
	var idx := _kav.size()
	_kav.append({"p": m, "a": a, "b": b, "wa": wa, "wb": wb, "ofs": fmod(m.x * 0.37 + m.y * 0.71, CEMBER)})
	var key := Vector2i(int(floor(m.x / HUCRE)), int(floor(m.y / HUCRE)))
	if not _hash.has(key):
		_hash[key] = []
	_hash[key].append(idx)

func _yakin(m: Vector2, r: float) -> Array:
	var out := []
	var key := Vector2i(int(floor(m.x / HUCRE)), int(floor(m.y / HUCRE)))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var k := key + Vector2i(dx, dz)
			if _hash.has(k):
				for idx in _hash[k]:
					if (_kav[idx]["p"] as Vector2).distance_to(m) < r:
						out.append(idx)
	return out

# eksen: 0 = A, 1 = B. Dönüş: 0 yeşil, 1 sarı, 2 kırmızı
func _durum(j: Dictionary, eksen: int) -> int:
	var f := fmod(_t + float(j["ofs"]) + (12.0 if eksen == 1 else 0.0), CEMBER)
	if f < 9.0:
		return 0
	if f < 11.0:
		return 1
	return 2

# t yönünde ilerleyen biri için konum q'nun önündeki ışığın durumu.
# Dönüş: {"d": ışığa mesafe (ilerleme yönünde), "durum": 0/1/2, "w": kesişen yol genişliği} ya da {}
func one_bak(q: Vector2, t: Vector2, menzil: float) -> Dictionary:
	var en := {}
	var en_d := menzil
	for idx in _yakin(q, menzil + 6.0):
		var j: Dictionary = _kav[idx]
		var fark: Vector2 = j["p"] - q
		var d := fark.dot(t)
		if d <= 0.0 or d >= en_d:
			continue
		var yan := (fark - t * d).length()
		var eksen := 0 if absf(t.dot(j["a"])) > 0.7 else 1
		var kes_w: float = float(j["wb"]) if eksen == 0 else float(j["wa"])
		if yan > 7.0:
			continue
		en_d = d
		en = {"d": d, "durum": _durum(j, eksen), "w": kes_w}
	return en

func _process(delta: float) -> void:
	_t += delta
	if _basliklar.is_empty():
		return
	var s: Array = []
	for j in _kav.size():
		s.append(_durum(_kav[j], 0) * 3 + _durum(_kav[j], 1))
	if s == _son:
		return
	_son = s
	_lamba_guncelle()

func _gorsel_kur() -> void:
	var kutu := BoxMesh.new()
	kutu.size = Vector3(0.14, 4.6, 0.14)
	var bas := BoxMesh.new()
	bas.size = Vector3(0.4, 1.15, 0.3)
	var lamba := SphereMesh.new()
	lamba.radius = 0.12
	lamba.height = 0.24
	lamba.radial_segments = 8
	lamba.rings = 4
	var govde_mm := MultiMesh.new()
	govde_mm.transform_format = MultiMesh.TRANSFORM_3D
	govde_mm.mesh = kutu
	var bas_mm := MultiMesh.new()
	bas_mm.transform_format = MultiMesh.TRANSFORM_3D
	bas_mm.mesh = bas
	var yer := []
	for idx in _kav.size():
		var j: Dictionary = _kav[idx]
		var a: Vector2 = j["a"]
		var b: Vector2 = j["b"]
		for sa in [-1.0, 1.0]:
			for sb in [-1.0, 1.0]:
				var c: Vector2 = j["p"] + a * sa * (float(j["wb"]) * 0.5 + 1.0) + b * sb * (float(j["wa"]) * 0.5 + 1.0)
				var y: float = harita.yuk(c.x, c.y)
				yer.append({"c": c, "y": y, "idx": idx})
				# A eksenine bakan baş (A yönünden gelen trafiğe, +sa tarafına bakar)
				_basliklar.append({"j": idx, "eksen": 0, "c": c, "y": y, "yon": a * sa})
				_basliklar.append({"j": idx, "eksen": 1, "c": c, "y": y, "yon": b * sb})
	govde_mm.instance_count = yer.size()
	for i in yer.size():
		govde_mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, Vector3(yer[i]["c"].x, yer[i]["y"] + 2.3, yer[i]["c"].y)))
	bas_mm.instance_count = _basliklar.size()
	for i in _basliklar.size():
		var h: Dictionary = _basliklar[i]
		var yon: Vector2 = h["yon"]
		var bs := Basis.looking_at(Vector3(yon.x, 0, yon.y), Vector3.UP, true)
		var kon := Vector3(h["c"].x, h["y"] + 4.0, h["c"].y) + Vector3(yon.x, 0, yon.y) * 0.18
		h["xf"] = Transform3D(bs, kon)
		bas_mm.set_instance_transform(i, h["xf"])
	var kara := StandardMaterial3D.new()
	kara.albedo_color = Color(0.07, 0.07, 0.08)
	_mm_ekle(govde_mm, kara)
	_mm_ekle(bas_mm, kara)
	_mm_k = _lamba_mm(lamba, Color(1.0, 0.15, 0.1))
	_mm_s = _lamba_mm(lamba, Color(1.0, 0.75, 0.1))
	_mm_y = _lamba_mm(lamba, Color(0.15, 1.0, 0.35))
	_lamba_guncelle()

func _mm_ekle(mm: MultiMesh, mt: Material) -> void:
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.material_override = mt
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

func _lamba_mm(mesh: Mesh, renk: Color) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = _basliklar.size()
	var mt := StandardMaterial3D.new()
	mt.albedo_color = renk
	mt.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mt.emission_enabled = true
	mt.emission = renk
	mt.emission_energy_multiplier = 2.5
	_mm_ekle(mm, mt)
	return mm

func _lamba_guncelle() -> void:
	var yok := Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	for i in _basliklar.size():
		var h: Dictionary = _basliklar[i]
		var d := _durum(_kav[h["j"]], h["eksen"])
		var xf: Transform3D = h["xf"]
		var on := xf.basis.z * 0.17
		# ışıkların bakış yönü: Basis.looking_at(..., true) +Z'yi yöne çevirir
		var kon := xf.origin + on
		_mm_k.set_instance_transform(i, Transform3D(Basis.IDENTITY, kon + Vector3(0, 0.36, 0)) if d == 2 else yok)
		_mm_s.set_instance_transform(i, Transform3D(Basis.IDENTITY, kon) if d == 1 else yok)
		_mm_y.set_instance_transform(i, Transform3D(Basis.IDENTITY, kon - Vector3(0, 0.36, 0)) if d == 0 else yok)
