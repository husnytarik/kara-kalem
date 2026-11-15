extends RefCounted
# Yolda bir grupla karşılaşınca çıkan konuşma/seçenek mantığı. Arayüz yok, sadece kural.
# secenekler(g) -> [{id, ad, ipucu}], uygula(g, id) -> {metin, tur, bitir}
# "Çatışma" şimdilik otomatik hesaplanır; 3D savaş sahnesi gelince burası ona geçiş olacak.

var oyun: Node
var gruplar: Node3D
var rng := RandomNumberGenerator.new()

func _init(o: Node, gr: Node3D) -> void:
	oyun = o
	gruplar = gr
	rng.randomize()

# ---------- sunum ----------
func baslik(g: Dictionary) -> String:
	return "%s (%d kişi)" % [g["ad"], g["kisi"]]

func giris(g: Dictionary) -> String:
	match g["tur"]:
		"rakip":
			if g["mod"] == "kac":
				return "%s seni görünce kaçmaya çalışıyordu ama yetiştin. Gözleri korkuyla sende." % g["ad"]
			return "%s yolunu kesti. Elleri ceplerinde ama niyetleri belli. Onlar %d kişi, senin tarafta %d kişi var." % [g["ad"], g["kisi"], oyun.bos_adamlar().size() + 1]
		"polis":
			if oyun.arama >= 30.0:
				return "Polisler seni durdurdu: \"Aranan tipe benziyorsun.\" (Arama seviyen %d)" % int(oyun.arama)
			return "Devriye polisleri bir an seni süzdü, ama suçlu bir şey görmediler."
	return "%s ile konuşabilirsin." % g["ad"]

func _kuvvet(g: Dictionary) -> float:
	return g["kisi"] * (1.15 if g["tur"] == "polis" else 1.0)

func secenekler(g: Dictionary) -> Array:
	var s: Array = []
	match g["tur"]:
		"rakip":
			if g["mod"] == "kac":
				s.append({"id": "haraci", "ad": "Para iste", "ipucu": "Yenik düşmüş ekipten haraç koparırsın."})
				s.append({"id": "saldir", "ad": "Saldır", "ipucu": "Çatışma: güçler karşılaştırılır."})
				s.append({"id": "birak", "ad": "Bırak gitsin", "ipucu": "Yolların ayrılır."})
			else:
				s.append({"id": "pazarlik", "ad": "Yol parası öde ($%d)" % (25 * g["kisi"]), "ipucu": "Kirli para ver, bir gün seni rahat bıraksınlar."})
				s.append({"id": "blof", "ad": "Blöf yap", "ipucu": "Daha güçlüysen işe yarar; yoksa kavga çıkar."})
				s.append({"id": "kac", "ad": "Kaçmayı dene", "ipucu": "Sürat ve şansa bağlı. Olmazsa kavga."})
				s.append({"id": "teslim", "ad": "Teslim ol", "ipucu": "Paranın bir kısmını verirsin, canın yanmaz."})
				s.append({"id": "saldir", "ad": "Saldır", "ipucu": "Çatışma: güçler karşılaştırılır."})
		"polis":
			if oyun.arama >= 30.0:
				s.append({"id": "rusvet", "ad": "Rüşvet ver ($%d)" % int(oyun.arama * 8), "ipucu": "Kirli para. Kabul ederlerse aramayı düşürür."})
				s.append({"id": "kac", "ad": "Kaçmayı dene", "ipucu": "Yakalanırsan işler kötüleşir."})
				s.append({"id": "teslim", "ad": "Teslim ol", "ipucu": "Para cezası ödersin, arama sıfırlanır."})
				s.append({"id": "saldir", "ad": "Karşı koy", "ipucu": "Çatışma. Kazansan bile arama artar."})
			else:
				s.append({"id": "selam", "ad": "Selam ver, sohbet et", "ipucu": "Mahalle hakkında bilgi alırsın."})
				s.append({"id": "bahsis", "ad": "Gönül alma ($30)", "ipucu": "Aramayı biraz düşürür."})
				s.append({"id": "ayril", "ad": "Ayrıl", "ipucu": ""})
		"sivil":
			s.append({"id": "dedikodu", "ad": "Dedikodu dinle", "ipucu": "Mahalle havası hakkında bilgi."})
			s.append({"id": "haber", "ad": "Polis ve çeteleri sor", "ipucu": "Gruplar şu an nerede, öğrenirsin."})
			s.append({"id": "bahsis", "ad": "Bahşiş ver ($5)", "ipucu": "Mahallede sevgin artar."})
			s.append({"id": "gozdagi", "ad": "Gözdağı ver", "ipucu": "Biraz kirli para, ama korku artar, sevgi düşer, arama yükselir."})
			s.append({"id": "ayril", "ad": "Ayrıl", "ipucu": ""})
	return s

# ---------- sonuç ----------
func _r(metin: String, tur: String = "info", bitir: bool = true) -> Dictionary:
	return {"metin": metin, "tur": tur, "bitir": bitir}

func _bolge_id(g: Dictionary) -> String:
	var b: String = oyun.harita.bolge_at(g["pos"])
	return b if b != "" else g["ev"]

func uygula(g: Dictionary, id: String) -> Dictionary:
	match id:
		"ayril", "birak":
			gruplar.serbest_birak(g, 30)
			return _r("Yollarınız ayrıldı.")
		"pazarlik":
			var m: int = 25 * g["kisi"]
			if not oyun.harcama(m, "kirli"):
				return _r("Yeterli kirli paran yok ($%d lazım)." % m, "bad", false)
			gruplar.serbest_birak(g, 1440)
			oyun.kayit("%s'a yol parası ödedin ($%d)." % [g["ad"], m], "warn")
			return _r("Parayı sayıp başlarını salladılar: \"Bu seferlik geç.\" Bir gün seni rahat bırakacaklar.", "warn")
		"blof":
			var oran: float = oyun.guc() / _kuvvet(g)
			var p := clampf(0.2 + (oran - 1.0) * 0.35, 0.05, 0.85)
			if rng.randf() < p:
				gruplar.serbest_birak(g, 1440)
				g["mod"] = "kac"
				_bolge_tan(g, 2.0)
				oyun.kayit("%s blöfüne yenildi, geri çekildi." % g["ad"], "good")
				return _r("Kendinden emin konuştun. Birbirlerine baktılar ve gerilediler. Mahallede adın duyuldu.", "good")
			return _carpis(g, 0.85, "Blöfün tutmadı, ilk yumruk onlardan geldi!")
		"kac":
			var p2 := clampf((0.45 if g["tur"] == "rakip" else 0.35) + (oyun.guc() / _kuvvet(g) - 1.0) * 0.1, 0.1, 0.8)
			if rng.randf() < p2:
				gruplar.serbest_birak(g, 120)
				oyun.kayit("%s'dan kaçtın." % g["ad"], "info")
				return _r("Sokaklara dalıp izini kaybettirdin. Bir süre peşini bırakacaklar.", "good")
			return _carpis(g, 0.8, "Kaçarken yakalandın!")
		"teslim":
			if g["tur"] == "polis":
				var ceza := int(60 + oyun.arama * 5)
				var odenen := _para_ode(ceza)
				oyun.arama = 0.0
				gruplar.serbest_birak(g, 720)
				oyun.kayit("Polise teslim oldun, $%d ceza ödedin." % odenen, "bad")
				return _r("Karakolda ifade verdin, $%d ceza ödedin. Dosyan kapandı (arama sıfırlandı)." % odenen, "bad")
			var kayip := _para_orani(0.35)
			gruplar.serbest_birak(g, 1440)
			oyun.kayit("%s'a teslim oldun, $%d kaybettin." % [g["ad"], kayip], "bad")
			return _r("Ellerini kaldırdın. Ceplerini boşalttılar ($%d) ama dokunmadılar." % kayip, "bad")
		"haraci":
			var al: int = g["kisi"] * 15
			oyun.kirli += al
			gruplar.serbest_birak(g, 1440)
			_bolge_tan(g, 1.0)
			oyun.kayit("%s'dan $%d koparttın." % [g["ad"], al], "good")
			return _r("Cebindekileri çıkarttılar: $%d kirli para." % al, "good")
		"rusvet":
			var m2 := int(oyun.arama * 8)
			if not oyun.harcama(m2, "kirli"):
				return _r("Yeterli kirli paran yok ($%d lazım)." % m2, "bad", false)
			if rng.randf() < 0.7:
				oyun.arama = maxf(0.0, oyun.arama - 25.0)
				gruplar.serbest_birak(g, 720)
				oyun.kayit("Polise rüşvet verdin, arama düştü.", "warn")
				return _r("Zarfı cebine attı: \"Bu akşam seni görmedim.\" Arama düştü.", "warn")
			oyun.arama += 10.0
			return _r("Rüşveti reddedip seni sıkıştırdılar! Para gitti, arama arttı.", "bad", false)
		"bahsis":
			if g["tur"] == "polis":
				if not oyun.harcama(30, "kirli"):
					return _r("Yeterli kirli paran yok.", "bad", false)
				oyun.arama = maxf(0.0, oyun.arama - 8.0)
				gruplar.serbest_birak(g, 240)
				return _r("Sigara parası verdin. Gülümsediler, gözleri yumuşadı.", "good")
			if not oyun.harcama(5, "temiz"):
				return _r("Yeterli temiz paran yok.", "bad", false)
			var b: Dictionary = oyun.bolge[_bolge_id(g)]
			b["sev"] = minf(100.0, b["sev"] + 1.5)
			gruplar.serbest_birak(g, 60)
			return _r("Teşekkür ettiler: \"Sağ ol evlat, Allah razı olsun.\" Mahallede sevgin biraz arttı.", "good")
		"gozdagi":
			var b2: Dictionary = oyun.bolge[_bolge_id(g)]
			var al2 := 10 + rng.randi() % 21
			oyun.kirli += al2
			b2["kor"] = minf(100.0, b2["kor"] + 1.5)
			b2["sev"] = maxf(0.0, b2["sev"] - 2.0)
			oyun.arama += 4.0
			gruplar.serbest_birak(g, 120)
			oyun.kayit("%s gözdağı verip $%d aldın." % [g["ad"], al2], "warn")
			return _r("Göz korkuttun, $%d kirli para bıraktılar. Sevgi düştü, korku arttı." % al2, "warn")
		"saldir":
			return _carpis(g, 1.0, "Silahlar çekildi!")
		"selam":
			var bid := _bolge_id(g)
			var h: Dictionary = oyun.bolge[bid]
			var yorum := "Mahalle sakin, rahat ol." if h["huzur"] >= 55.0 else "Buralar son zamanlarda gergin, başımız ağrıyor."
			gruplar.serbest_birak(g, 60)
			return _r("\"%s\" dedi memur. (%s huzur: %d)" % [yorum, oyun.harita.bolgeler[bid]["ad"], int(h["huzur"])])
		"dedikodu":
			gruplar.serbest_birak(g, 60)
			return _r(_dedikodu(g))
		"haber":
			gruplar.serbest_birak(g, 60)
			return _r(_haber())
	return _r("...")

# ---------- yardımcılar ----------
func _bolge_tan(g: Dictionary, d: float) -> void:
	var b: Dictionary = oyun.bolge[_bolge_id(g)]
	b["tan"] = minf(100.0, b["tan"] + d)

func _para_ode(m: int) -> int:
	var odenen := 0
	var k := mini(int(oyun.kirli), m)
	oyun.kirli -= k
	odenen += k
	var t := mini(int(oyun.temiz), m - k)
	oyun.temiz -= t
	return odenen + t

func _para_orani(o: float) -> int:
	var top := 0
	var a := int(oyun.kirli * o)
	oyun.kirli -= a
	var b := int(oyun.temiz * o)
	oyun.temiz -= b
	top = a + b
	return top

# Otomatik çatışma. Hesap: iki tarafın gücü + zar. 3D savaş gelene kadar yer tutucu.
func _carpis(g: Dictionary, ceza: float, giris_yazi: String) -> Dictionary:
	var pw: float = oyun.guc() * ceza
	var ew := _kuvvet(g) * rng.randf_range(0.8, 1.25)
	var p := pw / (pw + ew)
	var kazan := rng.randf() < p
	var ad: String = g["ad"]
	if kazan:
		var kayip_dusman := maxi(1, int(ceil(g["kisi"] * 0.6)))
		g["kisi"] = maxi(0, g["kisi"] - kayip_dusman)
		var metin := "%s Çatışmayı kazandın: %s ekibinden %d kişi yere serildi." % [giris_yazi, ad, kayip_dusman]
		if g["tur"] == "rakip":
			var ganimet := kayip_dusman * 20
			oyun.kirli += ganimet
			metin += " Ganimet: $%d kirli para." % ganimet
			_bolge_tan(g, 3.0)
		else:
			oyun.arama += 15.0
			metin += " Ama polise el kaldırdın: arama arttı."
		metin += _yaralanma(0.15)
		if g["kisi"] == 0:
			gruplar.dagit(g)
		else:
			gruplar.serbest_birak(g, 1440)
			g["mod"] = "kac"
		oyun.kayit("%s çatışması: kazandın." % ad, "good")
		return _r(metin, "good")
	var metin2 := "%s Çatışmayı kaybettin." % giris_yazi
	var kayip := _para_orani(0.3)
	metin2 += " Cebinden $%d gitti." % kayip
	metin2 += _yaralanma(0.45)
	gruplar.serbest_birak(g, 1440)
	oyun.kayit("%s çatışması: kaybettin, $%d gitti." % [ad, kayip], "bad")
	return _r(metin2, "bad")

func _yaralanma(sans: float) -> String:
	var yazi := ""
	for a in oyun.bos_adamlar():
		if rng.randf() < sans:
			oyun.yarala(a, 1 + rng.randi() % 2)
			yazi += " %s yaralandı." % a["ad"]
	return yazi

func _dedikodu(g: Dictionary) -> String:
	var bid := _bolge_id(g)
	var h: Dictionary = oyun.bolge[bid]
	var ad: String = oyun.harita.bolgeler[bid]["ad"]
	var hk: String = oyun.hakim_of(bid)
	var olasi: Array = []
	olasi.append("\"%s'da bugünlerde %s söz sahibi, ona göre davran.\"" % [ad, oyun.hakim_ad(hk) if hk != "" else "kimse"])
	olasi.append("\"Mahallede huzur %s.\"" % ("yerinde" if h["huzur"] >= 55.0 else "kalmadı artık"))
	olasi.append("\"Senin hakkında konuşuyorlar: %s.\"" % ["bir kısmı sevgiyle, bir kısmı korkuyla anıyor" if h["sev"] >= 40.0 else "pek sevenin yok, dikkatli ol"])
	olasi.append("\"Polis son günlerde bu taraflara sık uğruyor.\"")
	olasi.append("\"Esnaf haraçtan şikâyetçi ama kimse ağzını açmaya cesaret edemiyor.\"")
	return "%s fısıldadı: %s" % [g["ad"], olasi[rng.randi() % olasi.size()]]

func _haber() -> String:
	var satir: Array = []
	for x in gruplar.liste:
		if x["tur"] == "sivil":
			continue
		var b: String = oyun.harita.bolge_at(x["pos"])
		satir.append("%s: %s civarında (%d kişi)" % [x["ad"], oyun.harita.bolgeler[b]["ad"] if b != "" else "yollarda", x["kisi"]])
	satir.shuffle()
	return "Duyduğuma göre: " + "; ".join(satir.slice(0, 4)) + "."
