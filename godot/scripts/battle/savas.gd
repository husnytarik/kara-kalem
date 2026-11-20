extends Node3D
# 3. şahıs (TPS) savaş yöneticisi. Seviyeyi kurar, birimleri doğurur, kamera/girdi/HUD'u yönetir.
# Çağıran: sokak.gd -> savas_baslat(). Bittiğinde `bitti(sonuc)` sinyali verir:
#   sonuc = {sonuc: "zafer"|"yenilgi"|"kacis", dusman_olu, dusman_kalan, adam_olu: [id,...]}
# Veri sözlüğü:
#   tur, sahne, oyuncu_takimi: [{ad, silah, hp, isabet, id, oyuncu}], dusman_takimi: [{ad, silah, hp, isabet}],
#   dusman_ad, dusman_renk, dezavantaj (oyuncu başlangıç canı çarpanı, 1.0 = normal)

signal bitti(sonuc: Dictionary)

const BIRIM := preload("res://scripts/battle/savas_birim.gd")
const SEVIYE := preload("res://scripts/battle/savas_seviye.gd")
const ORIJIN := Vector3(5000, 0, 0)   # dünya haritasından uzak kur, fizik çakışmasın
const HAS := 0.0024

var oyun: Node
var veri: Dictionary
var durakladi := false
var birimler: Array = []
var oyuncu: CharacterBody3D
var otopilot := false

var _seviye: Node3D
var _pivot: Node3D
var _yay: SpringArm3D
var _kam: Camera3D
var _yaw := 0.0
var _pitch := -0.15
var _bitis := false
var _bitis_t := 0.0
var _bitis_yazi := ""
var _bitis_sonuc := ""
var _hud: CanvasLayer
var _l_sol: Label
var _l_silah: Label
var _l_orta: Label
var _hp_bar: ProgressBar
var _menu: PanelContainer
var _vurus_t := 0.0

func baslat(o: Node, v: Dictionary, oto: bool = false) -> void:
	oyun = o
	veri = v
	otopilot = oto
	_seviye = SEVIYE.kur(v["tur"], v.get("sahne", ""))
	add_child(_seviye)
	_seviye.global_position = ORIJIN
	_birimleri_kur()
	_kamera_kur()
	_hud_kur()
	if not otopilot:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _spawnlar(grup: String) -> Array:
	var r: Array = []
	for n in get_tree().get_nodes_in_group(grup):
		if _seviye.is_ancestor_of(n):
			r.append((n as Node3D).global_position)
	if r.is_empty():
		r.append(ORIJIN + Vector3(-10 if grup == "spawn_oyuncu" else 10, 1, 0))
	return r

func _birimleri_kur() -> void:
	var sp_o := _spawnlar("spawn_oyuncu")
	var sp_d := _spawnlar("spawn_dusman")
	var i := 0
	for u in veri["oyuncu_takimi"]:
		var renk := Color(0.3, 0.55, 0.9)
		if u.get("oyuncu", false):
			renk = Color(0.9, 0.7, 0.25)
		var b := _birim_yap(u, 0, renk, sp_o[i % sp_o.size()] + Vector3(0, 0.1, 0))
		if u.get("oyuncu", false):
			b.hp = b.hp_max * float(veri.get("dezavantaj", 1.0))
			oyuncu = b
			b.oto = otopilot
		i += 1
	i = 0
	for u in veri["dusman_takimi"]:
		_birim_yap(u, 1, veri["dusman_renk"], sp_d[i % sp_d.size()] + Vector3(0, 0.1, 0))
		i += 1

func _birim_yap(u: Dictionary, takim: int, renk: Color, poz: Vector3) -> CharacterBody3D:
	var b: CharacterBody3D = BIRIM.new()
	var d: Dictionary = u.duplicate()
	d["takim"] = takim
	d["renk"] = renk
	add_child(b)
	b.kur(self, d, poz)
	birimler.append(b)
	return b

func _kamera_kur() -> void:
	_pivot = Node3D.new()
	add_child(_pivot)
	_yay = SpringArm3D.new()
	_yay.spring_length = 3.4
	_yay.collision_mask = 1
	_yay.margin = 0.3
	_pivot.add_child(_yay)
	_kam = Camera3D.new()
	_kam.fov = 70.0
	_kam.h_offset = 0.7
	_yay.add_child(_kam)
	_kam.make_current()
	_yaw = -PI / 2.0   # dünya +X yönüne (düşmana) bak
	_pivot.global_position = oyuncu.global_position + Vector3(0, 1.6, 0)

func _hud_kur() -> void:
	_hud = CanvasLayer.new()
	_hud.layer = 20
	add_child(_hud)
	_l_sol = _etiket(Vector2(20, 14), 20)
	_l_orta = _etiket(Vector2(0, 280), 44)
	_l_orta.size = Vector2(1280, 80)
	_l_orta.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_l_silah = _etiket(Vector2(20, 640), 20)
	_hp_bar = ProgressBar.new()
	_hp_bar.position = Vector2(20, 672)
	_hp_bar.size = Vector2(300, 18)
	_hp_bar.show_percentage = false
	_hud.add_child(_hp_bar)
	var nis := _etiket(Vector2(632, 350), 28)
	nis.text = "+"
	var ipucu := _etiket(Vector2(20, 40), 14)
	ipucu.text = "WASD: hareket · Shift: koş · Fare: nişan · Sol tık: ateş · R: doldur · Esc: menü"
	ipucu.modulate = Color(1, 1, 1, 0.6)
	_menu = PanelContainer.new()
	_menu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_menu.custom_minimum_size = Vector2(300, 0)
	_menu.visible = false
	var vb := VBoxContainer.new()
	_menu.add_child(vb)
	var b1 := Button.new()
	b1.text = "Devam"
	b1.pressed.connect(_menu_ac.bind(false))
	vb.add_child(b1)
	var b2 := Button.new()
	b2.text = "Geri çekil (kaç)"
	b2.pressed.connect(_bitir.bind("kacis"))
	vb.add_child(b2)
	_hud.add_child(_menu)

func _etiket(poz: Vector2, boyut: int) -> Label:
	var l := Label.new()
	l.position = poz
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 8)
	_hud.add_child(l)
	return l

# ---------- yardımcılar (birimler çağırır) ----------
func en_yakin(b: CharacterBody3D) -> CharacterBody3D:
	var en: CharacterBody3D = null
	var en_uz := 1e12
	for x in birimler:
		if x.olu or x.takim == b.takim:
			continue
		var d: float = b.global_position.distance_squared_to(x.global_position)
		if d < en_uz:
			en_uz = d
			en = x
	return en

func gorus_var(a: Vector3, b: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(a, b, 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func iz_ciz(a: Vector3, b: Vector3) -> void:
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_add_vertex(a)
	im.surface_add_vertex(b)
	im.surface_end()
	mi.mesh = im
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = Color(1.0, 0.9, 0.5)
	mi.material_override = m
	mi.top_level = true
	add_child(mi)
	get_tree().create_timer(0.06).timeout.connect(mi.queue_free)

func vurus_bildir() -> void:
	_vurus_t = 0.15

func _say(takim: int) -> Array:
	var canli := 0
	var toplam := 0
	for x in birimler:
		if x.takim == takim:
			toplam += 1
			if not x.olu:
				canli += 1
	return [canli, toplam]

# ---------- girdi ----------
func _input(e: InputEvent) -> void:
	if otopilot or _bitis:
		return
	if e is InputEventMouseMotion and not durakladi:
		_yaw -= e.relative.x * HAS
		_pitch = clampf(_pitch - e.relative.y * HAS, -1.2, 0.9)
	elif e is InputEventKey and e.pressed and not e.echo:
		if e.keycode == KEY_ESCAPE:
			_menu_ac(not durakladi)
		elif e.keycode == KEY_R and not durakladi:
			oyuncu.yeniden_doldur()

func _menu_ac(ac: bool) -> void:
	durakladi = ac
	_menu.visible = ac
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if ac else Input.MOUSE_MODE_CAPTURED

func _physics_process(_dt: float) -> void:
	if durakladi or _bitis or otopilot or oyuncu.olu:
		return
	var x := float(Input.is_key_pressed(KEY_D)) - float(Input.is_key_pressed(KEY_A))
	var z := float(Input.is_key_pressed(KEY_S)) - float(Input.is_key_pressed(KEY_W))
	var yerel := Vector3(x, 0, z).normalized()
	oyuncu.girdi_yon = Basis(Vector3.UP, _yaw) * yerel
	oyuncu.kos = Input.is_key_pressed(KEY_SHIFT)
	oyuncu.bakis = _yaw
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		oyuncu.oyuncu_ates(_kam.global_position, -_kam.global_transform.basis.z)

func _process(dt: float) -> void:
	var hedef_poz: Vector3 = oyuncu.global_position
	if oyuncu.olu:
		for x in birimler:
			if x.takim == 0 and not x.olu:
				hedef_poz = x.global_position
				break
	elif otopilot:
		_yaw = lerp_angle(_yaw, oyuncu.bakis, 4.0 * dt)
	_pivot.global_position = hedef_poz + Vector3(0, 1.6, 0)
	_pivot.rotation = Vector3(_pitch, _yaw, 0)
	var s0 := _say(0)
	var s1 := _say(1)
	_l_sol.text = "Senin taraf: %d/%d     Düşman (%s): %d/%d" % [s0[0], s0[1], veri["dusman_ad"], s1[0], s1[1]]
	var sd: Dictionary = oyuncu.sd
	var mermi_yazi := "—"
	if sd["sarjor"] > 0:
		mermi_yazi = "%d/%d" % [oyuncu.mermi, sd["sarjor"]]
		if oyuncu.yeniden_durumu() > 0.0:
			mermi_yazi += "  (dolduruluyor)"
	_l_silah.text = "%s   Mermi: %s" % [sd["ad"], mermi_yazi]
	_hp_bar.max_value = oyuncu.hp_max
	_hp_bar.value = oyuncu.hp
	_vurus_t = maxf(0.0, _vurus_t - dt)
	if _bitis:
		_bitis_t -= dt
		_l_orta.text = _bitis_yazi
		if _bitis_t <= 0.0:
			_son_ver()
		return
	if s1[0] == 0:
		_bitis_baslat("ZAFER", "zafer", 1.8)
	elif oyuncu.olu:
		_bitis_baslat("YENİLGİ", "yenilgi", 2.2)

func _bitis_baslat(yazi: String, sonuc: String, sure: float) -> void:
	_bitis_yazi = yazi
	_bitis_sonuc = sonuc
	_bitis_t = sure
	_bitis = true

func _bitir(nasil: String) -> void:
	_menu_ac(false)
	_bitis_baslat("GERİ ÇEKİLDİN", nasil, 0.8)

func _son_ver() -> void:
	set_process(false)
	set_physics_process(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var olu_adam: Array = []
	for x in birimler:
		if x.takim == 0 and x.olu and x.kimlik != 0:
			olu_adam.append(x.kimlik)
	var s1 := _say(1)
	var lider_olu := false
	var mk := 0
	var ak := 0
	var ol := 0
	for x in birimler:
		if x.oyuncu_mu:
			mk = x.mermi_kullanilan
			ak = x.atis_say
			ol = x.oldurme
	for x in birimler:
		if x.takim == 1 and x.lider and x.olu:
			lider_olu = true
	bitti.emit({"sonuc": _bitis_sonuc, "dusman_olu": s1[1] - s1[0], "dusman_kalan": s1[0], "adam_olu": olu_adam, "lider_olu": lider_olu, "mermi_kullanilan": mk, "oyuncu_atis": ak, "oyuncu_oldurme": ol})
