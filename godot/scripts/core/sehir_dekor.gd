extends Node3D
# Sokak donanımı: lamba direkleri ve ağaçlar (data/sokak_ag.json, tools/sehir_uret2.py üretir).
# MultiMesh kullanır, yani yüzlerce nesne tek çizim çağrısıdır.

var harita: Node3D

func _ready() -> void:
	var f := FileAccess.open("res://data/sokak_ag.json", FileAccess.READ)
	if f == null:
		return
	var d: Dictionary = JSON.parse_string(f.get_as_text())
	_su_kur()
	for g in d.get("iskele", []):
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(g["w"], 1.0, g["d"])
		mi.mesh = bm
		var mt := StandardMaterial3D.new()
		var c: Array = g["renk"]
		mt.albedo_color = Color(c[0], c[1], c[2])
		mt.roughness = 0.9
		mi.material_override = mt
		mi.position = Vector3(g["x"], g["y"] - 0.5, g["z"])
		mi.add_to_group("iskele")
		add_child(mi)
	var direk := CylinderMesh.new()
	direk.top_radius = 0.12
	direk.bottom_radius = 0.18
	direk.height = 6.0
	_coklu(direk, d.get("lamba", []), 3.0, Color(0.12, 0.12, 0.13), false)
	var kafa := SphereMesh.new()
	kafa.radius = 0.55
	kafa.height = 1.1
	_coklu(kafa, d.get("lamba", []), 6.3, Color(1.0, 0.85, 0.5), true)
	var govde := CylinderMesh.new()
	govde.top_radius = 0.22
	govde.bottom_radius = 0.3
	govde.height = 3.0
	_coklu(govde, d.get("agac", []), 1.5, Color(0.28, 0.2, 0.14), false)
	var tepe := SphereMesh.new()
	tepe.radius = 2.4
	tepe.height = 4.4
	_coklu(tepe, d.get("agac", []), 4.6, Color(0.2, 0.38, 0.18), false)

func _coklu(mesh: Mesh, noktalar: Array, yuk: float, renk: Color, isik: bool) -> void:
	var m := StandardMaterial3D.new()
	m.albedo_color = renk
	m.roughness = 0.9
	if isik:
		m.emission_enabled = true
		m.emission = renk
		m.emission_energy_multiplier = 1.4
	mesh.surface_set_material(0, m)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = noktalar.size()
	for k in noktalar.size():
		var x: float = noktalar[k][0]
		var z: float = noktalar[k][1]
		mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, Vector3(x, harita.yuk(x, z, false) + yuk, z)))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	add_child(mi)

# Göl ve nehir: tek büyük saydam su düzlemi (arazi suyun altında çukur kalır).
func _su_kur() -> void:
	var pm := PlaneMesh.new()
	pm.size = Vector2(728.0, 1188.0)
	var mt := StandardMaterial3D.new()
	mt.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mt.albedo_color = Color(0.10, 0.27, 0.38, 0.88)
	mt.roughness = 0.12
	mt.metallic = 0.25
	var mi := MeshInstance3D.new()
	mi.mesh = pm
	mi.material_override = mt
	mi.position = Vector3(0, 0, 78)
	add_child(mi)
