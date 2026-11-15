extends SceneTree
# TEK SEFERLİK üretici: ilk haritayı (yükseklik/renk PNG, bolgeler.json, harita.tscn) yazar.
# Çalıştır: godot --headless --path godot --script res://tools/uret.gd
# DİKKAT: çalıştırırsan senin yaptığın harita düzenlemelerinin üstüne yazar!

const ADIM := 38.0
const BLOK := 28.0
const KOK := Vector2(-152.0, -228.0)
const SON_Z := 266.0
const X0 := -182.0
const Z0 := -258.0
const GEN := 364.0
const DER := 594.0
const MIN_H := -6.0
const MAX_H := 40.0
const ZS := [-258.0, -228.0, -76.0, 76.0, 190.0, 266.0]
const HS := [28.0, 26.0, 12.0, 3.5, 1.2, 0.35]
const ROMAN := ["", " II", " III", " IV", " V", " VI"]

const BOLGELER := {
	"hilltop": ["Hilltop", 0, 0, 4, 4],
	"downtown": ["Downtown", 4, 0, 4, 4],
	"southside": ["Southside", 0, 4, 4, 4],
	"eastside": ["Eastside", 4, 4, 4, 4],
	"flats": ["The Flats", 0, 8, 8, 3],
	"docks": ["Docks", 0, 11, 8, 2],
}
const POOL := {
	"hilltop": ["Hotel Belmont", "Jeweler", "Attorney", "Watchmaker", "Grand Theater", "Florist", "Tailor", "Dentist", "Country Club", "Art Gallery", "Mansion", "Private Library", "Chauffeur Garage", "Perfumery"],
	"downtown": ["City Hall", "First National Bank", "Daily Courier", "Post Office", "Orpheum Cinema", "Drugstore", "Department Store", "Courthouse", "Union Station", "Stock Exchange", "Telephone Exchange", "Hat Shop", "Chamber of Commerce"],
	"southside": ["Corner Grocer", "Barber Shop", "Bakery", "Pool Hall", "Pawn Shop", "Butcher Row", "Laundry Tenement", "Soda Fountain", "Boxing Gym", "Cobbler", "Social Hall"],
	"eastside": ["Synagogue", "Corner Diner", "Boarding House", "Print Shop", "Bakeshop", "Shoe Repair", "Public School 12", "Open Market", "Garment Sweatshop", "Yiddish Theater", "Deli", "Pushcart Alley"],
	"flats": ["Blacksmith", "Carpenter", "Junk Yard", "Tenement", "Turkish Bath", "Produce Stand", "Butcher", "Rail Depot", "Foundry", "Brick Yard", "Cold Storage", "Tool & Die"],
	"docks": ["Warehouse", "Bonded Warehouse", "Fish Market", "Customs House", "Harbor Master", "Shipyard", "Rope Works", "Dock Hiring Hall", "Coal Yard", "Sailors Bar", "Cannery", "Ship Chandler", "Stevedore Union", "Grain Elevator"],
}
const OZEL := {
	"southside": {2: "Home", 5: "Murphy's Tavern", 9: "Laundromat", 14: "Duffy's Bar", 20: "Sal the Shark"},
	"downtown": {6: "Precinct House"},
	"flats": {7: "Marchetti Family"},
	"docks": {4: "Harbor Trust"},
}

var _gurultu := FastNoiseLite.new()

func _h(x: float, z: float) -> float:
	var taban: float
	if z >= SON_Z:
		taban = lerpf(0.35, MIN_H, clampf((z - SON_Z) / 24.0, 0.0, 1.0))
	else:
		taban = HS[0]
		for i in range(ZS.size() - 1):
			if z >= ZS[i] and z < ZS[i + 1]:
				taban = lerpf(HS[i], HS[i + 1], (z - ZS[i]) / (ZS[i + 1] - ZS[i]))
	var bati := 10.0 * clampf(1.0 - (x - KOK.x) / 160.0, 0.0, 1.0) * clampf(1.0 - (z - (-228.0)) / 240.0, 0.0, 1.0)
	var gur := _gurultu.get_noise_2d(x, z) * 2.5 * lerpf(1.0, 0.25, clampf((z - 60.0) / 150.0, 0.0, 1.0))
	if z >= SON_Z:
		gur = 0.0
	return clampf(taban + bati + gur, MIN_H, MAX_H)

func _init() -> void:
	_gurultu.seed = 7
	_gurultu.frequency = 0.012
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var tdir := "res://assets/environment/terrain"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(tdir))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://data"))

	# bölge dikdörtgenleri
	var bj := {}
	for id in BOLGELER:
		var b: Array = BOLGELER[id]
		bj[id] = {"ad": b[0], "x0": KOK.x + b[1] * ADIM, "z0": KOK.y + b[2] * ADIM, "x1": KOK.x + (b[1] + b[3]) * ADIM, "z1": KOK.y + (b[2] + b[4]) * ADIM}
	var f := FileAccess.open("res://data/bolgeler.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(bj, "\t"))
	f.close()

	# yükseklik + renk PNG (2 m / piksel)
	var w := int(GEN / 2.0) + 1
	var hh := int(DER / 2.0) + 1
	var yi := Image.create(w, hh, false, Image.FORMAT_L8)
	var ri := Image.create(w, hh, false, Image.FORMAT_RGB8)
	for j in hh:
		for i in w:
			var x := X0 + i * 2.0
			var z := Z0 + j * 2.0
			var v := (_h(x, z) - MIN_H) / (MAX_H - MIN_H)
			yi.set_pixel(i, j, Color(v, v, v))
			var c := Color(0.28, 0.4, 0.2)
			if z > SON_Z:
				c = Color(0.62, 0.56, 0.4) if _h(x, z) > -2.0 else Color(0.35, 0.33, 0.25)
			for id in bj:
				var d: Dictionary = bj[id]
				if x >= d["x0"] and x < d["x1"] and z >= d["z0"] and z < d["z1"]:
					c = Color(0.14, 0.14, 0.15)
			ri.set_pixel(i, j, c)
	yi.save_png(tdir + "/yukseklik.png")
	ri.save_png(tdir + "/renk.png")

	# sahne
	var kok := Node3D.new()
	kok.name = "Harita"
	kok.set_script(load("res://scripts/core/harita.gd"))
	var arazi := Node3D.new()
	arazi.name = "Arazi"
	arazi.set_script(load("res://scripts/core/arazi.gd"))
	kok.add_child(arazi)
	arazi.owner = kok
	var binalar := _kap(kok, "Binalar")
	var kaideler := _kap(kok, "Kaideler")
	var iskeleler := _kap(kok, "Iskeleler")
	var deniz_kap := _kap(kok, "Deniz")
	var sahne: PackedScene = load("res://scenes/city/bina.tscn")

	var pad_m := StandardMaterial3D.new()
	pad_m.albedo_color = Color(0.42, 0.42, 0.4)
	pad_m.roughness = 1.0
	var sayac := {}
	for id in BOLGELER:
		var b: Array = BOLGELER[id]
		sayac[id] = 0
		for gz in range(b[2], b[2] + b[4]):
			for gx in range(b[1], b[1] + b[3]):
				var x0 := KOK.x + gx * ADIM + (ADIM - BLOK) / 2.0
				var z0 := KOK.y + gz * ADIM + (ADIM - BLOK) / 2.0
				var cx := x0 + BLOK / 2.0
				var cz := z0 + BLOK / 2.0
				var ust := -99.0
				for dx in [0.0, 0.5, 1.0]:
					for dz in [0.0, 0.5, 1.0]:
						ust = maxf(ust, _h(x0 + dx * BLOK, z0 + dz * BLOK))
				ust += 0.12
				var pad := MeshInstance3D.new()
				pad.name = "Kaide_%s_%d_%d" % [id, gx, gz]
				var bm := BoxMesh.new()
				bm.size = Vector3(BLOK, 5.0, BLOK)
				pad.mesh = bm
				pad.material_override = pad_m
				kaideler.add_child(pad)
				pad.owner = kok
				pad.position = Vector3(cx, ust - 2.5, cz)
				pad.add_to_group("kaide", true)
				# binalar
				var kalip: Array = []   # [dx, dz, w, d, h, renk]
				match id:
					"hilltop":
						kalip = [[0, 0, 16, 16, rng.randf_range(7, 11), Color(0.78, 0.7, 0.55)]]
					"downtown":
						kalip = [[0, 0, 20, 20, rng.randf_range(26, 55), Color(0.5, 0.55, 0.62)]]
					"southside", "eastside":
						var rc := Color(0.55, 0.3, 0.25) if id == "southside" else Color(0.5, 0.42, 0.32)
						kalip = [[-7, 0, 12, 22, rng.randf_range(12, 18), rc], [7, 0, 12, 22, rng.randf_range(12, 18), rc.lightened(0.08)]]
					"flats":
						kalip = [[0, 0, 22, 22, rng.randf_range(8, 12), Color(0.45, 0.4, 0.36)]]
					"docks":
						kalip = [[0, 0, 22, 22, rng.randf_range(7, 9), Color(0.38, 0.4, 0.42)]]
				for k in kalip:
					var i: int = sayac[id]
					sayac[id] += 1
					var havuz: Array = POOL[id]
					var ad: String = havuz[i % havuz.size()] + ROMAN[i / havuz.size()]
					var ozel := false
					if OZEL.has(id) and OZEL[id].has(i):
						ad = OZEL[id][i]
						ozel = true
					var n: Node3D = sahne.instantiate()
					n.name = (ad.replace(" ", "_").replace("'", "") + "_" + str(i))
					binalar.add_child(n)
					n.owner = kok
					n.position = Vector3(cx + k[0], ust, cz + k[1])
					n.set("ad", ad)
					n.set("bolge", id)
					n.set("ozel", ozel)
					n.set("boyut", Vector3(k[2], k[4], k[3]))
					n.set("renk", k[5])

	# iskeleler
	var tahta := StandardMaterial3D.new()
	tahta.albedo_color = Color(0.4, 0.28, 0.17)
	for k in 6:
		var p := MeshInstance3D.new()
		p.name = "Iskele_%d" % k
		var bm := BoxMesh.new()
		bm.size = Vector3(6, 1, 40)
		p.mesh = bm
		p.material_override = tahta
		iskeleler.add_child(p)
		p.owner = kok
		p.position = Vector3(KOK.x + 30 + k * 48 + 3, -0.5, SON_Z + 20)
		p.add_to_group("iskele", true)

	# deniz
	var dz := MeshInstance3D.new()
	dz.name = "Su"
	var pm := PlaneMesh.new()
	pm.size = Vector2(GEN, 74)
	dz.mesh = pm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.1, 0.3, 0.45, 0.8)
	sm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	sm.roughness = 0.2
	dz.material_override = sm
	deniz_kap.add_child(dz)
	dz.owner = kok
	dz.position = Vector3(0, -0.3, SON_Z + 37)

	var ps := PackedScene.new()
	ps.pack(kok)
	var hata := ResourceSaver.save(ps, "res://scenes/city/harita.tscn")
	print("KAYDEDILDI hata=", hata)
	quit()

func _kap(kok: Node, ad: String) -> Node3D:
	var n := Node3D.new()
	n.name = ad
	kok.add_child(n)
	n.owner = kok
	return n
