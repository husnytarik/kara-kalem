extends RefCounted
# Üç zafer yolu (web prototipindeki zafer.js): dürüst iş, belediye başkanlığı, hâkimiyet. Aylık kontrol edilir.
# Dosya (polis) = oyun.arama. Durum oyun.zf içinde (kayda girer).

const KAMPANYA_HEDEF := 6000.0
const DURUST_TEMIZ := 12000.0

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"kampanya": 0.0, "durust_ay": 0, "hakim_ay": 0}

func sahip_sayisi() -> int:
	return oyun.isy.values().filter(func(r): return r["sahip"]).size()

func harac_sayisi() -> int:
	return oyun.isy.values().filter(func(r): return r["haracli"]).size()

func _ort_sev() -> float:
	var l: Array = oyun.oyuncu_bolgeleri()
	if l.is_empty():
		return 0.0
	var t := 0.0
	for id in l:
		t += oyun.bolge[id]["sev"]
	return t / l.size()

func oy_orani() -> float:
	var n: int = oyun.oyuncu_bolgeleri().size()
	return clampf(12.0 + 0.3 * _ort_sev() + 22.0 * minf(1.0, oyun.zf["kampanya"] / KAMPANYA_HEDEF) + 4.0 * n - 0.3 * oyun.arama, 0.0, 100.0)

# Üç yolun koşul listesi: [{k, v, ok}]
func durum() -> Dictionary:
	var n: int = oyun.oyuncu_bolgeleri().size()
	var d: Dictionary = oyun.tarih()
	var durust := [
		{"k": "Sahip olduğun yer", "v": "%d / 4" % sahip_sayisi(), "ok": sahip_sayisi() >= 4},
		{"k": "Temiz para", "v": "%s / %s" % [oyun.para(oyun.temiz), oyun.para(DURUST_TEMIZ)], "ok": oyun.temiz >= DURUST_TEMIZ},
		{"k": "Polis dosyası (arama)", "v": "%d / en çok 15" % int(oyun.arama), "ok": oyun.arama <= 15.0},
		{"k": "Haraç bağlı yer", "v": "%d / 0" % harac_sayisi(), "ok": harac_sayisi() == 0},
		{"k": "Ekip", "v": "%d / en çok 2" % oyun.adamlar.size(), "ok": oyun.adamlar.size() <= 2},
		{"k": "Temiz sicil (gölge/korku)", "v": "%d / en çok 30" % int(oyun.yol_k.kotu()), "ok": oyun.yol_k.kotu() <= 30.0},
	]
	var baskan := [
		{"k": "Hakim olduğun mahalle", "v": "%d / en az 2" % n, "ok": n >= 2},
		{"k": "Seçim", "v": "her yıl 12. ay (%s)" % ("açık" if d["yil"] >= 2 else "2. yıldan sonra"), "ok": d["yil"] >= 2},
		{"k": "Kampanya fonu", "v": "%s / %s" % [oyun.para(oyun.zf["kampanya"]), oyun.para(KAMPANYA_HEDEF)], "ok": oyun.zf["kampanya"] >= KAMPANYA_HEDEF},
		{"k": "Tahmini oy", "v": "%%%d / %%50" % int(round(oy_orani())), "ok": oy_orani() >= 50.0},
		{"k": "Sicil (gölge/korku)", "v": "%d / en çok 50" % int(oyun.yol_k.kotu()), "ok": oyun.yol_k.kotu() < 50.0},
	]
	var hakim := [{"k": "Hakim olduğun mahalle", "v": "%d / 5" % n, "ok": n >= 5}]
	return {"durust": durust, "baskan": baskan, "hakim": hakim}

func kampanya_fon(miktar: int) -> Dictionary:
	if miktar <= 0:
		return oyun.hata("Geçersiz tutar.")
	if not oyun.harcama(float(miktar), "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(miktar))
	oyun.zf["kampanya"] += miktar
	oyun.kayit("Seçim kampanyasına %s aktardın (toplam %s)." % [oyun.para(miktar), oyun.para(oyun.zf["kampanya"])], "info")
	return oyun.tamam("Kampanya fonuna eklendi.")

func _bitir(tur: String, metin: String) -> void:
	oyun.son = {"tur": tur, "metin": metin}
	oyun.kayit(metin, "good" if tur == "zafer" else "bad")

# Ay sonunda (oyun._ay içinden).
func ay() -> void:
	if not oyun.son.is_empty():
		return
	var z: Dictionary = oyun.zf
	var d: Dictionary = oyun.tarih()
	var D := durum()
	z["durust_ay"] = z["durust_ay"] + 1 if D["durust"].all(func(x): return x["ok"]) else 0
	z["hakim_ay"] = z["hakim_ay"] + 1 if D["hakim"].all(func(x): return x["ok"]) else 0
	if z["durust_ay"] >= 2:
		_bitir("zafer", "İki ay üst üste temiz kasa, temiz dosya, sıfır haraç ve küçük bir ekip. Dükkânları ve apartmanları olan saygın bir iş adamısın; polisin sana dosyası bile yok. DÜRÜST İŞ ZAFERİ.")
		return
	if z["hakim_ay"] >= 2:
		_bitir("zafer", "Şehrin mahallelerinin neredeyse hepsi senin. Rakip aileler çekildi ya da boyun eğdi; kimse senden izin almadan şehirde iş yapamaz. HÂKİMİYET ZAFERİ.")
		return
	if d["ay_yil"] == 12 and d["yil"] >= 2 and oyun.oyuncu_bolgeleri().size() >= 2:
		var oy: float = oy_orani() + (oyun.rng.randf() - 0.5) * 10.0
		if oy >= 50.0:
			_bitir("zafer", "Seçim gecesi sayım bitti: oyların %%%d'ini aldın. Belediye başkanısın; belediye binasının merdivenlerinde alkışlanıyorsun. BAŞKANLIK ZAFERİ." % int(round(oy)))
			return
		oyun.kayit("Belediye seçimini kaybettin (%%%d). Kampanya fonu eridi." % int(round(oy)), "bad")
		z["kampanya"] = 0.0
