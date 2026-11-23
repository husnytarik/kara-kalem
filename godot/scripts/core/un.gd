extends RefCounted
# Ün eksenleri (0..100): Servet, Korku, Sevgi, Saygı, Dikkat, Aile. Hayat tipi bunlardan türer.
# Servet/Korku/Dikkat/Aile mevcut sistemlerden hesaplanır; Sevgi ve Saygı olaylarla birikir (oyun.un).

const EKSENLER := ["servet", "korku", "sevgi", "saygi", "dikkat", "aile"]
const AD := {"servet": "Servet", "korku": "Korku", "sevgi": "Sevgi", "saygi": "Saygı", "dikkat": "Dikkat", "aile": "Aile"}
const AC := {
	"servet": "Para ve mal varlığı (borç düşer).",
	"korku": "Haraç ve sertlikle büyür; hayırseverlik düşürür.",
	"sevgi": "Yardım ve dürüst işle büyür; zorbalık düşürür. Mahalle desteği.",
	"saygi": "İşletme, adam ve başarıyla büyür; rezillik düşürür.",
	"dikkat": "Polis dosyan. Yüksek olması federal baskı demek.",
	"aile": "Aile Namı ve gelenekler.",
}
const RENK := {"servet": Color("d4af37"), "korku": Color("b04030"), "sevgi": Color("5aa860"), "saygi": Color("6a8ac8"), "dikkat": Color("c08030"), "aile": Color("a870b8")}
const BAGIS_FIYAT := 100.0

var oyun: Node

func _init(o: Node) -> void:
	oyun = o

static func yeni() -> Dictionary:
	return {"sevgi": 0.0, "saygi": 0.0, "bagis": 0.0}

func _sahip() -> int:
	var n := 0
	for i in oyun.isy:
		if oyun.isy[i]["sahip"]:
			n += 1
	return n

func _haracli() -> int:
	var n := 0
	for i in oyun.isy:
		if oyun.isy[i]["haracli"]:
			n += 1
	return n

func net_servet() -> float:
	var m: float = oyun.temiz + oyun.kirli - float(oyun.borc.get("ana", 0.0))
	for i in oyun.isy:
		if oyun.isy[i]["sahip"]:
			m += float(oyun.fiyat(i))
	return m

func deger(e: String) -> float:
	var u: Dictionary = oyun.un
	match e:
		"servet":
			# $0 -> 0, $50.000 -> 100 (logaritmik)
			return clampf(log(maxf(net_servet(), 1.0)) / log(50000.0) * 100.0, 0.0, 100.0)
		"korku":
			return clampf(oyun.yol_k.puan("korku") + 4.0 * _haracli(), 0.0, 100.0)
		"sevgi":
			return clampf(u["sevgi"] + 0.4 * oyun.yol_k.puan("kanun") - 0.3 * oyun.yol_k.puan("korku"), 0.0, 100.0)
		"saygi":
			return clampf(u["saygi"] + 5.0 * _sahip() + 2.0 * oyun.adamlar.size(), 0.0, 100.0)
		"dikkat":
			return clampf(oyun.arama, 0.0, 100.0)
		"aile":
			var a: Dictionary = oyun.aile
			var dolu := 0
			for g in a["gel"]:
				if g != "":
					dolu += 1
			return clampf(10.0 * dolu + 10.0 * float(a["nam"]) + (10.0 if a["kuruldu"] else 0.0), 0.0, 100.0)
	return 0.0

# Sevgi/Saygı olayla değişir; aile kültürü kazanç hızını etkiler (kayıp etkilenmez).
func ekle(e: String, d: float) -> void:
	if not oyun.un.has(e):
		return
	if d > 0.0:
		d *= maxf(0.3, 1.0 + oyun.aile_k.etki(e))
	oyun.un[e] = clampf(oyun.un[e] + d, -50.0, 100.0)

func bagis() -> Dictionary:
	if not oyun.harcama(BAGIS_FIYAT, "temiz"):
		return oyun.hata("Temiz para yetmiyor (%s)." % oyun.para(BAGIS_FIYAT))
	ekle("sevgi", 4.0)
	ekle("saygi", 1.5)
	oyun.yol_k.ekle("korku", -1.0)
	oyun.un["bagis"] += BAGIS_FIYAT
	oyun.kayit("Mahalleye %s bağış yaptın. İnsanlar adını iyilikle anıyor." % oyun.para(BAGIS_FIYAT), "good")
	oyun.degisti.emit()
	return oyun.tamam()

# Günlük akış: haraç sevgiyi aşındırır, meşru işletme saygı ve sevgi kazandırır.
func gun() -> void:
	var h := _haracli()
	var s := _sahip()
	if h > 0:
		oyun.un["sevgi"] = maxf(-50.0, oyun.un["sevgi"] - 0.05 * h)
	if s > 0:
		ekle("saygi", 0.03 * s)
		ekle("sevgi", 0.02 * s)
	if oyun.arama >= 50.0:
		oyun.un["saygi"] = maxf(-50.0, oyun.un["saygi"] - 0.05)

# Hayat tipi: eksenlerden türer.
func tip() -> Dictionary:
	var sv := deger("servet")
	var ko := deger("korku")
	var se := deger("sevgi")
	var sy := deger("saygi")
	var di := deger("dikkat")
	var h := _haracli()
	if ko >= 45.0 and sv >= 40.0 and sy >= 35.0:
		return {"ad": "Baba", "ac": "Korkulan, zengin ve sayılan: sokak senin."}
	if se >= 40.0 and sv >= 40.0 and ko < 30.0:
		return {"ad": "Saygın iş adamı", "ac": "Sevilen, kazanan, temiz bir isim."}
	if h > 0 and sy < 20.0 and sv < 35.0 and di >= 25.0:
		return {"ad": "Rezil haraççı", "ac": "Haraçla debeleniyor; kimse ciddiye almıyor."}
	if ko >= 25.0 and h > 0:
		return {"ad": "Sokak haraççısı", "ac": "Korku salıyor ama henüz büyük değil."}
	if _sahip() >= 1 or se >= 20.0:
		return {"ad": "Mahalle esnafı", "ac": "Küçük ama kendi ayakları üstünde."}
	return {"ad": "Yolunu arayan", "ac": "Henüz bir şey olmadın."}
