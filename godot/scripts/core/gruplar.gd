extends Node3D
# Haritada gezen gruplar (Warband'daki "party" gibi): polis devriyeleri, rakip ekipler, siviller.
# Her grubun adı, kaç kişi olduğu, fraksiyonu ve durumu var; etiketi kafasının üstünde yazar.
# Yürüyüş: harita.yol_bul (A*). Hareket delta ile (Engine.time_scale hızı uygular).

signal yakinlasti(g: Dictionary)   # oyuncu bir grubun yanına girdi (uyarı)
signal temas(g: Dictionary)        # yetiştik / yakalandık: karşılaşma diyaloğu açılır

const GORUS := 14.0        # bu mesafede "karşılaşma" sayılır (m)
const TEMAS := 7.0         # kovalama bu mesafede yetişme sayılır (m)
const GORUS_AV := 45.0     # rakip/polis seni bu mesafeden fark eder (m)
const SECIM := 5.0         # tıklama/üzerine gelme yarıçapı (m)
const SIVIL_AD := ["Esnaf", "İşçiler", "Pazarcılar", "Denizciler", "Komşular", "Yolcular", "Çocuklar", "Tüccar"]
const POLIS_AD := ["Devriye", "Karakol Ekibi", "Bekçiler"]
const HIZ := {"polis": 7.0, "rakip": 6.5, "sivil": 4.0}

var harita: Node3D
var oyun: Node
var oyuncu: Node3D
var liste: Array[Dictionary] = []
var rng := RandomNumberGenerator.new()
var _sayac := 0
var takip_id := 0          # oyuncunun kovaladığı grup
var _esitle_sure := 0.0
var _gorus_sure := 0.0
var _temas := {}   # grup id -> oyuncunun yakınında mı (tekrar uyarı vermesin)

func kur(h: Node3D, o: Node, p: Node3D) -> void:
	harita = h
	oyun = o
	oyuncu = p
	rng.seed = 777
	for id in harita.bolgeler:
		_polis_ekle(id)
		for k in 5:
			_sivil_ekle(id)
	_esitle()

# ---------- oluşturma ----------
func _yeni(tur: String, fak: String, ad: String, kisi: int, ev: String) -> Dictionary:
	_sayac += 1
	var yerler: Array = _bolge_yerleri(ev)
	var bas: Vector3 = harita.yerler[yerler[rng.randi() % yerler.size()]]["pos"]
	var g := {
		"id": _sayac, "tur": tur, "fak": fak, "ad": ad, "kisi": kisi, "ev": ev,
		"pos": bas, "yol": PackedVector3Array(), "bekle": rng.randf_range(0.0, 4.0),
		"durum": "Bekliyor", "mod": "", "serbest": 0, "ai": 0.0, "kisi_max": kisi, "rejen": 0, "hiz": HIZ[tur] * rng.randf_range(0.9, 1.1), "dugum": null, "etiket": null, "gorunen": -1,
	}
	_gorsel_kur(g)
	liste.append(g)
	return g

func _polis_ekle(ev: String) -> void:
	var n: int = 3 + oyun.bolge[ev]["servet"] / 2 + rng.randi() % 2
	var ad := "%s %s" % [harita.bolgeler[ev]["ad"], POLIS_AD[rng.randi() % POLIS_AD.size()]]
	_yeni("polis", "polis", ad, n, ev)

func _sivil_ekle(ev: String) -> void:
	_yeni("sivil", "sivil", SIVIL_AD[rng.randi() % SIVIL_AD.size()], 1 + rng.randi() % 3, ev)

func _kullanilan(f: String) -> Array:
	return liste.filter(func(g): return g["fak"] == f and g.has("lider")).map(func(g): return g["lider"])

func _rakip_ekle(f: String, ev: String) -> void:
	var u: Dictionary = oyun.lider_bul(f, _kullanilan(f))
	var g := _yeni("rakip", f, oyun.uye_ad(u), 3 + rng.randi() % 4, ev)
	g["lider"] = u["uid"]

func lider_ata(g: Dictionary) -> void:
	var u: Dictionary = oyun.lider_bul(g["fak"], _kullanilan(g["fak"]))
	g["lider"] = u["uid"]
	g["ad"] = oyun.uye_ad(u)

# Don, ailenin en güçlü grubuyla kendi bölgesinde gezer.
func _don_gruplari() -> void:
	for f in oyun.NPC:
		var don: Array = oyun.aile_uyeleri(f).filter(func(u): return u["rutbe"] == "don")
		if don.is_empty():
			continue
		var var_mi := not liste.filter(func(g): return g.get("lider", -1) == don[0]["uid"]).is_empty()
		if var_mi:
			continue
		var ev := ""
		for id in harita.bolgeler:
			if oyun.hakim_of(id) == f:
				ev = id
				break
		if ev == "":
			continue
		var g := _yeni("rakip", f, oyun.uye_ad(don[0]), 6 + rng.randi() % 3, ev)
		g["lider"] = don[0]["uid"]
		g["don"] = true

# Her fraksiyonun, hâkim olduğu bölge başına bir ekibi olur. Bölge el değiştirirse ekip de taşınır.
func _esitle() -> void:
	for g in liste:
		if g["kisi"] < g["kisi_max"] and oyun.t >= g["rejen"]:
			g["kisi"] += 1
			g["rejen"] = oyun.t + 360
	for g in liste.duplicate():   # lideri ölmüş ekibe yeni lider
		if g["tur"] == "rakip" and g.has("lider") and oyun.uye(g["lider"]).get("durum", "olu") != "aktif":
			if g.has("don"):
				_sil(g)
			else:
				lider_ata(g)
		elif g.has("lider"):
			g["ad"] = oyun.uye_ad(oyun.uye(g["lider"]))
	_don_gruplari()
	for f in oyun.NPC:
		var bolgeleri: Array = []
		for id in harita.bolgeler:
			if oyun.hakim_of(id) == f:
				bolgeleri.append(id)
		var ekipler: Array = liste.filter(func(g): return g["fak"] == f and not g.has("don"))
		while ekipler.size() < bolgeleri.size():
			_rakip_ekle(f, bolgeleri[ekipler.size()])
			ekipler = liste.filter(func(g): return g["fak"] == f and not g.has("don"))
		while ekipler.size() > bolgeleri.size() and ekipler.size() > 1:
			_sil(ekipler.pop_back())
		for k in ekipler.size():
			if bolgeleri.size() > 0:
				ekipler[k]["ev"] = bolgeleri[k % bolgeleri.size()]
	# polis her bölgede bir devriye; sivil sayısı sabit

func _sil(g: Dictionary) -> void:
	if g["dugum"]:
		(g["dugum"] as Node3D).queue_free()
	liste.erase(g)

# ---------- görünüm ----------
func _renk(g: Dictionary) -> Color:
	match g["tur"]:
		"polis": return Color(0.2, 0.3, 0.75)
		"sivil": return Color(0.65, 0.62, 0.55)
	return oyun.FAK[g["fak"]]["renk"]

func _gorsel_kur(g: Dictionary) -> void:
	var n := Node3D.new()
	add_child(n)
	g["dugum"] = n
	var l := Label3D.new()
	l.font_size = 44
	l.pixel_size = 0.07
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 10
	l.position.y = 11.0
	l.modulate = _renk(g).lerp(Color.WHITE, 0.45)
	if g["tur"] == "sivil":
		l.visibility_range_end = 110.0
		l.font_size = 36
		l.pixel_size = 0.05
	else:
		l.visibility_range_end = 400.0
	n.add_child(l)
	g["etiket"] = l
	var halka := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 3.6
	cyl.bottom_radius = 3.6
	cyl.height = 0.12
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(_renk(g), 0.65)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	cyl.material = hm
	halka.mesh = cyl
	halka.position.y = 0.15
	n.add_child(halka)
	_kisileri_yenile(g)

# Kişi sayısı kadar (en çok 6) kapsül, küme halinde.
func _kisileri_yenile(g: Dictionary) -> void:
	var n: Node3D = g["dugum"]
	for c in n.get_children():
		if c.has_meta("kisi"):
			c.queue_free()
	var goster := mini(g["kisi"], 6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = _renk(g)
	for k in goster:
		var m := MeshInstance3D.new()
		var cm := CapsuleMesh.new()
		cm.radius = 0.35
		cm.height = 1.8
		cm.material = mat
		m.mesh = cm
		m.set_meta("kisi", true)
		var a := TAU * k / maxf(goster, 1.0)
		var r := 0.0 if goster == 1 else 2.4
		m.position = Vector3(cos(a) * r, 0.9 * 3.2, sin(a) * r)
		m.scale = Vector3.ONE * 3.2
		n.add_child(m)
	g["gorunen"] = g["kisi"]

func etiket_yazi(g: Dictionary) -> String:
	return "%s (%d)" % [g["ad"], g["kisi"]]

# ---------- hareket ----------
func _process(delta: float) -> void:
	_esitle_sure += delta
	if _esitle_sure > 4.0:
		_esitle_sure = 0.0
		_esitle()
	for g in liste:
		_yuru(g, delta)
		var n: Node3D = g["dugum"]
		n.global_position = g["pos"]
		if g["gorunen"] != g["kisi"]:
			_kisileri_yenile(g)
		(g["etiket"] as Label3D).text = etiket_yazi(g)
	_gorus_sure += delta
	if _gorus_sure > 0.4:
		_gorus_sure = 0.0
		_karsilasma()

func serbest_birak(g: Dictionary, dakika: int) -> void:
	g["serbest"] = oyun.t + dakika
	if g["mod"] == "kovala":
		g["mod"] = ""
	g["yol"] = PackedVector3Array()
	g["bekle"] = 2.0
	if takip_id == g["id"]:
		takip_id = 0

func dagit(g: Dictionary) -> void:
	if takip_id == g["id"]:
		takip_id = 0
	_sil(g)

func _ai(g: Dictionary, delta: float) -> void:
	if g["tur"] == "sivil":
		return
	g["ai"] -= delta
	if g["ai"] > 0.0:
		return
	g["ai"] = 0.7
	var d: float = (g["pos"] as Vector3).distance_to(oyuncu.global_position)
	var serbest: bool = oyun.t < g["serbest"]
	if serbest:
		if g["mod"] == "kovala":
			g["mod"] = ""
			g["yol"] = PackedVector3Array()
		return
	if g["tur"] == "polis":
		if g["mod"] == "" and oyun.arama >= 30.0 and d < GORUS_AV:
			g["mod"] = "kovala"
		elif g["mod"] == "kovala" and (d > 130.0 or oyun.arama < 30.0):
			g["mod"] = ""
	elif g["tur"] == "rakip":
		if g["mod"] == "" and d < GORUS_AV:
			g["mod"] = "kovala" if g["kisi"] >= 0.8 * oyun.guc() else "kac"
		elif g["mod"] != "" and d > 120.0:
			g["mod"] = ""
	match g["mod"]:
		"kovala":
			g["durum"] = "Seni kovalıyor!"
			g["hiz"] = HIZ[g["tur"]] * 1.2
			_git(g, oyuncu.global_position)
		"kac":
			g["durum"] = "Kaçıyor"
			g["hiz"] = HIZ[g["tur"]] * 1.1
			var en := Vector3.ZERO
			var en_uz := -1.0
			var yerler := _bolge_yerleri(g["ev"])
			for k in 5:
				var h: Vector3 = harita.yerler[yerler[rng.randi() % yerler.size()]]["pos"]
				var u := h.distance_to(oyuncu.global_position)
				if u > en_uz:
					en_uz = u
					en = h
			if (g["yol"] as PackedVector3Array).size() == 0:
				_git(g, en)
		_:
			g["hiz"] = HIZ[g["tur"]]

func _git(g: Dictionary, hedef: Vector3) -> void:
	var yol: PackedVector3Array = harita.yol_bul(g["pos"], hedef)
	if yol.size() > 1:
		yol.remove_at(0)
		g["yol"] = yol

func _yuru(g: Dictionary, delta: float) -> void:
	_ai(g, delta)
	var yol: PackedVector3Array = g["yol"]
	if yol.size() == 0 and g["mod"] != "":
		return
	if yol.size() == 0:
		g["bekle"] -= delta
		g["durum"] = "Bekliyor" if g["tur"] != "polis" else "Nöbette"
		if g["bekle"] <= 0.0:
			_hedef_sec(g)
		return
	var kalan: float = g["hiz"] * delta
	var p: Vector3 = g["pos"]
	while kalan > 0.0 and yol.size() > 0:
		var f := yol[0] - p
		f.y = 0
		var uz := f.length()
		if uz <= kalan:
			p = Vector3(yol[0].x, p.y, yol[0].z)
			kalan -= uz
			yol.remove_at(0)
		else:
			p += f / uz * kalan
			kalan = 0.0
	p.y = harita.yuk(p.x, p.z)
	g["pos"] = p
	g["yol"] = yol
	if yol.size() == 0:
		g["bekle"] = rng.randf_range(3.0, 9.0) if g["tur"] != "polis" else rng.randf_range(1.0, 4.0)

func _bolge_yerleri(id: String) -> Array:
	var r: Array = []
	for i in harita.yerler.size():
		if harita.yerler[i]["bolge"] == id:
			r.append(i)
	return r

func _hedef_sec(g: Dictionary) -> void:
	var ev: String = g["ev"]
	var bolge := ev
	var sans := rng.randf()
	match g["tur"]:
		"polis":
			if sans < 0.3:   # komşu bölgeye de uğra
				var k: Array = oyun.KOMSU[ev]
				bolge = k[rng.randi() % k.size()]
			g["durum"] = "Devriye geziyor"
		"sivil":
			if sans < 0.25:
				var k2: Array = oyun.KOMSU[ev]
				bolge = k2[rng.randi() % k2.size()]
			g["durum"] = "Yolda"
		"rakip":
			if sans < 0.15:
				var k3: Array = oyun.KOMSU[ev]
				bolge = k3[rng.randi() % k3.size()]
			g["durum"] = "Bölgesini geziyor"
	var yerler := _bolge_yerleri(bolge)
	var hedef: Vector3 = harita.yerler[yerler[rng.randi() % yerler.size()]]["pos"]
	var yol: PackedVector3Array = harita.yol_bul(g["pos"], hedef)
	if yol.size() > 1:
		yol.remove_at(0)
		g["yol"] = yol
	else:
		g["bekle"] = 2.0

# ---------- karşılaşma ----------
func _karsilasma() -> void:
	# yedek: yeni "temas" için önce en yakın uygun grubu bul
	for g in liste.duplicate():
		var uz: float = (g["pos"] as Vector3).distance_to(oyuncu.global_position)
		var serbest: bool = oyun.t < g["serbest"]
		if uz < TEMAS and not serbest and (g["mod"] != "" or takip_id == g["id"]):
			temas.emit(g)
			return
	for g in liste:
		var uz: float = (g["pos"] as Vector3).distance_to(oyuncu.global_position)
		var yakin: bool = uz < GORUS
		if yakin and not _temas.get(g["id"], false):
			yakinlasti.emit(g)
		_temas[g["id"]] = yakin

# ---------- seçim ----------
# Işına en yakın grup (yoksa boş sözlük).
func isinla(o: Vector3, n: Vector3) -> Dictionary:
	var en: Dictionary = {}
	var en_uz := SECIM
	for g in liste:
		if not (g["dugum"] as Node3D).visible:
			continue
		var p: Vector3 = (g["pos"] as Vector3) + Vector3(0, 3.0, 0)
		var t := maxf((p - o).dot(n), 0.0)
		var uz := p.distance_to(o + n * t)
		if uz < en_uz:
			en_uz = uz
			en = g
	return en

func say(tur: String) -> int:
	var s := 0
	for g in liste:
		if g["tur"] == tur:
			s += g["kisi"]
	return s
