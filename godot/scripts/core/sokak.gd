extends Node3D
# Faz 1 test sahnesi: zemin, ışık, kutu binalar, oyuncu ve kamera. Hepsi kodla kurulur.

func _ready() -> void:
	_cevre()
	_zemin()
	_binalar()
	var oyuncu := CharacterBody3D.new()
	oyuncu.set_script(load("res://scripts/characters/oyuncu.gd"))
	oyuncu.position = Vector3(0, 1.0, 8)
	add_child(oyuncu)
	var kamera := Node3D.new()
	kamera.set_script(load("res://scripts/characters/kamera.gd"))
	add_child(kamera)
	kamera.hedef = oyuncu
	oyuncu.kamera = kamera

func _cevre() -> void:
	var sky := ProceduralSkyMaterial.new()
	var s := Sky.new()
	s.sky_material = sky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = s
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	add_child(sun)

func _kutu(pos: Vector3, boyut: Vector3, renk: Color) -> StaticBody3D:
	var b := StaticBody3D.new()
	var m := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = boyut
	var mat := StandardMaterial3D.new()
	mat.albedo_color = renk
	mat.roughness = 0.9
	bm.material = mat
	m.mesh = bm
	b.add_child(m)
	var c := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = boyut
	c.shape = bs
	b.add_child(c)
	b.position = pos
	add_child(b)
	return b

func _zemin() -> void:
	_kutu(Vector3(0, -0.5, 0), Vector3(120, 1, 120), Color(0.28, 0.27, 0.25))   # kaldırım/zemin
	_kutu(Vector3(0, -0.45, 0), Vector3(10, 1, 120), Color(0.14, 0.14, 0.15))   # yol

func _binalar() -> void:
	var renkler := [Color(0.45, 0.25, 0.2), Color(0.5, 0.42, 0.3), Color(0.33, 0.33, 0.38), Color(0.4, 0.3, 0.25)]
	var i := 0
	for z in range(-50, 51, 20):
		for yon in [-1, 1]:
			var yuk := 8.0 + float((i * 7) % 9)
			_kutu(Vector3(yon * 14.0, yuk / 2.0, z), Vector3(12, yuk, 16), renkler[i % renkler.size()])
			i += 1
