extends RefCounted
# Aile kültürü: köken + inanç + değerler + gelenekler. Her seçim bonus VE bedel getirir (bkz. AILE_SISTEMI.md).
# Etkiler `etki("anahtar")` ile okunur: ailenin bütün seçimlerinin toplamı (yarım etkiler dahil).
# Katsayılar çarpandır: -0.15 = %15 azalır.

const GEL_SLOT := 3
const ALISMA_GUN := 90        # yeni gelenek ilk 90 gün yarım etki
const KILIT_GUN := 365        # aynı slot 1 yıl tekrar değiştirilemez

const ETKI_AD := {
	"adam_maliyet": "adam maliyeti", "adam_secenek": "adam seçeneği", "sadakat": "sadakat", "adam_kayip": "adam kaybı",
	"gelir_mesru": "meşru gelir", "gelir_haram": "haraç/kara gelir", "gider": "gider", "rusvet": "rüşvet bedeli",
	"aklama": "aklama", "borc_faiz": "borç faizi", "alkol_maliyet": "içki maliyeti", "alkol_gizli": "içki gizliliği",
	"kumar_gelir": "kumar geliri", "mal_fiyat": "mal fiyatı", "isabet": "isabet", "yakin_hasar": "yakın hasar",
	"can": "can", "silah_fiyat": "silah fiyatı", "kacis": "kaçış", "ikna": "ikna", "korku": "korku", "sevgi": "sevgi",
	"saygi": "saygı", "pazarlik": "pazarlık", "dikkat": "dikkat", "gizlilik": "gizlilik", "dogurganlik": "doğurganlık",
	"cocuk_gelisim": "çocuk gelişimi", "miras_kayip": "miras kaybı", "evlilik_secenek": "evlilik seçeneği",
	"stres": "stres", "polis_ilgi": "polis ilgisi", "federal_ilgi": "federal ilgi", "ilce_destek": "mahalle desteği",
	"muhbir": "muhbir riski", "ipucu": "ipucu", "gerginlik": "gerginlik artışı", "darbe": "darbe riski",
}

const KOKEN := {
	"belirsiz": {"ad": "Kökü belirsiz", "ac": "Havaalanından gelen biri. Bonus yok, bedel yok.", "e": {}, "ucuz": []},
	"irlandali": {"ad": "İrlandalı göçmen", "ac": "Sokakta büyüyen, kavgacı ve sadık bir halk.", "e": {"adam_secenek": 0.15, "sadakat": 0.08, "rusvet": 0.10}, "ucuz": ["kan_bagi", "meyhane", "kavgaci"]},
	"italyan": {"ad": "İtalyan / Sicilyalı", "ac": "Aile bağı ve korku üzerine kurulu bir gelenek.", "e": {"korku": 0.12, "sadakat": 0.10, "dikkat": 0.10}, "ucuz": ["aile_once", "omerta", "don_saygi"]},
	"yahudi": {"ad": "Yahudi tüccar ailesi", "ac": "Hesabı kitabı bilen, pazarlıkta usta bir çevre.", "e": {"gelir_mesru": 0.10, "pazarlik": 0.12, "adam_secenek": -0.10}, "ucuz": ["hesap", "bilgi_agi", "cemaat"]},
	"wasp": {"ad": "Eski Amerikalı", "ac": "Köklü soy, kulüpler, belediyede tanıdık.", "e": {"rusvet": -0.10, "ilce_destek": 0.08, "adam_maliyet": 0.10, "sevgi": -0.05}, "ucuz": ["kokluk", "siyaset", "gosteris"]},
	"isci": {"ad": "Doğu Avrupalı işçi", "ac": "Sert kış, ucuz hayat, emek onuru.", "e": {"can": 0.08, "gider": -0.08, "saygi": -0.05}, "ucuz": ["sendika", "sert_kis", "kavgaci"]},
	"guney": {"ad": "Güney'den göçen", "ac": "Cemaat bağı güçlü, polis gözü üstünde.", "e": {"sevgi": 0.10, "ilce_destek": 0.10, "polis_ilgi": 0.12}, "ucuz": ["cemaat", "mahalle_kalkan", "dindar"]},
	"cinli": {"ad": "Çinli / Uzakdoğulu", "ac": "Sessiz, kapalı, iz bırakmayan aile.", "e": {"gizlilik": 0.12, "kacis": 0.06, "adam_secenek": -0.10}, "ucuz": ["sessiz_aile", "hesap", "kapali_kapi"]},
}

const INANC := {
	"dindar": {"ad": "Dindar", "ac": "Cemaat ve kilise çevresi; içki ve kumar günah sayılır.", "e": {"adam_maliyet": -0.15, "adam_secenek": 0.15, "sevgi": 0.10, "alkol_maliyet": 0.25, "alkol_gizli": -0.15, "kumar_gelir": -0.20}},
	"ilimli": {"ad": "Ilımlı inanç", "ac": "Pazar ayinine gidilir, fazlası sorulmaz.", "e": {"stres": -0.05, "ilce_destek": 0.05}},
	"dunyevi": {"ad": "İnançsız / dünyevi", "ac": "Günah diye bir şey yok, sadece iş var.", "e": {"kumar_gelir": 0.10, "alkol_gizli": 0.08, "sevgi": -0.05, "sadakat": -0.05}},
	"batil": {"ad": "Batıl / folklorcu", "ac": "Nazar boncuğu, uğurlu sayılar.", "e": {"kacis": 0.05, "stres": -0.08, "gelir_mesru": -0.05}},
	"yuzeysel": {"ad": "Yüzeysel dindar", "ac": "Ruhban ile arası iyi, ama kimse inanmıyor.", "e": {"rusvet": -0.10, "saygi": -0.05}},
}

# Değer çifti: ikisinden biri seçilir.
const DEGER := {
	"namus_cikar": {"ad": "Namus ↔ Çıkar", "sol": {"ad": "Namus", "e": {"saygi": 0.10, "sevgi": 0.05, "gelir_haram": -0.05}}, "sag": {"ad": "Çıkar", "e": {"gelir_haram": 0.10, "saygi": -0.05}}},
	"sert_merhamet": {"ad": "Sert ↔ Merhametli", "sol": {"ad": "Sert", "e": {"korku": 0.12, "sevgi": -0.10}}, "sag": {"ad": "Merhametli", "e": {"sevgi": 0.12, "korku": -0.10}}},
	"gelenek_yenilik": {"ad": "Gelenek ↔ Yenilik", "sol": {"ad": "Gelenek", "e": {"sadakat": 0.08, "gelir_mesru": -0.05}}, "sag": {"ad": "Yenilik", "e": {"gelir_mesru": 0.08, "sadakat": -0.08}}},
	"sessiz_gosteris": {"ad": "Sessiz ↔ Gösterişli", "sol": {"ad": "Sessiz", "e": {"dikkat": -0.10, "saygi": -0.05}}, "sag": {"ad": "Gösterişli", "e": {"saygi": 0.10, "dikkat": 0.10}}},
}

# grup, ad, açıklama, etkiler, çatışır
const GEL := {
	"dindar": {"g": "Kutsal ve cemaat", "ad": "Dindar Hane", "e": {"adam_maliyet": -0.15, "adam_secenek": 0.15, "alkol_maliyet": 0.25, "alkol_gizli": -0.15}, "x": ["meyhane"]},
	"cemaat": {"g": "Kutsal ve cemaat", "ad": "Cemaat Bağı", "e": {"ilce_destek": 0.12, "sevgi": 0.08, "dikkat": 0.05}, "x": ["sessiz_aile"]},
	"vaftiz": {"g": "Kutsal ve cemaat", "ad": "Vaftiz Babası Geleneği", "e": {"sadakat": 0.12, "evlilik_secenek": 0.10, "gider": 0.06}, "x": []},
	"hayirsever": {"g": "Kutsal ve cemaat", "ad": "Hayırsever Hane", "e": {"sevgi": 0.15, "saygi": 0.06, "gider": 0.10}, "x": ["harac_soyu"]},
	"cenaze": {"g": "Kutsal ve cemaat", "ad": "Cenaze Onuru", "e": {"saygi": 0.10, "sadakat": 0.08, "gider": 0.05}, "x": []},
	"kan_bagi": {"g": "Kan ve sadakat", "ad": "Kan Bağı", "e": {"sadakat": 0.15, "adam_kayip": -0.08, "adam_secenek": -0.10}, "x": ["acik_kapi"]},
	"aile_once": {"g": "Kan ve sadakat", "ad": "Aile Önce", "e": {"sadakat": 0.12, "cocuk_gelisim": 0.10, "gelir_haram": -0.04}, "x": ["hesap"]},
	"don_saygi": {"g": "Kan ve sadakat", "ad": "Don'a Saygı", "e": {"korku": 0.10, "darbe": -0.20, "adam_secenek": -0.08}, "x": ["acik_kapi"]},
	"acik_kapi": {"g": "Kan ve sadakat", "ad": "Açık Kapı", "e": {"adam_secenek": 0.20, "adam_maliyet": -0.08, "sadakat": -0.10}, "x": ["kan_bagi", "don_saygi", "omerta", "kapali_kapi", "soyagaci"]},
	"intikam": {"g": "Kan ve sadakat", "ad": "İntikam Yemini", "e": {"korku": 0.12, "isabet": 0.05, "gerginlik": 0.25, "dikkat": 0.08}, "x": ["barisci"]},
	"hesap": {"g": "Ticaret ve para", "ad": "Hesap Kitap", "e": {"gelir_mesru": 0.10, "borc_faiz": -0.10, "korku": -0.05}, "x": ["aile_once"]},
	"meyhane": {"g": "Ticaret ve para", "ad": "Meyhane Ocağı", "e": {"alkol_maliyet": -0.15, "alkol_gizli": 0.10, "sevgi": -0.05}, "x": ["dindar"]},
	"tuccar": {"g": "Ticaret ve para", "ad": "Tüccar Soyu", "e": {"mal_fiyat": -0.10, "pazarlik": 0.10, "adam_secenek": -0.05}, "x": ["harac_soyu"]},
	"harac_soyu": {"g": "Ticaret ve para", "ad": "Haraç Soyu", "e": {"gelir_haram": 0.12, "sevgi": -0.08, "dikkat": 0.08}, "x": ["tuccar", "hayirsever"]},
	"sessiz_para": {"g": "Ticaret ve para", "ad": "Sessiz Para", "e": {"aklama": 0.15, "gelir_haram": -0.05}, "x": ["gosteris"]},
	"gosteris": {"g": "Ticaret ve para", "ad": "Gösterişli Zenginlik", "e": {"saygi": 0.12, "evlilik_secenek": 0.12, "dikkat": 0.12, "federal_ilgi": 0.10}, "x": ["sessiz_para", "sessiz_aile"]},
	"sendika": {"g": "Ticaret ve para", "ad": "Sendika Ruhu", "e": {"adam_maliyet": -0.10, "gelir_mesru": -0.05}, "x": []},
	"silah_gel": {"g": "Güç ve savaş", "ad": "Silah Geleneği", "e": {"silah_fiyat": -0.12, "isabet": 0.05, "polis_ilgi": 0.08}, "x": ["barisci"]},
	"kavgaci": {"g": "Güç ve savaş", "ad": "Sokak Kavgacıları", "e": {"yakin_hasar": 0.12, "can": 0.06, "dikkat": 0.06}, "x": []},
	"barisci": {"g": "Güç ve savaş", "ad": "Barışçıl Hane", "e": {"sevgi": 0.10, "polis_ilgi": -0.10, "korku": -0.10, "isabet": -0.04}, "x": ["silah_gel", "intikam"]},
	"sert_kis": {"g": "Güç ve savaş", "ad": "Sert Kış", "e": {"can": 0.10, "stres": -0.06, "gider": 0.04}, "x": []},
	"omerta": {"g": "Gizlilik ve bilgi", "ad": "Sessizlik Yemini (Omertà)", "e": {"muhbir": -0.25, "gizlilik": 0.12, "sevgi": -0.05}, "x": ["acik_kapi"]},
	"sessiz_aile": {"g": "Gizlilik ve bilgi", "ad": "Sessiz Aile", "e": {"dikkat": -0.12, "gizlilik": 0.08, "saygi": -0.06, "evlilik_secenek": -0.08}, "x": ["gosteris", "cemaat"]},
	"bilgi_agi": {"g": "Gizlilik ve bilgi", "ad": "Bilgi Ağı", "e": {"ipucu": 0.20, "gider": 0.08}, "x": []},
	"kapali_kapi": {"g": "Gizlilik ve bilgi", "ad": "Kapalı Kapı", "e": {"muhbir": -0.20, "adam_secenek": -0.08}, "x": ["acik_kapi"]},
	"siyaset": {"g": "Siyaset ve toplum", "ad": "Siyaset Bağı", "e": {"rusvet": -0.12, "federal_ilgi": -0.08, "gider": 0.05}, "x": []},
	"kokluk": {"g": "Siyaset ve toplum", "ad": "Köklü Soy", "e": {"saygi": 0.10, "ilce_destek": 0.08, "adam_maliyet": 0.08}, "x": ["gocmen"]},
	"gocmen": {"g": "Siyaset ve toplum", "ad": "Göçmen Ruhu", "e": {"adam_secenek": 0.12, "sevgi": 0.06, "ilce_destek": -0.04}, "x": ["kokluk"]},
	"mahalle_kalkan": {"g": "Siyaset ve toplum", "ad": "Mahalle Kalkanı", "e": {"muhbir": -0.20, "ilce_destek": 0.10, "gider": 0.05}, "x": []},
	"sofra": {"g": "Aile hayatı", "ad": "Kalabalık Sofra", "e": {"dogurganlik": 0.20, "sevgi": 0.06, "gider": 0.10}, "x": []},
	"cocuk_okur": {"g": "Aile hayatı", "ad": "Çocuk Okur", "e": {"cocuk_gelisim": 0.12, "gider": 0.08}, "x": ["erken_calisan"]},
	"erken_calisan": {"g": "Aile hayatı", "ad": "Erken Çalışan", "e": {"cocuk_gelisim": 0.08, "gelir_mesru": 0.03, "sevgi": -0.04}, "x": ["cocuk_okur"]},
	"konsey": {"g": "Aile hayatı", "ad": "Büyükler Konseyi", "e": {"miras_kayip": -0.15, "darbe": -0.10}, "x": []},
	"soyagaci": {"g": "Aile hayatı", "ad": "Soyağacı Yemini", "e": {"sadakat": 0.10}, "x": ["acik_kapi"]},
}

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"koken": "belirsiz", "inanc": "ilimli", "deger": {}, "gel": ["", "", ""], "nam": 0, "kuruldu": false, "degisim": {}, "yeni": {}}

func _a() -> Dictionary:
	return oyun.aile

# --- Etkiler ---------------------------------------------------------------------------
func _topla(e: Dictionary, anahtar: String, carpan: float) -> float:
	return float(e.get(anahtar, 0.0)) * carpan

func yari_mi(id: String) -> bool:
	var a := _a()
	return a["yeni"].has(id) and oyun.t - int(a["yeni"][id]) < ALISMA_GUN * 1440

func etki(anahtar: String) -> float:
	var a := _a()
	if a.is_empty():
		return 0.0
	var top := _topla(KOKEN[a["koken"]]["e"], anahtar, 1.0) + _topla(INANC[a["inanc"]]["e"], anahtar, 1.0)
	for k in a["deger"]:
		var d: Dictionary = DEGER[k][a["deger"][k]]
		top += _topla(d["e"], anahtar, 1.0)
	for id in a["gel"]:
		if id != "":
			top += _topla(GEL[id]["e"], anahtar, 0.5 if yari_mi(id) else 1.0)
	return top

# Hangi etki anahtarları (kaynak adıyla) bu aileye dokunuyor? Panel özeti için.
func toplam_etkiler() -> Dictionary:
	var out := {}
	for k in ETKI_AD:
		var v := etki(k)
		if absf(v) > 0.0001:
			out[k] = v
	return out

func etki_yazi(e: Dictionary, yari: bool = false) -> String:
	var parca: PackedStringArray = []
	for k in e:
		var v: float = float(e[k]) * (0.5 if yari else 1.0)
		parca.append("%s %s%d%%" % [ETKI_AD.get(k, k), "+" if v > 0.0 else "−", int(round(absf(v) * 100.0))])
	return ", ".join(parca)

# --- Seçimler ------------------------------------------------------------------------
func _cakisan(id: String) -> String:
	var a := _a()
	for s in a["gel"]:
		if s == "":
			continue
		if GEL[id]["x"].has(s) or GEL[s]["x"].has(id):
			return s
	return ""

func koken_sec(id: String) -> Dictionary:
	if _a()["kuruldu"]:
		return oyun.hata("Aile kurulduktan sonra köken değişmez.")
	_a()["koken"] = id
	oyun.degisti.emit()
	return oyun.tamam()

func inanc_sec(id: String) -> Dictionary:
	if _a()["kuruldu"]:
		return oyun.hata("Aile kurulduktan sonra inanç değişmez.")
	_a()["inanc"] = id
	oyun.degisti.emit()
	return oyun.tamam()

func deger_sec(k: String, taraf: String) -> Dictionary:
	if _a()["kuruldu"]:
		return oyun.hata("Aile kurulduktan sonra değerler değişmez.")
	if _a()["deger"].get(k, "") == taraf:
		_a()["deger"].erase(k)
	elif _a()["deger"].size() >= 2 and not _a()["deger"].has(k):
		return oyun.hata("En fazla iki değer seçilebilir.")
	else:
		_a()["deger"][k] = taraf
	oyun.degisti.emit()
	return oyun.tamam()

# Slota gelenek koy (boş slot bedelsiz; dolu slotu değiştirmek Aile Namı −1, yeni gelenek 90 gün yarım etki).
func gelenek_sec(slot: int, id: String) -> Dictionary:
	var a := _a()
	if slot < 0 or slot >= GEL_SLOT or not GEL.has(id):
		return oyun.hata("Geçersiz seçim.")
	if a["gel"].has(id):
		return oyun.hata("Bu gelenek zaten seçili.")
	var c := _cakisan(id)
	if c != "" and c != a["gel"][slot]:
		return oyun.hata("%s ile çatışıyor." % GEL[c]["ad"])
	var eski: String = a["gel"][slot]
	if eski != "":
		var son: int = int(a["degisim"].get(str(slot), -999999))
		var kalan: int = KILIT_GUN - int((oyun.t - son) / 1440)
		if a["kuruldu"] and kalan > 0:
			return oyun.hata("Bu slot %d gün daha değiştirilemez." % kalan)
		if a["kuruldu"] and not a.get("ilk_bedava", false):
			a["nam"] = int(a["nam"]) - 1
		a["ilk_bedava"] = false
		a["yeni"].erase(eski)
	a["gel"][slot] = id
	if a["kuruldu"]:
		a["yeni"][id] = oyun.t
		a["degisim"][str(slot)] = oyun.t
	oyun.kayit("Aile geleneği: %s." % GEL[id]["ad"], "info")
	oyun.degisti.emit()
	return oyun.tamam()

func gelenek_birak(slot: int) -> Dictionary:
	var a := _a()
	var eski: String = a["gel"][slot]
	if eski == "":
		return oyun.tamam()
	if a["kuruldu"]:
		return oyun.hata("Kurulmuş bir geleneği bırakmak için yerine yenisini seç.")
	a["gel"][slot] = ""
	oyun.degisti.emit()
	return oyun.tamam()

func kur_onayla() -> Dictionary:
	var a := _a()
	if a["kuruldu"]:
		return oyun.tamam()
	a["kuruldu"] = true
	oyun.kayit("Aile kuruldu. Kültürün artık seninle yürür.", "good")
	oyun.degisti.emit()
	return oyun.tamam()

# Miras: yeni aile başı ilk değişikliği Aile Namı kaybetmeden yapabilir.
func miras_devri() -> void:
	_a()["ilk_bedava"] = true
