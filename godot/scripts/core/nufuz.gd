extends RefCounted
# Nüfuz: dokunulmazlık (polis/yargıç/siyasi), federal tehdit, adamların sadakati ve darbe, malikâne.
# Durum: oyun.nuf = {dokun: {polis, yargic, siyasi}, fed, mal, fed_ay}

const KISI := {
	"polis": {"ad": "Polis şefi", "ac": "Kanıt dosyana daha yavaş girer."},
	"yargic": {"ad": "Yargıç", "ac": "Dosya 100'e ulaşsa da dava düşebilir."},
	"siyasi": {"ad": "Belediye / siyasetçi", "ac": "Federal ilgiyi ve mahalle baskısını azaltır."},
}
const TUR_UCRET := 400.0     # bir kademe (+15) için
const AYLIK_DUSUS := 6.0
const MAL_FIYAT := 12000.0
const PARTI_UCRET := 500.0
const AVUKAT_UCRET := 1500.0
const FED_ESIK := 60.0

var oyun: Node
var rng := RandomNumberGenerator.new()

func _init(o: Node) -> void:
	oyun = o
	rng.seed = 9091

static func yeni() -> Dictionary:
	return {"dokun": {"polis": 0.0, "yargic": 0.0, "siyasi": 0.0}, "fed": 0.0, "mal": false, "fed_ay": 0, "parti": -99}

func _n() -> Dictionary:
	return oyun.nuf

func dokun(k: String) -> float:
	return float(_n()["dokun"].get(k, 0.0))

# Rüşvet ver: bir kademe (+15) dokunulmazlık.
func rusvet_ver(k: String) -> Dictionary:
	var d: float = dokun(k)
	if d >= 100.0:
		return oyun.hata("Zaten tam dokunulmazlık.")
	var ucret: float = ucret_k(k)
	if not oyun.harcama(ucret, "kirli"):
		return oyun.hata("Para yetmiyor (%s)." % oyun.para(ucret))
	_n()["dokun"][k] = minf(100.0, d + 15.0)
	oyun.kayit("%s'e rüşvet gitti. Dokunulmazlık %d." % [KISI[k]["ad"], int(dokun(k))], "info")
	oyun.degisti.emit()
	return oyun.tamam()

func ucret_k(k: String) -> float:
	return TUR_UCRET * (1.0 + dokun(k) / 50.0) * maxf(0.3, 1.0 + oyun.aile_k.etki("rusvet"))

func fed() -> float:
	return float(_n()["fed"])

func fed_ekle(v: float) -> void:
	_n()["fed"] = clampf(fed() + v, 0.0, 100.0)

func avukat() -> Dictionary:
	if not oyun.harcama(AVUKAT_UCRET, "temiz"):
		return oyun.hata("Avukat için temiz para yetmiyor (%s)." % oyun.para(AVUKAT_UCRET))
	fed_ekle(-25.0)
	oyun.kayit("Avukat federal dosyayı yavaşlattı: Federal ilgi −25.", "good")
	oyun.degisti.emit()
	return oyun.tamam()

# Dosya 100'e vardığında yargıç kurtarabilir.
func dava_dusur() -> bool:
	if dokun("yargic") >= 50.0:
		_n()["dokun"]["yargic"] = dokun("yargic") - 50.0
		oyun.arama = 60.0
		oyun.kayit("Yargıç davayı düşürdü! Dosya 60'a indi. Yargıç ilişkisi −50.", "good")
		return true
	return false

func sadakat(a: Dictionary) -> float:
	return float(a.get("sadakat", 60.0))

# --- malikâne -------------------------------------------------------------
func mal_al() -> Dictionary:
	if _n()["mal"]:
		return oyun.hata("Zaten bir malikânen var.")
	if not oyun.harcama(MAL_FIYAT, "temiz"):
		return oyun.hata("Malikâne için temiz para yetmiyor (%s)." % oyun.para(MAL_FIYAT))
	_n()["mal"] = true
	oyun.un_k.ekle("saygi", 8.0)
	oyun.kayit("Malikâneyi satın aldın. Mahalle artık başka gözle bakıyor.", "good")
	oyun.degisti.emit()
	return oyun.tamam()

func parti() -> Dictionary:
	if not _n()["mal"]:
		return oyun.hata("Önce malikâne gerek.")
	var g: int = oyun.t / oyun.DAY
	if g - int(_n()["parti"]) < 10:
		return oyun.hata("Son partiden beri 10 gün geçmedi.")
	if not oyun.harcama(PARTI_UCRET, "temiz"):
		return oyun.hata("Parti için temiz para yetmiyor (%s)." % oyun.para(PARTI_UCRET))
	_n()["parti"] = g
	for a in oyun.adamlar:
		a["sadakat"] = minf(100.0, sadakat(a) + 10.0)
	oyun.un_k.ekle("saygi", 3.0)
	oyun.un_k.ekle("sevgi", 2.0)
	oyun.kis["stres"] = maxf(0.0, oyun.kis["stres"] - 15.0)
	oyun.kayit("Malikânede parti verdin. Adamlar sadık, mahalle konuşuyor. Stres −15.", "good")
	oyun.degisti.emit()
	return oyun.tamam()

# --- günlük / aylık ------------------------------------------------------
func gun() -> void:
	var n := _n()
	# federal ilgi: servet, dikkat ve korku büyüdükçe artar; siyasi dokunulmazlık yavaşlatır
	var sv: float = oyun.un_k.deger("servet") / 100.0
	var di: float = oyun.un_k.deger("dikkat") / 100.0
	var ko: float = oyun.un_k.deger("korku") / 100.0
	var kirli_p: float = clampf(oyun.kirli / 20000.0, 0.0, 1.0)
	var r: float = 0.12 * (0.5 * di + 0.3 * ko + 0.3 * sv * kirli_p + 0.2 * kirli_p)
	r *= maxf(0.2, 1.0 + oyun.aile_k.etki("federal_ilgi"))
	r *= 1.0 - 0.6 * dokun("siyasi") / 100.0
	if oyun.un_k.deger("servet") < 25.0:
		r *= 0.2
	n["fed"] = clampf(fed() + r - 0.02, 0.0, 100.0)
	if fed() >= FED_ESIK and oyun.t / oyun.DAY - int(n["fed_ay"]) >= 15:
		n["fed_ay"] = oyun.t / oyun.DAY
		_federal_olay()
	if fed() >= 100.0 and oyun.son.is_empty():
		if dokun("yargic") >= 60.0:
			n["dokun"]["yargic"] = dokun("yargic") - 60.0
			n["fed"] = 50.0
			oyun.kayit("Federal dava açıldı ama yargıç sana sahip çıktı. Federal ilgi 50'ye indi.", "warn")
		else:
			oyun.son = {"tur": "yenilgi", "metin": "Federal ajanlar hesaplarını inceledi: vergi kaçakçılığı. Capone gibi, silahla değil kağıtla düştün.\n\n" + oyun.kisi_k.ozet_yazi()}
	# sadakat eğilimi
	var hedef: float = clampf(55.0 + 100.0 * oyun.aile_k.etki("sadakat") + (oyun.un_k.deger("saygi") - 30.0) * 0.3 + (8.0 if n["mal"] else 0.0), 10.0, 95.0)
	for a in oyun.adamlar:
		a["sadakat"] = clampf(sadakat(a) + (hedef - sadakat(a)) * 0.03, 0.0, 100.0)

func _federal_olay() -> void:
	var r := rng.randi() % 3
	match r:
		0:
			var el: float = oyun.kirli * 0.3
			oyun.kirli -= el
			oyun.kayit("Federal ajanlar kasaya el koydu: kirli paranın %30'u (%s) gitti." % oyun.para(el), "bad")
		1:
			oyun.arama = minf(100.0, oyun.arama + 15.0)
			oyun.kayit("Federal ajanlar mahallede soru soruyor. Dosya +15.", "bad")
		2:
			var vergi: float = minf(oyun.temiz, 500.0 + oyun.temiz * 0.1)
			oyun.temiz -= vergi
			oyun.kayit("Vergi dairesi denetim yaptı: %s ceza ödedin." % oyun.para(vergi), "bad")
	fed_ekle(-10.0)

func ay() -> void:
	var n := _n()
	for k in n["dokun"]:
		n["dokun"][k] = maxf(0.0, dokun(k) - AYLIK_DUSUS)
	# darbe: sadakati çok düşük akıllı adam ihanet eder
	for a in oyun.adamlar.duplicate():
		if a["gorev"] != "" or sadakat(a) >= 30.0:
			continue
		var p: float = 0.25 * (1.0 + oyun.aile_k.etki("darbe")) * (1.0 - sadakat(a) / 30.0 * 0.5)
		if rng.randf() < clampf(p, 0.0, 0.8):
			var calinan: float = oyun.kirli * 0.15
			oyun.kirli -= calinan
			oyun.adamlar.erase(a)
			oyun.arama = minf(100.0, oyun.arama + 8.0 * (1.0 + oyun.aile_k.etki("muhbir")))
			oyun.kayit("%s ihanet etti! %s ile kaçtı ve polise konuştu. Dosya +8." % [a["ad"], oyun.para(calinan)], "bad")
