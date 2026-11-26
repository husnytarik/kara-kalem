extends Node3D
# Yollar: data/yol_ag.json eksenlerinden arazinin üstüne düz şerit (plane) olarak kurulur.
# Asfalt şeridi + ana caddelerde kesik sarı orta çizgi. Raylar arazi dokusunda kalır.

var harita: Node3D

const YUKSEK := 0.07       # arazinin üstünde (z-çakışması olmasın)
const SERIT_YUKSEK := 0.10

func _ready() -> void:
	var f := FileAccess.open("res://data/yol_ag.json", FileAccess.READ)
	if f == null:
		return
	var d: Array = JSON.parse_string(f.get_as_text())
	var asfalt := SurfaceTool.new()
	asfalt.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sari := SurfaceTool.new()
	sari.begin(Mesh.PRIMITIVE_TRIANGLES)
	for y in d:
		var p: Array = y["pts"]
		if p.size() < 2:
			continue
		var w := float(y["w"])
		_serit(asfalt, p, w, YUKSEK, 0.0, 0.0)
		if y["sinif"] == "ana" and w >= 11.0:
			_serit(sari, p, 0.35, SERIT_YUKSEK, 2.5, 2.5)
	_mesh_ekle(asfalt, Color(0.17, 0.17, 0.185), 1.0)
	_mesh_ekle(sari, Color(0.84, 0.70, 0.24), 0.8)

func _mesh_ekle(st: SurfaceTool, renk: Color, kabalik: float) -> void:
	st.generate_normals()
	var m := st.commit()
	if m == null or m.get_surface_count() == 0:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = renk
	mat.roughness = kabalik
	m.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)

# p: [[x,z],...] eksen noktaları; w: genişlik. dolu/bos > 0 ise kesik çizgi (m).
func _serit(st: SurfaceTool, p: Array, w: float, yuk: float, dolu: float, bos: float) -> void:
	var h := w * 0.5
	var kat := 0.0
	for i in range(p.size() - 1):
		var a := Vector2(p[i][0], p[i][1])
		var b := Vector2(p[i + 1][0], p[i + 1][1])
		var uz := a.distance_to(b)
		if uz < 0.01:
			continue
		var dir := (b - a) / uz
		var n := Vector2(-dir.y, dir.x) * h
		if dolu > 0.0:
			var ph := fmod(kat, dolu + bos)
			kat += uz
			if ph > dolu:
				continue
		var a2 := a - dir * 0.05
		var b2 := b + dir * 0.05
		var v: Array[Vector3] = [
			_nokta(a2 + n, yuk), _nokta(a2 - n, yuk), _nokta(b2 + n, yuk), _nokta(b2 - n, yuk)]
		for k in [0, 2, 1, 1, 2, 3]:
			st.add_vertex(v[k])

func _nokta(q: Vector2, yuk: float) -> Vector3:
	return Vector3(q.x, harita.yuk(q.x, q.y) + yuk, q.y)
