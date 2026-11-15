extends Node3D
# Ana sahne: haritayı kurar. Mount & Blade tarzı yukarıdan yönetim:
# sol tık = oraya git. Zaman: Boşluk duraklat, 1/2/3 hız.

var harita: Node3D
var oyuncu: Node3D
var kamera: Node3D
var _etiket: Label
var _ipucu: Label
var _hiz := 1.0

func _ready() -> void:
	_cevre()
	harita = load("res://scenes/city/harita.tscn").instantiate()
	add_child(harita)
	oyuncu = Node3D.new()
	oyuncu.set_script(load("res://scripts/characters/harita_oyuncu.gd"))
	oyuncu.harita = harita
	add_child(oyuncu)
	oyuncu.global_position = harita.merkez("southside")   # senin semtin, yol kesişimi
	oyuncu.global_position.y = harita.yuk(oyuncu.global_position.x, oyuncu.global_position.z)
	kamera = Node3D.new()
	kamera.set_script(load("res://scripts/characters/ust_kamera.gd"))
	add_child(kamera)
	kamera.hedef = oyuncu
	var hud := CanvasLayer.new()
	_etiket = Label.new()
	_etiket.position = Vector2(20, 14)
	_etiket.add_theme_font_size_override("font_size", 26)
	hud.add_child(_etiket)
	_ipucu = Label.new()
	_ipucu.position = Vector2(20, 52)
	_ipucu.add_theme_font_size_override("font_size", 22)
	_ipucu.modulate = Color(1.0, 0.85, 0.4)
	hud.add_child(_ipucu)
	var yardim := Label.new()
	yardim.text = "Sol tık: git · Sağ tık sürükle: döndür · Tekerlek: yakınlaş · WASD: kaydır · C: ortala · Boşluk: duraklat · 1/2/3: hız"
	yardim.position = Vector2(20, 690)
	yardim.add_theme_font_size_override("font_size", 14)
	yardim.modulate = Color(1, 1, 1, 0.7)
	hud.add_child(yardim)
	add_child(hud)
	for a in OS.get_cmdline_user_args():   # doğrulama: --hedef=x,z
		if a.begins_with("--hedef="):
			var p := a.substr(8).split(",")
			oyuncu.git(Vector3(float(p[0]), 0, float(p[1])))

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var k: Camera3D = kamera.kamera()
		var o := k.project_ray_origin(e.position)
		var n := k.project_ray_normal(e.position)
		var i: int = harita.yer_isinla(o, n)
		if i >= 0:
			oyuncu.git(harita.yerler[i]["pos"])   # binaya tıkla: önüne git
		else:
			var nokta = harita.arazi_isinla(o, n)
			if nokta != null:
				oyuncu.git(nokta)
	elif e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_SPACE: Engine.time_scale = 0.0 if Engine.time_scale > 0.0 else _hiz
			KEY_1: _hiz = 1.0; Engine.time_scale = _hiz
			KEY_2: _hiz = 2.0; Engine.time_scale = _hiz
			KEY_3: _hiz = 4.0; Engine.time_scale = _hiz

func _process(_d: float) -> void:
	var id: String = harita.bolge_at(oyuncu.global_position)
	var ad: String = harita.bolgeler[id]["ad"] if id != "" else "Yollar"
	_etiket.text = "%s   ·   %s" % [ad, "DURAKLATILDI" if Engine.time_scale == 0.0 else "hız ×%d" % int(Engine.time_scale)]
	var k: Camera3D = kamera.kamera()
	var fp := get_viewport().get_mouse_position()
	var i: int = harita.yer_isinla(k.project_ray_origin(fp), k.project_ray_normal(fp))
	if i >= 0:
		var y: Dictionary = harita.yerler[i]
		_ipucu.text = "%s  (%s)" % [y["ad"], harita.bolgeler[y["bolge"]]["ad"]]
	else:
		_ipucu.text = ""

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
	sun.directional_shadow_max_distance = 400.0
	add_child(sun)
