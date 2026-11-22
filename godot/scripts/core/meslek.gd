extends RefCounted
# Meslekler (web prototipindeki meslek.js): düz bir işe gir, öğren, sonra işletmesini al.
# Tanınırlık ve korku işe kabulü etkiler; bazı işler korkuyu sever, bazıları yüzünü saklamanı ister.

const MESLEKLER := {
	"taksi": {"ad": "Taksi şoförü", "isletme": "Taksi filosu", "maas": 27, "fiyat": 1800, "ciro": 0.07,
		"sevW": 0.6, "korW": 0.0, "tanC": 0.55, "taban": 60,
		"ac": "Şehrin sokaklarını ezbere öğrenirsin. Tecrübeyle yürüyüş hızın artar. Korkulan ve adı kötüye çıkmış şoförü kimse çağırmaz.",
		"perk": "Yürüyüş hızı (en çok +%40)"},
	"hamal": {"ad": "Liman hamalı", "isletme": "Nakliye şirketi", "maas": 24, "fiyat": 1600, "ciro": 0.07,
		"sevW": 0.1, "korW": 0.8, "tanC": 0.1, "taban": 62,
		"ac": "Sendika adamlarıyla omuz omuza çalışırsın. Korkulan adam rahat iş bulur. Tecrübeyle yolda pusuya düşmen zorlaşır.",
		"perk": "Pusu riski (en çok −%25)"},
	"berber": {"ad": "Berber çırağı", "isletme": "Berber salonu", "maas": 21, "fiyat": 1200, "ciro": 0.08,
		"sevW": 0.9, "korW": -0.3, "tanC": 0.2, "taban": 60,
		"ac": "Mahallenin dedikodusu koltuğundan akar. Sevilen adam burada tutunur. Tecrübeyle halkın sevgisi artar.",
		"perk": "Halk sevgisi (ayda +3)"},
	"katip": {"ad": "Defter katibi", "isletme": "Muhasebe bürosu", "maas": 30, "fiyat": 2000, "ciro": 0.06,
		"sevW": 0.3, "korW": -0.2, "tanC": 0.6, "taban": 62,
		"ac": "Rakamlarla uğraşırsın. Temiz isim ister. Tecrübeyle aklama ücreti düşer, kapasite büyür.",
		"perk": "Aklama (−%30 ücret, +%40 kapasite)"},
}
const BECERI_AD := ["Çaylak", "Tecrübeli", "Usta", "Üstat"]

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"is": {}, "beceri": {"taksi": 0.0, "hamal": 0.0, "berber": 0.0, "katip": 0.0}, "isletme": {}}

static func seviye(xp: float) -> int:
	return 3 if xp >= 75.0 else 2 if xp >= 50.0 else 1 if xp >= 25.0 else 0

# İşe kabul puanı (≥ eşik ise alınırsın)
func kabul(j: String, bid: String) -> Dictionary:
	var m: Dictionary = MESLEKLER[j]
	var b: Dictionary = oyun.bolge[bid]
	var e: Dictionary = oyun.etki(b, bid)
	var kotu: float = b["tan"] * (0.2 + 0.8 * b["kor"] / 100.0) + 0.3 * oyun.arama
	var iyi: float = 12.0 * (b["tan"] / 100.0) * (b["sev"] / 100.0)
	var referans := 4.0 if b["tan"] < 10.0 else 0.0
	var puan: float = m["taban"] + 0.3 * oyun.mes["beceri"][j] + 35.0 * e["s"] * m["sevW"] + 30.0 * e["k"] * m["korW"] - m["tanC"] * kotu + iyi - referans
	puan -= maxf(0.0, oyun.yol_k.kotu() - 25.0) * 0.8   # sicili kirli olana iş vermezler
	return {"puan": int(round(puan)), "esik": 50, "ok": puan >= 50.0}

func tecrube(j: String) -> float:
	return oyun.mes["beceri"][j] / 100.0

# Becerinin etkisi: işletmesi senin ise tam, değilse çeyreği.
func etki_guc(j: String) -> float:
	return tecrube(j) * (1.0 if oyun.mes["isletme"].has(j) else 0.25)

func maas_gun(j: String, bid: String) -> float:
	var m: Dictionary = MESLEKLER[j]
	var b: Dictionary = oyun.bolge[bid]
	return round(m["maas"] * (0.7 + 0.8 * tecrube(j)) * (0.8 + 0.08 * b["servet"]) * 10.0) / 10.0

func isletme_gelir(j: String) -> int:
	var m: Dictionary = MESLEKLER[j]
	return int(round(m["fiyat"] * m["ciro"] * (0.6 + 0.8 * tecrube(j))))

# --- diğer sistemlere kancalar ---
func yurume_carpan() -> float:
	return 1.0 + 0.4 * etki_guc("taksi")

func pusu_carpan() -> float:
	return 1.0 - 0.25 * etki_guc("hamal")

func aklama_ucret(ucret: float) -> float:
	return ucret * (1.0 - 0.3 * etki_guc("katip"))

func aklama_kapasite() -> float:
	return 1.0 + 0.4 * etki_guc("katip")

func calisiyor() -> bool:
	return not oyun.mes["is"].is_empty()

# --- dönemsel gerçekçilik ---
const TUR_MESLEK := {"esnaf": "berber", "eglence": "taksi", "luks": "katip", "atolye": "hamal", "depo": "hamal", "konut": "katip"}
const MEVSIM_CARPAN := {
	"taksi": [1.0, 1.15, 1.0, 0.9], "hamal": [1.0, 0.95, 1.1, 1.15],
	"berber": [1.05, 1.0, 0.95, 0.9], "katip": [1.0, 0.9, 1.1, 1.15]}   # ilkbahar, yaz, sonbahar, kış
const TATILLER := [[1, 1, "Yılbaşı"], [10, 1, "Hasat Bayramı"]]   # ay_yil, ay_gun

func pazar_mi() -> bool:
	return (oyun.tarih()["gun"] % 7) == 6

func tatil_adi() -> String:
	var d: Dictionary = oyun.tarih()
	for h in TATILLER:
		if d["ay_yil"] == h[0] and d["ay_gun"] == h[1]:
			return h[2]
	if pazar_mi():
		return "Pazar"
	return ""

# Ekonomi dalgası: kriz / refah, ±%12
func ekonomi() -> float:
	return 1.0 + 0.12 * sin(float(oyun.tarih()["ay"]) * 0.52)

func donem_carpan(j: String) -> float:
	var ms: int = (int(oyun.tarih()["ay"]) % 12) / 3
	return MEVSIM_CARPAN[j][ms] * ekonomi()

func donem_yazi() -> String:
	var e := ekonomi()
	return "%s · %s" % [oyun.mevsim(), "ekonomi canlı" if e > 1.06 else "ekonomi durgun" if e < 0.94 else "ekonomi normal"]

# --- gazete ilanları: her gün değişir ---
var _ilan_gun := -1
var _ilan: Array = []

func ilanlar() -> Array:
	var g: int = oyun.tarih()["gun"]
	if g == _ilan_gun:
		return _ilan
	_ilan_gun = g
	_ilan = []
	var rng := RandomNumberGenerator.new()
	rng.seed = g * 7919 + 13
	var adaylar: Array = []
	for i in oyun.isy:
		var r: Dictionary = oyun.isy[i]
		if r["sahip"] or not TUR_MESLEK.has(r["tur"]):
			continue
		adaylar.append(i)
	adaylar.sort()
	for n in 6:
		if adaylar.is_empty():
			break
		var i: int = adaylar[rng.randi() % adaylar.size()]
		adaylar.erase(i)
		var j: String = TUR_MESLEK[oyun.isy[i]["tur"]]
		_ilan.append({"j": j, "bina": i, "bolge": oyun.harita.yerler[i]["bolge"], "carpan": snappedf(rng.randf_range(0.85, 1.3), 0.05)})
	return _ilan

# --- eylemler ---
func is_gir(j: String, bid: String, bina: int = -1, carpan: float = 1.0) -> Dictionary:
	var M: Dictionary = oyun.mes
	if not MESLEKLER.has(j):
		return oyun.hata("Böyle bir meslek yok.")
	if not oyun.bolge.has(bid):
		return oyun.hata("Bu mahallede iş yok.")
	if not M["is"].is_empty():
		return oyun.hata("Zaten bir işte çalışıyorsun. Önce ayrıl.")
	var k := kabul(j, bid)
	if not k["ok"]:
		var b: Dictionary = oyun.bolge[bid]
		var neden := "Mahalle senden korkuyor; kimse başına iş açmak istemiyor." if b["tan"] > 30.0 and b["kor"] > 35.0 else "Mahalle sana güvenmiyor."
		return oyun.hata("%s olarak seni almadılar (puan %d/%d). %s" % [MESLEKLER[j]["ad"], k["puan"], k["esik"], neden])
	var gn: int = oyun.tarih()["gun"]
	M["is"] = {"j": j, "b": bid, "gun": 0, "bina": bina, "carpan": carpan, "son": gn}
	var yer := " (%s)" % oyun.harita.yerler[bina]["ad"] if bina >= 0 else ""
	oyun.kayit("%s olarak işe girdin%s. Her gün iş yerine gidip mesai yapmalısın; ücret mesai bitince orada ödenir (~%s/mesai)." % [MESLEKLER[j]["ad"], yer, oyun.para(mesai_ucret())], "good")
	return oyun.tamam()

func mesai_ucret() -> int:
	var I: Dictionary = oyun.mes["is"]
	if I.is_empty():
		return 0
	return int(round(maas_gun(I["j"], I["b"]) * I.get("carpan", 1.0) * donem_carpan(I["j"])))

# İş yerinde mesaiyi başlat (arayüz yakınlığı denetler)
func mesai_baslat(i: int) -> Dictionary:
	var I: Dictionary = oyun.mes["is"]
	if I.is_empty() or I.get("bina", -1) != i:
		return oyun.hata("Burası senin iş yerin değil.")
	if not oyun.vardiya.is_empty():
		return oyun.hata("Zaten çalışıyorsun.")
	var th := tatil_adi()
	if th != "":
		return oyun.hata("Bugün %s: iş yeri kapalı." % th)
	var sa: int = oyun.tarih()["saat"]
	if sa < 7 or sa > 16:
		return oyun.hata("Mesai 07:00–16:00 arası başlar.")
	oyun.vardiya = {"bina": i, "bitis": oyun.t + oyun.VARDIYA_DK, "ucret": mesai_ucret(), "meslek": true}
	oyun.kayit("%s mesaisi başladı (8 saat, %s)." % [MESLEKLER[I["j"]]["ad"], oyun.para(oyun.vardiya["ucret"])], "info")
	return oyun.tamam("Mesaiye başladın. Ücret bitince burada ödenir.")

# Mesai bitti: ücret ödenmiş olur; beceri ve yorgunluk güncellenir
func mesai_bitti() -> void:
	var M: Dictionary = oyun.mes
	if M["is"].is_empty():
		return
	var j: String = M["is"]["j"]
	var m: Dictionary = MESLEKLER[j]
	M["is"]["son"] = oyun.tarih()["gun"]
	M["is"]["gun"] += 1
	oyun.kis_k.oz_ekle({"taksi": "taksici_dostu", "hamal": "dayanikli", "berber": "mahalleli", "katip": "hesapci"}[j], 1.2)
	oyun.kis_k.degis("yorgun", 6.0)
	oyun.yet_k.meslek(j)
	var xp: float = M["beceri"][j]
	M["beceri"][j] = minf(100.0, xp + 1.2 * (1.0 - xp / 115.0))
	if seviye(M["beceri"][j]) > seviye(xp):
		oyun.kayit("%s işinde \"%s\" oldun." % [m["ad"], BECERI_AD[seviye(M["beceri"][j])]], "good")

func is_birak() -> Dictionary:
	if not calisiyor():
		return oyun.hata("Zaten işsizsin.")
	oyun.kayit("%s işinden ayrıldın." % MESLEKLER[oyun.mes["is"]["j"]]["ad"], "info")
	oyun.mes["is"] = {}
	return oyun.tamam()

func isletme_al(j: String) -> Dictionary:
	var M: Dictionary = oyun.mes
	if not MESLEKLER.has(j):
		return oyun.hata("Böyle bir meslek yok.")
	var m: Dictionary = MESLEKLER[j]
	if M["isletme"].has(j):
		return oyun.hata("Bu işletme zaten senin.")
	if M["beceri"][j] < 20.0:
		return oyun.hata("%s almak için bu işte en az \"Tecrübeli\" olmalısın (beceri 20)." % m["isletme"])
	if not oyun.harcama(float(m["fiyat"]), "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(m["fiyat"]))
	M["isletme"][j] = {"t": oyun.t}
	oyun.kayit("%s satın aldın (%s). Gelir her ay doğrudan kasana girer; tecrüben (%%%d) ve mevsim belirler." % [m["isletme"], oyun.para(m["fiyat"]), int(M["beceri"][j])], "good")
	return oyun.tamam()

# --- zaman ---
func gun() -> void:
	var M: Dictionary = oyun.mes
	if M["is"].is_empty():
		return
	var j: String = M["is"]["j"]
	var bid: String = M["is"]["b"]
	var m: Dictionary = MESLEKLER[j]
	var b: Dictionary = oyun.bolge[bid]
	var k := kabul(j, bid)
	if k["puan"] < 35:
		oyun.kayit("%s işinden kovuldun: %s (puan %d)." % [m["ad"], "mahalle senden korkuyor" if b["tan"] > 30.0 and b["kor"] > 35.0 else "mahalle sana sırt çevirdi", k["puan"]], "bad")
		M["is"] = {}
		return
	var yok: int = oyun.tarih()["gun"] - int(M["is"].get("son", 0))
	if yok == 4:
		oyun.kayit("%s patronu: \"4 gündür ortada yoksun. Yarın gelmezsen işin biter.\"" % m["ad"], "warn")
	elif yok >= 5:
		oyun.kayit("%s işinden devamsızlıktan kovuldun." % m["ad"], "bad")
		M["is"] = {}

func ay() -> void:
	var M: Dictionary = oyun.mes
	var top := 0
	var adlar: Array = []
	for j in M["isletme"]:
		var g := int(round(isletme_gelir(j) * donem_carpan(j)))
		oyun.yasal(g)
		top += g
		adlar.append(MESLEKLER[j]["isletme"])
		if j == "berber":
			for id in oyun.bolge:
				var b: Dictionary = oyun.bolge[id]
				b["sev"] = clampf(b["sev"] + 3.0 * tecrube("berber") * (1.0 if oyun.hakim_of(id) == "oyuncu" else 0.4), 0.0, 100.0)
	if top > 0:
		oyun.kayit("İŞLETMELER: %s · temiz gelir %s." % [", ".join(adlar), oyun.para(top)], "good")
	# çalışmayan ve işletmesi olmayan beceri çok yavaş körelir
	var cj: String = M["is"].get("j", "")
	for j in M["beceri"]:
		if j != cj and not M["isletme"].has(j):
			M["beceri"][j] = maxf(0.0, M["beceri"][j] - 0.3)
