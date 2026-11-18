extends RefCounted
# Karakter profili: menüde seçilir, oyun.gd başlangıçta uygular. Hiçbir şey seçilmediyse (test/komut satırı)
# varsayılan profil geçerlidir: eski davranışın aynısı.

static var aktif: Dictionary = {}          # {ad, yas, koken, aile, gecmis}
static var yukle_basta := false            # ana menüden "Devam Et" ile açıldı: kayıt dosyası yüklenecek

const KOKENLER := {
	"yerli": {"ad": "Southside'lı", "ikon": "🏠",
		"ozet": "Bu mahallede doğdun. Herkes seni tanır, birkaç dostun ve küçük bir birikimin var. Ama baban ölünce geriye yalnızca borç kaldı; her şeyi kendin kazanacaksın.",
		"temiz": 1500.0, "kirli": 0.0, "kira": 0, "konum": "Southside, evinin önü", "ev": "Home"},
	"aile": {"ad": "Bir ailenin adamı", "ikon": "🤝",
		"ozet": "Bir ailenin soldatosu olarak başlarsın. Aile semtinde sözün geçer, aylık pay alırsın; ama patronların da seni izler.",
		"temiz": 600.0, "kirli": 500.0, "kira": 0, "konum": "Ailenin karargâhı", "ev": ""},
	"gocmen": {"ad": "Dışarıdan gelen", "ikon": "✈",
		"ozet": "Şehre yeni indin. Kimseyi tanımıyorsun, cebinde birkaç dolar var. Ucuz bir oda kiralarsın; önce iş bulup çalışman gerekir.",
		"temiz": 45.0, "kirli": 0.0, "kira": 12, "konum": "Havaalanı", "ev": "Tenement"},
}

const AILELER := {
	"marchetti": {"ad": "Marchetti Family", "yer": "Marchetti Family", "renk": Color("c2506b"), "bolge": "flats",
		"ozet": "İtalyan ailesi: Flats ve Docks'ta güçlü, disiplinli."},
	"obrien": {"ad": "O'Brien Çetesi", "yer": "", "renk": Color("58a866"), "bolge": "eastside",
		"ozet": "İrlandalı çete: Eastside'ın sahibi, kavgacı ve gürültücü."},
	"tammany": {"ad": "Belediye Makinesi", "yer": "City Hall", "renk": Color("5f8fc4"), "bolge": "downtown",
		"ozet": "Siyasi makine: Downtown ve Hilltop'ta nüfuz, temiz görünüşlü."},
}

# Geçmişler: stat değişimleri (güç, nişan, zeka, karizma) + başlangıç parası.
const GECMISLER := {
	"isci": {"ad": "Liman işçisi", "d": {"guc": 2, "karizma": -1}, "temiz": 0.0, "kirli": 0.0,
		"ozet": "Yıllarca çuval taşıdın: güçlü ve dayanıklısın."},
	"boksor": {"ad": "Eski boksör", "d": {"guc": 1, "karizma": 1, "zeka": -1}, "temiz": 0.0, "kirli": 0.0,
		"ozet": "Ringde para kazandın: yumruğun ağır, adın bilinir."},
	"gazi": {"ad": "Savaş gazisi", "d": {"nisan": 2, "guc": 1, "zeka": -1}, "temiz": 0.0, "kirli": 0.0,
		"ozet": "Avrupa'dan döndün: soğukkanlı ve keskin nişancı."},
	"hesapci": {"ad": "Muhasebeci", "d": {"zeka": 2, "karizma": 1, "guc": -2}, "temiz": 150.0, "kirli": 0.0,
		"ozet": "Rakamlarla aran iyi: iş ve para konusunda akıllısın."},
	"kacakci": {"ad": "Kaçakçı çırağı", "d": {"zeka": 1, "nisan": 1, "karizma": -1}, "temiz": 0.0, "kirli": 300.0,
		"ozet": "Viski kaçırdın: sokağı bilirsin, cebinde kirli para var."},
}

const ISIMLER_AD := ["Tommy", "Vincent", "Frank", "Jack", "Eddie", "Sam", "Danny", "Walter", "Louie", "Henry", "Mickey", "Charlie", "Joe", "Nick", "Paul", "Artie"]
const ISIMLER_SOYAD := ["Romano", "Callahan", "Novak", "Weiss", "Santoro", "Doyle", "Kovacs", "Brennan", "Moretti", "Hayes", "Lombardi", "Fischer", "Reilly", "Costa", "Walsh", "Berg"]

static func varsayilan() -> Dictionary:
	return {"ad": "Sen", "yas": 30, "koken": "yerli", "aile": "marchetti", "gecmis": "yok"}

static func rastgele_ad() -> String:
	return "%s %s" % [ISIMLER_AD[randi() % ISIMLER_AD.size()], ISIMLER_SOYAD[randi() % ISIMLER_SOYAD.size()]]

static func al() -> Dictionary:
	if aktif.is_empty():
		return varsayilan()
	return aktif

# Seçimlerden türeyen her şey (hem menü özeti hem oyun burayı kullanır).
static func ozet(p: Dictionary) -> Dictionary:
	var s := {"guc": 5, "nisan": 5, "zeka": 5, "karizma": 5}
	var yas: int = p["yas"]
	if yas < 25:
		s["guc"] += 1
		s["karizma"] -= 1
	elif yas >= 55:
		s["guc"] -= 2
		s["karizma"] += 1
		s["zeka"] += 1
	elif yas >= 40:
		s["guc"] -= 1
		s["karizma"] += 1
		s["zeka"] += 1
	var k: Dictionary = KOKENLER[p["koken"]]
	if p["koken"] == "yerli":
		s["karizma"] += 1
	elif p["koken"] == "aile":
		s["guc"] += 1
	else:
		s["zeka"] += 1
	var temiz: float = k["temiz"]
	var kirli: float = k["kirli"]
	if GECMISLER.has(p["gecmis"]):
		var g: Dictionary = GECMISLER[p["gecmis"]]
		for st in g["d"]:
			s[st] += g["d"][st]
		temiz += g["temiz"]
		kirli += g["kirli"]
	for st in s:
		s[st] = clampi(s[st], 1, 10)
	var konum: String = k["konum"]
	var ev_ad: String = k["ev"]
	if p["koken"] == "aile":
		var a: Dictionary = AILELER[p["aile"]]
		konum = "%s karargâhı" % a["ad"]
		ev_ad = a["yer"]
	return {"stat": s, "temiz": temiz, "kirli": kirli, "kira": k["kira"], "konum": konum, "ev_ad": ev_ad,
		"hp": 100.0 + (s["guc"] - 5) * 6.0, "isabet": 0.5 + (s["nisan"] - 5) * 0.04,
		"guc_carpan": 1.0 + (s["guc"] - 5) * 0.1, "ucret_carpan": 1.0 + (s["zeka"] - 5) * 0.04 + (s["karizma"] - 5) * 0.02}
