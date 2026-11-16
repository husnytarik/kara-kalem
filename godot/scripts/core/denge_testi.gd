extends RefCounted
# Denge/oynanabilirlik probu: arayüzsüz, hızlandırılmış simülasyon.
#   mod "bos"  : hiçbir şey yapma
#   mod "bot"  : makul bir oyuncu (adam tut, haraç bağla/topla, bölge işleri, yatırım)

static func ozet(o: Node) -> String:
	var s := []
	for id in o.bolge:
		var hk: String = o.hakim_of(id)
		s.append("%s:%s" % [id.substr(0, 4), hk.substr(0, 3) if hk != "" else "-"])
	var haracli := 0
	var sahip := 0
	for i in o.isy:
		if o.isy[i]["haracli"]:
			haracli += 1
		if o.isy[i]["sahip"]:
			sahip += 1
	return "gun %d | temiz %d kirli %d | adam %d | arama %d | haracli %d sahip %d | %s | ofke m%d o%d" % [
		o.t / 1440, o.temiz, o.kirli, o.adamlar.size(), o.arama, haracli, sahip, " ".join(s), o.ofke["marchetti"], o.ofke["obrien"]]

static func calistir(o: Node, mod: String, gun: int) -> void:
	var bina_bolge := {}
	for i in o.isy:
		var b: String = o.harita.yerler[i]["bolge"]
		if not bina_bolge.has(b):
			bina_bolge[b] = []
		bina_bolge[b].append(i)
	print("BASLA ", mod, " | ", ozet(o))
	for d in gun:
		if mod == "bot":
			_bot(o, bina_bolge)
		o.ilerle(1440.0 / o.DK_SN)
		if d % 60 == 59:
			print(ozet(o))
	print("BITIS ", ozet(o))
	var sayac := {"good": 0, "bad": 0, "warn": 0}
	for e in o.defter:
		if sayac.has(e["tur"]):
			sayac[e["tur"]] += 1
	print("defter olay sayilari: ", sayac)

static func _bot(o: Node, bb: Dictionary) -> void:
	while o.adamlar.size() < 4 and o.kirli >= 100:
		o.adam_tut()
	# silah al
	for a in o.adamlar:
		if a["silah"] != "tabanca" and o.kirli > 400:
			o.silah_ver(a["id"], "tabanca")
	for id in o.bolge:
		if not o.erisim(id):
			continue
		for tur in ["himaye", "hediye", "gozdagi"]:
			if tur == "hediye" and o.temiz < 800:
				continue
			o.bolge_is(id, tur)
		if o.hakim_of(id) == "oyuncu" and o.temiz > 1500:
			o.bolge_yatirim(id)
		for i in bb.get(id, []):
			if o.gorev_gor_var(i):
				continue
			var k: String = o.kontrol(i)
			if k == "haraci" and o.isy[i]["birikim"] > 20:
				o.gorev_ver(i, "topla")
			elif k != "haraci" and k != "sahip":
				o.gorev_ver(i, "haraclan")
