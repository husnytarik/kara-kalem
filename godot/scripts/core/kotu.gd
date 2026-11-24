extends RefCounted
# Kötü yol: tefeci borcu, kumar, hatalı soygun, hapis ve rezillik spirali.
# Durum: oyun.kotu = {tef, tef_kac, rezil, hapis_say, kumar_gun, kumar_say, soy_gun}

const TEF_LIMIT := 4000.0
const TEF_FAIZ := 0.10
const KUMAR_GUNLUK := 4
const SOYGUN_GUN := 3
const KOMIK := [
	"Dükkânın kapısı çekmeli değil itmeliymiş; esnafın karşısında yirmi dakika kapıyla boğuştun.",
	"Maskeyi ters taktın, hiçbir şey göremeden kasayı değil duvarı soydun.",
	"Kaçış arabası olarak seçtiğin araç meğer belediyenin çöp arabasıymış.",
	"Dükkâncı seni tanıdı: \"Sen geçen hafta bana kömür satan çocuk değil misin?\"",
	"Kasayı açtın; içinde sadece bir kedi ve veresiye defteri vardı.",
]

var oyun: Node
var rng := RandomNumberGenerator.new()

func _init(o: Node) -> void:
	oyun = o
	rng.seed = 7731

static func yeni() -> Dictionary:
	return {"tef": 0.0, "tef_kac": 0, "rezil": 0.0, "hapis_say": 0, "kumar_gun": -1, "kumar_say": 0, "soy_gun": -99}

func _k() -> Dictionary:
	return oyun.kotu

func _gun() -> int:
	return oyun.t / oyun.DAY

# --- tefeci ---------------------------------------------------------------
func tefeci_al(m: float) -> Dictionary:
	var k := _k()
	if float(k["tef"]) + m > TEF_LIMIT:
		return oyun.hata("Tefeci en fazla %s borç verir." % oyun.para(TEF_LIMIT))
	k["tef"] = float(k["tef"]) + m
	oyun.kirli += m
	oyun.kayit("Tefeciden %s aldın. Aylık %%%d faiz işler; kimse sormaz, ama unutmaz." % [oyun.para(m), int(TEF_FAIZ * 100.0)], "warn")
	oyun.degisti.emit()
	return oyun.tamam()

func tefeci_ode(m: float) -> Dictionary:
	var k := _k()
	var x: float = minf(m, float(k["tef"]))
	if x <= 0.0:
		return oyun.hata("Tefeciye borcun yok.")
	if not oyun.harcama(x, "kirli"):
		return oyun.hata("Para yetmiyor.")
	k["tef"] = float(k["tef"]) - x
	if k["tef"] < 1.0:
		k["tef"] = 0.0
		k["tef_kac"] = 0
		oyun.kayit("Tefeciye borcun bitti. Rahat bir nefes.", "good")
	oyun.degisti.emit()
	return oyun.tamam()

# --- kumar -----------------------------------------------------------------
func kumar(bahis: float) -> Dictionary:
	var k := _k()
	var g := _gun()
	if int(k["kumar_gun"]) != g:
		k["kumar_gun"] = g
		k["kumar_say"] = 0
	if int(k["kumar_say"]) >= KUMAR_GUNLUK:
		return oyun.hata("Bugünlük masadan kaldırıldın.")
	if not oyun.harcama(bahis, "kirli"):
		return oyun.hata("Kirli para yetmiyor (%s)." % oyun.para(bahis))
	k["kumar_say"] = int(k["kumar_say"]) + 1
	var zeka: float = float(oyun.ozet.get("stat", {}).get("zeka", 5))
	var p: float = clampf(0.42 + oyun.aile_k.etki("kumar_gelir") + 0.01 * (zeka - 5.0), 0.2, 0.6)
	if rng.randf() < p:
		oyun.kirli += bahis * 2.0
		if bahis >= 200.0:
			oyun.kaz_k.ver("kumar_zengin")
		oyun.kayit("Kumarda kazandın: +%s." % oyun.para(bahis), "good")
		oyun.degisti.emit()
		return oyun.tamam("Kazandın! +%s" % oyun.para(bahis))
	oyun.kis["stres"] = minf(100.0, oyun.kis["stres"] + 6.0)
	oyun.kayit("Kumarda %s kaybettin." % oyun.para(bahis), "bad")
	oyun.degisti.emit()
	return oyun.tamam("Kaybettin: −%s (stres +6)" % oyun.para(bahis))

# --- hatalı soygun ---------------------------------------------------------
func soygun() -> Dictionary:
	var k := _k()
	if _gun() - int(k["soy_gun"]) < SOYGUN_GUN:
		return oyun.hata("Mahalle henüz seni unutmadı; %d gün sabret." % (SOYGUN_GUN - (_gun() - int(k["soy_gun"]))))
	k["soy_gun"] = _gun()
	var s: Dictionary = oyun.ozet.get("stat", {})
	var p: float = clampf(0.35 + 0.03 * (float(s.get("zeka", 5)) + float(s.get("guc", 5)) - 10.0) + 0.04 * oyun.adamlar.size() - oyun.arama / 250.0, 0.1, 0.8)
	oyun.bekle(60)
	if rng.randf() < p:
		var kazanc: float = float(rng.randi_range(180, 520))
		oyun.kirli += kazanc
		oyun.polis.kanit(3.0, "Küçük soygun.")
		oyun.yol_k.ekle("golge", 1.0)
		oyun.kayit("Soygun tuttu: %s." % oyun.para(kazanc), "good")
		oyun.degisti.emit()
		return oyun.tamam("Başardın! +%s kirli" % oyun.para(kazanc))
	_rezil_ekle(6.0)
	oyun.polis.kanit(6.0, "Soygun fiyaskosu.")
	var msg: String = KOMIK[rng.randi() % KOMIK.size()]
	oyun.kayit("Soygun fiyasko: " + msg, "bad")
	if rng.randf() < 0.45 + oyun.arama / 200.0:
		hapis(2 + rng.randi() % 3, "Soygunda yakalandın.")
		return oyun.tamam(msg + " Yakalandın!")
	oyun.degisti.emit()
	return oyun.tamam(msg + " Zor kaçtın.")

func _rezil_ekle(v: float) -> void:
	_k()["rezil"] = clampf(float(_k()["rezil"]) + v, 0.0, 100.0)
	oyun.un["saygi"] = maxf(-50.0, oyun.un["saygi"] - v * 0.8)

# --- hapis ------------------------------------------------------------------
func hapis(gun: int, neden: String) -> void:
	var k := _k()
	k["hapis_say"] = int(k["hapis_say"]) + 1
	oyun.kaz_k.ver("hapis")
	var ceza: float = minf(oyun.temiz + oyun.kirli, 150.0 * gun)
	oyun.harcama(ceza, "kirli")
	_rezil_ekle(8.0)
	oyun.kis_k.bulas_dene("verem" if oyun.rng.randf() < 0.5 else "tifus", 0.3 + 0.02 * gun, "hücrenin nemi ve kalabalığı")
	oyun.kis_k.uyku_baslat()
	oyun.kayit("%s %d gün hapis yattın; para cezası %s." % [neden, gun, oyun.para(ceza)], "bad")
	oyun.bekle(gun * oyun.DAY)
	oyun.kis_k.uyku_bitti()
	oyun.arama = maxf(0.0, oyun.arama - 15.0)
	oyun.un["sevgi"] = maxf(-50.0, oyun.un["sevgi"] - 3.0)
	oyun.degisti.emit()

# --- aylık: faiz, rezillik ---------------------------------------------------
func ay() -> void:
	var k := _k()
	if float(k["tef"]) > 0.0:
		var faiz: float = float(k["tef"]) * TEF_FAIZ
		if oyun.harcama(faiz, "kirli"):
			k["tef_kac"] = 0
			oyun.kayit("Tefeci faizi alındı: %s (borç %s)." % [oyun.para(faiz), oyun.para(k["tef"])], "info")
		else:
			k["tef"] = float(k["tef"]) + faiz
			k["tef_kac"] = int(k["tef_kac"]) + 1
			_rezil_ekle(4.0)
			oyun.kayit("Tefeciye faizi ödeyemedin (%d/3). Borç %s'a çıktı; adamları kapına geldi." % [k["tef_kac"], oyun.para(k["tef"])], "bad")
			oyun.kis["yara"] = minf(100.0, float(oyun.kis.get("yara", 0.0)) + 15.0)
			if int(k["tef_kac"]) >= 3 and oyun.son.is_empty():
				oyun.ol("Tefecinin sabrı bitti. Bir gece Southside'ın arka sokağında bulundun; borç kapanmadı ama sen kapandın.")
	k["rezil"] = maxf(0.0, float(k["rezil"]) - 1.0)
