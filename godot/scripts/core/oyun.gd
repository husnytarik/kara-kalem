extends Node
# Oyun durumu ve kuralları (JS prototipinden taşındı: bolge.js, isyeri.js, savas.js ekip kısmı).
# 2D arayüz bu düğümün sinyallerini dinler; harita/3D bu düğümü yalnızca okur ve eylem çağırır.
# Eylemler {ok: bool, msg: String} döndürür.

signal degisti                 # durum değişti, arayüz yenilensin
signal mesaj(metin: String, tur: String)

const DAY := 1440
const DK_SN := 8.0             # 1 gerçek saniye = 8 oyun dakikası (hız ×1)
const HAKIM_ESIK := 35.0
const SERVET_MAX := 5
const HAVUZ := 600.0
const EKIP_MAX := 8
const EKIP_MAAS := 40
const EKIP_FIYAT := 100
const GARNIZON_MAX := 6
const WALK := 2.0              # adam hızı, metre / oyun dakikası
const DAYS_PER_MONTH := 10

const HARAC := [["Yok", 0.0], ["Hafif %8", 0.08], ["Orta %15", 0.15], ["Ağır %25", 0.25]]
const FAK := {
	"oyuncu": {"ad": "Sen", "renk": Color("e0b24a"), "saldirgan": 1.0},
	"marchetti": {"ad": "Marchetti Family", "renk": Color("c2506b"), "saldirgan": 1.0},
	"obrien": {"ad": "O'Brien Çetesi", "renk": Color("58a866"), "saldirgan": 1.25},
	"tammany": {"ad": "Belediye Makinesi", "renk": Color("5f8fc4"), "saldirgan": 0.35},
}
const NPC := ["marchetti", "obrien", "tammany"]
const KOMSU := {
	"hilltop": ["downtown", "southside"], "downtown": ["hilltop", "eastside"],
	"southside": ["hilltop", "eastside", "flats"], "eastside": ["downtown", "southside", "flats"],
	"flats": ["southside", "eastside", "docks"], "docks": ["flats"],
}
const ACIKLAMA := {
	"hilltop": "Villalar, bankerler ve siyasetçiler. Para burada konuşur, ses çıkarmaz.",
	"downtown": "Belediye, banka, karakol ve gazete. Şehrin resmî yüzü.",
	"southside": "Senin semtin. Dar sokaklar, sadık halk, eski borçlar.",
	"eastside": "Göçmen mahalleleri, pazar yerleri, kalabalık apartmanlar.",
	"flats": "Demiryolu, depo ve atölyeler. Kimse ne yüklendiğini sormaz.",
	"docks": "Liman. Kaçakçılık, işçi sendikaları ve yarısı Marchetti'nin olan ambarlar.",
}
const KARAKTER := {
	"hilltop": {"sev": 0.8, "kor": 0.5, "ac": "Çekingen ve kibar: ziyafetle yumuşar; gözdağına polis çağırır."},
	"downtown": {"sev": 0.9, "kor": 0.7, "ac": "Resmî ve temkinli: sevgi de korku da zor işler."},
	"southside": {"sev": 1.4, "kor": 0.6, "ac": "Sadık halk: sevgiyle bağlanır, korkuya soğuk bakar."},
	"eastside": {"sev": 1.1, "kor": 0.9, "ac": "Kalabalık ve kapalı: yardım edeni unutmaz, sindireni de."},
	"flats": {"sev": 0.8, "kor": 1.2, "ac": "Sert işçi mahallesi: haraç korkuyla ödenir."},
	"docks": {"sev": 0.6, "kor": 1.5, "ac": "Sendika ve kaçakçı limanı: yalnızca güçlüyü dinler."},
}
const B0 := {
	"hilltop": {"inf": {"tammany": 70.0, "marchetti": 10.0}, "servet": 4, "ilerleme": 40.0, "huzur": 80.0, "tan": 3.0, "sev": 15.0, "kor": 5.0},
	"downtown": {"inf": {"tammany": 55.0, "obrien": 15.0, "marchetti": 10.0}, "servet": 4, "ilerleme": 20.0, "huzur": 70.0, "tan": 8.0, "sev": 20.0, "kor": 10.0},
	"southside": {"inf": {"oyuncu": 25.0, "obrien": 15.0, "marchetti": 15.0}, "servet": 2, "ilerleme": 30.0, "huzur": 60.0, "tan": 55.0, "sev": 60.0, "kor": 10.0},
	"eastside": {"inf": {"obrien": 60.0, "marchetti": 15.0}, "servet": 3, "ilerleme": 50.0, "huzur": 65.0, "tan": 12.0, "sev": 40.0, "kor": 15.0},
	"flats": {"inf": {"marchetti": 65.0, "obrien": 10.0}, "servet": 3, "ilerleme": 10.0, "huzur": 70.0, "tan": 6.0, "sev": 30.0, "kor": 25.0},
	"docks": {"inf": {"marchetti": 45.0, "tammany": 20.0, "obrien": 10.0}, "servet": 4, "ilerleme": 60.0, "huzur": 60.0, "tan": 6.0, "sev": 20.0, "kor": 40.0},
}
const TURLER := {
	"esnaf": {"ad": "Esnaf", "gelir": 14, "direnc": 3, "fiyat": 700},
	"eglence": {"ad": "Eğlence yeri", "gelir": 28, "direnc": 5, "fiyat": 1500},
	"luks": {"ad": "Lüks işletme", "gelir": 42, "direnc": 6, "fiyat": 2400},
	"atolye": {"ad": "Atölye / fabrika", "gelir": 22, "direnc": 5, "fiyat": 1100},
	"depo": {"ad": "Depo / liman işi", "gelir": 32, "direnc": 6, "fiyat": 1700},
	"konut": {"ad": "Apartman / pansiyon", "gelir": 11, "direnc": 2, "fiyat": 500},
	"resmi": {"ad": "Resmî kurum", "gelir": 0, "direnc": 99, "fiyat": 0},
}
const KURAL := [
	["resmi", ["bank", "courier", "post office", "hospital", "church", "synagogue", "school", "courthouse", "station", "exchange", "customs", "harbor master", "chamber", "stevedore", "precinct", "hiring", "city hall", "social hall"]],
	["luks", ["hotel", "jeweler", "club", "gallery", "mansion", "perfumery", "department", "theater", "cinema", "attorney", "library", "chauffeur", "watchmaker"]],
	["eglence", ["pool", " bar", "sailors", "social", "soda", "boxing", "bath", "diner"]],
	["depo", ["warehouse", "cold storage", "grain", "rail depot", "coal", "ship", "cannery", "fish market", "rope"]],
	["atolye", ["smith", "carpenter", "foundry", "brick", "tool", "sweatshop", "junk", "print", "dentist", "tailor"]],
	["konut", ["tenement", "boarding", "laundry"]],
]
const GOREVLER := {
	"haraclan": {"ad": "Haraç bağla", "is": 60},
	"topla": {"ad": "Haracı topla", "is": 25},
	"koru": {"ad": "Koru", "is": 40},
}
const IS_AD := {"himaye": "Esnafa himaye sat", "hediye": "Mahalleye ziyafet ver", "gozdagi": "Rakip adamları sindir"}
const IS_BEDEL := {"himaye": "$120 kirli", "hediye": "$200 temiz", "gozdagi": "$150 kirli · ekipte adam gerekir"}
const BEKLEME := {"himaye": 3, "hediye": 3, "gozdagi": 5}
# Silahlar: hasar (vuruş başı), menzil (m), hiz (atış/sn), sarjor (0: yakın dövüş), yenileme (sn), sacilma (radyan), pelet (saçma sayısı), fiyat (kirli $)
const SILAH := {
	"yumruk": {"ad": "Yumruk", "hasar": 12.0, "menzil": 2.3, "hiz": 1.5, "sarjor": 0, "yenileme": 0.0, "sacilma": 0.0, "pelet": 1, "fiyat": 0},
	"bicak": {"ad": "Bıçak", "hasar": 24.0, "menzil": 2.5, "hiz": 1.8, "sarjor": 0, "yenileme": 0.0, "sacilma": 0.0, "pelet": 1, "fiyat": 40},
	"tabanca": {"ad": "Tabanca", "hasar": 18.0, "menzil": 40.0, "hiz": 2.8, "sarjor": 8, "yenileme": 1.6, "sacilma": 0.035, "pelet": 1, "fiyat": 150},
	"pompali": {"ad": "Pompalı", "hasar": 9.0, "menzil": 20.0, "hiz": 1.0, "sarjor": 2, "yenileme": 2.2, "sacilma": 0.12, "pelet": 6, "fiyat": 300},
	"tommy": {"ad": "Tommy Gun", "hasar": 11.0, "menzil": 45.0, "hiz": 9.0, "sarjor": 30, "yenileme": 2.4, "sacilma": 0.07, "pelet": 1, "fiyat": 450},
}
# Aile hiyerarşisi: don > ikinci > danışman > kaptan > asker. Kaptanlar ve askerler ekiplere liderlik eder.
const RUTBE_SIRA := ["don", "ikinci", "danisman", "kaptan", "asker"]
const RUTBE := {
	"marchetti": {"don": "Don", "ikinci": "Underboss", "danisman": "Consigliere", "kaptan": "Capo", "asker": "Soldato"},
	"obrien": {"don": "Patron", "ikinci": "Sağ Kol", "danisman": "Muhasebeci", "kaptan": "Kaptan", "asker": "Külhanbeyi"},
	"tammany": {"don": "Başkan", "ikinci": "Meclis Üyesi", "danisman": "Avukat", "kaptan": "Bölge Temsilcisi", "asker": "Yardakçı"},
}
# Savaştaki güç: hp, silah havuzu, nişan başarısı
const RUTBE_GUC := {
	"don": {"hp": 140.0, "silah": ["tommy"], "isabet": 0.62},
	"ikinci": {"hp": 115.0, "silah": ["tommy", "pompali"], "isabet": 0.58},
	"danisman": {"hp": 80.0, "silah": ["tabanca"], "isabet": 0.55},
	"kaptan": {"hp": 95.0, "silah": ["pompali", "tommy", "tabanca"], "isabet": 0.55},
	"asker": {"hp": 70.0, "silah": ["tabanca", "bicak"], "isabet": 0.5},
}
const ADLAR := {
	"marchetti": [["Vito", "Carlo", "Sal", "Enzo", "Paulie", "Gino", "Rocco", "Nico"], ["Marchetti", "Bruno", "Gallo", "Rizzo", "Conti", "Moretti", "Fontana", "Greco"]],
	"obrien": [["Seamus", "Declan", "Finn", "Patrick", "Liam", "Colm", "Brendan", "Rory"], ["O'Brien", "Doyle", "Keane", "Murphy", "Quinn", "Walsh", "Byrne", "Kelly"]],
	"tammany": [["Walter", "Harold", "Edmund", "Clarence", "Arthur", "Chester", "Lloyd", "Percy"], ["Whitcomb", "Hargrove", "Pembroke", "Ashworth", "Sterling", "Vandermeer", "Crane", "Talbot"]],
}
const ISIMLER := ["Vinnie", "Moe", "Sully", "Bugsy", "Lenny", "Sal", "Dutch", "Frankie", "Mickey", "Nate", "Ray", "Hank", "Joey", "Tommy", "Lou", "Abe"]

var harita: Node3D
var rng := RandomNumberGenerator.new()
var t := 9 * 60                       # oyun dakikası (gün 0, 09:00)
var temiz := 1500.0
var kirli := 0.0
var bolge := {}                       # id -> durum
var ofke := {"marchetti": 0.0, "obrien": 0.0, "tammany": 0.0}
var adamlar: Array[Dictionary] = []   # {id, ad, yumruk, bicak, zeka, gorev}
var gorevler: Array[Dictionary] = []  # {adam, hedef, gorev, basla, yol, bitis, yolu}
var isy := {}                         # bina indeksi -> {tur, sahip, haracli, birikim, korumaBitis}
var oyuncu_silah := "tabanca"
var uyeler: Array = []   # aile üyeleri: {uid, ad, fak, rutbe, durum: aktif|olu, iliski, ev}
var _uid := 0
var _pid := 0
var ziyaret := {}   # bina -> gelen/gidenler günlüğü (görüş altındayken tutulur)
var gozlem := {}    # bina -> {t, n}: son gözlenen kişi sayısı
var muhbir := {"marchetti": 0, "obrien": 0, "tammany": 0}   # aile içi muhbir ağı seviyesi (0-3)
var ajan_sogutma := {}   # aile -> bu zamana kadar yeni sızma denemesi yok
var isl: RefCounted
var zafer: RefCounted
var arac_k: RefCounted
var arac := {"tip": "", "yakit": 0.0, "kullan": false, "ariza": 0, "yol": 0.0}   # araba durumu
var zf := {"kampanya": 0.0, "durust_ay": 0, "hakim_ay": 0}   # zafer yolları ilerlemesi
var son := {}                    # oyun bitti: {tur: zafer|yenilgi, metin}
var arama := 0.0   # polisin seni arama seviyesi (0-100)
var defter: Array[Dictionary] = []    # {t, metin, tur}
var _sayac := 0
var _ev := -1
var profil: Dictionary = {}     # menüden gelen karakter: {ad, yas, koken, aile, gecmis}
var ozet: Dictionary = {}       # profil.gd ozet(): statlar, hp, ücret çarpanı...
var vardiya: Dictionary = {}    # çalışıyorsan: {bina, bitis, ucret}
var kira_borc := 0.0
var mes: Dictionary = {}        # meslek durumu (meslek.gd)
var meslek: RefCounted
var borc: Dictionary = {}       # babanın tefeci borcu {ana, taksit, kacirilan}
var borc_k: RefCounted
var akl: Dictionary = {}        # aklama durumu (aklama.gd)
var aklama_k: RefCounted
var _kesir := 0.0

func kur(h: Node3D) -> void:
	harita = h
	rng.seed = 20260
	for id in B0:
		var b: Dictionary = B0[id].duplicate(true)
		b["garnizon"] = 0
		b["harac"] = 1
		b["sonIs"] = {}
		b["yatirimAy"] = -99
		bolge[id] = b
	for i in harita.yerler.size():
		var y: Dictionary = harita.yerler[i]
		if y["ad"] == "Home":
			_ev = i
		if y["ozel"]:
			continue
		var tur := _tur(y["ad"])
		if tur != "resmi":
			isy[i] = {"tur": tur, "sahip": false, "haracli": false, "birikim": 0.0, "korumaBitis": 0}
	isl = load("res://scripts/core/isletme.gd").new(self)
	zafer = load("res://scripts/core/zafer.gd").new(self)
	arac_k = load("res://scripts/core/arac.gd").new(self)
	meslek = load("res://scripts/core/meslek.gd").new(self)
	mes = meslek.yeni()
	borc_k = load("res://scripts/core/borc.gd").new(self)
	borc = borc_k.yeni()
	aklama_k = load("res://scripts/core/aklama.gd").new(self)
	akl = aklama_k.yeni()
	_aileleri_kur()
	_profil_uygula()

# Karakter seçimini oyun durumuna işler: para, ev, tanınırlık, aile bağı.
func _profil_uygula() -> void:
	var P := load("res://scripts/core/profil.gd")
	profil = P.al().duplicate()
	ozet = P.ozet(profil)
	temiz = ozet["temiz"]
	kirli = ozet["kirli"]
	var ev_ad: String = ozet["ev_ad"]
	if ev_ad != "":
		for i in harita.yerler.size():
			if harita.yerler[i]["ad"] == ev_ad:
				_ev = i
				break
	match profil["koken"]:
		"yerli":
			borc_k.baslat()
			kayit("%s: Southside'da doğdun. Önce adam tut, sonra esnafa git." % profil["ad"], "info")
			kayit("Baban öldü; geriye %s tefeci borcu kaldı (aylık %s taksit, 3 kaçırırsan biter)." % [para(borc["ana"]), para(borc["taksit"])], "warn")
		"aile":
			var f: String = profil["aile"]
			var a: Dictionary = P.AILELER[f]
			var b: Dictionary = bolge[a["bolge"]]
			b["inf"]["oyuncu"] = b["inf"].get("oyuncu", 0.0) + 12.0
			b["tan"] = maxf(b["tan"], 30.0)
			bolge["southside"]["inf"].erase("oyuncu")
			bolge["southside"]["tan"] = 10.0
			ofke[f] = 0.0
			if _ev < 0 or harita.yerler[_ev]["ad"] != ev_ad:
				_ev = _en_yakin_bina(harita.merkez(a["bolge"]))
			kayit("%s: %s'nın adamı olarak başladın. Aylık pay alırsın; semtinde sözün geçer." % [profil["ad"], a["ad"]], "info")
		"gocmen":
			bolge["southside"]["inf"].erase("oyuncu")
			bolge["southside"]["tan"] = 3.0
			kayit("%s: Havaalanına indin. Cebinde %s var, ucuz bir oda tuttun. Önce çalışacak bir iş bul." % [profil["ad"], para(temiz)], "info")
			kayit("İpucu: bir dükkâna/atölyeye yürü, binaya tıkla ve 'Burada çalış' de.", "info")

func _en_yakin_bina(p: Vector3) -> int:
	var en := -1
	var d := 1e9
	for i in harita.yerler.size():
		var q: float = harita.yerler[i]["pos"].distance_squared_to(p)
		if q < d:
			d = q
			en = i
	return en

# Başlangıç noktası: köken ve ev binasına göre, yürünebilir bir yer.
func baslangic_noktasi() -> Vector3:
	var p: Vector3
	if profil.get("koken", "yerli") == "gocmen":
		p = Vector3(262, 0, 272)   # havaalanı apronu (tools/sehir_uret2.py)
	elif _ev >= 0:
		p = harita.yerler[_ev]["pos"]
	else:
		p = harita.merkez("southside")
	if profil.get("koken", "yerli") == "yerli":
		p = harita.merkez("southside")
	return harita.serbest_nokta(p)

# ---------- aile hiyerarşisi ----------
func _aileleri_kur() -> void:
	uyeler.clear()
	for f in NPC:
		uye_yarat(f, "don")
		uye_yarat(f, "ikinci")
		uye_yarat(f, "danisman")
		for k in 4:
			uye_yarat(f, "kaptan")

func uye_yarat(f: String, rutbe: String) -> Dictionary:
	_uid += 1
	var ad := ""
	var denendi := 0
	while denendi < 20:
		var a: Array = ADLAR[f]
		ad = "%s %s" % [a[0][rng.randi() % a[0].size()], a[1][rng.randi() % a[1].size()]]
		if uyeler.filter(func(u): return u["ad"] == ad and u["durum"] == "aktif").is_empty():
			break
		denendi += 1
	var u := {"uid": _uid, "ad": ad, "fak": f, "rutbe": rutbe, "durum": "aktif", "iliski": 0, "ev": ""}
	uyeler.append(u)
	return u

func uye(uid: int) -> Dictionary:
	for u in uyeler:
		if u["uid"] == uid:
			return u
	return {}

func uye_ad(u: Dictionary) -> String:
	return "%s %s" % [RUTBE[u["fak"]][u["rutbe"]], u["ad"]]

func uye_rutbe_ad(u: Dictionary) -> String:
	return RUTBE[u["fak"]][u["rutbe"]]

func aile_uyeleri(f: String) -> Array:
	var r: Array = uyeler.filter(func(u): return u["fak"] == f and u["durum"] == "aktif")
	r.sort_custom(func(a, b): return RUTBE_SIRA.find(a["rutbe"]) < RUTBE_SIRA.find(b["rutbe"]))
	return r

func uye_guc(u: Dictionary) -> Dictionary:
	return RUTBE_GUC[u["rutbe"]]

# Boş bir lider lazım: kullanılmayan bir kaptan, yoksa yeni bir asker doğar. Hariç: zaten lider olanların uid'leri.
func lider_bul(f: String, kullanilan: Array) -> Dictionary:
	for u in aile_uyeleri(f):
		if u["rutbe"] == "kaptan" and not kullanilan.has(u["uid"]):
			return u
	return uye_yarat(f, "asker")

func uye_oldu(uid: int) -> String:
	var u := uye(uid)
	if u.is_empty() or u["durum"] != "aktif":
		return ""
	u["durum"] = "olu"
	var f: String = u["fak"]
	var yazi := "%s öldürüldü." % uye_ad(u)
	if u["rutbe"] == "don":
		var ik: Array = aile_uyeleri(f).filter(func(x): return x["rutbe"] == "ikinci")
		if not ik.is_empty():
			ik[0]["rutbe"] = "don"
			yazi += " Yeni %s: %s." % [RUTBE[f]["don"], ik[0]["ad"]]
			var kap: Array = aile_uyeleri(f).filter(func(x): return x["rutbe"] == "kaptan")
			if not kap.is_empty():
				kap[0]["rutbe"] = "ikinci"
		else:
			uye_yarat(f, "don")
		for id in bolge:
			if bolge[id]["inf"].has(f):
				bolge[id]["inf"][f] = bolge[id]["inf"][f] * 0.85
		ofke[f] = minf(100.0, ofke[f] + 25.0)
		yazi += " Aile sarsıldı, intikam peşinde!"
	elif u["rutbe"] == "ikinci":
		var kap2: Array = aile_uyeleri(f).filter(func(x): return x["rutbe"] == "kaptan")
		if not kap2.is_empty():
			kap2[0]["rutbe"] = "ikinci"
		ofke[f] = minf(100.0, ofke[f] + 12.0)
	else:
		ofke[f] = minf(100.0, ofke[f] + 4.0)
	kayit(yazi, "warn")
	degisti.emit()
	return yazi

# ---------- yardımcılar ----------
func _tur(ad: String) -> String:
	var a := ad.to_lower()
	for r in [" vi", " v", " iv", " iii", " ii"]:
		if a.ends_with(r):
			a = a.trim_suffix(r)
			break
	if a.ends_with("hall"):
		return "resmi"
	for k in KURAL:
		for kelime in k[1]:
			if a.contains(kelime):
				return k[0]
	return "esnaf"

func kayit(metin: String, tur: String = "info") -> void:
	defter.append({"t": t, "metin": metin, "tur": tur})
	if defter.size() > 300:
		defter.pop_front()
	mesaj.emit(metin, tur)

func para(x: float) -> String:
	return "$" + str(int(round(x)))

func harcama(miktar: float, mod: String) -> bool:
	if mod == "temiz":
		if temiz < miktar:
			return false
		temiz -= miktar
		return true
	if kirli + temiz < miktar:
		return false
	var d := minf(kirli, miktar)
	kirli -= d
	temiz -= miktar - d
	return true

func hata(m: String) -> Dictionary:
	return {"ok": false, "msg": m}

func tamam(m: String = "") -> Dictionary:
	return {"ok": true, "msg": m}

func tarih(zaman: int = -1) -> Dictionary:
	var z := t if zaman < 0 else zaman
	var gun := z / DAY
	var ay := gun / DAYS_PER_MONTH
	return {"gun": gun, "saat": (z % DAY) / 60, "dk": z % 60, "ay": ay, "ay_gun": gun % DAYS_PER_MONTH + 1, "yil": ay / 12 + 1, "ay_yil": ay % 12 + 1}

func saat_yazi(zaman: int = -1) -> String:
	var d := tarih(zaman)
	return "%02d:%02d" % [d["saat"], d["dk"]]

func tarih_yazi() -> String:
	var d := tarih()
	return "%d. yıl · %d. ay · %d. gün" % [d["yil"], d["ay_yil"], d["ay_gun"]]

func mevsim() -> String:
	return ["İlkbahar", "Yaz", "Sonbahar", "Kış"][(tarih()["ay"] % 12) / 3]

# ---------- bölge okuma ----------
func hakim_of(id: String) -> String:
	var inf: Dictionary = bolge[id]["inf"]
	var en := ""
	var bv := HAKIM_ESIK - 1e-9
	for f in FAK:
		if inf.get(f, 0.0) > bv:
			bv = inf[f]
			en = f
	return en

func hakim_ad(f: String) -> String:
	return FAK[f]["ad"] if f != "" else "Sahipsiz"

func etki(b: Dictionary, id: String) -> Dictionary:
	return {"s": clampf(KARAKTER[id]["sev"] * b["sev"] / 100.0, 0.0, 1.5), "k": clampf(KARAKTER[id]["kor"] * b["kor"] / 100.0, 0.0, 1.5)}

func erisim(id: String) -> bool:
	if bolge[id]["inf"].get("oyuncu", 0.0) >= 15.0:
		return true
	for k in KOMSU[id]:
		if hakim_of(k) == "oyuncu":
			return true
	return false

func kudret(f: String) -> float:
	var k := 2.0
	for id in bolge:
		if hakim_of(id) == f:
			k += bolge[id]["servet"]
	return k

func oyuncu_bolgeleri() -> Array:
	return bolge.keys().filter(func(id): return hakim_of(id) == "oyuncu")

func add_inf(b: Dictionary, f: String, d: float) -> void:
	var inf: Dictionary = b["inf"]
	inf[f] = clampf(inf.get(f, 0.0) + d, 0.0, 100.0)
	var top := 0.0
	for k in inf:
		top += inf[k]
	if top > 100.0:
		var digerleri: float = top - inf[f]
		var k2: float = (100.0 - inf[f]) / digerleri if digerleri > 0.0 else 0.0
		for o in inf.keys():
			if o != f:
				inf[o] *= k2
	for k in inf.keys():
		if inf[k] < 0.05:
			inf.erase(k)

func _hakim_degisti(id: String, onceki: String) -> void:
	var yeni := hakim_of(id)
	if yeni == onceki:
		return
	var ad: String = harita.bolgeler[id]["ad"]
	if yeni == "oyuncu":
		kayit("%s artık senin. Bölgenin hakimisin." % ad, "good")
	elif onceki == "oyuncu":
		kayit("%s'ı kaybettin: artık %s hakim." % [ad, hakim_ad(yeni)], "bad")
	elif yeni != "":
		kayit("%s: %s bölgeyi %s aldı." % [ad, hakim_ad(yeni), hakim_ad(onceki) if onceki != "" else "sahipsizlikten"], "info")
	else:
		kayit("%s sahipsiz kaldı: %s nüfuzunu yitirdi." % [ad, hakim_ad(onceki)], "info")

func _nufuz(id: String, miktar: float) -> void:
	var b: Dictionary = bolge[id]
	var onceki := hakim_of(id)
	add_inf(b, "oyuncu", miktar * (1.0 - b["inf"].get("oyuncu", 0.0) / 120.0))
	_hakim_degisti(id, onceki)

func hakim_icin_kalan(id: String) -> float:
	var inf: Dictionary = bolge[id]["inf"]
	var en := 0.0
	for f in inf:
		if f != "oyuncu":
			en = maxf(en, inf[f])
	return maxf(HAKIM_ESIK, en + 0.1) - inf.get("oyuncu", 0.0)

# ---------- ekip / adamlar ----------
func _yeni_adam() -> Dictionary:
	var kullanilan := adamlar.map(func(a): return a["ad"])
	var ad: String = ISIMLER[rng.randi() % ISIMLER.size()]
	for i in 40:
		if not kullanilan.has(ad):
			break
		ad = ISIMLER[(ISIMLER.find(ad) + 1) % ISIMLER.size()]
	_sayac += 1
	return {"id": _sayac, "ad": ad, "yumruk": 20 + rng.randi() % 55, "bicak": 20 + rng.randi() % 55, "zeka": 20 + rng.randi() % 55, "gorev": "", "silah": ["bicak", "bicak", "tabanca"][rng.randi() % 3]}

func beceri(a: Dictionary) -> int:
	return int(round(0.5 * a["yumruk"] + 0.3 * a["bicak"] + 0.2 * a["zeka"]))

func adam_tut() -> Dictionary:
	if adamlar.size() >= EKIP_MAX:
		return hata("Ekip en fazla %d kişi olabilir." % EKIP_MAX)
	if not harcama(EKIP_FIYAT, "kirli"):
		return hata("Para yetmiyor ($%d)." % EKIP_FIYAT)
	var a := _yeni_adam()
	adamlar.append(a)
	kayit("Ekibe %s katıldı (%d adam). Ayda $%d." % [a["ad"], adamlar.size(), EKIP_MAAS], "info")
	degisti.emit()
	return tamam()

func adam_cikar(id: int) -> Dictionary:
	for i in adamlar.size():
		if adamlar[i]["id"] == id:
			if adamlar[i]["gorev"] != "":
				return hata("Görevdeki adam çıkarılamaz.")
			kayit("%s ekipten ayrıldı." % adamlar[i]["ad"], "info")
			adamlar.remove_at(i)
			degisti.emit()
			return tamam()
	return hata("Adam bulunamadı.")

func adam_bul(id: int) -> Dictionary:
	for a in adamlar:
		if a["id"] == id:
			return a
	return {}

# Çatışmadaki gücün: sen + boştaki adamlar (becerisine göre).
func guc() -> float:
	var p: float = ozet.get("guc_carpan", 1.0)
	for a in bos_adamlar():
		p += 1.0 + beceri(a) / 60.0
	return p

func yarala(a: Dictionary, gun: int) -> void:
	a["gorev"] = "tutuklu"
	gorevler.append({"adam": a["id"], "hedef": -1, "gorev": "tutuklu", "yarali": true, "basla": t, "yol": 0, "bitis": t + gun * DAY, "yolu": PackedVector3Array()})

# Silah ver: adam_id 0 = sen. Yeni silahın fiyatı kirli paradan düşer (eskisi geri satılmaz).
func silah_ver(adam_id: int, silah: String) -> Dictionary:
	var mevcut: String = oyuncu_silah if adam_id == 0 else adam_bul(adam_id).get("silah", "yumruk")
	if mevcut == silah:
		return hata("Zaten bu silahı taşıyor.")
	if not harcama(SILAH[silah]["fiyat"], "kirli"):
		return hata("Kirli para yetmiyor ($%d)." % SILAH[silah]["fiyat"])
	if adam_id == 0:
		oyuncu_silah = silah
	else:
		adam_bul(adam_id)["silah"] = silah
	kayit("%s artık %s taşıyor." % ["Sen" if adam_id == 0 else adam_bul(adam_id)["ad"], SILAH[silah]["ad"]], "info")
	degisti.emit()
	return tamam()

func bos_adamlar() -> Array:
	return adamlar.filter(func(a): return a["gorev"] == "")

func _adam_sec(gorev: String, id: int) -> Dictionary:
	if id > 0:
		var a := adam_bul(id)
		return a if not a.is_empty() and a["gorev"] == "" else {}
	var en := {}
	var en_p := -1e9
	for a in bos_adamlar():
		var p: float = beceri(a) - maxf(0.0, a["bicak"] - a["yumruk"] - 20.0) if gorev == "haraclan" else (a["yumruk"] if gorev == "koru" else a["zeka"])
		if p > en_p:
			en_p = p
			en = a
	return en

# ---------- iş yeri ----------
func haftalik(i: int) -> int:
	var y: Dictionary = harita.yerler[i]
	var tt: Dictionary = TURLER[isy[i]["tur"]]
	var b: Dictionary = bolge[y["bolge"]]
	return int(round(tt["gelir"] * (0.5 + 0.25 * b["servet"]) * (0.6 + 0.4 * b["huzur"] / 100.0)))

func kontrol(i: int) -> String:
	if not isy.has(i):
		return ""
	var r: Dictionary = isy[i]
	if r["sahip"]:
		return "sahip"
	if r["haracli"]:
		return "haraci"
	return hakim_of(harita.yerler[i]["bolge"])

func tur_ad(i: int) -> String:
	return TURLER[isy[i]["tur"]]["ad"] if isy.has(i) else ("Özel yer" if harita.yerler[i]["ozel"] else "Resmî kurum")

func fiyat(i: int) -> int:
	return TURLER[isy[i]["tur"]]["fiyat"]

func yol_dakika(i: int) -> Dictionary:
	var a: Vector3 = harita.yerler[_ev]["pos"] if _ev >= 0 else Vector3.ZERO
	var yol: PackedVector3Array = harita.yol_bul(a, harita.yerler[i]["pos"])
	var uz := 0.0
	for k in range(1, yol.size()):
		uz += yol[k - 1].distance_to(yol[k])
	return {"dk": maxi(5, int(round(uz / WALK))), "yol": yol}

func gorev_ver(i: int, gorev: String, adam_id: int = 0) -> Dictionary:
	if not isy.has(i):
		return hata("Bu yer iş yeri değil.")
	var r: Dictionary = isy[i]
	var y: Dictionary = harita.yerler[i]
	var G: Dictionary = GOREVLER[gorev]
	if not erisim(y["bolge"]):
		return hata("%s'da henüz ayağın yok: önce komşu bir bölgeye hakim ol." % harita.bolgeler[y["bolge"]]["ad"])
	var k := kontrol(i)
	if gorev == "haraclan" and (k == "haraci" or k == "sahip"):
		return hata("Bu yer zaten senin.")
	if gorev == "topla" and k != "haraci":
		return hata("Toplanacak haraç yok.")
	if gorev == "topla" and r["birikim"] < 1.0:
		return hata("Henüz biriken para yok.")
	if gorev == "koru" and k != "haraci" and k != "sahip":
		return hata("Önce haraç bağla ya da satın al.")
	for g in gorevler:
		if g["hedef"] == i:
			return hata("Bu yere zaten bir adam gidiyor.")
	var adam := _adam_sec(gorev, adam_id)
	if adam.is_empty():
		return hata("Boşta adam yok." if adamlar.size() > 0 else "Ekibinde adam yok. Önce adam tut.")
	var yd := yol_dakika(i)
	adam["gorev"] = gorev
	gorevler.append({"adam": adam["id"], "hedef": i, "gorev": gorev, "basla": t, "yol": yd["dk"], "bitis": t + yd["dk"] + G["is"], "yolu": yd["yol"]})
	kayit("%s %s'a gidiyor: %s (~%d dk)." % [adam["ad"], y["ad"], G["ad"].to_lower(), yd["dk"] + G["is"]], "info")
	degisti.emit()
	return tamam()

func gorev_gor_var(i: int) -> bool:
	for g in gorevler:
		if g["hedef"] == i:
			return true
	return false

# ---------- çalışma ----------
const VARDIYA_DK := 480

func ucret(i: int) -> int:
	var tur: Dictionary = TURLER[isy[i]["tur"]]
	return int(round((4.0 + tur["gelir"] * 0.25) * ozet.get("ucret_carpan", 1.0)))

func calis(i: int) -> Dictionary:
	if not isy.has(i) or isy[i]["sahip"]:
		return hata("Burada çalışamazsın.")
	if not vardiya.is_empty():
		return hata("Zaten çalışıyorsun.")
	vardiya = {"bina": i, "bitis": t + VARDIYA_DK, "ucret": ucret(i)}
	kayit("%s'te mesai başladı (8 saat, %s)." % [harita.yerler[i]["ad"], para(vardiya["ucret"])], "info")
	return tamam("Mesaiye başladın. 8 saat sonra ücretini alırsın.")

func mesai_birak() -> void:
	if vardiya.is_empty():
		return
	kayit("Mesaiyi yarıda bıraktın; ücret yok.", "warn")
	vardiya = {}

func satin_al(i: int) -> Dictionary:
	if not isy.has(i):
		return hata("Bu yer iş yeri değil.")
	var y: Dictionary = harita.yerler[i]
	var r: Dictionary = isy[i]
	if not erisim(y["bolge"]):
		return hata("Bu bölgede henüz ayağın yok.")
	if r["sahip"]:
		return hata("Zaten senin.")
	var f := fiyat(i)
	if not harcama(f, "temiz"):
		return hata("Temiz para yetmiyor (%s)." % para(f))
	r["sahip"] = true
	r["haracli"] = false
	r["birikim"] = 0.0
	isl.baslat(i)
	_nufuz(y["bolge"], 4.0)
	kayit("%s'ı satın aldın (%s). Haftalık meşru gelir akacak." % [y["ad"], para(f)], "good")
	degisti.emit()
	return tamam()

func _coz(g: Dictionary) -> void:
	var adam := adam_bul(g["adam"])
	var i: int = g["hedef"]
	if adam.is_empty() or not isy.has(i):
		return
	adam["gorev"] = ""
	if g["gorev"] == "haraclan" or g["gorev"] == "topla":
		arama = minf(100.0, arama + 4.0)
	var r: Dictionary = isy[i]
	var y: Dictionary = harita.yerler[i]
	var bid: String = y["bolge"]
	var b: Dictionary = bolge[bid]
	var ad: String = y["ad"]
	var T: Dictionary = TURLER[r["tur"]]
	if g["gorev"] == "haraclan":
		var hk := hakim_of(bid)
		var rakip := hk if hk != "" and hk != "oyuncu" else ""
		var need: int = T["direnc"] * 10
		var e := etki(b, bid)
		var pw := clampf(0.38 + (beceri(adam) - need) / 60.0 + 0.15 * e["k"] + 0.1 * e["s"] - (0.05 if b["huzur"] > 80 else 0.0), 0.08, 0.95)
		if rng.randf() < pw:
			r["haracli"] = true
			r["birikim"] = 0.0
			b["kor"] = clampf(b["kor"] + 1.5, 0, 100)
			b["sev"] = clampf(b["sev"] - 1.5, 0, 100)
			b["tan"] = clampf(b["tan"] + 1.5, 0, 100)
			_nufuz(bid, 3.0)
			var extra := ""
			if adam["bicak"] - adam["yumruk"] > 25 and rng.randf() < 0.3:
				extra = " %s bıçağı fazla kullandı; sahibi yaralandı." % adam["ad"]
				b["sev"] = clampf(b["sev"] - 5, 0, 100)
			if rakip != "":
				ofke[rakip] = minf(60.0, ofke[rakip] + 6.0)
			kayit("%s: %s haraç bağladı. Haftalık ~%s.%s" % [ad, adam["ad"], para(haftalik(i)), extra], "good")
		else:
			b["sev"] = clampf(b["sev"] - 1, 0, 100)
			if rng.randf() < 0.35:
				adam["gorev"] = "tutuklu"
				kayit("%s: %s esnafı ikna edemedi ve karakola götürüldü. Üç gün sonra çıkar." % [ad, adam["ad"]], "bad")
				gorevler.append({"adam": adam["id"], "hedef": i, "gorev": "tutuklu", "basla": t, "yol": 0, "bitis": t + 3 * DAY, "yolu": PackedVector3Array()})
			else:
				kayit("%s: %s sahibi ikna edemedi. Daha becerikli bir adam gönder (beceri %d < direnç %d)." % [ad, adam["ad"], beceri(adam), need], "warn")
	elif g["gorev"] == "topla":
		if not r["haracli"]:
			kayit("%s: haraç artık sende değil." % ad, "warn")
			return
		var direnir := rng.randf() < clampf(0.25 - 0.3 * etki(b, bid)["k"] - 0.001 * adam["yumruk"], 0.02, 0.4)
		var al := int(round(r["birikim"] * (0.5 if direnir else 1.0)))
		r["birikim"] = 0.0
		kirli += al
		kayit("%s: %s %s topladı%s." % [ad, adam["ad"], para(al), " (sahibi yarısını ödedi)" if direnir else ""], "warn" if direnir else "good")
	elif g["gorev"] == "koru":
		r["korumaBitis"] = t + 7 * DAY
		b["sev"] = clampf(b["sev"] + 1, 0, 100)
		kayit("%s: %s bir hafta boyunca kapıda nöbet tutacak." % [ad, adam["ad"]], "info")

# ---------- bölge işleri ----------
func bolge_is(id: String, tur: String) -> Dictionary:
	var b: Dictionary = bolge[id]
	if not erisim(id):
		return hata("%s'a girmek için önce komşu bir bölgeye hakim olmalısın." % harita.bolgeler[id]["ad"])
	var gun: int = tarih()["gun"]
	if b["sonIs"].get(tur, -99) + BEKLEME[tur] > gun:
		return hata("Bu işi bu bölgede %d günde bir yapabilirsin." % BEKLEME[tur])
	var onceki := hakim_of(id)
	var kayip: float = 1.0 - b["inf"].get("oyuncu", 0.0) / 120.0
	var rakip := onceki if onceki != "" and onceki != "oyuncu" else ""
	var direnc: float = (1.0 - b["inf"].get(rakip, 0.0) / 150.0 if rakip != "" else 1.0) * (0.6 + 0.6 * b["tan"] / 100.0)
	var e := etki(b, id)
	var kazan := 0.0
	var ad: String = harita.bolgeler[id]["ad"]
	if tur == "himaye":
		if not harcama(120, "kirli"):
			return hata("Para yetmiyor ($120).")
		kazan = 7.0 * kayip * direnc * (0.7 + 0.5 * e["s"] + 0.2 * e["k"])
		b["sev"] = clampf(b["sev"] + 2, 0, 100)
		b["kor"] = clampf(b["kor"] + 2, 0, 100)
		kayit("%s: esnafa \"himaye\" sattın (nüfuz +%.1f)." % [ad, kazan], "info")
	elif tur == "hediye":
		if not harcama(200, "temiz"):
			return hata("Temiz para yetmiyor ($200).")
		kazan = 4.0 * kayip * direnc * (0.6 + 0.7 * e["s"])
		b["sev"] = clampf(b["sev"] + 8.0 * (1.0 - b["sev"] / 120.0), 0, 100)
		b["kor"] = clampf(b["kor"] - 2, 0, 100)
		b["huzur"] = clampf(b["huzur"] + 8, 0, 100)
		kayit("%s: mahalleye ziyafet verdin (nüfuz +%.1f, huzur +8)." % [ad, kazan], "good")
	else:
		if adamlar.is_empty():
			return hata("Bu iş için ekibinde en az bir adam olmalı.")
		if not harcama(150, "kirli"):
			return hata("Para yetmiyor ($150).")
		kazan = 11.0 * kayip * direnc * (0.7 + 0.6 * e["k"] + 0.2 * e["s"])
		b["kor"] = clampf(b["kor"] + 10.0 * (1.0 - b["kor"] / 120.0), 0, 100)
		b["sev"] = clampf(b["sev"] - 6, 0, 100)
		b["huzur"] = clampf(b["huzur"] - 8, 0, 100)
		if rakip != "":
			ofke[rakip] = minf(60.0, ofke[rakip] + 20.0)
		kayit("%s: %s sindirdin (nüfuz +%.1f, huzur −8)." % [ad, (hakim_ad(rakip) + " adamlarını") if rakip != "" else "sokak çetelerini", kazan], "warn")
	add_inf(b, "oyuncu", kazan)
	b["tan"] = clampf(b["tan"] + {"himaye": 3, "hediye": 4, "gozdagi": 6}[tur] * (1.0 - b["tan"] / 120.0), 0, 100)
	b["sonIs"][tur] = gun
	_hakim_degisti(id, onceki)
	degisti.emit()
	return tamam()

func bolge_yatirim(id: String) -> Dictionary:
	var b: Dictionary = bolge[id]
	if hakim_of(id) != "oyuncu":
		return hata("Yalnızca hakim olduğun bölgeye yatırım yaparsın.")
	var ay: int = tarih()["ay"]
	if b["yatirimAy"] == ay:
		return hata("Bu bölgeye bu ay zaten yatırım yaptın.")
	if b["servet"] >= SERVET_MAX and b["ilerleme"] >= 99:
		return hata("Bölge zaten en büyük hâlinde.")
	if not harcama(400, "temiz"):
		return hata("Temiz para yetmiyor ($400).")
	b["yatirimAy"] = ay
	_ilerlet(id, 35.0)
	add_inf(b, "oyuncu", 2.0 * (1.0 - b["inf"].get("oyuncu", 0.0) / 120.0))
	kayit("%s'a yatırım yaptın." % harita.bolgeler[id]["ad"], "good")
	degisti.emit()
	return tamam()

func bolge_harac(id: String, v: int) -> Dictionary:
	if hakim_of(id) != "oyuncu":
		return hata("Yalnızca hakim olduğun bölgeden haraç toplarsın.")
	bolge[id]["harac"] = clampi(v, 0, HARAC.size() - 1)
	degisti.emit()
	return tamam()

func _ilerlet(id: String, miktar: float) -> void:
	var b: Dictionary = bolge[id]
	var ad: String = harita.bolgeler[id]["ad"]
	b["ilerleme"] += miktar
	while b["ilerleme"] >= 100.0 and b["servet"] < SERVET_MAX:
		b["ilerleme"] -= 100.0
		b["servet"] += 1
		kayit("%s büyüdü (%s)." % [ad, "★".repeat(b["servet"])], "good" if hakim_of(id) == "oyuncu" else "info")
	if b["servet"] >= SERVET_MAX:
		b["ilerleme"] = minf(b["ilerleme"], 99.0)
	while b["ilerleme"] < 0.0 and b["servet"] > 1:
		b["ilerleme"] += 100.0
		b["servet"] -= 1
		kayit("%s küçüldü (%s)." % [ad, "★".repeat(b["servet"])], "bad" if hakim_of(id) == "oyuncu" else "info")
	if b["servet"] <= 1:
		b["ilerleme"] = maxf(b["ilerleme"], 0.0)

# ---------- zaman ----------
# Gerçek zamanlı akış: sokak.gd her karede çağırır (delta oyun hızıyla zaten ölçeklenmiş).
func ilerle(delta: float) -> void:
	_kesir += delta * DK_SN
	var n := int(_kesir)
	if n <= 0:
		return
	_kesir -= n
	for k in n:
		t += 1
		if t % 60 == 0:
			_saat()
		if t % DAY == 0:
			_gun()
			if (t / DAY) % DAYS_PER_MONTH == 0:
				_ay()
	degisti.emit()

func _saat() -> void:
	arama = maxf(0.0, arama - 0.5)
	if not vardiya.is_empty() and t >= vardiya["bitis"]:
		temiz += vardiya["ucret"]
		kayit("Vardiya bitti: %s kazandın (%s)." % [para(vardiya["ucret"]), harita.yerler[vardiya["bina"]]["ad"]], "good")
		vardiya = {}
	for g in gorevler.duplicate():
		if t >= g["bitis"]:
			gorevler.erase(g)
			if g["gorev"] == "tutuklu":
				var a := adam_bul(g["adam"])
				if not a.is_empty():
					a["gorev"] = ""
					kayit(("%s iyileşti." if g.get("yarali", false) else "%s karakoldan çıktı.") % a["ad"], "info")
			else:
				_coz(g)

# ---------- kayıt / yükleme ----------
func durum_al() -> Dictionary:
	return {"t": t, "temiz": temiz, "kirli": kirli, "bolge": bolge, "ofke": ofke, "adamlar": adamlar, "gorevler": gorevler,
		"isy": isy, "arama": arama, "oyuncu_silah": oyuncu_silah, "defter": defter, "sayac": _sayac, "uyeler": uyeler, "uid": _uid, "pid": _pid, "ziyaret": ziyaret, "gozlem": gozlem, "muhbir": muhbir, "ajan_sogutma": ajan_sogutma, "profil": profil, "vardiya": vardiya, "kira_borc": kira_borc, "ev": _ev, "zf": zf, "son": son, "arac": arac, "mes": mes, "borc": borc, "akl": akl}

func durum_yukle(d: Dictionary) -> void:
	t = d["t"]
	temiz = d["temiz"]
	kirli = d["kirli"]
	bolge = d["bolge"]
	ofke = d["ofke"]
	adamlar.assign(d["adamlar"])
	gorevler.assign(d["gorevler"])
	isy = d["isy"]
	arama = d["arama"]
	oyuncu_silah = d.get("oyuncu_silah", "tabanca")
	defter.assign(d["defter"])
	_sayac = d["sayac"]
	if d.has("uyeler"):
		uyeler = d["uyeler"]
		_uid = d["uid"]
	_pid = d.get("pid", 0)
	ziyaret = d.get("ziyaret", {})
	gozlem = d.get("gozlem", {})
	muhbir = d.get("muhbir", muhbir)
	ajan_sogutma = d.get("ajan_sogutma", {})
	if d.has("profil"):
		profil = d["profil"]
		ozet = load("res://scripts/core/profil.gd").ozet(profil)
	vardiya = d.get("vardiya", {})
	kira_borc = d.get("kira_borc", 0.0)
	_ev = d.get("ev", _ev)
	zf = d.get("zf", {"kampanya": 0.0, "durust_ay": 0, "hakim_ay": 0})
	son = d.get("son", {})
	arac = d.get("arac", {"tip": "", "yakit": 0.0, "kullan": false, "ariza": 0, "yol": 0.0})
	mes = d.get("mes", meslek.yeni())
	borc = d.get("borc", borc_k.yeni())
	akl = d.get("akl", aklama_k.yeni())
	degisti.emit()

# ---------- günlük rastgele olaylar ----------
func _olay() -> void:
	if rng.randf() > 0.3:
		return
	var harackilar: Array = isy.keys().filter(func(i): return isy[i]["haracli"])
	var idler: Array = harita.bolgeler.keys()
	var bid: String = idler[rng.randi() % idler.size()]
	var bad: String = harita.bolgeler[bid]["ad"]
	var b: Dictionary = bolge[bid]
	match rng.randi() % 6:
		0:
			if harackilar.is_empty():
				return
			var i: int = harackilar[rng.randi() % harackilar.size()]
			isy[i]["birikim"] = 0.0
			arama = minf(100.0, arama + 6.0)
			kayit("Polis %s'a baskın yaptı: biriken haraç el konuldu, arama arttı." % harita.yerler[i]["ad"], "bad")
		1:
			if harackilar.is_empty():
				return
			arama = minf(100.0, arama + 8.0)
			kayit("Biri polise seni ihbar etti. Arama arttı.", "bad")
		2:
			if harackilar.is_empty():
				return
			var i2: int = harackilar[rng.randi() % harackilar.size()]
			var m := 30 + rng.randi() % 51
			kirli += m
			kayit("%s sahibi minnet duydu, $%d kirli bahşiş bıraktı." % [harita.yerler[i2]["ad"], m], "good")
		3:
			var f: String = NPC[rng.randi() % NPC.size()]
			add_inf(b, f, 2.0)
			kayit("%s'da %s adamları görünür oldu (nüfuz arttı)." % [bad, FAK[f]["ad"]], "warn")
		4:
			b["huzur"] = maxf(0.0, b["huzur"] - 5.0)
			kayit("%s'da hırsızlık dalgası: huzur düştü." % bad, "warn")
		5:
			b["huzur"] = minf(100.0, b["huzur"] + 5.0)
			b["sev"] = minf(100.0, b["sev"] + 2.0)
			kayit("%s'da mahalle şenliği: huzur ve sevgi arttı." % bad, "good")

# Yasal (vergiye tabi, aklamaya esas) temiz gelir
func yasal(x: float) -> void:
	temiz += x
	akl["yasal"] += x

func _gun() -> void:
	_olay()
	meslek.gun()
	isl.gunluk()
	for i in isy:
		var r: Dictionary = isy[i]
		var w := haftalik(i)
		if r["sahip"]:
			yasal(w * 1.5 / 7.0 * isl.carpan(i))
			continue
		if not r["haracli"]:
			continue
		r["birikim"] = minf(w * 3.0, r["birikim"] + w / 7.0)
		var bid: String = harita.yerler[i]["bolge"]
		var hk := hakim_of(bid)
		if hk != "" and hk != "oyuncu" and t >= r["korumaBitis"] and rng.randf() < 0.012:
			r["haracli"] = false
			r["birikim"] = 0.0
			kayit("%s: %s adamları esnafı geri aldı; haracı artık onlara ödüyor." % [harita.yerler[i]["ad"], hakim_ad(hk)], "bad")
	if profil.get("koken", "yerli") == "yerli":
		yasal(40.0 + rng.randf() * 20.0)   # Murphy's Tavern günlük geliri (şimdilik sabit; meyhane sistemi sonra)

func _ay() -> void:
	isl.ay()
	meslek.ay()
	aklama_k.ay()
	borc_k.ay()
	var kira: float = ozet.get("kira", 0)
	if kira > 0.0:
		var borc := kira + kira_borc
		if temiz >= borc:
			temiz -= borc
			kira_borc = 0.0
			kayit("Oda kirası ödendi: %s." % para(borc), "info")
		else:
			kira_borc = borc
			kayit("Kirayı ödeyemedin (borç %s). Ev sahibi sabırsızlanıyor." % para(borc), "bad")
	if profil.get("koken", "") == "aile":
		kirli += 80.0
		kayit("%s'dan aylık pay: %s kirli." % [load("res://scripts/core/profil.gd").AILELER[profil["aile"]]["ad"], para(80.0)], "good")
	var onceki := {}
	for id in bolge:
		onceki[id] = hakim_of(id)
	var harac_toplam := 0.0
	var maas := 0.0
	for id in bolge:
		var b: Dictionary = bolge[id]
		if b["garnizon"] > 0:
			maas += b["garnizon"] * 40.0
		if hakim_of(id) == "oyuncu":
			var tt: Array = HARAC[b["harac"]]
			var ee := etki(b, id)
			var gelir := int(round(HAVUZ * b["servet"] * tt[1] * (0.6 + 0.4 * b["huzur"] / 100.0) * clampf(0.7 + 0.25 * ee["s"] + 0.25 * ee["k"], 0.5, 1.3)))
			var hd: Array = [[3, -2], [0, 1], [-2, 2], [-5, 4]][b["harac"]]
			b["sev"] = clampf(b["sev"] + hd[0], 0, 100)
			b["kor"] = clampf(b["kor"] + hd[1], 0, 100)
			if gelir > 0:
				kirli += gelir
				harac_toplam += gelir
	if adamlar.size() > 0:
		var gider := adamlar.size() * EKIP_MAAS
		if harcama(gider, "kirli"):
			maas += gider
		else:
			var son: Dictionary = adamlar[adamlar.size() - 1]
			if son["gorev"] == "":
				adamlar.pop_back()
				kayit("Ekibin maaşını ödeyemedin, %s çekip gitti." % son["ad"], "bad")
	for id in bolge:
		var b: Dictionary = bolge[id]
		b["sev"] += (30.0 - b["sev"]) * 0.04
		b["kor"] *= 0.95
		if hakim_of(id) == "oyuncu":
			b["tan"] = clampf(b["tan"] + 1.5, 0, 100)
		else:
			b["tan"] = maxf(30.0 if id == "southside" else 0.0, b["tan"] * 0.94)
	if harac_toplam > 0.0 or maas > 0.0:
		kayit("AYLIK: haraç %s · maaşlar %s." % [para(harac_toplam), para(maas)], "info")
	for id in bolge:
		var b: Dictionary = bolge[id]
		var hk := hakim_of(id)
		var ik := 0.0
		for f in b["inf"]:
			if f != hk:
				ik = maxf(ik, b["inf"][f])
		var ceza: float = [-4.0, 0.0, 5.0, 12.0][b["harac"]] if hk == "oyuncu" else 0.0
		var rakip_ceza := (ik - 20.0) * 0.8 if ik > 20.0 else 0.0
		var hedef := clampf(65.0 + (b["sev"] - 40.0) / 8.0 + 4.0 * minf(b["garnizon"], GARNIZON_MAX) - rakip_ceza - ceza, 0.0, 100.0)
		b["huzur"] = clampf(b["huzur"] + (hedef - b["huzur"]) * 0.35, 0, 100)
		var g: float = -8.0 if b["huzur"] < 30.0 else 4.5 + (b["huzur"] - 50.0) / 10.0 + (rng.randf() - 0.5) * 5.0
		if hk == "oyuncu" and b["harac"] == 3:
			g -= 3.0
		_ilerlet(id, g)
	for f in NPC:
		var ofke_c: float = 1.0 + ofke[f] / 30.0
		var k := kudret(f)
		for id in bolge:
			if hakim_of(id) == f:
				add_inf(bolge[id], f, 1.2)
		var adaylar := []
		for id in bolge:
			if hakim_of(id) == f:
				continue
			var var_komsu := false
			for n in KOMSU[id]:
				if hakim_of(n) == f:
					var_komsu = true
			if not var_komsu:
				continue
			var b: Dictionary = bolge[id]
			var hk := hakim_of(id)
			var w: float = (1.0 / (1.0 + (b["inf"].get(hk, 0.0) / 30.0 if hk != "" else 0.0))) * (0.7 + b["servet"] * 0.15)
			if hk == "oyuncu":
				w *= ofke_c
			adaylar.append([id, w])
		if adaylar.is_empty():
			continue
		var p: float = clampf(0.1 + 0.012 * k, 0.0, 0.5) * FAK[f]["saldirgan"] * ofke_c
		if rng.randf() >= p:
			continue
		var top := 0.0
		for a in adaylar:
			top += a[1]
		var r := rng.randf() * top
		var hedef_id: String = adaylar[0][0]
		for a in adaylar:
			r -= a[1]
			if r <= 0.0:
				hedef_id = a[0]
				break
		var b: Dictionary = bolge[hedef_id]
		var hk := hakim_of(hedef_id)
		var kazan := 4.0 + rng.randf() * 5.0 + k / 6.0
		if hk == "oyuncu" or b["inf"].get("oyuncu", 0.0) > 0.0:
			kazan = maxf(1.5, kazan - 1.8 * b["garnizon"] - 1.0)
		add_inf(b, f, kazan)
		b["huzur"] = clampf(b["huzur"] - 5, 0, 100)
		var hed_ad: String = harita.bolgeler[hedef_id]["ad"]
		if hk != "":
			kayit("%s, %s'in %s'daki hâkimiyetini zorluyor." % [hakim_ad(f), hakim_ad(hk), hed_ad], "warn" if hk == "oyuncu" else "info")
		else:
			kayit("%s sahipsiz %s'a el attı." % [hakim_ad(f), hed_ad], "info")
	for f in NPC:
		ofke[f] *= 0.8
	for id in bolge:
		_hakim_degisti(id, onceki[id])
	zafer.ay()
	arac_k.ay()
