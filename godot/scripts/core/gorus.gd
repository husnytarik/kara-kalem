extends Node3D
# Savaş sisi + görüş alanı (fog of war / line of sight).
# Görüş kaynakları: sen, haritada yürüyen adamların, sahip olduğun ve haraçlı binalar.
# Binalar görüşü keser (yol ızgarasındaki katı hücreler). Üç durum: bilinmeyen (kara),
# keşfedilmiş ama şu an görünmeyen (soluk), şu an görünen (net).
# Görünen binalarda içerideki kişi sayısı ve gelen-gidenler kaydedilir.

const HUCRE := 2.0
const GUNCELLE := 0.25
const R_OYUNCU := 60.0
const R_ADAM := 42.0
const R_SAHIP := 38.0
const R_HARAC := 24.0
const IN_MESAFE := 7.0     # bina kutusuna bu kadar yaklaşan grup "girdi" sayılır
const LOG_MAX := 14

var harita: Node3D
var oyun: Node
var sokak: Node
var acik := true            # false: sis kapalı (hile / geliştirme, F tuşu)
var _w := 0
var _h := 0
var _x0 := 0.0
var _z0 := 0.0
var kesif := PackedByteArray()
var gorunen := PackedByteArray()
var _img: Image
var _tex: ImageTexture
var _mi: MeshInstance3D
var _sure := 0.0
var _bu_tur := {}
var _icerde := {}           # "grupid:bina" -> true

func kur(h: Node3D, o: Node, s: Node) -> void:
	harita = h
	oyun = o
	sokak = s
	var a: Node3D = h.get_node("Arazi")
	_x0 = a.x0
	_z0 = a.z0
	_w = int(ceil(a.genislik / HUCRE))
	_h = int(ceil(a.derinlik / HUCRE))
	kesif.resize(_w * _h)
	gorunen.resize(_w * _h)
	_img = Image.create(_w, _h, false, Image.FORMAT_RG8)
	_tex = ImageTexture.create_from_image(_img)
	var sh := Shader.new()
	sh.code = """
shader_type spatial;
render_mode unshaded, depth_test_disabled, cull_disabled, blend_mix;
uniform sampler2D depth_tex : hint_depth_texture, repeat_disable, filter_nearest;
uniform sampler2D sis : filter_linear, repeat_disable;
uniform vec4 alan;
void vertex() { POSITION = vec4(VERTEX.xy, 1.0, 1.0); }
void fragment() {
	float d = textureLod(depth_tex, SCREEN_UV, 0.0).r;
	if (d <= 0.00001) { ALPHA = 0.0; ALBEDO = vec3(0.0); }
	else {
		vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, d);
		vec4 v = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
		v.xyz /= v.w;
		vec3 w = (INV_VIEW_MATRIX * vec4(v.xyz, 1.0)).xyz;
		vec2 uv = (w.xz - alan.xy) / alan.zw;
		vec2 f = texture(sis, uv).rg;
		float dis = (uv.x < 0.0 || uv.y < 0.0 || uv.x > 1.0 || uv.y > 1.0) ? 1.0 : 0.0;
		float bilinmeyen = max(1.0 - f.r, dis);
		float soluk = 1.0 - f.g;
		float a = mix(0.0, 0.5, soluk);
		a = mix(a, 0.96, bilinmeyen);
		ALBEDO = mix(vec3(0.02, 0.03, 0.06), vec3(0.0, 0.0, 0.02), bilinmeyen);
		ALPHA = a;
	}
}
"""
	var m := ShaderMaterial.new()
	m.shader = sh
	m.set_shader_parameter("sis", _tex)
	m.set_shader_parameter("alan", Vector4(_x0, _z0, a.genislik, a.derinlik))
	var q := QuadMesh.new()
	q.size = Vector2(2, 2)
	q.material = m
	_mi = MeshInstance3D.new()
	_mi.mesh = q
	_mi.extra_cull_margin = 16384.0
	_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mi)
	guncelle()

# ---------- sorgular ----------
func _idx(p: Vector3) -> int:
	var x := int(floor((p.x - _x0) / HUCRE))
	var z := int(floor((p.z - _z0) / HUCRE))
	if x < 0 or z < 0 or x >= _w or z >= _h:
		return -1
	return z * _w + x

func gorunur(p: Vector3) -> bool:
	if not acik:
		return true
	var k := _idx(p)
	return k >= 0 and gorunen[k] == 1

func kesfedildi(p: Vector3) -> bool:
	if not acik:
		return true
	var k := _idx(p)
	return k >= 0 and kesif[k] == 1

# Bina görünür mü: kutusunun kenarındaki herhangi bir hücre görünüyorsa.
func bina_gorunur(i: int) -> bool:
	return _bina_durum(i, gorunen)

func bina_kesfedildi(i: int) -> bool:
	return _bina_durum(i, kesif)

func _bina_durum(i: int, dizi: PackedByteArray) -> bool:
	if not acik:
		return true
	var a: AABB = harita.yerler[i]["aabb"]
	var x := a.position.x - 1.5
	while x <= a.end.x + 1.5:
		var z := a.position.z - 1.5
		while z <= a.end.z + 1.5:
			var k := _idx(Vector3(x, 0, z))
			if k >= 0 and dizi[k] == 1:
				return true
			z += HUCRE
		x += HUCRE
	return false

# ---------- görüş hesabı ----------
func _kaynaklar() -> Array:
	var s: Array = []   # [pos, yaricap, aabb|null]
	s.append([sokak.oyuncu.global_position, R_OYUNCU, null])
	for aid in sokak._adam_gorsel:
		s.append([(sokak._adam_gorsel[aid] as Node3D).global_position, R_ADAM, null])
	for i in oyun.isy:
		var r: Dictionary = oyun.isy[i]
		if r["sahip"] or r["haracli"]:
			var y: Dictionary = harita.yerler[i]
			s.append([y["pos"], R_SAHIP if r["sahip"] else R_HARAC, y["aabb"]])
	return s

func guncelle() -> void:
	gorunen.fill(0)
	_bu_tur.clear()
	for k in _kaynaklar():
		_isin_yay(k[0], k[1], k[2])
	var d := PackedByteArray()
	d.resize(_w * _h * 2)
	for n in _w * _h:
		if gorunen[n] == 1:
			kesif[n] = 1
		d[n * 2] = 255 if kesif[n] == 1 else 0
		d[n * 2 + 1] = 255 if gorunen[n] == 1 else 0
	_img.set_data(_w, _h, false, Image.FORMAT_RG8, d)
	_tex.update(_img)
	_mi.visible = acik

func _isaretle(p: Vector3) -> void:
	var k := _idx(p)
	if k >= 0:
		gorunen[k] = 1

# Görüş bir binanın duvarına çarptıysa binanın tamamı (cephe + çatı) görünür sayılır.
func _bina_isaretle(p: Vector3) -> void:
	for i in harita.yerler.size():
		var a: AABB = harita.yerler[i]["aabb"]
		if p.x >= a.position.x - 2.0 and p.x <= a.end.x + 2.0 and p.z >= a.position.z - 2.0 and p.z <= a.end.z + 2.0:
			if _bu_tur.has(i):
				return
			_bu_tur[i] = true
			var x := a.position.x
			while x <= a.end.x + HUCRE:
				var z := a.position.z
				while z <= a.end.z + HUCRE:
					_isaretle(Vector3(x, 0, z))
					z += HUCRE
				x += HUCRE
			return

func _isin_yay(o: Vector3, yar: float, ic) -> void:
	var rect := Rect2()
	var ic_var := ic != null
	if ic_var:
		var a: AABB = ic
		rect = Rect2(a.position.x - 1.0, a.position.z - 1.0, a.size.x + 2.0, a.size.z + 2.0)
		# binanın içi/duvarları görünür
		var x: float = rect.position.x
		while x <= rect.end.x:
			var z: float = rect.position.y
			while z <= rect.end.y:
				_isaretle(Vector3(x, 0, z))
				z += HUCRE
			x += HUCRE
	var n_ray := 144
	var adim := 1.5
	for r in n_ray:
		var ang := TAU * r / n_ray
		var dir := Vector3(cos(ang), 0, sin(ang))
		var d := 0.0
		while d <= yar:
			var p := o + dir * d
			_isaretle(p)
			var disarida := not ic_var or not rect.has_point(Vector2(p.x, p.z))
			if disarida and harita.engelli(p):
				_bina_isaretle(p)
				break
			d += adim

# ---------- zaman içinde ----------
func _process(delta: float) -> void:
	_sure += delta
	if _sure < GUNCELLE:
		return
	_sure = 0.0
	guncelle()
	_gorunurluk()
	_hareket_kaydi()

func _gorunurluk() -> void:
	for g in sokak.gruplar.liste:
		(g["dugum"] as Node3D).visible = gorunur(g["pos"])
	for n in get_tree().get_nodes_in_group("bina"):
		if n._etiket != null:
			n._etiket.visible = kesfedildi(n.global_position)

func _hareket_kaydi() -> void:
	for i in oyun.harita.yerler.size():
		var y: Dictionary = harita.yerler[i]
		if y["ozel"] and not oyun.isy.has(i):
			continue
		var gor := bina_gorunur(i)
		var ab: AABB = (y["aabb"] as AABB).grow(IN_MESAFE)
		for g in sokak.gruplar.liste:
			var key := "%d:%d" % [g["id"], i]
			var p: Vector3 = g["pos"]
			var icerde := ab.has_point(Vector3(p.x, ab.position.y + ab.size.y * 0.5, p.z))
			if icerde and not _icerde.has(key):
				_icerde[key] = true
				if gor:
					_log(i, g, "geldi")
			elif not icerde and _icerde.has(key):
				_icerde.erase(key)
				if gor:
					_log(i, g, "ayrıldı")
		if gor:
			oyun.gozlem[i] = {"t": oyun.t, "n": nufus(i)["toplam"]}

func _log(i: int, g: Dictionary, ne: String) -> void:
	if not oyun.ziyaret.has(i):
		oyun.ziyaret[i] = []
	var l: Array = oyun.ziyaret[i]
	l.append({"t": oyun.t, "ad": g["ad"], "tur": g["tur"], "kisi": g["kisi"], "ne": ne, "fak": g["fak"]})
	if l.size() > LOG_MAX:
		l.pop_front()

# ---------- bina doluluğu ----------
const TUR_TABAN := {"esnaf": 7, "eglence": 16, "luks": 9, "atolye": 5, "depo": 3, "konut": 9, "resmi": 6}

# Saat eğrisi: esnaf/atölye gündüz, eğlence akşam-gece, konut gece.
func _saat_etki(tur: String, saat: float) -> float:
	match tur:
		"eglence":
			if saat >= 18.0 or saat < 3.0:
				return 1.0
			return 0.4 if (saat >= 12.0 and saat < 18.0) else 0.1
		"konut":
			return 1.0 if (saat >= 21.0 or saat < 7.0) else 0.45
		"depo":
			return 0.9 if (saat >= 7.0 and saat < 18.0) else 0.15
	return 1.0 if (saat >= 8.0 and saat < 19.0) else 0.12

func nufus(i: int) -> Dictionary:
	var r: Dictionary = oyun.isy.get(i, {})
	var tur: String = r.get("tur", "resmi")
	var saat: float = (oyun.t % oyun.DAY) / 60.0
	var h: int = hash(Vector2i(i, oyun.t / 60))
	var oynama := 0.8 + float(h % 41) / 100.0   # 0.8-1.2, saatte bir değişir
	var calisan := 2
	var musteri_k := float(TUR_TABAN[tur]) * _saat_etki(tur, saat) * oynama
	if r.has("personel"):
		calisan = r["personel"].size()
		if r["sahip"]:
			musteri_k *= 0.5 + oyun.isl.carpan(i) * 0.7
	var musteri := int(round(musteri_k))
	var yabanci := 0
	var ab: AABB = (harita.yerler[i]["aabb"] as AABB).grow(IN_MESAFE)
	for g in sokak.gruplar.liste:
		var p: Vector3 = g["pos"]
		if g["tur"] != "sivil" and ab.has_point(Vector3(p.x, ab.position.y + ab.size.y * 0.5, p.z)):
			yabanci += g["kisi"]
	return {"toplam": calisan + musteri + yabanci, "calisan": calisan, "musteri": musteri, "yabanci": yabanci}

# ---------- kayıt ----------
func durum_al() -> Dictionary:
	return {"kesif": kesif}

func durum_yukle(d: Dictionary) -> void:
	if d.has("kesif") and d["kesif"].size() == kesif.size():
		kesif = d["kesif"]
	guncelle()
