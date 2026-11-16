extends CharacterBody3D
# Savaştaki tek bir kişi. Oyuncu girdiyle, diğerleri yapay zekâyla yönetilir.
# Silah verisi oyun.SILAH'tan gelir (hasar, menzil, atış hızı, şarjör...).

signal oldu(b: CharacterBody3D)

const YER := 9.8

var savas: Node3D
var takim := 0               # 0: senin taraf, 1: düşman
var ad := ""
var kimlik := 0              # oyun.adamlar id (oyuncu ve düşmanda 0)
var silah_id := "yumruk"
var sd: Dictionary = {}
var hp := 100.0
var hp_max := 100.0
var isabet := 0.5            # yapay zekâ nişan başarısı (0-1)
var lider := false           # düşman ekibin lideri (aile üyesi)
var oyuncu_mu := false
var oto := true              # true: yapay zekâ yönetir
var renk := Color.WHITE
var mermi := 0
var olu := false
var hedef: CharacterBody3D = null
var girdi_yon := Vector3.ZERO
var kos := false
var bakis := 0.0
var hiz_yuru := 4.5

var _atis := 0.0
var _yeniden := 0.0
var _hedef_ara := 0.0
var _gorus_t := 0.0
var _gorus := false
var _strafe_t := 0.0
var _strafe := 0.0
var _sikis := 0.0
var _kac := 1.0
var _govde: Node3D
var _mat: StandardMaterial3D
var _etiket: Label3D
var _flas := 0.0

func kur(s: Node3D, v: Dictionary, poz: Vector3) -> void:
	savas = s
	takim = v["takim"]
	ad = v["ad"]
	kimlik = v.get("id", 0)
	silah_id = v["silah"]
	sd = savas.oyun.SILAH[silah_id]
	hp_max = v["hp"]
	hp = hp_max
	isabet = v.get("isabet", 0.5)
	lider = v.get("lider", false)
	oyuncu_mu = v.get("oyuncu", false)
	oto = not oyuncu_mu
	renk = v["renk"]
	mermi = sd["sarjor"]
	collision_layer = 2
	collision_mask = 1 | 2
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	_govde = Node3D.new()
	add_child(_govde)
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = renk
	cm.material = _mat
	mi.mesh = cm
	mi.position.y = 0.9
	_govde.add_child(mi)
	var silah_mesh := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.12, 0.14, 0.7 if sd["menzil"] > 5.0 else 0.35)
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.1, 0.1, 0.1)
	bm.material = sm
	silah_mesh.mesh = bm
	silah_mesh.position = Vector3(0.3, 1.2, -0.45)
	_govde.add_child(silah_mesh)
	_etiket = Label3D.new()
	_etiket.text = ad
	_etiket.font_size = 36
	_etiket.pixel_size = 0.005
	_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiket.no_depth_test = true
	_etiket.outline_size = 8
	_etiket.position.y = 2.3
	_etiket.modulate = renk.lerp(Color.WHITE, 0.5)
	if lider:
		_etiket.pixel_size = 0.008
		_etiket.modulate = Color(1.0, 0.8, 0.3)
		_mi_olcek(mi)
	add_child(_etiket)
	global_position = poz
	_atis = randf_range(0.2, 1.2)
	hiz_yuru = 4.2 + randf() * 0.8

func _mi_olcek(mi: MeshInstance3D) -> void:
	mi.scale = Vector3(1.15, 1.05, 1.15)   # liderler biraz iri görünür

func goz() -> Vector3:
	return global_position + Vector3(0, 1.5, 0)

func govde_merkez() -> Vector3:
	return global_position + Vector3(0, 1.1, 0)

func _physics_process(dt: float) -> void:
	if olu or savas.durakladi:
		return
	_atis = maxf(0.0, _atis - dt)
	if _yeniden > 0.0:
		_yeniden -= dt
		if _yeniden <= 0.0:
			mermi = sd["sarjor"]
	if _flas > 0.0:
		_flas -= dt
		if _flas <= 0.0:
			_mat.albedo_color = renk
	if oyuncu_mu and not oto:
		_hareket(girdi_yon, 7.5 if kos else 5.0, dt)
		_govde.rotation.y = lerp_angle(_govde.rotation.y, bakis + PI, 14.0 * dt)
	else:
		_ai(dt)

func _hareket(yon: Vector3, hiz: float, dt: float) -> void:
	velocity.x = yon.x * hiz
	velocity.z = yon.z * hiz
	if is_on_floor():
		velocity.y = 0.0
	else:
		velocity.y -= YER * dt
	move_and_slide()

# ---------- yapay zekâ ----------
func _ai(dt: float) -> void:
	_hedef_ara -= dt
	if _hedef_ara <= 0.0 or hedef == null or hedef.olu:
		_hedef_ara = 0.6 + randf() * 0.4
		hedef = savas.en_yakin(self)
	if hedef == null:
		_hareket(Vector3.ZERO, 0.0, dt)
		return
	var fark := hedef.global_position - global_position
	fark.y = 0.0
	var d := fark.length()
	var yon := fark / maxf(d, 0.01)
	_gorus_t -= dt
	if _gorus_t <= 0.0:
		_gorus_t = 0.2
		_gorus = savas.gorus_var(goz(), hedef.goz())
	var menzil: float = sd["menzil"]
	var ideal: float = menzil * (0.55 if menzil > 5.0 else 0.8)
	var hareket := Vector3.ZERO
	if d > ideal or not _gorus:
		hareket = yon
	elif d < ideal * 0.45 and menzil > 5.0:
		hareket = -yon * 0.6
	else:
		_strafe_t -= dt
		if _strafe_t <= 0.0:
			_strafe_t = randf_range(0.8, 2.0)
			_strafe = [-1.0, 0.0, 1.0][randi() % 3]
		hareket = yon.cross(Vector3.UP) * _strafe * 0.6
	if menzil <= 3.0 and d <= menzil * 0.9:
		hareket = Vector3.ZERO
	if hareket.length() > 0.1 and get_real_velocity().length() < 0.7:
		_sikis += dt
	else:
		_sikis = 0.0
	if _sikis > 0.5:
		hareket = yon.cross(Vector3.UP) * _kac
		if _sikis > 1.4:
			_sikis = 0.0
			_kac = -_kac
	_hareket(hareket, hiz_yuru, dt)
	bakis = atan2(-yon.x, -yon.z)
	_govde.rotation.y = lerp_angle(_govde.rotation.y, bakis + PI, 12.0 * dt)
	if _gorus and d <= menzil:
		_ates_ai(d)

func _ates_ai(d: float) -> void:
	if _atis > 0.0 or _yeniden > 0.0:
		return
	if sd["sarjor"] > 0:
		if mermi <= 0:
			_yeniden = sd["yenileme"]
			return
		mermi -= 1
	_atis = 1.0 / sd["hiz"]
	var menzil: float = sd["menzil"]
	var p: float = isabet * 1.2
	if menzil > 3.0:
		p = isabet * clampf(1.0 - d / (menzil * 1.4), 0.15, 1.0)
	var vurdu := randf() < p
	if sd["sarjor"] > 0:
		var son: Vector3 = hedef.govde_merkez()
		if not vurdu:
			son += Vector3(randf_range(-1.2, 1.2), randf_range(-0.8, 0.8), randf_range(-1.2, 1.2))
		savas.iz_ciz(goz() + Vector3(0, -0.2, 0), son)
	if vurdu:
		for k in int(sd["pelet"]):
			hedef.hasar(sd["hasar"] * randf_range(0.8, 1.2), self)

# ---------- oyuncu ateşi (gerçek ışın) ----------
func oyuncu_ates(kaynak: Vector3, yon: Vector3) -> bool:
	if olu or _atis > 0.0 or _yeniden > 0.0:
		return false
	if sd["sarjor"] > 0:
		if mermi <= 0:
			yeniden_doldur()
			return false
		mermi -= 1
	_atis = 1.0 / sd["hiz"]
	var menzil: float = sd["menzil"]
	var vurus := false
	for k in int(sd["pelet"]):
		var y := yon
		var s: float = sd["sacilma"]
		if s > 0.0:
			y = (yon + Vector3(randf_range(-s, s), randf_range(-s, s), randf_range(-s, s))).normalized()
		var uzun: float = menzil if menzil > 3.0 else menzil + 1.0
		var q := PhysicsRayQueryParameters3D.create(kaynak, kaynak + y * (uzun + 3.5), 1 | 2, [get_rid()])
		var r := get_world_3d().direct_space_state.intersect_ray(q)
		var son: Vector3 = kaynak + y * minf(uzun, 60.0)
		if not r.is_empty():
			son = r["position"]
		if sd["sarjor"] > 0:
			savas.iz_ciz(goz() + Vector3(0, -0.2, 0), son)
		if not r.is_empty() and r["collider"].has_method("hasar") and r["collider"].takim != takim:
			var mesafe: float = global_position.distance_to(son)
			if mesafe <= menzil * 1.05:
				r["collider"].hasar(sd["hasar"] * randf_range(0.9, 1.1), self)
				vurus = true
	if vurus:
		savas.vurus_bildir()
	return true

func yeniden_doldur() -> void:
	if sd["sarjor"] > 0 and _yeniden <= 0.0 and mermi < sd["sarjor"]:
		_yeniden = sd["yenileme"]

func yeniden_durumu() -> float:
	return _yeniden

# ---------- hasar ----------
func hasar(d: float, _kaynak: Node = null) -> void:
	if olu:
		return
	hp -= d
	_mat.albedo_color = Color.WHITE
	_flas = 0.08
	if hp <= 0.0:
		hp = 0.0
		olu = true
		collision_layer = 0
		_govde.rotation.x = deg_to_rad(80)
		_govde.position.y = 0.3
		_etiket.modulate = Color(0.5, 0.5, 0.5)
		oldu.emit(self)
