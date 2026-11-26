extends RefCounted
# Adamların geçmişi: sabıka kaydı, aranma durumu, rakip bağlantıları ve muhbirlik.
# Adam alanları: sabika (0 temiz · 1 küçük · 2 ağır · 3 aranan), gecmis (sabıka satırları),
# bag (eskiden çalıştığı rakip), muhbir ("" / "polis" / rakip kimliği), sizinti (sayaç), ifsa (muhbir olduğu anlaşıldı).

const SABIKA_AD := ["Sabıkasız", "Küçük sabıkalı", "Ağır sabıkalı", "ARANIYOR"]
const SUCLAR := [
	["Ufak hırsızlık", "Kavga ve yaralama", "Kaçak içki taşıma", "Sahte para", "Cüzdan çalma"],
	["Silahlı soygun", "Adam yaralama", "Haraç ve tehdit", "Kasa soygunu", "Hapisten firar"],
	["Cinayet şüphesi", "Banka soygunu", "Polis öldürme", "Cinayet", "Rehine ve fidye"],
]
const AD_FIRSAT := 0.005     # aranan adamın günlük yakalanma ihtimali (taban)
const SIZINTI_P := 0.012     # muhbirin günlük bilgi sızdırma ihtimali

var o: Node
var rng := RandomNumberGenerator.new()

func _init(oyun: Node) -> void:
	o = oyun
	rng.seed = 7741

# Yeni adayın geçmişini üretir (adam sözlüğüne yazar).
func uret(a: Dictionary) -> void:
	var r := rng.randf()
	var s := 0 if r < 0.50 else (1 if r < 0.78 else (2 if r < 0.92 else 3))
	a["sabika"] = s
	var gec: Array = []
	if s > 0:
		var havuz: Array = SUCLAR[mini(s, 3) - 1] if s < 3 else SUCLAR[2]
		gec.append(havuz[rng.randi() % havuz.size()])
		if s >= 2 and rng.randf() < 0.5:
			gec.append(SUCLAR[0][rng.randi() % SUCLAR[0].size()])
	a["gecmis"] = gec
	var bag := ""
	if rng.randf() < 0.22:
		bag = ["marchetti", "obrien"][rng.randi() % 2]
	a["bag"] = bag
	var m := ""
	if bag != "" and rng.randf() < 0.35:
		m = bag
	elif rng.randf() < 0.06:
		m = "polis"
	a["muhbir"] = m
	a["sizinti"] = 0
	a["ifsa"] = false

func rozet(a: Dictionary) -> String:
	return SABIKA_AD[int(a.get("sabika", 0))]

func gecmis_yazi(a: Dictionary) -> String:
	var gec: Array = a.get("gecmis", [])
	return ", ".join(gec) if not gec.is_empty() else "Kaydı temiz."

func bag_yazi(a: Dictionary) -> String:
	var b: String = a.get("bag", "")
	return "Eskiden %s için çalışmış." % o.FAK[b]["ad"] if b != "" else ""

# Ekibe katılırken kısa uyarı (log için).
func katilma_notu(a: Dictionary) -> String:
	var s: int = a.get("sabika", 0)
	var n := ""
	if s == 3:
		n = " Polis onu arıyor (%s)." % gecmis_yazi(a)
	elif s > 0:
		n = " Sabıkalı: %s." % gecmis_yazi(a)
	if a.get("bag", "") != "":
		n += " " + bag_yazi(a)
	return n

func _tutuklat(a: Dictionary, neden: String) -> void:
	a["sabika"] = maxi(2, int(a.get("sabika", 0)))
	if a["gorev"] == "":
		o.yarala(a, 5)
	var ek := 10.0
	o.polis.kanit(ek, "%s: ekibinde aranan bir adam vardı." % a["ad"])
	o.kayit("Polis %s'ı yakaladı (%s). Onu barındırdığın ortaya çıktı: Dosya +%d." % [a["ad"], neden, int(ek)], "bad")

func gun() -> void:
	var dosya_k: float = 1.0 + float(o.arama) / 50.0
	for a in o.adamlar.duplicate():
		var s: int = a.get("sabika", 0)
		if a["gorev"] == "tutuklu":
			continue
		# polis aranan adamı sokakta/yanında yakalar; dosya ne kadar kalınsa o kadar kolay
		if s >= 2 and rng.randf() < (AD_FIRSAT if s == 3 else AD_FIRSAT * 0.3) * dosya_k:
			if s == 3:
				_tutuklat(a, a["gecmis"][0] if not a["gecmis"].is_empty() else "arama emri")
			else:
				o.polis.kanit(3.0, "%s ağır sabıkalı; polis ekibini yakından izliyor." % a["ad"])
		# muhbir: bilgi sızdırır
		var m: String = a.get("muhbir", "")
		if m != "" and rng.randf() < SIZINTI_P:
			_sizdir(a, m)

func _sizdir(a: Dictionary, m: String) -> void:
	a["sizinti"] = int(a.get("sizinti", 0)) + 1
	if m == "polis":
		o.polis.kanit(4.0, "Ekibinden biri polise bilgi veriyor.")
	else:
		o.gerginlik.ekle("oyuncu", m, 6.0, "ekibindeki bir muhbir bilgi sızdırdı")
		o.kayit("%s ekibindeki birinden senin hareketlerini öğrendi (gerginlik arttı)." % o.FAK[m]["ad"], "bad")
	if a["sizinti"] >= 2 and not a.get("ifsa", false):
		a["ifsa"] = true
		var kime: String = "polise" if m == "polis" else o.FAK[m]["ad"] + "'a"
		o.kayit("%s'ın %s bilgi sattığı anlaşıldı. Ekibinden atmalısın." % [a["ad"], kime], "warn")
