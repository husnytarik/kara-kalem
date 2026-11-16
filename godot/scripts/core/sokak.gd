extends Node3D
# Ana sahne: haritayı, oyun kurallarını (oyun.gd) ve 2D arayüzü (arayuz.gd) bir araya getirir.
# Sol tık: git (binaya tıklarsan paneli de açılır). Boşluk: duraklat. 1/2/3: hız. B: bölge. A: adamlar. D: defter.

var harita: Node3D
var oyun: Node
var arayuz: CanvasLayer
var oyuncu: Node3D
var gruplar: Node3D
var _oy_etiket: Label3D
var kamera: Node3D
var _etiket: Label
var _ipucu: Label
var _hiz := 1.0
var _hud_kok: CanvasLayer
var takip_id := 0
var _takip_sure := 0.0
var _onceki_hiz := 1.0
var _adam_gorsel := {}   # adam id -> Node3D (haritada yürüyen adam)

func _ready() -> void:
	_cevre()
	harita = load("res://scenes/city/harita.tscn").instantiate()
	add_child(harita)
	oyun = load("res://scripts/core/oyun.gd").new()
	oyun.name = "Oyun"
	add_child(oyun)
	oyun.kur(harita)
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
	_oy_etiket = Label3D.new()
	_oy_etiket.font_size = 40
	_oy_etiket.pixel_size = 0.07
	_oy_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_oy_etiket.no_depth_test = true
	_oy_etiket.outline_size = 12
	_oy_etiket.modulate = Color(1.0, 0.85, 0.4)
	_oy_etiket.position.y = 12.0
	oyuncu.add_child(_oy_etiket)
	gruplar = load("res://scripts/core/gruplar.gd").new()
	gruplar.name = "Gruplar"
	add_child(gruplar)
	gruplar.kur(harita, oyun, oyuncu)
	gruplar.yakinlasti.connect(_karsilasti)
	gruplar.temas.connect(func(g): arayuz.karsilasma_ac(g))
	arayuz = load("res://scripts/ui/arayuz.gd").new()
	add_child(arayuz)
	arayuz.kur(oyun, self)
	var hud := CanvasLayer.new()
	_hud_kok = hud
	_etiket = Label.new()
	_etiket.position = Vector2(20, 100)
	_etiket.add_theme_font_size_override("font_size", 22)
	_etiket.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiket.add_theme_constant_override("outline_size", 8)
	hud.add_child(_etiket)
	_ipucu = Label.new()
	_ipucu.position = Vector2(20, 132)
	_ipucu.add_theme_font_size_override("font_size", 20)
	_ipucu.add_theme_color_override("font_outline_color", Color.BLACK)
	_ipucu.add_theme_constant_override("outline_size", 8)
	_ipucu.modulate = Color(1.0, 0.85, 0.4)
	hud.add_child(_ipucu)
	var yardim := Label.new()
	yardim.text = "Sol tık: git/bina seç · Sağ tık sürükle: döndür · Tekerlek: yakınlaş · WASD: kaydır · C: ortala · Boşluk: duraklat · 1/2/3: hız · B: bölge · A: adamlar · D: defter · F6: kaydet · F9: yükle"
	yardim.position = Vector2(20, 694)
	yardim.add_theme_font_size_override("font_size", 14)
	yardim.modulate = Color(1, 1, 1, 0.7)
	hud.add_child(yardim)
	add_child(hud)
	Engine.time_scale = _hiz
	for a in OS.get_cmdline_user_args():   # doğrulama: --hedef=x,z  --bina=ad  --hizli
		if a.begins_with("--hedef="):
			var p := a.substr(8).split(",")
			oyuncu.git(Vector3(float(p[0]), 0, float(p[1])))
		elif a.begins_with("--diyalog="):
			_diyalog_testi(a.substr(10))
		elif a == "--kayit-testi":
			oyun.adam_tut()
			kaydet()
			oyun.adam_tut()
			print("once: ", oyun.adamlar.size())
			yukle()
			print("sonra: ", oyun.adamlar.size())
			for k in 400:
				oyun._gun()
			print("olaylar tamam, defter: ", oyun.defter.size())
		elif a.begins_with("--savas="):
			_savas_testi(a.substr(8))
		elif a == "--test":
			_otomatik_test()

func _karsilasti(g: Dictionary) -> void:
	match g["tur"]:
		"polis":
			oyun.kayit("%s yakınında (%d polis)." % [g["ad"], g["kisi"]], "warn")
		"rakip":
			oyun.kayit("%s yakınında (%d kişi)." % [g["ad"], g["kisi"]], "bad")

const KAYIT := "user://kayit.dat"

func kaydet() -> void:
	var f := FileAccess.open(KAYIT, FileAccess.WRITE)
	if f == null:
		oyun.kayit("Kayıt yazılamadı.", "bad")
		return
	f.store_var({"oyun": oyun.durum_al(), "oyuncu": oyuncu.global_position, "surum": 1}, true)
	oyun.kayit("Oyun kaydedildi (F9 ile yüklenir).", "good")

func yukle() -> void:
	if not FileAccess.file_exists(KAYIT):
		oyun.kayit("Kayıt bulunamadı (F6 ile kaydet).", "bad")
		return
	var f := FileAccess.open(KAYIT, FileAccess.READ)
	var d: Variant = f.get_var(true)
	if typeof(d) != TYPE_DICTIONARY or not d.has("oyun"):
		oyun.kayit("Kayıt dosyası bozuk.", "bad")
		return
	oyun.durum_yukle(d["oyun"])
	oyuncu.global_position = d["oyuncu"]
	oyuncu._yol = PackedVector3Array()
	takip_birak()
	oyun.kayit("Kayıt yüklendi.", "good")

func takip_ver(g: Dictionary) -> void:
	takip_id = g["id"]
	gruplar.takip_id = g["id"]
	oyun.kayit("%s kovalanıyor." % g["ad"], "info")

func takip_birak() -> void:
	takip_id = 0
	gruplar.takip_id = 0

func modal_duraklat(ac: bool) -> void:
	if ac:
		_onceki_hiz = _hiz
		Engine.time_scale = 0.0
	else:
		Engine.time_scale = _onceki_hiz

var savas_aktif := false

# 3D TPS savaşı başlat: dünya gizlenir, en yakın savaş alanı kurulur, bitince geri dönülür.
func savas_baslat(g: Dictionary, ceza: float, geri: Callable, tur_zorla: String = "", oto: bool = false) -> void:
	var veri: Dictionary = arayuz._kars.savas_verisi(g, ceza)
	if tur_zorla != "":
		veri["tur"] = tur_zorla
		veri["sahne"] = ""
	savas_aktif = true
	var onceki_kam: Camera3D = kamera.kamera()
	harita.visible = false
	oyuncu.visible = false
	gruplar.visible = false
	gruplar.set_process(false)
	arayuz.visible = false
	_hud_kok.visible = false
	Engine.time_scale = 1.0
	var s: Node3D = load("res://scripts/battle/savas.gd").new()
	add_child(s)
	s.baslat(oyun, veri, oto)
	s.bitti.connect(func(sonuc: Dictionary):
		s.queue_free()
		savas_aktif = false
		harita.visible = true
		oyuncu.visible = true
		gruplar.visible = true
		gruplar.set_process(true)
		arayuz.visible = true
		_hud_kok.visible = true
		onceki_kam.make_current()
		Engine.time_scale = 0.0 if arayuz.modal else _hiz
		print("savas sonucu: ", sonuc)
		geri.call(sonuc))

func hiz_ayarla(v: float) -> void:
	if v > 0.0:
		_hiz = v
	Engine.time_scale = v

func _unhandled_input(e: InputEvent) -> void:
	if arayuz.modal or savas_aktif:
		return
	if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
		var k: Camera3D = kamera.kamera()
		var o := k.project_ray_origin(e.position)
		var n := k.project_ray_normal(e.position)
		var i: int = harita.yer_isinla(o, n)
		if i >= 0:
			oyuncu.git(harita.yerler[i]["pos"])   # binaya tıkla: önüne git ve paneli aç
			arayuz.bina_ac(i)
		else:
			var nokta = harita.arazi_isinla(o, n)
			if nokta != null:
				oyuncu.git(nokta)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE: Engine.time_scale = 0.0 if Engine.time_scale > 0.0 else _hiz
			KEY_1: hiz_ayarla(1.0)
			KEY_2: hiz_ayarla(2.0)
			KEY_3: hiz_ayarla(4.0)
			KEY_B: arayuz._bolge_dugmesi()
			KEY_A: arayuz.adamlar_ac()
			KEY_D: arayuz.defter_ac()
			KEY_ESCAPE: arayuz.kapat()
			KEY_F6: kaydet()
			KEY_F9: yukle()

func _process(delta: float) -> void:
	if savas_aktif:
		return
	oyun.ilerle(delta)
	if takip_id != 0:
		_takip_sure -= delta
		if _takip_sure <= 0.0:
			_takip_sure = 0.5
			var hedef := {}
			for g in gruplar.liste:
				if g["id"] == takip_id:
					hedef = g
			if hedef.is_empty():
				takip_birak()
			else:
				oyuncu.git(hedef["pos"])
	_adamlari_guncelle()
	var id: String = harita.bolge_at(oyuncu.global_position)
	_etiket.text = harita.bolgeler[id]["ad"] if id != "" else "Yollar"
	var k: Camera3D = kamera.kamera()
	var fp := get_viewport().get_mouse_position()
	var gh: Dictionary = gruplar.isinla(k.project_ray_origin(fp), k.project_ray_normal(fp))
	var i: int = harita.yer_isinla(k.project_ray_origin(fp), k.project_ray_normal(fp))
	_oy_etiket.text = "Sen · %d kişi" % (1 + oyun.adamlar.size())
	if not gh.is_empty():
		_ipucu.text = "%s — %s" % [gruplar.etiket_yazi(gh), gh["durum"]]
	elif i >= 0:
		var y: Dictionary = harita.yerler[i]
		_ipucu.text = "%s  (%s)" % [y["ad"], harita.bolgeler[y["bolge"]]["ad"]]
	else:
		_ipucu.text = ""

# Görevdeki adamlar haritada yürür (yol_bul ile bulunan yoldan).
func _adamlari_guncelle() -> void:
	var canlilar := {}
	for g in oyun.gorevler:
		if g["gorev"] == "tutuklu":
			continue
		var aid: int = g["adam"]
		canlilar[aid] = true
		if not _adam_gorsel.has(aid):
			_adam_gorsel[aid] = _adam_olustur(oyun.adam_bul(aid).get("ad", "?"))
		var yol: PackedVector3Array = g["yolu"]
		var f := clampf(float(oyun.t - g["basla"]) / maxf(1.0, g["yol"]), 0.0, 1.0)
		(_adam_gorsel[aid] as Node3D).global_position = _yol_noktasi(yol, f)
	for aid in _adam_gorsel.keys():
		if not canlilar.has(aid):
			(_adam_gorsel[aid] as Node3D).queue_free()
			_adam_gorsel.erase(aid)

func _yol_noktasi(yol: PackedVector3Array, f: float) -> Vector3:
	if yol.size() == 0:
		return Vector3.ZERO
	var toplam := 0.0
	for k in range(1, yol.size()):
		toplam += yol[k - 1].distance_to(yol[k])
	var kalan := toplam * f
	for k in range(1, yol.size()):
		var d := yol[k - 1].distance_to(yol[k])
		if kalan <= d and d > 0.0:
			return yol[k - 1].lerp(yol[k], kalan / d)
		kalan -= d
	return yol[yol.size() - 1]

func _adam_olustur(ad: String) -> Node3D:
	var n := Node3D.new()
	var m := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.25, 0.45, 0.85)
	cm.material = mat
	m.mesh = cm
	m.position.y = 0.9
	m.scale = Vector3.ONE * 2.5
	n.add_child(m)
	var l := Label3D.new()
	l.text = ad
	l.font_size = 36
	l.pixel_size = 0.04
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 10
	l.modulate = Color(0.6, 0.8, 1.0)
	l.position.y = 7.0
	n.add_child(l)
	add_child(n)
	return n

# Komut satırı doğrulaması: adam tut, haraç bağla, hızlı ilerlet, sonucu yazdır.
func _otomatik_test() -> void:
	print("TEST başladı")
	print(oyun.adam_tut())
	var hedef := -1
	for i in harita.yerler.size():
		if harita.yerler[i]["bolge"] == "southside" and oyun.isy.has(i):
			hedef = i
			break
	print("hedef: ", harita.yerler[hedef]["ad"])
	print(oyun.gorev_ver(hedef, "haraclan"))
	arayuz.bina_ac(hedef)
	Engine.time_scale = 4.0
	_hiz = 4.0

# Doğrulama: verilen türden bir grubu yanına getirir, diyaloğu açar ve tüm seçenekleri dener.
func _savas_testi(tur: String) -> void:
	oyun.adam_tut()
	oyun.adam_tut()
	var g: Dictionary = {}
	for x in gruplar.liste:
		if x["tur"] == "rakip":
			g = x
			break
	g["kisi"] = 5
	await get_tree().process_frame
	savas_baslat(g, 1.0, func(s): print("TEST sonuc: ", s), tur, true)

func _diyalog_testi(tur: String) -> void:
	for g in gruplar.liste:
		if g["tur"] == tur:
			g["pos"] = oyuncu.global_position + Vector3(4, 0, 0)
			if tur == "rakip":
				g["mod"] = "kovala"
			elif tur == "polis":
				oyun.arama = 50.0
			print("DIYALOG ", tur, " ", g["ad"])
			var kars: RefCounted = load("res://scripts/core/karsilasma.gd").new(oyun, gruplar)
			for sec in kars.secenekler(g):
				var kopya: Dictionary = g.duplicate()
				print("  ", sec["id"], " -> ", kars.uygula(kopya, sec["id"])["metin"])
			arayuz.karsilasma_ac(g)
			return

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
