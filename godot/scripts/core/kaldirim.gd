extends Node3D
# 3 boyutlu kaldırım: yol eksenlerinin iki yanında yükseltilmiş beton şerit + yola bakan bordür yüzü.
# Kesişen yolların asfaltı üstüne kaldırım çıkmaz (şerit orada kesilir). Yükseklik izgarası harita.yuk()'a
# eklenir, yani yayalar ve oyuncu kaldırıma gerçekten "çıkar".

const YUK := 0.2        # bordür yüksekliği (m)
const GEN := 2.4        # kaldırım genişliği (m)
const HUCRE := 8.0
const IZ := 1.0         # yükseklik izgarası hücresi (m)

const SH := """
shader_type spatial;
varying vec3 wp;
varying vec3 wn;
void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wn = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
}
float h(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	vec2 uv = wp.xz / 1.6;
	vec2 f = fract(uv);
	vec2 id = floor(uv);
	float j = clamp(step(f.x, 0.035) + step(f.y, 0.035), 0.0, 1.0);
	vec3 top = vec3(0.50, 0.48, 0.45) * (0.88 + 0.16 * h(id)) * (1.0 - 0.28 * j);
	vec3 yan = vec3(0.66, 0.64, 0.6) * (0.92 + 0.1 * h(floor(wp.xz / 2.0)));
	float u = step(0.7, wn.y);
	ALBEDO = mix(yan, top, u);
	ROUGHNESS = 0.95;
}
"""

var harita: Node
var _yollar: Array = []        # {p: PackedVector2Array, w}
var _hash := {}                # Vector2i -> Array[Vector2i(yol, nokta)]
var _x0 := 0.0
var _z0 := 0.0
var _gw := 0
var _gh := 0
var _m := PackedByteArray()

func kur(h: Node, x0: float, z0: float, gen: float, der: float) -> void:
	harita = h
	_x0 = x0
	_z0 = z0
	_gw = int(ceil(gen / IZ)) + 1
	_gh = int(ceil(der / IZ)) + 1
	_m.resize(_gw * _gh)
	_m.fill(0)
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
		var yi := _yollar.size()
		_yollar.append({"p": p, "w": float(y["w"])})
		for i in p.size():
			var key := Vector2i(int(floor(p[i].x / HUCRE)), int(floor(p[i].y / HUCRE)))
			if not _hash.has(key):
				_hash[key] = []
			_hash[key].append(Vector2i(yi, i))
	_mesh_kur()

# (x,z) noktasındaki kaldırım yüksekliği (0 ya da YUK).
func ek(x: float, z: float) -> float:
	var i := int((x - _x0) / IZ + 0.5)
	var j := int((z - _z0) / IZ + 0.5)
	if i < 0 or j < 0 or i >= _gw or j >= _gh:
		return 0.0
	return YUK if _m[j * _gw + i] != 0 else 0.0

func _yolda(q: Vector2, haric: int) -> bool:
	var key := Vector2i(int(floor(q.x / HUCRE)), int(floor(q.y / HUCRE)))
	for dx in range(-1, 2):
		for dz in range(-1, 2):
			var k := key + Vector2i(dx, dz)
			if not _hash.has(k):
				continue
			for r in _hash[k]:
				if r.x == haric:
					continue
				var lim: float = float(_yollar[r.x]["w"]) * 0.5 + 1.2
				if (_yollar[r.x]["p"] as PackedVector2Array)[r.y].distance_squared_to(q) < lim * lim:
					return true
	return false

func _iz_yaz(a: Vector2, b: Vector2) -> void:
	var n := int(ceil(a.distance_to(b) / 0.5)) + 1
	for s in n + 1:
		var q := a.lerp(b, float(s) / float(n))
		var i := int((q.x - _x0) / IZ + 0.5)
		var j := int((q.y - _z0) / IZ + 0.5)
		if i >= 0 and j >= 0 and i < _gw and j < _gh:
			_m[j * _gw + i] = 1

func _mesh_kur() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var adet := 0
	for yi in _yollar.size():
		var p: PackedVector2Array = _yollar[yi]["p"]
		var w: float = _yollar[yi]["w"]
		for yan in [-1.0, 1.0]:
			var onceki_ok := false
			var ia := Vector2.ZERO
			var oa := Vector2.ZERO
			var ya := 0.0
			var yoa := 0.0
			for i in p.size():
				var i0 := maxi(i - 1, 0)
				var i1 := mini(i + 1, p.size() - 1)
				var t := (p[i1] - p[i0]).normalized()
				var nr: Vector2 = Vector2(-t.y, t.x) * float(yan)
				var ic: Vector2 = p[i] + nr * (w * 0.5)
				var dis: Vector2 = p[i] + nr * (w * 0.5 + GEN)
				var ok := true
				# kesişen yolun asfaltı, köprü/iskele güvertesi, su: kaldırım yok
				if _yolda(ic, yi) or _yolda(dis, yi) or _yolda((ic + dis) * 0.5, yi):
					ok = false
				var yi_t: float = 0.0
				var yo_t: float = 0.0
				if ok:
					var gi: float = harita.yuk(ic.x, ic.y, true)
					var go: float = harita.yuk(dis.x, dis.y, true)
					var ti: float = harita._arazi.yuk(ic.x, ic.y)
					var to: float = harita._arazi.yuk(dis.x, dis.y)
					if absf(gi - ti) > 0.01 or absf(go - to) > 0.01 or ti < 0.15 or to < 0.15:
						ok = false
					yi_t = ti
					yo_t = to
				if ok and onceki_ok:
					_serit(st, ia, oa, ya, yoa, ic, dis, yi_t, yo_t, nr)
					_iz_yaz(ic, dis)
					_iz_yaz(ia, ic)
					_iz_yaz(oa, dis)
					adet += 1
				onceki_ok = ok
				ia = ic
				oa = dis
				ya = yi_t
				yoa = yo_t
	if adet == 0:
		return
	var mesh := st.commit()
	var sh := Shader.new()
	sh.code = SH
	var mt := ShaderMaterial.new()
	mt.shader = sh
	mesh.surface_set_material(0, mt)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	add_child(mi)

func _v(st: SurfaceTool, q: Vector2, y: float, n: Vector3) -> void:
	st.set_normal(n)
	st.add_vertex(Vector3(q.x, y, q.y))

# Bir şerit parçası: üst yüz + yola bakan bordür yüzü. nr: yoldan dışa doğru birim vektör.
func _serit(st: SurfaceTool, ia: Vector2, oa: Vector2, ya: float, yoa: float, ib: Vector2, ob: Vector2, yb: float, yob: float, nr: Vector2) -> void:
	var up := Vector3.UP
	var ya_u := ya + YUK
	var yoa_u := yoa + YUK
	var yb_u := yb + YUK
	var yob_u := yob + YUK
	# üst
	_v(st, ia, ya_u, up)
	_v(st, oa, yoa_u, up)
	_v(st, ib, yb_u, up)
	_v(st, oa, yoa_u, up)
	_v(st, ob, yob_u, up)
	_v(st, ib, yb_u, up)
	# bordür (yola bakar)
	var bn := Vector3(-nr.x, 0, -nr.y)
	_v(st, ia, ya - 0.02, bn)
	_v(st, ia, ya_u, bn)
	_v(st, ib, yb - 0.02, bn)
	_v(st, ia, ya_u, bn)
	_v(st, ib, yb_u, bn)
	_v(st, ib, yb - 0.02, bn)
