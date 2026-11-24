extends Node3D
# Ana sahne: haritayı, oyun kurallarını (oyun.gd) ve 2D arayüzü (arayuz.gd) bir araya getirir.
# Sol tık: git (binaya tıklarsan önüne gider, varınca panel açılır). Sağ tık: bina bilgisi. Boşluk: duraklat. 1/2/3: hız. B: mahalle. T: adamlar. F: defter.

var harita: Node3D
var oyun: Node
var arayuz: CanvasLayer
var oyuncu: Node3D
var gruplar: Node3D
var _oy_etiket: Label3D
var _oy_plaka: Sprite3D
var _oy_yz := ""
var kamera: Node3D
var _etiket: Label
var _fps: Label
var _ipucu: Label
var _hiz := 1.0
var _hud_kok: CanvasLayer
var takip_id := 0
var _takip_sure := 0.0
var _onceki_hiz := 1.0
var gorus: Node3D
var _adam_gorsel := {}   # adam id -> Node3D (haritada yürüyen adam)

func _ready() -> void:
	for a in OS.get_cmdline_user_args():   # doğrulama: --profil=koken,aile,gecmis,yas,ad (menüyü atlar)
		if a.begins_with("--profil="):
			var q := a.substr(9).split(",")
			var pr := {"ad": q[4] if q.size() > 4 else "Test Adam", "yas": int(q[3]) if q.size() > 3 else 30,
				"koken": q[0], "aile": q[1] if q.size() > 1 else "marchetti", "gecmis": q[2] if q.size() > 2 else "yok"}
			load("res://scripts/core/profil.gd").aktif = pr
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
	oyuncu.oyun = oyun
	add_child(oyuncu)
	oyuncu.global_position = oyun.baslangic_noktasi()   # köken ve eve göre
	kamera = Node3D.new()
	kamera.set_script(load("res://scripts/characters/ust_kamera.gd"))
	add_child(kamera)
	kamera.hedef = oyuncu
	_hava_kur()
	_oy_etiket = Label3D.new()
	_oy_etiket.font_size = 40
	_oy_etiket.pixel_size = 0.07
	_oy_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_oy_etiket.no_depth_test = true
	_oy_etiket.outline_size = 0
	_oy_etiket.font = load("res://scripts/ui/tema.gd").yazi_tipi()
	_oy_etiket.modulate = Color("1c1710")
	_oy_etiket.render_priority = 2
	_oy_etiket.position.y = 12.0
	oyuncu.add_child(_oy_etiket)
	_oy_plaka = Sprite3D.new()
	_oy_plaka.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_oy_plaka.no_depth_test = true
	_oy_plaka.shaded = false
	_oy_plaka.render_priority = 1
	_oy_plaka.pixel_size = 0.07
	_oy_plaka.position.y = 12.0
	oyuncu.add_child(_oy_plaka)
	gruplar = load("res://scripts/core/gruplar.gd").new()
	gruplar.name = "Gruplar"
	add_child(gruplar)
	gruplar.kur(harita, oyun, oyuncu)
	gorus = load("res://scripts/core/gorus.gd").new()
	gorus.name = "Gorus"
	add_child(gorus)
	gorus.kur(harita, oyun, self)
	var bc: Node3D = load("res://scripts/core/bolge_cizgi.gd").new()
	bc.name = "BolgeCizgi"
	add_child(bc)
	bc.kur(oyun, harita, self)
	var yy: Node3D = load("res://scripts/core/yayalar.gd").new()
	yy.name = "Yayalar"
	add_child(yy)
	yy.kur(harita, oyuncu, oyun, kamera)
	var bs: Node3D = load("res://scripts/core/bina_simge.gd").new()
	bs.name = "BinaSimge"
	add_child(bs)
	bs.kur(oyun, harita, kamera)
	_bs = bs
	gruplar.yakinlasti.connect(_karsilasti)
	gruplar.temas.connect(func(g): arayuz.karsilasma_ac(g))
	arayuz = load("res://scripts/ui/arayuz.gd").new()
	add_child(arayuz)
	arayuz.kur(oyun, self)
	var hud := CanvasLayer.new()
	_hud_kok = hud
	_fps = Label.new()
	_fps.anchor_left = 1.0
	_fps.anchor_right = 1.0
	_fps.offset_left = -110
	_fps.offset_top = 76
	_fps.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps.add_theme_font_size_override("font_size", 14)
	_fps.add_theme_color_override("font_outline_color", Color.BLACK)
	_fps.add_theme_constant_override("outline_size", 6)
	_fps.modulate = Color(1, 1, 1, 0.75)
	hud.add_child(_fps)
	_etiket = Label.new()
	_etiket.position = Vector2(14, 72)
	_etiket.add_theme_font_size_override("font_size", 17)
	_etiket.add_theme_color_override("font_outline_color", Color.BLACK)
	_etiket.add_theme_constant_override("outline_size", 8)
	hud.add_child(_etiket)
	_ipucu = Label.new()
	_ipucu.position = Vector2(135, 126)
	_ipucu.add_theme_font_size_override("font_size", 16)
	_ipucu.add_theme_color_override("font_outline_color", Color.BLACK)
	_ipucu.add_theme_constant_override("outline_size", 8)
	_ipucu.modulate = Color("d6c49c")
	hud.add_child(_ipucu)
	var yardim := Label.new()
	yardim.text = "Sol tık: git/binaya gir/kovala · Sağ tık: bina-adam bilgisi · Sağ tık sürükle: döndür · Tekerlek: yakınlaş · WASD: kaydır · C: ortala · Boşluk: duraklat · V: sis aç/kapa · 1/2/3: hız · B: mahalle · T: adamlar · F: defter · H: eve git · F6: kaydet · F9: yükle · F11: tam ekran"
	yardim.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	yardim.offset_left = 205
	yardim.offset_top = -26
	yardim.add_theme_font_size_override("font_size", 12)
	yardim.modulate = Color(1, 1, 1, 0.5)
	hud.add_child(yardim)
	var ev_is := Control.new()
	ev_is.set_script(load("res://scripts/ui/ev_isaret.gd"))
	ev_is.oyun = oyun
	ev_is.sokak = self
	hud.add_child(ev_is)
	add_child(hud)
	Engine.time_scale = _hiz
	var PR := load("res://scripts/core/profil.gd")
	if PR.yukle_basta:
		PR.yukle_basta = false
		yukle(PR.yukle_slot)
		PR.yukle_slot = ""
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
		elif a.begins_with("--isin="):   # doğrulama: oyuncuyu doğrudan oraya koy
			var q := a.substr(7).split(",")
			oyuncu.global_position = Vector3(float(q[0]), harita.yuk(float(q[0]), float(q[1])), float(q[1]))
		elif a.begins_with("--saat="):
			oyun.t = float(a.substr(7)) * 60.0
		elif a.begins_with("--hava="):
			oyun.hava_zorla = a.substr(7)
			_orttu_g = 0.9
			_yog_g = 1.0
		elif a.begins_with("--mesafe="):
			kamera.mesafe = float(a.substr(9))
		elif a == "--sissiz":
			gorus.acik = false
			gorus.guncelle()
			gorus._gorunurluk()
		elif a == "--is-testi":
			var bi := -1
			for k in oyun.isy:
				if not oyun.isy[k]["sahip"]:
					bi = k
					break
			print("is: ", oyun.harita.yerler[bi]["ad"], " ucret ", oyun.ucret(bi), " temiz once ", oyun.temiz)
			print("calis: ", oyun.calis(bi))
			for k in 500:
				oyun.t += 1
				if oyun.t % 60 == 0:
					oyun._saat()
			print("temiz sonra ", oyun.temiz, " vardiya ", oyun.vardiya)
			for k in 10:
				oyun._gun()
			oyun._ay()
			print("ay sonu temiz ", oyun.temiz, " borc ", oyun.kira_borc, " ev ", oyun.harita.yerler[oyun._ev]["ad"], " konum ", oyuncu.global_position)
		elif a == "--arac-testi":
			oyun.temiz = 5000.0
			print(oyun.arac_k.al("ford")["msg"], " hiz x", oyun.arac_k.hiz_carpan())
			oyun.arac_k.adim(300.0)
			print("yakit ", oyun.arac["yakit"])
			print(oyun.arac_k.benzin_al()["msg"])
			arayuz.garaj_ac()
		elif a == "--meslek-testi":
			var K: RefCounted = oyun.meslek
			print("kabul taksi southside: ", K.kabul("taksi", "southside"))
			print(K.is_gir("taksi", "southside")["msg"])
			for i in 30:
				oyun.meslek.gun()
			print("beceri ", oyun.mes["beceri"]["taksi"], " yurume x", K.yurume_carpan())
			oyun.temiz = 5000.0
			print(K.isletme_al("taksi")["msg"], " x", K.yurume_carpan(), " gelir ", K.isletme_gelir("taksi"))
			oyun.temiz = 0.0
			for i in 3:
				oyun.borc_k.ay()
			print("borc ", oyun.borc, " son=", oyun.son)
			oyun.son = {}
			oyun.temiz = 2000.0
			oyun.temiz = 3000.0
			oyun.kirli = 2000.0
			oyun.yasal(1000.0)
			print("plan ", oyun.aklama_k.plan(), " camasir ", oyun.aklama_k.camasir_al()["ok"])
			oyun.akl["yuzde"] = 150
			oyun.aklama_k.ay()
			print("akl ", oyun.akl, " temiz ", oyun.temiz, " kirli ", oyun.kirli)
			arayuz.meslek_ac()
		elif a == "--polis-testi":
			oyun.kirli = 3000.0
			oyun.temiz = 1000.0
			oyun.adam_tut()
			print("adamlar ", oyun.adamlar.size())
			print(oyun.polis.kur()["msg"], oyun.polis.hacim_ayarla(60)["ok"])
			for i in 40:
				oyun.polis.gun()
				if oyun.arama >= 75:
					break
			print("gun ", oyun.t, " arama ", oyun.arama, " pol ", oyun.pol)
			oyun.arama = 80.0
			oyun.polis.gun()
			print("baskin planli ", oyun.pol["baskin"], " t ", oyun.t)
			oyun.t += 4 * 1440
			oyun.polis.gun()
			print("baskin sonrasi arama ", oyun.arama, " kurulu ", oyun.pol["kurulu"])
			print(oyun.polis.rusvet(300.0)["msg"])
			arayuz.polis_ac()
		elif a.begins_with("--ekran="):
			_ekran_cek(a.substr(8))
		elif a == "--kart-testi":
			var kk: RefCounted = oyun.kart_k
			for id in kk.KARTLAR:
				if kk.KARTLAR[id][1] == 0 and id != "yol_sec":
					continue
				kk.hazirla(id)
				var ns: int = kk.secenekler(id).size()
				for n2 in ns:
					oyun.temiz = 1000.0
					oyun.kirli = 1000.0
					oyun.arama = 50.0
					oyun.borc["ana"] = 500.0
					var rr: Dictionary = kk._coz(id, n2)
					print(id, " ", n2, " -> ", rr["metin"])
			print("yol: ", oyun.yol["puan"], " ", oyun.yol_k.ozet_satiri())
			oyun.t += 25 * 1440
			oyun.yol_k.gun()
			print("donem: ", oyun.yol["donem"], " bekleyen: ", oyun.yol["bekleyen"])
			get_tree().quit()
		elif a == "--kisisel-testi":
			var K: RefCounted = oyun.kis_k
			print("baslangic taninma ", K.taninma(), " fark ", K.fark_edildi(), " oz ", K.oz_liste())
			oyun.bekle(60 * 30)
			print("30 saat sonra: ", oyun.kis["aclik"], " ", oyun.kis["yorgun"], " ", oyun.kis["stres"], " ", oyun.kis["sikinti"], " form ", K.form(), " acil ", K.acil())
			var diner := -1
			var bar := -1
			for i in oyun.harita.yerler.size():
				var ad: String = String(oyun.harita.yerler[i]["ad"]).to_lower()
				if diner < 0 and ad.contains("diner"):
					diner = i
				if bar < 0 and oyun.pazar_k.site_mi(i):
					bar = i
			print("diner ", diner, " eylemler ", K.eylemler(diner), " bar ", bar, " eylemler ", K.eylemler(bar))
			print(K.yap("yemek"))
			print("yemekten sonra aclik ", oyun.kis["aclik"])
			print("adaylar: ", oyun.pazar_k.liste(bar))
			oyun.kirli = 500.0
			print(oyun.pazar_k.tut(bar, 0), " ekip ", oyun.adamlar.size())
			for n in 6:
				K.yap("sohbet")
			print("oz: ", K.oz_liste(), " cevre ", K.oz("cevre"))
			oyun.uyu()
			print("uyku sonrasi yorgun ", oyun.kis["yorgun"], " saat ", oyun.saat_yazi())
			get_tree().quit()
		elif a == "--gir-testi":
			oyuncu.gir(oyun._ev)
			arayuz.bina_ac(oyun._ev)
		elif a == "--gerg-testi":
			var gk: RefCounted = oyun.gerginlik
			gk.ekle("marchetti", "obrien", 6.0, "test")
			print("savasta (esik alti): ", gk.savasta("marchetti", "obrien"))
			gk.ekle("obrien", "marchetti", 5.0, "test")
			print("savasta: ", gk.savasta("marchetti", "obrien"), " puan ", gk.gerginlik("marchetti", "obrien"))
			var ci: int = oyun.isy.keys()[0]
			oyun.vardiya = {"bina": ci, "bitis": oyun.t + 480, "ucret": 10}
			var hb: String = oyun.harita.yerler[ci]["bolge"]
			print("is bolgesi ", gk.is_bolgesi(), " hakim ", oyun.hakim_of(hb), " ev sahibi ", gk.ev_sahibi())
			oyun.t += 21 * 1440
			gk.ay()
			print("21 gun sonra savasta: ", gk.savasta("marchetti", "obrien"))
			print("guvenli (evde): ", gruplar.guvenli_mi())
		elif a == "--zafer-testi":
			var n := 0
			for k in oyun.isy:
				if n < 4:
					oyun.isy[k]["sahip"] = true
					n += 1
			oyun.temiz = 20000.0
			oyun.arama = 0.0
			oyun.zafer.ay()
			print("1. ay: ", oyun.zf, " son=", oyun.son)
			oyun.zafer.ay()
			print("2. ay: ", oyun.zf, " son=", oyun.son)
			arayuz.zafer_ac()
		elif a == "--aile-testi":
			_aile_testi()
		elif a.begins_with("--isletme-testi"):
			_isletme_testi(a.ends_with("ss"))
		elif a.begins_with("--denge="):
			var dd := a.substr(8).split(",")
			load("res://scripts/core/denge_testi.gd").calistir(oyun, dd[0], int(dd[1]))
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

const KY := preload("res://scripts/core/kayitlar.gd")
var _son_oto := -1

func kaydet(slot: String = "") -> void:
	if slot == "":
		slot = KY.aktif
	var f := FileAccess.open(KY.yol(slot), FileAccess.WRITE)
	if f == null:
		oyun.kayit("Kayıt yazılamadı.", "bad")
		return
	var yil: int = oyun.t / 172800
	var meta := {"tarih": Time.get_datetime_string_from_system(false, true).substr(0, 16), "yil": 1920 + yil, "tip": oyun.un_k.tip()["ad"],
		"nesil": int(oyun.aile.get("nesil", 1)), "para": int(oyun.temiz)}
	f.store_var({"oyun": oyun.durum_al(), "oyuncu": oyuncu.global_position, "gorus": gorus.durum_al(), "surum": 2, "meta": meta}, true)
	if slot != "oto":
		KY.aktif = slot
		oyun.kayit("Oyun kaydedildi (%s)." % KY.ad(slot), "good")

func yukle(slot: String = "") -> void:
	if slot == "":
		slot = KY.aktif if KY.var_mi(KY.aktif) else KY.en_yeni()
	var yol: String = KY.hangisi(slot) if slot != "" else ""
	if yol == "":
		oyun.kayit("Kayıt bulunamadı (F6 ile kaydet).", "bad")
		return
	var f := FileAccess.open(yol, FileAccess.READ)
	var d: Variant = f.get_var(true)
	if typeof(d) != TYPE_DICTIONARY or not d.has("oyun"):
		oyun.kayit("Kayıt dosyası bozuk.", "bad")
		return
	oyun.durum_yukle(d["oyun"])
	oyuncu.global_position = d["oyuncu"]
	oyuncu._yol = PackedVector3Array()
	if d.has("gorus"):
		gorus.durum_yukle(d["gorus"])
	takip_birak()
	if slot != "oto":
		KY.aktif = slot
	_son_oto = int(oyun.t / (oyun.DAY * 10))
	oyun.kayit("Kayıt yüklendi (%s)." % KY.ad(slot), "good")

# Her oyun ayında (10 gün) otomatik kayıt; kart/panel açıkken veya öldüyken yazılmaz.
func _oto_kayit() -> void:
	var ay: int = int(oyun.t / (oyun.DAY * 10))
	if _son_oto < 0:
		_son_oto = ay
		return
	if ay != _son_oto and not arayuz.modal and oyun.son.is_empty():
		_son_oto = ay
		kaydet("oto")

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

var _dur: Node
var _env: Environment
var _gunes: DirectionalLight3D
var _hover_sure := 0.0
var _gh: Dictionary = {}
var _hi := -1
var _bs: Node3D   # bina simgeleri (simge tıklama + bina vurgusu)

func _duraklat_menu() -> void:
	if _dur != null:
		return
	_dur = load("res://scripts/ui/duraklat.gd").new()
	add_child(_dur)
	modal_duraklat(true)
	_dur.kur(self)
	_dur.tree_exited.connect(func():
		_dur = null
		modal_duraklat(false))

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
		var ik: int = _bs.ikon_isinla(e.position)   # bina simgesine tıklamak binaya tıklamakla aynı
		var gt: Dictionary = gruplar.isinla(o, n) if ik < 0 else {}
		if not gt.is_empty():
			_gir_bina = -1
			takip_ver(gt)   # gruba tıkla: kovala, yetişince karşılaşma diyaloğu açılır
			return
		takip_birak()
		var i: int = ik if ik >= 0 else harita.yer_isinla(o, n)
		if i >= 0:
			if oyuncu.iceride == i:
				arayuz.bina_ac(i)
			else:
				oyuncu.git(harita.yerler[i]["pos"])   # binaya tıkla: önüne git, varınca içeri gir
				_gir_bina = i
		else:
			_gir_bina = -1
			var nokta = harita.arazi_isinla(o, n)
			if nokta != null:
				oyuncu.git(nokta)
	elif e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_RIGHT:
		# sağ tık (sürüklemeden): binanın bilgilerini aç; sürükleme kamerayı döndürür
		if e.pressed:
			_sag_basla = e.position
		elif e.position.distance_to(_sag_basla) < 6.0:
			var k2: Camera3D = kamera.kamera()
			var ik2: int = _bs.ikon_isinla(e.position)
			var g2: Dictionary = gruplar.isinla(k2.project_ray_origin(e.position), k2.project_ray_normal(e.position)) if ik2 < 0 else {}
			if not g2.is_empty() and not g2.has("sakin"):
				arayuz.grup_ac(g2)
				return
			var i2: int = ik2 if ik2 >= 0 else harita.yer_isinla(k2.project_ray_origin(e.position), k2.project_ray_normal(e.position))
			if i2 >= 0:
				arayuz.bina_ac(i2)
	elif e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_SPACE: Engine.time_scale = 0.0 if Engine.time_scale > 0.0 else _hiz
			KEY_1: hiz_ayarla(1.0)
			KEY_2: hiz_ayarla(2.0)
			KEY_3: hiz_ayarla(4.0)
			KEY_H:
				if oyun._ev >= 0:
					oyuncu.git(harita.serbest_nokta(oyun.harita.yerler[oyun._ev]["pos"]))
					_gir_bina = oyun._ev
			KEY_B: arayuz._bolge_dugmesi()
			KEY_T: arayuz.adamlar_ac()
			KEY_F: arayuz.defter_ac()
			KEY_G: arayuz.silah_ac()
			KEY_Y: arayuz.yetenek_ac()
			KEY_V:
				gorus.acik = not gorus.acik
				gorus.guncelle()
				gorus._gorunurluk()
			KEY_K: arayuz.aile_ac()
			KEY_ESCAPE:
				if oyuncu.iceride >= 0:
					oyuncu.cik()
					arayuz.kapat()
				elif arayuz._sag.visible:
					arayuz.kapat()
				else:
					_duraklat_menu()
			KEY_F11:
				var tam := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
				DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if tam else DisplayServer.WINDOW_MODE_FULLSCREEN)
			KEY_F6: kaydet()
			KEY_F9: yukle()

var _gir_bina := -1
var _sag_basla := Vector2.ZERO

func _process(delta: float) -> void:
	_oto_kayit()
	if _gir_bina >= 0 and oyuncu.iceride < 0 and arayuz.yakin_bina(_gir_bina):
		oyuncu.gir(_gir_bina)
		arayuz.bina_ac(_gir_bina)
		_gir_bina = -1
	_fps.text = "%d FPS" % Engine.get_frames_per_second()
	# Hızlı oynatmada fizik adımı sayısı time_scale ile çarpılır; adım sıklığını düşürerek gerçek adım/sn'yi 60'ta tut.
	var tps := clampi(roundi(60.0 / maxf(Engine.time_scale, 1.0)), 15, 60)
	if Engine.physics_ticks_per_second != tps:
		Engine.physics_ticks_per_second = tps
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
	# kalite: uzaktan bakarken SSAO ve gölge gereksiz (ve pahalı)
	_hava_guncelle(delta)
	_atmosfer()
	var uz: float = kamera.mesafe
	_env.ssao_enabled = false
	_gunes.shadow_enabled = uz < 260.0
	_gunes.directional_shadow_max_distance = clampf(uz * 2.2, 120.0, 400.0)
	# fare altındakini bulmak (1000 bina üstünde ışın testi) her karede değil, kısa aralıkla
	_hover_sure -= delta
	if _hover_sure <= 0.0:
		_hover_sure = 0.08
		var k: Camera3D = kamera.kamera()
		var fp := get_viewport().get_mouse_position()
		_gh = gruplar.isinla(k.project_ray_origin(fp), k.project_ray_normal(fp))
		_hi = harita.yer_isinla(k.project_ray_origin(fp), k.project_ray_normal(fp))
	var gh: Dictionary = _gh
	var i: int = _hi
	if _bs.hover_i >= 0:
		i = _bs.hover_i   # fare bir simgenin üstündeyse o bina
		gh = {}
	# tıklanabilir şeyin üstünde: bina hattı + el imleci
	var tikla_i: int = -1 if (arayuz.modal or savas_aktif) else (i if gh.is_empty() else -1)
	_bs.vurgula(tikla_i)
	_bs.dis_i = tikla_i
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND if (tikla_i >= 0 or (not gh.is_empty() and not arayuz.modal)) else Input.CURSOR_ARROW)
	_oy_etiket.visible = oyuncu.iceride < 0
	oyun.ic_mekan = oyuncu.iceride
	var yz := "%s · %d kişi" % [oyun.profil.get("ad", "Sen"), 1 + oyun.adamlar.size()]
	if yz != _oy_yz:
		_oy_yz = yz
		_oy_etiket.text = yz
		var w: float = load("res://scripts/ui/tema.gd").yazi_tipi().get_string_size(yz, HORIZONTAL_ALIGNMENT_LEFT, -1, _oy_etiket.font_size).x
		_oy_plaka.texture = load("res://scripts/core/gruplar.gd")._plaka_tex(int(w) + 40, int(_oy_etiket.font_size * 1.55), Color("c9a14a"))
	oyuncu.kilitli = not oyun.vardiya.is_empty()
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
	var m: Node3D = load("res://scripts/core/cubuk.gd").kisi(Color(0.25, 0.45, 0.85))
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

const GOKYUZU_SHADER := """
shader_type sky;
uniform vec3 ust : source_color = vec3(0.3, 0.5, 0.8);
uniform vec3 ufuk : source_color = vec3(0.8, 0.85, 0.9);
uniform vec3 bulut : source_color = vec3(1.0);
uniform float orttu = 0.4;
uniform float koyu = 0.0;
uniform vec2 kayma = vec2(0.0);
float h(vec2 p){ return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float n(vec2 p){ vec2 i = floor(p); vec2 f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h(i), h(i + vec2(1.0, 0.0)), f.x), mix(h(i + vec2(0.0, 1.0)), h(i + vec2(1.0, 1.0)), f.x), f.y); }
float fbm(vec2 p){ float v = 0.0; float a = 0.5; for (int i = 0; i < 5; i++) { v += a * n(p); p = p * 2.03 + vec2(7.1, 3.3); a *= 0.5; } return v; }
void sky() {
	vec3 d = EYEDIR;
	float y = d.y;
	vec3 col = mix(ufuk, ust, smoothstep(0.0, 0.55, y));
	if (y < 0.0) col = mix(ufuk, ufuk * 0.45, clamp(-y * 3.0, 0.0, 1.0));
	if (y > 0.0) {
		vec2 uv = d.xz / (y + 0.22) * 1.3 + kayma;
		float c = fbm(uv);
		float esik = 1.0 - orttu;
		float m = smoothstep(esik - 0.05, esik + 0.28, c);
		m *= smoothstep(0.0, 0.16, y);
		vec3 bc = bulut * (1.0 - koyu * 0.6);
		float alt = smoothstep(esik, esik + 0.4, c);
		bc = mix(bc, bc * 0.62, alt * (0.35 + koyu * 0.5));
		col = mix(col, bc, m * 0.92);
	}
	COLOR = col;
}
""";

var _hava_yag: GPUParticles3D
var _hava_tur := ""
var _bulut_x := 0.0
var _orttu_g := 0.4
var _yog_g := 0.0

func _hava_kur() -> void:
	_hava_yag = GPUParticles3D.new()
	_hava_yag.amount = 4000
	_hava_yag.lifetime = 1.3
	_hava_yag.visibility_aabb = AABB(Vector3(-120, -80, -120), Vector3(240, 160, 240))
	_hava_yag.local_coords = false
	_hava_yag.emitting = false
	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = Vector3(70, 1, 70)
	pm.direction = Vector3(0.12, -1, 0.05)
	pm.spread = 3.0
	pm.initial_velocity_min = 55.0
	pm.initial_velocity_max = 70.0
	pm.gravity = Vector3.ZERO
	_hava_yag.process_material = pm
	var q := QuadMesh.new()
	q.size = Vector2(0.07, 1.6)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.75, 0.82, 0.95, 0.5)
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	q.material = mat
	_hava_yag.draw_pass_1 = q
	kamera.add_child(_hava_yag)
	_hava_yag.top_level = true

func _hava_guncelle(dt: float) -> void:
	var hv: Dictionary = oyun.hava()
	_orttu_g = lerpf(_orttu_g, float(hv["orttu"]), 1.0 - exp(-0.4 * dt))
	_yog_g = lerpf(_yog_g, float(hv["yog"]), 1.0 - exp(-0.6 * dt))
	_bulut_x += dt * 0.004
	var sky: ShaderMaterial = _env.sky.sky_material
	sky.set_shader_parameter("orttu", _orttu_g)
	sky.set_shader_parameter("koyu", clampf(_orttu_g - 0.4, 0.0, 1.0) * (1.0 if hv["tur"] != "bulutlu" else 0.5) + _yog_g * 0.3)
	sky.set_shader_parameter("kayma", Vector2(_bulut_x, _bulut_x * 0.3))
	var tur: String = hv["tur"]
	var yagiyor: bool = (tur == "yagmur" or tur == "kar") and _yog_g > 0.05
	if _hava_yag != null:
		if tur != _hava_tur:
			_hava_tur = tur
			var pm: ParticleProcessMaterial = _hava_yag.process_material
			var q: QuadMesh = _hava_yag.draw_pass_1
			if tur == "kar":
				pm.initial_velocity_min = 5.0
				pm.initial_velocity_max = 9.0
				pm.direction = Vector3(0.1, -1, 0.1)
				pm.spread = 25.0
				q.size = Vector2(0.28, 0.28)
				_hava_yag.lifetime = 9.0
				_hava_yag.amount = 5000
			else:
				pm.initial_velocity_min = 55.0
				pm.initial_velocity_max = 70.0
				pm.direction = Vector3(0.12, -1, 0.05)
				pm.spread = 3.0
				q.size = Vector2(0.07, 1.6)
				_hava_yag.lifetime = 1.3
				_hava_yag.amount = 4000
		_hava_yag.emitting = yagiyor and kamera.mesafe < 220.0
		_hava_yag.global_position = kamera.global_position + Vector3(0, 70 if tur == "yagmur" else 60, 0)
		_hava_yag.amount_ratio = clampf(_yog_g, 0.1, 1.0)

func _cevre() -> void:
	var sky := ShaderMaterial.new()
	var sh := Shader.new()
	sh.code = GOKYUZU_SHADER
	sky.shader = sh
	var s := Sky.new()
	s.radiance_size = Sky.RADIANCE_SIZE_64
	s.sky_material = sky
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = s
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = false
	env.fog_enabled = true
	env.fog_density = 0.0004
	env.glow_enabled = true
	env.glow_intensity = 0.8
	env.glow_bloom = 0.12
	env.glow_hdr_threshold = 0.9
	env.adjustment_enabled = true
	env.adjustment_saturation = 0.86   # 1.15 idi; ~%25 düşük
	env.adjustment_contrast = 1.08
	_env = env
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-50, -30, 0)
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 400.0
	_gunes = sun
	add_child(sun)

# Günün saatine göre gökyüzü/ışık/sis rengi: şafak turuncu, öğle soluk, akşam kızıl, gece lacivert + sıcak lamba parıltısı.
const _ANAHTAR := [
	# saat, gökyüzü üstü, ufuk, güneş rengi, güneş gücü, sis, ortam gücü
	[0.0, Color("0b1226"), Color("1b2440"), Color("6f86c8"), 0.25, Color("141c33"), 0.55],
	[5.0, Color("1c2a4a"), Color("7a5a5a"), Color("ffb070"), 0.5, Color("5a4a56"), 0.6],
	[7.0, Color("5d86b8"), Color("e6b98a"), Color("ffd2a0"), 1.0, Color("b9a58f"), 0.8],
	[12.0, Color("5f93c9"), Color("c9d6dc"), Color("fff0d8"), 1.25, Color("b7c3c8"), 0.95],
	[17.0, Color("486a99"), Color("e69a62"), Color("ffb060"), 1.0, Color("c08f6a"), 0.8],
	[19.5, Color("1e2748"), Color("a24f3c"), Color("ff7a48"), 0.5, Color("5a3a40"), 0.6],
	[21.5, Color("0b1226"), Color("1b2440"), Color("6f86c8"), 0.25, Color("141c33"), 0.55],
	[24.0, Color("0b1226"), Color("1b2440"), Color("6f86c8"), 0.25, Color("141c33"), 0.55],
]
var _atm_sure := 0.0

func _atmosfer() -> void:
	if oyun == null:
		return
	var h: float = fmod(float(oyun.t), float(oyun.DAY)) / 60.0
	var a: Array = _ANAHTAR[0]
	var b: Array = _ANAHTAR[1]
	for i in _ANAHTAR.size() - 1:
		if h >= _ANAHTAR[i][0] and h <= _ANAHTAR[i + 1][0]:
			a = _ANAHTAR[i]
			b = _ANAHTAR[i + 1]
			break
	var k: float = (h - float(a[0])) / maxf(0.001, float(b[0]) - float(a[0]))
	var sky: ShaderMaterial = _env.sky.sky_material
	var ust: Color = (a[1] as Color).lerp(b[1], k)
	var ufuk: Color = (a[2] as Color).lerp(b[2], k)
	var kapali: float = clampf((_orttu_g - 0.4) / 0.5, 0.0, 1.0)   # bulutlu/yağışlı: gök gri, güneş zayıf
	var gri: Color = Color(0.5, 0.54, 0.6) * clampf(float(a[4]) * 0.6 + 0.15, 0.2, 0.9)
	ust = ust.lerp(gri.lerp(ust, 0.25), kapali * 0.75)
	ufuk = ufuk.lerp(gri.lerp(ufuk, 0.3), kapali * 0.75)
	sky.set_shader_parameter("ust", ust)
	sky.set_shader_parameter("ufuk", ufuk)
	var gunes_g: float = lerpf(float(a[4]), float(b[4]), k)
	sky.set_shader_parameter("bulut", Color(0.25, 0.27, 0.32).lerp(Color(1.0, 0.97, 0.94), clampf(gunes_g / 1.1, 0.0, 1.0)).lerp(ufuk, 0.25))
	_gunes.light_color = (a[3] as Color).lerp(b[3], k)
	_gunes.light_energy = gunes_g * (1.0 - 0.6 * kapali)
	_env.fog_light_color = ((a[5] as Color).lerp(b[5], k)).lerp(ufuk, kapali * 0.5)
	_env.fog_density = 0.0004 + 0.0009 * _yog_g
	_env.ambient_light_color = ust.lerp(ufuk, 0.5)
	_env.ambient_light_energy = lerpf(float(a[6]), float(b[6]), k)
	# gece lamba havuzları: güneş zayıfladıkça belirir
	var gece: float = clampf((0.8 - float(_gunes.light_energy)) / 0.55, 0.0, 1.0)
	if harita.has_meta("lamba_mat"):
		var lm: Array = harita.get_meta("lamba_mat")
		(lm[0] as StandardMaterial3D).albedo_color = Color(1, 1, 1, gece * 0.28)
		(lm[1] as StandardMaterial3D).albedo_color = Color(1, 1, 1, gece * 0.6)
	# güneş alçak: sabah/akşam uzun gölge
	_gunes.rotation_degrees.x = -lerpf(25.0, 60.0, clampf(float(_gunes.light_energy) / 1.25, 0.0, 1.0))

func _aile_testi() -> void:
	for f in oyun.NPC:
		print(f, ": ", oyun.aile_uyeleri(f).map(func(u): return oyun.uye_ad(u)))
	var don: Dictionary = oyun.aile_uyeleri("marchetti")[0]
	print("don oluyor: ", oyun.uye_oldu(don["uid"]))
	await get_tree().create_timer(1.0).timeout
	print("yeni: ", oyun.aile_uyeleri("marchetti").map(func(u): return oyun.uye_ad(u)))
	print("gruplar: ", gruplar.liste.filter(func(g): return g["tur"] == "rakip").map(func(g): return g["ad"]))
	arayuz.aile_ac()

func _isletme_testi(ekran: bool) -> void:
	oyun.temiz = 20000.0
	oyun.kirli = 5000.0
	for f in oyun.NPC:
		oyun.ofke[f] = 60.0
	var sec := -1
	for i in oyun.isy:
		if oyun.isy[i]["tur"] == "eglence":
			sec = i
			break
	oyun.bolge[oyun.harita.yerler[sec]["bolge"]]["inf"]["oyuncu"] = 50.0
	print("satin al: ", oyun.satin_al(sec))
	for k in 2:
		print("tut: ", oyun.isl.tut(sec, true))
	oyun.isy[sec]["personel"][0]["ajan"] = "marchetti"
	oyun.isl.muhbir_ayarla("marchetti", 2)
	oyun.isl.muhbir_ayarla("obrien", 1)
	for g in 300:
		oyun.t += oyun.DAY
		oyun._gun()
		if g % 10 == 9:
			oyun._ay()
		var r: Dictionary = oyun.isy[sec]
		if r["personel"].size() < 2:
			oyun.isl.tut(sec, true)
	print("itibar ", oyun.isy[sec]["itibar"], " gelir ", oyun.isl.gelir_yazi(sec), " temiz ", int(oyun.temiz))
	for e in oyun.defter:
		print(e["metin"])
	if ekran:
		oyun.isy[sec]["personel"][0]["supheli"] = 80
		arayuz.bina_ac(sec)

# Test: --ekran=yol.png[,ben|bina] -> 7 sn sonra oyun görüntüsünü kaydeder ve kapanır (isteğe bağlı panel açar).
func _ekran_cek(arg: String) -> void:
	var p := arg.split(",")
	await get_tree().create_timer(7.0, true, false, true).timeout
	if p.size() > 1:
		if p[1] == "ben":
			arayuz.ben_ac()
		elif p[1] == "adam":
			oyun.adamlar.append({"id": 91, "ad": "Joe Moretti", "yumruk": 70, "bicak": 55, "zeka": 60, "gorev": "", "silah": "bicak", "sadakat": 75})
			arayuz.adamlar_ac()
		elif p[1] == "aile":
			arayuz.aile_ac()
		elif p[1] == "ev":
			oyuncu.gir(oyun._ev)
			arayuz.bina_ac(oyun._ev)
		elif p[1] == "bar":
			oyun.temiz = 500.0
			oyuncu.gir(97)
			arayuz.bina_ac(97)
		elif p[1] == "pie":
			for c in arayuz.get_children():
				if c.has_method("hepsini_ac"):
					c.hepsini_ac()
		elif p[1] == "bina":
			oyun.temiz = 500.0
			arayuz.bina_ac(97)
		elif p[1] == "meslek":
			arayuz.meslek_ac()
		elif p[1] == "polis":
			arayuz.polis_ac()
		elif p[1] == "garaj":
			arayuz.garaj_ac()
		elif p[1] == "silah":
			oyun.sil_k.ver("tommy", "ganimet", "Vito'nun Tommy'si", "Vito Marchetti'yi yendiğinin kanıtı.", 30.0, "marchetti")
			oyun.sil_k.al("pompali")
			arayuz._sil_acik = 1
			arayuz.silah_ac()
		elif p[1] == "yetenek":
			arayuz.yetenek_ac()
		elif p[1] == "kotu":
			oyun.kirli += 800.0
			oyun.kotu_k.tefeci_al(500.0)
			for i in 4:
				print(oyun.kotu_k.kumar(50.0))
			print(oyun.kotu_k.soygun())
			oyun.kotu_k.hapis(35, "Test")
			print(oyun.kotu, oyun.nuf, oyun.t)
			arayuz.nufuz_ac()
		elif p[1] == "nufuz":
			oyun.kirli += 5000.0
			oyun.temiz += 15000.0
			oyun.nuf["fed"] = 40.0
			oyun.nuf_k.rusvet_ver("polis")
			oyun.nuf_k.mal_al()
			oyun.adamlar.append({"id": 99, "ad": "Test Adam", "yumruk": 5, "bicak": 5, "zeka": 5, "gorev": "", "sadakat": 20.0})
			arayuz.nufuz_ac()
		elif p[1] == "miras2":
			oyun.kisi_k.test_hazirla()
			oyun.ol("Test")
			print(oyun.kisi_k.miras_al(int(oyun.kisi_k.cocuklar()[0]["id"])))
			arayuz.ailem_ac()
		elif p[1] == "senaryo":
			var U: RefCounted = oyun.un_k
			# 1) Baba: zengin, korkulan, sayılan
			oyun.temiz = 30000.0
			oyun.yol["puan"]["korku"] = 60.0
			oyun.un["saygi"] = 50.0
			print("BABA: ", U.tip()["ad"], " servet=", int(U.deger("servet")))
			# 2) Saygın iş adamı: zengin, sevilen, korkusuz
			oyun.yol["puan"]["korku"] = 0.0
			oyun.un["sevgi"] = 60.0
			print("IS ADAMI: ", U.tip()["ad"])
			# 3) Rezil haraççı: fakir, haraçlı, saygısız, dikkat çekiyor
			oyun.temiz = 150.0
			oyun.un["sevgi"] = 0.0
			oyun.un["saygi"] = -20.0
			oyun.arama = 40.0
			var n := 0
			for i in oyun.isy:
				if n < 2:
					oyun.isy[i]["haracli"] = true
					n += 1
			print("REZIL: ", U.tip()["ad"], " saygi=", int(U.deger("saygi")), " dikkat=", int(U.deger("dikkat")))
		elif p[1] == "kaz":
			oyun.arama = 99.0
			oyun.polis.kanit(5.0, "t")
			oyun.nuf["fed"] = 100.0
			oyun.borc["taksit"] = 150.0
			oyun.kirli = 1000.0
			oyun.nuf_k.gun()
			oyun.borc["ana"] = 100.0
			oyun.temiz = 0.0
			for i in 3:
				oyun.borc_k.ay()
			print("SON=", oyun.son, " KAZ=", oyun.kaz.keys())
			arayuz.kazanim_ac()
		elif p[1] == "oynat":
			var KK = oyun.kart_k
			var say: Dictionary = {}
			var sv_say: Dictionary = {}
			var bn2 := 0
			var yilmax := 12
			var dip: bool = p.size() > 2 and p[2] == "dip"
			var zinc: Dictionary = {}
			if dip:
				oyun.temiz = 100.0
				oyun.kotu["rezil"] = 30.0
				oyun.kotu["tef"] = 400.0
				oyun.un["saygi"] = -10.0
				yilmax = 6
			for adm in 360 * yilmax:
				oyun.ilerle(60.0)
				var yil: int = oyun.t / 172800
				if adm % 6 == 0:
					oyun.kis["agir"] = 0.0
					oyun.kis["hasta"] = 0
					oyun.kis["aclik"] = 20.0
					oyun.kis["yorgun"] = 20.0
				if not oyun.son.is_empty():
					print("OLUM yil=", yil, " ", str(oyun.son.get("metin", "")).substr(0, 60))
					break
				if not oyun.yol.get("zincir", []).is_empty() and adm % 360 == 0:
					print("ZINCIR_BEKLEYEN ", oyun.yol["zincir"])
				# kademeli ilerleme (elle oynayan oyuncu yerine)
				if adm % 360 == 0:
					if yil == 3:
						oyun.temiz += 3000.0
						for bid in oyun.bolge:
							if bn2 < 1:
								oyun.add_inf(oyun.bolge[bid], "oyuncu", 100.0)
								bn2 += 1
					if yil == 6:
						oyun.temiz += 20000.0
						for bid in oyun.bolge:
							if bn2 < 3:
								oyun.add_inf(oyun.bolge[bid], "oyuncu", 100.0)
								bn2 += 1
					if yil == 9:
						oyun.temiz += 40000.0
						for bid in oyun.bolge:
							if bn2 < 5:
								oyun.add_inf(oyun.bolge[bid], "oyuncu", 100.0)
								bn2 += 1
				var bk: String = oyun.yol["bekleyen"]
				if bk != "" and oyun.t >= oyun.yol.get("acilis", 0):
					KK.hazirla(bk)
					var opts: Array = KK.secenekler(bk)
					var ok_i: Array = []
					for oi in opts.size():
						if opts[oi]["can"]:
							ok_i.append(oi)
					var sec: int = ok_i[oyun.rng.randi() % ok_i.size()] if not ok_i.is_empty() else 0
					KK.uygula(bk, sec)
					say[bk] = say.get(bk, 0) + 1
					if bk.begins_with("z"):
						print("ZINCIR_GELDI ", bk, " yil=", yil)
					var lvk := "L" + str(KK.seviye())
					sv_say[lvk] = sv_say.get(lvk, 0) + 1
					if not KK.OL.var_mi(bk) and false:
						pass
				if adm % 360 == 359:
					print("YIL ", yil, " L", KK.seviye(), " temiz=", int(oyun.temiz), " arama=", int(oyun.arama), " olay_toplam=", say.size())
			var yeni: Array = []
			var eski: Array = []
			for id in say:
				if KK.OL.var_mi(id):
					yeni.append(id + "x" + str(say[id]))
				else:
					eski.append(id + "x" + str(say[id]))
			print("SEVIYE_DAGILIM ", sv_say)
			print("YENI ", yeni)
			print("ESKI ", eski)
			print("OYNAT_BITTI")
		elif p[1] == "kayit":
			kaydet("2")
			oyun.t += 172800 * 3
			oyun.temiz = 8200.0
			kaydet("4")
			oyun.t += 14400
			var kpn: CanvasLayer = load("res://scripts/ui/kayit_paneli.gd").new()
			add_child(kpn)
			kpn.kur("yukle", func(sl: String): pass)
			print("OTO_VAR=", FileAccess.file_exists("user://oto.dat"))
		elif p[1] == "kimler":
			var bi := -1
			for k in oyun.isy:
				if oyun.kontrol(k) in ["marchetti", "obrien", "tammany"]:
					bi = k
					break
			if bi < 0:
				bi = oyun.isy.keys()[0]
			gorus.acik = false
			arayuz.bina_ac(bi)
		elif p[1] == "rakipsim":
			oyun.mesaj.connect(func(m: String, _t: String): print("  [", oyun.t / 17280, "ay] ", m))
			for ay in 120:
				oyun.t += oyun.DAY * 10
				oyun._ay()
				if ay % 24 == 23:
					print("=== ", ay / 12 + 1, ". yil")
					for f in oyun.NPC:
						print(f, ": ", oyun.rakip_k.ozet(f), " | ", oyun.aile_uyeleri(f).map(func(u): return oyun.uye_ad(u)))
		elif p[1] == "kadro":
			for u in oyun.uyeler:
				print("KADRO ", oyun.uye_ad(u))
		elif p[1] == "olay2":
			var OLY = oyun.kart_k.OL
			var bn := 0
			for bid in oyun.bolge:
				if bn < 4:
					oyun.add_inf(oyun.bolge[bid], "oyuncu", 100.0)
					bn += 1
			oyun.temiz = 40000.0
			oyun.un["saygi"] = 60.0
			oyun.yol["puan"]["korku"] = 60.0
			print("DON seviye=", oyun.kart_k.seviye())
			var sat2: Array = []
			for id in OLY.liste:
				var w2: float = OLY.agirlik(id)
				if w2 > 0.0:
					sat2.append(id + ":" + str(snappedf(w2, 0.1)))
			print("DON uygun=", sat2.size(), " ", sat2)
			arayuz.kart_ac("d04")
		elif p[1] == "olay":
			var OLX = oyun.kart_k.OL
			print("OLAY_SAYI=", OLX.liste.size())
			for sen in ["cocuk", "don"]:
				if sen == "don":
					oyun.kisi_k.test_hazirla()
					oyun.temiz = 30000.0
					oyun.un["saygi"] = 60.0
				var sat: Array = []
				for id in OLX.liste:
					var w: float = OLX.agirlik(id)
					if w > 0.0:
						sat.append(id + ":" + str(snappedf(w, 0.1)))
				print("SEN ", sen, " uygun=", sat.size(), " ", sat)
		elif p[1] == "ozet2":
			oyun.kisi_k.test_hazirla()
			oyun.aile["gecmis"] = [{"ad": "Vito", "tip": "Sokak haraççısı", "yas": 58}, {"ad": "Enzo", "tip": "Baba", "yas": 66}]
			oyun.aile["nesil"] = 3
			oyun.t = 172800 * 41
			oyun.temiz = 38000.0
			oyun.yol["puan"]["korku"] = 62.0
			oyun.un["saygi"] = 55.0
			oyun.un["sevgi"] = 20.0
			oyun.arama = 30.0
			oyun.kotu["hapis_say"] = 2
			for kid in ["baskan", "hakim", "hapis", "evlilik", "cocuk", "malikane", "nesil", "nesil3", "baba", "dava", "federal"]:
				oyun.kaz[kid] = 1
			oyun.kisi_k.cocuklar().clear()
			for k in oyun.aile["kisiler"]:
				k["olu"] = true
			oyun.ol("Yetmiş yaşında, malikânesinin bahçesinde kalbi durdu.")
		elif p[1] == "ozet":
			oyun.kisi_k.test_hazirla()
			oyun.kisi_k.cocuklar().clear()
			for k in oyun.aile["kisiler"]:
				k["olu"] = true
			oyun.ol("Test: uykunda gitti.")
		elif p[1] == "miras":
			oyun.kisi_k.test_hazirla()
			oyun.ol("Test: yıllara yenik düştün.")
		elif p[1] == "ailem":
			oyun.aile_k.koken_sec("italyan")
			oyun.aile_k.inanc_sec("dindar")
			oyun.aile_k.deger_sec("sert_merhamet", "sol")
			oyun.aile_k.gelenek_sec(0, "kan_bagi")
			oyun.aile_k.gelenek_sec(1, "omerta")
			arayuz.ailem_ac()
		elif p[1] == "defter":
			arayuz.defter_ac()
		elif p[1] == "zafer":
			arayuz.zafer_ac()
		elif p[1].begins_with("grup_"):
			var gt: String = p[1].substr(5)
			for g3 in gruplar.liste:
				if g3["tur"] == gt:
					arayuz.grup_ac(g3)
					break
		elif p[1] == "yaya" or p[1] == "araba":
			kamera.mesafe = 45.0
			for dn in 90:
				await get_tree().process_frame
				if dn > 20 and (get_node("Yayalar") as Node3D).test_hedef(p[1] == "araba"):
					break
		elif p[1] == "kavsak":
			var tr: Node = (get_node("Yayalar") as Node).trafik
			var en := 1e9
			for j in tr._kav:
				var dd: float = (j["p"] as Vector2).distance_to(Vector2(oyuncu.global_position.x, oyuncu.global_position.z))
				if dd < en:
					en = dd
					oyuncu.global_position = Vector3(j["p"].x, harita.yuk(j["p"].x, j["p"].y), j["p"].y)
			kamera.mesafe = 22.0
			kamera._pitch = -0.6
			await get_tree().create_timer(1.0, true, false, true).timeout
		elif p[1] == "binafoto":
			var yb: Dictionary = harita.yerler[0]
			for yy in harita.yerler:
				if yy["ad"] == OS.get_environment("BINA_AD") or (yy["ad"] == "Sailors Bar" and OS.get_environment("BINA_AD") == ""):
					yb = yy
			oyuncu.global_position = yb["pos"]
			kamera.rotation.y = float(p[2]) if p.size() > 2 else 0.0
			kamera.mesafe = 30.0
			kamera._pitch = float(OS.get_environment("BINA_PITCH")) if OS.get_environment("BINA_PITCH") != "" else -0.35
			await get_tree().create_timer(1.0, true, false, true).timeout
		elif p[1] == "savas":
			var gs: Dictionary = {}
			for x in gruplar.liste:
				if x["tur"] == "rakip":
					gs = x
					break
			gs["kisi"] = 4
			oyun.adam_tut()
			oyun.adam_tut()
			savas_baslat(gs, 1.0, func(_s): pass, p[2] if p.size() > 2 else "sokak", false)
			await get_tree().create_timer(1.0, true, false, true).timeout
		elif p[1] == "bolge":
			arayuz.bolge_ac("southside")
		await get_tree().create_timer(1.5, true, false, true).timeout
	get_viewport().get_texture().get_image().save_png(p[0])
	get_tree().quit()
