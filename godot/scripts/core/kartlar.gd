extends RefCounted
# Karar kartları: oyun sana düzenli aralıklarla bir ikilem getirir. Her kartta farklı yollardan (yasal / gölge /
# korku / kulis) çözüm vardır; her çözümün bedeli, riski ve iz bıraktığı yer farklıdır. Seçimlerin yol puanını
# (yol.gd) büyütür, yol seviyesi de oyuna somut avantaj verir. Dönem (hava) hangi seçimin işlediğini değiştirir.

var oyun: Node
var Y: RefCounted

# id -> [başlık, ağırlık, bekleme(gün), tek sefer]
const KARTLAR := {
	"dolan": ["Dolan kapıda", 10, 12, false],
	"esnaf": ["Esnaf şikâyeti", 8, 10, false],
	"ihale": ["Belediye ihalesi", 7, 15, false],
	"tefeci": ["Tefecinin adamı", 8, 12, false],
	"muhbir": ["Muhbir", 7, 12, false],
	"gazeteci": ["Gazeteci", 6, 20, false],
	"senlik": ["Mahalle şenliği", 6, 12, false],
	"ittifak": ["Aile teklifi", 6, 20, false],
	"baskin": ["Baskın ihbarı", 9, 14, false],
	"secim": ["Belediye seçimi", 5, 30, false],
}

# Seçimlerin karaktere işlediği huylar: "kartid+seçenek" -> {özellik: artış}
const OZ_SEC := {
	"dolan0": {"dilbaz": 3, "polis_dostu": 2}, "dolan1": {"gizli": 3}, "dolan2": {"sert_bakis": 3, "sinirli": 1}, "dolan3": {"mahalleli": 2, "vicdanli": 1},
	"esnaf0": {"sert_bakis": 3, "kavgaci": 1}, "esnaf1": {"gizli": 3, "acimasiz": 1}, "esnaf2": {"mahalleli": 3, "vicdanli": 1}, "esnaf3": {"dilbaz": 3, "cilveli": 1},
	"ihale0": {"hesapci": 3}, "ihale1": {"dilbaz": 3, "polis_dostu": 1}, "ihale2": {"acimasiz": 2, "sert_bakis": 2},
	"tefeci0": {"hesapci": 2}, "tefeci1": {"dilbaz": 3, "cilveli": 2}, "tefeci2": {"sert_bakis": 3, "acimasiz": 2},
	"muhbir0": {"muhbir_agi": 3, "polis_dostu": 1}, "muhbir1": {"gizli": 3, "dilbaz": 1}, "muhbir2": {"acimasiz": 3, "sert_bakis": 2},
	"gazeteci0": {"cilveli": 3, "mahalleli": 1}, "gazeteci1": {"dilbaz": 2, "polis_dostu": 1}, "gazeteci2": {"gizli": 2, "muhbir_agi": 1}, "gazeteci3": {"sert_bakis": 3},
	"senlik0": {"comert": 4, "mahalleli": 2}, "senlik1": {"cimri": 2, "sert_bakis": 2}, "senlik2": {"gizli": 2, "cimri": 2}, "senlik3": {"dilbaz": 2, "polis_dostu": 1},
	"ittifak0": {"cilveli": 3, "dilbaz": 1}, "ittifak1": {"sert_bakis": 3, "sinirli": 1}, "ittifak2": {"gizli": 2, "korkak": 2},
	"baskin0": {"gizli": 3, "korkak": 1}, "baskin1": {"polis_dostu": 3, "dilbaz": 2}, "baskin2": {"hesapci": 2, "mahalleli": 1}, "baskin3": {"kavgaci": 3, "sinirli": 2},
	"secim0": {"mahalleli": 2, "vicdanli": 2}, "secim1": {"dilbaz": 3, "polis_dostu": 2}, "secim2": {"acimasiz": 3, "sinirli": 2},
}

var _bolge := ""      # kartın ilgili bölgesi
var _aile := ""       # kartın ilgili ailesi

func _init(o: Node) -> void:
	oyun = o
	Y = o.yol_k

func baslik(id: String) -> String:
	return KARTLAR[id][0]

func uygun(id: String) -> bool:
	var y: Dictionary = oyun.yol
	if KARTLAR[id][1] == 0:
		return false
	if y["once"].has(id):
		return false
	if oyun.t < y["cool"].get(id, -99999):
		return false
	match id:
		"dolan":
			return oyun.arama >= 20.0
		"esnaf":
			return not oyun.isy.keys().filter(func(i): return oyun.isy[i]["haracli"] or oyun.isy[i]["sahip"]).is_empty()
		"ihale":
			return oyun.temiz >= 60.0
		"tefeci":
			return oyun.borc.get("ana", 0.0) > 0.0
		"muhbir":
			return oyun.arama >= 15.0
		"gazeteci":
			return oyun.arama >= 25.0 or Y.ana() != ""
		"ittifak":
			return not oyun.oyuncu_bolgeleri().is_empty()
		"baskin":
			return oyun.arama >= 40.0 or oyun.pol["kurulu"]
		"secim":
			return Y.puan("kulis") >= 15.0 or Y.puan("kanun") >= 15.0
	return true

# Ağırlıklı seçim; yola uygun kartlar biraz öne çıkar.
func cek() -> String:
	if oyun.rng.randf() > 0.55:
		return ""
	var adaylar: Array = []
	var top := 0
	for id in KARTLAR:
		if uygun(id):
			adaylar.append(id)
			top += KARTLAR[id][1]
	if adaylar.is_empty():
		return ""
	var r: int = oyun.rng.randi() % top
	for id in adaylar:
		r -= KARTLAR[id][1]
		if r < 0:
			return id
	return adaylar[0]

# Kart açılırken ilgili bölge/aile belirlenir.
func hazirla(id: String) -> void:
	_bolge = ""
	_aile = ""
	var idler: Array = oyun.harita.bolgeler.keys()
	_bolge = idler[oyun.rng.randi() % idler.size()]
	_aile = oyun.NPC[oyun.rng.randi() % oyun.NPC.size()]
	if id == "esnaf" and not oyun.isy.keys().filter(func(i): return oyun.isy[i]["haracli"] or oyun.isy[i]["sahip"]).is_empty():
		var hl: Array = oyun.isy.keys().filter(func(i): return oyun.isy[i]["haracli"] or oyun.isy[i]["sahip"])
		_bolge = oyun.harita.yerler[hl[oyun.rng.randi() % hl.size()]]["bolge"]

func _bad(b: String) -> String:
	return oyun.harita.bolgeler[b]["ad"]

func _fad() -> String:
	return oyun.FAK[_aile]["ad"]

func metin(id: String) -> String:
	match id:
		"yol_sec":
			return "Babanın borcu, boş bir cep, bir şehir. Büyümek için bir yol seçmelisin. Hepsi ayrı bir kapı; hiçbiri sonsuza kadar açık değil. Seçtiğin yolun puanı artar, bırakırsan solar."
		"dolan":
			return "Komiser Dolan masanın başına geçti. Dosyanın kalınlığını gösteriyor: \"Bunu kapatmanın bir yolu var, ya da kapatmamanın.\""
		"esnaf":
			return "%s'daki esnaf yakınıyor: %s'ın adamları da gelip para istiyormuş. \"İki ağaya birden ödeyemem. Sen çöz.\"" % [_bad(_bolge), _fad()]
		"ihale":
			return "Belediye sokak taşı ve kaldırım ihalesi açtı. Küçük bir iş; ama kazanan hem para hem isim kazanır."
		"tefeci":
			return "Sal'ın tefeci adamı kapıya dayandı: \"Taksitler gecikiyor. Patron sabırsız.\""
		"muhbir":
			return "Karakolda çalışan tanıdık biri fısıldıyor: \"Dosyanda yeni bir şeyler var. Bilgi istiyorsan konuşalım.\""
		"gazeteci":
			return "Bir gazeteci, Boston Evening'den, seni sorup duruyor. Kuzey Mahalle'de adını duymuş."
		"senlik":
			return "%s'da mahalle şenliği hazırlanıyor. Herkes bir şey bekliyor." % _bad(_bolge)
		"ittifak":
			return "%s'ın elçisi sana geldi: \"İki taraf da kan istemiyor. Bir anlaşma yapalım, ya da karşı çıkalım.\"" % _fad()
		"baskin":
			return "Kapıda bir çocuk: \"Polis bu gece baskın yapacak diyorlar.\" Elinde olan her şey tehlikede."
		"secim":
			return "Belediye seçimi geliyor. İki aday da senin mahallede destek arıyor."
	return ""

# Seçenek: {ad, ipucu, can:bool}
func secenekler(id: String) -> Array:
	var tm: float = oyun.temiz
	var kt: float = oyun.temiz + oyun.kirli
	match id:
		"yol_sec":
			return [
				{"ad": "Yasal yol", "ipucu": "+$150 temiz, Yasal +30. Dürüst iş, esnaf sever.", "can": true},
				{"ad": "Gölge yolu", "ipucu": "+$100 kirli, Gölge +30. İz bırakmadan çalış.", "can": true},
				{"ad": "Korku yolu", "ipucu": "+$80 kirli, Korku +30. Sert ol, söz geçir.", "can": true},
				{"ad": "Kulis yolu", "ipucu": "+$100 temiz, Kulis +30. İlişkiler, zarflar.", "can": true},
			]
		"dolan":
			return [
				{"ad": "Zarf ver ($80)", "ipucu": "Dosya −15, Kulis +8. Reform döneminde riskli.", "can": kt >= 80.0},
				{"ad": "Evrakları sakla", "ipucu": "%55 şans: Dosya −10, Gölge +6. Yoksa Dosya +10.", "can": true},
				{"ad": "Gözünü korkut", "ipucu": "Dosya +5, Korku +8. %60: sessiz kalır.", "can": true},
				{"ad": "Dürüst konuş", "ipucu": "Yasal +6. Dosya −5 (kanun yolu güçlüyse −8).", "can": true},
			]
		"esnaf":
			return [
				{"ad": "Rakibin adamını korkut", "ipucu": "%s ile gerginlik +4, Korku +8, bölgede sevgi −2." % oyun.FAK[_aile]["ad"], "can": true},
				{"ad": "Gizlice zarar ver", "ipucu": "%55: gerginlik yok, nüfuz −3. Yoksa gerginlik +5, Gölge −3.", "can": true},
				{"ad": "Belediyeye dilekçe", "ipucu": "Yasal +6, bölgede huzur +3.", "can": true},
				{"ad": "Aracı ayarla ($40)", "ipucu": "Kulis +6, gerginlik −2.", "can": kt >= 40.0},
			]
		"ihale":
			return [
				{"ad": "Dürüst teklif ($150)", "ipucu": "%70 kazanırsın: +$350 temiz, Yasal +8.", "can": tm >= 150.0},
				{"ad": "Zarf ver ($120)", "ipucu": "%85 kazanırsın: +$450 temiz, Kulis +8, Dosya +5.", "can": kt >= 120.0},
				{"ad": "Rakipleri sindir", "ipucu": "%60: +$300 kirli, Korku +8. Dosya +8.", "can": true},
				{"ad": "Geç", "ipucu": "Hiçbir şey olmaz.", "can": true},
			]
		"tefeci":
			return [
				{"ad": "Ek ödeme yap ($100)", "ipucu": "Borç −$100. Yasal +4.", "can": tm >= 100.0},
				{"ad": "Tatlı dille oyala", "ipucu": "Kulis +6. %50: bir sonraki taksit hafifler (borç −$60).", "can": true},
				{"ad": "Adamını korkut", "ipucu": "%50: borç −$150 silinir, Korku +8. Yoksa Dosya +5.", "can": true},
			]
		"muhbir":
			return [
				{"ad": "Bilgi al ($60)", "ipucu": "Dosya −10, Kulis +5.", "can": kt >= 60.0},
				{"ad": "Yalan bilgi besle", "ipucu": "%55: Dosya −12, Gölge +6. Yoksa Dosya +8.", "can": true},
				{"ad": "Muhbiri dövdür", "ipucu": "Korku +8, Dosya +6, Dosya −12 (%60 sessiz kalır).", "can": true},
				{"ad": "Yok say", "ipucu": "Hiçbir şey olmaz.", "can": true},
			]
		"gazeteci":
			return [
				{"ad": "Röportaj ver", "ipucu": "Yasal +6, sevgi +2 (bir bölgede). Dosya +3.", "can": true},
				{"ad": "Haberi gömdür ($100)", "ipucu": "Dosya −8, Kulis +6.", "can": kt >= 100.0},
				{"ad": "Rakibe yönlendir", "ipucu": "Gölge +6. Aile ile gerginlik +3.", "can": true},
				{"ad": "Korkut", "ipucu": "Korku +6, Dosya +8.", "can": true},
			]
		"senlik":
			return [
				{"ad": "Bağış yap ($60)", "ipucu": "Yasal +6. Bölgede sevgi +5, huzur +3.", "can": tm >= 60.0},
				{"ad": "Esnaftan \"katkı\" topla", "ipucu": "+$80 kirli, Korku +6, sevgi −3.", "can": true},
				{"ad": "Parayı kes", "ipucu": "+$50 kirli, Gölge +4. %30 yakalanırsın: Dosya +8.", "can": true},
				{"ad": "Belediye üzerinden sponsor ($40)", "ipucu": "Kulis +6, sevgi +2.", "can": kt >= 40.0},
			]
		"ittifak":
			return [
				{"ad": "Anlaş", "ipucu": "%s ile gerginlik −6, Kulis +6." % oyun.FAK[_aile]["ad"], "can": true},
				{"ad": "Reddet, gözdağı ver", "ipucu": "Gerginlik +4, Korku +8.", "can": true},
				{"ad": "Oyalama", "ipucu": "Gölge +4. Gerginlik −1.", "can": true},
			]
		"baskin":
			return [
				{"ad": "Malı sakla", "ipucu": "Gölge +6. (Bodrum kuruluysa: 3 gün üretim durur.)", "can": true},
				{"ad": "Dolan'a haber ver ($100)", "ipucu": "%65: baskın iptal, Dosya −10, Kulis +6. Yoksa para boşa.", "can": kt >= 100.0},
				{"ad": "Her şeyi bırak, kal", "ipucu": "Yasal +4. Elinde temiz olan yok sayılır.", "can": true},
				{"ad": "Karşı koymaya hazırlan", "ipucu": "Korku +8, Dosya +8.", "can": true},
			]
		"secim":
			return [
				{"ad": "Reformcu adayı destekle ($150)", "ipucu": "%60: Reform dönemi başlar, Yasal +10.", "can": tm >= 150.0},
				{"ad": "Yolsuz adayı destekle ($150)", "ipucu": "%60: Kulis +12, Dosya −8. Yoksa Dosya +8.", "can": kt >= 150.0},
				{"ad": "Seçimi sabote et", "ipucu": "Korku +6, Gölge +6. Çete yılı başlar.", "can": true},
				{"ad": "Tarafsız kal", "ipucu": "Hiçbir şey olmaz.", "can": true},
			]
	return []

# Seçimi uygular -> {metin, tur}
func uygula(id: String, n: int) -> Dictionary:
	var y: Dictionary = oyun.yol
	var r: Dictionary = _coz(id, n)
	var K: RefCounted = oyun.kis_k
	var oz: Dictionary = OZ_SEC.get(id + str(n), {})
	for o in oz:
		K.oz_ekle(o, oz[o])
	K.degis("sikinti", -12.0)
	match r["tur"]:
		"bad": K.stres_ekle(7.0)
		"warn": K.stres_ekle(3.0)
		"good": K.degis("stres", -3.0)
	y["bekleyen"] = ""
	y["cool"][id] = oyun.t + KARTLAR[id][2] * oyun.DAY
	if KARTLAR[id][3]:
		y["once"][id] = true
	oyun.kayit("%s: %s" % [KARTLAR[id][0], r["metin"]], r["tur"])
	oyun.degisti.emit()
	return r

func _r(m: String, t: String = "info") -> Dictionary:
	return {"metin": m, "tur": t}

func _sans(p: float) -> bool:
	return oyun.rng.randf() < clampf(p, 0.05, 0.95)

func _dosya(d: float) -> void:
	if d > 0.0:
		d *= Y.arama_carpan()
	oyun.arama = clampf(oyun.arama + d, 0.0, 100.0)

func _coz(id: String, n: int) -> Dictionary:
	var B: Dictionary = oyun.bolge[_bolge] if _bolge != "" else {}
	match id:
		"yol_sec":
			match n:
				0:
					oyun.temiz += 150.0
					Y.ekle("kanun", 30.0)
					return _r("Dürüst yolu seçtin. +$150 temiz.", "good")
				1:
					oyun.kirli += 100.0
					Y.ekle("golge", 30.0)
					return _r("Gölgede çalışmayı seçtin. +$100 kirli.", "good")
				2:
					oyun.kirli += 80.0
					Y.ekle("korku", 30.0)
					return _r("Sert yolu seçtin. +$80 kirli.", "good")
				_:
					oyun.temiz += 100.0
					Y.ekle("kulis", 30.0)
					return _r("İlişki yolunu seçtin. +$100 temiz.", "good")
		"dolan":
			match n:
				0:
					var p: float = 0.8 + 0.15 * Y.etki("kulis")
					oyun.harcama(80.0 * Y.rusvet_carpan(), "kirli")
					if _sans(p):
						oyun.arama = maxf(0.0, oyun.arama - 15.0)
						Y.ekle("kulis", 8.0)
						return _r("Dolan zarfı aldı. Dosya −15.", "good")
					oyun.arama = minf(100.0, oyun.arama + 5.0)
					return _r("Dolan zarfı aldı ama dosyayı kapatmadı. Dosya +5.", "bad")
				1:
					if _sans(0.55 + 0.1 * Y.etki("golge")):
						oyun.arama = maxf(0.0, oyun.arama - 10.0)
						Y.ekle("golge", 6.0)
						return _r("Evrakları kimse bulamadı. Dosya −10.", "good")
					_dosya(10.0)
					return _r("Evrakları sakladığını anladılar. Dosya +10.", "bad")
				2:
					_dosya(5.0)
					Y.ekle("korku", 8.0)
					if _sans(0.6):
						return _r("Dolan geri çekildi. Bir süre sesi çıkmaz.", "good")
					oyun.arama = minf(100.0, oyun.arama + 6.0)
					return _r("Dolan sinirlendi. Dosya daha da kabardı.", "bad")
				_:
					Y.ekle("kanun", 6.0)
					var e := 8.0 if Y.seviye("kanun") >= 1 else 5.0
					oyun.arama = maxf(0.0, oyun.arama - e)
					return _r("Dolan elinde bir şey bulamadı. Dosya −%d." % int(e), "good")
		"esnaf":
			match n:
				0:
					oyun.gerginlik.ekle("oyuncu", _aile, 4.0, "esnaf için")
					Y.ekle("korku", 8.0)
					B["sev"] = maxf(0.0, B["sev"] - 2.0)
					return _r("%s'ın adamları bir daha uğramadı. Ama gerginlik arttı." % _fad(), "warn")
				1:
					if _sans(0.55 + 0.1 * Y.etki("golge")):
						oyun.add_inf(B, _aile, -3.0)
						Y.ekle("golge", 6.0)
						return _r("Bir gece %s'ın tahsildarı \"yolda kayboldu\". Kimse seni sormadı." % _fad(), "good")
					oyun.gerginlik.ekle("oyuncu", _aile, 5.0, "esnaf için")
					Y.ekle("golge", -3.0)
					return _r("Gizli iş açığa çıktı. %s seni biliyor." % _fad(), "bad")
				2:
					Y.ekle("kanun", 6.0)
					B["huzur"] = minf(100.0, B["huzur"] + 3.0)
					return _r("Belediye gelen dilekçeyi kayda aldı. Mahalle sana güveniyor.", "good")
				_:
					oyun.harcama(40.0, "kirli")
					Y.ekle("kulis", 6.0)
					oyun.gerginlik.ekle("oyuncu", _aile, -2.0, "")
					return _r("%s'la bir aracı üzerinden anlaştın." % _fad(), "good")
		"ihale":
			match n:
				0:
					oyun.harcama(150.0, "temiz")
					if _sans(0.7 + 0.1 * Y.etki("kanun")):
						oyun.yasal(350.0)
						Y.ekle("kanun", 8.0)
						return _r("İhaleyi aldın. +$350 temiz.", "good")
					return _r("İhaleyi başkası aldı. Para kayboldu.", "bad")
				1:
					oyun.harcama(120.0 * Y.rusvet_carpan(), "kirli")
					_dosya(5.0)
					if _sans(0.85 + 0.1 * Y.etki("kulis")):
						oyun.yasal(450.0)
						Y.ekle("kulis", 8.0)
						return _r("İhaleyi aldın. +$450 temiz.", "good")
					return _r("Zarf alındı ama ihale gitti.", "bad")
				2:
					_dosya(8.0)
					Y.ekle("korku", 8.0)
					if _sans(0.6 + 0.1 * Y.etki("korku")):
						oyun.kirli += 300.0
						return _r("Rakipler çekildi. İş senin: +$300 kirli.", "good")
					return _r("Rakipler seni ihbar etti. Dosya +8.", "bad")
				_:
					return _r("Geçtin.")
		"tefeci":
			match n:
				0:
					oyun.borc_k.ode(100.0)
					Y.ekle("kanun", 4.0)
					return _r("Tefeci sakinleşti.", "good")
				1:
					Y.ekle("kulis", 6.0)
					if _sans(0.5):
						oyun.borc["ana"] = maxf(0.0, oyun.borc["ana"] - 60.0)
						return _r("Tefeci bir miktarını sildi (−$60).", "good")
					return _r("Tefeci bu kez ikna oldu; ama unutmayacak.", "warn")
				_:
					Y.ekle("korku", 8.0)
					if _sans(0.5 + 0.1 * Y.etki("korku")):
						oyun.borc["ana"] = maxf(0.0, oyun.borc["ana"] - 150.0)
						return _r("Tefecinin adamı bir daha gelmedi (borç −$150).", "good")
					_dosya(5.0)
					return _r("Tefeci seni şikâyet etti. Dosya +5.", "bad")
		"muhbir":
			match n:
				0:
					oyun.harcama(60.0 * Y.rusvet_carpan(), "kirli")
					oyun.arama = maxf(0.0, oyun.arama - 10.0)
					Y.ekle("kulis", 5.0)
					return _r("Dosyadaki bir kısım silindi. Dosya −10.", "good")
				1:
					if _sans(0.55 + 0.1 * Y.etki("golge")):
						oyun.arama = maxf(0.0, oyun.arama - 12.0)
						Y.ekle("golge", 6.0)
						return _r("Polis yanlış yere baktı. Dosya −12.", "good")
					_dosya(8.0)
					return _r("Yalan açığa çıktı. Dosya +8.", "bad")
				2:
					Y.ekle("korku", 8.0)
					_dosya(6.0)
					if _sans(0.6):
						oyun.arama = maxf(0.0, oyun.arama - 12.0)
						return _r("Muhbir sustu, işi yarım bıraktı. Dosya düştü.", "good")
					return _r("Muhbir polise koştu.", "bad")
				_:
					return _r("Yok saydın.")
		"gazeteci":
			match n:
				0:
					Y.ekle("kanun", 6.0)
					_dosya(3.0)
					B["sev"] = minf(100.0, B["sev"] + 2.0)
					return _r("Haber olumlu çıktı. Mahalle seni seviyor.", "good")
				1:
					oyun.harcama(100.0 * Y.rusvet_carpan(), "kirli")
					oyun.arama = maxf(0.0, oyun.arama - 8.0)
					Y.ekle("kulis", 6.0)
					return _r("Haber çöpe gitti. Dosya −8.", "good")
				2:
					Y.ekle("golge", 6.0)
					oyun.gerginlik.ekle(_aile, oyun.NPC[(oyun.NPC.find(_aile) + 1) % oyun.NPC.size()], 3.0, "gazete")
					return _r("Haber başkasının kapısına yöneldi. Aileler birbirini suçluyor.", "good")
				_:
					Y.ekle("korku", 6.0)
					_dosya(8.0)
					return _r("Gazeteci sustu; ama birkaç yazar daha dikkat kesildi.", "warn")
		"senlik":
			match n:
				0:
					oyun.harcama(60.0, "temiz")
					Y.ekle("kanun", 6.0)
					B["sev"] = minf(100.0, B["sev"] + 5.0)
					B["huzur"] = minf(100.0, B["huzur"] + 3.0)
					return _r("Şenlik coşkulu geçti. %s sevdi seni." % _bad(_bolge), "good")
				1:
					oyun.kirli += 80.0
					Y.ekle("korku", 6.0)
					B["sev"] = maxf(0.0, B["sev"] - 3.0)
					return _r("Esnaf katkı verdi, ama dudak büktü. +$80 kirli.", "warn")
				2:
					oyun.kirli += 50.0
					Y.ekle("golge", 4.0)
					if _sans(0.3 - 0.1 * Y.etki("golge")):
						_dosya(8.0)
						return _r("Birisi parayı fark etti. Dosya +8.", "bad")
					return _r("Kimse fark etmedi. +$50 kirli.", "good")
				_:
					oyun.harcama(40.0, "kirli")
					Y.ekle("kulis", 6.0)
					B["sev"] = minf(100.0, B["sev"] + 2.0)
					return _r("Belediye masrafı üstlendi, sen alkışı aldın.", "good")
		"ittifak":
			match n:
				0:
					oyun.gerginlik.ekle("oyuncu", _aile, -6.0, "")
					Y.ekle("kulis", 6.0)
					return _r("%s ile bir süre savaş yok." % _fad(), "good")
				1:
					oyun.gerginlik.ekle("oyuncu", _aile, 4.0, "gözdağı")
					Y.ekle("korku", 8.0)
					return _r("%s elçisi sinirle çıktı." % _fad(), "warn")
				_:
					oyun.gerginlik.ekle("oyuncu", _aile, -1.0, "")
					Y.ekle("golge", 4.0)
					return _r("Bir şey vaat etmeden oyaladın.")
		"baskin":
			match n:
				0:
					Y.ekle("golge", 6.0)
					if oyun.pol["kurulu"]:
						oyun.polis.sakla()
					return _r("Mallar saklandı. Baskın boşa gitti.", "good")
				1:
					oyun.harcama(100.0 * Y.rusvet_carpan(), "kirli")
					if _sans(0.65 + 0.1 * Y.etki("kulis")):
						oyun.arama = maxf(0.0, oyun.arama - 10.0)
						Y.ekle("kulis", 6.0)
						oyun.pol["baskin"] = 0
						return _r("Baskın iptal edildi. Dosya −10.", "good")
					return _r("Haber alamadın; para boşa.", "bad")
				2:
					Y.ekle("kanun", 4.0)
					return _r("Temiz işini gösterdin; baskın seni pek ilgilendirmedi.", "good")
				_:
					Y.ekle("korku", 8.0)
					_dosya(8.0)
					return _r("Adamlar silahlandı. Şehir gerildi.", "warn")
		"secim":
			match n:
				0:
					oyun.harcama(150.0, "temiz")
					if _sans(0.6):
						Y.ekle("kanun", 10.0)
						y_donem("reform")
						return _r("Reformcu aday kazandı: reform dalgası başlıyor.", "good")
					return _r("Aday kaybetti. Para gitti.", "bad")
				1:
					oyun.harcama(150.0 * Y.rusvet_carpan(), "kirli")
					if _sans(0.6 + 0.1 * Y.etki("kulis")):
						Y.ekle("kulis", 12.0)
						oyun.arama = maxf(0.0, oyun.arama - 8.0)
						return _r("Aday kazandı, sana borçlu. Dosya −8.", "good")
					_dosya(8.0)
					return _r("Aday kaybetti. İhbar geldi. Dosya +8.", "bad")
				2:
					Y.ekle("korku", 6.0)
					Y.ekle("golge", 6.0)
					y_donem("cete")
					return _r("Seçim kan gölüne döndü: çete yılı başlıyor.", "warn")
				_:
					return _r("Tarafsız kaldın.")
	return _r("")

func y_donem(d: String) -> void:
	oyun.yol["donem"] = d
	oyun.yol["bitis"] = oyun.t + 20 * oyun.DAY
	oyun.kayit("Dengeler değişti — %s: %s" % [Y.DONEMLER[d]["ad"], Y.DONEMLER[d]["yazi"]], "warn")
