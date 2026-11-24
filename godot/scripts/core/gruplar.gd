extends Node3D
const Tema := preload("res://scripts/ui/tema.gd")
# Haritada gezen gruplar (Warband'daki "party" gibi): polis devriyeleri, rakip ekipler, siviller.
# Her grubun adı, kaç kişi olduğu, fraksiyonu ve durumu var; etiketi kafasının üstünde yazar.
# Yürüyüş: harita.yol_bul (A*). Hareket delta ile (Engine.time_scale hızı uygular).

signal yakinlasti(g: Dictionary)   # oyuncu bir grubun yanına girdi (uyarı)
signal temas(g: Dictionary)        # yetiştik / yakalandık: karşılaşma diyaloğu açılır

const GORUS := 14.0        # bu mesafede "karşılaşma" sayılır (m)
const TEMAS := 7.0         # kovalama bu mesafede yetişme sayılır (m)
const GORUS_AV := 45.0     # rakip/polis seni bu mesafeden fark eder (m)
const GUVENLI := 45.0      # evin çevresinde bu yarıçapta kimse sana bulaşamaz (m)
const SECIM := 5.0         # tıklama/üzerine gelme yarıçapı (m)
const Sakinler := preload("res://scripts/core/sakinler.gd")
const Cubuk := preload("res://scripts/core/cubuk.gd")
const SIVIL_AD := ["Esnaf", "İşçiler", "Pazarcılar", "Denizciler", "Komşular", "Yolcular", "Çocuklar", "Tüccar"]
const POLIS_AD := ["Devriye", "Karakol Ekibi", "Bekçiler"]
const KARARGAH := {"marchetti": "Marchetti Family", "obrien": "Murphy's Tavern", "tammany": "City Hall"}
const TEHLIKE := 85.0      # karargâhın bu yarıçapında nöbetçiler seni görür görmez üstüne gelir (m)
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
var _npc_sure := 0.0
var _hq := {}      # fraksiyon -> karargâh konumu
var _hq_ici := {}  # fraksiyon -> oyuncu tehlike bölgesinde mi
var _temas := {}   # grup id -> oyuncunun yakınında mı (tekrar uyarı vermesin)

func kur(h: Node3D, o: Node, p: Node3D) -> void:
	harita = h
	oyun = o
	oyuncu = p
	rng.seed = 777
	for id in harita.bolgeler:
		_polis_ekle(id)
		for _b in 2:
			_bekci_ekle(id)
	for f in KARARGAH:
		for i in harita.yerler.size():
			if harita.yerler[i]["ad"] == KARARGAH[f]:
				_hq[f] = harita.yerler[i]["pos"]
				for k in 3:
					_nobet_ekle(f, harita.yerler[i]["bolge"], k)
				break
	for sk in Sakinler.LISTE + Sakinler.GIZLI:   # isimli, rutinli şehir sakinleri (+ gizli olanlar)
		_sakin_ekle(sk)
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

# Karargâh nöbetçileri: kalabalık, karargâhın çevresinde dolaşır, bölgeye giren herkesin üstüne gelir.
func _nobet_ekle(f: String, ev: String, k: int) -> void:
	var g := _yeni("rakip", f, "%s Nöbetçileri" % oyun.FAK[f]["ad"].split(" ")[0], 6 + rng.randi() % 3, ev)
	g["nobet"] = f
	var a := TAU * k / 3.0
	g["pos"] = (_hq[f] as Vector3) + Vector3(cos(a), 0, sin(a)) * 22.0

# Gece bekçisi: tek polis, yalnızca geceleri sokaklarda gezer (gündüz görünmez).
func _bekci_ekle(ev: String) -> void:
	var g := _yeni("polis", "polis", "Bekçi", 1, ev)
	g["bekci"] = true
	g["evde"] = true
	(g["dugum"] as Node3D).visible = false

func gece_mi() -> bool:
	var saat: float = fmod(float(oyun.t), float(oyun.DAY)) / 60.0
	return saat >= 21.0 or saat < 5.5

func _bekci_plan(g: Dictionary) -> void:
	var dn: Node3D = g["dugum"]
	if not gece_mi():
		if not g["evde"]:
			g["evde"] = true
			g["yol"] = PackedVector3Array()
			g["mod"] = ""
			dn.visible = false
		return
	if g["evde"]:
		g["evde"] = false
		var yerler: Array = _bolge_yerleri(g["ev"])
		g["pos"] = harita.yerler[yerler[rng.randi() % yerler.size()]]["pos"]
		g["bekle"] = rng.randf_range(0.0, 3.0)
		dn.visible = true
		g["durum"] = "Gece devriyesi"

func _sivil_ekle(ev: String) -> void:
	_yeni("sivil", "sivil", SIVIL_AD[rng.randi() % SIVIL_AD.size()], 1 + rng.randi() % 3, ev)

# İsimli sakin: tek kişi, kendi mahallesinde, rutin saatlerinde görünür; aralık dışında evinde (haritada yok).
func _sakin_ekle(sk: Dictionary) -> void:
	var g := _yeni("sivil", "sivil", sk["ad"], 1, sk["bolge"])
	g["sakin"] = sk
	g["evde"] = true
	g["yer"] = ""
	g["sakin_durum"] = "Evinde"
	g["hiz"] = HIZ["sivil"] * rng.randf_range(0.85, 1.1)
	var yerler: Array = _bolge_yerleri(sk["bolge"])
	g["ev_pos"] = harita.yerler[yerler[absi(hash(sk["ad"])) % yerler.size()]]["pos"]
	(g["dugum"] as Node3D).visible = false

# Rutindeki bina adının, sakinin mahallesindeki ilk eşleşen binası (yoksa rastgele mahalle yeri).
func _sakin_hedef(g: Dictionary, bina: String) -> Vector3:
	var yerler: Array = _bolge_yerleri(g["ev"])
	if bina != "*":
		for i in yerler:
			if String(harita.yerler[i]["ad"]).begins_with(bina):
				return harita.yerler[i]["pos"]
	return harita.yerler[yerler[rng.randi() % yerler.size()]]["pos"]

func _sakin_plan(g: Dictionary) -> void:
	var saat: float = fmod(float(oyun.t), float(oyun.DAY)) / 60.0
	var a: Dictionary = Sakinler.aralik(g["sakin"], saat)
	var dn: Node3D = g["dugum"]
	if a.is_empty():
		if not g["evde"]:
			g["evde"] = true
			g["yer"] = ""
			g["yol"] = PackedVector3Array()
			dn.visible = false
		g["sakin_durum"] = "Evinde"
		return
	if g["evde"]:
		g["evde"] = false
		g["pos"] = g["ev_pos"]
		dn.visible = true
	if g["sakin"].has("fisilti") and (g["pos"] as Vector3).distance_to(oyuncu.global_position) < 8.0:
		var gun: int = int(oyun.t / oyun.DAY)
		if g.get("fis_gun", -1) != gun:
			g["fis_gun"] = gun
			oyun.kayit(g["sakin"]["fisilti"], "info")
	var anahtar := "%s@%s" % [a["yer"], a["bas"]]
	if g["yer"] != anahtar:
		g["yer"] = anahtar
		var hedef := _sakin_hedef(g, a["yer"])
		if (g["pos"] as Vector3).distance_to(oyuncu.global_position) > 140.0 and hedef.distance_to(oyuncu.global_position) > 140.0:
			g["pos"] = hedef   # kimse görmüyorsa ışınlan (zaman atlamaları / uzaktan)
			g["yol"] = PackedVector3Array()
		else:
			_git(g, hedef)
		g["sakin_durum"] = "Mahallede dolaşıyor" if a["yer"] == "*" else "Şurada: %s" % a["yer"]

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

# Don, ailenin en güçlü grubuyla kendi mahallesinde gezer.
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

# Her fraksiyonun, hâkim olduğu mahalle başına bir ekibi olur. Mahalle el değiştirirse ekip de taşınır.
func _esitle() -> void:
	for g in liste:
		if g["kisi"] < g["kisi_max"] and oyun.t >= g["rejen"]:
			g["kisi"] += 1
			g["rejen"] = oyun.t + 360
	for g in liste.duplicate():   # lideri ölmüş ekibe yeni lider
		if g["tur"] == "rakip" and g.has("lider") and (oyun.uye(g["lider"]).get("durum", "olu") != "aktif" or oyun.uye(g["lider"]).get("fak", "") != g["fak"]):
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
		var ekipler: Array = liste.filter(func(g): return g["fak"] == f and not g.has("don") and not g.has("nobet"))
		while ekipler.size() < bolgeleri.size():
			_rakip_ekle(f, bolgeleri[ekipler.size()])
			ekipler = liste.filter(func(g): return g["fak"] == f and not g.has("don") and not g.has("nobet"))
		while ekipler.size() > bolgeleri.size() and ekipler.size() > 1:
			_sil(ekipler.pop_back())
		var ask: int = oyun.aile_uyeleri(f).filter(func(u): return u["rutbe"] == "asker").size()
		for k in ekipler.size():
			if bolgeleri.size() > 0:
				ekipler[k]["ev"] = bolgeleri[k % bolgeleri.size()]
			ekipler[k]["kisi_max"] = clampi(2 + ask / maxi(1, ekipler.size()), 2, 8)
			ekipler[k]["kisi"] = mini(ekipler[k]["kisi"], ekipler[k]["kisi_max"])
	# polis her mahallede bir devriye; sivil sayısı sabit

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

static var _plaka_onb := {}
# Krem kâğıt plaka: ince siyah çerçeve, içte fraksiyon renginde çizgi, pahlı Art Deco uçlar.
static func _plaka_tex(w: int, h: int, renk: Color) -> ImageTexture:
	w = (w + 7) / 8 * 8
	var k := "%d_%d_%s" % [w, h, renk.to_html()]
	if _plaka_onb.has(k):
		return _plaka_onb[k]
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var ink := Color("1c1710")
	var kagit := Color("e8dfc8")
	var ic := renk.lerp(Color("8f7c52"), 0.5)
	var pah := h / 4
	for y in h:
		for x in w:
			var kx := mini(x, w - 1 - x)
			var ky := mini(y, h - 1 - y)
			var e := mini(mini(kx, ky), kx + ky - pah)
			var c := Color(0, 0, 0, 0)
			if e >= 0:
				c = kagit
				if e <= 1:
					c = ink
				elif e == 3:
					c = ic
				elif y > h * 0.55:
					c = kagit.darkened(0.06)
			im.set_pixel(x, y, c)
	var t := ImageTexture.create_from_image(im)
	_plaka_onb[k] = t
	return t

func _gorsel_kur(g: Dictionary) -> void:
	var n := Node3D.new()
	add_child(n)
	g["dugum"] = n
	var l := Label3D.new()
	l.font_size = 44
	l.pixel_size = 0.07
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = true
	l.outline_size = 0
	l.position.y = 11.0
	l.font = Tema.yazi_tipi()
	l.modulate = Color("1c1710")
	l.render_priority = 2
	var pl := Sprite3D.new()
	pl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	pl.no_depth_test = true
	pl.shaded = false
	pl.render_priority = 1
	pl.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	pl.position.y = 11.0
	n.add_child(pl)
	g["plaka"] = pl
	if g["tur"] == "sivil":
		l.visibility_range_end = 110.0
		l.font_size = 36
		l.pixel_size = 0.05
		pl.visibility_range_end = 110.0
	else:
		l.visibility_range_end = 400.0
		pl.visibility_range_end = 400.0
	pl.pixel_size = l.pixel_size
	n.add_child(l)
	g["etiket"] = l
	var halka := MeshInstance3D.new()
	var tor := TorusMesh.new()
	tor.inner_radius = 3.45
	tor.outer_radius = 3.65
	tor.rings = 40
	tor.ring_segments = 6
	var hm := StandardMaterial3D.new()
	hm.albedo_color = Color(_renk(g), 0.85)
	hm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	hm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	tor.material = hm
	halka.mesh = tor
	halka.scale = Vector3(1, 0.25, 1)
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
	for k in goster:
		var m: Node3D = Cubuk.kisi(_renk(g))
		m.set_meta("kisi", true)
		var a := TAU * k / maxf(goster, 1.0)
		var r := 0.0 if goster == 1 else 2.4
		m.position = Vector3(cos(a) * r, 0.0, sin(a) * r)
		m.scale = Vector3.ONE * 3.2
		n.add_child(m)
	g["gorunen"] = g["kisi"]

func etiket_yazi(g: Dictionary) -> String:
	if g.has("sakin"):
		return "%s · %s" % [g["ad"], g["sakin"]["is"]]
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
		var yz := etiket_yazi(g)
		if g.get("yz", "") != yz:
			g["yz"] = yz
			var l3: Label3D = g["etiket"]
			l3.text = yz
			var w: float = Tema.yazi_tipi().get_string_size(yz, HORIZONTAL_ALIGNMENT_LEFT, -1, l3.font_size).x
			(g["plaka"] as Sprite3D).texture = _plaka_tex(int(w) + 40, int(l3.font_size * 1.55), _renk(g))
	_npc_sure += delta
	if _npc_sure > 2.5:
		_npc_sure = 0.0
		_npc_etkilesim()
	_gorus_sure += delta
	if _gorus_sure > 0.4:
		_gorus_sure = 0.0
		_karsilasma()

# ---------- NPC'ler arası: aileler birbirine saldırır, polis yasadışı ekipleri sıkıştırır ----------
func _yakin_mi(g: Dictionary) -> bool:
	return (g["pos"] as Vector3).distance_to(oyuncu.global_position) < 90.0

func _npc_etkilesim() -> void:
	var rak: Array = liste.filter(func(g): return g["tur"] == "rakip")
	var pol: Array = liste.filter(func(g): return g["tur"] == "polis")
	for i in rak.size():
		for j in range(i + 1, rak.size()):
			var a: Dictionary = rak[i]
			var b: Dictionary = rak[j]
			if a["fak"] == b["fak"]:
				continue
			if (a["pos"] as Vector3).distance_to(b["pos"]) > 18.0:
				continue
			var gp: float = oyun.gerginlik.gerginlik(a["fak"], b["fak"])
			var savas: bool = oyun.gerginlik.savasta(a["fak"], b["fak"])
			var p: float = 0.1 + 0.03 * gp + (0.5 if savas else 0.0)
			if rng.randf() < p:
				_npc_catisma(a, b)
	for pl in pol:
		if pl.get("evde", false):
			continue
		for r in rak:
			if (pl["pos"] as Vector3).distance_to(r["pos"]) > 26.0:
				continue
			if pl["mod"] == "" and (pl["yol"] as PackedVector3Array).size() == 0:
				_git(pl, r["pos"])
			if (pl["pos"] as Vector3).distance_to(r["pos"]) < 12.0 and rng.randf() < 0.22:
				_polis_baskin(pl, r)

func _npc_catisma(a: Dictionary, b: Dictionary) -> void:
	var ga: float = a["kisi"] * rng.randf_range(0.7, 1.3)
	var gb: float = b["kisi"] * rng.randf_range(0.7, 1.3)
	var kazan: Dictionary = a if ga >= gb else b
	var kaybeden: Dictionary = b if ga >= gb else a
	var kayip: int = 1 + rng.randi() % 2
	kaybeden["kisi"] = maxi(1, kaybeden["kisi"] - kayip)
	if rng.randf() < 0.4:
		kazan["kisi"] = maxi(1, kazan["kisi"] - 1)
	for g in [a, b]:
		g["bekle"] = 3.0
		g["yol"] = PackedVector3Array()
		g["durum"] = "Çatışıyor"
	oyun.gerginlik.ekle(a["fak"], b["fak"], 1.2, "sokak çatışması")
	if _yakin_mi(a):
		oyun.kayit("%s ve %s adamları çatıştı: %s üstün geldi." % [oyun.hakim_ad(a["fak"]), oyun.hakim_ad(b["fak"]), oyun.hakim_ad(kazan["fak"])], "warn")

func _polis_baskin(pl: Dictionary, r: Dictionary) -> void:
	r["kisi"] = maxi(1, r["kisi"] - 1)
	r["bekle"] = 3.0
	r["yol"] = PackedVector3Array()
	r["durum"] = "Polisle çatışıyor"
	if _yakin_mi(r):
		oyun.kayit("%s, %s adamlarından birini yakaladı." % [pl["ad"], oyun.hakim_ad(r["fak"])], "info")

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

func guvenli_mi() -> bool:
	if oyuncu.iceride >= 0:
		return true   # bir binanın içindesin: kimse göremez
	if oyun._ev < 0:
		return false
	var e: Vector3 = harita.yerler[oyun._ev]["pos"]
	return Vector2(e.x, e.z).distance_to(Vector2(oyuncu.global_position.x, oyuncu.global_position.z)) < GUVENLI

func _ai(g: Dictionary, delta: float) -> void:
	if g["tur"] == "sivil" or g.get("evde", false):
		return
	g["ai"] -= delta
	if g["ai"] > 0.0:
		return
	g["ai"] = 0.7
	var d: float = (g["pos"] as Vector3).distance_to(oyuncu.global_position)
	var serbest: bool = oyun.t < g["serbest"]
	if guvenli_mi() and g["tur"] != "sivil":
		if g["mod"] != "":
			g["mod"] = ""
			g["yol"] = PackedVector3Array()
		return
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
	elif g["tur"] == "rakip" and g.has("nobet"):
		var hq: Vector3 = _hq[g["nobet"]]
		var dh := Vector2(hq.x - oyuncu.global_position.x, hq.z - oyuncu.global_position.z).length()
		if g["mod"] == "" and dh < TEHLIKE and not oyun.gerginlik.dost_mu(g["fak"]):
			g["mod"] = "kovala"
		elif g["mod"] != "" and (dh > TEHLIKE + 55.0 or oyun.gerginlik.dost_mu(g["fak"])):
			g["mod"] = ""
			g["yol"] = PackedVector3Array()
	elif g["tur"] == "rakip":
		if g["mod"] == "" and d < GORUS_AV:
			if oyun.gerginlik.dost_mu(g["fak"]):
				pass   # çalıştığın mahallenin ailesi: seni kollar, bulaşmaz
			elif oyun.gerginlik.dusman_mi(g["fak"]):
				g["mod"] = "kovala"   # savaşta ya da ev sahibinin düşmanı: gücüne bakmadan üstüne gelir
			elif not oyun.kis_k.fark_edildi():
				pass   # henüz kimse değilsin: aileler seni umursamaz, haraç istemeye gelmez
			else:
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
	if g.has("bekci"):
		_bekci_plan(g)
		if g["evde"]:
			return
	_ai(g, delta)
	if g.has("sakin") and g["mod"] == "" and takip_id != g["id"]:
		_sakin_plan(g)
		if g["evde"]:
			return
	var yol: PackedVector3Array = g["yol"]
	if yol.size() == 0 and g["mod"] != "":
		return
	if yol.size() == 0:
		g["bekle"] -= delta
		g["durum"] = g["sakin_durum"] if g.has("sakin") else ("Bekliyor" if g["tur"] != "polis" else "Nöbette")
		if g["bekle"] <= 0.0:
			if g.has("sakin") and not String(g["yer"]).begins_with("*"):
				g["bekle"] = 5.0   # işyerinde kal
			else:
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
	if g.has("nobet"):
		var hq: Vector3 = _hq[g["nobet"]]
		var yakin: Array = []
		for i in harita.yerler.size():
			if (harita.yerler[i]["pos"] as Vector3).distance_to(hq) < TEHLIKE * 0.7:
				yakin.append(i)
		g["durum"] = "Karargâhı gözlüyor"
		if yakin.is_empty():
			g["bekle"] = 3.0
			return
		_git(g, harita.yerler[yakin[rng.randi() % yakin.size()]]["pos"])
		if (g["yol"] as PackedVector3Array).size() == 0:
			g["bekle"] = 2.0
		return
	var ev: String = g["ev"]
	var bolge := ev
	var sans := rng.randf()
	if g["tur"] == "rakip" and gece_mi() and not g.has("don"):
		# gece: kendi mahallesinin köşesinde durur, bölgesini kollar
		if not g.has("kose") or g.get("kose_ev", "") != ev:
			var ky: Array = _bolge_yerleri(ev)
			g["kose"] = harita.yerler[ky[rng.randi() % ky.size()]]["pos"]
			g["kose_ev"] = ev
		g["durum"] = "Köşeyi tutuyor"
		if (g["pos"] as Vector3).distance_to(g["kose"]) > 8.0:
			_git(g, g["kose"])
		if (g["yol"] as PackedVector3Array).size() == 0:
			g["bekle"] = 8.0
		return
	match g["tur"]:
		"polis":
			if sans < 0.3:   # komşu mahalleye de uğra
				var k: Array = oyun.KOMSU[ev]
				bolge = k[rng.randi() % k.size()]
			g["durum"] = "Devriye geziyor"
		"sivil":
			if sans < 0.25 and not g.has("sakin"):
				var k2: Array = oyun.KOMSU[ev]
				bolge = k2[rng.randi() % k2.size()]
			g["durum"] = "Yolda"
		"rakip":
			if sans < 0.15:
				var k3: Array = oyun.KOMSU[ev]
				bolge = k3[rng.randi() % k3.size()]
			g["durum"] = "Mahallesini geziyor"
	var yerler := _bolge_yerleri(bolge)
	var hedef: Vector3 = harita.yerler[yerler[rng.randi() % yerler.size()]]["pos"]
	var yol: PackedVector3Array = harita.yol_bul(g["pos"], hedef)
	if yol.size() > 1:
		yol.remove_at(0)
		g["yol"] = yol
	else:
		g["bekle"] = 2.0

# ---------- karşılaşma ----------
func _tehlike_uyari() -> void:
	for f in _hq:
		var hq: Vector3 = _hq[f]
		var ici := Vector2(hq.x - oyuncu.global_position.x, hq.z - oyuncu.global_position.z).length() < TEHLIKE
		if ici and not _hq_ici.get(f, false) and oyuncu.iceride < 0 and not oyun.gerginlik.dost_mu(f):
			oyun.kayit("TEHLİKE: %s karargâhına yaklaşıyorsun. Nöbetçiler gören herkesin üstüne gelir." % oyun.FAK[f]["ad"], "warn")
		_hq_ici[f] = ici

func _karsilasma() -> void:
	_tehlike_uyari()
	if guvenli_mi():
		return
	# yedek: yeni "temas" için önce en yakın uygun grubu bul
	for g in liste.duplicate():
		if g.get("evde", false):
			continue
		var uz: float = (g["pos"] as Vector3).distance_to(oyuncu.global_position)
		var serbest: bool = oyun.t < g["serbest"]
		if uz < TEMAS and not serbest and (g["mod"] != "" or takip_id == g["id"]):
			temas.emit(g)
			return
	for g in liste:
		if g.get("evde", false):
			continue
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
