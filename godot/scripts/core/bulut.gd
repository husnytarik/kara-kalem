extends Node3D
# Mahalle (harita) görünümünde yüksekten bakarken şehrin üstünde süzülen bulutlar.
# Görsel: assets/ui/bulut1..4.png varsa o (alfa kanalı bulut), yoksa gürültüden üretilen yumuşak bulut.

const ADET := 22
const YUKSEKLIK := 150.0

const SH := """
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;
uniform sampler2D gurultu : repeat_enable;
uniform sampler2D imge : source_color;
uniform bool imge_var = false;
uniform float alfa = 0.0;
uniform float tohum = 0.0;
void fragment() {
	vec2 q = UV - vec2(0.5);
	float a;
	vec3 renk = vec3(0.97, 0.97, 0.99);
	if (imge_var) {
		vec4 t = texture(imge, UV);
		a = t.a;
		renk = t.rgb;
	} else {
		float n = texture(gurultu, UV * 0.9 + vec2(tohum, tohum * 0.7)).r;
		float kenar = 1.0 - smoothstep(0.18, 0.5, length(q * vec2(1.0, 1.25)));
		a = smoothstep(0.42, 0.78, n * 0.85 + kenar * 0.55) * kenar;
		renk = mix(vec3(0.82, 0.84, 0.9), vec3(1.0), n);
	}
	ALBEDO = renk;
	ALPHA = a * alfa;
}
"""

var _bulutlar: Array = []
var _alfa := 0.0
var _hedef := 0.0
var _kur_tamam := false
var _x0 := -400.0
var _x1 := 400.0
var _z0 := -600.0
var _z1 := 600.0

func _ready() -> void:
	top_level = true
	visible = false

func harita_siniri(x0: float, x1: float, z0: float, z1: float) -> void:
	_x0 = x0
	_x1 = x1
	_z0 = z0
	_z1 = z1

func goster(a: bool) -> void:
	_hedef = 1.0 if a else 0.0
	if a:
		if not _kur_tamam:
			_olustur()
		visible = true

func _olustur() -> void:
	_kur_tamam = true
	var rng := RandomNumberGenerator.new()
	rng.seed = 1920
	var gur := FastNoiseLite.new()
	gur.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	gur.frequency = 0.012
	gur.fractal_octaves = 4
	var gtex := NoiseTexture2D.new()
	gtex.noise = gur
	gtex.width = 256
	gtex.height = 256
	gtex.seamless = true
	var imgeler: Array = []
	for k in range(1, 5):
		var yol := "res://assets/ui/bulut%d.png" % k
		if ResourceLoader.exists(yol):
			imgeler.append(load(yol))
	for n in ADET:
		var m := MeshInstance3D.new()
		var q := QuadMesh.new()
		var s := rng.randf_range(110.0, 230.0)
		q.size = Vector2(s, s * rng.randf_range(0.55, 0.8))
		q.orientation = PlaneMesh.FACE_Y
		m.mesh = q
		var mt := ShaderMaterial.new()
		var sh := Shader.new()
		sh.code = SH
		mt.shader = sh
		mt.set_shader_parameter("gurultu", gtex)
		mt.set_shader_parameter("tohum", rng.randf() * 5.0)
		if not imgeler.is_empty():
			mt.set_shader_parameter("imge", imgeler[n % imgeler.size()])
			mt.set_shader_parameter("imge_var", true)
		mt.render_priority = 5
		m.material_override = mt
		m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		m.position = Vector3(rng.randf_range(_x0, _x1), YUKSEKLIK + rng.randf_range(-25.0, 40.0), rng.randf_range(_z0, _z1))
		m.rotation.y = rng.randf() * TAU
		add_child(m)
		_bulutlar.append({"m": m, "mt": mt, "hiz": rng.randf_range(2.0, 6.0)})

func _process(_d: float) -> void:
	var dt := float(get_process_delta_time())
	# gerçek süre: oyun duraklasa da bulutlar akar
	dt = float(Time.get_ticks_usec() - _son) / 1000000.0 if _son > 0 else dt
	_son = Time.get_ticks_usec()
	_alfa = move_toward(_alfa, _hedef, dt * 0.8)
	if _alfa <= 0.0 and _hedef <= 0.0:
		visible = false
		return
	for b in _bulutlar:
		var m: MeshInstance3D = b["m"]
		m.position.x += b["hiz"] * dt
		if m.position.x > _x1 + 120.0:
			m.position.x = _x0 - 120.0
		(b["mt"] as ShaderMaterial).set_shader_parameter("alfa", _alfa * 0.62)

var _son := 0
