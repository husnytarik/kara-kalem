extends RefCounted
# Aklama, maliye şüphesi, vergi, çamaşırhane (web: launderInfo, maliSuphe, TAX).
# Kirli para, yasal cironun belli bir oranı kadar temize çevrilir; fazlası maliyenin dikkatini çeker.

const ORAN_YASAL := 0.30     # yasal aylık ciro × bu = aklama kapasitesi
const ORAN_CAMASIR := 0.50   # çamaşırhane cirosu için
const UCRET := 0.20
const VERGI := 0.10
const CAMASIR_FIYAT := 1200
const CAMASIR_CIRO := 100    # ayda yasal ciro (temiz gelir)

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"yasal": 0.0, "camasir": false, "yuzde": 50, "suphe": 0.0, "son": {}}

func kapasite() -> float:
	var a: Dictionary = oyun.akl
	var m: RefCounted = oyun.meslek
	var yasal: float = a["yasal"]
	var cam: float = CAMASIR_CIRO if a["camasir"] else 0.0
	var ek := 0.0
	if oyun.mes["isletme"].has("katip"):
		ek = m.isletme_gelir("katip") * 3.0
	return (maxf(0.0, yasal - cam) * ORAN_YASAL + cam * ORAN_CAMASIR) * m.aklama_kapasite() + ek

func ucret() -> float:
	return oyun.meslek.aklama_ucret(UCRET)

func plan() -> Dictionary:
	var kap := kapasite()
	var tutar := minf(oyun.kirli, kap * oyun.akl["yuzde"] / 100.0)
	return {"kap": kap, "ucret": ucret(), "tutar": tutar}

func yuzde_ayarla(v: int) -> void:
	oyun.akl["yuzde"] = v

func camasir_al() -> Dictionary:
	if oyun.akl["camasir"]:
		return oyun.hata("Çamaşırhane zaten senin.")
	if not oyun.harcama(float(CAMASIR_FIYAT), "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(CAMASIR_FIYAT))
	oyun.akl["camasir"] = true
	oyun.kayit("Çamaşırhane aldın (%s). Nakit akışı kirli parayı aklamak için ideal." % oyun.para(CAMASIR_FIYAT), "good")
	return oyun.tamam()

# Ay sonu: önce aklama, sonra vergi, sonra maliye.
func ay() -> void:
	var a: Dictionary = oyun.akl
	if a["camasir"]:
		oyun.temiz += CAMASIR_CIRO
		a["yasal"] += CAMASIR_CIRO
	var p := plan()
	var akl_tutar: float = p["tutar"]
	if akl_tutar > 0.0:
		oyun.kirli -= akl_tutar
		oyun.temiz += akl_tutar * (1.0 - p["ucret"])
		oyun.kayit("AKLAMA: %s kirli → %s temiz (kapasite %s, kesinti %%%d)." % [oyun.para(akl_tutar), oyun.para(akl_tutar * (1.0 - p["ucret"])), oyun.para(p["kap"]), int(round(p["ucret"] * 100.0))], "info")
		if akl_tutar > p["kap"] * 1.001:
			var sapma: float = (akl_tutar - p["kap"]) / p["kap"] * 100.0
			var ek := 0.02 * sapma * sapma
			a["suphe"] += ek
			oyun.kayit("Kapasitenin %%%d üstünde akladın: Mali Şüphe +%d (şimdi %d)." % [int(sapma), int(ek), int(a["suphe"])], "warn")
	# vergi: yasal cironun %10'u (ekip maaşı gider sayılır)
	var vergi := maxf(0.0, (a["yasal"] - oyun.adamlar.size() * oyun.EKIP_MAAS) * VERGI)
	if vergi > 0.0:
		if oyun.temiz >= vergi:
			oyun.temiz -= vergi
		else:
			a["suphe"] += 6.0
			oyun.kayit("Vergiyi ödeyemedin; Mali Şüphe artıyor.", "bad")
		oyun.kayit("VERGİ: yasal ciro %s · vergi %s." % [oyun.para(a["yasal"]), oyun.para(vergi)], "info")
	a["son"] = {"yasal": a["yasal"], "vergi": vergi}
	# maliye denetimi
	if a["suphe"] >= 50.0:
		a["suphe"] = 20.0
		oyun.harcama(300.0, "temiz")
		oyun.arama = minf(100.0, oyun.arama + 10.0)
		oyun.kayit("MALİYE: defterler incelendi. $300 ceza, arama +10: kapasitenin çok üstünde para aklamıştın.", "bad")
	a["suphe"] *= 0.8
	a["yasal"] = 0.0
