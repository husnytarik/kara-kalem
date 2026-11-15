extends Node3D
# Ana sahne: şehir haritası, ışık, oyuncu, kamera ve bölge adı göstergesi.

var harita: Node3D
var oyuncu: CharacterBody3D
var _etiket: Label

func _ready() -> void:
	_cevre()
	harita = load("res://scripts/core/harita.gd").new()
	add_child(harita)
	harita.kur()
	oyuncu = CharacterBody3D.new()
	oyuncu.set_script(load("res://scripts/characters/oyuncu.gd"))
	oyuncu.position = harita.merkez("southside") + Vector3(0, 1.0, 0)   # senin semtin
	add_child(oyuncu)
	var kamera := Node3D.new()
	kamera.set_script(load("res://scripts/characters/kamera.gd"))
	add_child(kamera)
	kamera.hedef = oyuncu
	oyuncu.kamera = kamera
	var hud := CanvasLayer.new()
	_etiket = Label.new()
	_etiket.position = Vector2(20, 14)
	_etiket.add_theme_font_size_override("font_size", 26)
	hud.add_child(_etiket)
	add_child(hud)
	if "--ust" in OS.get_cmdline_user_args():   # doğrulama için kuş bakışı kamera
		kamera.queue_free()
		var k := Camera3D.new()
		add_child(k)
		k.position = Vector3(0, 520, 330)
		k.look_at(Vector3(0, 0, 20))
		k.current = true

func _process(_d: float) -> void:
	var id: String = harita.bolge_at(oyuncu.global_position)
	_etiket.text = harita.bolgeler[id]["ad"] if id != "" else "Yollar"

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
	sun.directional_shadow_max_distance = 300.0
	add_child(sun)
