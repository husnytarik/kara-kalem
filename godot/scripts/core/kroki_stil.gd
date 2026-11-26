extends MeshInstance3D
# Kroki stili: kalem çizgisi + sulu boya yıkaması (tam ekran spatial son işlem; kameranın çocuğu).
# Çizgi titreşimi dünya konumuna bağlı: kamera kayınca çizgiler ekranda "yüzmez".

const SHADER := """
shader_type spatial;
render_mode unshaded, fog_disabled, depth_test_disabled, cull_disabled, shadows_disabled;
uniform sampler2D tex : hint_screen_texture, repeat_disable, filter_linear;
uniform float kalinlik = 1.5;
uniform float d_esik = 0.012;
uniform float r_esik = 0.18;
uniform float koyuluk = 0.92;
uniform float tane_g = 0.22;
uniform sampler2D dep : hint_depth_texture, repeat_disable, filter_nearest;

float h21(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float vn(vec2 p){ vec2 i = floor(p), f = fract(p); f = f*f*(3.0-2.0*f);
	return mix(mix(h21(i), h21(i+vec2(1,0)), f.x), mix(h21(i+vec2(0,1)), h21(i+vec2(1,1)), f.x), f.y); }

vec3 dunya(vec2 uv, mat4 ip, mat4 iv, out float lin){
	float d = texture(dep, uv).x;
	vec4 v = ip * vec4(uv * 2.0 - 1.0, d, 1.0);
	v.xyz /= v.w;
	lin = -v.z;
	return (iv * vec4(v.xyz, 1.0)).xyz;
}

void vertex(){ POSITION = vec4(VERTEX.xy, 1.0, 1.0); }

float kenar(vec2 uv, vec2 px, float lin0, mat4 ip, mat4 iv){
	float r = kalinlik;   // sabit piksel kalınlığı
	float l1, l2, l3, l4;
	dunya(uv + vec2(r, 0) * px, ip, iv, l1);
	dunya(uv - vec2(r, 0) * px, ip, iv, l2);
	dunya(uv + vec2(0, r) * px, ip, iv, l3);
	dunya(uv - vec2(0, r) * px, ip, iv, l4);
	float de = (abs(l1 - l2) + abs(l3 - l4)) / max(lin0, 1.0);
	float k = smoothstep(d_esik * 0.35, d_esik * 2.0, de);
	vec3 a = texture(tex, uv + vec2(r, 0) * px).rgb, b = texture(tex, uv - vec2(r, 0) * px).rgb;
	vec3 e = texture(tex, uv + vec2(0, r) * px).rgb, f = texture(tex, uv - vec2(0, r) * px).rgb;
	return max(k, smoothstep(r_esik * 0.55, r_esik * 1.5, length(a - b) + length(e - f)) * 0.8);
}

void fragment(){
	vec2 px = 1.0 / vec2(textureSize(tex, 0));
	vec2 uv = SCREEN_UV;
	vec3 c = texture(tex, uv).rgb;
	// 5 örnek ortalaması: çizgi kenarları yumuşak (anti-alias), kömür gibi hafif yayılır
	float cz = 0.0;
	vec2 o[5] = vec2[](vec2(0.0), vec2(0.7, 0.7), vec2(-0.7, 0.7), vec2(0.7, -0.7), vec2(-0.7, -0.7));
	for (int i = 0; i < 5; i++) {
		vec2 u = uv + o[i] * px;
		float l0;
		dunya(u, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX, l0);
		cz += kenar(u, px, l0, INV_PROJECTION_MATRIX, INV_VIEW_MATRIX) * (i == 0 ? 0.4 : 0.15);
	}
	// kömür tanesi: ince kâğıt greni çizgiyi hafif kırar
	vec2 gp = uv / px;
	float tane = fract(sin(dot(floor(gp), vec2(12.9898, 78.233))) * 43758.5453);
	cz *= (1.0 - tane_g) + tane_g * tane;
	vec3 komur = vec3(0.02, 0.018, 0.017);
	ALBEDO = mix(c, komur, clamp(cz * 1.15, 0.0, koyuluk));
}
"""

func kur() -> void:
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	var m := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = SHADER
	m.shader = sh
	m.render_priority = 100
	q.material = m
	mesh = q
	extra_cull_margin = 16384.0
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	position = Vector3(0, 0, -1)
	visible = false

func ayarla(e: Dictionary) -> void:
	var m := (mesh as QuadMesh).material as ShaderMaterial
	m.set_shader_parameter("kalinlik", e["kalinlik"])
	m.set_shader_parameter("d_esik", e["d_esik"])
	m.set_shader_parameter("r_esik", e["r_esik"])
	m.set_shader_parameter("koyuluk", e["koyuluk"])
	m.set_shader_parameter("tane_g", e["tane"])
