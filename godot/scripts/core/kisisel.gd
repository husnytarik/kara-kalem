extends RefCounted
# Kişisel durum: açlık, yorgunluk, stres, sıkıntı, hastalık + özellikler (karakterin huyları) + tanınırlık.
# İhtiyaçlar her oyun saatinde birikir; seni bir şeyler yapmaya iter (yemek, uyku, eğlence, dinlenme).
# Özellikler (0..100) kararlarla ve yaşananlarla büyür, kullanılmazsa solar; oyunun hesaplarına etki eder.

# Her özellik: ad, açıklama, e: {etki anahtarı: katsayı (puan/100 ile çarpılır)}
const OZ := {
	"taksici_dostu": {"ad": "Taksici dostu", "ac": "Şehrin şoförleri seni tanır: söylentileri ve bilgiyi kolay alırsın.", "e": {"bilgi": 0.6, "cevre": 0.2}},
	"gece_kusu": {"ad": "Gece kuşu", "ac": "Gece çalışmak seni yormaz. Barlarda çevre edinirsin, adam bulman kolaylaşır.", "e": {"cevre": 0.5, "gece": 0.7}},
	"cilveli": {"ad": "Cilveli", "ac": "Sohbet açmak, güven vermek: adam bulma ve ikna kolaylaşır.", "e": {"cevre": 0.5, "ikna": 0.4}},
	"mahalleli": {"ad": "Mahalleli", "ac": "Esnaf seni kendinden sayar: yasal iş ve mahalle sevgisi.", "e": {"yasal": 0.25, "sevgi": 0.4}},
	"soguk_kanli": {"ad": "Soğukkanlı", "ac": "Baskı altında paniklemezsin: stres daha yavaş birikir.", "e": {"stres": 0.5}},
	"dayanikli": {"ad": "Dayanıklı", "ac": "Açlığa ve yorgunluğa direnirsin.", "e": {"dayan": 0.45}},
	"saglikli": {"ad": "Sağlıklı", "ac": "Hastalık seni zor bulur, çabuk iyileşirsin.", "e": {"saglik": 0.6}},
	"sert_bakis": {"ad": "Sert bakış", "ac": "Gözdağı verince esnaf kıpırdamaz: haraç ve korku.", "e": {"harac": 0.35, "korku": 0.4}},
	"dilbaz": {"ad": "Dilbaz", "ac": "Rüşvet ve pazarlık ucuza gelir.", "e": {"rusvet": 0.4, "pazarlik": 0.4}},
	"gizli": {"ad": "İz bırakmaz", "ac": "Polis dosyan daha yavaş kabarır.", "e": {"gizli": 0.45}},
	"hesapci": {"ad": "Hesapçı", "ac": "Yasal gelirler ve aklama daha verimli.", "e": {"yasal": 0.35, "pazarlik": 0.15}},
	"kavgaci": {"ad": "Kavgacı", "ac": "Çatışmada gücün artar.", "e": {"dovus": 0.4}},
	"nisanci": {"ad": "Keskin göz", "ac": "Silahlı çatışmada isabetin artar.", "e": {"dovus": 0.25, "isabet": 0.3}},
	"comert": {"ad": "Cömert", "ac": "Adamların sadık olur, mahalle seni över; ama cebin tez boşalır.", "e": {"sadakat": 0.4, "sevgi": 0.2, "pazarlik": -0.2}},
	"cimri": {"ad": "Cimri", "ac": "Harcamalar ucuz, ama adamlar sana pek bağlanmaz.", "e": {"sadakat": -0.3, "pazarlik": 0.3}},
	"muhbir_agi": {"ad": "Muhbir ağı", "ac": "Sokaktan haber gelir: bilgi alman kolay.", "e": {"bilgi": 0.5, "gizli": 0.15}},
	"polis_dostu": {"ad": "Polisle iyi", "ac": "Karakolda tanıdık yüzler var: rüşvet ucuz, dosya yavaş.", "e": {"rusvet": 0.3, "gizli": 0.25}},
	"vicdanli": {"ad": "Vicdanlı", "ac": "Yaptıkların içine işler: stres artar, ama insanlar sana güvenir.", "e": {"stres": -0.2, "sevgi": 0.3}},
	"acimasiz": {"ad": "Acımasız", "ac": "Korku salarsın, ama rahatsız bir uyku uyursun.", "e": {"korku": 0.5, "harac": 0.2, "stres": -0.15}},
	"kumarbaz": {"ad": "Kumarbaz", "ac": "Riski seversin: kumar sıkıntıyı alır ama cebi boşaltır.", "e": {"sikinti": 0.35, "pazarlik": -0.15}},
	"alkolik": {"ad": "Alkole düşkün", "ac": "İçki stresi alır, ama sağlığın ve isabetin bozulur.", "e": {"saglik": -0.4, "isabet": -0.3, "stres": 0.2}},
	"sinirli": {"ad": "Sinirli", "ac": "Çabuk parlarsın: stres hızlı birikir, adamlarla zor geçinirsin.", "e": {"stres": -0.5, "sadakat": -0.3, "dovus": 0.1}},
	"korkak": {"ad": "Temkinli", "ac": "Tehlikeden kaçarsın: dosya kabarmaz, ama sözün ağırlığı azalır.", "e": {"gizli": 0.2, "harac": -0.25}},
	"sabirsiz": {"ad": "Sabırsız", "ac": "Sıkıntı çabuk bastırır.", "e": {"sikinti": 0.5}},
}

# Bina adına göre yapılabilecek eylemler: id -> {ad, ipucu, ucret, dk, d: {ihtiyaç: değişim}, oz: {özellik: artış}}
const EYLEM := {
	"yemek": {"ad": "Yemek ye", "ucret": 12.0, "dk": 40, "d": {"aclik": -70.0, "stres": -3.0}, "oz": {}},
	"atistirma": {"ad": "Bir şeyler atıştır", "ucret": 4.0, "dk": 15, "d": {"aclik": -30.0}, "oz": {}},
	"evde_ye": {"ad": "Evde bir şeyler ye", "ucret": 3.0, "dk": 25, "d": {"aclik": -45.0}, "oz": {}},
	"icki": {"ad": "İçki iç", "ucret": 10.0, "dk": 60, "d": {"stres": -25.0, "sikinti": -35.0, "yorgun": 4.0}, "oz": {"alkolik": 1.2}},
	"sohbet": {"ad": "Çevre edin (sohbet et)", "ucret": 8.0, "dk": 90, "d": {"sikinti": -25.0, "stres": -5.0, "yorgun": 5.0}, "oz": {"cilveli": 2.0, "gece_kusu": 0.0}},
	"bilardo": {"ad": "Bilardo oyna", "ucret": 6.0, "dk": 90, "d": {"sikinti": -35.0, "stres": -10.0, "yorgun": 5.0}, "oz": {"cilveli": 1.0}},
	"kumar": {"ad": "Zar at (kumar)", "ucret": 15.0, "dk": 60, "d": {"sikinti": -50.0, "stres": 6.0}, "oz": {"kumarbaz": 2.5}},
	"hamam": {"ad": "Hamama gir", "ucret": 15.0, "dk": 90, "d": {"stres": -40.0, "yorgun": -20.0, "sikinti": -10.0}, "oz": {"saglikli": 0.6}},
	"sinema": {"ad": "Bir film izle", "ucret": 8.0, "dk": 120, "d": {"sikinti": -45.0, "stres": -10.0}, "oz": {}},
	"dua": {"ad": "Sessizce otur / dua et", "ucret": 0.0, "dk": 45, "d": {"stres": -22.0}, "oz": {"vicdanli": 1.0}},
	"idman": {"ad": "Antrenman yap", "ucret": 5.0, "dk": 90, "d": {"stres": -15.0, "sikinti": -15.0, "yorgun": 12.0, "aclik": 8.0}, "oz": {"kavgaci": 1.6, "saglikli": 0.4}},
	"ilac": {"ad": "İlaç al (hastalık, yara)", "ucret": 45.0, "dk": 20, "d": {}, "oz": {}},
	"dinlen": {"ad": "Biraz uzan", "ucret": 0.0, "dk": 60, "d": {"yorgun": -12.0, "stres": -8.0}, "oz": {}},
}

var oyun: Node
var _son_t := 0
var _son_taninma := 0

func _init(o: Node) -> void:
	oyun = o

func yeni() -> Dictionary:
	return {"aclik": 10.0, "yorgun": 10.0, "stres": 10.0, "sikinti": 10.0, "hasta": 0, "hasta_ad": "", "agir": 0.0, "yara": 0.0,
		"oz": {}, "uyuyor": false, "uyari": {}, "gece_say": 0.0}

# Karakter seçimlerinden başlangıç özellikleri.
func baslat() -> void:
	var p: Dictionary = oyun.profil
	var o: Dictionary = oyun.kis["oz"]
	match p.get("gecmis", ""):
		"isci":
			o["dayanikli"] = 25.0
		"boksor":
			o["kavgaci"] = 30.0
			o["sert_bakis"] = 15.0
		"gazi":
			o["nisanci"] = 30.0
			o["soguk_kanli"] = 25.0
		"hesapci":
			o["hesapci"] = 30.0
			o["dilbaz"] = 10.0
		"kacakci":
			o["gizli"] = 25.0
			o["gece_kusu"] = 20.0
	match p.get("koken", ""):
		"yerli":
			o["mahalleli"] = 25.0
			o["taksici_dostu"] = 12.0
		"aile":
			o["sert_bakis"] = o.get("sert_bakis", 0.0) + 15.0
			o["polis_dostu"] = 0.0
		"gocmen":
			o["dayanikli"] = o.get("dayanikli", 0.0) + 15.0
			o["cimri"] = 15.0
	if int(p.get("yas", 30)) >= 45:
		o["soguk_kanli"] = o.get("soguk_kanli", 0.0) + 15.0
	elif int(p.get("yas", 30)) < 25:
		o["sabirsiz"] = 18.0
		o["saglikli"] = o.get("saglikli", 0.0) + 15.0
	_son_t = oyun.t

# ---------- özellikler ----------
func oz_puan(id: String) -> float:
	return oyun.kis["oz"].get(id, 0.0)

func oz_ekle(id: String, d: float) -> void:
	if not OZ.has(id) or d == 0.0:
		return
	var o: Dictionary = oyun.kis["oz"]
	var eski: float = o.get(id, 0.0)
	var yeni_p := clampf(eski + d, 0.0, 100.0)
	o[id] = yeni_p
	if int(eski / 25.0) < int(yeni_p / 25.0) and yeni_p >= 25.0:
		oyun.kayit("Huyun değişiyor: \"%s\" — %s" % [OZ[id]["ad"], OZ[id]["ac"]], "info")
	elif int(eski / 25.0) > int(yeni_p / 25.0) and eski >= 25.0:
		oyun.kayit("\"%s\" huyun zayıfladı." % OZ[id]["ad"], "info")

# Bir etki anahtarının toplam değeri (bütün özelliklerden)
func oz(anahtar: String) -> float:
	var top := 0.0
	var o: Dictionary = oyun.kis["oz"]
	for id in o:
		var e: Dictionary = OZ[id]["e"]
		if e.has(anahtar):
			top += float(o[id]) / 100.0 * float(e[anahtar])
	return clampf(top, -1.0, 1.5)

func oz_liste() -> Array:
	var l: Array = []
	var o: Dictionary = oyun.kis["oz"]
	for id in o:
		if o[id] >= 5.0:
			l.append([id, o[id]])
	l.sort_custom(func(a, b): return a[1] > b[1])
	return l

# ---------- ihtiyaçlar ----------
func _n(k: String) -> float:
	return oyun.kis[k]

func degis(k: String, d: float) -> void:
	oyun.kis[k] = clampf(oyun.kis[k] + d, 0.0, 100.0)

func stres_ekle(d: float) -> void:
	if d > 0.0:
		d *= clampf(1.0 - 0.5 * oz("stres"), 0.4, 1.8)
	degis("stres", d)

# Yaralanma: iyileşmeyi yavaşlatır, hastalık riskini artırır.
func yara_ekle(x: float) -> void:
	oyun.kis["yara"] = clampf(oyun.kis.get("yara", 0.0) + x, 0.0, 100.0)
	oyun.kayit("Yaralandın; dinlenmezsen hastalığa açık olursun.", "bad")

# 0..1.5: ihtiyaçların ve yaranın bedene bindirdiği yük
func yuk() -> float:
	var k: Dictionary = oyun.kis
	var p: float = maxf(0.0, k["aclik"] - 55.0) + maxf(0.0, k["yorgun"] - 55.0) + maxf(0.0, k["stres"] - 65.0) * 0.7 + k.get("yara", 0.0) * 0.5
	return clampf(p / 100.0, 0.0, 1.5)

func hasta_mi() -> bool:
	return oyun.t < oyun.kis["hasta"]

# 0.55..1.0: bitkinlik, açlık, stres ve hastalık yüzünden performans kaybı
func form() -> float:
	var k: Dictionary = oyun.kis
	var c := 0.0
	c += maxf(0.0, k["aclik"] - 65.0) * 0.004
	c += maxf(0.0, k["yorgun"] - 65.0) * 0.005
	c += maxf(0.0, k["stres"] - 70.0) * 0.004
	c += maxf(0.0, k["sikinti"] - 80.0) * 0.002
	if hasta_mi():
		c += 0.2 + k.get("agir", 0.0) * 0.002
	c += k.get("yara", 0.0) * 0.002
	return clampf(1.0 - c, 0.55, 1.0)

# Her oyun saatinde çağrılır (oyun.gd _saat).
func saat() -> void:
	var k: Dictionary = oyun.kis
	if not k.has("agir"):
		k["agir"] = 0.0
		k["yara"] = 0.0
	if oyun.t - _son_t < 30:
		return
	var dk: float = float(oyun.t - _son_t)
	_son_t = oyun.t
	var sa := dk / 60.0
	var d: Dictionary = oyun.tarih()
	var gece: bool = d["saat"] >= 22 or d["saat"] < 6
	var ic: bool = (oyun.ic_mekan == oyun._ev and oyun._ev >= 0) or (oyun.ic_mekan >= 0 and oyun.pazar_k.konak_mi(oyun.ic_mekan))
	var dis_ic: bool = oyun.ic_mekan >= 0
	var dayan: float = clampf(1.0 - 0.45 * oz("dayan"), 0.55, 1.5)
	var uyuyor: bool = k["uyuyor"]
	# açlık
	degis("aclik", sa * (1.6 if uyuyor else 3.2) * dayan)
	# yorgunluk
	if uyuyor:
		degis("yorgun", -sa * 9.0 * (1.0 + 0.3 * oz("saglik")))
	else:
		var y := 2.6 * dayan
		if gece:
			y *= 1.0 + 0.35 * (1.0 - clampf(oz("gece"), 0.0, 1.0))
		degis("yorgun", sa * y)
	# sıkıntı: boş gezmek ve rutin
	if not uyuyor:
		degis("sikinti", sa * 1.6 * (1.0 + oz("sikinti")) * (0.6 if dis_ic else 1.0))
	# stres: tehlikeden birikir, evde ve uykuda çözülür
	var s := 0.0
	if oyun.arama >= 50.0:
		s += 1.0 + (oyun.arama - 50.0) / 40.0
	elif oyun.arama >= 25.0:
		s += 0.3
	var kalan: int = oyun.DAYS_PER_MONTH - int(d["ay_gun"]) + 1
	if kalan <= 3 and oyun.borc.get("ana", 0.0) > 0.0 and oyun.temiz < oyun.borc.get("taksit", 0.0):
		s += 0.8
	for kk in oyun.gerg:
		if oyun.gerg[kk]["savas"] > oyun.t and kk.contains("oyuncu"):
			s += 0.6
	if k["aclik"] > 80.0:
		s += 0.4
	if k["yorgun"] > 85.0:
		s += 0.4
	if ic or uyuyor:
		s -= 1.4
	else:
		s -= 0.25
	if s > 0.0:
		stres_ekle(s * sa)
	else:
		degis("stres", s * sa)
	# gece çalışma alışkanlığı
	if gece and not uyuyor and not dis_ic and k["yorgun"] < 90.0:
		k["gece_say"] += sa
		if k["gece_say"] >= 3.0:
			k["gece_say"] = 0.0
			oz_ekle("gece_kusu", 1.0)
	# hastalık
	# yara: dinlenince ve tok/dinçken iyileşir
	if k.get("yara", 0.0) > 0.0:
		var iy: float = 0.35
		if uyuyor or ic:
			iy = 1.1
		if k["aclik"] > 85.0 or k["yorgun"] > 90.0:
			iy = 0.0
		k["yara"] = maxf(0.0, k["yara"] - iy * sa * clampf(1.0 + 0.4 * oz("saglik"), 0.6, 1.5))
	var yuk_d: float = yuk()
	if hasta_mi():
		var dinlen: bool = uyuyor or ic
		# iyileşme hızı: dinlenmeyle artar, ihtiyaç yükü ve yara ile düşer
		var hiz: float = (0.5 if dinlen else 0.0) * clampf(1.0 - yuk_d * 0.9, 0.1, 1.0)
		k["hasta"] -= int(dk * hiz)
		# hastalığın ağırlığı: yük bindikçe ve dinlenilmedikçe artar, rahat ortamda azalır
		var da: float = (0.1 + yuk_d * 0.55) * (0.2 if dinlen and yuk_d < 0.5 else 1.0) - (1.0 if dinlen and yuk_d < 0.4 else 0.0)
		k["agir"] = clampf(k["agir"] + da * sa, 0.0, 100.0)
		if k["agir"] >= 60.0 and not k["uyari"].get("agir", false):
			k["uyari"]["agir"] = true
			oyun.kayit("%s ağırlaştı! Hemen eve git, karnını doyur, ilaç al; yoksa ölebilirsin." % k["hasta_ad"], "bad")
		if k["agir"] >= 100.0 and oyun.son.is_empty():
			oyun.son = {"tur": "yenilgi", "metin": "%s seni yendi. Kendine bakmadın; bedenin dayanamadı. Southside sessizce bir adam eksildi." % k["hasta_ad"]}
		if oyun.t >= k["hasta"] and k["agir"] >= 50.0:
			k["hasta"] = oyun.t + int(0.5 * oyun.DAY)   # geçmedi, uzadı
	elif k["hasta_ad"] != "":
		k["hasta_ad"] = ""
		k["agir"] = 0.0
		k["uyari"]["agir"] = false
		oyun.kayit("Hastalığın geçti.", "good")
	else:
		# risk ihtiyaçlarla sürekli artar (eşik altında da küçük)
		var risk: float = (maxf(0.0, k["yorgun"] - 50.0) * 0.00055 + maxf(0.0, k["aclik"] - 55.0) * 0.0006 + maxf(0.0, k["stres"] - 55.0) * 0.0005 + k.get("yara", 0.0) * 0.0004)
		if oyun.mevsim() == "Kış":
			risk += 0.003
		risk *= clampf(1.0 - 0.8 * oz("saglik"), 0.3, 2.0) * sa
		if risk > 0.0 and oyun.rng.randf() < risk:
			var ad: String = ["Grip", "Zatürre", "Ateş", "Mide hastalığı"][oyun.rng.randi() % 4]
			k["hasta"] = oyun.t + int((2.0 + oyun.rng.randf() * 3.0) * oyun.DAY)
			k["hasta_ad"] = ad
			k["agir"] = 15.0 + yuk_d * 25.0
			oyun.kayit("%s oldun. Evde yat, karnını doyur ya da ilaç al; kendine bakmazsan ağırlaşır." % ad, "bad")
	# uyarılar
	_uyar("aclik", 70.0, "Karnın zil çalıyor. Bir lokantaya ya da eve git.", "bad")
	_uyar("yorgun", 75.0, "Gözlerin kapanıyor. Eve dönüp uyu.", "bad")
	_uyar("stres", 70.0, "Sinirlerin gergin. Bir içki, hamam ya da evde dinlen.", "bad")
	_uyar("sikinti", 75.0, "Canın sıkıldı. Bir bara, bilardoya ya da sinemaya uğra.", "warn")
	# özellikler zamanla solar
	if int(oyun.t / 60) % 24 == 0:
		for id in k["oz"].keys():
			k["oz"][id] = maxf(0.0, k["oz"][id] - 0.12)

func _uyar(a: String, esik: float, m: String, tur: String) -> void:
	var u: Dictionary = oyun.kis["uyari"]
	if oyun.kis[a] >= esik:
		if not u.get(a, false):
			u[a] = true
			oyun.kayit(m, tur)
	elif oyun.kis[a] < esik - 15.0:
		u[a] = false

# En acil ihtiyaç -> {ad, deger, mesaj} (yoksa boş)
func acil() -> Dictionary:
	var k: Dictionary = oyun.kis
	var en := ""
	var en_d := 0.0
	var msj := {"aclik": "AÇSIN: bir lokantaya git (yemek ye).", "yorgun": "BİTKİNSİN: eve dön ve uyu.",
		"stres": "STRESTESİN: bir bar, hamam ya da ev.", "sikinti": "CANIN SIKILIYOR: eğlenceli bir yere uğra."}
	var esik := {"aclik": 70.0, "yorgun": 75.0, "stres": 70.0, "sikinti": 75.0}
	for a in esik:
		var f: float = k[a] - esik[a]
		if f > en_d:
			en_d = f
			en = a
	if hasta_mi():
		return {"ad": "hasta", "mesaj": "%s: evde yat ya da bir eczaneden ilaç al." % k["hasta_ad"]}
	if en == "":
		return {}
	return {"ad": en, "mesaj": msj[en]}

# ---------- bina eylemleri ----------
func _isim(i: int) -> String:
	return String(oyun.harita.yerler[i]["ad"]).to_lower()

func eylemler(i: int) -> Array:
	var ad := _isim(i)
	var l: Array = []
	if i == oyun._ev:
		l = ["evde_ye", "dinlen"]
		return l
	if ad.contains("diner") or ad.contains("deli") or ad.contains("tavern") or ad.contains("hotel") or ad.contains("butcher row") or ad.contains("soda"):
		l.append("yemek")
	if ad.contains("bakery") or ad.contains("bakeshop") or ad.contains("grocer") or ad.contains("produce") or ad.contains("market") or ad.contains("fish") or ad.contains("butcher"):
		l.append("atistirma")
	if ad.contains("bar") or ad.contains("tavern") or ad.contains("sailors") or ad.contains("club"):
		l.append("icki")
		l.append("sohbet")
	if ad.contains("pool"):
		l.append("bilardo")
		l.append("sohbet")
		l.append("kumar")
	if ad.contains("social"):
		l.append("sohbet")
		l.append("kumar")
	if ad.contains("bath"):
		l.append("hamam")
	if ad.contains("cinema") or ad.contains("theater") or ad.contains("orpheum"):
		l.append("sinema")
	if ad.contains("synagogue") or ad.contains("church"):
		l.append("dua")
	if ad.contains("boxing"):
		l.append("idman")
	if ad.contains("drugstore") or ad.contains("dentist"):
		l.append("ilac")
	return l

func yap(id: String) -> Dictionary:
	var e: Dictionary = EYLEM[id]
	var ucret: float = e["ucret"] * clampf(1.0 - 0.3 * oz("pazarlik"), 0.6, 1.4)
	if oyun.temiz + oyun.kirli < ucret:
		return oyun.hata("Para yetmiyor ($%d)." % int(ucret))
	if ucret > 0.0:
		oyun.harcama(ucret, "kirli")
	if id == "ilac":
		if hasta_mi():
			oyun.kis["agir"] = maxf(0.0, oyun.kis["agir"] - 55.0)
			oyun.kis["hasta"] -= int(1.5 * oyun.DAY)
			oyun.kis["yara"] = maxf(0.0, oyun.kis.get("yara", 0.0) - 15.0)
			oyun.kayit("İlaç aldın; hastalık geriliyor (dinlenmeyi ihmal etme).", "good")
		else:
			oyun.kis["yara"] = maxf(0.0, oyun.kis.get("yara", 0.0) - 25.0)
			oyun.kayit("İlaç aldın; yaraların sarıldı.", "good")
	for a in e["d"]:
		var dv: float = e["d"][a]
		if a == "stres" and dv > 0.0:
			stres_ekle(dv)
		else:
			degis(a, dv)
	for o in e["oz"]:
		if e["oz"][o] > 0.0:
			oz_ekle(o, e["oz"][o])
	if id == "icki" and oyun.kis["stres"] < 20.0:
		oz_ekle("alkolik", 0.5)
	if id == "sohbet":
		# gece çevre edinmek daha verimli
		var sa: int = oyun.tarih()["saat"]
		if sa >= 20 or sa < 4:
			oz_ekle("gece_kusu", 1.5)
			oz_ekle("cilveli", 1.0)
		if oz("bilgi") > 0.1 and oyun.rng.randf() < 0.5 + oz("bilgi"):
			oyun.arama = maxf(0.0, oyun.arama - 3.0)
			oyun.kayit("Sohbette polisin ne düşündüğünü öğrendin: bir iki şeyi toparladın (dosya −3).", "good")
	oyun.bekle(int(e["dk"]))
	return oyun.tamam("%s (%d dk)." % [e["ad"], e["dk"]])

func uyku_baslat() -> void:
	oyun.kis["uyuyor"] = true

func uyku_bitti() -> void:
	oyun.kis["uyuyor"] = false

# ---------- tanınırlık ----------
# Tanınırlık: parayla, bölgelerle, ekiple ve dosyayla büyür. Aileler, ancak ismin yayılınca seni umursar.
func taninma() -> float:
	var top := 0.0
	var mx := 0.0
	for id in oyun.bolge:
		mx = maxf(mx, oyun.bolge[id]["tan"])
	var haracli := 0
	for i in oyun.isy:
		if oyun.isy[i]["haracli"] or oyun.isy[i]["sahip"]:
			haracli += 1
	top += 0.15 * mx
	top += minf(30.0, (oyun.temiz + oyun.kirli) / 400.0)
	top += 7.0 * oyun.oyuncu_bolgeleri().size()
	top += 3.0 * haracli
	top += 2.5 * oyun.adamlar.size()
	top += 0.25 * oyun.arama
	top += 0.15 * oyun.yol_k.puan("korku")
	top += minf(15.0, 0.6 * float(oyun.isler.get("tamam", 0)))   # yaptığın kirli işler
	return clampf(top, 0.0, 100.0)

const ESIK_TAN := 28.0       # rakip aileler seni bu tanınırlıktan sonra umursar

func fark_edildi() -> bool:
	return taninma() >= ESIK_TAN

func tan_kontrol() -> void:
	var t := taninma()
	var s := 0
	if t >= 70.0:
		s = 3
	elif t >= 45.0:
		s = 2
	elif t >= ESIK_TAN:
		s = 1
	if s > _son_taninma:
		var m: String = ["", "Adın duyulmaya başladı. Aileler artık seni fark ediyor; sokakta bulaşanlar çıkacak.", "Şehir adını biliyor. Rakipler seni tehdit olarak görüyor.", "Sen artık şehrin konuşulan adamlarındansın. Herkes bir şey bekliyor."][s]
		oyun.kayit(m, "warn")
	_son_taninma = s
