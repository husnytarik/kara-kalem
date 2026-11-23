extends RefCounted
# Polis dosyası (web: dosya/stage/raid/bribe) ve bodrum içki imalatı (web: dist).
# Dosya = oyun.arama (0-100). Aşamalar: Temiz <25 · Gözetim · Soruşturma · Arama emri (75+).
# Bodrum: imalathane kur, hacim ayarla; üretim iz bırakır, iz × polis dikkati = günlük yakalanma ihtimali.

const ASAMALAR := [[75, "Arama emri"], [50, "Soruşturma"], [25, "Gözetim"], [0, "Temiz"]]
const DOSYA_AZALMA := 0.4
const IZ_TABAN := 8.0
const IZ_SONUM := 0.15
const TESPIT_K := 0.0001
const DIKKAT_TABAN := 40.0
const KUR_FIYAT := 400
const GIZLI_ODA := 500
const HACIM_MAX := 60
const STOK_MAX := 300
const HAM_MALIYET := 4.0
const SATIS_FIYAT := 10.0
const TALEP := 50.0
const MEVSIM_TALEP := [1.0, 0.9, 1.05, 1.15]   # ilkbahar, yaz, sonbahar, kış
const AYLIK_DOLAN := 60

var oyun: Node
var rng := RandomNumberGenerator.new()
var _onceki := 0.0
var _asama := 0

func _init(o: Node) -> void:
	oyun = o
	rng.seed = 9113

static func yeni() -> Dictionary:
	return {"kurulu": false, "gizli": false, "hacim": 0, "stok": 0.0, "saklanma": 0, "iz": 0.0, "p": 0.0,
		"baskin": 0, "baskin_ok": 0, "dolan_t": -99999, "aylik": false, "iz_ek": 0.0, "dikkat_ek": 0.0, "satis": 0.0}

func asama_idx() -> int:
	var a: float = oyun.arama
	return 3 if a >= 75.0 else 2 if a >= 50.0 else 1 if a >= 25.0 else 0

func asama_ad() -> String:
	for x in ASAMALAR:
		if oyun.arama >= x[0]:
			return x[1]
	return "Temiz"

func haberli() -> bool:
	return oyun.pol["aylik"]

func dikkat_satirlari() -> Array:
	var l: Array = [["Semt tabanı", DIKKAT_TABAN]]
	var p: Dictionary = oyun.pol
	if p["dikkat_ek"] >= 0.5:
		l.append(["Son olaylar", round(p["dikkat_ek"])])
	if p["aylik"]:
		l.append(["Dolan aylıkta", -15.0])
	if oyun.arama >= 50.0:
		l.append(["Soruşturma açık", 10.0])
	return l

func dikkat() -> float:
	var s := 0.0
	for x in dikkat_satirlari():
		s += x[1]
	return clampf(s, 5.0, 100.0)

func gizlilik() -> float:
	return clampf((0.75 if oyun.pol["gizli"] else 0.5) + oyun.aile_k.etki("alkol_gizli") + 0.5 * oyun.aile_k.etki("gizlilik"), 0.05, 0.95)

func gunluk_iz(hacim: float) -> float:
	if hacim <= 0.0:
		return 0.0
	return IZ_TABAN * pow(hacim / 20.0, 0.7) * (1.0 - gizlilik()) * (1.5 if oyun.arama >= 25.0 else 1.0)

func tespit_p() -> float:
	return 1.0 - exp(-TESPIT_K * oyun.pol["iz"] * dikkat())

# Kanıt dosyaya girer; aşama değişimi, dava ve baskın tetiklenir.
func kanit(v: float, neden: String) -> void:
	var onceki := asama_idx()
	oyun.arama = clampf(oyun.arama + v, 0.0, 100.0)
	oyun.kayit("Dosyana kanıt girdi: +%d (Dosya %d). %s" % [int(v), int(oyun.arama), neden], "bad")
	_kontrol(onceki)

func _kontrol(onceki: int) -> void:
	var st := asama_idx()
	var p: Dictionary = oyun.pol
	if st > onceki:
		var msg: String = ["", "Gözetim altındasın. Bıraktığın iz artık 1,5 kat sayılıyor.", "Hakkında soruşturma açıldı. Polis dikkati +10.", "Savcılık arama emri hazırlıyor."][st]
		oyun.kayit("Dosya aşaması: %s. %s" % [ASAMALAR[3 - st][1], msg], "bad")
	if oyun.arama >= 100.0 and oyun.son.is_empty():
		oyun.son = {"tur": "yenilgi", "metin": "Dosya 100'e ulaştı. Savcı iddianameyi yazdı; sabaha karşı kapın çalındı. Dava açıldı."}
		return
	if oyun.arama >= 75.0 and p["baskin"] == 0 and oyun.t >= p["baskin_ok"]:
		p["baskin"] = oyun.t + (1 + rng.randi() % 3) * oyun.DAY
		if haberli():
			oyun.kayit("Dolan fısıldadı: polis yakında bodruma baskın yapacak. Malı saklamak için vaktin var.", "warn")

func _baskin_coz() -> void:
	var p: Dictionary = oyun.pol
	p["baskin"] = 0
	p["baskin_ok"] = oyun.t + 10 * oyun.DAY
	var saklida: bool = oyun.t < p["saklanma"]
	if not p["kurulu"] or saklida:
		oyun.arama = maxf(0.0, oyun.arama - 30.0)
		oyun.kayit("BASKIN: Polis bodrumu aradı, hiçbir şey bulamadı. Dosya −30 (Dosya %d)." % int(oyun.arama), "good")
		return
	var ceza := minf(500.0, maxf(0.0, oyun.temiz))
	oyun.temiz -= ceza
	var kayip := int(round(p["stok"]))
	p["kurulu"] = false
	p["gizli"] = false
	p["hacim"] = 0
	p["stok"] = 0.0
	p["iz"] = 0.0
	oyun.kayit("BASKIN: Polis bodrumu bastı. İmalathane söküldü, %d şişeye el kondu, %s ceza kesildi." % [kayip, oyun.para(ceza)], "bad")
	var b: Dictionary = oyun.bolge["southside"]
	b["tan"] = minf(100.0, b["tan"] + 8.0)
	b["sev"] = maxf(0.0, b["sev"] - 6.0)
	kanit(20.0, "Baskında suçüstü: imalathane ve stok bulundu.")

# --- günlük ---
func gun() -> void:
	var p: Dictionary = oyun.pol
	_kontrol(_asama)   # başka sistemlerin (olay kartları vb.) arttırdığı dosya
	var uretim := 0.0
	if p["kurulu"] and oyun.t >= p["saklanma"] and oyun.adamlar.size() > 0:
		uretim = minf(float(p["hacim"]), STOK_MAX - p["stok"])
		var maliyet := uretim * HAM_MALIYET * maxf(0.3, 1.0 + oyun.aile_k.etki("alkol_maliyet"))
		if uretim > 0.0 and oyun.harcama(maliyet, "kirli"):
			p["stok"] += uretim
		elif uretim > 0.0:
			uretim = 0.0
			oyun.kayit("Hammadde alacak para yok; bu gece kazan kaynamadı.", "warn")
	# satış: mevsime ve işyeri sayına göre günlük talep
	if p["kurulu"] and oyun.t >= p["saklanma"] and p["stok"] > 0.0:
		var m: float = MEVSIM_TALEP[(oyun.tarih()["ay"] % 12) / 3]
		var sahip := 0
		for i in oyun.isy:
			if oyun.isy[i]["sahip"] or oyun.isy[i]["haracli"]:
				sahip += 1
		var talep: float = TALEP * m * (1.0 + 0.1 * sahip)
		var satilan := minf(p["stok"], talep)
		p["stok"] -= satilan
		oyun.kirli += satilan * SATIS_FIYAT
		p["satis"] += satilan * SATIS_FIYAT
	# iz ve kanıt
	p["iz"] = p["iz"] * (1.0 - IZ_SONUM) + gunluk_iz(uretim) + p["iz_ek"]
	p["iz_ek"] = 0.0
	var kanit_var: bool = oyun.arama > _onceki + 0.01
	p["p"] = tespit_p()
	if p["iz"] > 1.0 and rng.randf() < p["p"]:
		var r := rng.randf()
		var v := 3.0 if r < 0.4 else 5.0 if r < 0.7 else 8.0 if r < 0.9 else 10.0
		var ne: String = {3: "Devriye gece arabasını fark etti.", 5: "Bir muhbir bodrumdaki kokuyu anlattı.", 8: "Sivil polis arka kapıdan şişe çıkarırken gördü.", 10: "Müşterilerinden biri karakolda öttü."}[int(v)]
		kanit(v, "%s İz %d × polis dikkati %d → günlük yakalanma ihtimali %%%d." % [ne, int(p["iz"]), int(dikkat()), int(round(p["p"] * 100.0))])
		kanit_var = true
	if not kanit_var and oyun.arama > 0.0:
		oyun.arama = maxf(0.0, oyun.arama - DOSYA_AZALMA)
	_onceki = oyun.arama
	_asama = asama_idx()
	p["dikkat_ek"] *= 0.9
	if p["baskin"] != 0 and oyun.t >= p["baskin"]:
		_baskin_coz()

func ay() -> void:
	var p: Dictionary = oyun.pol
	if p["aylik"]:
		if oyun.harcama(float(AYLIK_DOLAN), "kirli"):
			oyun.kayit("POLİS: Dolan'ın aylığı %s ödendi." % oyun.para(AYLIK_DOLAN), "info")
		else:
			p["aylik"] = false
			oyun.kayit("Dolan'ın aylığını ödeyemedin. Artık seni kollamıyor.", "bad")

# --- eylemler ---
func kur() -> Dictionary:
	var p: Dictionary = oyun.pol
	if p["kurulu"]:
		return oyun.hata("Zaten kurulu.")
	if oyun.adamlar.is_empty():
		return oyun.hata("Önce bu işi yürütecek bir adam tut (ekip).")
	if not oyun.harcama(float(KUR_FIYAT), "kirli"):
		return oyun.hata("Para yetmiyor (%s)." % oyun.para(KUR_FIYAT))
	p["kurulu"] = true
	oyun.kayit("Bodruma imalathane kuruldu (%s). Üretim için hacim ayarla." % oyun.para(KUR_FIYAT), "good")
	return oyun.tamam()

func gizli_oda() -> Dictionary:
	var p: Dictionary = oyun.pol
	if not p["kurulu"] or p["gizli"]:
		return oyun.hata("Yapılamaz.")
	if not oyun.harcama(float(GIZLI_ODA), "kirli"):
		return oyun.hata("Para yetmiyor (%s)." % oyun.para(GIZLI_ODA))
	p["gizli"] = true
	oyun.kayit("Bodruma çift duvar örüldü: aynı üretim yarı yarıya iz bırakır.", "good")
	return oyun.tamam()

func hacim_ayarla(v: int) -> Dictionary:
	if not oyun.pol["kurulu"]:
		return oyun.hata("İmalathane yok.")
	oyun.pol["hacim"] = clampi(v, 0, HACIM_MAX)
	return oyun.tamam()

func sakla() -> Dictionary:
	var p: Dictionary = oyun.pol
	if not p["kurulu"]:
		return oyun.hata("Saklanacak bir şey yok.")
	if oyun.t < p["saklanma"]:
		return oyun.hata("Mal zaten saklı.")
	var kayip: float = p["stok"] * 0.2
	p["stok"] -= kayip
	p["saklanma"] = oyun.t + 3 * oyun.DAY
	oyun.kayit("Mal saklandı, imalathane söküldü. 3 gün üretim ve satış yok. %d şişe telef oldu." % int(kayip), "warn")
	return oyun.tamam()

func rusvet_tahmin(miktar: float) -> Dictionary:
	var x: float = 1.2 * log(1.0 + miktar / 60.0) + 0.8 - oyun.arama / 50.0 - 1.5
	return {"p": 1.0 / (1.0 + exp(-x)), "etki": clampf(3.0 + miktar / 50.0, 0.0, 10.0)}

func rusvet(miktar: float) -> Dictionary:
	var p: Dictionary = oyun.pol
	var m := clampf(round(miktar), 20.0, 1000.0)
	if oyun.t - p["dolan_t"] < 10 * oyun.DAY:
		return oyun.hata("Dolan'la daha yeni görüştün. Sık gidersen göze batar.")
	if oyun.temiz + oyun.kirli < m:
		return oyun.hata("Para yetmiyor.")
	var e := rusvet_tahmin(m)
	p["dolan_t"] = oyun.t
	if rng.randf() < e["p"]:
		oyun.harcama(m, "kirli")
		oyun.arama = maxf(0.0, oyun.arama - e["etki"])
		oyun.kayit("Dolan zarfı aldı. Dosyadan birkaç evrak \"kayboldu\": Dosya −%d (kabul ihtimali %%%d idi)." % [int(e["etki"]), int(round(e["p"] * 100.0))], "good")
	else:
		p["dikkat_ek"] += 5.0
		oyun.kayit("Dolan zarfı masaya geri itti: \"Bunu görmemiş olayım.\" Polis dikkati +5 (kabul ihtimali %%%d idi)." % int(round(e["p"] * 100.0)), "bad")
	_onceki = oyun.arama
	return oyun.tamam()

func aylik_ver(v: bool) -> Dictionary:
	oyun.pol["aylik"] = v
	oyun.kayit("Dolan'ın aylığı %s." % ("bağlandı (ayda $%d, polis dikkati −15)" % AYLIK_DOLAN if v else "kesildi"), "info")
	return oyun.tamam()
