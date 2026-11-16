extends RefCounted
# Araba (web prototipindeki arac.js): yürümekten hızlı ama araç, yakıt ve bakım ister.
# "Kolaylık": ekip, para ve bölgeler büyüdükçe yakıt/bakım/arıza derdi azalır.

const ARACLAR := {
	"ford": {"ad": "Ford Model T", "fiyat": 600, "hiz": 2.0, "tank": 30.0, "tuk": 0.9, "bakim": 30, "guv": 1.0, "pusu": 0.9,
		"ac": "Ucuz ve dayanıklı ama yavaş. Arızaya yatkın."},
	"buick": {"ad": "Buick Master Six", "fiyat": 1800, "hiz": 2.6, "tank": 45.0, "tuk": 1.1, "bakim": 70, "guv": 0.6, "pusu": 0.8,
		"ac": "Hızlı, rahat. Pusuya karşı biraz daha korunaklı."},
	"packard": {"ad": "Packard Twin Six", "fiyat": 4200, "hiz": 3.2, "tank": 60.0, "tuk": 1.5, "bakim": 140, "guv": 0.35, "pusu": 0.65,
		"ac": "Şehrin en gösterişli arabası: çok hızlı, sağlam, pusuya zor yakalanır."},
}
const YAKIT_FIYAT := 1.8
const PX_M := 0.8        # web'deki 1 birim ≈ 0,8 m (yakıt/arıza hesabı metreye çevrilir)

var oyun: Node
var rng := RandomNumberGenerator.new()

func _init(o: Node) -> void:
	oyun = o
	rng.seed = 7351

static func yeni() -> Dictionary:
	return {"tip": "", "yakit": 0.0, "kullan": false, "ariza": 0, "yol": 0.0}

func kolaylik() -> float:
	var ek := minf(1.0, oyun.adamlar.size() / 8.0)
	var pa := minf(1.0, (oyun.temiz + oyun.kirli) / 15000.0)
	var bo := minf(1.0, oyun.oyuncu_bolgeleri().size() / 4.0)
	return clampf(0.4 * ek + 0.3 * pa + 0.3 * bo, 0.0, 1.0)

func yakit_fiyat() -> float:
	return YAKIT_FIYAT * (1.0 - 0.6 * kolaylik())

func bakim_gider() -> int:
	var a: Dictionary = oyun.arac
	return int(round(ARACLAR[a["tip"]]["bakim"] * (1.0 - 0.5 * kolaylik()))) if a["tip"] != "" else 0

func ariza_p100() -> float:
	var a: Dictionary = oyun.arac
	return 0.4 * ARACLAR[a["tip"]]["guv"] * (1.0 - 0.8 * kolaylik()) if a["tip"] != "" else 0.0

func surulur() -> bool:
	var a: Dictionary = oyun.arac
	return a["tip"] != "" and a["kullan"] and a["yakit"] > 0.0 and oyun.t >= a["ariza"]

func hiz_carpan() -> float:
	return ARACLAR[oyun.arac["tip"]]["hiz"] if surulur() else 1.0

func pusu_carpan() -> float:
	return ARACLAR[oyun.arac["tip"]]["pusu"] if surulur() else 1.0

# Her yürüyüş adımında (metre): yakıt yanar, arıza çıkabilir.
func adim(metre: float) -> void:
	if not surulur():
		return
	var a: Dictionary = oyun.arac
	var T: Dictionary = ARACLAR[a["tip"]]
	var px := metre / PX_M
	a["yakit"] = maxf(0.0, a["yakit"] - T["tuk"] * px / 100.0)
	a["yol"] += px
	if a["yakit"] <= 0.0:
		oyun.kayit("%s'in benzini bitti; yürümeye devam ediyorsun. Bir yerden yakıt almalısın." % T["ad"], "warn")
		return
	if rng.randf() < ariza_p100() / 100.0 * px / 100.0:
		var masraf := int(round(30.0 * (1.0 - 0.5 * kolaylik())))
		a["ariza"] = oyun.t + 90
		oyun.harcama(float(masraf), "kirli")
		oyun.kayit("%s yolda bozuldu: 90 dakika yürüyeceksin. Tamir %s." % [T["ad"], oyun.para(masraf)], "bad")

func al(tip: String) -> Dictionary:
	if not ARACLAR.has(tip):
		return oyun.hata("Böyle bir araba yok.")
	var a: Dictionary = oyun.arac
	if a["tip"] != "":
		return oyun.hata("Zaten bir araban var. Önce sat.")
	var T: Dictionary = ARACLAR[tip]
	if not oyun.harcama(float(T["fiyat"]), "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(T["fiyat"]))
	a["tip"] = tip
	a["yakit"] = T["tank"] * 0.5
	a["kullan"] = true
	a["ariza"] = 0
	oyun.kayit("%s aldın (%s). Depoda yarım benzin var; artık arabayla gidebilirsin." % [T["ad"], oyun.para(T["fiyat"])], "good")
	return oyun.tamam()

func sat() -> Dictionary:
	var a: Dictionary = oyun.arac
	if a["tip"] == "":
		return oyun.hata("Araban yok.")
	var T: Dictionary = ARACLAR[a["tip"]]
	var g := int(round(T["fiyat"] * 0.6))
	oyun.temiz += g
	oyun.kayit("%s satıldı (%s)." % [T["ad"], oyun.para(g)], "info")
	a["tip"] = ""
	a["yakit"] = 0.0
	a["kullan"] = false
	return oyun.tamam()

func sur(v: bool) -> Dictionary:
	if oyun.arac["tip"] == "":
		return oyun.hata("Araban yok.")
	oyun.arac["kullan"] = v
	return oyun.tamam()

func benzin_al() -> Dictionary:
	var a: Dictionary = oyun.arac
	if a["tip"] == "":
		return oyun.hata("Araban yok.")
	var T: Dictionary = ARACLAR[a["tip"]]
	var f := yakit_fiyat()
	var eksik: float = T["tank"] - a["yakit"]
	if eksik < 1.0:
		return oyun.hata("Depo zaten dolu.")
	var l := mini(int(floor(eksik)), int(floor((oyun.temiz + oyun.kirli) / f)))
	if l < 1:
		return oyun.hata("Benzin için para yetmiyor.")
	oyun.harcama(l * f, "kirli")
	a["yakit"] += l
	oyun.kayit("%d litre benzin aldın (%s)." % [l, oyun.para(l * f)], "info")
	return oyun.tamam()

# Ay sonunda
func ay() -> void:
	var a: Dictionary = oyun.arac
	if a["tip"] == "":
		return
	var g := bakim_gider()
	if oyun.harcama(float(g), "kirli"):
		oyun.kayit("ARABA: %s bakım %s." % [ARACLAR[a["tip"]]["ad"], oyun.para(g)], "info")
	else:
		a["ariza"] = oyun.t + 3 * 1440
		oyun.kayit("Bakım parası çıkmadı: araba 3 gün serviste.", "bad")
