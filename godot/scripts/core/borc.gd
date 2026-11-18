extends RefCounted
# Babadan kalan tefeci borcu (web: debt). Aylık %1 faiz, aylık taksit; temiz parayla ödenir.
# Üç taksit üst üste ödenmezse oyun biter. Sadece "yerli" (Murphy's Tavern) başlangıcında vardır.

const FAIZ := 0.01
const ANA := 2400.0
const TAKSIT := 150.0

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"ana": 0.0, "taksit": 0.0, "kacirilan": 0}

func baslat() -> void:
	oyun.borc = {"ana": ANA, "taksit": TAKSIT, "kacirilan": 0}

func var_mi() -> bool:
	return oyun.borc["ana"] > 0.0

func ode(miktar: float) -> Dictionary:
	var b: Dictionary = oyun.borc
	var m := minf(miktar, b["ana"])
	if m <= 0.0:
		return oyun.hata("Ödenecek borç yok.")
	if oyun.temiz < m:
		return oyun.hata("Temiz paran yetmiyor.")
	oyun.temiz -= m
	b["ana"] -= m
	oyun.kayit("Borçtan %s erken ödendi." % oyun.para(m), "good")
	_bitti_mi()
	return oyun.tamam()

func _bitti_mi() -> void:
	var b: Dictionary = oyun.borc
	if b["ana"] < 1.0 and b["taksit"] > 0.0:
		b["ana"] = 0.0
		b["kacirilan"] = 0
		oyun.kayit("Babanın borcu bitti. Sal'a artık bir şey borçlu değilsin.", "good")

func ay() -> void:
	var b: Dictionary = oyun.borc
	if b["ana"] <= 0.0:
		return
	b["ana"] *= 1.0 + FAIZ
	var pay := minf(b["taksit"], b["ana"])
	if oyun.temiz >= pay:
		oyun.temiz -= pay
		b["ana"] -= pay
		oyun.kayit("BORÇ: taksit %s ödendi · kalan %s." % [oyun.para(pay), oyun.para(b["ana"])], "info")
		_bitti_mi()
	else:
		b["kacirilan"] += 1
		oyun.kayit("Taksiti ödeyemedin (%d/3). Temiz paran %s, taksit %s; kirli parayla resmî taksit ödenmez." % [b["kacirilan"], oyun.para(oyun.temiz), oyun.para(pay)], "bad")
		if b["kacirilan"] >= 3 and oyun.son.is_empty():
			oyun.son = {"tur": "yenilgi", "metin": "Üç taksit üst üste ödenmedi. Sal'ın adamları bu sefer oturmadı. Meyhanenin tapusu el değiştirdi."}
