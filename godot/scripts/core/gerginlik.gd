extends RefCounted
# Aileler arası gerginlik ve savaş. Bir aile, başka ailenin mahallesinde esnaftan haraç alırsa / nüfuz
# kemirirse aralarında gerginlik birikir; eşik aşılınca SAVAŞ çıkar (2 ay). Oyuncu da bir taraf olabilir
# ("oyuncu"). Çalıştığın mahallenin ailesi senin "ev sahibin" sayılır: onun düşmanları seni onun adamı sayar.

const ESIK := 10.0
const SAVAS_SURE := 20 * 1440      # 2 ay (10 gün/ay)
const SOGUMA := 0.85               # aylık gerginlik azalması

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

func _anahtar(a: String, b: String) -> String:
	return a + "|" + b if a < b else b + "|" + a

func _kayit(a: String, b: String) -> Dictionary:
	var k := _anahtar(a, b)
	if not oyun.gerg.has(k):
		oyun.gerg[k] = {"puan": 0.0, "savas": 0}
	return oyun.gerg[k]

func ad(f: String) -> String:
	return "Sen" if f == "oyuncu" else oyun.hakim_ad(f)

func ekle(a: String, b: String, p: float, neden: String = "") -> void:
	if a == "" or b == "" or a == b:
		return
	var g := _kayit(a, b)
	g["puan"] += p
	if g["savas"] == 0 and g["puan"] >= ESIK:
		g["savas"] = oyun.t + SAVAS_SURE
		var m := "SAVAŞ: %s ile %s arasında savaş çıktı!" % [ad(a), ad(b)]
		if neden != "":
			m += " (%s)" % neden
		oyun.kayit(m, "bad" if a == "oyuncu" or b == "oyuncu" else "warn")

func baris(a: String, b: String) -> void:
	var g := _kayit(a, b)
	g["savas"] = 0
	g["puan"] = 2.0
	oyun.kayit("Barış: %s ile %s anlaştı." % [ad(a), ad(b)], "info")

func savasta(a: String, b: String) -> bool:
	if a == b or a == "" or b == "":
		return false
	var k := _anahtar(a, b)
	return oyun.gerg.has(k) and oyun.gerg[k]["savas"] > oyun.t

func gerginlik(a: String, b: String) -> float:
	var k := _anahtar(a, b)
	return oyun.gerg[k]["puan"] if oyun.gerg.has(k) else 0.0

# Çalıştığın yer: vardiya veya meslek -> mahalle id (yoksa "")
func is_bolgesi() -> String:
	if not oyun.vardiya.is_empty():
		return oyun.harita.yerler[oyun.vardiya["bina"]]["bolge"]
	if not oyun.mes["is"].is_empty():
		return oyun.mes["is"]["b"]
	return ""

# Çalıştığın mahalleyi elinde tutan NPC ailesi (yoksa "")
func ev_sahibi() -> String:
	var b := is_bolgesi()
	if b == "":
		return ""
	var h: String = oyun.hakim_of(b)
	return h if h != "" and h != "oyuncu" else ""

# Düşmanın seni hedef alır mı? (kendi ailesi veya ev sahibine karşı savaşta olanlar)
func dusman_mi(f: String) -> bool:
	if savasta("oyuncu", f):
		return true
	var es := ev_sahibi()
	return es != "" and savasta(es, f)

func dost_mu(f: String) -> bool:
	return ev_sahibi() == f and not savasta("oyuncu", f)

func ay() -> void:
	for k in oyun.gerg.keys():
		var g: Dictionary = oyun.gerg[k]
		var p: PackedStringArray = k.split("|")
		if g["savas"] > 0 and oyun.t >= g["savas"]:
			g["savas"] = 0
			g["puan"] = 3.0
			oyun.kayit("Barış: %s ile %s savaşı sona erdi." % [ad(p[0]), ad(p[1])], "info")
		elif g["savas"] > 0:
			_savas_ay(p[0], p[1])
		else:
			g["puan"] *= SOGUMA

# Savaş ayı: güçlü taraf zayıfın bir mahallesinde nüfuz kazanır.
func _savas_ay(a: String, b: String) -> void:
	if a == "oyuncu" or b == "oyuncu":
		return   # oyuncu tarafı savaşı kendi hamleleriyle yürütür
	var ka: float = oyun.kudret(a) * (0.7 + oyun.rng.randf() * 0.6)
	var kb: float = oyun.kudret(b) * (0.7 + oyun.rng.randf() * 0.6)
	var guclu := a if ka >= kb else b
	var zayif := b if ka >= kb else a
	var hedefler: Array = oyun.bolge.keys().filter(func(id): return oyun.hakim_of(id) == zayif)
	if hedefler.is_empty():
		return
	var id: String = hedefler[oyun.rng.randi() % hedefler.size()]
	oyun.add_inf(oyun.bolge[id], guclu, 8.0)
	oyun.bolge[id]["huzur"] = maxf(0.0, oyun.bolge[id]["huzur"] - 8.0)
	oyun.kayit("Savaş: %s, %s'in %s'daki hâkimiyetine saldırdı." % [ad(guclu), ad(zayif), oyun.harita.bolgeler[id]["ad"]], "info")
