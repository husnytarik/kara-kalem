extends RefCounted
# Kara Defter: aile üyelerine karşı kin kaydı. Kayıt açmak bedava ama kin seni yorar;
# kapatma yolları: af, tazminat, hesaplaşma. (prototype social.js'in Godot karşılığı)

const NEDENLER := ["Borç", "Hakaret", "İhanet", "İhbar", "Kan"]
const HESAP_BEDEL := 200.0

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"liste": [], "seq": 1}

func kayit_var(uid: int) -> bool:
	for k in oyun.kara["liste"]:
		if k["hedef"] == uid:
			return true
	return false

func ac(uid: int, neden: String, agirlik: int) -> Dictionary:
	var u: Dictionary = oyun.uye(uid)
	if u.is_empty() or u["durum"] != "aktif":
		return oyun.hata("Geçersiz hedef.")
	if kayit_var(uid):
		return oyun.hata("Bu kişi zaten defterde.")
	agirlik = clampi(agirlik, 1, 3)
	var K: Dictionary = oyun.kara
	K["liste"].append({"id": K["seq"], "hedef": uid, "neden": neden, "agirlik": agirlik, "gun0": oyun.t / oyun.DAY, "kin": 10.0 * agirlik})
	K["seq"] += 1
	oyun.yol_k.ekle("korku", 0.8 * agirlik)
	oyun.kayit("Kara Defter'e yazıldı: %s (%s, ağırlık %d). Kin seni yorar; kapatmak için af, tazminat ya da hesaplaşma var." % [oyun.uye_ad(u), neden, agirlik], "warn")
	return oyun.tamam()

# Korkun ve ününle tazminatın kabul ihtimali
func tazminat_olasilik(agirlik: int) -> float:
	var k: float = oyun.yol_k.puan("korku") + 0.4 * oyun.kis_k.taninma()
	return 1.0 / (1.0 + exp(-(k - 20.0 - 12.0 * agirlik) / 10.0))

func _bul(id: int) -> Dictionary:
	for k in oyun.kara["liste"]:
		if k["id"] == id:
			return k
	return {}

func _kapat(id: int) -> void:
	oyun.kara["liste"] = oyun.kara["liste"].filter(func(x): return x["id"] != id)

func kapat(id: int, yol: String) -> Dictionary:
	var k := _bul(id)
	if k.is_empty():
		return oyun.hata("Kayıt yok.")
	var u: Dictionary = oyun.uye(k["hedef"])
	var f: String = u["fak"]
	var ad: String = oyun.uye_ad(u)
	if yol == "af":
		_kapat(id)
		u["iliski"] += 25
		oyun.ofke[f] = maxf(0.0, oyun.ofke[f] - 6.0 * k["agirlik"])
		oyun.yol_k.ekle("korku", -1.5)
		oyun.yol_k.ekle("kanun", 0.8)
		oyun.kis_k.stres_ekle(-4.0)
		oyun.kayit("%s kaydını affettin. Öfke düştü, biraz korku kaybettin." % ad, "good")
		return oyun.tamam()
	if yol == "tazminat":
		var p := tazminat_olasilik(k["agirlik"])
		if oyun.rng.randf() < p:
			var m: float = 200.0 * k["agirlik"]
			oyun.kirli += m
			_kapat(id)
			u["iliski"] -= 5
			oyun.kayit("%s tazminat ödedi: $%d kirli. Kayıt kapandı (ihtimal %%%d idi)." % [ad, int(m), int(p * 100.0)], "good")
		else:
			u["iliski"] -= 10
			oyun.yol_k.ekle("korku", -2.0)
			oyun.ofke[f] = minf(100.0, oyun.ofke[f] + 3.0)
			oyun.kayit("%s tazminatı reddetti ve güldü (ihtimal %%%d idi). Boş tehdit korkunu düşürdü." % [ad, int(p * 100.0)], "bad")
		return oyun.tamam()
	if yol == "hesap":
		if oyun.adamlar.is_empty():
			return oyun.hata("Hesaplaşmak için ekipte adam olmalı.")
		if not oyun.harcama(HESAP_BEDEL, "kirli"):
			return oyun.hata("Kirli para yetmiyor ($%d)." % int(HESAP_BEDEL))
		_kapat(id)
		oyun.uye_oldu(u["uid"])
		oyun.yol_k.ekle("korku", 6.0)
		oyun.arama = minf(100.0, oyun.arama + 3.0)
		if oyun.rng.randf() < 0.35:
			oyun.arama = minf(100.0, oyun.arama + 5.0)
			oyun.kayit("Hesaplaşmayı gören biri karakolda ifade verdi (%s)." % ad, "bad")
		oyun.kis_k.stres_ekle(6.0)
		oyun.kayit("%s ile hesaplaştın. Kayıt kapandı; yeraltında adın duyuldu." % ad, "warn")
		return oyun.tamam()
	return oyun.hata("Bilinmeyen yol.")

# Günlük: kin yavaş söner
func gun() -> void:
	for k in oyun.kara["liste"]:
		k["kin"] *= 0.9985

# Aylık: yüksek kin stres getirir, küçük kayıtlar zamanaşımına uğrar, ölen hedefler silinir
func ay() -> void:
	var stres := 0
	for k in oyun.kara["liste"].duplicate():
		var u: Dictionary = oyun.uye(k["hedef"])
		if u.is_empty() or u["durum"] != "aktif":
			_kapat(k["id"])
			continue
		if k["kin"] >= 20.0:
			stres += 1
		var yas: int = oyun.t / oyun.DAY - int(k["gun0"])
		if k["agirlik"] == 1 and yas > 150:
			_kapat(k["id"])
			oyun.kayit("%s kaydı zamanaşımına uğradı." % oyun.uye_ad(u), "info")
	if stres > 0:
		oyun.kis_k.stres_ekle(minf(3.0, float(stres)))
		oyun.kayit("Kara Defter'deki kinler seni yoruyor.", "info")
