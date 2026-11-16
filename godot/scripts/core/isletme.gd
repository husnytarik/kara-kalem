extends RefCounted
# Satın alınan işletmelerin işleyişi: itibar, fiyat, personel, olaylar, sızma (ajan) ve muhbirlik.
# Durum oyun.isy[i] içinde tutulur (kayıtla birlikte saklanır):
#   itibar (0-100), fiyat (0 ucuz, 1 normal, 2 pahalı), personel [{pid, ad, rol, beceri, sadakat, supheli, ajan, fak_bilinen, sab}],
#   olay {tur, ad, bitis(gün), carpan}
# Muhbirlik: oyun.muhbir[aile] = 0..3 (bilgi kalitesi, aylık gider).

const ROL := {"esnaf": "Tezgâhtar", "eglence": "Aşçı / Barmen", "luks": "Şef", "atolye": "Usta", "depo": "Depo şefi", "konut": "Kapıcı"}
const YEMEK := ["eglence", "luks", "esnaf"]
const FIYAT_AD := ["Ucuz", "Normal", "Pahalı"]
const FIYAT_CARPAN := [0.8, 1.0, 1.25]
const FIYAT_ITIBAR := [6.0, 0.0, -10.0]
const PERSONEL_MAX := 2
const MUHBIR_GIDER := 120
const MUHBIR_KURULUM := 200

var o: Node
var rng: RandomNumberGenerator

func _init(oyun: Node) -> void:
	o = oyun
	rng = oyun.rng

# ---------- durum ----------
func baslat(i: int) -> void:
	var r: Dictionary = o.isy[i]
	r["itibar"] = 50.0
	r["fiyat"] = 1
	r["personel"] = []
	r["olay"] = {}

func _ad(i: int) -> String:
	return o.harita.yerler[i]["ad"]

func _gun() -> int:
	return o.t / o.DAY

func rol_ad(i: int) -> String:
	return ROL[o.isy[i]["tur"]]

func yemek_mi(i: int) -> bool:
	return YEMEK.has(o.isy[i]["tur"])

func kalite(r: Dictionary) -> float:
	var p: Array = r["personel"]
	if p.is_empty():
		return 20.0
	var top := 0.0
	var agirlik := 0.0
	for k in p.size():
		var w := 0.7 if k == 0 else 0.3
		top += p[k]["beceri"] * w
		agirlik += w
	return top / agirlik

func olay_var(r: Dictionary) -> bool:
	return not r["olay"].is_empty() and _gun() < r["olay"]["bitis"]

func carpan(i: int) -> float:
	var r: Dictionary = o.isy[i]
	if not r.has("itibar"):
		return 1.0
	var m: float = (0.35 + 0.0125 * r["itibar"]) * FIYAT_CARPAN[r["fiyat"]]
	if olay_var(r):
		m *= r["olay"]["carpan"]
	return m

func gelir_yazi(i: int) -> String:
	return "%.0f%%" % (carpan(i) * 100.0)

# ---------- oyuncu eylemleri ----------
func fiyat_ayarla(i: int, f: int) -> Dictionary:
	o.isy[i]["fiyat"] = clampi(f, 0, 2)
	o.degisti.emit()
	return o.tamam()

func tut(i: int, usta: bool) -> Dictionary:
	var r: Dictionary = o.isy[i]
	if not r["sahip"]:
		return o.hata("Yalnızca sahip olduğun işletmede personel tutabilirsin.")
	if r["personel"].size() >= PERSONEL_MAX:
		return o.hata("Bu işletmede en fazla %d personel çalışır." % PERSONEL_MAX)
	var ucret := 250 if usta else 80
	if not o.harcama(ucret, "temiz"):
		return o.hata("Temiz para yetmiyor ($%d)." % ucret)
	o._pid += 1
	var p := {"pid": o._pid, "ad": o.ISIMLER[rng.randi() % o.ISIMLER.size()], "rol": rol_ad(i),
		"beceri": (55 + rng.randi() % 36) if usta else (25 + rng.randi() % 36),
		"sadakat": 40 + rng.randi() % 40, "supheli": 0, "ajan": "", "fak_bilinen": false, "sab": 0}
	# Rakip aileler, öfkeleri yükseldikçe sızmaya çalışır.
	var en := ""
	var en_o := 0.0
	for f in o.NPC:
		if o.ofke[f] > en_o:
			en_o = o.ofke[f]
			en = f
	if en != "" and rng.randf() < clampf(0.03 + en_o / 300.0, 0.0, 0.25) and o.t >= o.ajan_sogutma.get(en, 0):
		p["ajan"] = en
	r["personel"].append(p)
	o.kayit("%s: %s işe alındı (%s)." % [_ad(i), p["ad"], p["rol"]], "info")
	o.degisti.emit()
	return o.tamam("%s işe alındı. Beceri %d." % [p["ad"], p["beceri"]])

func _bul(i: int, pid: int) -> Dictionary:
	for p in o.isy[i]["personel"]:
		if p["pid"] == pid:
			return p
	return {}

func kov(i: int, pid: int) -> Dictionary:
	var p := _bul(i, pid)
	if p.is_empty():
		return o.hata("Personel bulunamadı.")
	o.isy[i]["personel"].erase(p)
	o.kayit("%s: %s kovuldu." % [_ad(i), p["ad"]], "info")
	o.degisti.emit()
	if p["ajan"] != "":
		return o.tamam("%s kapıdan çıkarıldı. Kimin adamı olduğunu ya da başka bir işte karşına çıkıp çıkmayacağını bilmiyorsun." % p["ad"])
	return o.tamam("%s kapıdan çıkarıldı." % p["ad"])

func sorustur(i: int, pid: int) -> Dictionary:
	var p := _bul(i, pid)
	if p.is_empty():
		return o.hata("Personel bulunamadı.")
	if o.adamlar.is_empty():
		return o.hata("Soruşturmayı yürütecek bir adamın yok.")
	if not o.harcama(60, "kirli"):
		return o.hata("Soruşturma için $60 kirli para lazım.")
	var zeka := 0
	for a in o.adamlar:
		zeka = maxi(zeka, a["zeka"])
	var seviye: int = o.muhbir.values().max() if not o.muhbir.is_empty() else 0
	var sans := 0.5 + zeka / 250.0 + seviye * 0.08
	if p["ajan"] != "":
		if rng.randf() < sans:
			p["supheli"] = 100
			p["fak_bilinen"] = true
			o.kayit("%s: %s'in %s adına çalıştığı ortaya çıktı!" % [_ad(i), p["ad"], o.FAK[p["ajan"]]["ad"]], "bad")
			o.degisti.emit()
			return o.tamam("Soruşturma sonuçlandı: %s, %s tarafından yerleştirilmiş. Şimdi karar senin." % [p["ad"], o.FAK[p["ajan"]]["ad"]])
		p["supheli"] = mini(100, p["supheli"] + 10)
		o.degisti.emit()
		return o.tamam("Kesin bir şey bulunamadı. Adam ustaymış ya da iz bırakmamış.")
	if rng.randf() < sans:
		p["supheli"] = 0
		o.degisti.emit()
		return o.tamam("%s temiz çıktı: kimseyle gizli bağı yok." % p["ad"])
	if rng.randf() < 0.3:
		p["supheli"] = mini(100, p["supheli"] + 20)
		o.degisti.emit()
		return o.tamam("Bulgular karışık. Hâlâ biraz şüpheli duruyor.")
	o.degisti.emit()
	return o.tamam("Soruşturmadan net bir sonuç çıkmadı.")

func infaz(i: int, pid: int) -> Dictionary:
	var p := _bul(i, pid)
	if p.is_empty():
		return o.hata("Personel bulunamadı.")
	if o.adamlar.is_empty():
		return o.hata("İşi yapacak bir adamın yok.")
	var b: Dictionary = o.bolge[o.harita.yerler[i]["bolge"]]
	var r: Dictionary = o.isy[i]
	r["personel"].erase(p)
	o.arama = minf(100.0, o.arama + 15.0)
	if p["ajan"] != "":
		var f: String = p["ajan"]
		o.ofke[f] = minf(100.0, o.ofke[f] + 12.0)
		o.ajan_sogutma[f] = o.t + 60 * o.DAY   # ağı çöktü, 60 gün yeni sızma denemesi olmaz
		b["kor"] = minf(100.0, b["kor"] + 6.0)
		b["tan"] = minf(100.0, b["tan"] + 4.0)
		for q in r["personel"]:
			q["sadakat"] = mini(100, q["sadakat"] + 10)
		o.kayit("%s: %s adına çalışan %s infaz edildi. Mahalle sesini kesti." % [_ad(i), o.FAK[f]["ad"], p["ad"]], "warn")
		o.degisti.emit()
		return o.tamam("%s infaz edildi. %s bu sızma ağını yeniden kurmak için zaman isteyecek; ama öfkeleri arttı. Arama yükseldi." % [p["ad"], o.FAK[f]["ad"]])
	b["sev"] = maxf(0.0, b["sev"] - 10.0)
	b["huzur"] = maxf(0.0, b["huzur"] - 8.0)
	b["kor"] = minf(100.0, b["kor"] + 6.0)
	for q in r["personel"]:
		q["sadakat"] = maxi(0, q["sadakat"] - 25)
	if o.adamlar.size() > 0 and rng.randf() < 0.25:
		var a: Dictionary = o.adamlar[rng.randi() % o.adamlar.size()]
		if a["gorev"] == "":
			o.adamlar.erase(a)
			o.kayit("%s bu masum kanı kaldıramadı ve ekipten ayrıldı." % a["ad"], "bad")
	o.kayit("%s: masum bir çalışanı (%s) infaz ettin. Mahalle seni sevmiyor." % [_ad(i), p["ad"]], "bad")
	o.degisti.emit()
	return o.tamam("%s'in hiçbir suçu yokmuş. Mahallede sevgin ve huzur düştü, personel korkuyor, arama arttı." % p["ad"])

# ---------- muhbirlik ----------
func muhbir_ayarla(f: String, seviye: int) -> Dictionary:
	var mevcut: int = o.muhbir[f]
	seviye = clampi(seviye, 0, 3)
	if seviye == mevcut:
		return o.tamam()
	if seviye > mevcut:
		var bedel := MUHBIR_KURULUM * (seviye - mevcut)
		if not o.harcama(bedel, "kirli"):
			return o.hata("Muhbir ağı için $%d kirli para lazım." % bedel)
	o.muhbir[f] = seviye
	o.kayit("%s içinde muhbir ağın: seviye %d." % [o.FAK[f]["ad"], seviye], "info")
	o.degisti.emit()
	return o.tamam()

func muhbir_goruyor(f: String, gereken: int) -> bool:
	return o.muhbir.get(f, 0) >= gereken

# ---------- günlük döngü ----------
func gunluk() -> void:
	var bugun_olay := false
	for i in o.isy:
		var r: Dictionary = o.isy[i]
		if not r["sahip"] or not r.has("itibar"):
			continue
		var bid: String = o.harita.yerler[i]["bolge"]
		var hedef: float = 20.0 + 0.6 * kalite(r) + FIYAT_ITIBAR[r["fiyat"]] + (o.bolge[bid]["huzur"] - 50.0) * 0.1
		r["itibar"] = clampf(r["itibar"] + (hedef - r["itibar"]) * 0.04, 0.0, 100.0)
		if not r["olay"].is_empty() and _gun() >= r["olay"]["bitis"]:
			r["olay"] = {}
		for p in r["personel"]:
			p["supheli"] = maxi(0, p["supheli"] - 1) if p["ajan"] == "" else p["supheli"]
			if p["ajan"] != "" and rng.randf() < 0.035:
				_sabotaj(i, p)
		if not bugun_olay and not olay_var(r) and rng.randf() < 0.012:
			bugun_olay = _rastgele(i)
	_ipucu_dene()

func _rastgele(i: int) -> bool:
	var r: Dictionary = o.isy[i]
	var ad := _ad(i)
	var bid: String = o.harita.yerler[i]["bolge"]
	var b: Dictionary = o.bolge[bid]
	var kal := kalite(r)
	var gun := _gun()
	var havuz: Array = []   # [ad, ağırlık]
	if yemek_mi(i):
		havuz.append(["curuk", 3.0 * (1.8 if kal < 40.0 else (0.5 if kal > 70.0 else 1.0))])
	havuz.append(["denetim", 1.5 if r["itibar"] < 45.0 else 0.6])
	havuz.append(["hirsiz", 1.5])
	havuz.append(["ovgu", 2.0 if r["itibar"] > 60.0 else 0.4])
	havuz.append(["yangin", 0.5])
	havuz.append(["akin", 1.0])
	var en_ofke := 0.0
	var rakip := ""
	var hk: String = o.hakim_of(bid)
	if hk != "" and hk != "oyuncu":
		rakip = hk
		en_ofke = o.ofke[hk]
	if rakip != "" and en_ofke >= 10.0:
		havuz.append(["tahrip", en_ofke / 15.0])
	var top := 0.0
	for h in havuz:
		top += h[1]
	var x := rng.randf() * top
	var tur: String = havuz[0][0]
	for h in havuz:
		x -= h[1]
		if x <= 0.0:
			tur = h[0]
			break
	match tur:
		"curuk":
			r["itibar"] = maxf(0.0, r["itibar"] - 14.0)
			r["olay"] = {"tur": tur, "ad": "Bozuk mal skandalı", "bitis": gun + 6, "carpan": 0.6}
			if not r["personel"].is_empty():
				r["personel"][0]["supheli"] = mini(100, r["personel"][0]["supheli"] + 15)
			o.kayit("%s: bozuk yiyecek çıktı, müşteriler yüzünü buruşturdu (itibar düştü)." % ad, "bad")
		"denetim":
			var ceza := mini(int(o.temiz), 60 + rng.randi() % 80)
			o.temiz -= ceza
			r["itibar"] = maxf(0.0, r["itibar"] - 3.0)
			o.kayit("%s: belediye denetçisi eksik buldu, $%d ceza kesti." % [ad, ceza], "warn")
		"hirsiz":
			var m := mini(int(o.temiz), 40 + rng.randi() % 120)
			o.temiz -= m
			o.kayit("%s: kasadan $%d eksik çıktı." % [ad, m], "warn")
		"ovgu":
			r["itibar"] = minf(100.0, r["itibar"] + 10.0)
			r["olay"] = {"tur": tur, "ad": "Gazete övgüsü", "bitis": gun + 5, "carpan": 1.2}
			o.kayit("%s: gazetede iyi bir yazı çıktı, müşteri akını başladı." % ad, "good")
		"yangin":
			var h := mini(int(o.temiz), 150 + rng.randi() % 200)
			o.temiz -= h
			r["olay"] = {"tur": tur, "ad": "Küçük yangın", "bitis": gun + 4, "carpan": 0.0}
			o.kayit("%s: küçük bir yangın çıktı, 4 gün kapalı (tamirat $%d)." % [ad, h], "bad")
		"akin":
			r["olay"] = {"tur": tur, "ad": "Mahalle şenliği", "bitis": gun + 3, "carpan": 1.3}
			o.kayit("%s: mahalle şenliği, kapıda kuyruk var." % ad, "good")
		"tahrip":
			r["itibar"] = maxf(0.0, r["itibar"] - 8.0)
			b["huzur"] = maxf(0.0, b["huzur"] - 3.0)
			o.kayit("%s: %s adamları camları kırıp müşteriyi korkuttu." % [ad, o.hakim_ad(rakip)], "bad")
	return true

func _sabotaj(i: int, p: Dictionary) -> void:
	var r: Dictionary = o.isy[i]
	var ad := _ad(i)
	var f: String = p["ajan"]
	var gun := _gun()
	var bid: String = o.harita.yerler[i]["bolge"]
	var b: Dictionary = o.bolge[bid]
	p["sab"] += 1
	p["supheli"] = mini(100, p["supheli"] + 25)
	for q in r["personel"]:
		if q != p and q["ajan"] == "":
			q["supheli"] = mini(100, q["supheli"] + 8)
	if yemek_mi(i) and rng.randf() < 0.6:
		var hasta := 2 + rng.randi() % 6
		var ol := 0
		if rng.randf() < 0.45:
			ol = 1 + rng.randi() % 2
		r["itibar"] = maxf(0.0, r["itibar"] - 35.0)
		r["olay"] = {"tur": "zehir", "ad": "Zehirlenme skandalı", "bitis": gun + 10, "carpan": 0.35}
		b["huzur"] = maxf(0.0, b["huzur"] - 5.0)
		b["sev"] = maxf(0.0, b["sev"] - 3.0)
		o.arama = minf(100.0, o.arama + (14.0 if ol > 0 else 6.0))
		o.kayit("%s: yemekten %d kişi zehirlendi%s! Mutfakta birileri oyun oynuyor olabilir." % [ad, hasta, ", %d kişi öldü" % ol if ol > 0 else ""], "bad")
	elif rng.randf() < 0.5:
		var m := mini(int(o.temiz), 250 + rng.randi() % 250)
		o.temiz -= m
		o.kayit("%s: kasadan büyük bir miktar ($%d) kayboldu." % [ad, m], "bad")
	else:
		o.arama = minf(100.0, o.arama + 12.0)
		r["itibar"] = maxf(0.0, r["itibar"] - 8.0)
		o.kayit("%s: polise isimsiz ihbar gitti, arama arttı." % ad, "bad")
	if p["sab"] >= 3 and rng.randf() < 0.5:   # iş bitince sızan çekilir
		r["personel"].erase(p)
		o.kayit("%s: %s bir sabah ortadan kayboldu." % [ad, p["ad"]], "warn")

# Muhbir ağı sayesinde önceden ipucu: seviye 1 belirsiz, 2 işletmeyi/kişiyi gösterir, 3 aileyi de söyler.
func _ipucu_dene() -> void:
	for i in o.isy:
		var r: Dictionary = o.isy[i]
		if not r["sahip"] or not r.has("personel"):
			continue
		for p in r["personel"]:
			if p["ajan"] == "":
				continue
			var s: int = o.muhbir[p["ajan"]]
			var seviye := 0
			for f in o.muhbir:
				seviye = maxi(seviye, o.muhbir[f])
			seviye = maxi(seviye, s)
			if seviye <= 0 or rng.randf() > 0.05 * (1.0 + 1.5 * seviye):
				continue
			if seviye == 1:
				o.kayit("Muhbirin fısıldadı: işletmelerinden birine bir sızma var.", "warn")
			elif seviye == 2:
				p["supheli"] = mini(100, p["supheli"] + 35)
				o.kayit("Muhbirin: %s'daki %s hakkında kuşkulu şeyler duyuluyor." % [_ad(i), p["ad"]], "warn")
			else:
				p["supheli"] = mini(100, p["supheli"] + 60)
				p["fak_bilinen"] = true
				o.kayit("Muhbirin kesin konuştu: %s'daki %s, %s'in adamı!" % [_ad(i), p["ad"], o.FAK[p["ajan"]]["ad"]], "bad")

func ay() -> void:
	for f in o.NPC:
		var s: int = o.muhbir[f]
		if s <= 0:
			continue
		var gider := MUHBIR_GIDER * s
		if not o.harcama(gider, "kirli"):
			o.muhbir[f] = s - 1
			o.kayit("%s içindeki muhbirlere ödeme yapamadın, ağın zayıfladı." % o.FAK[f]["ad"], "bad")
			continue
		if rng.randf() < 0.03 * s:
			o.muhbir[f] = s - 1
			o.ofke[f] = minf(100.0, o.ofke[f] + 8.0)
			o.kayit("%s içindeki bir muhbirin yakalandı! Ağın zayıfladı, %s öfkeli." % [o.FAK[f]["ad"], o.FAK[f]["ad"]], "bad")
