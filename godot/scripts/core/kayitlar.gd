extends RefCounted
# Çoklu kayıt: 5 yuva + otomatik kayıt. Eski tek dosya (kayit.dat) 1. yuva olarak okunur.

const SLOTLAR := ["1", "2", "3", "4", "5", "oto"]
const ESKI := "user://kayit.dat"
static var aktif := "1"            # F6/F9'un kullandığı yuva

static func yol(slot: String) -> String:
	if slot == "oto":
		return "user://oto.dat"
	return "user://kayit_%s.dat" % slot

static func hangisi(slot: String) -> String:
	if FileAccess.file_exists(yol(slot)):
		return yol(slot)
	if slot == "1" and FileAccess.file_exists(ESKI):
		return ESKI
	return ""

static func var_mi(slot: String) -> bool:
	return hangisi(slot) != ""

static func hicbiri_var() -> bool:
	for s in SLOTLAR:
		if var_mi(s):
			return true
	return false

# En son yazılan yuva (Devam et / F9 için).
static func en_yeni() -> String:
	var en := ""
	var tm := 0
	for s in SLOTLAR:
		var p: String = hangisi(s)
		if p != "":
			var m: int = FileAccess.get_modified_time(p)
			if m >= tm:
				tm = m
				en = s
	return en

static func meta(slot: String) -> Dictionary:
	var p: String = hangisi(slot)
	if p == "":
		return {}
	var f := FileAccess.open(p, FileAccess.READ)
	if f == null:
		return {}
	var d: Variant = f.get_var(true)
	if typeof(d) != TYPE_DICTIONARY:
		return {}
	return d.get("meta", {"eski": true})

static func ad(slot: String) -> String:
	return "Otomatik kayıt" if slot == "oto" else "Yuva " + slot

# Yuvanın özeti.
static func ozet(slot: String) -> String:
	if not var_mi(slot):
		return "— boş —"
	var m: Dictionary = meta(slot)
	if m.is_empty() or m.has("eski"):
		return "Eski kayıt"
	return "%d · %s · %d. nesil · $%d\n%s" % [m.get("yil", 1920), m.get("tip", "?"), m.get("nesil", 1), m.get("para", 0), m.get("tarih", "")]
