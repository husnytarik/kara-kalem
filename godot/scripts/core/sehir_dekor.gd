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
	_isik_havuzlari(d.get("lamba", []))
	var govde := CylinderMesh.new()
	govde.top_radius = 0.22
	govde.bottom_radius = 0.3
	govde.height = 3.0
	_coklu(govde, d.get("agac", []), 1.5, Color(0.28, 0.2, 0.14), false)
	var tepe := SphereMesh.new()
	tepe.radius = 2.4
	tepe.height = 4.4
	_coklu(tepe, d.get("agac", []), 4.6, Color(0.2, 0.38, 0.18), false)

# Gece lamba altında sıcak ışık havuzu + lamba başında hale (additive, MultiMesh). Parlaklık sokak.gd _atmosfer'den meta ile ayarlanır.
func _isik_havuzlari(noktalar: Array) -> void:
	var gr := Gradient.new()
	gr.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gr.colors = PackedColorArray([Color(1, 0.8, 0.45, 1), Color(1, 0.65, 0.3, 0.25), Color(1, 0.6, 0.25, 0.0)])
	var tx := GradientTexture2D.new()
	tx.gradient = gr
	tx.fill = GradientTexture2D.FILL_RADIAL
	tx.fill_from = Vector2(0.5, 0.5)
	tx.fill_to = Vector2(1.0, 0.5)
	tx.width = 128
	tx.height = 128
	var havuz := PlaneMesh.new()
	havuz.size = Vector2(16, 16)
	var hale := QuadMesh.new()
	hale.size = Vector2(5, 5)
	var mats: Array = []
	for tur in 2:
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		m.albedo_texture = tx
		m.albedo_color = Color(1, 1, 1, 0)
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if tur == 1:
			m.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
			m.no_depth_test = false
		mats.append(m)
		var mesh: Mesh = havuz if tur == 0 else hale
		mesh.surface_set_material(0, m)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh
		mm.instance_count = noktalar.size()
		for k in noktalar.size():
			var x: float = noktalar[k][0]
			var z: float = noktalar[k][1]
			var y: float = harita.yuk(x, z, false) + (0.25 if tur == 0 else 6.3)
			mm.set_instance_transform(k, Transform3D(Basis.IDENTITY, Vector3(x, y, z)))
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)
	harita.set_meta("lamba_mat", mats)

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
