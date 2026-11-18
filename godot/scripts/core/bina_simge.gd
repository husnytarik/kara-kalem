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

func kur(o: Node, h: Node, ka: Node) -> void:
	oyun = o
	harita = h
	kamera = ka
	_pazar = Pazar.new(oyun)
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

func _rozet(renk: Color) -> ImageTexture:
	var a := renk.to_html()
	if _tex.has(a):
		return _tex[a]
	var N := 64
	var im := Image.create(N, N, false, Image.FORMAT_RGBA8)
	var c := Vector2(N / 2.0 - 0.5, N / 2.0 - 0.5)
	for x in N:
		for y in N:
			var d: float = Vector2(x, y).distance_to(c)
			var col := Color(0, 0, 0, 0)
			if d < 31.0:
				col = Color("2b1d12")
			if d >= 24.0 and d < 28.5:
				col = renk
			elif d >= 28.5 and d < 31.0:
				col = Color("1a1106")
			if d >= 31.0 and d < 32.0:
				col = Color(0, 0, 0, 0.35)
			im.set_pixel(x, y, col)
	var t := ImageTexture.create_from_image(im)
	_tex[a] = t
	return t

func _oge_kur(i: int, n: Node3D) -> void:
	var y: Dictionary = harita.yerler[i]
	if n.get("_etiket") != null:
		(n._etiket as Label3D).visible = false
	var kok := Node3D.new()
	kok.position = n.global_position + Vector3(0, n.boyut.y + 4.0, 0)
	add_child(kok)
	var simge := Node3D.new()
	simge.position = Vector3(0, 4.0, 0)
	kok.add_child(simge)
	var sp := Sprite3D.new()
	sp.pixel_size = 0.055
	sp.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sp.no_depth_test = true
	sp.shaded = false
	sp.render_priority = 3
	sp.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	simge.add_child(sp)
	var gl := Label3D.new()
	gl.font_size = 64
	gl.pixel_size = 0.04
	gl.outline_size = 0
	gl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	gl.no_depth_test = true
	gl.render_priority = 4
	simge.add_child(gl)
	# kâğıt şerit
	var ad: String = y["ad"]
	var sz: Vector2 = ThemeDB.fallback_font.get_string_size(ad, HORIZONTAL_ALIGNMENT_LEFT, -1, 56)
	var gw: float = sz.x * 0.03 + 3.0
	var gh := 3.0
	var k := 4.0
	var sr := Sprite3D.new()
	sr.texture = Tema.kagit_tex(int(gw / (0.03 * k)), int(gh / (0.03 * k)), Tema.KAGIT, Color("2b1b0c"))
	sr.pixel_size = 0.03 * k
	sr.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sr.no_depth_test = true
	sr.shaded = false
	sr.render_priority = 1
	sr.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	var sl := Label3D.new()
	sl.font_size = 56
	sl.pixel_size = 0.03
	sl.outline_size = 0
	sl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sl.no_depth_test = true
	sl.render_priority = 2
	sl.modulate = Tema.KAGIT_YAZI
	sl.text = ad
	for q in [sr, sl]:
		q.visibility_range_end = 120.0
		kok.add_child(q)
	_ogeler.append({"i": i, "kok": kok, "simge": simge, "sp": sp, "gl": gl, "sr": sr, "kat": ""})

func _guncelle() -> void:
	for o in _ogeler:
		var kat := kategori(o["i"])
		if kat == o["kat"]:
			continue
		o["kat"] = kat
		var d: Array = KAT[kat]
		(o["sp"] as Sprite3D).texture = _rozet(d[1])
		var gl: Label3D = o["gl"]
		gl.text = d[0]
		gl.modulate = d[1].lerp(Color.WHITE, 0.35)
		var hep: bool = kat == "ev" or kat == "gelir"
		var uz: float = 0.0 if hep else 420.0
		(o["sp"] as Sprite3D).visibility_range_end = uz
		gl.visibility_range_end = uz

func _process(dt: float) -> void:
	_sure += dt
	if _sure > 1.0:
		_sure = 0.0
		_guncelle()
	var m: float = kamera.mesafe
	var s: float = clampf(m / 90.0, 1.0, 3.0)
	if absf(s - _olcek) > 0.01:
		_olcek = s
		for o in _ogeler:
			(o["simge"] as Node3D).scale = Vector3.ONE * s
			(o["simge"] as Node3D).position.y = 4.0 * s
