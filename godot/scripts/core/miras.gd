extends RefCounted
# DEDENİN MİRASI: dedenin dağılmış mafyasının kırıntıları ve oyuncunun yükselen "söz hakkı".
# Oyuncu başta "kimse"dir (tanınırlık ~0). Gücü (kudret, adam, korku/saygı/aile ünü, dokunulmazlık) arttıkça
# tanınır; tanınırlık eşikleri kararların kilidini açar: HİMAYE (< %20), LAĞVET (< %40), İNTİKAM/YIK (< %40), BİRLİK (hepsi bağlıysa).
# Karar başarısı = etkin güç / karşı güç. Karşı güç = grubun gücü + arkasındaki patron ailenin/siyasetin desteği.
# Durum: oyun.mir = {"tanin", "k": {id: {guc, durum, hos, son}}, "yol"}

const KIR := {
	"rihtim": {"ad": "Rıhtım Kardeşliği", "lider": "Salvatore 'Kör' Danza", "bolge": "docks", "guc": 26.0, "tavir": "korkak", "patron": "marchetti",
		"not": "Dedenin liman işlerini alıp Marchetti'nin gölgesine sığındılar."},
	"demir": {"ad": "Demiryolu Çetesi", "lider": "Ottavio Ferro", "bolge": "flats", "guc": 20.0, "tavir": "dusman", "patron": "obrien",
		"not": "Dedeye kin besleyen Ferro, torunun adını duyunca silah temizliyor."},
	"kasap": {"ad": "Kasap Sokağı Birliği", "lider": "Dona Pietra", "bolge": "southside", "guc": 22.0, "tavir": "bagimsiz", "patron": "tammany",
		"not": "Belediyeyle iş tutup kimseye bağlanmadan, kendi başına yaşıyorlar."},
	"muhafiz": {"ad": "Eski Muhafızlar", "lider": "Amca Tonio", "bolge": "eastside", "guc": 12.0, "tavir": "sadik", "patron": "",
		"not": "Dedeye ömür boyu bağlı kalan birkaç yaşlı adam. Hâlâ ev anahtarının kopyasını saklıyorlar."},
}
# kilit eşikleri (tanınırlık)
const ESIK_GORUN := 10.0
const ESIK_HIMAYE := 20.0
const ESIK_LAGVET := 40.0
const ESIK_BIRLIK := 60.0
const DURUM_AD := {"bagimsiz": "Bağımsız", "himaye": "Himayede", "bagli": "Bağlı (lağvedildi)", "yikik": "Yıkıldı"}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	var k := {}
	for id in KIR:
		k[id] = {"guc": KIR[id]["guc"], "durum": "bagimsiz", "hos": {"sadik": 40.0, "korkak": 0.0, "bagimsiz": 0.0, "dusman": -45.0}[KIR[id]["tavir"]], "son": 0}
	return {"tanin": 0.0, "k": k, "yol": ""}

func _m() -> Dictionary:
	if oyun.mir.is_empty():
		oyun.mir = yeni()
	return oyun.mir

func tanin() -> float:
	return float(_m()["tanin"])

func tanin_ekle(v: float) -> void:
	var m := _m()
	m["tanin"] = clampf(m["tanin"] + v, 0.0, 100.0)

func grup(id: String) -> Dictionary:
	return _m()["k"][id]

func gorunur() -> bool:
	return tanin() >= ESIK_GORUN

# ---------------- güç ----------------
# Oyuncunun ham gücü: mahalle kudreti, ekip, ün (korku/saygı/aile) ve dokunulmazlık (polis/yargıç/siyaset).
func guc_oyuncu() -> float:
	var g: float = oyun.kudret("oyuncu") * 1.2 + oyun.adamlar.size() * 3.0
	g += oyun.un_k.deger("korku") * 0.25 + oyun.un_k.deger("saygi") * 0.2 + oyun.un_k.deger("aile") * 0.2
	g += (oyun.nuf_k.dokun("polis") + oyun.nuf_k.dokun("yargic") + oyun.nuf_k.dokun("siyasi")) * 0.12
	# himayedeki/bağlı kırıntılar da senin gücündür
	for id in KIR:
		var d := grup(id)
		if d["durum"] == "himaye":
			g += d["guc"] * 0.5
		elif d["durum"] == "bagli":
			g += d["guc"] * 0.3
	return g

# Etkin güç: tanınırlıkla ağırlaşır. Kimse seni tanımıyorsa ağırlığın yarısı bile geçmez.
func etkin_guc() -> float:
	return guc_oyuncu() * (0.5 + tanin() / 100.0)

# Gruba karşı toplam direnç: kendi gücü + patronunun (sana düşmansa) ve siyasetin desteği.
func karsi_guc(id: String) -> float:
	var d := grup(id)
	var g: float = d["guc"]
	var p: String = KIR[id]["patron"]
	if p != "":
		var ger: float = oyun.gerginlik.gerginlik("oyuncu", p)
		var dost: float = clampf(1.0 - ger / 40.0, -1.0, 1.0)   # gerginlik düşükse patron tarafsız/yanında, yüksekse karşında
		g += oyun.kudret(p) * 0.35 * clampf(-dost + 0.3, 0.0, 1.0)
		if oyun.gerginlik.savasta("oyuncu", p):
			g += oyun.kudret(p) * 0.2
	return g

# Siyasi/sosyal destek çarpanı: Belediye Makinesiyle ilişkin ve siyasi nüfuzun karar şansını artırır.
func destek() -> float:
	var s: float = oyun.nuf_k.dokun("siyasi") * 0.004
	s += oyun.un_k.deger("saygi") * 0.002
	if oyun.gerginlik.gerginlik("oyuncu", "tammany") > 25.0:
		s -= 0.12
	return s

func oran(id: String) -> float:
	return etkin_guc() / maxf(1.0, karsi_guc(id))

# Karar başarı olasılığı (arayüzde gösterilir).
func sans(id: String, karar: String) -> float:
	var o: float = oran(id)
	var d := grup(id)
	var gerek: float = {"himaye": 0.8, "lagvet": 1.2, "yik": 1.5}[karar]
	var p: float = 0.5 + (o - gerek) * 0.45 + destek()
	if karar == "himaye":
		p += d["hos"] / 250.0            # sadık/hoşnut olanlar kolay kabul eder
	elif karar == "lagvet":
		p += d["hos"] / 400.0
	return clampf(p, 0.05, 0.95)

func kilit(karar: String) -> float:
	return {"himaye": ESIK_HIMAYE, "lagvet": ESIK_LAGVET, "yik": ESIK_LAGVET}[karar]

func uygun(id: String, karar: String) -> String:
	# "" = yapılabilir; aksi hâlde nedeni
	var d := grup(id)
	if tanin() < kilit(karar):
		return "Yeterince tanınmıyorsun (%%%d gerek)" % int(kilit(karar))
	if d["durum"] == "yikik":
		return "Artık yok"
	if karar == "himaye" and d["durum"] != "bagimsiz":
		return "Zaten bağlı"
	if karar != "himaye" and d["durum"] in ["bagli"] :
		return "Zaten lağvedildi"
	if karar == "himaye" and d["durum"] == "himaye":
		return "Zaten himayede"
	return ""

# ---------------- kararlar ----------------
func karar_ver(id: String, karar: String) -> Dictionary:
	var ned := uygun(id, karar)
	if ned != "":
		return {"ok": false, "msg": ned}
	var d := grup(id)
	var K: Dictionary = KIR[id]
	var p: float = sans(id, karar)
	var ok: bool = oyun.rng.randf() < p
	var patron: String = K["patron"]
	var msg := ""
	match karar:
		"himaye":
			if ok:
				d["durum"] = "himaye"
				d["hos"] = clampf(d["hos"] + 15.0, -100.0, 100.0)
				msg = "%s seni kabul etti: himayene girdiler. Her ay pay verecekler." % K["ad"]
				_dalga("himaye", id)
			else:
				d["hos"] = clampf(d["hos"] - 15.0, -100.0, 100.0)
				msg = "%s teklifini geri çevirdi. «Biz kimseye bağlı değiliz.»" % K["ad"]
				tanin_ekle(1.0)
		"lagvet":
			if ok:
				d["durum"] = "bagli"
				msg = "%s lağvedildi: adamlar dağıldı, bir kısmı sana bağlandı." % K["ad"]
				oyun.kirli += d["guc"] * 20.0
				_bolge_al(K["bolge"], 12.0)
				_dalga("lagvet", id)
			else:
				d["hos"] = clampf(d["hos"] - 35.0, -100.0, 100.0)
				msg = "%s itiraz etti, lağvı reddetti. Artık düşman." % K["ad"]
				if patron != "":
					oyun.gerginlik.ekle("oyuncu", patron, 3.0, "Dedenin mirası")
				oyun.kis_k.stres_ekle(3.0)
		"yik":
			if ok:
				d["durum"] = "yikik"
				d["guc"] = 0.0
				msg = "%s yıkıldı; dedenin intikamı alındı." % K["ad"]
				oyun.un_k.ekle("korku", 6.0)
				_bolge_al(K["bolge"], 20.0)
				if patron != "":
					oyun.gerginlik.ekle("oyuncu", patron, 5.0, "Dedenin mirası")
				_dalga("yik", id)
			else:
				d["hos"] = clampf(d["hos"] - 25.0, -100.0, 100.0)
				if not oyun.adamlar.is_empty():
					oyun.adamlar.remove_at(oyun.rng.randi() % oyun.adamlar.size())
					msg = "%s saldırıyı püskürttü; bir adamını kaybettin." % K["ad"]
				else:
					msg = "%s saldırıyı püskürttü." % K["ad"]
				if patron != "":
					oyun.gerginlik.ekle("oyuncu", patron, 4.0, "Dedenin mirası")
	d["son"] = oyun.t
	tanin_ekle(3.0 if ok else 1.0)
	oyun.kayit("MİRAS: " + msg, "good" if ok else "bad")
	_son_kontrol()
	oyun.degisti.emit()
	return {"ok": ok, "msg": msg}

func _bolge_al(bid: String, v: float) -> void:
	if oyun.bolge.has(bid):
		oyun.add_inf(oyun.bolge[bid], "oyuncu", v)

# Bir karar diğer gruplar üstünde yankılanır: güçlü olan sertleştikçe sadıklar sevinir, korkaklar eğilir, dik duranlar kızar.
func _dalga(tur: String, kaynak: String) -> void:
	for id in KIR:
		if id == kaynak:
			continue
		var d := grup(id)
		if d["durum"] == "yikik":
			continue
		var tv: String = KIR[id]["tavir"]
		var dh := 0.0
		match tur:
			"himaye": dh = 4.0 if tv != "dusman" else -3.0
			"lagvet": dh = {"sadik": 6.0, "korkak": 8.0, "bagimsiz": -8.0, "dusman": -12.0}[tv]
			"yik": dh = {"sadik": 3.0, "korkak": 14.0, "bagimsiz": -5.0, "dusman": -6.0}[tv]
		# korku/saygı yankıyı büyütür
		dh *= 1.0 + (oyun.un_k.deger("korku") - 50.0) / 200.0 if dh < 0.0 else 1.0
		d["hos"] = clampf(d["hos"] + dh, -100.0, 100.0)
		# patronlar da olanı izler: patron grubu yıkılan/lağvedilen kişiyi seven aileyse sana kızar
		if KIR[kaynak]["patron"] == KIR[id]["patron"] and KIR[id]["patron"] != "":
			oyun.gerginlik.ekle("oyuncu", KIR[id]["patron"], 1.0)

# ---------------- aylık ----------------
func ay() -> void:
	var m := _m()
	var g := guc_oyuncu()
	# tanınırlık güçle birlikte yavaş yavaş artar; asıl sıçrama olaylar ve kararlar ile gelir
	tanin_ekle(maxf(0.0, (g - 12.0) / 45.0))
	var toplam_pay := 0.0
	for id in KIR:
		var d := grup(id)
		match d["durum"]:
			"himaye":
				var pay: float = d["guc"] * (0.6 + oyun.un_k.deger("korku") / 200.0)
				oyun.kirli += pay
				toplam_pay += pay
				d["hos"] = clampf(d["hos"] + (1.0 if d["hos"] < 60.0 else 0.0), -100.0, 100.0)
				if d["hos"] < 15.0 and oyun.rng.randf() < 0.15:
					d["durum"] = "bagimsiz"
					oyun.kayit("MİRAS: %s himayeni bırakıp yeniden bağımsız oldu." % KIR[id]["ad"], "warn")
			"bagli":
				var pay2: float = d["guc"] * 0.25
				oyun.kirli += pay2
				toplam_pay += pay2
			"bagimsiz":
				# bağımsızlar yavaşça büyür; sana düşman olan ve seni geçecek kadar hoş olmayanlar bela çıkarır
				d["guc"] = minf(d["guc"] + 0.4, KIR[id]["guc"] * 1.8)
				var zit: float = -d["hos"]
				d["hos"] = clampf(d["hos"] + (1.0 if KIR[id]["tavir"] == "sadik" else -0.3 if KIR[id]["tavir"] == "dusman" else 0.0), -100.0, 100.0)
				# seni fark edip korkanlar (tanınırlık yüksek, hoşnut değil) rahatsız eder
				if tanin() >= ESIK_GORUN and d["hos"] < -20.0 and oyun.rng.randf() < 0.12 + zit / 600.0:
					var pp: String = KIR[id]["patron"]
					if pp != "":
						oyun.gerginlik.ekle("oyuncu", pp, 1.5, "Dedenin mirası")
					oyun.kayit("MİRAS: %s senin aleyhine dedikodu yayıyor; patronları huzursuz." % KIR[id]["ad"], "warn")
				# sadıklar küçük destek gönderir
				elif d["hos"] > 40.0 and KIR[id]["tavir"] == "sadik" and oyun.rng.randf() < 0.2:
					oyun.un_k.ekle("saygi", 0.6)
					oyun.kayit("MİRAS: %s sessizce desteğini gösterdi." % KIR[id]["ad"], "good")
	if toplam_pay > 0.0:
		oyun.kayit("MİRAS: kırıntılardan bu ay $%d pay geldi." % int(toplam_pay), "info")
	_son_kontrol()

func _son_kontrol() -> void:
	var m := _m()
	var bagli := 0
	var yikik := 0
	for id in KIR:
		var s: String = grup(id)["durum"]
		if s in ["himaye", "bagli"]:
			bagli += 1
		elif s == "yikik":
			yikik += 1
	if bagli == KIR.size() and m["yol"] == "":
		m["yol"] = "birlik"
		oyun.kaz_k.ver("miras_birlik")
	elif yikik + bagli == KIR.size() and yikik >= 2 and m["yol"] == "":
		m["yol"] = "intikam"
		oyun.kaz_k.ver("miras_intikam")

func ozet() -> String:
	return "Güç %d · etkin %d · tanınırlık %%%d" % [int(guc_oyuncu()), int(etkin_guc()), int(tanin())]
