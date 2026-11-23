extends RefCounted
# Aile üyeleri, yaşlanma, evlilik, çocuk, ölüm ve mirasçı devri (bkz. AILE_SISTEMI.md §4, §6, §8).
# Her üye: {id, ad, rol: es|cocuk|kardes|ebeveyn, cins: e|k, dogum (oyun dk, negatif olabilir), oz: [id], stat: {guc,nisan,zeka,karizma},
#           sevgi 0..100 (sana karşı), olu: bool, konus: son konuşulan gün}
# Aile başı (oyuncu) özellikleri oyun.aile["oz"], yaşı yas0 + geçen yıl.

const YIL_DK := 10 * 12 * 1440
const EVLEN_UCRET := 300.0
const MIRAS_YAS := 16
const KAYIP_TABAN := 0.10

const ERKEK := ["Tony", "Frank", "Vincent", "Sal", "Mike", "Jimmy", "Eddie", "Paulie", "Danny", "Carl", "Joe", "Sam", "Nick", "Walter"]
const KADIN := ["Rosa", "Maria", "Anna", "Lucia", "Helen", "Dorothy", "Eileen", "Rose", "Clara", "Betty", "Ida", "Nora", "Gina", "Mabel"]

# id: {ad, e: etkiler, zit, k: kalıtsal mı}
const OZ := {
	"cesur": {"ad": "Cesur", "e": {"isabet": 0.04, "stres": -0.08}, "zit": "korkak", "k": true},
	"korkak": {"ad": "Korkak", "e": {"kacis": 0.08, "stres": 0.06, "saygi": -0.05}, "zit": "cesur", "k": false},
	"sabirli": {"ad": "Sabırlı", "e": {"gelir_mesru": 0.04, "pazarlik": 0.04}, "zit": "sabirsiz", "k": false},
	"sabirsiz": {"ad": "Sabırsız", "e": {"gelir_mesru": -0.03}, "zit": "sabirli", "k": false},
	"hirsli": {"ad": "Hırslı", "e": {"gelir_haram": 0.05, "dikkat": 0.05, "darbe": 0.08}, "zit": "kanaatkar", "k": true},
	"kanaatkar": {"ad": "Kanaatkâr", "e": {"stres": -0.08, "gider": -0.05}, "zit": "hirsli", "k": false},
	"comert": {"ad": "Cömert", "e": {"sevgi": 0.10, "gider": 0.06}, "zit": "cimri", "k": false},
	"cimri": {"ad": "Cimri", "e": {"gider": -0.08, "sevgi": -0.08}, "zit": "comert", "k": false},
	"sadik": {"ad": "Sadık", "e": {"sadakat": 0.12}, "zit": "ihanetkar", "k": true},
	"ihanetkar": {"ad": "İhanetkâr", "e": {"ikna": 0.05, "sadakat": -0.12}, "zit": "sadik", "k": false},
	"merhametli": {"ad": "Merhametli", "e": {"sevgi": 0.10, "korku": -0.06}, "zit": "acimasiz", "k": false},
	"acimasiz": {"ad": "Acımasız", "e": {"korku": 0.12, "sevgi": -0.10}, "zit": "merhametli", "k": false},
	"zeki": {"ad": "Zeki", "e": {"ikna": 0.05, "pazarlik": 0.05}, "zit": "yavas", "k": true},
	"yavas": {"ad": "Yavaş", "e": {"stres": -0.03}, "zit": "zeki", "k": false},
	"cekici": {"ad": "Çekici", "e": {"ikna": 0.08, "evlilik_secenek": 0.10}, "zit": "sevimsiz", "k": true},
	"sevimsiz": {"ad": "Sevimsiz", "e": {"ikna": -0.06, "korku": 0.04}, "zit": "cekici", "k": false},
	"durust": {"ad": "Dürüst", "e": {"sevgi": 0.06, "rusvet": 0.08}, "zit": "duzenbaz", "k": false},
	"duzenbaz": {"ad": "Düzenbaz", "e": {"pazarlik": 0.08, "sevgi": -0.06, "gizlilik": 0.05}, "zit": "durust", "k": false},
	"guclu": {"ad": "Güçlü", "e": {"yakin_hasar": 0.12, "can": 0.08}, "zit": "", "k": true},
	"cevik": {"ad": "Çevik", "e": {"kacis": 0.10, "isabet": 0.03}, "zit": "", "k": true},
}
const HAVUZ := ["cesur", "korkak", "sabirli", "sabirsiz", "hirsli", "kanaatkar", "comert", "cimri", "sadik", "ihanetkar", "merhametli", "acimasiz", "zeki", "yavas", "cekici", "sevimsiz", "durust", "duzenbaz", "guclu", "cevik"]

const ROL_AD := {"es": "Eş", "cocuk": "Çocuk", "kardes": "Kardeş", "ebeveyn": "Ebeveyn"}

var oyun: Node
var rng := RandomNumberGenerator.new()

func _init(o: Node) -> void:
	oyun = o
	rng.seed = 4417

func _a() -> Dictionary:
	return oyun.aile

# aile sözlüğüne eksik alanları ekler (eski kayıtlar için de)
func hazirla() -> void:
	var a := _a()
	if not a.has("kisiler"):
		a["kisiler"] = []
		a["gecmis"] = []
		a["adaylar"] = []
		a["nesil"] = 1
		a["yas0"] = int(oyun.profil.get("yas", 30))
		a["t0"] = oyun.t
		a["son_yil"] = oyun.tarih()["yil"]
		a["sayac"] = 1
		a["oz"] = _rastgele_oz(2, [])

func _rastgele_oz(n: int, haric: Array) -> Array:
	var out: Array = []
	var havuz: Array = HAVUZ.duplicate()
	havuz.shuffle()
	for id in havuz:
		if out.size() >= n:
			break
		var zit: String = OZ[id]["zit"]
		if haric.has(id) or out.has(zit):
			continue
		out.append(id)
	return out

func oz_yazi(l: Array) -> String:
	var p: PackedStringArray = []
	for id in l:
		p.append(OZ[id]["ad"])
	return ", ".join(p) if not p.is_empty() else "—"

# --- yaş ---------------------------------------------------------------
func yas(k: Dictionary) -> int:
	return maxi(0, int(floor(float(oyun.t - int(k["dogum"])) / float(YIL_DK))))

func oyuncu_yas() -> int:
	var a := _a()
	return int(a["yas0"]) + int(floor(float(oyun.t - int(a["t0"])) / float(YIL_DK)))

func ad_soyad(ad: String) -> String:
	var p: PackedStringArray = str(oyun.profil.get("ad", "Sen")).split(" ")
	return "%s %s" % [ad, p[p.size() - 1]] if p.size() > 1 else ad

func _isim(cins: String) -> String:
	var l: Array = ERKEK if cins == "e" else KADIN
	return l[rng.randi() % l.size()]

func _stat() -> Dictionary:
	var s: Dictionary = oyun.ozet.get("stat", {"guc": 5, "nisan": 5, "zeka": 5, "karizma": 5})
	var out := {}
	for k in ["guc", "nisan", "zeka", "karizma"]:
		out[k] = clampi(int(round((float(s.get(k, 5)) + 5.0) * 0.5)) + rng.randi_range(-1, 1), 3, 9)
	return out

func _yeni_kisi(rol: String, cins: String, ad: String, yas_: int, oz: Array) -> Dictionary:
	var a := _a()
	var id: int = int(a["sayac"])
	a["sayac"] = id + 1
	return {"id": id, "ad": ad, "rol": rol, "cins": cins, "dogum": oyun.t - yas_ * YIL_DK - rng.randi_range(0, YIL_DK - 1), "oz": oz,
		"stat": _stat(), "sevgi": 60.0 if rol != "cocuk" else 70.0, "olu": false, "konus": -1}

func canlilar() -> Array:
	return _a()["kisiler"].filter(func(k): return not k["olu"])

func es() -> Dictionary:
	for k in canlilar():
		if k["rol"] == "es":
			return k
	return {}

func cocuklar() -> Array:
	return canlilar().filter(func(k): return k["rol"] == "cocuk")

# --- evlilik -------------------------------------------------------------
func evlenebilir() -> bool:
	return es().is_empty() and oyuncu_yas() >= 18

func es_adaylari_uret() -> void:
	var l: Array = []
	var py: int = oyuncu_yas()
	for i in 3:
		var cins: String = "k" if rng.randf() < 0.75 else "e"
		var ad := _isim(cins)
		l.append(_yeni_kisi("es", cins, ad_soyad(ad) if false else ad, clampi(py + rng.randi_range(-8, 3), 18, 55), _rastgele_oz(2, [])))
	_a()["adaylar"] = l

func evlen(i: int) -> Dictionary:
	var a := _a()
	if not evlenebilir():
		return oyun.hata("Zaten evlisin ya da henüz yaşın tutmuyor.")
	if i < 0 or i >= a["adaylar"].size():
		return oyun.hata("Geçersiz aday.")
	var ucret: float = EVLEN_UCRET * maxf(0.3, 1.0 + oyun.aile_k.etki("gider"))
	if not oyun.harcama(ucret, "temiz"):
		return oyun.hata("Düğün için temiz para yetmiyor (%s)." % oyun.para(ucret))
	var k: Dictionary = a["adaylar"][i]
	a["kisiler"].append(k)
	a["adaylar"] = []
	oyun.un_k.ekle("saygi", 3.0)
	oyun.un_k.ekle("sevgi", 3.0)
	oyun.kaz_k.ver("evlilik")
	oyun.kayit("%s ile evlendin. Düğün %s tuttu; mahalle konuşuyor." % [k["ad"], oyun.para(ucret)], "good")
	oyun.degisti.emit()
	return oyun.tamam()

# --- konuşma ------------------------------------------------------------
const SOZ := {
	"es": ["Bu sokaklar seni bir gün bana geri getirmeyecek diye korkuyorum.", "Akşam yemeğe gelirsin, değil mi?", "Komşular senin için neler konuşuyor, biliyor musun?"],
	"cocuk": ["Baba, büyüyünce senin gibi olacağım!", "Bugün okulda herkes senden bahsetti.", "Beni de iş başına götür, sıkıldım."],
	"kardes": ["Aileye bir şey olursa seni kimse kurtaramaz.", "Eski günleri hatırlıyor musun?"],
	"ebeveyn": ["Yolunu seç ama ardında ne bıraktığını da düşün.", "Ben bu mahallede çok şey gördüm evladım."],
}
const OZ_SOZ := {
	"cesur": "Korkmuyorum. Ne gelirse gelsin.", "korkak": "Bir şey olursa diye hep kapıya bakıyorum.", "hirsli": "Daha büyük olmalıyız. Bu kadarla yetinmeyelim.",
	"comert": "Komşuya bir tabak yemek götürsem fena olmaz.", "cimri": "Bu ay harcamalar fazlaydı. Hesapları sen mi tutuyorsun?",
	"merhametli": "Kimseye haksızlık yapmamalıyız.", "acimasiz": "Zayıflığın bedelini ödetmek lazım.", "zeki": "Bir şeyi fark ettim, ama sana sonra anlatırım.",
	"durust": "Kazandığımız para temiz mi?", "duzenbaz": "Bir fikrim var, ama kimseye söyleme.",
}

func konus(id: int) -> Dictionary:
	var a := _a()
	for k in a["kisiler"]:
		if k["id"] != id or k["olu"]:
			continue
		var gun: int = oyun.t / oyun.DAY
		if int(k["konus"]) == gun:
			return oyun.hata("%s ile bugün zaten konuştun." % k["ad"])
		k["konus"] = gun
		k["sevgi"] = minf(100.0, k["sevgi"] + 3.0)
		oyun.kis["stres"] = maxf(0.0, oyun.kis["stres"] - 5.0)
		var soz: String
		var oz: Array = k["oz"].filter(func(x): return OZ_SOZ.has(x))
		if not oz.is_empty() and rng.randf() < 0.5:
			soz = OZ_SOZ[oz[rng.randi() % oz.size()]]
		else:
			var l: Array = SOZ[k["rol"]]
			soz = l[rng.randi() % l.size()]
		oyun.degisti.emit()
		return oyun.tamam("%s: \"%s\" (stres −5, bağ +3)" % [k["ad"], soz])
	return oyun.hata("Kişi bulunamadı.")

# --- zaman ---------------------------------------------------------------
func gun() -> void:
	hazirla()
	var a := _a()
	var yil: int = oyun.tarih()["yil"]
	if yil != a["son_yil"]:
		a["son_yil"] = yil
		_yil_sonu()

func _yil_sonu() -> void:
	var a := _a()
	var py: int = oyuncu_yas()
	# diğer üyeler yaşlanır, ölür
	for k in a["kisiler"]:
		if k["olu"]:
			continue
		var y := yas(k)
		if y >= 55 and rng.randf() < clampf((y - 55) * 0.02, 0.0, 0.5):
			k["olu"] = true
			oyun.kayit("%s (%s) vefat etti. Ailede yas var." % [k["ad"], ROL_AD[k["rol"]]], "bad")
			oyun.un_k.ekle("saygi", 0.0)
	# doğum
	var e := es()
	if not e.is_empty() and yas(e) >= 18 and yas(e) <= 42 and cocuklar().size() < 6 and e["cins"] != oyun.profil.get("cins", ""):
		var p: float = clampf(0.4 * (1.0 + oyun.aile_k.etki("dogurganlik")), 0.0, 0.9)
		if rng.randf() < p:
			_dogum(e)
	# aile başı
	if py >= 45 and oyun.son.is_empty() and rng.randf() < clampf((py - 45) * 0.02, 0.0, 0.6):
		oyun.ol("Yıllara yenik düştün. %d yaşında, uykunda gözlerini yumdun." % py)

func _dogum(e: Dictionary) -> void:
	var a := _a()
	var cins: String = "e" if rng.randf() < 0.5 else "k"
	var oz: Array = []
	for kaynak in [a["oz"], e["oz"]]:
		for id in kaynak:
			if OZ[id]["k"] and oz.size() < 2 and not oz.has(id) and not oz.has(OZ[id]["zit"]) and rng.randf() < 0.4:
				oz.append(id)
	var ek := _rastgele_oz(3 - oz.size(), oz)
	for id in ek:
		if oz.size() < 3:
			oz.append(id)
	var c := _yeni_kisi("cocuk", cins, _isim(cins), 0, oz)
	a["kisiler"].append(c)
	oyun.kaz_k.ver("cocuk")
	oyun.kayit("%s doğdu! Ailenin yeni üyesi: %s." % [c["ad"], oz_yazi(oz)], "good")
	oyun.un_k.ekle("sevgi", 1.0)

# --- miras ----------------------------------------------------------------
func adaylar() -> Array:
	return canlilar().filter(func(k): return yas(k) >= MIRAS_YAS)

func kayip_orani() -> float:
	return clampf(KAYIP_TABAN * (1.0 + oyun.aile_k.etki("miras_kayip")), 0.0, 0.6)

const ANI := {
	"Baba": "Mahallede adı fısıltıyla anılır; kimi korkuyla, kimi saygıyla.",
	"Saygın iş adamı": "Cenazesine yüzlerce kişi geldi; dükkânlar kepenk indirdi.",
	"Rezil haraççı": "Esnaf onu hâlâ \"o beceriksiz\" diye anlatır, ama gülerek.",
	"Sokak haraççısı": "Sokaklarda adı bilinirdi, ama kimse arkasından ağlamadı.",
	"Mahalle esnafı": "Küçük ama dürüst bir hayat; komşuları iyilikle andı.",
	"Yolunu arayan": "Kim olduğunu kimse tam bilemedi.",
}

func ozet_yazi() -> String:
	var a := _a()
	var U: RefCounted = oyun.un_k
	var tip: Dictionary = U.tip()
	var yil: int = oyun.tarih()["yil"]
	var cocuk_say := 0
	for k in a["kisiler"]:
		if k["rol"] == "cocuk":
			cocuk_say += 1
	var l: PackedStringArray = []
	l.append("— HAYAT ÖZETİ —")
	l.append("%s, %d yaşında öldü." % [oyun.profil.get("ad", "Sen"), oyuncu_yas()])
	l.append("Unvanı: %s. %d nesil, %d yıl sürdü." % [tip["ad"], int(a["nesil"]), yil])
	l.append("Servet %s · Korku %d · Sevgi %d · Saygı %d" % [oyun.para(U.net_servet()), int(U.deger("korku")), int(U.deger("sevgi")), int(U.deger("saygi"))])
	l.append("Aile: %d çocuk · rezillik %d · hapis %d kez · tefeci borcu %s" % [cocuk_say, int(oyun.kotu["rezil"]), int(oyun.kotu["hapis_say"]), oyun.para(oyun.kotu["tef"])])
	if oyun.nuf["mal"]:
		l.append("Malikânede yaşadı.")
	l.append(ANI.get(tip["ad"], ""))
	for g in a["gecmis"]:
		l.append("— %s (%s, %d yaşında)" % [g["ad"], g["tip"], g["yas"]])
	return "
".join(l)

func ozet_anisi() -> String:
	return ANI.get(oyun.un_k.tip()["ad"], "")

# Hayat özetinin "Sonuç" paragrafı: oynanışa göre hükümler.
func sonuc_yazi() -> String:
	var a := _a()
	var U: RefCounted = oyun.un_k
	var tip: String = U.tip()["ad"]
	var yil: int = oyun.tarih()["yil"]
	var nesil: int = int(a["nesil"])
	var p: PackedStringArray = []
	match tip:
		"Baba":
			p.append("Sokaklar onu korkuyla andı, kapılar onun için açıldı. Gücünü hem cebinden hem gölgesinden aldı.")
		"Saygın iş adamı":
			p.append("Silahla değil defterle büyüdü; mahalle ona şapka çıkardı, çocuklar adını duyunca gülümsedi.")
		"Rezil haraççı":
			p.append("Büyük hayaller kurdu ama sokak onu ciddiye almadı. Yine de her sabah kalkıp denemekten vazgeçmedi.")
		_:
			p.append("Büyük bir şey olamadı; ama kendi ayakları üstünde durmaya çalıştı.")
	if nesil > 1:
		p.append("Soyadı %d kuşak boyunca şehrin hafızasında kaldı." % nesil)
	if int(oyun.kotu["hapis_say"]) > 0:
		p.append("Parmaklıkların ardında %d kez uyandı." % int(oyun.kotu["hapis_say"]))
	if oyun.kaz_k.sayi() >= 8:
		p.append("%d kazanımıyla dolu dolu bir hayat sürdü." % oyun.kaz_k.sayi())
	p.append("Toplam %d yıl yaşandı. Bir sonraki hayat başka türlü olabilir." % yil)
	return " ".join(p)

func miras_al(id: int) -> Dictionary:
	var a := _a()
	var h: Dictionary = {}
	for k in canlilar():
		if k["id"] == id and yas(k) >= MIRAS_YAS:
			h = k
	if h.is_empty():
		return oyun.hata("Bu kişi mirasçı olamaz.")
	# eski aile başı geçmişe
	a["gecmis"].append({"ad": oyun.profil.get("ad", "Sen"), "tip": oyun.un_k.tip()["ad"], "yas": oyuncu_yas()})
	# servet kaybı
	var kayip: float = kayip_orani()
	oyun.temiz *= (1.0 - kayip)
	oyun.kirli *= (1.0 - kayip)
	# rolleri yeni baş açısından yeniden yaz
	var eski_rol: String = h["rol"]
	a["kisiler"].erase(h)
	for k in a["kisiler"]:
		if k["olu"]:
			continue
		match [eski_rol, k["rol"]]:
			["cocuk", "cocuk"]:
				k["rol"] = "kardes"
			["cocuk", "es"]:
				k["rol"] = "ebeveyn"
			["es", "cocuk"]:
				pass
			["kardes", "cocuk"]:
				k["rol"] = "kardes"
			["es", "es"]:
				pass
	# eski aile başı olu kayıt olarak değil, geçmişte
	# yeni baş: kimlik, yaş, stat, özellik, beceri
	var yeni_ad: String = ad_soyad(h["ad"])
	oyun.profil["ad"] = yeni_ad
	oyun.profil["cins"] = h["cins"]
	a["yas0"] = yas(h)
	a["t0"] = oyun.t
	a["oz"] = h["oz"]
	a["nesil"] = int(a["nesil"]) + 1
	a["adaylar"] = []
	oyun.ozet["stat"] = h["stat"]
	var eski: Dictionary = oyun.yet["p"].duplicate()
	oyun.yet["p"] = {}
	oyun.yet_k.baslat()
	for sid in eski:
		oyun.yet["p"][sid] = maxf(float(oyun.yet["p"].get(sid, 0.0)), float(eski[sid]) * 0.4)
	oyun.kis = oyun.kis_k.yeni()
	oyun.kis_k.baslat()
	oyun.kis_k._son_t = oyun.t
	oyun.arama *= 0.5
	oyun.un["sevgi"] *= 0.7
	oyun.un["saygi"] *= 0.7
	oyun.aile_k.miras_devri()
	oyun.kaz_k.ver("nesil")
	if int(a["nesil"]) >= 3:
		oyun.kaz_k.ver("nesil3")
	oyun.son = {}
	oyun.kayit("%s ailenin başına geçti (%d. nesil). Servetin %%%d'i kaybedildi." % [yeni_ad, int(a["nesil"]), int(round(kayip * 100.0))], "warn")
	oyun.degisti.emit()
	return oyun.tamam()

# test: eş, çocuk ve ölüm hazırlar
func test_hazirla() -> void:
	hazirla()
	var a := _a()
	a["yas0"] = 52
	es_adaylari_uret()
	oyun.temiz += 1000.0
	evlen(0)
	_dogum(es())
	_dogum(es())
	for k in a["kisiler"]:
		if k["rol"] == "cocuk":
			k["dogum"] = oyun.t - 19 * YIL_DK
