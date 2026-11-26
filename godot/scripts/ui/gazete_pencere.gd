extends Control
# Harbor Herald: günlük/haftalık gazete penceresi (yalnızca evde açılır).
# Sekmeler: Haberler · Haftanın özeti (pazartesi sayısı) · İş ilanları · Emlak · Meydan.

const Tema := preload("res://scripts/ui/tema.gd")
const KAGIT := Color(0.93, 0.89, 0.78)
const KAGIT2 := Color(0.88, 0.83, 0.7)
const MUREKKEP := Color(0.13, 0.1, 0.07)
const SOLUK := Color(0.4, 0.34, 0.26)
const TUR_RENK := {
	"mafya": Color(0.62, 0.12, 0.16), "polis": Color(0.15, 0.25, 0.5), "catisma": Color(0.7, 0.1, 0.08), "ekonomi": Color(0.2, 0.42, 0.2),
	"emlak": Color(0.5, 0.35, 0.1), "saglik": Color(0.5, 0.2, 0.45), "meydan": Color(0.15, 0.4, 0.45), "tarih": Color(0.25, 0.25, 0.3),
	"mahalle": Color(0.35, 0.3, 0.2), "magazin": Color(0.55, 0.3, 0.45),
}

var oyun: Node
var arayuz: Node
var G: RefCounted
var _sec := -1            # seçili sayı indeksi
var _sekme := "haber"
var _ic: VBoxContainer
var _icerik: VBoxContainer
var _sonuc := ""
var _sonuc_lbl: Label

func kur(o: Node, a: Node) -> void:
	oyun = o
	arayuz = a
	G = oyun.gaz_k
	G.oku()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Tema.tema()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var kutu := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = KAGIT
	sb.border_color = Color(0.25, 0.2, 0.14)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(3)
	sb.set_content_margin_all(18)
	kutu.add_theme_stylebox_override("panel", sb)
	kutu.custom_minimum_size = Vector2(900, 640)
	kutu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	kutu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	kutu.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(kutu)
	_ic = VBoxContainer.new()
	_ic.add_theme_constant_override("separation", 8)
	kutu.add_child(_ic)
	_sec = oyun.gaz["sayilar"].size() - 1
	_ciz()

func _l(ebeveyn: Node, t: String, boy: int = 15, renk: Color = MUREKKEP) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
	if ebeveyn is VBoxContainer:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ebeveyn.add_child(l)
	return l

func _b(ebeveyn: Node, t: String, f: Callable, kapali: bool = false) -> Button:
	var b := Button.new()
	b.text = t
	b.focus_mode = Control.FOCUS_NONE
	b.disabled = kapali
	b.pressed.connect(f)
	ebeveyn.add_child(b)
	return b

func _cizgi(ebeveyn: Node) -> void:
	var c := ColorRect.new()
	c.color = Color(0.25, 0.2, 0.14)
	c.custom_minimum_size = Vector2(0, 2)
	ebeveyn.add_child(c)

func _sayi() -> Dictionary:
	var s: Array = oyun.gaz["sayilar"]
	if s.is_empty():
		return {}
	return s[clampi(_sec, 0, s.size() - 1)]

func _ciz() -> void:
	for c in _ic.get_children():
		c.queue_free()
	var sy: Dictionary = _sayi()
	var ust := HBoxContainer.new()
	_ic.add_child(ust)
	var ad := _l(ust, "THE HARBOR HERALD", 34, MUREKKEP)
	ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_b(ust, "Kapat", func(): arayuz.gazete_kapandi(); queue_free())
	_cizgi(_ic)
	var tip := "HAFTALIK ÖZEL SAYI" if sy.get("tip", "") == "haftalik" else "GÜNLÜK SAYI"
	var alt := _l(_ic, "%s · No. %d · %s · %s" % [sy.get("tarih", ""), sy.get("no", 0), tip, sy.get("hava", "")], 13, SOLUK)
	alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	# sayı seçici
	var sh := HFlowContainer.new()
	_ic.add_child(sh)
	sh.visible = false
	# sekmeler
	var sk := HBoxContainer.new()
	_ic.add_child(sk)
	var sekmeler: Array = [["haber", "Haberler"]]
	if sy.get("tip", "") == "haftalik":
		sekmeler.append(["hafta", "Haftanın Özeti"])
	sekmeler.append_array([["ilan", "İş İlanları"], ["emlak", "Emlak ve Fiyatlar"], ["meydan", "Meydan"]])
	for t in sekmeler:
		var id: String = t[0]
		var bt2 := _b(sk, t[1], func():
			_sekme = id
			_ciz())
		bt2.disabled = id == _sekme
	_cizgi(_ic)
	var kaydir := ScrollContainer.new()
	kaydir.size_flags_vertical = Control.SIZE_EXPAND_FILL
	kaydir.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	kaydir.custom_minimum_size = Vector2(0, 470)
	_ic.add_child(kaydir)
	_icerik = VBoxContainer.new()
	_icerik.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_icerik.add_theme_constant_override("separation", 10)
	kaydir.add_child(_icerik)
	match _sekme:
		"haber": _haberler(sy)
		"hafta": _hafta(sy)
		"ilan": _ilanlar()
		"emlak": _emlak(sy)
		"meydan": _meydan(sy)
	_sonuc_lbl = _l(_ic, _sonuc, 14, Color(0.5, 0.15, 0.1))

func _haber_kart(h: Dictionary, buyuk: bool = false) -> void:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = KAGIT2
	var rk: Color = TUR_RENK.get(h.get("tur", "mahalle"), SOLUK)
	sb.border_color = rk
	sb.border_width_left = 5
	sb.set_content_margin_all(10)
	p.add_theme_stylebox_override("panel", sb)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_icerik.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 3)
	p.add_child(v)
	_l(v, G.TUR.get(h.get("tur", "mahalle"), "HABER"), 12, rk)
	_l(v, h.get("bas", ""), 26 if buyuk else 18, MUREKKEP)
	_l(v, h.get("metin", ""), 16 if buyuk else 14, Color(0.2, 0.16, 0.12))

func _haberler(sy: Dictionary) -> void:
	if sy.is_empty():
		_l(_icerik, "Bugün gazete yok.", 16)
		return
	if not sy["manset"].is_empty():
		_haber_kart(sy["manset"], true)
	for h in sy["haber"]:
		_haber_kart(h)
	if not sy["meydan"].is_empty():
		_l(_icerik, "MEYDAN PROGRAMI", 13, TUR_RENK["meydan"])
		for m in sy["meydan"]:
			_l(_icerik, "• " + m, 14)
	_l(_icerik, "İLAN: " + sy["reklam"], 13, SOLUK)

func _hafta(sy: Dictionary) -> void:
	var H: Dictionary = sy.get("hafta", {})
	if H.is_empty():
		return
	_l(_icerik, "HAFTANIN BİLANÇOSU", 16, MUREKKEP)
	if H["bilanco"].is_empty():
		_l(_icerik, "Bu hafta olağanüstü bir olay kaydedilmedi.", 14)
	for b in H["bilanco"]:
		_l(_icerik, "• " + b, 14)
	if not H["seri"].is_empty():
		_l(_icerik, "BÜYÜK OLAY ÖRGÜLERİ", 16, MUREKKEP)
		for s in H["seri"]:
			var p := PanelContainer.new()
			var sb := StyleBoxFlat.new()
			sb.bg_color = KAGIT2
			sb.border_color = Color(0.25, 0.2, 0.14)
			sb.border_width_left = 5
			sb.set_content_margin_all(10)
			p.add_theme_stylebox_override("panel", sb)
			_icerik.add_child(p)
			var v := VBoxContainer.new()
			p.add_child(v)
			_l(v, s["ad"], 17, MUREKKEP)
			for x in s["satir"]:
				_l(v, "%s: %s" % [G.tarih_yazi(int(x["gun"])), x["bas"]], 13, Color(0.2, 0.16, 0.12))
	_l(_icerik, "HAFTANIN ÖNE ÇIKAN OLAYLARI", 16, MUREKKEP)
	for h in H["olaylar"]:
		_haber_kart(h)
	_l(_icerik, "EKONOMİ", 16, MUREKKEP)
	for e in H["ekonomi"]:
		_l(_icerik, "• " + e, 14)

func _ilanlar() -> void:
	var K: RefCounted = oyun.meslek
	var gun: int = int(oyun.gaz["ilan_gun"])
	_l(_icerik, "RESMÎ İŞ İLANLARI — son basım: %s" % G.tarih_yazi(gun), 16, MUREKKEP)
	_l(_icerik, "Bu pano yalnızca gazeteyi okuduğunda yenilenir. İşe girince ilandaki iş yerine gidip mesai yapmalısın.", 13, SOLUK)
	var M: Dictionary = oyun.mes
	for ad in K.ilanlar():
		var aj: String = ad["j"]
		var k2: Dictionary = K.kabul(aj, ad["bolge"])
		var mu: int = int(round(K.maas_gun(aj, ad["bolge"]) * ad["carpan"] * K.donem_carpan(aj)))
		var h := HBoxContainer.new()
		_icerik.add_child(h)
		var lb := _l(h, "%s · %s (%s) · mesai ~%s" % [K.MESLEKLER[aj]["ad"], oyun.harita.yerler[ad["bina"]]["ad"], oyun.harita.bolgeler[ad["bolge"]]["ad"], oyun.para(mu)], 14)
		lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_b(h, "Başvur (%d/%d)" % [k2["puan"], k2["esik"]], func():
			var r: Dictionary = K.is_gir(aj, ad["bolge"], ad["bina"], ad["carpan"])
			_sonuc = r.get("msg", "")
			_ciz(), not M["is"].is_empty())
	if K.ilanlar().is_empty():
		_l(_icerik, "Bu hafta ilan yok.", 14)

func _emlak(sy: Dictionary) -> void:
	var E: Dictionary = oyun.gaz["emlak"]
	if sy.has("emlak"):
		E = sy["emlak"]
	_l(_icerik, "EMLAK PİYASASI — %s" % (G.tarih_yazi(int(E["gun"])) if int(E["gun"]) >= 0 else "henüz haftalık özet yok"), 16, MUREKKEP)
	if E["satir"].is_empty():
		_l(_icerik, "Bu hafta anlamlı bir fiyat değişimi kaydedilmedi.", 14)
	for s in E["satir"]:
		var o: float = float(s.get("oran", 0.0))
		_l(_icerik, ("▲ " if o > 0 else "▼ ") + s["bas"], 14, Color(0.15, 0.4, 0.15) if o > 0 else Color(0.6, 0.12, 0.1))
	_l(_icerik, "KİRALIK / SATILIK İLANLARI", 16, MUREKKEP)
	var n := 0
	for i in oyun.isy:
		var r: Dictionary = oyun.isy[i]
		if r.get("bos", false) and not r["sahip"] and n < 10:
			n += 1
			_l(_icerik, "• %s%s (%s) — %s" % [oyun.harita.yerler[i]["ad"], " [DEVREN SATILIK]" if r.get("devren", false) else "", oyun.harita.bolgeler[oyun.harita.yerler[i]["bolge"]]["ad"], oyun.para(oyun.devren_fiyat(i) if r.get("devren", false) else oyun.ilan_fiyat(i))], 14)
	if n == 0:
		_l(_icerik, "Şu an boş ilan yok.", 14)

func _meydan(sy: Dictionary) -> void:
	_l(_icerik, "LIBERTY MEYDANI — RESMÎ PROGRAM", 16, MUREKKEP)
	var e: Dictionary = G.etk()
	if e.is_empty():
		_l(_icerik, "Önümüzdeki günler için meydanda bildirilmiş bir program yok.", 14)
	else:
		_l(_icerik, "%s: %s — %s günü 14:00–18:00" % [G.ETK_AD.get(e["tur"], "Etkinlik"), e["ad"], G.GUN_AD[int(e["gun"]) % 7]], 15, TUR_RENK["meydan"])
		if e.has("duyuru"):
			_l(_icerik, String(e["duyuru"]), 14)
	_l(_icerik, "SON ETKİNLİKLER", 16, MUREKKEP)
	var gec: Array = oyun.gaz["gec"]
	if gec.is_empty():
		_l(_icerik, "Henüz kayıtlı etkinlik yok.", 14)
	for i in range(gec.size() - 1, -1, -1):
		_l(_icerik, "• %s — %s: %s" % [G.tarih_yazi(int(gec[i]["gun"])), gec[i]["ad"], gec[i]["sonuc"]], 14)
