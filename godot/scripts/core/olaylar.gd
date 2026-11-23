extends RefCounted
# Durum-duyarlı olay motoru (bkz. OLAYLAR.md). Veri olay_veri_*.gd dosyalarındadır; bu dosya kapı/çarpan/etki motorudur.
# ağırlık = taban × evre_uyumu × yol_uyumu × beceri × dünya × tazelik
# Seçenek: [ad, koşul, olasılık, ok_etki, ok_metin, no_etki, no_metin]
#   olasılık: 1.0 (kesin) | 0.55 | "0.5,zeka,0.03" (taban + stat×katsayı)
#   koşul/etki dizgeleri: bkz. _v() ve _fx().  Etki dizgesinde {F}=ilgili aile, {B}=ilgili mahalle.

const V1 := preload("res://scripts/core/olay_veri_a.gd")
const V2 := preload("res://scripts/core/olay_veri_b.gd")
const V3 := preload("res://scripts/core/olay_veri_c.gd")
const V4 := preload("res://scripts/core/olay_veri_d.gd")
const V5 := preload("res://scripts/core/olay_veri_e.gd")

const AD_ETIKET := {
	"arama": "Dosya", "y.kanun": "Yasal", "y.golge": "Gölge", "y.korku": "Korku", "y.kulis": "Kulis",
	"sevgi": "Sevgi", "saygi": "Saygı", "fed": "Federal ilgi", "dok.polis": "Polis nüfuzu", "dok.yargic": "Yargıç nüfuzu",
	"dok.siyasi": "Siyasi nüfuz", "sad": "Adam sadakati", "stres": "Stres", "yara": "Yara", "rezil": "Rezillik", "nam": "Aile Namı",
}

var oyun: Node
var Y: RefCounted
var kart: RefCounted
var liste: Dictionary = {}
var _f := ""
var _b := ""

func _init(o: Node, k: RefCounted) -> void:
	oyun = o
	Y = o.yol_k
	kart = k
	for v in [V1, V2, V3, V4, V5]:
		for id in v.OLAY:
			liste[id] = v.OLAY[id]

func var_mi(id: String) -> bool:
	return liste.has(id)

func baslik(id: String) -> String:
	return liste[id]["b"]

# ---------------- değişkenler ----------------
func _stat(n: String) -> float:
	return float(oyun.ozet.get("stat", {}).get(n, 5))

func _v(n: String) -> float:
	match n:
		"arama", "dikkat": return oyun.arama
		"temiz": return oyun.temiz
		"kirli": return oyun.kirli
		"para": return oyun.temiz + oyun.kirli
		"servet": return oyun.un_k.net_servet()
		"adam": return float(oyun.adamlar.size())
		"bolge": return float(oyun.oyuncu_bolgeleri().size())
		"sev": return float(kart.seviye())
		"korku", "sevgi", "saygi", "aile_un": return oyun.un_k.deger("aile" if n == "aile_un" else n)
		"servet_un": return oyun.un_k.deger("servet")
		"fed": return oyun.nuf_k.fed()
		"y_kanun": return Y.puan("kanun")
		"y_golge": return Y.puan("golge")
		"y_korku": return Y.puan("korku")
		"y_kulis": return Y.puan("kulis")
		"isl": return float(oyun.isy.keys().filter(func(i): return oyun.isy[i]["sahip"]).size())
		"harac": return float(oyun.isy.keys().filter(func(i): return oyun.isy[i]["haracli"]).size())
		"borc": return float(oyun.borc.get("ana", 0.0))
		"tef": return float(oyun.kotu["tef"])
		"rezil": return float(oyun.kotu["rezil"])
		"hapis": return float(oyun.kotu["hapis_say"])
		"yas": return float(oyun.kisi_k.oyuncu_yas())
		"evli": return 0.0 if oyun.kisi_k.es().is_empty() else 1.0
		"cocuk": return float(oyun.kisi_k.cocuklar().size())
		"cocuk6": return float(oyun.kisi_k.cocuklar().filter(func(k): return oyun.kisi_k.yas(k) >= 6 and oyun.kisi_k.yas(k) <= 16).size())
		"cocuk12": return float(oyun.kisi_k.cocuklar().filter(func(k): return oyun.kisi_k.yas(k) >= 12).size())
		"cocuk14": return float(oyun.kisi_k.cocuklar().filter(func(k): return oyun.kisi_k.yas(k) >= 14 and oyun.kisi_k.yas(k) <= 22).size())
		"evlicocuk": return float(oyun.kisi_k.cocuklar().filter(func(k): return oyun.kisi_k.yas(k) >= 22).size())
		"nesil": return float(oyun.aile["nesil"])
		"nam": return float(oyun.aile["nam"])
		"sad":
			var m := 100.0
			for a in oyun.adamlar:
				m = minf(m, oyun.nuf_k.sadakat(a))
			return m
		"d_polis": return oyun.nuf_k.dokun("polis")
		"d_yargic": return oyun.nuf_k.dokun("yargic")
		"d_siyasi": return oyun.nuf_k.dokun("siyasi")
		"zeka", "guc", "karizma", "nisan": return _stat(n)
		"stres": return float(oyun.kis["stres"])
		"yara": return float(oyun.kis.get("yara", 0.0))
		"yil": return float(oyun.tarih()["yil"])
		"savas":
			for f in oyun.NPC:
				if oyun.gerginlik.savasta("oyuncu", f):
					return 1.0
			return 0.0
		"gerg":
			var m2 := 0.0
			for f in oyun.NPC:
				m2 = maxf(m2, oyun.gerginlik.gerginlik("oyuncu", f))
			return m2
		"avukat": return 1.0 if oyun.nuf.get("avukat", false) else 0.0
		"mal": return 1.0 if oyun.nuf.get("mal", false) else 0.0
		"bodrum": return 1.0 if oyun.pol.get("kurulu", false) else 0.0
		"muhbir": return float(oyun.muhbir.size()) if typeof(oyun.muhbir) in [TYPE_ARRAY, TYPE_DICTIONARY] else 0.0
		"hasta": return 1.0 if int(oyun.kis.get("hasta", 0)) > 0 else 0.0
	return 0.0

func _kosul_tek(t: String) -> bool:
	t = t.strip_edges()
	if t == "":
		return true
	for op in [">=", "<=", "==", ">", "<"]:
		var i := t.find(op)
		if i > 0:
			var sol: float = _v(t.substr(0, i).strip_edges())
			var sag: float = t.substr(i + op.length()).to_float()
			match op:
				">=": return sol >= sag
				"<=": return sol <= sag
				"==": return is_equal_approx(sol, sag)
				">": return sol > sag
				_: return sol < sag
	if t.begins_with("!"):
		return _v(t.substr(1)) <= 0.0
	return _v(t) > 0.0

func kosul(s: String) -> bool:
	for t in s.split(";", false):
		if not _kosul_tek(t):
			return false
	return true

# ---------------- dünya: aile gücü oranı ----------------
func oran(f: String) -> float:
	var ben: float = maxf(2.0, oyun.kudret("oyuncu") + 0.8 * oyun.adamlar.size())
	return oyun.kudret(f) / ben

func _aileler(mod: String) -> Array:
	var r: Array = []
	for f in oyun.NPC:
		var g: float = oran(f)
		match mod:
			"zayif":
				if g < 0.5:
					r.append(f)
			"guclu":
				if g >= 1.2:
					r.append(f)
			"esit":
				if g >= 0.6 and g <= 1.4:
					r.append(f)
			"teslim":
				if g < 0.3 and oyun.un_k.deger("korku") >= 40.0:
					r.append(f)
			"rakip":
				if g >= 0.6:
					r.append(f)
			"gerg":
				if oyun.gerginlik.gerginlik("oyuncu", f) >= 3.0:
					r.append(f)
			_:
				r.append(f)
	return r

func _dunya_carpan(mod: String) -> float:
	match mod:
		"zayif": return 2.0
		"esit": return 2.0
		"guclu": return 1.3
		"gerg": return 1.6
	return 1.0

# ---------------- uygunluk ve ağırlık ----------------
func evre_uyumu(o: Dictionary) -> float:
	var lv: int = kart.seviye()
	var e: Array = o["ev"]
	if lv < e[0]:
		return 0.0
	if lv <= e[1]:
		return 1.0
	match lv - e[1]:
		1: return 0.35
		2: return 0.1
	return 0.0

func uygun(id: String) -> bool:
	return agirlik(id) > 0.0

func agirlik(id: String) -> float:
	var o: Dictionary = liste[id]
	var y: Dictionary = oyun.yol
	if y["once"].has(id) or oyun.t < y["cool"].get(id, -99999):
		return 0.0
	var w: float = float(o["w"]) * evre_uyumu(o)
	if w <= 0.0:
		return 0.0
	if not kosul(o.get("k", "")):
		return 0.0
	if o.has("f"):
		if _aileler(o["f"]).is_empty():
			return 0.0
		w *= _dunya_carpan(o["f"])
	if o.has("yol"):
		w *= clampf(0.6 + Y.puan(o["yol"]) / 50.0, 0.6, 2.0)
	if o.has("tip"):
		w *= 2.0 if oyun.un_k.tip()["ad"] in o["tip"] else 0.5
	if o.has("bec"):
		w *= 0.7 + 0.06 * _stat(o["bec"])
	var tag: String = o.get("tag", "")
	if tag != "" and tag == y.get("son_tag", ""):
		w *= 0.4
	if tag == "kriz" and (oyun.arama >= 70.0 or _v("savas") > 0.0):
		w *= 0.25
	return w

func hazirla(id: String) -> void:
	var o: Dictionary = liste[id]
	_f = ""
	if o.has("f"):
		var l: Array = _aileler(o["f"])
		if not l.is_empty():
			_f = l[oyun.rng.randi() % l.size()]
	if _f == "":
		_f = oyun.NPC[oyun.rng.randi() % oyun.NPC.size()]
	var idler: Array = oyun.harita.bolgeler.keys()
	_b = idler[oyun.rng.randi() % idler.size()]
	var hl: Array = oyun.isy.keys().filter(func(i): return oyun.isy[i]["haracli"] or oyun.isy[i]["sahip"])
	if not hl.is_empty():
		_b = oyun.harita.yerler[hl[oyun.rng.randi() % hl.size()]]["bolge"]

func _yer(s: String) -> String:
	return s.replace("{F}", oyun.FAK[_f]["ad"] if _f != "" else "bir aile").replace("{B}", oyun.harita.bolgeler[_b]["ad"] if _b != "" else "mahalle")

func metin(id: String) -> String:
	return _yer(liste[id]["m"])

# ---------------- etkiler ----------------
func _olc() -> float:
	return 1.0 + 0.6 * kart.seviye()

func _ayir(t: String) -> Array:
	t = t.strip_edges()
	for i in range(1, t.length()):
		var c: String = t[i]
		if c == "+" or c == "-" or c == "=" or c == ":":
			return [t.substr(0, i), c, t.substr(i + 1)]
	return [t, "", ""]

func _para_say(fx: String) -> Array:
	# [temiz_maliyet, kirli_maliyet]
	var tm := 0.0
	var kr := 0.0
	for tok in fx.split(";", false):
		var p := _ayir(tok)
		if p[1] == "-" and (p[0] == "temiz" or p[0] == "kirli"):
			var v: float = float(p[2]) * _olc()
			if p[0] == "temiz":
				tm += v
			else:
				kr += v
	return [tm, kr]

func yeterli(fx: String) -> bool:
	var m := _para_say(fx)
	return oyun.temiz >= m[0] and oyun.temiz + oyun.kirli >= m[0] + m[1]

func _etki_yazi(fx: String) -> String:
	var l: PackedStringArray = []
	for tok in fx.split(";", false):
		var p := _ayir(tok)
		var k: String = p[0]
		var s: String = p[1]
		var v: String = p[2]
		if k == "temiz" or k == "kirli":
			l.append("%s$%d %s" % ["+" if s == "+" else "−", int(round(float(v) * _olc())), k])
		elif k == "ger":
			l.append("{F} ile gerginlik %s%s" % ["+" if s == "+" else "−", v])
		elif k == "adam":
			l.append("Ekibe adam %s%s" % ["+" if s == "+" else "−", v])
		elif k == "hapis":
			l.append("%s gün hapis" % v)
		elif k == "tef":
			l.append("Tefeci borcu %s$%d" % ["+" if s == "+" else "−", int(round(float(v) * _olc()))])
		elif k == "inf":
			l.append("{B}'da nüfuz %s%s" % ["+" if s == "+" else "−", v])
		elif k == "donem":
			l.append("Şehrin havası değişir")
		elif AD_ETIKET.has(k):
			l.append("%s %s%s" % [AD_ETIKET[k], "+" if s == "+" else "−", v])
	return ", ".join(l)

func _uygula_etki(fx: String) -> void:
	var K: RefCounted = oyun.kis_k
	for tok in fx.split(";", false):
		var p := _ayir(tok)
		var k: String = p[0]
		var s: String = p[1]
		var vs: String = p[2]
		var v: float = vs.to_float()
		if s == "-":
			v = -v
		match k:
			"temiz":
				oyun.temiz = maxf(0.0, oyun.temiz + v * _olc())
			"kirli":
				if v < 0.0 and oyun.kirli < -v * _olc():
					var kalan: float = -v * _olc() - oyun.kirli
					oyun.kirli = 0.0
					oyun.temiz = maxf(0.0, oyun.temiz - kalan)
				else:
					oyun.kirli = maxf(0.0, oyun.kirli + v * _olc())
			"arama":
				kart._dosya(v)
			"y.kanun": Y.ekle("kanun", v)
			"y.golge": Y.ekle("golge", v)
			"y.korku": Y.ekle("korku", v)
			"y.kulis": Y.ekle("kulis", v)
			"sevgi": oyun.un_k.ekle("sevgi", v)
			"saygi": oyun.un_k.ekle("saygi", v)
			"fed": oyun.nuf_k.fed_ekle(v)
			"dok.polis", "dok.yargic", "dok.siyasi":
				var kk: String = k.substr(4)
				oyun.nuf["dokun"][kk] = clampf(oyun.nuf_k.dokun(kk) + v, 0.0, 100.0)
			"sad":
				for a in oyun.adamlar:
					a["sadakat"] = clampf(oyun.nuf_k.sadakat(a) + v, 0.0, 100.0)
			"stres": K.stres_ekle(v)
			"yara": oyun.kis["yara"] = clampf(float(oyun.kis.get("yara", 0.0)) + v, 0.0, 100.0)
			"rezil": oyun.kotu_k._rezil_ekle(v)
			"nam": oyun.aile["nam"] = clampi(int(oyun.aile["nam"]) + int(v), 0, 10)
			"tef":
				oyun.kotu["tef"] = maxf(0.0, float(oyun.kotu["tef"]) + v * _olc())
				if v > 0.0:
					oyun.kirli += v * _olc()
			"ger":
				if _f != "":
					oyun.gerginlik.ekle("oyuncu", _f, v, "olay")
			"inf":
				if _b != "":
					oyun.add_inf(oyun.bolge[_b], "oyuncu", v)
			"adam":
				if v > 0.0:
					for i in int(v):
						if oyun.adamlar.size() < oyun.EKIP_MAX:
							oyun.adamlar.append(oyun._yeni_adam())
				else:
					for i in int(-v):
						var bos: Array = oyun.bos_adamlar()
						if not bos.is_empty():
							oyun.adamlar.erase(bos[0])
			"hapis":
				oyun.kotu_k.hapis(int(vs), "Olayın sonucu.")
			"kaz":
				oyun.kaz_k.ver(vs)
			"donem":
				kart.y_donem(vs)
			"es_aday":
				oyun.kisi_k.es_adaylari_uret()
			"sonra":
				var kv: PackedStringArray = vs.split(":")
				var zl: Array = oyun.yol.get("zincir", [])
				zl.append({"id": kv[0], "t": oyun.t + int(kv[1]) * oyun.DAY})
				oyun.yol["zincir"] = zl

# ---------------- seçenekler ----------------
func _olas(p: Variant) -> float:
	if typeof(p) == TYPE_STRING:
		var a: PackedStringArray = str(p).split(",")
		return float(a[0]) + _stat(a[1]) * float(a[2])
	return float(p)

func _olas_yazi(p: Variant) -> String:
	var x: float = clampf(_olas(p), 0.05, 0.95)
	return "%%%d" % int(round(x * 100.0))

func secenekler(id: String) -> Array:
	var o: Dictionary = liste[id]
	var r: Array = []
	for s in o["s"]:
		var kosul_ok: bool = kosul(s[1]) and yeterli(s[3]) and (typeof(s[2]) != TYPE_FLOAT or float(s[2]) >= 1.0 or yeterli(s[5]) or true)
		var ip: String
		if typeof(s[2]) == TYPE_FLOAT and float(s[2]) >= 1.0:
			ip = _etki_yazi(s[3])
		else:
			ip = "%s şans: %s." % [_olas_yazi(s[2]), _etki_yazi(s[3])]
			if str(s[5]) != "":
				ip += " Olmazsa: %s." % _etki_yazi(s[5])
		if ip == "" or ip == " şans: .":
			ip = "Hiçbir şey olmaz."
		r.append({"ad": _yer(s[0]), "ipucu": _yer(ip), "can": kosul_ok})
	return r

func uygula(id: String, n: int) -> Dictionary:
	var o: Dictionary = liste[id]
	var s: Array = o["s"][n]
	var kesin: bool = typeof(s[2]) == TYPE_FLOAT and float(s[2]) >= 1.0
	var ok: bool = kesin or oyun.rng.randf() < clampf(_olas(s[2]), 0.05, 0.95)
	var fx: String = s[3] if ok else s[5]
	var txt: String = s[4] if ok else s[6]
	_uygula_etki(fx)
	var y: Dictionary = oyun.yol
	y["bekleyen"] = ""
	y["cool"][id] = oyun.t + int(o.get("cd", 12)) * oyun.DAY
	if o.get("tek", false):
		y["once"][id] = true
	y["son_tag"] = o.get("tag", "")
	var ek: String = _etki_yazi(fx)
	var m: String = _yer(txt)
	if ek != "":
		m += " (" + _yer(ek) + ")"
	var tur := "info" if kesin else ("good" if ok else "bad")
	K_oz(id, n)
	oyun.kayit("%s: %s" % [o["b"], m], tur)
	oyun.degisti.emit()
	return {"metin": m, "tur": tur}

func K_oz(_id: String, _n: int) -> void:
	oyun.kis_k.degis("sikinti", -12.0)

# Zincir: sırası gelmiş bir olay varsa onu döndürür.
func zincir_cek() -> String:
	var zl: Array = oyun.yol.get("zincir", [])
	for i in zl.size():
		if oyun.t >= int(zl[i]["t"]) and liste.has(zl[i]["id"]):
			var id: String = zl[i]["id"]
			zl.remove_at(i)
			return id
	return ""
