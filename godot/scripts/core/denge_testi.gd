extends RefCounted
# Denge/oynanabilirlik probu: arayüzsüz, hızlandırılmış simülasyon.
#   mod "bos"  : hiçbir şey yapma
#   mod "bot"  : makul bir oyuncu (adam tut, haraç bağla/topla, mahalle işleri, yatırım)

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
		if mod != "bos":
			_bakim(o)
		if mod == "bot":
			_bot(o, bina_bolge)
		elif mod == "iyi":
			_iyi(o)
		elif mod == "kotu":
			_kotu(o, bina_bolge)
			_isler(o)
		elif mod == "isci":
			if d == 0:
				o.kirli = 900.0
			while o.adamlar.size() < 5 and o.kirli >= 100:
				o.adam_tut()
			for a in o.adamlar:
				if a["silah"] != "tabanca" and o.kirli > 200:
					o.silah_ver(a["id"], "tabanca")
			for id in o.bolge:
				if o.erisim(id) and d % 7 == 0:
					o.bolge_is(id, "gozdagi")
			_isler(o)
		if not o.son.is_empty():
			print("OYUN BITTI gun ", o.t / 1440, ": ", o.son)
			break
		o.ilerle(1440.0 / o.DK_SN)
		if d % 60 == 59:
			print(ozet(o))
	print("BITIS ", ozet(o))
	print("borc ", o.borc, " kira_borc ", o.kira_borc, " meslek ", o.mes["is"], " beceri ", o.mes["beceri"], " isletme ", o.mes["isletme"].keys())
	print("kisisel ", o.kis, " un ", o.kis_k.taninma(), " ekip ", o.adamlar.size(), " zafer ", o.zf)
	var sayac := {"good": 0, "bad": 0, "warn": 0}
	for e in o.defter:
		if sayac.has(e["tur"]):
			sayac[e["tur"]] += 1
	print("defter olay sayilari: ", sayac)
	son_kayitlar(o, 30)

# Basit bakım: günde bir yemek, gerekirse uyku, hastaysa ilaç.
static func _bakim(o: Node) -> void:
	var k: Dictionary = o.kis
	if k["aclik"] > 40.0:
		o.harcama(6.0, "temiz")
		k["aclik"] = 10.0
	if k["yorgun"] > 45.0:
		k["yorgun"] = 15.0
	if k["stres"] > 60.0:
		k["stres"] = 30.0
	if o.kis_k.hasta_mi():
		o.kis_k.yap("ilac")

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


# Dürüst yol: işe gir, becerini geliştir, işletme al, meşru yer satın al, mahalleye hediye ver. Haraç/adam yok.
static func _iyi(o: Node) -> void:
	if not o.meslek.calisiyor() and o.mes["isletme"].is_empty():
		for ad in o.meslek.ilanlar():
			if o.meslek.is_gir(ad["j"], ad["bolge"], ad["bina"], ad["carpan"]).get("ok", false):
				break
	elif o.meslek.calisiyor() and o.vardiya.is_empty():
		o.t = o.t - o.t % 1440 + 7 * 60
		o.meslek.mesai_baslat(o.mes["is"]["bina"])
	for j in o.meslek.MESLEKLER:
		if o.mes["beceri"][j] >= 20.0 and not o.mes["isletme"].has(j) and o.temiz > o.meslek.MESLEKLER[j]["fiyat"] + 500:
			o.meslek.isletme_al(j)
	for id in o.bolge:
		if o.erisim(id) and o.temiz > 4000:
			o.bolge_is(id, "hediye")
	for i in o.isy:
		if o.isy[i]["sahip"] or o.isy[i]["tur"] == "resmi":
			continue
		if o.erisim(o.harita.yerler[i]["bolge"]) and o.temiz > o.fiyat(i) + 1200:
			o.satin_al(i)
			break

# Kötü yol: tam kadro adam, silah, korku, yüksek haraç.
static func _kotu(o: Node, bb: Dictionary) -> void:
	while o.adamlar.size() < 8 and o.kirli >= 100:
		o.adam_tut()
	for a in o.adamlar:
		if a["silah"] != "tabanca" and o.kirli > 300:
			o.silah_ver(a["id"], "tabanca")
	for id in o.bolge:
		if not o.erisim(id):
			continue
		o.bolge_is(id, "gozdagi")
		o.bolge_is(id, "himaye")
		if o.hakim_of(id) == "oyuncu":
			o.bolge_harac(id, 3)
		for i in bb.get(id, []):
			if o.gorev_gor_var(i):
				continue
			var k: String = o.kontrol(i)
			if k == "haraci" and o.isy[i]["birikim"] > 20:
				o.gorev_ver(i, "topla")
			elif k != "haraci" and k != "sahip":
				o.gorev_ver(i, "haraclan")

static func son_kayitlar(o: Node, n: int) -> void:
	for e in o.defter.slice(maxi(0, o.defter.size() - n)):
		print("  ", o.saat_yazi(e["t"]), " ", e["tur"], " ", e["metin"])

# Kirli iş botu: kulüp/bar tahtalarından işleri alır.
static func _isler(o: Node) -> void:
	if o.bos_adamlar().is_empty():
		return
	for i in o.harita.yerler.size():
		if not o.pazar_k.site_mi(i) or not o.erisim(o.harita.yerler[i]["bolge"]):
			continue
		var l: Array = o.isler_k.liste(i)
		for idx in range(l.size() - 1, -1, -1):
			if o.bos_adamlar().is_empty():
				return
			o.isler_k.kabul(i, idx)
