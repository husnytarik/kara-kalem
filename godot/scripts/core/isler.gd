extends RefCounted
# Kirli işler: adam bulunan mekânlarda (bar, bilardo, boks salonu, dernek) başkalarının pis işleri para karşılığı alınır.
# Ünün büyüdükçe teklifler de büyür: korkutmadan başlar; dövme, yangın, suikast, soygun, kalabalık baskın ve çete çatışmasına uzanır.
# İş ekipten adam(lar) gönderilir; sonuç beceriye, silaha ve ünlendiğin yere bağlıdır. Her iş polis dosyasını ve yol puanını etkiler.

# id -> {ad, kisi, zor[min,max], para[min,max], sure(dk), un(min ün), arama, tan, yol, tier, ac}
const TURLER := {
	"kurye": {"ad": "Paket taşı", "kisi": 1, "zor": [12, 28], "para": [55, 95], "sure": 150, "un": 0.0, "arama": 2.0, "tan": 0.5, "yol": {"golge": 2.0}, "tier": 1,
		"ac": "Kimse sormasın diye bir paketi öbür mahalleye ulaştırmak. İçini merak etme."},
	"korkut": {"ad": "Birini korkut", "kisi": 1, "zor": [18, 34], "para": [70, 120], "sure": 120, "un": 0.0, "arama": 3.0, "tan": 1.0, "yol": {"korku": 2.0}, "tier": 1,
		"ac": "Borcunu ödemeyen ya da ağzı fazla açılan birine gözdağı vermek."},
	"borc": {"ad": "Borç tahsil et", "kisi": 1, "zor": [22, 38], "para": [90, 150], "sure": 180, "un": 5.0, "arama": 2.5, "tan": 1.0, "yol": {"korku": 1.5, "golge": 1.0}, "tier": 1,
		"ac": "Tefecinin alacağını tahsil etmek. Gelirin bir kısmı senin."},
	"dovdur": {"ad": "Dövdür", "kisi": 1, "zor": [34, 50], "para": [160, 260], "sure": 150, "un": 12.0, "arama": 5.0, "tan": 1.5, "yol": {"korku": 3.0}, "tier": 2,
		"ac": "Birine iyi bir ders verilecek. Ölmesin yeter."},
	"yangin": {"ad": "Dükkân kır / yak", "kisi": 2, "zor": [40, 56], "para": [260, 420], "sure": 240, "un": 18.0, "arama": 8.0, "tan": 2.0, "yol": {"korku": 3.0, "golge": 2.0}, "tier": 2,
		"ac": "Bir rakip esnafın dükkânı geceleyin 'kaza' geçirecek."},
	"vur": {"ad": "Birini vur", "kisi": 2, "zor": [55, 72], "para": [650, 1050], "sure": 300, "un": 30.0, "arama": 14.0, "tan": 3.0, "yol": {"korku": 5.0, "golge": 2.0}, "tier": 3,
		"ac": "Bir adamın işi bitirilecek. Tanık bırakma, iz bırakma."},
	"soygun": {"ad": "Kasa soy", "kisi": 3, "zor": [58, 74], "para": [950, 1600], "sure": 360, "un": 35.0, "arama": 15.0, "tan": 3.0, "yol": {"golge": 4.0}, "tier": 3,
		"ac": "Gece yarısı, bir tüccarın kasasına dalınacak. Hızlı ve sessiz."},
	"baskin": {"ad": "Kalabalık baskın", "kisi": 4, "zor": [66, 80], "para": [2100, 3500], "sure": 420, "un": 50.0, "arama": 20.0, "tan": 5.0, "yol": {"korku": 6.0, "golge": 3.0}, "tier": 4,
		"ac": "Rakip bir çetenin deposuna kalabalık bir ekiple baskın. Birçok kişi yaralanabilir."},
	"catisma": {"ad": "Çete çatışması", "kisi": 5, "zor": [74, 88], "para": [4200, 6800], "sure": 480, "un": 65.0, "arama": 26.0, "tan": 7.0, "yol": {"korku": 8.0}, "tier": 4,
		"ac": "İki çete arasındaki hesap bu gece görülecek; seninkiler öne çıkacak. Sokak savaşı."},
}

const HEDEFLER := ["Hoffman", "Kowalski", "Brennan", "Moretti", "Lazar", "O'Dell", "Petrov", "Cohen", "Russo", "Hanlon", "Sullivan", "Bianchi", "Novak", "Grady"]
const ISVEREN := ["Bardaki bir tanıdık", "Sessiz bir adam", "Tefeci çevresinden biri", "Bir tüccar", "Eski bir dost", "Gölgeden biri"]

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"tahta": {}, "tamam": 0, "bozulan": 0}

func _s() -> Dictionary:
	return oyun.isler

# Ünle büyüyen teklif listesi (bir mekânda günlük).
func liste(i: int) -> Array:
	var gun: int = int(oyun.t / oyun.DAY)
	var T: Dictionary = _s()["tahta"]
	var d: Dictionary = T.get(i, {})
	if d.is_empty() or d["gun"] != gun:
		d = {"gun": gun, "l": _uret(i)}
		T[i] = d
	return d["l"]

func _uret(i: int) -> Array:
	var un: float = oyun.kis_k.taninma()
	var uygun: Array = []
	for id in TURLER:
		if un >= TURLER[id]["un"]:
			uygun.append(id)
	var n: int = clampi(1 + int(un / 22.0) + oyun.rng.randi() % 2, 1, 4)
	var bid: String = oyun.harita.yerler[i]["bolge"]
	var l: Array = []
	for k in n:
		# yüksek ünde zor işler daha sık gelir
		var id: String = uygun[oyun.rng.randi() % uygun.size()]
		if oyun.rng.randf() < clampf(un / 120.0, 0.0, 0.5):
			var ust: Array = uygun.filter(func(x): return TURLER[x]["tier"] >= 3)
			if not ust.is_empty():
				id = ust[oyun.rng.randi() % ust.size()]
		var T: Dictionary = TURLER[id]
		var zor: int = T["zor"][0] + oyun.rng.randi() % (T["zor"][1] - T["zor"][0] + 1)
		var para: float = (T["para"][0] + oyun.rng.randf() * (T["para"][1] - T["para"][0])) * (1.0 + un / 160.0)
		var pusu := -1
		if T["tier"] >= 2 and T["tier"] <= 3 and oyun.rng.randf() < 0.5:
			var ks: Array = []
			for q in oyun.harita.yerler.size():
				if oyun.harita.yerler[q]["bolge"] == bid and oyun.pazar_k.konak_mi(q):
					ks.append(q)
			if not ks.is_empty():
				pusu = ks[oyun.rng.randi() % ks.size()]
		l.append({"id": id, "pusu": pusu, "zor": zor, "para": roundf(para / 5.0) * 5.0, "bid": bid,
			"hedef": HEDEFLER[oyun.rng.randi() % HEDEFLER.size()], "veren": ISVEREN[oyun.rng.randi() % ISVEREN.size()]})
	return l

func baslik(j: Dictionary) -> String:
	return "%s: %s" % [TURLER[j["id"]]["ad"], j["hedef"]]

func risk_yazi(j: Dictionary) -> String:
	var z: int = j["zor"]
	return "Kolay" if z < 30 else ("Orta" if z < 50 else ("Zor" if z < 70 else "Çok zor"))

# Pusu: hedefin uğrayacağı otelde bekle; kendin vurursun (adam gerekmez, ödeme %25 fazla, yara riski sende).
func pusu_kur(i: int, idx: int) -> Dictionary:
	var l: Array = liste(i)
	if idx < 0 or idx >= l.size() or l[idx].get("pusu", -1) < 0:
		return oyun.hata("Bu teklifte pusu yok.")
	var j: Dictionary = l[idx]
	_s()["pusu"] = {"is": j, "bina": j["pusu"], "bitis": oyun.t + 2 * oyun.DAY}
	l.remove_at(idx)
	oyun.kayit("Pusu: hedef (%s) %s civarında görülebilir. İki gün içinde orada kalıp bekle." % [j["hedef"], oyun.harita.yerler[j["pusu"]]["ad"]], "info")
	oyun.degisti.emit()
	return oyun.tamam("Pusu kuruldu: %s." % oyun.harita.yerler[j["pusu"]]["ad"])

func pusu_var(bina: int) -> bool:
	var p: Dictionary = _s().get("pusu", {})
	return not p.is_empty() and p["bina"] == bina and oyun.t < p["bitis"]

# Otelde 2 saat bekle; hedef gelirse sen vurursun.
func pusu_bekle(bina: int) -> Dictionary:
	var p: Dictionary = _s().get("pusu", {})
	if p.is_empty() or p["bina"] != bina:
		return oyun.hata("Burada kurulu bir pusun yok.")
	oyun.bekle(120)
	if oyun.t >= p["bitis"]:
		_s()["pusu"] = {}
		oyun.kayit("Hedef hiç gelmedi; pusu boşa gitti.", "warn")
		return oyun.hata("Hedef gelmedi, süre doldu.")
	var gece: bool = oyun.tarih()["saat"] >= 20 or oyun.tarih()["saat"] < 5
	if oyun.rng.randf() > (0.4 if gece else 0.22):
		return oyun.tamam("Pencere başında bekledin; hedef henüz görünmedi.")
	var j: Dictionary = p["is"]
	var T: Dictionary = TURLER[j["id"]]
	var pw: float = clampf(0.55 + {"yumruk": 0.0, "bicak": 0.05, "tabanca": 0.1, "pompali": 0.15, "tommy": 0.15}.get(oyun.oyuncu_silah, 0.0) - (j["zor"] - 40) / 100.0, 0.2, 0.9) * oyun.kis_k.form()
	_s()["pusu"] = {}
	var b: Dictionary = oyun.bolge[j["bid"]]
	if oyun.rng.randf() < pw:
		var para: float = j["para"] * 1.25
		oyun.kirli += para
		oyun.arama = minf(100.0, oyun.arama + T["arama"] * 0.6 * 0.8 * oyun.yol_k.arama_carpan())
		b["tan"] = clampf(b["tan"] + T["tan"], 0.0, 100.0)
		for y in T["yol"]:
			oyun.yol_k.ekle(y, T["yol"][y])
		oyun.yol_k.ekle("kanun", -T["tier"] * 1.5)
		_s()["tamam"] += 1
		oyun.kayit("Pusu tuttu: %s (%s) işi bitti, %s kazandın." % [T["ad"], j["hedef"], oyun.para(para)], "good")
		return oyun.tamam("Hedef geldi ve işi bitirdin: %s." % oyun.para(para))
	oyun.arama = minf(100.0, oyun.arama + T["arama"] * 0.6 * 1.4 * oyun.yol_k.arama_carpan())
	oyun.kis_k.yara_ekle(20.0 + oyun.rng.randf() * 15.0)
	oyun.kayit("Pusu ters gitti: hedef seni fark etti, yaralı kaçtın.", "bad")
	return oyun.hata("Pusu ters gitti. Yaralandın, dosya kabardı.")

# En becerikli boşta adamlar
func _ekip(kisi: int) -> Array:
	var bos: Array = oyun.bos_adamlar()
	bos.sort_custom(func(a, b): return oyun.beceri(a) > oyun.beceri(b))
	return bos.slice(0, kisi)

func kabul(i: int, idx: int) -> Dictionary:
	var l: Array = liste(i)
	if idx < 0 or idx >= l.size():
		return oyun.hata("Bu teklif artık yok.")
	var j: Dictionary = l[idx]
	var T: Dictionary = TURLER[j["id"]]
	var bos: Array = oyun.bos_adamlar()
	if bos.size() < T["kisi"]:
		return oyun.hata("Bu iş için %d boşta adam lazım (şu an %d)." % [T["kisi"], bos.size()])
	var ekip := _ekip(T["kisi"])
	var ids: Array = []
	var adlar: Array = []
	for a in ekip:
		a["gorev"] = "sozlesme"
		ids.append(a["id"])
		adlar.append(a["ad"])
	l.remove_at(idx)
	oyun.gorevler.append({"adam": ids[0], "adamlar": ids, "hedef": -1, "gorev": "sozlesme", "is": j, "basla": oyun.t, "yol": 0,
		"bitis": oyun.t + T["sure"], "yolu": PackedVector3Array()})
	oyun.kayit("%s işi: %s yola çıktı (%s)." % [T["ad"], ", ".join(adlar), baslik(j)], "info")
	oyun.degisti.emit()
	return oyun.tamam("İş verildi: %s." % ", ".join(adlar))

# Süre dolunca sonuç.
func coz(g: Dictionary) -> void:
	var j: Dictionary = g["is"]
	var T: Dictionary = TURLER[j["id"]]
	var ekip: Array = []
	for id in g["adamlar"]:
		var a: Dictionary = oyun.adam_bul(id)
		if not a.is_empty():
			ekip.append(a)
	if ekip.is_empty():
		return
	var toplam := 0.0
	var silah_b := 0.0
	for a in ekip:
		toplam += oyun.beceri(a)
		silah_b += {"yumruk": 0.0, "bicak": 0.03, "tabanca": 0.06, "pompali": 0.1, "tommy": 0.12}.get(a.get("silah", "yumruk"), 0.0)
	var ort: float = toplam / ekip.size()
	var b: Dictionary = oyun.bolge[j["bid"]]
	var pw: float = clampf(0.4 + (ort - j["zor"]) / 55.0 + silah_b / ekip.size() + 0.08 * (ekip.size() - T["kisi"]) + 0.0015 * b["tan"], 0.08, 0.95) * oyun.kis_k.form()
	var ok: bool = oyun.rng.randf() < pw
	var ad: String = T["ad"]
	var arama_c: float = oyun.yol_k.arama_carpan()
	var yazi := ""
	var bulas: Dictionary = {"borc": ["tifus", 0.05], "dovdur": ["ates", 0.08], "yangin": ["zaturre", 0.15], "baskin": ["tifus", 0.1], "catisma": ["ates", 0.12], "soygun": ["grip", 0.05], "kurye": ["grip", 0.03]}
	if bulas.has(j["id"]):
		oyun.kis_k.bulas_dene(bulas[j["id"]][0], bulas[j["id"]][1], "iş sırasında: " + T["ad"])
	for a in ekip:
		a["gorev"] = ""
	if ok:
		var para: float = j["para"]
		oyun.kirli += para
		oyun.arama = minf(100.0, oyun.arama + T["arama"] * 0.6 * arama_c)
		b["tan"] = clampf(b["tan"] + T["tan"], 0.0, 100.0)
		b["kor"] = clampf(b["kor"] + T["tan"] * 0.6, 0.0, 100.0)
		b["sev"] = clampf(b["sev"] - T["tan"] * 0.5, 0.0, 100.0)
		for y in T["yol"]:
			oyun.yol_k.ekle(y, T["yol"][y])
		oyun.yol_k.ekle("kanun", -T["tier"] * 1.5)
		_s()["tamam"] += 1
		# bazı işlerde adam yara alır; büyük işlerde ölebilir
		for a in ekip.duplicate():
			var r: float = oyun.rng.randf()
			if r < 0.04 * T["tier"] * T["tier"] * 0.25 + 0.03 * (T["tier"] - 1) and T["tier"] >= 3:
				oyun.adamlar.erase(a)
				ekip.erase(a)
				yazi += " %s hayatını kaybetti." % a["ad"]
			elif r < 0.12 + 0.05 * T["tier"]:
				oyun.yarala(a, 1 + oyun.rng.randi() % 3)
				yazi += " %s yaralandı." % a["ad"]
		oyun.kayit("%s tamam (%s): %s kazandın.%s" % [ad, j["hedef"], oyun.para(para), yazi], "good")
	else:
		oyun.arama = minf(100.0, oyun.arama + T["arama"] * 0.6 * 1.5 * arama_c)
		_s()["bozulan"] += 1
		for a in ekip.duplicate():
			var r2: float = oyun.rng.randf()
			if r2 < 0.1 * T["tier"] and T["tier"] >= 2:
				oyun.adamlar.erase(a)
				ekip.erase(a)
				yazi += " %s dönmedi." % a["ad"]
			elif r2 < 0.35 + 0.1 * T["tier"]:
				if oyun.rng.randf() < 0.5:
					oyun.yarala(a, 1 + oyun.rng.randi() % 3)
					yazi += " %s yaralandı." % a["ad"]
				else:
					a["gorev"] = "tutuklu"
					oyun.gorevler.append({"adam": a["id"], "hedef": -1, "gorev": "tutuklu", "basla": oyun.t, "yol": 0, "bitis": oyun.t + 3 * oyun.DAY, "yolu": PackedVector3Array()})
					yazi += " %s karakola düştü." % a["ad"]
		oyun.kayit("%s ters gitti (%s): para yok, dosya kabardı.%s" % [ad, j["hedef"], yazi], "bad")
