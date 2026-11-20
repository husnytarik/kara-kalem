extends RefCounted
# Beceri ağacı: her eylem bir beceriyi besler (ya da köreltir). Puanlar 0..100; seviye = puan/20.
# Bir beceri, ebeveyni yeterince gelişmeden açılmaz. Kullanılmayan beceri yavaş yavaş körelir.
# Etkiler `etki("anahtar")` ile okunur: puan/100 × katsayı, bütün becerilerin toplamı.

const DAL_AD := {"silah": "Silah", "yol": "Yol & Direksiyon", "sosyal": "Sokak & Söz"}
const DAL_SIRA := ["silah", "yol", "sosyal"]

# id: {ad, dal, ac, ust: [ebeveyn, gereken puan] ya da [], e: {etki: katsayı}}
const YET := {
	"nisan": {"ad": "Nişancılık", "dal": "silah", "ust": [], "ac": "Her silahta isabet: namlu daha az sapar.", "e": {"isabet": 0.22}},
	"tabanca": {"ad": "Tabanca ustalığı", "dal": "silah", "ust": ["nisan", 15], "ac": "Tabanca ve revolverde daha sert vuruş, daha hızlı doldurma.", "e": {"tabanca_hasar": 0.2, "tabanca_dol": -0.2}},
	"uzun": {"ad": "Uzun namlu", "dal": "silah", "ust": ["nisan", 20], "ac": "Pompalı ve tüfekte sapma azalır, hasar artar.", "e": {"uzun_hasar": 0.18, "uzun_sac": -0.3}},
	"otomatik": {"ad": "Hafif otomatik", "dal": "silah", "ust": ["tabanca", 25], "ac": "Tommy gun'ı kontrol altında tutarsın: sapma ve doldurma süresi düşer.", "e": {"oto_sac": -0.35, "oto_dol": -0.15}},
	"hizli_el": {"ad": "Hızlı el", "dal": "silah", "ust": ["tabanca", 10], "ac": "Şarjör değiştirmen çok daha çabuk.", "e": {"dol": -0.3}},
	"yakin": {"ad": "Yakın dövüş", "dal": "silah", "ust": [], "ac": "Yumruk, bıçak, sopa: hasar ve hız artar.", "e": {"yakin_hasar": 0.35, "yakin_hiz": 0.15}},
	"bakim": {"ad": "Silah bakımı", "dal": "silah", "ust": ["nisan", 10], "ac": "Silahlar daha geç aşınır; kendi tamirini yaparsın.", "e": {"asinma": -0.5, "tamir": 0.4}},
	"surus": {"ad": "Direksiyon", "dal": "yol", "ust": [], "ac": "Araç kullanırken yakıt ve arıza şansı daha iyi, yolda daha hızlısın.", "e": {"surus": 0.4}},
	"kacis": {"ad": "Kaçış sürüşü", "dal": "yol", "ust": ["surus", 20], "ac": "Kovalanırken sıyrılmak kolaylaşır.", "e": {"kacis": 0.4}},
	"ikna": {"ad": "İkna", "dal": "sosyal", "ust": [], "ac": "Blöf ve konuşmalar daha sık tutar.", "e": {"ikna": 0.4}},
	"korku": {"ad": "Gözdağı", "dal": "sosyal", "ust": ["ikna", 10], "ac": "Bakışın yeter: haraç ve blöf güçlenir, ama insanlar sevmez.", "e": {"korku": 0.4, "sevgi": -0.15}},
	"pazarlik": {"ad": "Pazarlık", "dal": "sosyal", "ust": ["ikna", 10], "ac": "Rüşvet, silah ve mermi daha ucuza gelir.", "e": {"pazarlik": 0.4, "rusvet": 0.3}},
	"sokak": {"ad": "Sokak aklı", "dal": "sosyal", "ust": ["ikna", 15], "ac": "Polis devriyesinden önce sezersin: üstünün aranma şansı azalır.", "e": {"gizlilik": 0.4}},
}

# Eylem -> beceri değişimleri (+ artırır, − köreltir). Kişisel eylemler ve meslekler buradan beslenir.
const EYLEM := {
	"icki": {"nisan": -0.5, "hizli_el": -0.3, "surus": -0.3},
	"kumar": {"pazarlik": 0.3, "sokak": 0.4},
	"sohbet": {"ikna": 0.9, "sokak": 0.3},
	"bilardo": {"nisan": 0.6, "ikna": 0.2},
	"idman": {"yakin": 1.3},
	"hamam": {"ikna": 0.1},
	"sinema": {"sokak": 0.1},
	"dua": {"korku": -0.4},
}
const MESLEK := {
	"taksi": {"surus": 1.6, "kacis": 0.4, "ikna": 0.6, "sokak": 0.5, "nisan": -0.15},
	"hamal": {"yakin": 0.5, "surus": -0.1},
	"berber": {"ikna": 0.7, "nisan": 0.25, "korku": -0.1},
	"katip": {"pazarlik": 0.8, "ikna": 0.3, "yakin": -0.2},
}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"p": {}, "son": {}}

# Karakterin istatistiklerinden başlangıç puanları.
func baslat() -> void:
	var st: Dictionary = oyun.ozet.get("stat", {})
	var p: Dictionary = oyun.yet["p"]
	var nisan: float = st.get("nisan", 5) * 6.0
	p["nisan"] = nisan
	p["tabanca"] = maxf(0.0, nisan - 20.0)
	p["yakin"] = st.get("guc", 5) * 5.0
	p["ikna"] = st.get("karizma", 5) * 5.0
	p["pazarlik"] = maxf(0.0, st.get("zeka", 5) * 4.0 - 8.0)
	p["surus"] = 8.0
	match oyun.profil.get("gecmis", ""):
		"gazi":
			p["nisan"] += 12.0
			p["tabanca"] += 14.0
			p["uzun"] = 10.0
		"boksor":
			p["yakin"] += 15.0
		"kacakci":
			p["surus"] += 18.0
			p["sokak"] = 15.0
		"hesapci":
			p["pazarlik"] += 14.0
		"isci":
			p["yakin"] += 6.0

func puan(id: String) -> float:
	return oyun.yet["p"].get(id, 0.0)

func seviye(id: String) -> int:
	return int(puan(id) / 20.0)

func acik(id: String) -> bool:
	var u: Array = YET[id]["ust"]
	return u.is_empty() or puan(u[0]) >= float(u[1])

func etki(anahtar: String) -> float:
	var top := 0.0
	for id in YET:
		var e: Dictionary = YET[id]["e"]
		if e.has(anahtar):
			top += puan(id) / 100.0 * float(e[anahtar])
	return clampf(top, -0.85, 1.0)

# Beceriyi besle (d>0) ya da köreltir (d<0). Kilitli beceri öğrenilmez, ama körelebilir.
func ekle(id: String, d: float) -> void:
	if not YET.has(id) or d == 0.0:
		return
	if d > 0.0 and not acik(id):
		return
	var eski := puan(id)
	var yeni_p := clampf(eski + d * (1.0 - eski / 130.0 if d > 0.0 else 1.0), 0.0, 100.0)
	oyun.yet["p"][id] = yeni_p
	if d > 0.0:
		oyun.yet["son"][id] = oyun.tarih()["gun"]
	if seviye(id) > int(eski / 20.0):
		oyun.kayit("Beceri yükseldi: %s (seviye %d)." % [YET[id]["ad"], seviye(id)], "good")
	elif d < 0.0 and int(yeni_p / 20.0) < int(eski / 20.0):
		oyun.kayit("Beceri köreldi: %s (seviye %d)." % [YET[id]["ad"], int(yeni_p / 20.0)], "warn")

func harca(d: Dictionary) -> void:
	for id in d:
		ekle(id, d[id])

func eylem(id: String) -> void:
	if EYLEM.has(id):
		harca(EYLEM[id])

func meslek(j: String) -> void:
	if MESLEK.has(j):
		harca(MESLEK[j])

# Günlük: kullanılmayan beceri yavaşça körelir.
func gun() -> void:
	var g: int = oyun.tarih()["gun"]
	for id in YET:
		var pu := puan(id)
		if pu <= 12.0:
			continue
		var son: int = oyun.yet["son"].get(id, g)
		if g - son > 12:
			oyun.yet["p"][id] = maxf(12.0, pu - 0.25)

# Arayüz için: ["silah", [id,...]]
func dallar() -> Array:
	var r: Array = []
	for d in DAL_SIRA:
		var l: Array = []
		for id in YET:
			if YET[id]["dal"] == d:
				l.append(id)
		r.append([d, l])
	return r
