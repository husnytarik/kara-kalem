extends RefCounted
# Geçici (gri kutu) savaş seviyeleri. Gerçek seviye sahnesi yoksa kullanılır.
# Tür: "sokak" (dar, siperli), "ic" (kapalı oda), "liman" (geniş, konteynerli).
# Sözleşme: zemin/duvar/siper layer 1; Marker3D'ler "spawn_oyuncu" ve "spawn_dusman" gruplarında.

static func kur(tur: String, sahne_yolu: String = "") -> Node3D:
	if sahne_yolu != "" and ResourceLoader.exists(sahne_yolu):
		return (load(sahne_yolu) as PackedScene).instantiate()
	var yol := "res://scenes/battle/%s.tscn" % tur
	if ResourceLoader.exists(yol):
		return (load(yol) as PackedScene).instantiate()
	var k := Node3D.new()
	k.name = "GeciciSeviye_" + tur
	match tur:
		"ic": _ic(k)
		"liman": _liman(k)
		_: _sokak(k)
	return k

static func _kutu(ebeveyn: Node3D, boyut: Vector3, poz: Vector3, renk: Color, gorunur: bool = true) -> void:
	var sb := StaticBody3D.new()
	sb.position = poz
	sb.collision_layer = 1
	sb.collision_mask = 0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = boyut
	cs.shape = bs
	sb.add_child(cs)
	if gorunur:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = boyut
		var m := StandardMaterial3D.new()
		m.albedo_color = renk
		bm.material = m
		mi.mesh = bm
		sb.add_child(mi)
	ebeveyn.add_child(sb)

static func _isaret(ebeveyn: Node3D, grup: String, poz: Vector3) -> void:
	var m := Marker3D.new()
	m.position = poz
	ebeveyn.add_child(m)
	m.add_to_group(grup)

# Sınırı çeviren görünmez duvarlar (kimse alandan düşmesin).
static func _sinir(k: Node3D, w: float, d: float) -> void:
	var h := 12.0
	_kutu(k, Vector3(w + 2, h, 1), Vector3(0, h / 2, -d / 2 - 0.5), Color.WHITE, false)
	_kutu(k, Vector3(w + 2, h, 1), Vector3(0, h / 2, d / 2 + 0.5), Color.WHITE, false)
	_kutu(k, Vector3(1, h, d + 2), Vector3(-w / 2 - 0.5, h / 2, 0), Color.WHITE, false)
	_kutu(k, Vector3(1, h, d + 2), Vector3(w / 2 + 0.5, h / 2, 0), Color.WHITE, false)

static func _sokak(k: Node3D) -> void:
	var w := 70.0
	var d := 36.0
	_kutu(k, Vector3(w, 1, d), Vector3(0, -0.5, 0), Color(0.34, 0.34, 0.36))
	_sinir(k, w, d)
	# iki yanda bina cepheleri
	_kutu(k, Vector3(w, 9, 3), Vector3(0, 4.5, -d / 2 - 1.5 + 3), Color(0.55, 0.32, 0.28))
	_kutu(k, Vector3(w, 9, 3), Vector3(0, 4.5, d / 2 + 1.5 - 3), Color(0.5, 0.36, 0.3))
	# arabalar ve kasalar (siper)
	var arabalar := [Vector3(-14, 0.8, -6), Vector3(-2, 0.8, 7), Vector3(10, 0.8, -4), Vector3(18, 0.8, 8)]
	for a in arabalar:
		_kutu(k, Vector3(4.2, 1.6, 2.0), a, Color(0.2, 0.25, 0.32))
	for c in [Vector3(-22, 0.6, 3), Vector3(-6, 0.6, -10), Vector3(4, 0.6, 1), Vector3(14, 0.6, -12), Vector3(24, 0.6, -2), Vector3(0, 0.6, 12)]:
		_kutu(k, Vector3(1.6, 1.2, 1.6), c, Color(0.5, 0.38, 0.2))
	_kutu(k, Vector3(1.0, 2.2, 5.0), Vector3(-10, 1.1, 0), Color(0.4, 0.4, 0.42))   # barikat
	_kutu(k, Vector3(1.0, 2.2, 5.0), Vector3(8, 1.1, 2), Color(0.4, 0.4, 0.42))
	for i in 6:
		_isaret(k, "spawn_oyuncu", Vector3(-30, 1.0, -7.5 + i * 3.0))
		_isaret(k, "spawn_dusman", Vector3(30, 1.0, -7.5 + i * 3.0))

static func _ic(k: Node3D) -> void:
	var w := 26.0
	var d := 20.0
	var duvar := Color(0.62, 0.55, 0.45)
	_kutu(k, Vector3(w, 1, d), Vector3(0, -0.5, 0), Color(0.3, 0.22, 0.16))
	_sinir(k, w, d)
	# dış duvarlar (görünür) ve tavan yok
	_kutu(k, Vector3(w, 4, 0.5), Vector3(0, 2, -d / 2 + 0.25), duvar)
	_kutu(k, Vector3(w, 4, 0.5), Vector3(0, 2, d / 2 - 0.25), duvar)
	_kutu(k, Vector3(0.5, 4, d), Vector3(-w / 2 + 0.25, 2, 0), duvar)
	_kutu(k, Vector3(0.5, 4, d), Vector3(w / 2 - 0.25, 2, 0), duvar)
	# iki ara duvar, ortalarında kapı boşluğu
	for x in [-4.0, 5.0]:
		_kutu(k, Vector3(0.5, 4, 7.0), Vector3(x, 2, -6.5), duvar)
		_kutu(k, Vector3(0.5, 4, 7.0), Vector3(x, 2, 6.5), duvar)
	# mobilya
	for m in [Vector3(-9, 0.5, -5), Vector3(-9, 0.5, 5), Vector3(0.5, 0.5, 0), Vector3(10, 0.5, -6), Vector3(10, 0.5, 6), Vector3(-1, 0.5, 8)]:
		_kutu(k, Vector3(2.0, 1.0, 1.4), m, Color(0.42, 0.28, 0.18))
	_kutu(k, Vector3(1.0, 1.0, 5.0), Vector3(-11.5, 0.5, 0), Color(0.3, 0.2, 0.15))   # tezgâh
	for i in 6:
		_isaret(k, "spawn_oyuncu", Vector3(-11.0 + (i % 2), 1.0, -5.0 + i * 2.0))
		_isaret(k, "spawn_dusman", Vector3(11.0 - (i % 2), 1.0, -5.0 + i * 2.0))

static func _liman(k: Node3D) -> void:
	var w := 130.0
	var d := 90.0
	_kutu(k, Vector3(w, 1, d), Vector3(0, -0.5, 0), Color(0.42, 0.42, 0.4))
	_sinir(k, w, d)
	# güney kenarda deniz (görsel)
	var deniz := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(w + 80, 70)
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.1, 0.25, 0.4)
	pm.material = dm
	deniz.mesh = pm
	deniz.position = Vector3(0, -1.5, d / 2 + 30)
	k.add_child(deniz)
	var renkler := [Color(0.65, 0.22, 0.18), Color(0.2, 0.4, 0.55), Color(0.7, 0.55, 0.2), Color(0.3, 0.5, 0.3)]
	var n := 0
	for satir in [-24.0, 0.0, 24.0]:
		for sutun in [-30.0, -6.0, 18.0, 40.0]:
			if (n + int(satir)) % 3 == 0:
				n += 1
				continue
			_kutu(k, Vector3(12.0, 2.6, 2.6), Vector3(sutun, 1.3, satir), renkler[n % 4])
			if n % 2 == 0:
				_kutu(k, Vector3(12.0, 2.6, 2.6), Vector3(sutun, 3.9, satir), renkler[(n + 1) % 4])
			n += 1
	for c in [Vector3(-48, 0.8, -8), Vector3(-14, 0.8, 12), Vector3(12, 0.8, -12), Vector3(30, 0.8, 10), Vector3(50, 0.8, -6), Vector3(0, 0.8, 34)]:
		_kutu(k, Vector3(2.2, 1.6, 2.2), c, Color(0.5, 0.38, 0.2))
	_kutu(k, Vector3(5.0, 3.0, 7.0), Vector3(-52, 1.5, -30), Color(0.5, 0.5, 0.55))   # gümrük kulübesi
	for i in 6:
		_isaret(k, "spawn_oyuncu", Vector3(-56.0, 1.0, -12.0 + i * 5.0))
		_isaret(k, "spawn_dusman", Vector3(56.0, 1.0, -12.0 + i * 5.0))
