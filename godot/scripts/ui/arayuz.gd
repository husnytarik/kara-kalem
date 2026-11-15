extends CanvasLayer
# 2D arayüz şablonu: üst çubuk (tarih, para, ekip, hız), sağ panel (bina / bölge / adamlar / defter),
# sol altta son olaylar. Her şey kodla kuruluyor; görünümü değiştirmek için _stil(), RENK ve
# font boyutlarını değiştirmen yeter. Veri tarafı oyun.gd'dedir; burada kural yok, yalnızca gösterim.

const RENK := {
	"good": Color("7ed07e"), "bad": Color("ee7070"), "warn": Color("f0b060"), "info": Color("d0d0d0"),
	"altin": Color("e0b24a"), "soluk": Color(1, 1, 1, 0.6),
}

var oyun: Node
var sokak: Node
var _mod := ""
var _hedef: Variant = null
var _son_imza := ""
var _sonuc := ""
var _sonuc_tur := "info"
var _adam_secim := 0
var _adam_idler: Array = []

var _tarih: Label
var _saat: Label
var _temiz: Label
var _kirli: Label
var _ekip: Label
var _durum: Label
var _sag: PanelContainer
var _ic: VBoxContainer
var _log: VBoxContainer
var _log_n := -1

func kur(o: Node, s: Node) -> void:
	oyun = o
	sokak = s
	_ust_cubuk()
	_sag_panel()
	_log = VBoxContainer.new()
	_log.position = Vector2(16, 520)
	_log.custom_minimum_size = Vector2(620, 0)
	add_child(_log)

# ---------- kurulum ----------
func _stil(arka: Color = Color(0.07, 0.07, 0.09, 0.93)) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = arka
	sb.border_color = Color(0.7, 0.55, 0.2, 0.9)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(6)
	sb.set_content_margin_all(10)
	return sb

func _lbl(ebeveyn: Node, metin: String, boyut: int = 16, renk: Color = Color.WHITE) -> Label:
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", boyut)
	l.add_theme_color_override("font_color", renk)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ebeveyn.add_child(l)
	return l

func _btn(ebeveyn: Node, metin: String, fn: Callable, pasif: bool = false) -> Button:
	var b := Button.new()
	b.text = metin
	b.focus_mode = Control.FOCUS_NONE   # Boşluk tuşu düğmeye basmasın
	b.disabled = pasif
	b.pressed.connect(fn)
	ebeveyn.add_child(b)
	return b

func _bar(ebeveyn: Node, ad: String, deger: float, renk: Color, yazi: String = "") -> void:
	var h := HBoxContainer.new()
	ebeveyn.add_child(h)
	var l := _lbl(h, ad, 15)
	l.size_flags_horizontal = Control.SIZE_FILL
	l.custom_minimum_size = Vector2(105, 0)
	var p := ProgressBar.new()
	p.min_value = 0
	p.max_value = 100
	p.value = deger
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, 14)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := StyleBoxFlat.new()
	f.bg_color = renk
	p.add_theme_stylebox_override("fill", f)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(1, 1, 1, 0.1)
	p.add_theme_stylebox_override("background", bg)
	h.add_child(p)
	var v := _lbl(h, yazi if yazi != "" else str(int(round(deger))), 14, RENK["soluk"])
	v.size_flags_horizontal = Control.SIZE_FILL
	v.custom_minimum_size = Vector2(44, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _ayrac(ebeveyn: Node) -> void:
	ebeveyn.add_child(HSeparator.new())

func _ust_cubuk() -> void:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _stil())
	pc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	pc.offset_left = 8
	pc.offset_right = -8
	pc.offset_top = 6
	add_child(pc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 22)
	pc.add_child(h)
	var sol := VBoxContainer.new()
	h.add_child(sol)
	_tarih = _lbl(sol, "", 15, RENK["soluk"])
	_saat = _lbl(sol, "", 22, RENK["altin"])
	_temiz = _lbl(h, "", 20, Color("9be39b"))
	_kirli = _lbl(h, "", 20, Color("e09b9b"))
	_ekip = _lbl(h, "", 18)
	_durum = _lbl(h, "", 18, RENK["warn"])
	for l in [_tarih, _saat, _temiz, _kirli, _ekip, _durum]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var bosluk := Control.new()
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(bosluk)
	for hv in [["⏸", 0.0], ["×1", 1.0], ["×2", 2.0], ["×4", 4.0]]:
		_btn(h, hv[0], sokak.hiz_ayarla.bind(hv[1]))
	_btn(h, "Bölge", _bolge_dugmesi)
	_btn(h, "Adamlar", adamlar_ac)
	_btn(h, "Defter", defter_ac)

func _sag_panel() -> void:
	_sag = PanelContainer.new()
	_sag.add_theme_stylebox_override("panel", _stil())
	_sag.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_sag.offset_left = -400
	_sag.offset_right = -8
	_sag.offset_top = 86
	_sag.offset_bottom = -40
	_sag.visible = false
	add_child(_sag)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sag.add_child(sc)
	_ic = VBoxContainer.new()
	_ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ic.add_theme_constant_override("separation", 6)
	sc.add_child(_ic)

# ---------- açma / kapama ----------
func bina_ac(i: int) -> void:
	_mod = "bina"
	_hedef = i
	_adam_secim = 0
	_sonuc = ""
	_yenile(true)

func bolge_ac(id: String) -> void:
	_mod = "bolge"
	_hedef = id
	_sonuc = ""
	_yenile(true)

func adamlar_ac() -> void:
	if _mod == "adamlar":
		kapat()
		return
	_mod = "adamlar"
	_sonuc = ""
	_yenile(true)

func grup_ac(g: Dictionary) -> void:
	_mod = "grup"
	_hedef = g
	_sonuc = ""
	_yenile(true)

func defter_ac() -> void:
	if _mod == "defter":
		kapat()
		return
	_mod = "defter"
	_yenile(true)

func _bolge_dugmesi() -> void:
	if _mod == "bolge":
		kapat()
		return
	var id: String = sokak.harita.bolge_at(sokak.oyuncu.global_position)
	if id == "":
		id = "southside"
	bolge_ac(id)

func kapat() -> void:
	_mod = ""
	_sag.visible = false

func _sonuc_goster(r: Dictionary, tamam_yazi: String = "Tamam.") -> void:
	_sonuc = r["msg"] if r["msg"] != "" else tamam_yazi
	_sonuc_tur = "good" if r["ok"] else "bad"
	_yenile(true)

# ---------- döngü ----------
func _process(_d: float) -> void:
	var d: Dictionary = oyun.tarih()
	_tarih.text = "%s · %s" % [oyun.tarih_yazi(), oyun.mevsim()]
	_saat.text = oyun.saat_yazi()
	_temiz.text = "Temiz %s" % oyun.para(oyun.temiz)
	_kirli.text = "Kirli %s" % oyun.para(oyun.kirli)
	_ekip.text = "Ekip %d/%d" % [oyun.adamlar.size(), oyun.EKIP_MAX]
	_durum.text = "DURAKLATILDI" if Engine.time_scale == 0.0 else ""
	if oyun.defter.size() != _log_n:
		_log_n = oyun.defter.size()
		for c in _log.get_children():
			c.queue_free()
		var son: Array = oyun.defter.slice(maxi(0, _log_n - 5))
		for e in son:
			var l := _lbl(_log, "%s  %s" % [oyun.saat_yazi(e["t"]), e["metin"]], 15, RENK[e["tur"]])
			l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
			l.add_theme_constant_override("outline_size", 6)
	if _mod != "":
		_yenile(false)
	if d["gun"] < 0:
		return

func _imza() -> String:
	match _mod:
		"bina":
			var i: int = _hedef
			var y: Dictionary = oyun.harita.yerler[i]
			var gs: Array = oyun.gorevler.filter(func(g): return g["hedef"] == i).map(func(g): return [g["adam"], g["gorev"], (g["bitis"] - oyun.t) / 60])
			return str([oyun.isy.get(i), oyun.kontrol(i), oyun.bolge[y["bolge"]]["inf"], oyun.bos_adamlar().map(func(a): return a["id"]), gs, oyun.temiz, oyun.kirli, _sonuc])
		"bolge":
			return str([oyun.bolge[_hedef], oyun.erisim(_hedef), oyun.temiz, oyun.kirli, oyun.adamlar.size(), oyun.tarih()["gun"], _sonuc])
		"adamlar":
			return str([oyun.adamlar, oyun.gorevler.map(func(g): return [g["adam"], (g["bitis"] - oyun.t) / 60]), oyun.kirli, _sonuc])
		"grup":
			var g: Dictionary = _hedef
			return str([g["kisi"], g["durum"], g["ev"], sokak.gruplar.liste.has(g)])
		"defter":
			return str(oyun.defter.size())
	return ""

func _yenile(zorla: bool) -> void:
	var imza := _imza()
	if not zorla and imza == _son_imza:
		return
	_son_imza = imza
	for c in _ic.get_children():
		c.queue_free()
	_sag.visible = true
	match _mod:
		"bina": _bina_paneli()
		"bolge": _bolge_paneli()
		"adamlar": _adam_paneli()
		"defter": _defter_paneli()
		"grup": _grup_paneli()
	_kapat_dugmesi()

func _kapat_dugmesi() -> void:
	_ayrac(_ic)
	_btn(_ic, "Kapat", kapat)

func _sonuc_satiri() -> void:
	if _sonuc != "":
		_lbl(_ic, _sonuc, 15, RENK[_sonuc_tur])

# ---------- bina paneli ----------
func _bina_paneli() -> void:
	var i: int = _hedef
	var y: Dictionary = oyun.harita.yerler[i]
	var bid: String = y["bolge"]
	_lbl(_ic, y["ad"], 24, RENK["altin"] if y["ozel"] else Color.WHITE)
	_lbl(_ic, "%s · %s" % [oyun.harita.bolgeler[bid]["ad"], oyun.tur_ad(i)], 15, RENK["soluk"])
	_btn(_ic, "Bölge bilgisi", bolge_ac.bind(bid))
	_ayrac(_ic)
	if not oyun.isy.has(i):
		if y["ozel"]:
			_lbl(_ic, "Özel mekân. Buraya ileride kendi görevleri ve konuşmaları gelecek.", 15, RENK["soluk"])
		else:
			_lbl(_ic, "Resmî kurum: haraç bağlanamaz, satın alınamaz.", 15, RENK["soluk"])
		return
	var r: Dictionary = oyun.isy[i]
	var k: String = oyun.kontrol(i)
	var kontrol_yazi := "Sahipsiz (kimse koruma parası almıyor)"
	var kontrol_renk := RENK["info"]
	if k == "sahip":
		kontrol_yazi = "Sahibi sensin"
		kontrol_renk = RENK["good"]
	elif k == "haraci":
		kontrol_yazi = "Haracını sen alıyorsun"
		kontrol_renk = RENK["good"]
	elif k != "":
		kontrol_yazi = "%s koruma parası alıyor" % oyun.hakim_ad(k)
		kontrol_renk = RENK["warn"]
	_lbl(_ic, kontrol_yazi, 17, kontrol_renk)
	_lbl(_ic, "Haftalık gelir: %s" % oyun.para(oyun.haftalik(i)), 16)
	if r["haracli"]:
		_lbl(_ic, "Biriken haraç: %s" % oyun.para(r["birikim"]), 16, RENK["altin"])
	_lbl(_ic, "Direnç: %d · Fiyat: %s" % [oyun.TURLER[r["tur"]]["direnc"] * 10, oyun.para(oyun.fiyat(i))], 15, RENK["soluk"])
	_ayrac(_ic)
	for g in oyun.gorevler:
		if g["hedef"] == i:
			var a: Dictionary = oyun.adam_bul(g["adam"])
			var kalan: int = maxi(1, int(ceil((g["bitis"] - oyun.t) / 60.0)))
			_lbl(_ic, "%s: %s (~%d saat)" % [a.get("ad", "?"), "tutuklu" if g["gorev"] == "tutuklu" else oyun.GOREVLER[g["gorev"]]["ad"].to_lower(), kalan], 15, RENK["warn"])
	var bos: Array = oyun.bos_adamlar()
	_adam_idler = [0]
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.add_item("Adam: otomatik (en uygun)")
	for a in bos:
		ob.add_item("%s · beceri %d" % [a["ad"], oyun.beceri(a)])
		_adam_idler.append(a["id"])
	ob.selected = clampi(_adam_secim, 0, _adam_idler.size() - 1)
	ob.item_selected.connect(func(n: int): _adam_secim = n)
	_ic.add_child(ob)
	var secili: int = _adam_idler[clampi(_adam_secim, 0, _adam_idler.size() - 1)]
	for gk in ["haraclan", "topla", "koru"]:
		_btn(_ic, "%s  (%d dk iş)" % [oyun.GOREVLER[gk]["ad"], oyun.GOREVLER[gk]["is"]], func(): _sonuc_goster(oyun.gorev_ver(i, gk, secili), "Adam yola çıktı."))
	_btn(_ic, "Satın al  (%s temiz)" % oyun.para(oyun.fiyat(i)), func(): _sonuc_goster(oyun.satin_al(i), "Satın aldın."), r["sahip"])
	_btn(_ic, "Buraya git", func(): sokak.oyuncu.git(y["pos"]))
	_sonuc_satiri()

# ---------- bölge paneli ----------
func _bolge_paneli() -> void:
	var id: String = _hedef
	var b: Dictionary = oyun.bolge[id]
	var hk: String = oyun.hakim_of(id)
	_lbl(_ic, oyun.harita.bolgeler[id]["ad"], 24, RENK["altin"])
	_lbl(_ic, oyun.ACIKLAMA[id], 15, RENK["soluk"])
	_lbl(_ic, oyun.KARAKTER[id]["ac"], 15, RENK["soluk"])
	_ayrac(_ic)
	_lbl(_ic, "Hakim: %s" % oyun.hakim_ad(hk), 18, oyun.FAK[hk]["renk"] if hk != "" else Color.WHITE)
	if hk != "oyuncu":
		_lbl(_ic, "Hakim olmak için +%.1f nüfuz gerekir." % oyun.hakim_icin_kalan(id), 15, RENK["soluk"])
	_lbl(_ic, "Nüfuz", 16, RENK["altin"])
	var sirali: Array = b["inf"].keys()
	sirali.sort_custom(func(a, c): return b["inf"][a] > b["inf"][c])
	for f in sirali:
		_bar(_ic, oyun.FAK[f]["ad"], b["inf"][f], oyun.FAK[f]["renk"])
	_ayrac(_ic)
	_lbl(_ic, "Servet: " + "★".repeat(b["servet"]) + "☆".repeat(oyun.SERVET_MAX - b["servet"]), 16)
	_bar(_ic, "Huzur", b["huzur"], Color("6fa8dc"))
	_bar(_ic, "Sevgi", b["sev"], Color("7ed07e"))
	_bar(_ic, "Korku", b["kor"], Color("d96060"))
	_bar(_ic, "Tanınırlık", b["tan"], Color("c9a0dc"))
	_ayrac(_ic)
	if not oyun.erisim(id):
		_lbl(_ic, "Buraya girmek için önce komşu bir bölgeye hakim ol.", 15, RENK["warn"])
	else:
		_lbl(_ic, "Bölge işleri", 16, RENK["altin"])
		for tur in ["himaye", "hediye", "gozdagi"]:
			_btn(_ic, "%s  (%s)" % [oyun.IS_AD[tur], oyun.IS_BEDEL[tur]], func(): _sonuc_goster(oyun.bolge_is(id, tur)))
	if hk == "oyuncu":
		_ayrac(_ic)
		_lbl(_ic, "Yönetim", 16, RENK["altin"])
		_btn(_ic, "Yatırım yap  ($400 temiz)", func(): _sonuc_goster(oyun.bolge_yatirim(id)))
		var ob := OptionButton.new()
		ob.focus_mode = Control.FOCUS_NONE
		for h in oyun.HARAC:
			ob.add_item("Haraç: " + h[0])
		ob.selected = b["harac"]
		ob.item_selected.connect(func(n: int): oyun.bolge_harac(id, n))
		_ic.add_child(ob)
	_sonuc_satiri()

# ---------- adam paneli ----------
func _adam_paneli() -> void:
	_lbl(_ic, "Adamlar", 24, RENK["altin"])
	_lbl(_ic, "%d / %d adam · ayda $%d kişi başı" % [oyun.adamlar.size(), oyun.EKIP_MAX, oyun.EKIP_MAAS], 15, RENK["soluk"])
	_btn(_ic, "Adam tut  ($%d kirli)" % oyun.EKIP_FIYAT, func(): _sonuc_goster(oyun.adam_tut(), "Adam tuttun."))
	_ayrac(_ic)
	if oyun.adamlar.is_empty():
		_lbl(_ic, "Ekibin boş. Adam olmadan haraç bağlayamazsın.", 15, RENK["warn"])
	for a in oyun.adamlar:
		_lbl(_ic, "%s  ·  beceri %d" % [a["ad"], oyun.beceri(a)], 18)
		_bar(_ic, "Yumruk", a["yumruk"], Color("d98a4a"))
		_bar(_ic, "Bıçak", a["bicak"], Color("c26a6a"))
		_bar(_ic, "Zekâ", a["zeka"], Color("6fa8dc"))
		var durum := "Boşta"
		if a["gorev"] == "tutuklu":
			durum = "Karakolda"
		elif a["gorev"] != "":
			durum = "Görevde: " + oyun.GOREVLER[a["gorev"]]["ad"]
		_lbl(_ic, durum, 15, RENK["warn"] if a["gorev"] != "" else RENK["good"])
		var id: int = a["id"]
		_btn(_ic, "Çıkar", func(): _sonuc_goster(oyun.adam_cikar(id)), a["gorev"] != "")
		_ayrac(_ic)
	_sonuc_satiri()

# ---------- defter ----------
func _defter_paneli() -> void:
	_lbl(_ic, "Defter", 24, RENK["altin"])
	var n: int = oyun.defter.size()
	for k in range(n - 1, maxi(-1, n - 41), -1):
		var e: Dictionary = oyun.defter[k]
		_lbl(_ic, "%s %s" % [oyun.saat_yazi(e["t"]), e["metin"]], 14, RENK[e["tur"]])

# ---------- grup paneli (polis, rakip ekip, sivil) ----------
func _grup_paneli() -> void:
	var g: Dictionary = _hedef
	if not sokak.gruplar.liste.has(g):
		_lbl(_ic, "Grup dağıldı.", 16, RENK["soluk"])
		return
	var tur_ad := {"polis": "Polis", "rakip": "Rakip ekip", "sivil": "Siviller"}
	var renk: Color = sokak.gruplar._renk(g)
	_lbl(_ic, g["ad"], 24, renk.lerp(Color.WHITE, 0.4))
	_lbl(_ic, "%s · %d kişi" % [tur_ad[g["tur"]], g["kisi"]], 16, RENK["soluk"])
	_ayrac(_ic)
	_lbl(_ic, "Durum: %s" % g["durum"], 16)
	_lbl(_ic, "Bölgesi: %s" % oyun.harita.bolgeler[g["ev"]]["ad"], 16)
	var simdi: String = oyun.harita.bolge_at(g["pos"])
	if simdi != "":
		_lbl(_ic, "Şu an: %s" % oyun.harita.bolgeler[simdi]["ad"], 16)
	match g["tur"]:
		"polis":
			_lbl(_ic, "Devriye gezen polisler. Yanlarında kirli iş yapma; ileride delil ve arama buraya bağlanacak.", 15, RENK["warn"])
		"rakip":
			var f: Dictionary = oyun.FAK[g["fak"]]
			_lbl(_ic, "Fraksiyon: %s" % f["ad"], 16, f["renk"])
			_lbl(_ic, "Bu ekibin bölgesinde rakip sayılırsın. İleride pazarlık, baskın ve çatışma buradan açılacak.", 15, RENK["warn"])
		"sivil":
			_lbl(_ic, "Mahalle halkı. İleride dedikodu ve bilgi buradan alınacak.", 15, RENK["soluk"])
	_ayrac(_ic)
	_btn(_ic, "Yanına git", func(): sokak.oyuncu.git(g["pos"]))
