extends Node3D
# Bina simgeleri: her binanın işlevini gösteren yuvarlak simge (uzaktan görünür) ve yakında kâğıt şerit üstünde adı.
# Bizim olan yerler (ev, işletmeler) uzaktan da hep görünür.
const Tema := preload("res://scripts/ui/tema.gd")
const Pazar := preload("res://scripts/core/pazar.gd")

# kategori -> [glif, halka rengi, açıklama]
const KAT := {
	"ev": ["⌂", Color("f0cf7a"), "Evin"],
	"gelir": ["$", Color("8fd08a"), "Senin işletmen"],
	"yemek": ["♨", Color("e8955a"), "Yemek"],
	"konak": ["☾", Color("8aa6e0"), "Konaklama"],
	"adam": ["♞", Color("d86a6a"), "Adam bulunur"],
	"is": ["⚒", Color("c9b08a"), "İş yeri"],
	"resmi": ["⚖", Color("9aa0aa"), "Resmî kurum"],
	"ozel": ["★", Color("e6c45a"), "Özel mekân"],
}
const IKON := {"ev": "bina_ev", "gelir": "bina_gelir", "yemek": "bina_yemek", "konak": "bina_ev", "adam": "bina_adam", "is": "is", "resmi": "polis", "ozel": "bina_ozel"}
const YEMEK := ["diner", "soda", "cafe", "restaurant", "bakery", "deli", "grill", "oyster", "kitchen", "tavern"]
const KONAK := ["hotel", "boarding", "tenement", "mansion", "inn", "pension", "lodging"]

var oyun: Node
var harita: Node
var kamera: Node
var _pazar: RefCounted
var _ogeler: Array = []   # {i, kok, simge, glif, serit, serit_l, kat}
var _tex: Dictionary = {}
var _sure := 0.0
var _olcek := -1.0
var hover_i := -1          # fare altındaki simgenin bina indeksi (yoksa -1)
var _hov_k := -1
var _vurgulu := -1
var _dugum: Dictionary = {}   # bina indeksi -> bina düğümü

func kur(o: Node, h: Node, ka: Node) -> void:
	oyun = o
	harita = h
	kamera = ka
	_pazar = Pazar.new(oyun)
	_kagit_kur()
	var by: Dictionary = {}
	for n in get_tree().get_nodes_in_group("bina"):
		if not n.dolgu:
			by[n.global_position] = n
	for i in harita.yerler.size():
		var y: Dictionary = harita.yerler[i]
		if not by.has(y["pos"]):
			continue
		var n: Node3D = by[y["pos"]]
		_oge_kur(i, n)
	_guncelle()

func kategori(i: int) -> String:
	var ad := String(harita.yerler[i]["ad"]).to_lower()
	if i == oyun._ev:
		return "ev"
	if oyun.isy.has(i) and oyun.isy[i]["sahip"]:
		return "gelir"
	if _pazar.site_mi(i):
		return "adam"
	for k in YEMEK:
		if ad.contains(k):
			return "yemek"
	for k in KONAK:
		if ad.contains(k):
			return "konak"
	if oyun.isy.has(i):
		return "resmi" if oyun.isy[i]["tur"] == "resmi" else "is"
	return "ozel" if harita.yerler[i]["ozel"] else "resmi"

func _bina_ikonu(ad: String, kat: String) -> Texture2D:
	var k := String(ad).to_lower()
	for p in [["ı", "i"], ["'", ""], ["&", ""]]:
		k = k.replace(p[0], p[1])
	var s := ""
	for ch in k:
		s += ch if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") else "_"
	while s.contains("__"):
		s = s.replace("__", "_")
	s = s.trim_prefix("_").trim_suffix("_")
	var adaylar := [s, s.trim_suffix("_iii").trim_suffix("_ii")]
	if s.begins_with("tool_"):
		adaylar.append("tool_die")
	for a in adaylar:
		var yol := "res://assets/ui/bina/%s.png" % a
		if ResourceLoader.exists(yol):
			return _gri(yol)
	return _gri("res://assets/ui/icons/%s.png" % IKON[kat])

# Siyah-beyaz baskı rozeti: krem kâğıt daire, alt yarıda yarım ton noktalar, kalın siyah halka.
func _rozet(_renk: Color) -> ImageTexture:
	if _tex.has("bw"):
		return _tex["bw"]
	var N := 96
	var im := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := Vector2(N / 2.0 - 0.5, N / 2.0 - 0.5)
	var kagit := Color("efe4c6")
	var murekkep := Color("14110d")
	for x in N:
		for y in N:
			var d: float = Vector2(x, y).distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d < 47.0:
				col = kagit
				# yarım ton: aşağı doğru büyüyen noktalar
				var t: float = clampf((y - N * 0.3) / (N * 0.7), 0.0, 1.0)
				if t > 0.0 and d < 40.0:
					var gx := fposmod(x, 4.0) - 2.0
					var gy := fposmod(y, 4.0) - 2.0
					if sqrt(gx * gx + gy * gy) < t * 1.9:
						col = Color("8c8372")
			if d >= 41.5 and d < 45.0:
				col = murekkep
			elif d >= 45.0 and d < 47.0:
				col = Color(0, 0, 0, 0.0) if d >= 46.5 else murekkep
			im.set_pixel(x, y, col)
	var t2 := ImageTexture.create_from_image(im)
	_tex["bw"] = t2
	return t2

func _gri(yol: String) -> Texture2D:
	if _tex.has(yol):
		return _tex[yol]
	var im: Image = (load(yol) as Texture2D).get_image()
	if im.is_compressed():
		im.decompress()
	im.convert(Image.FORMAT_RGBA8)
	for x in im.get_width():
		for y in im.get_height():
			var c := im.get_pixel(x, y)
			if c.a > 0.0:
				var l := clampf((0.299 * c.r + 0.587 * c.g + 0.114 * c.b - 0.5) * 1.5 + 0.5, 0.0, 1.0)
				im.set_pixel(x, y, Color(l, l, l, c.a))
	var t := ImageTexture.create_from_image(im)
	_tex[yol] = t
	return t

func _oge_kur(i: int, n: Node3D) -> void:
	var y: Dictionary = harita.yerler[i]
	for c in n.get_children():
		if c is Label3D:
			(c as Label3D).visible = false
	var kok := Node3D.new()
	kok.position = n.global_position + Vector3(0, n.boyut.y + 4.0, 0)
	add_child(kok)
	var simge := Node3D.new()
	simge.position = Vector3(0, 4.0, 0)
	kok.add_child(simge)
	var sp := Sprite3D.new()
	sp.pixel_size = 0.0367
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.no_depth_test = true
	sp.shaded = false
	sp.render_priority = 3
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	simge.add_child(sp)
	var ik := Sprite3D.new()
	ik.pixel_size = 0.0118
	ik.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	ik.no_depth_test = true
	ik.shaded = false
	ik.render_priority = 4
	ik.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	simge.add_child(ik)
	var gl := Label3D.new()
	gl.visible = false
	gl.font_size = 64
	gl.pixel_size = 0.04
	gl.outline_size = 0
	gl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gl.no_depth_test = true
	gl.render_priority = 4
	simge.add_child(gl)
	var ad: String = y["ad"]
	_dugum[i] = n
	_ogeler.append({"i": i, "kok": kok, "simge": simge, "sp": sp, "ik": ik, "gl": gl, "ad": ad, "kat": ""})

func _guncelle() -> void:
	var gr: Node = get_parent().get("gorus")
	for o in _ogeler:
		var kat := kategori(o["i"])
		var hep: bool = kat == "ev" or kat == "gelir"
		var gor: bool = hep or gr == null or gr.kesfedildi(harita.yerler[o["i"]]["pos"])
		(o["kok"] as Node3D).visible = gor
		o["gor"] = gor
		if kat == o["kat"]:
			continue
		o["kat"] = kat
		var d: Array = KAT[kat]
		(o["sp"] as Sprite3D).texture = _rozet(d[1])
		var gl: Label3D = o["gl"]
		gl.text = d[0]
		gl.modulate = d[1].lerp(Color.WHITE, 0.35)
		(o["ik"] as Sprite3D).texture = _bina_ikonu(o["ad"], kat)
		(o["ik"] as Sprite3D).visibility_range_end = 0.0 if hep else 420.0
		var uz: float = 0.0 if hep else 420.0
		(o["sp"] as Sprite3D).visibility_range_end = uz
		gl.visibility_range_end = uz

var _k_kutu: Control
var _k_ic: Control
var _k_yazi: Label
var _k_tw: Tween
var _k_oge := -1
var _k_w := 0.0

func _kagit_kur() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	_k_kutu = Control.new()
	_k_kutu.clip_contents = false
	_k_kutu.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_k_kutu.visible = false
	cl.add_child(_k_kutu)
	_k_ic = Panel.new()
	_k_ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_k_kutu.add_child(_k_ic)
	_k_yazi = Label.new()
	_k_yazi.add_theme_font_override("font", Tema.yazi_tipi())
	_k_yazi.add_theme_font_size_override("font_size", 14)
	_k_yazi.add_theme_color_override("font_color", Color("14110d"))
	_k_yazi.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_k_yazi.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_k_yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_k_ic.add_child(_k_yazi)

func _k_goster(oge: int) -> void:
	if oge == _k_oge:
		return
	_k_oge = oge
	if _k_tw != null:
		_k_tw.kill()
	if oge < 0:
		_k_kutu.visible = false
		return
	var ad: String = _ogeler[oge]["ad"]
	var ts: Vector2 = Tema.yazi_tipi().get_string_size(ad, HORIZONTAL_ALIGNMENT_LEFT, -1, 14)
	_k_w = ts.x + 26.0
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe4c6")
	sb.border_color = Color("14110d")
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(11)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 3
	sb.shadow_offset = Vector2(1, 2)
	_k_ic.add_theme_stylebox_override("panel", sb)
	_k_ic.size = Vector2(_k_w, 22)
	_k_yazi.text = ad
	_k_yazi.size = Vector2(_k_w, 22)
	_k_kutu.size = Vector2(_k_w, 22)
	_k_kutu.modulate.a = 0.0
	_k_kutu.visible = true
	_k_tw = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_k_tw.tween_property(_k_kutu, "modulate:a", 1.0, 0.15)

# Verilen ekran noktasına en yakın (22 px içinde) görünür simgenin _ogeler indeksi; yoksa -1.
func _simge_bul(fare: Vector2) -> int:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return -1
	var en := -1
	var en_d := 22.0 * 22.0
	for k in _ogeler.size():
		var o: Dictionary = _ogeler[k]
		if not o.get("gor", true):
			continue
		var sp: Sprite3D = o["sp"]
		var w: Vector3 = sp.global_position
		if cam.is_position_behind(w):
			continue
		if sp.visibility_range_end > 0.0 and cam.global_position.distance_to(w) > sp.visibility_range_end:
			continue
		var d: float = cam.unproject_position(w).distance_squared_to(fare)
		if d < en_d:
			en_d = d
			en = k
	return en

# Tıklama için: ekran noktasındaki simgenin bina indeksi (yoksa -1).
func ikon_isinla(fare: Vector2) -> int:
	var k := _simge_bul(fare)
	return _ogeler[k]["i"] if k >= 0 else -1

# Fare üstündeki binayı vurgula (-1: hiçbiri). Hat kalınlığı kamera uzaklığıyla büyür.
func vurgula(i: int) -> void:
	var kal: float = clampf(kamera.mesafe / 110.0, 0.5, 3.0)
	if i != _vurgulu:
		if _dugum.has(_vurgulu):
			_dugum[_vurgulu].vurgu(false)
		_vurgulu = i
	if i >= 0 and _dugum.has(i):
		_dugum[i].vurgu(true, kal)

var dis_i := -1   # sokak.gd: fare simgede değil de binanın üstündeyse o bina

func _fare_tara() -> void:
	var cam: Camera3D = get_viewport().get_camera_3d()
	if cam == null:
		return
	var fare: Vector2 = get_viewport().get_mouse_position()
	for a in OS.get_cmdline_user_args():   # test: --fare=x,y
		if a.begins_with("--fare="):
			var f: PackedStringArray = a.substr(7).split(",")
			fare = Vector2(float(f[0]), float(f[1]))
	var en := _simge_bul(fare)
	var dogrudan := en >= 0
	if en < 0 and dis_i >= 0:   # fare binanın gövdesinde: simgesi de hover olsun
		for k in _ogeler.size():
			if _ogeler[k]["i"] == dis_i and _ogeler[k].get("gor", true):
				en = k
				break
	_k_goster(en)
	hover_i = _ogeler[en]["i"] if dogrudan else -1
	if en != _hov_k:   # üstüne gelinen simge hafifçe büyür
		if _hov_k >= 0 and _hov_k < _ogeler.size():
			(_ogeler[_hov_k]["simge"] as Node3D).scale = Vector3.ONE * _olcek
		_hov_k = en
		if en >= 0:
			(_ogeler[en]["simge"] as Node3D).scale = Vector3.ONE * _olcek * 1.18
	if en >= 0:
		var q2: Vector2 = cam.unproject_position((_ogeler[en]["sp"] as Sprite3D).global_position)
		_k_kutu.position = q2 + Vector2(22, -11)

func _process(dt: float) -> void:
	_fare_tara()
	_sure += dt
	if _sure > 1.0:
		_sure = 0.0
		_guncelle()
	var m: float = kamera.mesafe
	var s: float = clampf(m / 90.0, 1.0, 3.0)
	if absf(s - _olcek) > 0.01:
		_olcek = s
		for k in _ogeler.size():
			var o: Dictionary = _ogeler[k]
			(o["simge"] as Node3D).scale = Vector3.ONE * s * (1.18 if k == _hov_k else 1.0)
			(o["simge"] as Node3D).position.y = 4.0 * s
