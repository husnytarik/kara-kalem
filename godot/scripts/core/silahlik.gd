extends RefCounted
# Silah sistemi: sahip olduğun silahlar, nerede durdukları (üstünde / evde / bagajda), mühimmat, taşıma yükü,
# geliştirme (parçalar), bakım, alışma, imza silah, ganimet, polis araması ve savaş bağlantısı.
# Silahın verisi (hasar, menzil...) KATALOG'dan; kişiye özel hali `etkin()` ile hesaplanır (beceri, kusur, parça, aşınma).
#
# Durum (oyun.sil): {liste, eldeki, seq, m: {u:{}, e:{}, b:{}}, ruhsat, emanet, kayip}
#   yer: "u" üstünde · "e" evde · "b" araç bagajında

# hasar (vuruş başı), menzil (m), hiz (atış/sn), sarjor (0: yakın dövüş), yenileme (sn), sacilma (rad), pelet, fiyat (kirli $)
# tur: yakin|tabanca|pompali|otomatik|tufek · kal: mermi cinsi · el: 1/2 el · agirlik: kg · gizli: 0..1 (1 = hiç görünmez) · prestij: gösteriş
const KATALOG := {
	"yumruk": {"ad": "Yumruk", "tur": "yakin", "kal": "", "el": 1, "agirlik": 0.0, "gizli": 1.0, "prestij": 0, "yil": 0,
		"hasar": 12.0, "menzil": 2.3, "hiz": 1.5, "sarjor": 0, "yenileme": 0.0, "sacilma": 0.0, "pelet": 1, "fiyat": 0,
		"ac": "Çıplak eller. Herkesin vardır, kimse korkmaz."},
	"musta": {"ad": "Muşta", "tur": "yakin", "kal": "", "el": 1, "agirlik": 0.3, "gizli": 0.95, "prestij": 2, "yil": 1900,
		"hasar": 17.0, "menzil": 2.2, "hiz": 1.4, "sarjor": 0, "yenileme": 0.0, "sacilma": 0.0, "pelet": 1, "fiyat": 25,
		"ac": "Pirinç muşta. Cebe sığar ama polis görürse hemen suç sayar."},
	"bicak": {"ad": "Bıçak", "tur": "yakin", "kal": "", "el": 1, "agirlik": 0.3, "gizli": 0.9, "prestij": 2, "yil": 1900,
		"hasar": 24.0, "menzil": 2.5, "hiz": 1.8, "sarjor": 0, "yenileme": 0.0, "sacilma": 0.0, "pelet": 1, "fiyat": 40,
		"ac": "Çevik ve sessiz. Gürültü çıkarmadan iş görür."},
	"sopa": {"ad": "Beyzbol sopası", "tur": "yakin", "kal": "", "el": 1, "agirlik": 1.1, "gizli": 0.2, "prestij": 3, "yil": 1900,
		"hasar": 28.0, "menzil": 2.8, "hiz": 1.1, "sarjor": 0, "yenileme": 0.0, "sacilma": 0.0, "pelet": 1, "fiyat": 20,
		"ac": "Ağır ve yavaş ama vurduğunda anlaşılır. Gizlenmez."},
	"derringer": {"ad": "Remington Derringer", "tur": "tabanca", "kal": ".38", "el": 1, "agirlik": 0.3, "gizli": 1.0, "prestij": 8, "yil": 1866,
		"hasar": 20.0, "menzil": 14.0, "hiz": 1.6, "sarjor": 2, "yenileme": 1.4, "sacilma": 0.05, "pelet": 1, "fiyat": 90,
		"ac": "İki atışlık cep silahı. Hiçbir aramada bulunmaz ama yakında işe yarar."},
	"revolver": {"ad": "Smith & Wesson .38", "tur": "tabanca", "kal": ".38", "el": 1, "agirlik": 0.9, "gizli": 0.7, "prestij": 10, "yil": 1899,
		"hasar": 17.0, "menzil": 38.0, "hiz": 2.2, "sarjor": 6, "yenileme": 2.6, "sacilma": 0.03, "pelet": 1, "fiyat": 130,
		"ac": "Altı atışlık sağlam tambur. Tutukluk yapmaz, doldurması yavaştır."},
	"tabanca": {"ad": "Colt M1911", "tur": "tabanca", "kal": ".45", "el": 1, "agirlik": 1.1, "gizli": 0.65, "prestij": 12, "yil": 1911,
		"hasar": 18.0, "menzil": 40.0, "hiz": 2.8, "sarjor": 8, "yenileme": 1.6, "sacilma": 0.035, "pelet": 1, "fiyat": 150,
		"ac": "Ordunun .45'liği. Dengeli, hızlı doldurulur; şehrin her köşesinde bulunur."},
	"kesik": {"ad": "Kesik pompalı", "tur": "pompali", "kal": "12", "el": 2, "agirlik": 2.4, "gizli": 0.45, "prestij": 14, "yil": 1920,
		"hasar": 8.0, "menzil": 11.0, "hiz": 1.1, "sarjor": 2, "yenileme": 2.0, "sacilma": 0.22, "pelet": 7, "fiyat": 220,
		"ac": "Namlusu kesilmiş çifte. Palto altında taşınır, yakın mesafede acımaz."},
	"pompali": {"ad": "Winchester M1897", "tur": "pompali", "kal": "12", "el": 2, "agirlik": 3.6, "gizli": 0.15, "prestij": 16, "yil": 1897,
		"hasar": 9.0, "menzil": 20.0, "hiz": 1.0, "sarjor": 2, "yenileme": 2.2, "sacilma": 0.12, "pelet": 6, "fiyat": 300,
		"ac": "Siperlerde bile ünlenen pompalı. Gizlenmez, sokak köşelerinde söz sahibi yapar."},
	"tommy": {"ad": "Thompson M1921", "tur": "otomatik", "kal": ".45", "el": 2, "agirlik": 4.9, "gizli": 0.1, "prestij": 30, "yil": 1921,
		"hasar": 11.0, "menzil": 45.0, "hiz": 9.0, "sarjor": 30, "yenileme": 2.4, "sacilma": 0.07, "pelet": 1, "fiyat": 450,
		"ac": "\"Chicago daktilosu\". Ateş gücü eşsiz, ama herkes görür; mermi yer."},
	"tufek": {"ad": "Winchester M1895", "tur": "tufek", "kal": ".30", "el": 2, "agirlik": 4.0, "gizli": 0.1, "prestij": 20, "yil": 1895,
		"hasar": 40.0, "menzil": 70.0, "hiz": 0.8, "sarjor": 5, "yenileme": 3.0, "sacilma": 0.01, "pelet": 1, "fiyat": 380,
		"ac": "Kollu tüfek. Uzaktan tek atışta iş bitirir; yakın dövüşte hantal."},
}

# Mermi cinsleri: kutu (20 mermi) fiyatı, tek merminin ağırlığı (kg)
const KAL := {
	".45": {"ad": ".45 ACP", "kutu": 10.0, "agirlik": 0.030},
	".38": {"ad": ".38 Special", "kutu": 8.0, "agirlik": 0.025},
	"12": {"ad": "12 kalibre saçma", "kutu": 12.0, "agirlik": 0.050},
	".30": {"ad": ".30-30 tüfek", "kutu": 14.0, "agirlik": 0.035},
}
const KUTU := 20

# Geliştirme parçaları (firearm). Her biri 3 seviye.
const PARCA := {
	"namlu": {"ad": "Namlu", "ac": "Daha uzun/sağlam namlu: menzil artar, silah daha zor gizlenir."},
	"kabze": {"ad": "Kabze / kundak", "ac": "Ergonomik kabze: sapma azalır, silah biraz ağırlaşır."},
	"nisan": {"ad": "Nişangâh", "ac": "Daha iyi arpacık-gez: isabet artar."},
	"sarjor": {"ad": "Şarjör / tambur", "ac": "Daha fazla mermi alır, doldurması biraz uzar, ağırlaşır."},
	"kaplama": {"ad": "Kaplama / oyma", "ac": "Nikel, fildişi sap, el oyması: gösteriş. Silah senin imzan olur."},
}
const PARCA_FIYAT := [60.0, 130.0, 240.0]

const LAKAPLAR := ["Tatlı Kız", "Yaşlı Dost", "Küçük Tom", "Hanımefendi", "Dilsiz", "Pazartesi", "Son Söz", "Gece Kuşu", "Papaz", "Kara Gül", "Noel", "Avukat", "Sessiz Joe", "Barış"]
const KUSUR := {
	"miyop": {"ad": "Miyop", "ac": "Uzağı bulanık görürsün: isabet düşer, sapma artar. Gözlük kısmen düzeltir."},
	"tek_el": {"ad": "Tek elli", "ac": "Bir elin işe yaramıyor: pompalı, tüfek ve Tommy gibi iki elli silahlar kullanamazsın."},
	"yavas_el": {"ad": "Yavaş el", "ac": "Şarjör değiştirmen herkesten uzun sürer."},
	"titrek": {"ad": "Titrek el", "ac": "Eller titriyor: namlu sallanır, sapma artar."},
}
const TRUNK := {"ford": 18.0, "buick": 26.0, "packard": 34.0}   # bagaj kapasitesi (kg)
const YER_AD := {"u": "Üstünde", "e": "Evde", "b": "Bagajda"}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"liste": [], "eldeki": 0, "seq": 1, "m": {"u": {}, "e": {}, "b": {}}, "ruhsat": 0, "emanet": [], "kayip": []}

# ---------- başlangıç ----------
func baslat() -> void:
	var p: Dictionary = oyun.profil
	oyun.sil = yeni()
	var w: Dictionary = {}
	match p.get("koken", "yerli"):
		"yerli":
			w = ver("revolver", "miras", "Babanın .38'i", "Baban ölünce eline geçen tek şey. Namlusu çizik, kabzası aşınmış; ama senin yanında büyüdü.", 10.0)
			muh_ekle("u", ".38", 18)
			muh_ekle("e", ".38", 24)
		"aile":
			w = ver("tabanca", "aile", "", "Ailenin sana verdiği ilk emanet.", 2.0)
			muh_ekle("u", ".45", 16)
			muh_ekle("e", ".45", 30)
			oyun.sil["ruhsat"] = oyun.t + 120 * oyun.DAY
		_:
			w = ver("bicak", "getirdi", "", "Gemiye bindiğinde yanındaydı; şimdi sokağın ilk dersini bununla veriyorsun.", 0.0)
	if not w.is_empty():
		oyun.sil["eldeki"] = w["uid"]
		sync()
	# bedensel kusurlar: bazen doğuştan, çoğu zaman sokaktan
	var kk: Dictionary = {}
	if oyun.rng.randf() < 0.17:
		kk["miyop"] = true
	if oyun.rng.randf() < 0.08:
		kk["yavas_el"] = true
	if oyun.rng.randf() < 0.06:
		kk["titrek"] = true
	oyun.kis["kusur"] = kk
	oyun.kis["gozluk"] = false

# Eski kayıt: sadece oyuncu_silah vardı.
func migrate() -> void:
	oyun.sil = yeni()
	var tip: String = oyun.oyuncu_silah
	if KATALOG.has(tip) and tip != "yumruk":
		var w := ver(tip, "eski", "", "", 0.0)
		oyun.sil["eldeki"] = w["uid"]
		var kal: String = KATALOG[tip]["kal"]
		if kal != "":
			muh_ekle("u", kal, 24)
	if not oyun.kis.has("kusur"):
		oyun.kis["kusur"] = {}
	sync()

func S() -> Dictionary:
	return oyun.sil

# Yeni silah nesnesi oluşturur (üstüne verir). Ödeme yapmaz.
func ver(tip: String, kaynak: String, ad: String = "", yazi: String = "", prestij_ek: float = 0.0, sahip: String = "", yer: String = "u") -> Dictionary:
	var s: Dictionary = oyun.sil
	var w: Dictionary = {"uid": s["seq"], "tip": tip, "ad": ad, "durum": 90.0 if kaynak in ["ganimet", "eski"] else 100.0, "mod": {},
		"yer": yer, "kills": 0, "alisma": 0.0, "kaynak": kaynak, "yazi": yazi, "prestij_ek": prestij_ek, "sahip": sahip,
		"gun": oyun.tarih()["gun"]}
	s["seq"] += 1
	s["liste"].append(w)
	return w

func bul(uid: int) -> Dictionary:
	for w in oyun.sil["liste"]:
		if w["uid"] == uid:
			return w
	return {}

func eldeki() -> Dictionary:
	var uid: int = oyun.sil.get("eldeki", 0)
	if uid == 0:
		return {}
	var w := bul(uid)
	return w if (not w.is_empty() and w["yer"] == "u") else {}

func sync() -> void:
	var w := eldeki()
	oyun.oyuncu_silah = w["tip"] if not w.is_empty() else "yumruk"

func ad(w: Dictionary) -> String:
	var kat: String = KATALOG[w["tip"]]["ad"]
	return ("%s — %s" % [w["ad"], kat]) if w["ad"] != "" else kat

func kisa_ad(w: Dictionary) -> String:
	return w["ad"] if w["ad"] != "" else KATALOG[w["tip"]]["ad"]

func parca_var(tip: String) -> bool:
	return KATALOG[tip]["sarjor"] > 0

func parca_listesi(tip: String) -> Array:
	return ["namlu", "kabze", "nisan", "sarjor", "kaplama"] if parca_var(tip) else ["kaplama"]

func lv(w: Dictionary, p: String) -> int:
	return int(w["mod"].get(p, 0))

# ---------- kusurlar ----------
func kusur(id: String) -> bool:
	return oyun.kis.get("kusur", {}).get(id, false)

func kusur_ekle(id: String) -> bool:
	var k: Dictionary = oyun.kis.get("kusur", {})
	if k.get(id, false):
		return false
	k[id] = true
	oyun.kis["kusur"] = k
	oyun.kayit("Kalıcı bir sakatlık: \"%s\" — %s" % [KUSUR[id]["ad"], KUSUR[id]["ac"]], "bad")
	if id == "tek_el":
		var w := eldeki()
		if not w.is_empty() and KATALOG[w["tip"]]["el"] == 2:
			oyun.sil["eldeki"] = 0
			sync()
			oyun.kayit("İki elli silahını artık tutamıyorsun; elinden bıraktın.", "warn")
	return true

func gozluk_al() -> Dictionary:
	if not kusur("miyop"):
		return oyun.hata("Gözlüğe ihtiyacın yok.")
	if oyun.kis.get("gozluk", false):
		return oyun.hata("Zaten gözlüğün var.")
	if not oyun.harcama(45.0, "temiz"):
		return oyun.hata("Temiz para yetmiyor ($45).")
	oyun.kis["gozluk"] = true
	oyun.kayit("Gözlük taktırdın: miyopluğun kısmen düzeldi.", "good")
	return oyun.tamam("Gözlük aldın.")

# ---------- yük / kapasite ----------
func ekip_n() -> int:
	return oyun.bos_adamlar().size()

func kapasite(yer: String) -> float:
	match yer:
		"u":
			var guc: float = oyun.ozet.get("stat", {}).get("guc", 5)
			return 6.0 + guc * 0.6 + 2.5 * minf(6.0, float(ekip_n()))
		"b":
			var t: String = oyun.arac.get("tip", "")
			return TRUNK.get(t, 0.0)
		_:
			return 999.0

func silah_agirlik(w: Dictionary) -> float:
	var a: float = KATALOG[w["tip"]]["agirlik"]
	a += 0.2 * lv(w, "kabze") + 0.15 * lv(w, "sarjor") + 0.1 * lv(w, "namlu")
	return a

func muh(yer: String, kal: String) -> int:
	return int(oyun.sil["m"][yer].get(kal, 0))

func muh_toplam(yer: String) -> int:
	var n := 0
	for k in oyun.sil["m"][yer]:
		n += int(oyun.sil["m"][yer][k])
	return n

func muh_ekle(yer: String, kal: String, n: int) -> void:
	var m: Dictionary = oyun.sil["m"][yer]
	m[kal] = maxi(0, int(m.get(kal, 0)) + n)

func yuk(yer: String) -> float:
	var top := 0.0
	for w in oyun.sil["liste"]:
		if w["yer"] == yer:
			top += silah_agirlik(w)
	for k in oyun.sil["m"][yer]:
		top += float(oyun.sil["m"][yer][k]) * float(KAL[k]["agirlik"])
	return top

# Aşırı yük oranı (0 = yok). Bagaj araç yoksa kapasite 0.
func asiri() -> float:
	var kap := kapasite("u")
	return maxf(0.0, yuk("u") / kap - 1.0)

func form_ceza() -> float:
	return minf(0.3, asiri() * 0.6)

# Araç kullanılıyorsa bagajdaki silahlar da "taşınıyor" sayılır (polis aramasında).
func bagaj_aktif() -> bool:
	return oyun.arac.get("tip", "") != "" and oyun.arac.get("kullan", false)

# ---------- el değiştirme ----------
func tasi(uid: int, yer: String) -> Dictionary:
	var w := bul(uid)
	if w.is_empty():
		return oyun.hata("Silah yok.")
	if w["yer"] == yer:
		return oyun.hata("Zaten orada.")
	if not YER_AD.has(yer):
		return oyun.hata("Geçersiz yer.")
	if yer == "b" and kapasite("b") <= 0.0:
		return oyun.hata("Aracın yok; bagaj kullanamazsın.")
	var ag := silah_agirlik(w)
	if yer != "e" and yuk(yer) + ag > kapasite(yer) + 0.001:
		return oyun.hata("%s taşıma sınırı dolu (%.1f/%.1f kg)." % [YER_AD[yer], yuk(yer), kapasite(yer)])
	var eski: String = w["yer"]
	w["yer"] = yer
	if oyun.sil["eldeki"] == uid and yer != "u":
		oyun.sil["eldeki"] = 0
	sync()
	oyun.degisti.emit()
	return oyun.tamam("%s: %s → %s." % [kisa_ad(w), YER_AD[eski], YER_AD[yer]])

func kusan(uid: int) -> Dictionary:
	var w := bul(uid)
	if w.is_empty() or w["yer"] != "u":
		return oyun.hata("Önce silahı üstüne al.")
	if KATALOG[w["tip"]]["el"] == 2 and kusur("tek_el"):
		return oyun.hata("Tek elinle iki elli silah tutamazsın.")
	oyun.sil["eldeki"] = uid
	sync()
	oyun.degisti.emit()
	return oyun.tamam("%s elinde." % kisa_ad(w))

func birak_el() -> void:
	oyun.sil["eldeki"] = 0
	sync()
	oyun.degisti.emit()

func muh_tasi(kal: String, n: int, kaynak: String, hedef: String) -> Dictionary:
	n = mini(n, muh(kaynak, kal))
	if n <= 0:
		return oyun.hata("Taşınacak mermi yok.")
	if hedef == "b" and kapasite("b") <= 0.0:
		return oyun.hata("Aracın yok.")
	if hedef != "e":
		var bos := kapasite(hedef) - yuk(hedef)
		var sigan := int(floor(bos / float(KAL[kal]["agirlik"])))
		n = mini(n, sigan)
		if n <= 0:
			return oyun.hata("%s taşıma sınırı dolu." % YER_AD[hedef])
	muh_ekle(kaynak, kal, -n)
	muh_ekle(hedef, kal, n)
	oyun.degisti.emit()
	return oyun.tamam("%d mermi (%s) taşındı." % [n, KAL[kal]["ad"]])

# ---------- satın alma ----------
func mekan_indirim(tur: String) -> float:
	# Sahip olduğun mekânlar: depo/liman silah ve mermiyi, atölye parçaları, lüks/eğlence kaplamayı ucuzlatır.
	var d := 0.0
	for i in oyun.isy:
		var r: Dictionary = oyun.isy[i]
		if not r["sahip"]:
			continue
		match r["tur"]:
			"depo":
				if tur in ["silah", "mermi"]:
					d = maxf(d, 0.15)
			"atolye":
				if tur in ["parca", "bakim"]:
					d = maxf(d, 0.3)
			"luks", "eglence":
				if tur == "kaplama":
					d = maxf(d, 0.25)
	return d

func _pazarlik() -> float:
	return clampf(1.0 - 0.5 * oyun.yet_k.etki("pazarlik") + 0.3 * -oyun.kis_k.oz("pazarlik"), 0.5, 1.3)

func fiyat(tip: String) -> int:
	return int(round(KATALOG[tip]["fiyat"] * _pazarlik() * (1.0 - mekan_indirim("silah"))))

func al(tip: String) -> Dictionary:
	if not KATALOG.has(tip) or tip == "yumruk":
		return oyun.hata("Böyle bir silah yok.")
	var f := fiyat(tip)
	if not oyun.harcama(f, "kirli"):
		return oyun.hata("Kirli para yetmiyor ($%d)." % f)
	var w := ver(tip, "satin")
	var yer := "u"
	if yuk("u") + silah_agirlik(w) > kapasite("u"):
		yer = "e"
		w["yer"] = "e"
	if oyun.sil["eldeki"] == 0 and yer == "u":
		if not (KATALOG[tip]["el"] == 2 and kusur("tek_el")):
			oyun.sil["eldeki"] = w["uid"]
	sync()
	oyun.kayit("%s aldın (%s)." % [KATALOG[tip]["ad"], oyun.para(f)], "info")
	oyun.degisti.emit()
	return oyun.tamam("%s aldın%s." % [KATALOG[tip]["ad"], "" if yer == "u" else " (yük dolu: eve bırakıldı)"])

func mermi_fiyat(kal: String) -> int:
	return int(round(KAL[kal]["kutu"] * _pazarlik() * (1.0 - mekan_indirim("mermi"))))

func mermi_al(kal: String) -> Dictionary:
	var f := mermi_fiyat(kal)
	if not oyun.harcama(f, "kirli"):
		return oyun.hata("Kirli para yetmiyor ($%d)." % f)
	var yer := "u"
	if yuk("u") + KUTU * float(KAL[kal]["agirlik"]) > kapasite("u"):
		yer = "e"
	muh_ekle(yer, kal, KUTU)
	oyun.degisti.emit()
	return oyun.tamam("%d mermi (%s) aldın%s." % [KUTU, KAL[kal]["ad"], "" if yer == "u" else " (yük dolu: eve bırakıldı)"])

func sat_fiyat(w: Dictionary) -> int:
	var f: float = KATALOG[w["tip"]]["fiyat"] * 0.45 * (w["durum"] / 100.0 * 0.5 + 0.5)
	for p in w["mod"]:
		f += PARCA_FIYAT[0] * int(w["mod"][p]) * 0.25
	return int(round(f))

func sat(uid: int) -> Dictionary:
	var w := bul(uid)
	if w.is_empty():
		return oyun.hata("Silah yok.")
	if w["prestij_ek"] >= 15.0 or w["sahip"] != "":
		return oyun.hata("Bu silah senin hikâyen; satmazsın.")
	var f := sat_fiyat(w)
	oyun.kirli += f
	if oyun.sil["eldeki"] == uid:
		oyun.sil["eldeki"] = 0
	oyun.sil["liste"].erase(w)
	sync()
	oyun.kayit("%s satıldı (%s)." % [ad(w), oyun.para(f)], "info")
	oyun.degisti.emit()
	return oyun.tamam("Sattın: %s." % oyun.para(f))

# ---------- geliştirme / bakım ----------
func parca_maliyet(w: Dictionary, p: String) -> int:
	var l := lv(w, p)
	if l >= 3:
		return -1
	var f: float = PARCA_FIYAT[l] * (1.0 + KATALOG[w["tip"]]["fiyat"] / 600.0)
	if p == "kaplama":
		f *= 1.5 * (1.0 - mekan_indirim("kaplama"))
	else:
		f *= 1.0 - mekan_indirim("parca")
	return int(round(f * _pazarlik()))

func parca_yap(uid: int, p: String) -> Dictionary:
	var w := bul(uid)
	if w.is_empty() or not (p in parca_listesi(w["tip"])):
		return oyun.hata("Bu silaha takılmaz.")
	var f := parca_maliyet(w, p)
	if f < 0:
		return oyun.hata("Bu parça son seviyede.")
	if not oyun.harcama(f, "kirli"):
		return oyun.hata("Kirli para yetmiyor ($%d)." % f)
	w["mod"][p] = lv(w, p) + 1
	oyun.bekle(60 * lv(w, p))
	oyun.kayit("%s: %s %d. seviye (%s)." % [kisa_ad(w), PARCA[p]["ad"], lv(w, p), oyun.para(f)], "good")
	oyun.degisti.emit()
	return oyun.tamam("%s geliştirildi." % PARCA[p]["ad"])

func bakim(uid: int) -> Dictionary:
	var w := bul(uid)
	if w.is_empty():
		return oyun.hata("Silah yok.")
	if w["durum"] >= 99.0:
		return oyun.hata("Silah zaten pırıl pırıl.")
	var f := int(round(6.0 * (1.0 - mekan_indirim("bakim"))))
	if not oyun.harcama(f, "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(f))
	w["durum"] = minf(100.0, w["durum"] + 35.0 + 40.0 * oyun.yet_k.etki("tamir"))
	oyun.yet_k.ekle("bakim", 0.5)
	oyun.bekle(30)
	oyun.degisti.emit()
	return oyun.tamam("Silah yağlanıp temizlendi.")

func lakap(uid: int) -> Dictionary:
	var w := bul(uid)
	if w.is_empty():
		return oyun.hata("Silah yok.")
	var i: int = LAKAPLAR.find(w["ad"])
	w["ad"] = LAKAPLAR[(i + 1) % LAKAPLAR.size()]
	oyun.degisti.emit()
	return oyun.tamam("Silahının adı: %s." % w["ad"])

# ---------- hesaplar ----------
func sinif(tip: String) -> String:
	match KATALOG[tip]["tur"]:
		"yakin": return "yakin"
		"tabanca": return "tabanca"
		"otomatik": return "oto"
		_: return "uzun"

func yet_id(tip: String) -> String:
	match KATALOG[tip]["tur"]:
		"yakin": return "yakin"
		"tabanca": return "tabanca"
		"otomatik": return "otomatik"
		_: return "uzun"

func prestij(w: Dictionary) -> float:
	var p: float = KATALOG[w["tip"]]["prestij"] + w["prestij_ek"]
	p += 7.0 * lv(w, "kaplama") + 1.5 * (lv(w, "namlu") + lv(w, "kabze") + lv(w, "nisan") + lv(w, "sarjor"))
	p += minf(25.0, w["kills"] * 0.8)
	return p

func unvan(w: Dictionary) -> String:
	var k: int = w["kills"]
	if k >= 25:
		return "Efsane"
	if k >= 12:
		return "Ünlü"
	if k >= 5:
		return "Tanınmış"
	if k >= 1:
		return "Kanlı"
	return ""

func alisma_etki(w: Dictionary) -> float:
	return 0.07 * float(w.get("alisma", 0.0)) / 100.0

func agir_oran(w: Dictionary) -> float:
	var guc: float = oyun.ozet.get("stat", {}).get("guc", 5)
	return silah_agirlik(w) / (1.0 + guc * 0.55)

# Oyuncunun nişan başarısı (0.15..0.95): karakter + beceri + parça + alışma − kusur, yorgunlukla çarpılır.
func isabet(w: Dictionary) -> float:
	var i: float = oyun.ozet.get("isabet", 0.5)
	i += 0.5 * oyun.kis_k.oz("isabet")
	i += oyun.yet_k.etki("isabet")
	if not w.is_empty():
		i += 0.03 * lv(w, "nisan") + alisma_etki(w)
	if kusur("miyop"):
		i -= 0.18 * (0.4 if oyun.kis.get("gozluk", false) else 1.0)
	if kusur("titrek"):
		i -= 0.05
	i *= oyun.kis_k.form() * (1.0 - form_ceza())
	return clampf(i, 0.15, 0.95)

# Savaşta kullanılacak silah verisi (KATALOG ile aynı anahtarlar + "isabet").
func etkin(w: Dictionary) -> Dictionary:
	var tip: String = "yumruk" if w.is_empty() else w["tip"]
	var sd: Dictionary = KATALOG[tip].duplicate()
	var yt: RefCounted = oyun.yet_k
	var cls := sinif(tip)
	if not w.is_empty():
		sd["menzil"] = float(sd["menzil"]) * (1.0 + 0.12 * lv(w, "namlu") + 0.04 * lv(w, "nisan"))
		sd["sacilma"] = float(sd["sacilma"]) * (1.0 - 0.06 * lv(w, "namlu")) * (1.0 - 0.10 * lv(w, "kabze"))
		if sd["sarjor"] > 0:
			sd["sarjor"] = int(sd["sarjor"]) + int(ceil(float(sd["sarjor"]) * 0.25 * lv(w, "sarjor")))
			sd["yenileme"] = float(sd["yenileme"]) * (1.0 + 0.06 * lv(w, "sarjor"))
		var d: float = w["durum"]
		if d < 50.0:
			sd["hasar"] = float(sd["hasar"]) * (0.75 + 0.25 * d / 50.0)
			sd["sacilma"] = float(sd["sacilma"]) * (1.0 + (50.0 - d) / 80.0)
		sd["ad"] = kisa_ad(w) if w["ad"] != "" else KATALOG[tip]["ad"]
		var r := agir_oran(w)
		if r > 1.0:
			sd["sacilma"] = float(sd["sacilma"]) * (1.0 + (r - 1.0) * 0.4)
			sd["yenileme"] = float(sd["yenileme"]) * (1.0 + (r - 1.0) * 0.3)
	# beceri etkileri
	var dol: float = 1.0 + yt.etki("dol")
	match cls:
		"tabanca":
			sd["hasar"] = float(sd["hasar"]) * (1.0 + yt.etki("tabanca_hasar"))
			dol *= 1.0 + yt.etki("tabanca_dol")
		"uzun":
			sd["hasar"] = float(sd["hasar"]) * (1.0 + yt.etki("uzun_hasar"))
			sd["sacilma"] = float(sd["sacilma"]) * (1.0 + yt.etki("uzun_sac"))
		"oto":
			sd["sacilma"] = float(sd["sacilma"]) * (1.0 + yt.etki("oto_sac"))
			dol *= 1.0 + yt.etki("oto_dol")
		"yakin":
			sd["hasar"] = float(sd["hasar"]) * (1.0 + yt.etki("yakin_hasar"))
			sd["hiz"] = float(sd["hiz"]) * (1.0 + yt.etki("yakin_hiz"))
	if kusur("yavas_el"):
		dol *= 1.4
	sd["yenileme"] = float(sd["yenileme"]) * clampf(dol, 0.4, 2.0)
	# nişan: oyuncu elle nişan alır, isabet başarısı namlunun sapmasına çevrilir
	var ib := isabet(w)
	sd["isabet"] = ib
	if sd["sacilma"] > 0.0:
		sd["sacilma"] = float(sd["sacilma"]) * clampf(1.0 + (0.55 - ib) * 2.2, 0.45, 2.4)
	return sd

# Karne: 0..100 ölçekli tasarım değerlendirmesi + yorum + karakter uyumu.
func karne(w: Dictionary) -> Dictionary:
	var sd: Dictionary = etkin(w)
	var dps: float = float(sd["hasar"]) * float(sd["pelet"]) * float(sd["hiz"])
	var k := {
		"Güç": clampf(dps / 1.2, 0.0, 100.0),
		"Menzil": clampf(float(sd["menzil"]) / 0.8, 0.0, 100.0),
		"Hız": clampf(float(sd["hiz"]) * 10.0, 0.0, 100.0),
		"Güvenilirlik": w["durum"],
		"Gizlenebilirlik": clampf((float(KATALOG[w["tip"]]["gizli"]) - 0.07 * lv(w, "namlu") - 0.05 * lv(w, "kaplama")) * 100.0, 0.0, 100.0),
		"Gösteriş": clampf(prestij(w) * 1.6, 0.0, 100.0),
	}
	var y: Array = []
	if k["Gösteriş"] >= 55.0 and k["Güç"] < 45.0:
		y.append("Gösteriş silahı: parlıyor ama sokakta iş görmez.")
	elif k["Gösteriş"] >= 55.0:
		y.append("Hem güçlü hem gösterişli: görenin dizi titrer.")
	if k["Gizlenebilirlik"] >= 70.0 and k["Menzil"] < 50.0:
		y.append("Ceket altı silahı: sessiz, polisin gözünden uzak.")
	elif k["Gizlenebilirlik"] <= 20.0:
		y.append("Gizlenmez: yürürken herkes görür, polis hemen durdurur.")
	if k["Güç"] >= 70.0:
		y.append("Tek başına küçük bir ordu.")
	elif k["Güç"] < 30.0:
		y.append("Gücü zayıf; asıl iş sende bitiyor.")
	if k["Menzil"] >= 70.0:
		y.append("Uzak mesafede söz sahibi.")
	if w["durum"] < 50.0:
		y.append("Bakımsız: tutukluk yapabilir, sapma artmış.")
	if y.is_empty():
		y.append("Dengeli, kararlı bir silah.")
	var ar := agir_oran(w)
	var uyum := "Eline oturmuş." if (alisma_etki(w) > 0.04 and ar <= 1.0) else ("Sana ağır geliyor." if ar > 1.0 else "Alışıyorsun.")
	return {"d": k, "yorum": y, "uyum": uyum}

# İmza silah: elindeki silah; kills veya özel hikâye taşıyorsa adın onunla anılır.
func tan_bonus() -> float:
	var w := eldeki()
	if w.is_empty():
		return 0.0
	return minf(10.0, prestij(w) * 0.12 + w["kills"] * 0.15)

# ---------- poligon ----------
func poligon() -> Dictionary:
	var w := eldeki()
	var kal := ""
	if not w.is_empty():
		kal = KATALOG[w["tip"]]["kal"]
	if kal != "" and muh("u", kal) < 15:
		return oyun.hata("Poligon için en az 15 mermi lazım.")
	if not oyun.harcama(20.0, "temiz"):
		return oyun.hata("Temiz para yetmiyor ($20).")
	if kal != "":
		muh_ekle("u", kal, -15)
	var yt: RefCounted = oyun.yet_k
	if w.is_empty() or kal == "":
		yt.ekle("yakin", 1.2)
	else:
		yt.ekle("nisan", 1.6)
		yt.ekle(yet_id(w["tip"]), 1.2)
		yt.ekle("hizli_el", 0.5)
		w["alisma"] = minf(100.0, w["alisma"] + 3.0)
		w["durum"] = maxf(0.0, w["durum"] - 1.5 * (1.0 + yt.etki("asinma")))
	oyun.kis_k.degis("yorgun", 8.0)
	oyun.kis_k.degis("stres", -8.0)
	oyun.bekle(180)
	oyun.degisti.emit()
	return oyun.tamam("Poligonda üç saat geçirdin.")

# ---------- ruhsat ----------
func ruhsat_var() -> bool:
	return oyun.t < oyun.sil.get("ruhsat", 0)

func ruhsat_al() -> Dictionary:
	if ruhsat_var():
		return oyun.hata("Ruhsatın hâlâ geçerli.")
	if oyun.arama >= 40.0:
		return oyun.hata("Dosyan kabarık; memur ruhsat vermiyor.")
	var f: float = 200.0 * (1.0 - 0.3 * oyun.yet_k.etki("rusvet"))
	if not oyun.harcama(f, "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(f))
	oyun.sil["ruhsat"] = oyun.t + 180 * oyun.DAY
	oyun.kayit("Tabanca ruhsatı çıkardın (Sullivan Yasası): 180 gün geçerli.", "good")
	oyun.degisti.emit()
	return oyun.tamam("Ruhsat çıktı.")

# ---------- polis araması ----------
func yasadisi(w: Dictionary) -> bool:
	var tip: String = w["tip"]
	if tip in ["kesik", "musta", "derringer"]:
		return true
	if KATALOG[tip]["tur"] == "tabanca":
		return not ruhsat_var()
	return false

# Devriye seni durdurursa üstünde bulunan yasa dışı şeyler. {bulundu:[w], mermi:int}
func ust_arama(rng: RandomNumberGenerator) -> Dictionary:
	var bulundu: Array = []
	var sezgi: float = oyun.yet_k.etki("gizlilik")
	for w in oyun.sil["liste"]:
		var aktif: bool = w["yer"] == "u" or (w["yer"] == "b" and bagaj_aktif())
		if not aktif or not yasadisi(w):
			continue
		var g: float = KATALOG[w["tip"]]["gizli"] - 0.07 * lv(w, "namlu") - 0.05 * lv(w, "kaplama")
		var p: float = clampf(0.9 - g * 0.85 - sezgi * 0.5 - (0.25 if w["yer"] == "b" else 0.0), 0.04, 0.95)
		if rng.randf() < p:
			bulundu.append(w)
	# açıkta duran uzun namlular (gizli < 0.3) her zaman görünür ama yasal; sadece mermi fazlası şüpheli
	var mermi := muh_toplam("u") + (muh_toplam("b") if bagaj_aktif() else 0)
	var fazla := mermi > 60 and rng.randf() < clampf(0.5 - sezgi * 0.4, 0.1, 0.6)
	return {"bulundu": bulundu, "mermi": mermi if fazla else 0}

func ust_bos(u: Dictionary) -> bool:
	return u["bulundu"].is_empty() and u["mermi"] == 0

func ust_yazi(u: Dictionary) -> String:
	var l: Array = []
	for w in u["bulundu"]:
		l.append(KATALOG[w["tip"]]["ad"])
	if u["mermi"] > 0:
		l.append("%d mermi" % u["mermi"])
	return ", ".join(l)

# Müsadere: bulunan silahlar emanete gider.
func musadere(u: Dictionary) -> void:
	for w in u["bulundu"]:
		oyun.sil["liste"].erase(w)
		oyun.sil["emanet"].append(w)
		if oyun.sil["eldeki"] == w["uid"]:
			oyun.sil["eldeki"] = 0
	if u["mermi"] > 0:
		for yer in ["u", "b"]:
			oyun.sil["m"][yer].clear()
	sync()

func emanet_fiyat(w: Dictionary) -> int:
	return int(round(60.0 + KATALOG[w["tip"]]["fiyat"] * 0.35))

func emanetten_al(uid: int) -> Dictionary:
	for w in oyun.sil["emanet"]:
		if w["uid"] == uid:
			var f := emanet_fiyat(w)
			if not oyun.harcama(f, "kirli"):
				return oyun.hata("Kirli para yetmiyor ($%d)." % f)
			oyun.sil["emanet"].erase(w)
			w["yer"] = "e"
			oyun.sil["liste"].append(w)
			oyun.kayit("%s emanetten çıktı (%s rüşvet)." % [ad(w), oyun.para(f)], "info")
			oyun.degisti.emit()
			return oyun.tamam("Silahın evine gönderildi.")
	return oyun.hata("Emanette böyle bir silah yok.")

# ---------- savaş ----------
# Savaşa girerken oyuncunun silah verisi.
func savas_verisi() -> Dictionary:
	var w := eldeki()
	var sd := etkin(w)
	var kal: String = sd["kal"]
	var stok := -1
	if kal != "":
		stok = muh("u", kal) + (muh("b", kal) if bagaj_aktif() else 0)
	return {"silah": "yumruk" if w.is_empty() else w["tip"], "sd": sd, "isabet": sd["isabet"], "stok": stok, "uid": 0 if w.is_empty() else w["uid"]}

# Savaş bitince: mermi düşer, silah aşınır, ustalık kazanılır; yenilgide silah düşebilir.
func savas_sonu(s: Dictionary, g: Dictionary) -> String:
	var yazi := ""
	var w := eldeki()
	var kal: String = KATALOG[w["tip"]]["kal"] if not w.is_empty() else ""
	var kullanilan: int = int(s.get("mermi_kullanilan", 0))
	if kal != "" and kullanilan > 0:
		var k := kullanilan
		var u := mini(k, muh("u", kal))
		muh_ekle("u", kal, -u)
		k -= u
		if k > 0:
			muh_ekle("b", kal, -mini(k, muh("b", kal)))
		if muh("u", kal) + muh("b", kal) == 0:
			yazi += " Mermin bitti; silahın boş kaldı."
	var oldurme: int = int(s.get("oyuncu_oldurme", 0))
	var atis: int = int(s.get("oyuncu_atis", 0))
	var yt: RefCounted = oyun.yet_k
	if not w.is_empty():
		w["kills"] += oldurme
		w["alisma"] = minf(100.0, w["alisma"] + 2.0 + oldurme)
		w["durum"] = maxf(0.0, w["durum"] - float(atis) * 0.06 * (1.0 + yt.etki("asinma")) - 1.0)
		var xp := minf(3.0, 0.4 + oldurme * 0.6)
		if kal == "":
			yt.ekle("yakin", xp)
		else:
			yt.ekle("nisan", xp)
			yt.ekle(yet_id(w["tip"]), xp * 1.1)
			if oldurme > 0:
				yt.ekle("hizli_el", 0.3)
		var un := unvan(w)
		if oldurme > 0 and un != "" and w["kills"] - oldurme < 5 and w["kills"] >= 5:
			oyun.kayit("%s artık \"%s\": sokak seni silahınla anıyor." % [kisa_ad(w), un], "good")
	# yenilgi / geri çekilme: silah düşebilir, kalıcı sakatlık olabilir
	var sonuc: String = s.get("sonuc", "")
	if sonuc == "yenilgi" or sonuc == "kacis":
		var rng: RandomNumberGenerator = oyun.rng
		var p_dus := 0.35 if sonuc == "yenilgi" else 0.12
		if not w.is_empty() and rng.randf() < p_dus:
			oyun.sil["liste"].erase(w)
			oyun.sil["eldeki"] = 0
			if g.get("tur", "") == "polis":
				oyun.sil["emanet"].append(w)
				yazi += " %s düştü; polis emanete aldı (geri almak rüşvetle olur)." % ad(w)
			else:
				oyun.sil["kayip"].append({"ad": ad(w), "tip": w["tip"], "kills": w["kills"], "sahip": w["sahip"]})
				yazi += " %s elinden düştü; düşman aldı." % ad(w)
			sync()
		if sonuc == "yenilgi":
			if rng.randf() < 0.09 and not kusur("tek_el"):
				kusur_ekle("tek_el")
			elif rng.randf() < 0.08 and not kusur("titrek"):
				kusur_ekle("titrek")
	oyun.degisti.emit()
	return yazi

# Lider yenilince özel silahı sende kalır (düşmanı yendiğinin işareti).
func ganimet_lider(uye: Dictionary) -> String:
	var rutbe: String = uye.get("rutbe", "asker")
	var tip := "tommy" if rutbe in ["don", "ikinci"] else ("pompali" if rutbe == "kaptan" else "tabanca")
	var ad_s: String = oyun.uye_ad(uye)
	var fak: String = uye.get("fak", "")
	var yazi_s := "%s'ın silahı. Onu yendiğinin kanıtı; taşırsan herkes bilir." % ad_s
	var pe := 30.0 if rutbe in ["don", "ikinci"] else (18.0 if rutbe == "kaptan" else 10.0)
	var w := ver(tip, "ganimet", "%s'ın %s" % [ad_s.get_slice(" ", 0), KATALOG[tip]["ad"].get_slice(" ", 0)], yazi_s, pe, fak, "e")
	w["durum"] = 85.0
	oyun.kayit("Ganimet: %s evine gönderildi." % ad(w), "good")
	return " Ganimet: %s." % ad(w)

# Sıradan düşmandan bazen bir silah kalır.
func ganimet_rastgele() -> String:
	var rng: RandomNumberGenerator = oyun.rng
	if rng.randf() > 0.3:
		return ""
	var havuz := ["bicak", "musta", "sopa", "revolver", "tabanca", "derringer", "kesik"]
	var tip: String = havuz[rng.randi() % havuz.size()]
	var w := ver(tip, "ganimet", "", "", 0.0, "", "e")
	oyun.kayit("Ganimet: %s evine gönderildi." % KATALOG[tip]["ad"], "info")
	return " Ganimet: %s." % KATALOG[tip]["ad"]

# ---------- günlük ----------
func gun() -> void:
	var tasiyor := false
	for w in oyun.sil["liste"]:
		if w["yer"] == "u" and w["sahip"] != "" and oyun.ofke.has(w["sahip"]):
			tasiyor = true
			oyun.ofke[w["sahip"]] = minf(100.0, oyun.ofke[w["sahip"]] + 0.4)
	if tasiyor and oyun.rng.randf() < 0.1:
		oyun.kayit("Bir ailenin ustasının silahını taşıyorsun: birileri intikam peşinde, kulağına söylentiler geliyor.", "warn")
	if asiri() > 0.0 and oyun.rng.randf() < 0.3:
		oyun.kayit("Üzerindeki yük fazla; ağırlıktan yoruluyorsun. Fazlasını eve bırak.", "warn")
