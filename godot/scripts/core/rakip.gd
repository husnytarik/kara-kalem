extends RefCounted
# Rakip ailelerin yaşayan simülasyonu: kasa, moral, kadro büyür/küçülür, savaşta adam kaybeder, kaptanlar terfi eder,
# sadakati düşenler afaroz edilir / ailesini satıp başka aileye geçer / Don'a darbe yapar, zayıf taraf barış ister.
# Aylık işler (oyun._ay -> ay()). Durum oyun.fk içinde (kayda girer). Üye alanları (tembel): sadakat, hirs.

const GUC := {"don": 4.0, "ikinci": 3.0, "danisman": 1.0, "kaptan": 2.0, "asker": 1.0}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

func fk(f: String) -> Dictionary:
	if not oyun.fk.has(f):
		oyun.fk[f] = {"kasa": 300.0, "moral": 50.0, "kayip": 0}
	return oyun.fk[f]

func _hazir(u: Dictionary) -> Dictionary:
	if not u.has("sadakat"):
		u["sadakat"] = 55.0 + oyun.rng.randf() * 20.0
		u["hirs"] = 20.0 + oyun.rng.randf() * 60.0
	return u

func uyeler(f: String, rutbe: String = "") -> Array:
	var r: Array = oyun.aile_uyeleri(f)
	if rutbe != "":
		r = r.filter(func(u): return u["rutbe"] == rutbe)
	for u in r:
		_hazir(u)
	return r

func kuvvet(f: String) -> float:
	var k := 0.0
	for u in oyun.aile_uyeleri(f):
		k += GUC[u["rutbe"]]
	return k

func bolge_say(f: String) -> int:
	var n := 0
	for id in oyun.bolge:
		if oyun.hakim_of(id) == f:
			n += 1
	return n

func _ad(f: String) -> String:
	return oyun.hakim_ad(f)

func _sec(a: Array) -> Dictionary:
	return a[oyun.rng.randi() % a.size()] if not a.is_empty() else {}

func _en_iyi(a: Array) -> Dictionary:
	var en: Dictionary = {}
	var puan := -1.0
	for u in a:
		_hazir(u)
		var p: float = u["sadakat"] * 0.4 + u["hirs"] * 0.6
		if p > puan:
			puan = p
			en = u
	return en

func ay() -> void:
	for f in oyun.NPC:
		_ekonomi(f)
	for i in oyun.NPC.size():
		for j in range(i + 1, oyun.NPC.size()):
			_catisma(oyun.NPC[i], oyun.NPC[j])
	for f in oyun.NPC:
		_dogal(f)
		_sadakat(f)
		_ihanet(f)
		_afaroz_ay(f)
		_kadro(f)
		fk(f)["kayip"] = 0
	_baris_ve_savas()
	_geri_donus()

# ---------- ekonomi ----------
func _ekonomi(f: String) -> void:
	var d: Dictionary = fk(f)
	var gelir := 0.0
	for id in oyun.bolge:
		if oyun.hakim_of(id) == f:
			gelir += oyun.bolge[id]["servet"] * 90.0
	var gider: float = oyun.aile_uyeleri(f).size() * 12.0
	d["kasa"] = clampf(d["kasa"] + gelir - gider, -600.0, 6000.0)
	var say := bolge_say(f)
	var dm: float = 3.0 if gelir > gider else (-5.0 if d["kasa"] < 0.0 else -1.5)
	if say > 3:
		dm -= 3.0 * (say - 3)   # fazla büyüyen aile gevşer, iç çekişme artar
	dm -= d["kayip"] * 4.0
	d["moral"] = clampf(d["moral"] + dm + (50.0 - d["moral"]) * 0.1, 0.0, 100.0)

# ---------- aileler arası çatışma ----------
func _catisma(a: String, b: String) -> void:
	if not oyun.gerginlik.savasta(a, b):
		return
	var ka: float = kuvvet(a) * (0.7 + oyun.rng.randf() * 0.6)
	var kb: float = kuvvet(b) * (0.7 + oyun.rng.randf() * 0.6)
	var pa: float = ka / maxf(0.1, ka + kb)
	var la := _kayip(a, int(round((1.0 - pa) * 4.0 * oyun.rng.randf())), 1.0 - pa)
	var lb := _kayip(b, int(round(pa * 4.0 * oyun.rng.randf())), pa)
	if la + lb > 0:
		oyun.kayit("Savaş: %s %d, %s %d adam kaybetti." % [_ad(a), la, _ad(b), lb], "info")

# n asker kaybı + üst kadroya risk. Dönen: toplam kayıp (ölen üst kadro dahil).
func _kayip(f: String, n: int, risk: float) -> int:
	var say := 0
	for k in n:
		var ask: Array = uyeler(f, "asker")
		if ask.is_empty():
			break
		_sec(ask)["durum"] = "olu"
		say += 1
	for rutbe in [["kaptan", 0.09], ["ikinci", 0.04], ["don", 0.025], ["danisman", 0.03]]:
		var ad: Array = uyeler(f, rutbe[0])
		if not ad.is_empty() and oyun.rng.randf() < rutbe[1] * risk * 2.0:
			oyun.uye_oldu(_sec(ad)["uid"], "savaşta öldü")
			say += 1
	fk(f)["kayip"] += say
	return say

# ---------- doğal ölüm ----------
func _dogal(f: String) -> void:
	for u in uyeler(f):
		var p := 0.0
		match u["rutbe"]:
			"don": p = 0.006
			"ikinci", "danisman": p = 0.004
		if p > 0.0 and oyun.rng.randf() < p:
			oyun.uye_oldu(u["uid"], "hayata gözlerini yumdu")

# ---------- sadakat ----------
func _sadakat(f: String) -> void:
	var d: Dictionary = fk(f)
	var eksi: float = 6.0 if d["kasa"] < 0.0 else 0.0
	for u in uyeler(f):
		u["sadakat"] = clampf(u["sadakat"] + (d["moral"] - 50.0) / 12.0 - eksi + (oyun.rng.randf() - 0.5) * 7.0 + (55.0 - u["sadakat"]) * 0.05, 0.0, 100.0)

# ---------- ihanet: darbe / afaroz / firar / aileyi satma ----------
func _ihanet(f: String) -> void:
	for u in uyeler(f):
		if u["rutbe"] == "don" or u["sadakat"] >= 22.0 or oyun.rng.randf() > 0.3:
			continue
		var ad: String = oyun.uye_ad(u)
		var r: float = oyun.rng.randf()
		if u["rutbe"] == "ikinci" and u["hirs"] > 55.0 and r < 0.4:
			var don: Array = uyeler(f, "don")
			if don.is_empty():
				continue
			if oyun.rng.randf() < 0.45 + (u["hirs"] - 50.0) / 150.0:
				oyun.uye_oldu(don[0]["uid"], "%s tarafından devrildi" % u["ad"])
				u["sadakat"] = 70.0
			else:
				oyun.kayit("%s: %s darbe girişiminde yakalandı ve cezalandırıldı." % [_ad(f), ad], "warn")
				oyun.uye_oldu(u["uid"], "ihanetten idam edildi", true)
			continue
		if r < 0.35:
			_afaroz(f, u)
		else:
			_firar(f, u, r > 0.8)
		fk(f)["moral"] = maxf(0.0, fk(f)["moral"] - 4.0)

func _afaroz(f: String, u: Dictionary) -> void:
	u["durum"] = "afaroz"
	u["afaroz_t"] = oyun.t
	oyun.kayit("%s: %s afaroz edildi, aileden atıldı." % [_ad(f), oyun.uye_ad(u)], "info")

# sat=true: aileyi satar, gittiği aileye bu ailenin mahallelerinde nüfuz getirir.
func _firar(f: String, u: Dictionary, sat: bool) -> void:
	var adaylar: Array = oyun.NPC.filter(func(x): return x != f)
	var g := ""
	var en := -1.0
	for x in adaylar:
		var w: float = (kuvvet(x) + 1.0) * fk(x)["moral"] * (0.5 + oyun.rng.randf())
		if w > en:
			en = w
			g = x
	if g == "":
		return
	var eski: String = oyun.uye_ad(u)
	var r0: String = u["rutbe"]
	var yeni := "asker"
	if r0 in ["kaptan", "ikinci"] and uyeler(g, "kaptan").size() < 6:
		yeni = "kaptan"
	elif r0 == "danisman" and uyeler(g, "danisman").is_empty():
		yeni = "danisman"
	u["fak"] = g
	u["rutbe"] = yeni
	u["sadakat"] = 60.0
	u["eski"] = f
	var m := "%s, %s'i terk edip %s saflarına geçti (%s)." % [eski, _ad(f), _ad(g), oyun.uye_rutbe_ad(u)]
	if sat and r0 in ["kaptan", "ikinci", "danisman"]:
		var hedef: Array = oyun.bolge.keys().filter(func(id): return oyun.hakim_of(id) == f)
		if not hedef.is_empty():
			var id: String = hedef[oyun.rng.randi() % hedef.size()]
			oyun.add_inf(oyun.bolge[id], g, 9.0)
			m += " Üstelik %s'daki sırları satmış!" % oyun.harita.bolgeler[id]["ad"]
			oyun.gerginlik.ekle(g, f, 2.5, "ihanet")
	oyun.kayit(m, "warn")

func _afaroz_ay(f: String) -> void:
	for u in oyun.uyeler:
		if u["fak"] != f or u["durum"] != "afaroz" or oyun.rng.randf() > 0.25:
			continue
		if oyun.rng.randf() < 0.5:
			var adaylar: Array = oyun.NPC.filter(func(x): return x != f)
			var g: String = adaylar[oyun.rng.randi() % adaylar.size()]
			u["fak"] = g
			u["rutbe"] = "asker"
			u["durum"] = "aktif"
			u["sadakat"] = 55.0
			oyun.kayit("Afaroz edilen %s, %s'e sığındı." % [u["ad"], _ad(g)], "info")
		else:
			u["durum"] = "olu"   # sokaklarda kayboldu

# ---------- kadro: terfi, işe alım, işten çıkarma ----------
func _kadro(f: String) -> void:
	var d: Dictionary = fk(f)
	var say := bolge_say(f)
	var hedef_kap := clampi(2 + say, 2, 6)
	var hedef_ask := clampi(2 + 3 * say, 3, 14)
	if uyeler(f, "don").is_empty():
		var ik: Array = uyeler(f, "ikinci")
		if not ik.is_empty():
			ik[0]["rutbe"] = "don"
			oyun.kayit("%s: %s yeni %s oldu." % [_ad(f), ik[0]["ad"], oyun.RUTBE[f]["don"]], "warn")
		else:
			oyun.uye_yarat(f, "don")
	if uyeler(f, "ikinci").is_empty():
		var kap: Dictionary = _en_iyi(uyeler(f, "kaptan"))
		if not kap.is_empty():
			kap["rutbe"] = "ikinci"
			oyun.kayit("%s: %s %s oldu." % [_ad(f), kap["ad"], oyun.RUTBE[f]["ikinci"]], "info")
		else:
			oyun.uye_yarat(f, "ikinci")
	if uyeler(f, "danisman").is_empty():
		var ask0: Dictionary = _en_iyi(uyeler(f, "asker"))
		if not ask0.is_empty():
			ask0["rutbe"] = "danisman"
		else:
			oyun.uye_yarat(f, "danisman")
	if uyeler(f, "kaptan").size() < hedef_kap and d["kasa"] > 100.0:
		var ask: Dictionary = _en_iyi(uyeler(f, "asker"))
		if not ask.is_empty():
			ask["rutbe"] = "kaptan"
			oyun.kayit("%s: %s kaptanlığa terfi etti." % [_ad(f), ask["ad"]], "info")
	var yeni := 0
	while uyeler(f, "asker").size() < hedef_ask and d["kasa"] > 120.0 and yeni < 2:
		oyun.uye_yarat(f, "asker")
		d["kasa"] -= 60.0
		yeni += 1
	var asker: Array = uyeler(f, "asker")
	if asker.size() > hedef_ask + 2 and d["kasa"] < 0.0:
		_sec(asker)["durum"] = "ayrildi"

# ---------- barış & yeni savaşlar ----------
func _baris_ve_savas() -> void:
	for i in oyun.NPC.size():
		for j in range(i + 1, oyun.NPC.size()):
			var a: String = oyun.NPC[i]
			var b: String = oyun.NPC[j]
			if oyun.gerginlik.savasta(a, b):
				var zayif: String = a if kuvvet(a) < kuvvet(b) else b
				var dz: Dictionary = fk(zayif)
				var p := 0.1
				if dz["moral"] < 35.0 or dz["kasa"] < -100.0:
					p = 0.4
				if oyun.rng.randf() < p:
					oyun.gerginlik.baris(a, b)
	for f in oyun.NPC:
		var d: Dictionary = fk(f)
		var don: Array = uyeler(f, "don")
		if don.is_empty() or d["moral"] < 60.0 or d["kasa"] < 600.0 or don[0]["hirs"] < 65.0:
			continue
		var hedef := ""
		var en := 1e9
		for g in oyun.NPC:
			if g != f and not oyun.gerginlik.savasta(f, g) and kuvvet(g) < en:
				en = kuvvet(g)
				hedef = g
		if hedef != "" and oyun.rng.randf() < 0.05:
			oyun.gerginlik.ekle(f, hedef, 99.0, "%s'in genişleme hırsı" % _ad(f))

# ---------- oyuncu ile barış ----------
const BARIS_BEDEL := 250.0

func baris_teklif(f: String) -> Dictionary:
	if not oyun.gerginlik.savasta("oyuncu", f):
		return {"ok": false, "m": "%s ile savaşta değilsin." % _ad(f)}
	if not oyun.harcama(BARIS_BEDEL, "kirli"):
		return {"ok": false, "m": "Arabuluculuk hediyesi için $%d kirli para lazım." % int(BARIS_BEDEL)}
	var d: Dictionary = fk(f)
	var p: float = 0.35 + (0.25 if d["moral"] < 40.0 else 0.0) + (0.1 if d["kasa"] < 0.0 else 0.0) - oyun.ofke[f] / 200.0
	if oyun.rng.randf() < p:
		oyun.gerginlik.baris("oyuncu", f)
		oyun.ofke[f] *= 0.5
		return {"ok": true, "m": "%s barışa razı oldu. Savaş bitti." % _ad(f)}
	return {"ok": false, "m": "%s teklifi reddetti; hediyeni cebine koydu." % _ad(f)}

# Panel özeti
func ozet(f: String) -> String:
	var d: Dictionary = fk(f)
	var sv: Array = []
	for g in oyun.NPC + ["oyuncu"]:
		if g != f and oyun.gerginlik.savasta(f, g):
			sv.append(_ad(g) if g != "oyuncu" else "SEN")
	return "Adam %d · mahalle %d · kasa $%d · moral %d%s" % [oyun.aile_uyeleri(f).size(), bolge_say(f), int(d["kasa"]), int(d["moral"]), (" · SAVAŞTA: " + ", ".join(sv)) if not sv.is_empty() else " · barışta"]

# Mahallesi kalmayan / bir mahalleye sıkışan aile kasası ve morali yerindeyse güçlünün en zayıf mahallesine saldırıp geri dönmeyi dener.
func _geri_donus() -> void:
	var en := ""
	for f in oyun.NPC:
		if en == "" or bolge_say(f) > bolge_say(en):
			en = f
	if bolge_say(en) < 3:
		return
	for f in oyun.NPC:
		if f == en or bolge_say(f) > 1 or fk(f)["kasa"] < 300.0 or oyun.rng.randf() > 0.3:
			continue
		var h: Array = oyun.bolge.keys().filter(func(id): return oyun.hakim_of(id) == en)
		var id: String = h[0]
		for x in h:
			if oyun.bolge[x]["inf"].get(en, 0.0) < oyun.bolge[id]["inf"].get(en, 0.0):
				id = x
		oyun.add_inf(oyun.bolge[id], f, 10.0)
		fk(f)["kasa"] -= 200.0
		fk(f)["moral"] = minf(100.0, fk(f)["moral"] + 8.0)
		oyun.kayit("%s toparlanıyor: %s'daki adamlarını yeniden örgütledi." % [_ad(f), oyun.harita.bolgeler[id]["ad"]], "info")
		oyun.gerginlik.ekle(f, en, 3.0, "geri dönüş")
