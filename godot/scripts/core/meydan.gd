extends Node3D
# Şehir meydanı: heykelli taş meydan + etkinlik dekorları (darağacı, kürsü, bayraklar, barikat...).
# Etkinlik durumunu oyun.gaz_k'dan okur; dekorlar etkinliğe iki saat kala kurulur, bitince kalkar.

const POS := Vector3(74.0, 0.0, 46.0)
const R := 16.0

var oyun: Node
var harita: Node3D
var _merkez := Vector3.ZERO
var _setler: Dictionary = {}     # tür -> Node3D
var _etiket: Label3D
var _son := ""
var _sure := 0.0

func _mat(c: Color, parlak: float = 0.0, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.9
	m.metallic = metal
	if parlak > 0.0:
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = parlak
	return m

func _kutu(ata: Node3D, boyut: Vector3, p: Vector3, c: Color, kaide: bool = false, parlak: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = boyut
	mi.mesh = bm
	mi.material_override = _mat(c, parlak)
	mi.position = p
	if kaide:
		mi.add_to_group("kaide")
	ata.add_child(mi)
	return mi

func _silindir(ata: Node3D, r: float, h: float, p: Vector3, c: Color, parlak: float = 0.0, metal: float = 0.0) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r
	cm.bottom_radius = r
	cm.height = h
	mi.mesh = cm
	mi.material_override = _mat(c, parlak, metal)
	mi.position = p
	ata.add_child(mi)
	return mi

func _kure(ata: Node3D, r: float, p: Vector3, c: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = r
	sm.height = r * 2.0
	mi.mesh = sm
	mi.material_override = _mat(c)
	mi.position = p
	ata.add_child(mi)
	return mi

func _ready() -> void:
	_merkez = Vector3(POS.x, harita.yuk(POS.x, POS.z), POS.z)
	position = _merkez
	var taban := Color(0.56, 0.53, 0.48)
	var disk := _silindir(self, R, 0.5, Vector3(0, 0.0, 0), taban)
	disk.name = "Zemin"
	_silindir(self, R * 0.62, 0.56, Vector3(0, 0.0, 0), Color(0.64, 0.6, 0.52))
	_silindir(self, R * 0.3, 0.6, Vector3(0, 0.0, 0), Color(0.5, 0.47, 0.42))
	# heykel
	var kaide := _kutu(self, Vector3(3.4, 2.4, 3.4), Vector3(0, 1.4, 0), Color(0.72, 0.69, 0.63), true)
	kaide.name = "Kaide"
	_kutu(self, Vector3(4.2, 0.5, 4.2), Vector3(0, 0.45, 0), Color(0.66, 0.63, 0.58))
	var bronz := Color(0.22, 0.42, 0.36)
	var govde := _silindir(self, 0.55, 1.9, Vector3(0, 3.55, 0), bronz, 0.0, 0.6)
	govde.name = "Heykel"
	_kure(self, 0.38, Vector3(0, 4.75, 0), bronz)
	_kutu(self, Vector3(0.22, 1.3, 0.22), Vector3(0.7, 4.3, 0.1), bronz).rotation_degrees = Vector3(0, 0, -25)
	_kutu(self, Vector3(1.3, 0.12, 0.6), Vector3(0, 3.35, 0), bronz)
	var yazi := Label3D.new()
	yazi.text = "LIBERTY MEYDANI"
	yazi.font = load("res://scripts/ui/tema.gd").yazi_tipi()
	yazi.font_size = 52
	yazi.pixel_size = 0.012
	yazi.modulate = Color(0.1, 0.09, 0.07)
	yazi.outline_size = 0
	yazi.position = Vector3(0, 1.4, 1.72)
	add_child(yazi)
	# banklar ve lambalar
	for k in 8:
		var a := TAU * k / 8.0 + 0.2
		var d := Vector3(cos(a), 0, sin(a))
		var b := Node3D.new()
		b.position = d * (R * 0.78)
		b.rotation.y = -a + PI / 2.0
		add_child(b)
		_kutu(b, Vector3(2.4, 0.18, 0.7), Vector3(0, 0.75, 0), Color(0.34, 0.22, 0.14))
		_kutu(b, Vector3(2.4, 0.5, 0.12), Vector3(0, 1.1, -0.3), Color(0.3, 0.2, 0.12))
		_kutu(b, Vector3(0.14, 0.5, 0.6), Vector3(-1.05, 0.5, 0), Color(0.12, 0.12, 0.13))
		_kutu(b, Vector3(0.14, 0.5, 0.6), Vector3(1.05, 0.5, 0), Color(0.12, 0.12, 0.13))
	for k in 4:
		var a2 := TAU * k / 4.0 + PI / 4.0
		var lp := Vector3(cos(a2), 0, sin(a2)) * (R - 0.9)
		_silindir(self, 0.12, 5.0, lp + Vector3(0, 2.5, 0), Color(0.12, 0.12, 0.13))
		_kure(self, 0.5, lp + Vector3(0, 5.2, 0), Color(1.0, 0.85, 0.5)).material_override = _mat(Color(1.0, 0.85, 0.5), 1.4)
	_setler_kur()
	_etiket = Label3D.new()
	_etiket.font = load("res://scripts/ui/tema.gd").yazi_tipi()
	_etiket.font_size = 44
	_etiket.pixel_size = 0.03
	_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_etiket.no_depth_test = true
	_etiket.modulate = Color(1, 0.93, 0.7)
	_etiket.outline_size = 8
	_etiket.outline_modulate = Color(0.1, 0.07, 0.04)
	_etiket.position = Vector3(0, 9.0, 0)
	_etiket.visible = false
	add_child(_etiket)

func _set_al(tur: String) -> Node3D:
	var n := Node3D.new()
	n.visible = false
	add_child(n)
	_setler[tur] = n
	return n

func _bayrak(ata: Node3D, p: Vector3, c: Color, h: float = 6.0) -> void:
	_silindir(ata, 0.07, h, p + Vector3(0, h / 2.0, 0), Color(0.75, 0.72, 0.65))
	_kutu(ata, Vector3(1.4, 0.9, 0.05), p + Vector3(0.7, h - 0.6, 0), c)

func _kurs(ata: Node3D, p: Vector3) -> void:
	_kutu(ata, Vector3(3.2, 1.0, 2.0), p + Vector3(0, 0.5, 0), Color(0.36, 0.25, 0.15))
	_kutu(ata, Vector3(3.0, 0.1, 1.8), p + Vector3(0, 1.05, 0), Color(0.46, 0.33, 0.2))
	_kutu(ata, Vector3(1.2, 0.9, 0.3), p + Vector3(0, 1.5, -0.4), Color(0.3, 0.2, 0.12))

func _setler_kur() -> void:
	var s: Node3D
	var ahsap := Color(0.31, 0.21, 0.13)
	# idam: darağacı
	s = _set_al("idam")
	_kutu(s, Vector3(6.0, 1.6, 4.0), Vector3(0, 0.8, -9.5), ahsap)
	for k in 4:
		var hh: float = 1.4 - 0.35 * k
		_kutu(s, Vector3(0.9, hh, 1.6), Vector3(-3.6 - k * 0.9, hh / 2.0, -9.5), ahsap)
	_kutu(s, Vector3(0.35, 5.2, 0.35), Vector3(-1.6, 4.2, -9.5), ahsap)
	_kutu(s, Vector3(4.2, 0.35, 0.35), Vector3(0.4, 6.7, -9.5), ahsap)
	_kutu(s, Vector3(0.2, 1.8, 0.2), Vector3(-1.0, 5.6, -9.5), ahsap).rotation_degrees = Vector3(0, 0, 40)
	_silindir(s, 0.04, 1.4, Vector3(1.6, 5.95, -9.5), Color(0.55, 0.47, 0.32))
	var ilmik := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = 0.2
	tm.outer_radius = 0.32
	ilmik.mesh = tm
	ilmik.material_override = _mat(Color(0.55, 0.47, 0.32))
	ilmik.position = Vector3(1.6, 5.15, -9.5)
	ilmik.rotation_degrees = Vector3(90, 0, 0)
	s.add_child(ilmik)
	for k in 6:
		_kutu(s, Vector3(0.6, 1.0, 0.6), Vector3(-6.0 + k * 2.4, 0.5, -3.0), Color(0.1, 0.1, 0.14))   # askerî sıra (koyu)
	# isyan: barikat, kırmızı bayraklar, yangın
	s = _set_al("isyan")
	for k in 7:
		var a: float = lerpf(-0.9, 0.9, k / 6.0)
		_kutu(s, Vector3(2.2, 1.3, 0.35), Vector3(sin(a) * 11.0, 0.65, -cos(a) * 11.0 + 0.0), Color(0.28, 0.2, 0.14)).rotation.y = -a
	for k in 4:
		_bayrak(s, Vector3(-9.0 + k * 6.0, 0, 5.0), Color(0.75, 0.1, 0.1), 5.0)
	_kurs(s, Vector3(0, 0, 9.0))
	for k in 3:
		var f := _kure(s, 0.7, Vector3(-4.0 + k * 4.0, 0.9, -8.0), Color(1.0, 0.45, 0.1))
		f.material_override = _mat(Color(1.0, 0.45, 0.1), 2.4)
	# polis: mavi barikat, fıçılar, afiş
	s = _set_al("polis")
	for k in 6:
		_kutu(s, Vector3(2.3, 1.1, 0.25), Vector3(-6.5 + k * 2.6, 0.55, -10.0), Color(0.12, 0.2, 0.42))
		_kutu(s, Vector3(2.3, 0.12, 0.3), Vector3(-6.5 + k * 2.6, 1.1, -10.0), Color(0.9, 0.9, 0.9))
	for k in 9:
		_silindir(s, 0.45, 1.0, Vector3(-4.0 + (k % 3) * 1.1, 0.5 + (k / 6) * 1.0, 6.0 + (k / 3 % 2) * 1.1), Color(0.4, 0.26, 0.14))
	_kurs(s, Vector3(7.5, 0, -6.0))
	_bayrak(s, Vector3(-8.0, 0, -8.0), Color(0.12, 0.2, 0.42), 5.5)
	_bayrak(s, Vector3(8.0, 0, -8.5), Color(0.12, 0.2, 0.42), 5.5)
	# kutlama: renkli bayrak dizisi, balonlar, sahne
	s = _set_al("kutlama")
	_kutu(s, Vector3(6.0, 1.0, 3.5), Vector3(0, 0.5, -9.0), Color(0.5, 0.18, 0.18))
	_kutu(s, Vector3(6.2, 0.12, 3.7), Vector3(0, 1.05, -9.0), Color(0.82, 0.72, 0.4))
	var renkler := [Color(0.85, 0.15, 0.15), Color(0.95, 0.9, 0.85), Color(0.15, 0.3, 0.75), Color(0.95, 0.75, 0.15)]
	for k in 12:
		var a2 := TAU * k / 12.0
		_kutu(s, Vector3(0.5, 0.5, 0.06), Vector3(cos(a2) * 13.0, 5.0 - 0.6 * absf(sin(a2 * 3.0)), sin(a2) * 13.0), renkler[k % 4])
	for k in 4:
		var a3 := TAU * k / 4.0 + PI / 4.0
		_silindir(s, 0.06, 6.0, Vector3(cos(a3) * 13.0, 3.0, sin(a3) * 13.0), Color(0.6, 0.55, 0.5))
	for k in 10:
		_kure(s, 0.45, Vector3(-8.0 + k * 1.8, 6.0 + sin(k * 1.7) * 0.6, -11.0 + sin(k) * 1.5), renkler[k % 4])
	# miting: kürsü, afiş, bayraklar
	s = _set_al("miting")
	_kurs(s, Vector3(0, 0, -9.0))
	_bayrak(s, Vector3(-4.0, 0, -9.5), Color(0.12, 0.2, 0.55), 6.0)
	_bayrak(s, Vector3(4.0, 0, -9.5), Color(0.8, 0.12, 0.12), 6.0)
	_kutu(s, Vector3(5.5, 1.6, 0.08), Vector3(0, 3.6, -10.6), Color(0.9, 0.85, 0.72))
	# tören: bayraklar, çelenk
	s = _set_al("toren")
	for k in 3:
		_bayrak(s, Vector3(-4.0 + k * 4.0, 0, -9.0), [Color(0.75, 0.1, 0.1), Color(0.95, 0.95, 0.95), Color(0.15, 0.25, 0.65)][k], 7.0)
	_kurs(s, Vector3(0, 0, -6.0))
	var celenk := MeshInstance3D.new()
	var tm2 := TorusMesh.new()
	tm2.inner_radius = 0.5
	tm2.outer_radius = 0.8
	celenk.mesh = tm2
	celenk.material_override = _mat(Color(0.2, 0.45, 0.2))
	celenk.position = Vector3(0, 2.2, 1.8)
	celenk.rotation_degrees = Vector3(80, 0, 0)
	add_child(celenk)
	_setler["toren_celenk"] = celenk
	celenk.visible = false

func _process(delta: float) -> void:
	_sure -= delta
	if _sure > 0.0 or oyun == null or oyun.gaz_k == null:
		return
	_sure = 1.0
	var durum: String = oyun.gaz_k.etk_durum()
	var e: Dictionary = oyun.gaz_k.etk()
	var tur: String = e.get("tur", "") if durum != "" else ""
	var anahtar := "%s|%s" % [tur, durum]
	if anahtar == _son:
		return
	_son = anahtar
	for k in _setler:
		(_setler[k] as Node3D).visible = (k == tur) or (k == "toren_celenk" and tur == "toren")
	if tur != "":
		_etiket.visible = durum == "aktif"
		_etiket.text = String(e.get("ad", ""))
	else:
		_etiket.visible = false
	if durum == "aktif" and not e.get("bildirildi", false):
		e["bildirildi"] = true
		oyun.kayit("Meydanda %s başladı (Liberty Meydanı, Eastside)." % String(e.get("ad", "bir etkinlik")).to_lower(), "info")
