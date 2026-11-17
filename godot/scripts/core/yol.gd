extends RefCounted
# Yükseliş yolları + dönemler. Dört yol: Yasal (kanun), Gölge (gizli illegal), Korku (zor), Kulis (rüşvet/ilişki).
# Puan 0..100. Her yolun seviyesi (0/1/2) oyuna somut avantaj verir; ama her yolun bir zayıflığı vardır ve
# "dönem" (siyasi/ekonomik hava) zamanla hangi yolun işlediğini değiştirir. Hiçbir yol her dönemde en iyisi değil.

const YOLLAR := ["kanun", "golge", "korku", "kulis"]
const AD := {"kanun": "Yasal", "golge": "Gölge", "korku": "Korku", "kulis": "Kulis"}
const ACIKLAMA := {
	"kanun": "Temiz iş, esnafın sevgisi. Yasal gelir artar, polis seni sevmese de elinde bir şey bulamaz.",
	"golge": "Gizli illegal: iz bırakmadan çalışırsın. Dosya daha yavaş kabarır, olaylarda kıl payı kurtulursun.",
	"korku": "Asıp kesen: haraç daha çok gelir, esnaf direnmez. Ama sevgi düşer, dosya kabarır, aileler tedirgin olur.",
	"kulis": "Rüşvet ve ilişkiler: Dolan ve belediye seninle çalışır. Skandal çıkarsa ilk sen yanarsın.",
}

# Dönemler: ay sonlarında değişir. "iyi": işleyen yol, "kotu": zorlanan yol.
const DONEMLER := {
	"sakin": {"ad": "Sakin dönem", "iyi": "", "kotu": "", "yazi": "Şehir sakin. Kimse kimseyi kıpırdatmıyor."},
	"reform": {"ad": "Reform dalgası", "iyi": "kanun", "kotu": "kulis", "yazi": "Belediye temizlik yapıyor. Rüşvet riskli, temiz işler ödüllü."},
	"skandal": {"ad": "Yolsuzluk skandalı", "iyi": "golge", "kotu": "kulis", "yazi": "Gazeteler rüşvet haberiyle dolu. Zarflar tehlikeli; gölgede kalan kazanır."},
	"cete": {"ad": "Çete yılı", "iyi": "korku", "kotu": "kanun", "yazi": "Sokaklar kaynıyor. Güçlü olan sözünü geçiriyor; temiz yol zor."},
	"refah": {"ad": "Refah dönemi", "iyi": "kanun", "kotu": "golge", "yazi": "Para bol. Yasal işler kazandırıyor; gizli işler göze batıyor."},
	"baski": {"ad": "Polis baskısı", "iyi": "kulis", "kotu": "korku", "yazi": "Polis her köşede. Korku yolu pahalı; kulis iş görür."},
}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

func yeni() -> Dictionary:
	return {"puan": {"kanun": 0.0, "golge": 0.0, "korku": 0.0, "kulis": 0.0},
		"donem": "sakin", "bitis": 20 * 1440, "cool": {}, "once": {}, "bekleyen": "", "son_kart": -99999, "secti": false}

func ekle(yol: String, d: float) -> void:
	var p: Dictionary = oyun.yol["puan"]
	p[yol] = clampf(p[yol] + d, 0.0, 100.0)

func puan(yol: String) -> float:
	return oyun.yol["puan"][yol]

# 0: yok, 1: 25+, 2: 50+
func seviye(yol: String) -> int:
	var x := puan(yol)
	return 2 if x >= 50.0 else (1 if x >= 25.0 else 0)

func donem() -> Dictionary:
	return DONEMLER[oyun.yol["donem"]]

# Dönem, yola bonus/ceza verir: +1 / 0 / -1
func hava(yol: String) -> int:
	var d := donem()
	if d["iyi"] == yol:
		return 1
	if d["kotu"] == yol:
		return -1
	return 0

# Bir yolun gelire/olaya etkisi: seviye + dönem
func etki(yol: String) -> float:
	return float(seviye(yol)) + 0.5 * float(hava(yol))

# Ana yol: en yüksek puanlı (0 ise "")
func ana() -> String:
	var en := ""
	var m := 10.0
	for y in YOLLAR:
		if puan(y) > m:
			m = puan(y)
			en = y
	return en

# --- oyuna bağlanan çarpanlar ---
func yasal_carpan() -> float:
	return 1.0 + 0.15 * etki("kanun")

func harac_carpan() -> float:
	return 1.0 + 0.2 * etki("korku")

# Haraçta direnç: korku yolu esnafın karşı koymasını azaltır (başarı olasılığı bonusu)
func harac_sans() -> float:
	return 0.06 * etki("korku") + 0.03 * etki("kanun")

# Polis dosyası artışı çarpanı (gölge azaltır, korku artırır, reform dönemi artırır)
func arama_carpan() -> float:
	var c := 1.0 - 0.15 * etki("golge") + 0.12 * float(seviye("korku"))
	if oyun.yol["donem"] == "reform":
		c += 0.25
	if oyun.yol["donem"] == "baski":
		c += 0.25
	return clampf(c, 0.4, 2.0)

# Rüşvet maliyeti çarpanı
func rusvet_carpan() -> float:
	return clampf(1.0 - 0.15 * etki("kulis"), 0.5, 1.6)

# --- zaman ---
func gun() -> void:
	var y: Dictionary = oyun.yol
	# yavaş çürüme: kullanmayan yol soluyor
	for k in YOLLAR:
		y["puan"][k] = maxf(0.0, y["puan"][k] - 0.08)
	# gölge: dosya kendiliğinden biraz daha hızlı soğur
	if seviye("golge") >= 1:
		oyun.arama = maxf(0.0, oyun.arama - 0.15 * seviye("golge"))
	if oyun.yol["donem"] == "reform" and seviye("kulis") >= 1:
		ekle("kulis", -0.3)
	if oyun.yol["donem"] == "cete" and seviye("kanun") >= 1:
		ekle("kanun", -0.2)
	if oyun.t >= y["bitis"]:
		_donem_degis()
	# kart çekimi
	if y["bekleyen"] == "" and oyun.t - y["son_kart"] >= 2 * oyun.DAY:
		var k: String = oyun.kart_k.cek()
		if k != "":
			y["bekleyen"] = k
			y["son_kart"] = oyun.t

func ay() -> void:
	pass

func _donem_degis() -> void:
	var y: Dictionary = oyun.yol
	var adaylar: Array = DONEMLER.keys().filter(func(k): return k != y["donem"])
	var yeni_d: String = adaylar[oyun.rng.randi() % adaylar.size()]
	y["donem"] = yeni_d
	y["bitis"] = oyun.t + (15 + oyun.rng.randi() % 16) * oyun.DAY
	var d: Dictionary = DONEMLER[yeni_d]
	oyun.kayit("Dengeler değişti — %s: %s" % [d["ad"], d["yazi"]], "warn")
	if yeni_d == "skandal":
		ekle("kulis", -10.0)
		oyun.arama = minf(100.0, oyun.arama + 5.0)
	elif yeni_d == "cete":
		for f in oyun.NPC:
			oyun.gerginlik.ekle(f, oyun.NPC[(oyun.NPC.find(f) + 1) % oyun.NPC.size()], 2.0, "çete yılı")
	oyun.degisti.emit()

func ozet_satiri() -> String:
	var a := ana()
	var d := donem()
	var t := {"": "henüz belli değil", "kanun": "düzgün biri olarak tanınıyorsun", "golge": "izini belli etmeyen biri olarak tanınıyorsun",
		"korku": "korkulan biri olarak tanınıyorsun", "kulis": "iş bitiren, bağlantılı biri olarak tanınıyorsun"}
	return "Şehirde %s · %s" % [t[a], d["ad"]]
