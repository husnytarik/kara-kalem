extends RefCounted
# Adam bulma: ekibe adam, sokaktan değil, işi bilenlerin takıldığı yerlerden (bar, bilardo, boks salonu, dernek) alınır.
# Her mekânın günlük adayları vardır. Geceleri daha çok kişi çıkar; çevren ve gece alışkanlığın adayların sayısını/kalitesini artırır.

const ISIMLER := ["Sniffy", "Big Al", "Ruby", "Fingers", "Knuckles", "Scarface", "Moe", "Lefty", "Nails", "Pops", "Tiny", "Dutch", "Cheeks", "Bugsy", "Sparks", "Weasel", "Bones", "Rocco", "Dino", "Silent Sam"]
const NOTLAR := ["Eski liman kavgacısı", "Şehre yeni gelmiş", "Hapisten yeni çıkmış", "Bilardo hilebazı", "Barın bekçisi", "Eski denizci", "Boksör, borçlu", "Kaçakçı çırağı", "Sessiz, işini bilen", "Konuşkan ama güvenilir", "Işsiz, aç", "Polise mahkûm olmuş"]

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

func site_mi(i: int) -> bool:
	var ad := String(oyun.harita.yerler[i]["ad"]).to_lower()
	return ad.contains("bar") or ad.contains("tavern") or ad.contains("pool") or ad.contains("boxing") or ad.contains("social hall") or ad.contains("sailors")

func _gece() -> bool:
	var s: int = oyun.tarih()["saat"]
	return s >= 20 or s < 4

func _uret(i: int, gun: int) -> Dictionary:
	var K: RefCounted = oyun.kis_k
	var bid: String = oyun.harita.yerler[i]["bolge"]
	var b: Dictionary = oyun.bolge[bid]
	var cevre: float = K.oz("cevre")
	var n: int = 1 + oyun.rng.randi() % 2 + int(round(3.0 * cevre))
	if _gece():
		n += 1
	n = clampi(n, 1, 5)
	var l: Array = []
	var kul: Array = oyun.adamlar.map(func(a): return a["ad"])
	for k in n:
		var ad: String = ISIMLER[oyun.rng.randi() % ISIMLER.size()]
		if kul.has(ad):
			continue
		kul.append(ad)
		var q: int = 22 + oyun.rng.randi() % 40 + int(14.0 * cevre) + int(0.12 * b["kor"]) + (4 if _gece() else 0)
		var y := clampi(q + oyun.rng.randi() % 16 - 8, 15, 90)
		var bi := clampi(q + oyun.rng.randi() % 16 - 8, 15, 90)
		var z := clampi(q + oyun.rng.randi() % 16 - 8, 15, 90)
		var sad := clampi(35 + oyun.rng.randi() % 45 + int(30.0 * K.oz("sadakat")), 5, 100)
		var ort := (y + bi + z) / 3.0
		var fiyat := roundf((55.0 + ort * 1.1) * clampf(1.0 - 0.3 * K.oz("pazarlik"), 0.6, 1.3) / 5.0) * 5.0
		l.append({"ad": ad, "yumruk": y, "bicak": bi, "zeka": z, "sadakat": sad, "fiyat": fiyat,
			"silah": ["bicak", "bicak", "tabanca"][oyun.rng.randi() % 3], "not": NOTLAR[oyun.rng.randi() % NOTLAR.size()]})
	return {"gun": gun, "gece": _gece(), "l": l}

func liste(i: int) -> Array:
	var gun: int = int(oyun.t / oyun.DAY)
	var P: Dictionary = oyun.pazar
	var d: Dictionary = P.get(i, {})
	if d.is_empty() or d["gun"] != gun or (_gece() and not d["gece"] and d["l"].size() < 3):
		d = _uret(i, gun)
		P[i] = d
	return d["l"]

func tut(i: int, idx: int) -> Dictionary:
	var l: Array = liste(i)
	if idx < 0 or idx >= l.size():
		return oyun.hata("Aday yok.")
	if oyun.adamlar.size() >= oyun.EKIP_MAX:
		return oyun.hata("Ekip dolu (en fazla %d)." % oyun.EKIP_MAX)
	var c: Dictionary = l[idx]
	if not oyun.harcama(c["fiyat"], "kirli"):
		return oyun.hata("Para yetmiyor ($%d)." % int(c["fiyat"]))
	oyun._sayac += 1
	var a := {"id": oyun._sayac, "ad": c["ad"], "yumruk": c["yumruk"], "bicak": c["bicak"], "zeka": c["zeka"],
		"gorev": "", "silah": c["silah"], "sadakat": c["sadakat"]}
	oyun.adamlar.append(a)
	l.remove_at(idx)
	oyun.kis_k.oz_ekle("cilveli", 0.8)
	if _gece():
		oyun.kis_k.oz_ekle("gece_kusu", 1.0)
	oyun.kayit("%s ekibe katıldı (%d adam)." % [a["ad"], oyun.adamlar.size()], "info")
	oyun.degisti.emit()
	return oyun.tamam("%s ekibe katıldı." % a["ad"])
