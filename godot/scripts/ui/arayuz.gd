extends CanvasLayer
# 2D arayüz şablonu: üst çubuk (tarih, para, ekip, hız), sağ panel (bina / bölge / adamlar / defter),
# sol altta son olaylar. Her şey kodla kuruluyor; görünümü değiştirmek için _stil(), RENK ve
# font boyutlarını değiştirmen yeter. Veri tarafı oyun.gd'dedir; burada kural yok, yalnızca gösterim.

const Tema := preload("res://scripts/ui/tema.gd")
const Portre := preload("res://scripts/ui/portre.gd")
const CepSaati := preload("res://scripts/ui/cep_saati.gd")
const Pie := preload("res://scripts/ui/pie_menu.gd")
const RENK := {
	"good": Tema.IYI, "bad": Tema.KOTU, "warn": Tema.UYARI, "info": Tema.BILGI,
	"altin": Tema.VURGU, "soluk": Tema.SOLUK,
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
var _arama: Label
var _sag: PanelContainer
var _ic: VBoxContainer
var _log: VBoxContainer
var _log_panel: PanelContainer
var _log_acik := false
var _log_n := -1
var modal := false           # karşılaşma diyaloğu açıkken true
var _kars: RefCounted
var _dlg: PanelContainer
var _dlg_ic: VBoxContainer
var _dlg_g: Dictionary = {}
var _dlg_sonuc: Dictionary = {}
const YAKIN := 16.0          # bir binayla/grupla işlem için gereken en büyük uzaklık (m)

func kur(o: Node, s: Node) -> void:
	oyun = o
	sokak = s
	_ust_cubuk()
	_amac_paneli()
	_sag_panel()
	_diyalog_kur()
	var saat := CepSaati.new()
	saat.kur(oyun)
	saat.position = Vector2(6, 4)
	add_child(saat)
	var sp := Pie.new()
	sp.kur(true, [["♟", "Ben", ben_ac], ["⚒", "İş", meslek_ac], ["⚙", "Garaj", garaj_ac], ["★", "Hedefler", zafer_ac]])
	sp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	sp.offset_left = 0
	sp.offset_top = -Pie.BOY
	sp.offset_right = Pie.BOY
	sp.offset_bottom = 0
	add_child(sp)
	var rp := Pie.new()
	rp.kur(false, [["♜", "Aileler", aile_ac], ["♞", "Adamlar", adamlar_ac], ["⚑", "Bölgeler", _bolge_dugmesi], ["⚖", "Polis", polis_ac], ["✎", "Defter", defter_ac]])
	rp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	rp.offset_left = -Pie.BOY
	rp.offset_top = -Pie.BOY
	rp.offset_right = 0
	rp.offset_bottom = 0
	add_child(rp)
	_log_panel = PanelContainer.new()
	var lsb := StyleBoxFlat.new()
	lsb.bg_color = Color(0.06, 0.045, 0.03, 0.55)
	lsb.set_corner_radius_all(4)
	lsb.content_margin_left = 8
	lsb.content_margin_right = 8
	lsb.content_margin_top = 3
	lsb.content_margin_bottom = 3
	_log_panel.add_theme_stylebox_override("panel", lsb)
	_log_panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	_log_panel.offset_left = 205
	_log_panel.offset_bottom = -34
	_log_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_log_panel.custom_minimum_size = Vector2(420, 0)
	_log_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_log_panel.tooltip_text = "Tıkla: eski haberleri aç/kapa"
	_log_panel.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_log_acik = not _log_acik
			_log_n = -1
			_log_panel.accept_event())
	add_child(_log_panel)
	_log = VBoxContainer.new()
	_log.add_theme_constant_override("separation", 0)
	_log.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_log_panel.add_child(_log)

# ---------- kurulum ----------
func _stil(arka: Color = Tema.ARKA) -> StyleBoxFlat:
	return Tema.stil(arka)

var _kagit_mod := false   # true iken paneller kâğıt üstünde: açık renkler koyu mürekkebe çevrilir

func _murekkep(c: Color) -> Color:
	if not _kagit_mod:
		return c
	if c.s < 0.18:
		return Tema.KAGIT_YAZI if c.v > 0.62 else Color("5a4630")
	return Color.from_hsv(c.h, minf(1.0, c.s * 1.1), 0.42)

func _lbl(ebeveyn: Node, metin: String, boyut: int = 16, renk: Color = Color.WHITE) -> Label:
	renk = _murekkep(renk)
	var l := Label.new()
	l.text = metin
	l.add_theme_font_size_override("font_size", Tema.boyut(boyut))
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
	l.custom_minimum_size = Vector2(90, 0)
	var p := ProgressBar.new()
	p.min_value = 0
	p.max_value = 100
	p.value = deger
	p.show_percentage = false
	p.custom_minimum_size = Vector2(0, 10)
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var f := StyleBoxFlat.new()
	f.bg_color = renk
	p.add_theme_stylebox_override("fill", f)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.2) if _kagit_mod else Color(1, 1, 1, 0.08)
	p.add_theme_stylebox_override("background", bg)
	h.add_child(p)
	var v := _lbl(h, yazi if yazi != "" else str(int(round(deger))), 14, RENK["soluk"])
	v.size_flags_horizontal = Control.SIZE_FILL
	v.custom_minimum_size = Vector2(44, 0)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _portre(ebeveyn: Node, ad: String, boy: Vector2 = Vector2(56, 64)) -> Control:
	var p := Portre.new()
	p.custom_minimum_size = boy
	p.renk = Color.from_hsv(float(ad.hash() % 360) / 360.0, 0.35, 0.65)
	ebeveyn.add_child(p)
	return p

# Panel başlığı: altın serif başlık + altında ince çizgi.
func _baslik(ebeveyn: Node, metin: String, alt: String = "") -> void:
	var l := _lbl(ebeveyn, metin, 26, RENK["altin"])
	if not _kagit_mod:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 3)
	if alt != "":
		_lbl(ebeveyn, alt, 15, RENK["soluk"])
	_ayrac(ebeveyn)

# Koyu çerçeveli iç kutu (görseldeki "Eylemler" / "Adam Arayanlar" gibi).
func _kutu(ebeveyn: Node, baslik: String = "") -> VBoxContainer:
	var pc := PanelContainer.new()
	if _kagit_mod:
		pc.add_theme_stylebox_override("panel", Tema.stil(Color(0.55, 0.42, 0.24, 0.16), Tema.KAGIT_KENAR, 8, 2))
	else:
		pc.add_theme_stylebox_override("panel", Tema.stil(Color(0.06, 0.045, 0.03, 0.9), Tema.KENAR, 8, 2))
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ebeveyn.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	pc.add_child(v)
	if baslik != "":
		_lbl(v, baslik, 17, RENK["altin"])
	return v

func _ayrac(ebeveyn: Node) -> void:
	ebeveyn.add_child(HSeparator.new())

var _amac_kutu: PanelContainer
var _amac_baslik: Label
var _amac_yazi: Label
var _baski_yazi: Label
var _ihtiyac_yazi: Label

# Sol üstte: şimdiki hedef (içine çeker) + yaklaşan yükümlülükler (ayakta kalma baskısı).
func _amac_paneli() -> void:
	_amac_kutu = PanelContainer.new()
	var asb := StyleBoxFlat.new()
	asb.bg_color = Color(0.06, 0.045, 0.03, 0.55)
	asb.set_corner_radius_all(4)
	asb.content_margin_left = 8
	asb.content_margin_right = 8
	asb.content_margin_top = 4
	asb.content_margin_bottom = 4
	_amac_kutu.add_theme_stylebox_override("panel", asb)
	_amac_kutu.theme = Tema.tema()
	_amac_kutu.position = Vector2(8, 136)
	_amac_kutu.custom_minimum_size = Vector2(250, 0)
	_amac_kutu.mouse_filter = Control.MOUSE_FILTER_STOP
	_amac_kutu.tooltip_text = "Tıkla: ayrıntıyı aç/kapa"
	_amac_kutu.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_amac_acik = not _amac_acik
			_amac_kutu.accept_event())
	add_child(_amac_kutu)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	_amac_kutu.add_child(v)
	_amac_baslik = _lbl(v, "", 12, Color("e0b050"))
	_amac_yazi = _lbl(v, "", 13, Color("e8dcc0"))
	_baski_yazi = _lbl(v, "", 12, Color("b8a888"))
	for q in [_amac_baslik, _amac_yazi, _baski_yazi]:
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ihtiyac_yazi = Label.new()   # eski satır: artık üstteki çubuklarda

var _amac_acik := false
var _ihc: Dictionary = {}
var _ihc_hasta: Label

# Üst çubuğun altında: açlık / yorgunluk / stres / sıkıntı / hasta / ün çubukları.
func _ihtiyac_cubugu(v: Control) -> void:
	var kr := ColorRect.new()
	kr.color = Color(0.17, 0.11, 0.06, 0.6)
	kr.custom_minimum_size = Vector2(2, 0)
	v.add_child(kr)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	h.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	v.add_child(h)
	for hv in [["II", 0.0], ["▶", 1.0], ["×2", 2.0], ["×4", 4.0]]:
		var hb := _btn(h, hv[0], sokak.hiz_ayarla.bind(hv[1]))
		hb.add_theme_font_size_override("font_size", Tema.boyut(14))
	for e in [["aclik", "Açlık", Tema.IYI], ["yorgun", "Yorgunluk", Tema.UYARI], ["stres", "Stres", Tema.KOTU], ["sikinti", "Sıkıntı", Tema.BILGI], ["un", "Ünün", Tema.VURGU]]:
		var c := HBoxContainer.new()
		c.add_theme_constant_override("separation", 5)
		h.add_child(c)
		var l := _lbl(c, "● " + e[1], 13, Tema.KAGIT_YAZI)
		l.add_theme_color_override("font_color", Tema.KAGIT_YAZI)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		var p := ProgressBar.new()
		p.min_value = 0
		p.max_value = 100
		p.show_percentage = false
		p.custom_minimum_size = Vector2(46, 10)
		p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var f := StyleBoxFlat.new()
		f.bg_color = e[2]
		p.add_theme_stylebox_override("fill", f)
		c.add_child(p)
		_ihc[e[0]] = [p, f]
	_ihc_hasta = _lbl(h, "✚ HASTA", 14, Tema.KOTU)
	_ihc_hasta.autowrap_mode = TextServer.AUTOWRAP_OFF
	_ihc_hasta.visible = false

func _ihtiyac_guncelle() -> void:
	var k: Dictionary = oyun.kis
	var v := {"aclik": float(k["aclik"]), "yorgun": float(k["yorgun"]), "stres": float(k["stres"]), "sikinti": float(k["sikinti"]), "un": float(oyun.kis_k.taninma())}
	for a in v:
		var p: ProgressBar = _ihc[a][0]
		p.value = v[a]
		var f: StyleBoxFlat = _ihc[a][1]
		if a != "un" and a != "sikinti":
			f.bg_color = Tema.IYI if v[a] < 40.0 else (Tema.UYARI if v[a] < 70.0 else Tema.KOTU)
	_ihc_hasta.visible = oyun.kis_k.hasta_mi()

func _amac_guncelle() -> void:
	var baslik := "HEDEF"
	var yazi := ""
	var haracli := 0
	var sahip := 0
	for i in oyun.isy:
		if oyun.isy[i]["sahip"]:
			sahip += 1
		elif oyun.isy[i]["haracli"]:
			haracli += 1
	var bolgeler: int = oyun.oyuncu_bolgeleri().size()
	if oyun.adamlar.is_empty():
		yazi = "Önce bir adam tut: T tuşu (Adamlar). Tek başına esnafı sıkıştıramazsın."
	elif haracli + sahip == 0:
		yazi = "Bir esnafa git, paneli aç ve adamınla haraç bağla. Gelir oradan başlar."
	elif bolgeler == 0:
		yazi = "Nüfuzunu büyüt: haraç bağladıkça mahalle senin olur. Haraçlı iş: %d" % (haracli + sahip)
	else:
		yazi = "%d bölge senin. Rakip ailelere karşı büyü: Hedefler panelinde zafer yollarına bak." % bolgeler
	if oyun.arama >= 60.0:
		baslik = "TEHLİKE"
		yazi = "Polis dosyan kabarık (%d). Ortalıkta görünme, rüşvet ver ya da evine gir." % int(oyun.arama)
	var ac: Dictionary = oyun.kis_k.acil()
	if not ac.is_empty() and oyun.arama < 60.0:
		baslik = "İHTİYAÇ"
		yazi = ac["mesaj"]
	_amac_baslik.text = baslik
	if _amac_acik:
		yazi += "
" + oyun.yol_k.ozet_satiri()
	_amac_yazi.text = yazi
	_baski_yazi.visible = _amac_acik
	var k: Dictionary = oyun.kis
	_ihtiyac_guncelle()
	_ihtiyac_yazi.text = "Açlık %d · Yorgun %d · Stres %d · Sıkıntı %d%s · Ünün %d" % [int(k["aclik"]), int(k["yorgun"]), int(k["stres"]), int(k["sikinti"]), " · HASTA" if oyun.kis_k.hasta_mi() else "", int(oyun.kis_k.taninma())]
	_ihtiyac_yazi.add_theme_color_override("font_color", RENK["bad"] if not ac.is_empty() else RENK["soluk"])
	# yükümlülükler
	var d: Dictionary = oyun.tarih()
	var kalan: int = oyun.DAYS_PER_MONTH - int(d["ay_gun"]) + 1
	var borc := 0.0
	if oyun.borc.get("ana", 0.0) > 0.0:
		borc = oyun.borc["taksit"]
	var kira: float = float(oyun.ozet.get("kira", 0)) + oyun.kira_borc
	var toplam := borc + kira
	if toplam <= 0.0:
		_baski_yazi.text = "Ay sonuna %d gün." % kalan
		_baski_yazi.add_theme_color_override("font_color", Color("b8a888"))
	else:
		var yeter: bool = oyun.temiz >= toplam
		_baski_yazi.text = "Ay sonuna %d gün · ödenecek %s (taksit %s + kira %s)%s" % [kalan, oyun.para(toplam), oyun.para(borc), oyun.para(kira), "" if yeter else " — PARA YETMİYOR" ]
		_baski_yazi.add_theme_color_override("font_color", Color("8fd08a") if yeter else (Color("ff8a70") if kalan <= 3 else Color("e0b050")))

var _un: Label
var _konum: Label

func _hap(h: Node, sembol: String, renk: Color) -> Label:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.stil(Color(0.05, 0.035, 0.025, 0.95), Tema.KENAR, 4, 10))
	h.add_child(pc)
	var l := _lbl(pc, sembol, 16, renk)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	return l

func _ust_cubuk() -> void:
	# gazete başlığı: kâğıt zemin, büyük tarih, altında konum; sağında para/ün/ekip rozetleri
	_saat = Label.new()   # saat artık cep saatinde; metin yine de tutulur
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.kagit_panel())
	pc.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	pc.offset_left = 130
	pc.offset_right = -8
	pc.offset_top = 6
	pc.theme = Tema.tema_kagit()
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pc)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 16)
	pc.add_child(h)
	var sol := VBoxContainer.new()
	sol.add_theme_constant_override("separation", 0)
	h.add_child(sol)
	_tarih = Label.new()
	_tarih.add_theme_font_size_override("font_size", Tema.boyut(20))
	_tarih.add_theme_color_override("font_color", Tema.KAGIT_YAZI)
	_tarih.autowrap_mode = TextServer.AUTOWRAP_OFF
	sol.add_child(_tarih)
	var kural := ColorRect.new()
	kural.color = Color(0.17, 0.11, 0.06, 0.75)
	kural.custom_minimum_size = Vector2(0, 2)
	sol.add_child(kural)
	sol.custom_minimum_size = Vector2(190, 0)
	_konum = Label.new()
	_konum.add_theme_font_size_override("font_size", Tema.boyut(13))
	_konum.add_theme_color_override("font_color", Color("6a1f10"))
	_konum.autowrap_mode = TextServer.AUTOWRAP_OFF
	sol.add_child(_konum)
	_ihtiyac_cubugu(h)
	var bosluk := Control.new()
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(bosluk)
	var dik := ColorRect.new()
	dik.color = Color(0.17, 0.11, 0.06, 0.6)
	dik.custom_minimum_size = Vector2(2, 0)
	h.add_child(dik)
	var sag := VBoxContainer.new()
	sag.add_theme_constant_override("separation", 4)
	sag.alignment = BoxContainer.ALIGNMENT_CENTER
	h.add_child(sag)
	var r1 := HBoxContainer.new()
	r1.add_theme_constant_override("separation", 6)
	sag.add_child(r1)
	_temiz = _hap(r1, "", Tema.VURGU)
	_kirli = _hap(r1, "", Tema.KOTU)
	_un = _hap(r1, "", Tema.VURGU)
	var r2 := HBoxContainer.new()
	r2.add_theme_constant_override("separation", 12)
	sag.add_child(r2)
	_ekip = _lbl(r2, "", 15, Tema.KAGIT_YAZI)
	_arama = _lbl(r2, "", 15, Tema.KAGIT_YAZI)
	_durum = _lbl(r2, "", 15, Color("8a2a10"))
	for l in [_ekip, _arama, _durum]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		l.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		l.size_flags_vertical = Control.SIZE_SHRINK_CENTER

func _sag_panel() -> void:
	_sag = PanelContainer.new()
	_sag.add_theme_stylebox_override("panel", Tema.kagit_panel())
	_sag.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_sag.offset_left = -340
	_sag.offset_right = -8
	_sag.offset_top = 66
	_sag.offset_bottom = -200
	_sag.visible = false
	_sag.theme = Tema.tema_kagit()
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

func aile_ac() -> void:
	if _mod == "aile":
		kapat()
		return
	_mod = "aile"
	_yenile(true)

func zafer_ac() -> void:
	if _mod == "zafer":
		kapat()
		return
	_mod = "zafer"
	_yenile(true)

func polis_ac() -> void:
	if _mod == "polis":
		kapat()
		return
	_mod = "polis"
	_yenile(true)

func meslek_ac() -> void:
	if _mod == "meslek":
		kapat()
		return
	_mod = "meslek"
	_yenile(true)

func garaj_ac() -> void:
	if _mod == "garaj":
		kapat()
		return
	_mod = "garaj"
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

func yakin_bina(i: int) -> bool:
	var ab: AABB = oyun.harita.yerler[i]["aabb"]
	var p: Vector3 = sokak.oyuncu.global_position
	return ab.grow(YAKIN).has_point(Vector3(p.x, ab.position.y + ab.size.y * 0.5, p.z))

func yakin_grup(g: Dictionary) -> bool:
	return (g["pos"] as Vector3).distance_to(sokak.oyuncu.global_position) < YAKIN

func bolgede_mi(id: String) -> bool:
	return oyun.harita.bolge_at(sokak.oyuncu.global_position) == id

func kapat() -> void:
	if _mod == "bina" and sokak.oyuncu.iceride >= 0:
		sokak.oyuncu.cik()   # paneli kapatmak = binadan çıkmak
	_mod = ""
	_sag.visible = false

func _sonuc_goster(r: Dictionary, tamam_yazi: String = "Tamam.") -> void:
	_sonuc = r["msg"] if r["msg"] != "" else tamam_yazi
	_sonuc_tur = "good" if r["ok"] else "bad"
	_yenile(true)

# ---------- döngü ----------
func _process(_d: float) -> void:
	var d: Dictionary = oyun.tarih()
	_tarih.text = oyun.tarih_yazi().to_upper()
	_konum.text = "⚑ %s  ·  %s" % [sokak._etiket.text, oyun.mevsim()]
	sokak._etiket.visible = false
	_saat.text = oyun.saat_yazi()
	_temiz.text = "● %s" % oyun.para(oyun.temiz)
	_kirli.text = "▮ %s" % oyun.para(oyun.kirli)
	_un.text = "♛ Ün: %d" % int(oyun.kis_k.taninma())
	_ekip.text = "Ekip %d/%d" % [oyun.adamlar.size(), oyun.EKIP_MAX]
	_arama.text = "Arama %d" % int(oyun.arama)
	_arama.add_theme_color_override("font_color", Color("a02a10") if oyun.arama >= 30.0 else (Color("a86a10") if oyun.arama >= 10.0 else Color("5a4630")))
	_arama.tooltip_text = "Polis seni arıyor: 30 ve üstünde devriyeler kovalar."
	_arama.mouse_filter = Control.MOUSE_FILTER_PASS
	_durum.text = "DURAKLATILDI" if Engine.time_scale == 0.0 else ""
	if not oyun.vardiya.is_empty():
		_durum.text = "ÇALIŞIYOR · %d sa kaldı" % maxi(1, int(ceil((oyun.vardiya["bitis"] - oyun.t) / 60.0)))
	if oyun.defter.size() != _log_n:
		_log_n = oyun.defter.size()
		for c in _log.get_children():
			c.queue_free()
		var son: Array = oyun.defter.slice(maxi(0, _log_n - (8 if _log_acik else 1)))
		for e in son:
			var l := _lbl(_log, "%s  %s" % [oyun.saat_yazi(e["t"]), e["metin"]], 13, RENK[e["tur"]])
			l.mouse_filter = Control.MOUSE_FILTER_IGNORE
			l.custom_minimum_size = Vector2(404, 0)
		if not _log_acik and _log_n > 1:
			var ip := _lbl(_log, "▴ %d haber daha · tıkla" % (_log_n - 1), 11, RENK["soluk"])
			ip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amac_guncelle()
	_kart_bekle()
	_son_kontrol()
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
			return str([oyun.ziyaret.get(i, []).size(), sokak.gorus.bina_gorunur(i), oyun.t / 60, oyun.isy.get(i), oyun.kontrol(i), oyun.bolge[y["bolge"]]["inf"], oyun.bos_adamlar().map(func(a): return a["id"]), gs, oyun.temiz, oyun.kirli, _sonuc, yakin_bina(i), oyun.vardiya, sokak.oyuncu.iceride, oyun.kis, oyun.pazar.get(i)])
		"bolge":
			return str([oyun.bolge[_hedef], oyun.erisim(_hedef), oyun.temiz, oyun.kirli, oyun.adamlar.size(), oyun.tarih()["gun"], _sonuc, bolgede_mi(_hedef)])
		"adamlar":
			return str([oyun.adamlar, oyun.gorevler.map(func(g): return [g["adam"], (g["bitis"] - oyun.t) / 60]), oyun.kirli, _sonuc])
		"grup":
			var g: Dictionary = _hedef
			return str([g["kisi"], g["durum"], g["ev"], sokak.gruplar.liste.has(g), yakin_grup(g), sokak.takip_id])
		"ben":
			return str([oyun.kis, oyun.kis_k.taninma(), oyun.yol["puan"]])
		"defter":
			return str(oyun.defter.size())
		"polis":
			return str([oyun.pol, oyun.arama, oyun.temiz, oyun.kirli, _sonuc])
		"meslek":
			return str([oyun.mes, oyun.borc, oyun.akl, oyun.temiz, _sonuc, _oyuncu_bolge(), oyun.arama])
		"garaj":
			return str([oyun.arac, oyun.temiz, oyun.kirli, _sonuc, oyun.t / 60])
		"zafer":
			return str([oyun.zafer.durum(), oyun.zf, oyun.temiz, _sonuc])
		"aile":
			return str([oyun.muhbir, oyun.temiz, oyun.kirli, _sonuc, oyun.uyeler, sokak.gruplar.liste.filter(func(g): return g.has("lider")).map(func(g): return [g["lider"], oyun.harita.bolge_at(g["pos"])])])
	return ""

func _yenile(zorla: bool) -> void:
	var imza := _imza()
	if not zorla and imza == _son_imza:
		return
	_son_imza = imza
	for c in _ic.get_children():
		c.queue_free()
	_sag.visible = true
	_kagit_mod = true
	_sag.offset_left = -(540 if _mod in ["ben", "aile", "adamlar"] else (500 if _mod == "bina" and sokak.oyuncu.iceride >= 0 else 360))
	match _mod:
		"bina": _bina_paneli()
		"bolge": _bolge_paneli()
		"adamlar": _adam_paneli()
		"defter": _defter_paneli()
		"zafer": _zafer_paneli()
		"garaj": _garaj_paneli()
		"meslek": _meslek_paneli()
		"polis": _polis_paneli()
		"aile": _aile_paneli()
		"grup": _grup_paneli()
		"ben": _ben_paneli()
	_kapat_dugmesi()
	_kagit_mod = false

# İçerideyken: haritada görünmezsin, kimse sana bulaşamaz. Ev ise dinlenip zaman geçirebilirsin.
func _ic_bolumu(i: int) -> void:
	_ayrac(_ic)
	_lbl(_ic, "İçeridesin — haritada görünmüyorsun.", 16, RENK["good"])
	if i == oyun._ev:
		_lbl(_ic, "Evin güvenli: kimse bulaşamaz. Dinlenirken zaman akar, ama borç ve kira beklemez.", 14, RENK["soluk"])
		_btn(_ic, "1 saat bekle", func(): oyun.bekle(60); _yenile(true))
		_btn(_ic, "Sabaha kadar uyu (07:00)", func(): oyun.uyu(); _yenile(true))
	_btn(_ic, "Dışarı çık", kapat)

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
	if sokak.oyuncu.iceride == i:
		_ic_bolumu(i)
		_kisisel_bolumu(i)
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
	var yakin := yakin_bina(i)
	if not yakin:
		_lbl(_ic, "Uzaktasın: işlem yapmak için binaya yaklaş.", 15, RENK["warn"])
	for gk in ["haraclan", "topla", "koru"]:
		_btn(_ic, "%s  (%d dk iş)" % [oyun.GOREVLER[gk]["ad"], oyun.GOREVLER[gk]["is"]], func(): _sonuc_goster(oyun.gorev_ver(i, gk, secili), "Adam yola çıktı."), not yakin)
	_btn(_ic, "Satın al  (%s temiz)" % oyun.para(oyun.fiyat(i)), func(): _sonuc_goster(oyun.satin_al(i), "Satın aldın."), r["sahip"] or not yakin)
	if not r["sahip"]:
		_ayrac(_ic)
		if oyun.vardiya.is_empty():
			_btn(_ic, "Burada çalış  (8 saat · %s)" % oyun.para(oyun.ucret(i)), func(): _sonuc_goster(oyun.calis(i), "Mesaiye başladın."), not yakin)
		elif oyun.vardiya["bina"] == i:
			_lbl(_ic, "Burada çalışıyorsun (~%d saat kaldı)." % maxi(1, int(ceil((oyun.vardiya["bitis"] - oyun.t) / 60.0))), 15, RENK["info"])
			_btn(_ic, "Mesaiyi bırak (ücret yok)", func(): oyun.mesai_birak(); _yenile(true))
		else:
			_lbl(_ic, "Başka yerde çalışıyorsun.", 15, RENK["soluk"])
	_hareket_bolumu(i)
	if r["sahip"] and r.has("itibar"):
		_isletme_bolumu(i, r)
	_btn(_ic, "Buraya git", func(): sokak.oyuncu.git(y["pos"]))
	_sonuc_satiri()

func _hareket_bolumu(i: int) -> void:
	var g: Node3D = sokak.gorus
	_ayrac(_ic)
	_lbl(_ic, "Görüş ve hareket", 18, RENK["altin"])
	var log: Array = oyun.ziyaret.get(i, [])
	if g.bina_gorunur(i):
		var n: Dictionary = g.nufus(i)
		_lbl(_ic, "Şu an içeride ≈ %d kişi" % n["toplam"], 16, RENK["good"])
		_lbl(_ic, "Çalışan %d · müşteri/ziyaretçi %d · yabancı/silahlı grup %d" % [n["calisan"], n["musteri"], n["yabanci"]], 14, RENK["soluk"])
	elif g.bina_kesfedildi(i):
		var s: Dictionary = oyun.gozlem.get(i, {})
		_lbl(_ic, "Görüş dışı — canlı bilgi yok.", 16, RENK["warn"])
		if not s.is_empty():
			_lbl(_ic, "Son gözlem: %s, ≈ %d kişi" % [oyun.saat_yazi(s["t"]), s["n"]], 14, RENK["soluk"])
	else:
		_lbl(_ic, "Burası henüz keşfedilmedi. Adam gönder ya da yaklaş.", 15, RENK["soluk"])
		return
	if log.is_empty():
		_lbl(_ic, "Gelen giden kaydı yok.", 14, RENK["soluk"])
	for k in range(log.size() - 1, maxi(-1, log.size() - 9), -1):
		var e: Dictionary = log[k]
		var renk: Color = RENK["warn"] if e["tur"] != "sivil" else RENK["soluk"]
		_lbl(_ic, "%s  %s (%d kişi) %s" % [oyun.saat_yazi(e["t"]), e["ad"], e["kisi"], e["ne"]], 13, renk)

func _isletme_bolumu(i: int, r: Dictionary) -> void:
	var isl = oyun.isl
	_ayrac(_ic)
	_lbl(_ic, "İşletme · gelir %s" % isl.gelir_yazi(i), 18, RENK["altin"])
	_bar(_ic, "İtibar", r["itibar"], Color("a89870"))
	if isl.olay_var(r):
		_lbl(_ic, "Durum: %s (%d gün kaldı)" % [r["olay"]["ad"], r["olay"]["bitis"] - oyun.t / oyun.DAY], 15, RENK["warn"])
	var satir := HBoxContainer.new()
	_ic.add_child(satir)
	for f in 3:
		var b := Button.new()
		b.text = ("► " if r["fiyat"] == f else "") + "Fiyat: " + isl.FIYAT_AD[f]
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(func(): isl.fiyat_ayarla(i, f))
		satir.add_child(b)
	_lbl(_ic, "Personel (%s) %d/%d" % [isl.rol_ad(i), r["personel"].size(), isl.PERSONEL_MAX], 16)
	for p in r["personel"]:
		var sp: int = p["supheli"]
		var renk: Color = RENK["good"] if sp < 25 else (RENK["warn"] if sp < 70 else RENK["bad"])
		var etiket := "%s · beceri %d · şüphe %d" % [p["ad"], p["beceri"], sp]
		if p["fak_bilinen"]:
			etiket += " · %s'in adamı!" % oyun.FAK[p["ajan"]]["ad"]
		_lbl(_ic, etiket, 14, renk)
		var h := HBoxContainer.new()
		_ic.add_child(h)
		for e in [["Soruştur ($60 kirli)", isl.sorustur], ["Kov", isl.kov], ["İnfaz et", isl.infaz]]:
			var f2: Callable = e[1]
			var b2 := Button.new()
			b2.text = e[0]
			b2.focus_mode = Control.FOCUS_NONE
			b2.pressed.connect(func(): _sonuc_goster(f2.call(i, p["pid"]), ""))
			h.add_child(b2)
	if r["personel"].size() < isl.PERSONEL_MAX:
		var h2 := HBoxContainer.new()
		_ic.add_child(h2)
		for e in [["Çırak tut ($80)", false], ["Usta tut ($250)", true]]:
			var usta: bool = e[1]
			var b3 := Button.new()
			b3.text = e[0]
			b3.focus_mode = Control.FOCUS_NONE
			b3.pressed.connect(func(): _sonuc_goster(isl.tut(i, usta), ""))
			h2.add_child(b3)

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
	_bar(_ic, "Huzur", b["huzur"], Color("7f95ab"))
	_bar(_ic, "Sevgi", b["sev"], Color("7fa386"))
	_bar(_ic, "Korku", b["kor"], Color("b07878"))
	_bar(_ic, "Tanınırlık", b["tan"], Color("9a8fa8"))
	_ayrac(_ic)
	if not oyun.erisim(id):
		_lbl(_ic, "Buraya girmek için önce komşu bir bölgeye hakim ol.", 15, RENK["warn"])
	else:
		_lbl(_ic, "Bölge işleri", 16, RENK["altin"])
		var ici := bolgede_mi(id)
		if not ici:
			_lbl(_ic, "Bölge işleri için bu bölgede olmalısın.", 15, RENK["warn"])
			_btn(_ic, "Bölgeye git", func(): sokak.oyuncu.git(oyun.harita.merkez(id)))
		for tur in ["himaye", "hediye", "gozdagi"]:
			_btn(_ic, "%s  (%s)" % [oyun.IS_AD[tur], oyun.IS_BEDEL[tur]], func(): _sonuc_goster(oyun.bolge_is(id, tur)), not ici)
	if hk == "oyuncu":
		_ayrac(_ic)
		_lbl(_ic, "Yönetim", 16, RENK["altin"])
		_btn(_ic, "Yatırım yap  ($400 temiz)", func(): _sonuc_goster(oyun.bolge_yatirim(id)), not bolgede_mi(id))
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
	_baslik(_ic, "Adamlar", "%d / %d adam · ayda $%d kişi başı" % [oyun.adamlar.size(), oyun.EKIP_MAX, oyun.EKIP_MAAS])
	var ipucu := _lbl(_ic, "Adamlarını barlarda, bilardo salonlarında, boks salonlarında ve derneklerde bulabilirsin. Geceleri daha çok kişi çıkar.", 14, RENK["warn"])
	ipucu.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if oyun.adamlar.is_empty():
		_lbl(_ic, "Ekibin boş. Adam olmadan haraç bağlayamazsın.", 15, RENK["warn"])
	for a in oyun.adamlar:
		var kv := _kutu(_ic)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 10)
		kv.add_child(h)
		_portre(h, a["ad"])
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		_lbl(v, "%s  ·  beceri %d" % [a["ad"], oyun.beceri(a)], 18)
		_bar(v, "Yumruk", a["yumruk"], Color("b08f6c"))
		_bar(v, "Bıçak", a["bicak"], Color("a67070"))
		_bar(v, "Zekâ", a["zeka"], Color("7f95ab"))
		_bar(v, "Sadakat", a.get("sadakat", 60), Tema.VURGU)
		var durum := "Boşta"
		if a["gorev"] == "tutuklu":
			durum = "Karakolda"
		elif a["gorev"] != "":
			durum = "Görevde: " + oyun.GOREVLER[a["gorev"]]["ad"]
		_lbl(v, "Görev: " + durum, 15, RENK["warn"] if a["gorev"] != "" else RENK["good"])
		var id: int = a["id"]
		_btn(v, "Çıkar", func(): _sonuc_goster(oyun.adam_cikar(id)), a["gorev"] != "")
	_sonuc_satiri()

# ---------- aileler (hiyerarşi) ----------
func _aile_paneli() -> void:
	_baslik(_ic, "Aileler")
	var kartlar := HBoxContainer.new()
	kartlar.add_theme_constant_override("separation", 6)
	_ic.add_child(kartlar)
	var simge := {"marchetti": "♛", "obrien": "☘", "tammany": "✦"}
	for f in oyun.NPC:
		var fd: Dictionary = oyun.FAK[f]
		var v := _kutu(kartlar)
		var sm := _lbl(v, simge[f], 28, fd["renk"])
		sm.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		var ad := _lbl(v, fd["ad"], 15, Tema.YAZI)
		ad.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl(v, "Güç: %d" % int(oyun.kudret(f)), 15, Tema.VURGU)
		var g: float = clampf(oyun.gerginlik.gerginlik("oyuncu", f), 0.0, 100.0)
		_lbl(v, "Gerginlik:", 14, Tema.YAZI)
		var gp := ProgressBar.new()
		gp.max_value = 100
		gp.value = g
		gp.show_percentage = false
		gp.custom_minimum_size = Vector2(0, 12)
		var gf := StyleBoxFlat.new()
		gf.bg_color = Tema.IYI if g < 35.0 else (Tema.UYARI if g < 65.0 else Tema.KOTU)
		gp.add_theme_stylebox_override("fill", gf)
		v.add_child(gp)
		var sv: bool = oyun.gerginlik.savasta("oyuncu", f)
		_lbl(v, "Savaş: " + ("Evet" if sv else "Hayır"), 14, Tema.KOTU if sv else Tema.SOLUK)
		var bs := 0
		for id in oyun.bolge:
			if oyun.hakim_of(id) == f:
				bs += 1
		_lbl(v, "Bölge: %d" % bs, 14, Tema.SOLUK)
	for f in oyun.NPC:
		var fd: Dictionary = oyun.FAK[f]
		_ayrac(_ic)
		_lbl(_ic, "%s  ·  öfke %d" % [fd["ad"], int(oyun.ofke[f])], 18, fd["renk"])
		var ms: int = oyun.muhbir[f]
		var mh := HBoxContainer.new()
		_ic.add_child(mh)
		var ml := Label.new()
		ml.text = "Muhbir ağı: %d/3  " % ms
		mh.add_child(ml)
		for dlt in [-1, 1]:
			var mb := Button.new()
			mb.text = "Azalt" if dlt < 0 else "Güçlendir ($%d kirli)" % oyun.isl.MUHBIR_KURULUM
			mb.focus_mode = Control.FOCUS_NONE
			mb.disabled = (dlt < 0 and ms <= 0) or (dlt > 0 and ms >= 3)
			mb.pressed.connect(func(): _sonuc_goster(oyun.isl.muhbir_ayarla(f, ms + dlt), ""))
			mh.add_child(mb)
		for u in oyun.aile_uyeleri(f):
			var yer := "karargâhta"
			if ms <= 0:
				yer = "yeri bilinmiyor (muhbir gerekir)"
			for g in sokak.gruplar.liste:
				if ms > 0 and g.get("lider", -1) == u["uid"]:
					var b: String = oyun.harita.bolge_at(g["pos"])
					yer = "%s (%d kişi)" % [oyun.harita.bolgeler[b]["ad"] if b != "" else "yollarda", g["kisi"]]
			var renk: Color = RENK["altin"] if u["rutbe"] == "don" else Color.WHITE
			_lbl(_ic, "%s %s — %s · ilişki %+d" % ["♛" if u["rutbe"] == "don" else "•", oyun.uye_ad(u), yer, u["iliski"]], 14, renk)
		var oluler: Array = oyun.uyeler.filter(func(u): return u["fak"] == f and u["durum"] == "olu")
		if not oluler.is_empty():
			_lbl(_ic, "Ölenler: %s" % ", ".join(oluler.map(func(u): return oyun.uye_ad(u))), 13, RENK["soluk"])

# ---------- defter ----------
func _defter_paneli() -> void:
	_lbl(_ic, "Defter", 24, RENK["altin"])
	var n: int = oyun.defter.size()
	for k in range(n - 1, maxi(-1, n - 41), -1):
		var e: Dictionary = oyun.defter[k]
		_lbl(_ic, "%s %s" % [oyun.saat_yazi(e["t"]), e["metin"]], 14, RENK[e["tur"]])

# ---------- polis / bodrum ----------
func _polis_paneli() -> void:
	var P: RefCounted = oyun.polis
	var p: Dictionary = oyun.pol
	_lbl(_ic, "Polis ve bodrum", 24, RENK["altin"])
	_bar(_ic, "Dosya", oyun.arama, Color("a86a6a"), "%d · %s" % [int(oyun.arama), P.asama_ad()])
	_lbl(_ic, "Dosya 100'e çıkarsa dava açılır. 75'te arama emri: baskın gelir. Kanıt girmeyen her gün dosya biraz erir.", 13, RENK["soluk"])
	var dl := ""
	for x in P.dikkat_satirlari():
		dl += "%s %+d · " % [x[0], int(x[1])]
	_lbl(_ic, "Polis dikkati %d  (%s)" % [int(P.dikkat()), dl.trim_suffix(" · ")], 13, RENK["info"])
	if p["baskin"] != 0:
		_lbl(_ic, "Baskın yaklaşıyor: ~%d sa sonra." % maxi(1, int(ceil((p["baskin"] - oyun.t) / 60.0))), 15, RENK["bad"])
	_ayrac(_ic)
	_lbl(_ic, "Dedektif Dolan", 17, RENK["altin"])
	var rh := HBoxContainer.new()
	_ic.add_child(rh)
	for m in [100, 300, 600]:
		var e: Dictionary = P.rusvet_tahmin(float(m))
		_btn(rh, "$%d · %%%d" % [m, int(round(e["p"] * 100.0))], func(): _sonuc_goster(P.rusvet(float(m))))
	_lbl(_ic, "Rüşvet: tutar · kabul ihtimali. Kabul edilirse dosya erir. Aylığa bağlarsan dikkat −15 olur ve baskını önceden haber verir.", 13, RENK["soluk"])
	_btn(_ic, "Aylığı kes" if p["aylik"] else "Aylığa bağla ($%d/ay)" % P.AYLIK_DOLAN, func(): _sonuc_goster(P.aylik_ver(not p["aylik"])))
	_ayrac(_ic)
	_lbl(_ic, "Bodrum imalathanesi", 17, RENK["altin"])
	if not p["kurulu"]:
		_lbl(_ic, "Kaçak içki: yüksek kâr, ama iz bırakır. Üretimi ekibinden bir adam yürütür.", 13, RENK["soluk"])
		_btn(_ic, "İmalathane kur (%s kirli)" % oyun.para(P.KUR_FIYAT), func(): _sonuc_goster(P.kur()))
	else:
		_lbl(_ic, "Stok %d şişe · hacim %d/gün · gizlilik %.2f · iz %d · günlük yakalanma %%%d" % [int(p["stok"]), p["hacim"], P.gizlilik(), int(p["iz"]), int(round(p["p"] * 100.0))], 14)
		_lbl(_ic, "Toplam satış: %s kirli" % oyun.para(p["satis"]), 13, RENK["soluk"])
		var hh := HBoxContainer.new()
		_ic.add_child(hh)
		for v in [0, 20, 40, 60]:
			_btn(hh, "%d" % v, func(): _sonuc_goster(P.hacim_ayarla(v)), p["hacim"] == v)
		var ah := HBoxContainer.new()
		_ic.add_child(ah)
		if not p["gizli"]:
			_btn(ah, "Gizli oda %s" % oyun.para(P.GIZLI_ODA), func(): _sonuc_goster(P.gizli_oda()))
		_btn(ah, "Malı sakla (3 gün)", func(): _sonuc_goster(P.sakla()), oyun.t < p["saklanma"])
		if oyun.t < p["saklanma"]:
			_lbl(_ic, "Mal saklı: üretim/satış durdu.", 14, RENK["warn"])
	_sonuc_satiri()

# ---------- meslek / borç ----------
func _oyuncu_bolge() -> String:
	return oyun.harita.bolge_at(sokak.oyuncu.global_position)

func _meslek_paneli() -> void:
	var K: RefCounted = oyun.meslek
	var M: Dictionary = oyun.mes
	var bid := _oyuncu_bolge()
	_lbl(_ic, "Meslek ve borç", 24, RENK["altin"])
	if oyun.borc_k.var_mi():
		var b: Dictionary = oyun.borc
		_lbl(_ic, "Tefeci borcu: %s · aylık taksit %s · kaçırılan %d/3" % [oyun.para(b["ana"]), oyun.para(b["taksit"]), b["kacirilan"]], 15, RENK["bad"] if b["kacirilan"] > 0 else RENK["warn"])
		var bh := HBoxContainer.new()
		_ic.add_child(bh)
		for m in [100, 500, 1000]:
			_btn(bh, "Öde $%d" % m, func(): _sonuc_goster(oyun.borc_k.ode(float(m))), oyun.temiz < minf(m, b["ana"]))
		_ayrac(_ic)
	if M["is"].is_empty():
		_lbl(_ic, "İşsizsin. Bulunduğun bölge: %s. Düz iş temiz gelir, tecrübe ve meşru bir yüz verir." % (oyun.harita.bolgeler[bid]["ad"] if bid != "" else "—"), 14, RENK["soluk"])
	else:
		var j: String = M["is"]["j"]
		_lbl(_ic, "Çalıştığın iş: %s (%s) · günlük ~%s" % [K.MESLEKLER[j]["ad"], oyun.harita.bolgeler[M["is"]["b"]]["ad"], oyun.para(K.maas_gun(j, M["is"]["b"]))], 16, RENK["good"])
		_btn(_ic, "İşten ayrıl", func(): _sonuc_goster(K.is_birak()))
	_ayrac(_ic)
	var A: RefCounted = oyun.aklama_k
	var pl: Dictionary = A.plan()
	_lbl(_ic, "Aklama ve maliye", 17, RENK["altin"])
	_lbl(_ic, "Kirli para ay sonunda yasal cironun bir kısmı kadar temize çevrilir (kesinti %%%d). Fazlası Mali Şüphe'yi artırır; şüphe 50'yi geçerse müfettiş gelir." % int(round(pl["ucret"] * 100.0)), 13, RENK["soluk"])
	_lbl(_ic, "Bu ay yasal ciro %s · kapasite ~%s · Mali Şüphe %d/50" % [oyun.para(oyun.akl["yasal"]), oyun.para(pl["kap"]), int(oyun.akl["suphe"])], 14, RENK["warn"] if oyun.akl["suphe"] > 25.0 else RENK["info"])
	var ah := HBoxContainer.new()
	_ic.add_child(ah)
	for y in [0, 50, 100, 150]:
		_btn(ah, "%%%d" % y, func(): A.yuzde_ayarla(y), oyun.akl["yuzde"] == y)
	_lbl(ah, "Aklanan: kapasitenin %%%d'i" % oyun.akl["yuzde"], 14)
	if oyun.akl["camasir"]:
		_lbl(_ic, "✔ Çamaşırhane senin (kapasiteyi artırır).", 14, RENK["good"])
	else:
		_btn(_ic, "Çamaşırhane al (%s)" % oyun.para(A.CAMASIR_FIYAT), func(): _sonuc_goster(A.camasir_al()), oyun.temiz < A.CAMASIR_FIYAT)
	for j in K.MESLEKLER:
		var m: Dictionary = K.MESLEKLER[j]
		_ayrac(_ic)
		var xp: float = M["beceri"][j]
		_lbl(_ic, "%s · %s (%%%d)" % [m["ad"], K.BECERI_AD[K.seviye(xp)], int(xp)], 17)
		_lbl(_ic, "%s Avantaj: %s." % [m["ac"], m["perk"]], 13, RENK["soluk"])
		var h := HBoxContainer.new()
		_ic.add_child(h)
		if bid != "" and M["is"].is_empty():
			var k: Dictionary = K.kabul(j, bid)
			_btn(h, "İşe gir (kabul %d/%d)" % [k["puan"], k["esik"]], func(): _sonuc_goster(K.is_gir(j, bid)))
		if M["isletme"].has(j):
			_lbl(h, "✔ %s senin · ay geliri %s" % [m["isletme"], oyun.para(K.isletme_gelir(j))], 14, RENK["good"])
		else:
			_btn(h, "%s al (%s)" % [m["isletme"], oyun.para(m["fiyat"])], func(): _sonuc_goster(K.isletme_al(j)), xp < 20.0 or oyun.temiz < m["fiyat"])
	_sonuc_satiri()

# ---------- garaj ----------
func _garaj_paneli() -> void:
	var K: RefCounted = oyun.arac_k
	var Ar: Dictionary = K.ARACLAR
	var a: Dictionary = oyun.arac
	_lbl(_ic, "Garaj", 24, RENK["altin"])
	if a["tip"] == "":
		_lbl(_ic, "Araban yok. Araba yürümekten çok hızlıdır ama yakıt ve bakım ister; ekibin, paran ve bölgelerin büyüdükçe masrafı azalır.", 14, RENK["soluk"])
		for tip in Ar:
			var T: Dictionary = Ar[tip]
			_ayrac(_ic)
			_lbl(_ic, "%s · %s" % [T["ad"], oyun.para(T["fiyat"])], 17)
			_lbl(_ic, "%s Hız ×%.1f · depo %d L" % [T["ac"], T["hiz"], int(T["tank"])], 14, RENK["soluk"])
			_btn(_ic, "Satın al (temiz)", func(): _sonuc_goster(K.al(tip)), oyun.temiz < T["fiyat"])
	else:
		var T: Dictionary = Ar[a["tip"]]
		_lbl(_ic, T["ad"], 18)
		_bar(_ic, "Yakıt", a["yakit"] / T["tank"] * 100.0, Color("a89870"), "%d L" % int(a["yakit"]))
		_lbl(_ic, "Benzin: %s / litre · aylık bakım %s · yol %d m" % [oyun.para(K.yakit_fiyat()), oyun.para(K.bakim_gider()), int(a["yol"] * K.PX_M)], 14, RENK["soluk"])
		_lbl(_ic, "Hız ×%.1f · pusuya yakalanma ×%.2f" % [T["hiz"], T["pusu"]], 14, RENK["soluk"])
		if oyun.t < a["ariza"]:
			_lbl(_ic, "Serviste/arızalı: %d sa sonra hazır." % int(ceil((a["ariza"] - oyun.t) / 60.0)), 15, RENK["bad"])
		elif a["kullan"]:
			_lbl(_ic, "Arabayla gidiyorsun.", 15, RENK["good"])
		var h := HBoxContainer.new()
		_ic.add_child(h)
		_btn(h, "Benzin al", func(): _sonuc_goster(K.benzin_al()))
		_btn(h, "Yürüyerek git" if a["kullan"] else "Arabaya bin", func(): _sonuc_goster(K.sur(not a["kullan"])))
		_btn(h, "Sat (%s)" % oyun.para(round(T["fiyat"] * 0.6)), func(): _sonuc_goster(K.sat()))
	_sonuc_satiri()

# ---------- hedefler / zafer yolları ----------
func _zafer_paneli() -> void:
	_lbl(_ic, "Hedefler", 24, RENK["altin"])
	_lbl(_ic, "Üç zafer yolundan biri oyunu kazandırır. Koşullar ay sonunda kontrol edilir.", 14, RENK["soluk"])
	var D: Dictionary = oyun.zafer.durum()
	var yollar := [["durust", "Dürüst iş (2 ay üst üste)", oyun.zf["durust_ay"]], ["baskan", "Belediye başkanlığı (yıllık seçim, 12. ay)", -1], ["hakim", "Hâkimiyet (2 ay üst üste)", oyun.zf["hakim_ay"]]]
	for y in yollar:
		_ayrac(_ic)
		var ad: String = y[1]
		if y[2] >= 0:
			ad += " · %d/2 ay" % y[2]
		_lbl(_ic, ad, 17, RENK["altin"])
		for x in D[y[0]]:
			var h := HBoxContainer.new()
			_ic.add_child(h)
			_lbl(h, "%s %s" % ["✔" if x["ok"] else "✘", x["k"]], 15, RENK["good"] if x["ok"] else RENK["soluk"])
			var v := _lbl(h, x["v"], 15)
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ayrac(_ic)
	_lbl(_ic, "Seçim kampanyası", 17, RENK["altin"])
	_lbl(_ic, "Afiş, aşevi, miting: oy oranını yükseltir. Kazanamazsan para gider.", 14, RENK["soluk"])
	var kh := HBoxContainer.new()
	_ic.add_child(kh)
	for m in [500, 1000, 2500]:
		_btn(kh, "+$%d" % m, func(): _sonuc_goster(oyun.zafer.kampanya_fon(m)))
	_sonuc_satiri()

# Oyun sonu (zafer/yenilgi) örtüsü
var _son_ortu: Control

func _son_kontrol() -> void:
	if oyun.son.is_empty() or _son_ortu != null:
		return
	var Menu := preload("res://scripts/ui/menu.gd")
	_son_ortu = Control.new()
	_son_ortu.set_anchors_preset(Control.PRESET_FULL_RECT)
	_son_ortu.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.75)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_son_ortu.add_child(dim)
	var pc := PanelContainer.new()
	pc.theme = Tema.tema()
	pc.add_theme_stylebox_override("panel", Menu.panel_stil())
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.custom_minimum_size = Vector2(460, 0)
	pc.grow_horizontal = Control.GROW_DIRECTION_BOTH
	pc.grow_vertical = Control.GROW_DIRECTION_BOTH
	_son_ortu.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pc.add_child(v)
	var zafer: bool = oyun.son["tur"] == "zafer"
	var b := _lbl(v, "ZAFER" if zafer else "OYUN BİTTİ", 28, RENK["good"] if zafer else RENK["bad"])
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl(v, oyun.son["metin"], 16)
	if zafer:
		_btn(v, "Oynamaya devam et", _son_kapat)
	_btn(v, "Ana menü", _ana_menu)
	add_child(_son_ortu)
	Engine.time_scale = 0.0
	modal = true

func _son_kapat() -> void:
	_son_ortu.queue_free()
	_son_ortu = null
	oyun.son = {"tur": "devam", "metin": ""}   # bir daha gösterme; zafer sistemi durur
	modal = false
	Engine.time_scale = sokak._hiz

func _ana_menu() -> void:
	Engine.time_scale = 1.0
	get_tree().change_scene_to_file("res://scenes/menu.tscn")

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
	if yakin_grup(g):
		_btn(_ic, "Konuş / karşılaş", func(): karsilasma_ac(g))
	else:
		_lbl(_ic, "Uzaktasın: konuşmak için yanına git.", 15, RENK["warn"])
		_btn(_ic, "Yanına git", func(): sokak.oyuncu.git(g["pos"]))
	if sokak.takip_id == g["id"]:
		_btn(_ic, "Kovalamayı bırak", func(): sokak.takip_birak())
	else:
		_btn(_ic, "Kovala", func(): sokak.takip_ver(g))

# ---------- karşılaşma diyaloğu (ekran ortasında, oyun duraklar) ----------
func _diyalog_kur() -> void:
	_dlg = PanelContainer.new()
	_dlg.add_theme_stylebox_override("panel", _stil(Color(0.07, 0.08, 0.09, 0.97)))
	_dlg.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_dlg.custom_minimum_size = Vector2(440, 0)
	_dlg.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_dlg.grow_vertical = Control.GROW_DIRECTION_BOTH
	_dlg.visible = false
	_dlg.theme = Tema.tema()
	add_child(_dlg)
	_dlg_ic = VBoxContainer.new()
	_dlg_ic.add_theme_constant_override("separation", 8)
	_dlg.add_child(_dlg_ic)
	_kars = load("res://scripts/core/karsilasma.gd").new(oyun, sokak.gruplar)

func karsilasma_ac(g: Dictionary) -> void:
	if modal:
		return
	modal = true
	_dlg_g = g
	_dlg_sonuc = {}
	sokak.modal_duraklat(true)
	_diyalog_ciz()

func _diyalog_ciz() -> void:
	for c in _dlg_ic.get_children():
		c.queue_free()
	var g := _dlg_g
	_dlg.add_theme_stylebox_override("panel", _stil(Color(0.07, 0.05, 0.035, 0.97)))
	_dlg.custom_minimum_size = Vector2(440, 0)
	var renk: Color = sokak.gruplar._renk(g)
	_lbl(_dlg_ic, _kars.baslik(g), 24, renk.lerp(Color.WHITE, 0.4))
	_lbl(_dlg_ic, _kars.giris(g), 16)
	if _dlg_sonuc.is_empty() or not _dlg_sonuc["bitir"]:
		if not _dlg_sonuc.is_empty():
			_lbl(_dlg_ic, _dlg_sonuc["metin"], 16, RENK[_dlg_sonuc["tur"]])
		_ayrac(_dlg_ic)
		for sec in _kars.secenekler(g):
			var id: String = sec["id"]
			var b := _btn(_dlg_ic, sec["ad"], func(): _secenek(id))
			b.tooltip_text = sec["ipucu"]
	else:
		_ayrac(_dlg_ic)
		_lbl(_dlg_ic, _dlg_sonuc["metin"], 17, RENK[_dlg_sonuc["tur"]])
		_btn(_dlg_ic, "Tamam", _diyalog_kapat)
	_dlg.visible = true

func _secenek(id: String) -> void:
	_dlg_sonuc = _kars.uygula(_dlg_g, id)
	if _dlg_sonuc.get("savas", false):
		var on: Dictionary = _dlg_sonuc
		_dlg.visible = false
		sokak.savas_baslat(_dlg_g, on["ceza"], func(s: Dictionary):
			var r: Dictionary = _kars.savas_bitir(_dlg_g, s)
			r["metin"] = "%s %s" % [on["metin"], r["metin"]]
			_dlg_sonuc = r
			_diyalog_ciz())
		return
	_diyalog_ciz()

func _diyalog_kapat() -> void:
	modal = false
	_dlg.visible = false
	sokak.modal_duraklat(false)

# ---------- karar kartları ----------
var _kart_id := ""
var _kart_sonuc := {}

func _kart_bekle() -> void:
	if modal or oyun.yol["bekleyen"] == "":
		return
	var arg := OS.get_cmdline_user_args()
	if arg.size() > 0 and not arg.has("--kart-goster"):
		return
	kart_ac(oyun.yol["bekleyen"])

func kart_ac(id: String) -> void:
	if modal:
		return
	modal = true
	_kart_id = id
	_kart_sonuc = {}
	oyun.kart_k.hazirla(id)
	sokak.modal_duraklat(true)
	_kart_ciz()

func _kart_ciz() -> void:
	for c in _dlg_ic.get_children():
		c.queue_free()
	var K: RefCounted = oyun.kart_k
	var kw: Color = Tema.KAGIT_YAZI
	_dlg.add_theme_stylebox_override("panel", Tema.kagit_stil())
	_dlg.custom_minimum_size = Vector2(520, 0)
	var bsl := _lbl(_dlg_ic, K.baslik(_kart_id), 26, kw)
	bsl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl(_dlg_ic, K.metin(_kart_id), 17, kw)
	if _kart_sonuc.is_empty():
		var n := 0
		for sec in K.secenekler(_kart_id):
			var i := n
			var b := _btn(_dlg_ic, sec["ad"], func(): _kart_sec(i), not sec["can"])
			var ip: String = _etiket_temizle(sec["ipucu"])
			b.tooltip_text = ip
			var h := _lbl(_dlg_ic, ip, 13, Color("5a4630"))
			h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			n += 1
	else:
		var m := _lbl(_dlg_ic, _kart_sonuc["metin"], 17, kw)
		m.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_btn(_dlg_ic, "Tamam", _diyalog_kapat)
	_dlg.visible = true

# Karakter rol yapsın: yol puanları gösterilmez, yalnız somut sonuçlar kalır.
func _etiket_temizle(t: String) -> String:
	var rx := RegEx.new()
	rx.compile("\\s*(Yasal|Gölge|Korku|Kulis) [+−]\\d+[.,]?")
	return rx.sub(t, "", true).strip_edges().trim_suffix(",")

func _kart_sec(i: int) -> void:
	_kart_sonuc = oyun.kart_k.uygula(_kart_id, i)
	_kart_ciz()

# ---------- kişisel: eylemler, adam bulma, karakter paneli ----------
func ben_ac() -> void:
	if _mod == "ben":
		kapat()
		return
	_mod = "ben"
	_sonuc = ""
	_yenile(true)

func _ihtiyac_bar(ad: String, deger: float) -> void:
	var renk := RENK["good"]
	if deger >= 75.0:
		renk = RENK["bad"]
	elif deger >= 50.0:
		renk = RENK["warn"]
	_bar(_ic, ad, deger, renk)

func _ben_paneli() -> void:
	var K: RefCounted = oyun.kis_k
	var k: Dictionary = oyun.kis
	_baslik(_ic, "Ben")
	var ust := HBoxContainer.new()
	ust.add_theme_constant_override("separation", 12)
	_ic.add_child(ust)
	var ad: String = oyun.profil.get("ad", "Sen")
	_portre(ust, ad, Vector2(110, 130))
	var kim := VBoxContainer.new()
	kim.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ust.add_child(kim)
	_lbl(kim, ad, 26, Tema.VURGU)
	_lbl(kim, "Ünün: %d · Form: %%%d" % [int(K.taninma()), int(K.form() * 100.0)], 16, Tema.YAZI)
	if K.hasta_mi():
		_lbl(kim, "%s: güçsüzsün. Evde yat ya da ilaç al." % k["hasta_ad"], 15, RENK["bad"])
	var st: Dictionary = oyun.ozet["stat"]
	_bar(kim, "Güç", st["guc"] * 10.0, Color("b08f6c"), str(st["guc"]))
	_bar(kim, "Nişan", st["nisan"] * 10.0, Color("a67070"), str(st["nisan"]))
	_bar(kim, "Zekâ", st["zeka"] * 10.0, Color("7f95ab"), str(st["zeka"]))
	_bar(kim, "Karizma", st["karizma"] * 10.0, Tema.VURGU, str(st["karizma"]))
	var iki := HBoxContainer.new()
	iki.add_theme_constant_override("separation", 8)
	_ic.add_child(iki)
	var sol := _kutu(iki, "Durum")
	_ihtiyac_bar_to(sol, "Açlık", k["aclik"])
	_ihtiyac_bar_to(sol, "Yorgunluk", k["yorgun"])
	_ihtiyac_bar_to(sol, "Stres", k["stres"])
	_ihtiyac_bar_to(sol, "Sıkıntı", k["sikinti"])
	var sag := _kutu(iki, "Huylar")
	var l: Array = K.oz_liste()
	if l.is_empty():
		_lbl(sag, "Henüz belirgin bir huyun yok.", 14, RENK["soluk"])
	for e in l:
		var o: Dictionary = K.OZ[e[0]]
		_bar(sag, o["ad"], e[1], RENK["altin"])
		var a := _lbl(sag, o["ac"], 13, RENK["soluk"])
		a.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var dur := _kutu(_ic, "Duruşun")
	var y: RefCounted = oyun.yol_k
	for yl in y.YOLLAR:
		_bar(dur, y.AD[yl], y.puan(yl), RENK["info"])
	var ozet := _lbl(_ic, y.ozet_satiri(), 15, Tema.VURGU)
	ozet.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_sonuc_satiri()

func _ihtiyac_bar_to(hedef: Node, ad: String, deger: float) -> void:
	var renk := RENK["good"]
	if deger >= 75.0:
		renk = RENK["bad"]
	elif deger >= 50.0:
		renk = RENK["warn"]
	_bar(hedef, ad, deger, renk)

func _efekt_yazi(d: Dictionary) -> String:
	var ad := {"aclik": "Açlık", "yorgun": "Yorgunluk", "stres": "Stres", "sikinti": "Sıkıntı", "hasta": "Hastalık"}
	var p: Array = []
	for a in d:
		if ad.has(a) and absf(d[a]) >= 10.0:
			p.append("%s %s%%%d" % [ad[a], "−" if d[a] < 0 else "+", int(absf(d[a]))])
	return ", ".join(p)

func _kisisel_bolumu(i: int) -> void:
	var K: RefCounted = oyun.kis_k
	var l: Array = K.eylemler(i)
	if not l.is_empty():
		var kv := _kutu(_ic, "Eylemler")
		var g := GridContainer.new()
		g.columns = 4
		g.add_theme_constant_override("h_separation", 10)
		g.add_theme_constant_override("v_separation", 2)
		kv.add_child(g)
		for id in l:
			var e: Dictionary = K.EYLEM[id]
			var b := Button.new()
			b.text = e["ad"]
			b.flat = true
			b.alignment = HORIZONTAL_ALIGNMENT_LEFT
			b.focus_mode = Control.FOCUS_NONE
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_font_size_override("font_size", Tema.boyut(15))
			b.add_theme_color_override("font_color", Tema.KAGIT_YAZI)
			b.add_theme_color_override("font_hover_color", Color("8a5a10"))
			b.pressed.connect(func(): _sonuc_goster(K.yap(id)))
			g.add_child(b)
			var u := _lbl(g, "$%d" % int(e["ucret"]), 14, Tema.VURGU)
			u.size_flags_horizontal = Control.SIZE_FILL
			var dk := _lbl(g, "%d dk" % int(e["dk"]), 14, Tema.SOLUK)
			dk.size_flags_horizontal = Control.SIZE_FILL
			var ef := _lbl(g, _efekt_yazi(e["d"]), 13, Tema.IYI)
			ef.size_flags_horizontal = Control.SIZE_FILL
			for lb in [u, dk, ef]:
				lb.autowrap_mode = TextServer.AUTOWRAP_OFF
	if oyun.pazar_k.site_mi(i):
		var kv := _kutu(_ic, "Adam Arayanlar")
		var adaylar: Array = oyun.pazar_k.liste(i)
		if adaylar.is_empty():
			_lbl(kv, "Şimdi kimse yok. Gece ya da başka bir gün gel.", 14, RENK["soluk"])
		var n := 0
		for c in adaylar:
			var idx := n
			var h := HBoxContainer.new()
			h.add_theme_constant_override("separation", 8)
			kv.add_child(h)
			_portre(h, c["ad"], Vector2(48, 56))
			var v := VBoxContainer.new()
			v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			h.add_child(v)
			_lbl(v, c["ad"], 16)
			_lbl(v, "Yumruk: %d · Sadakat: %d" % [c["yumruk"], c["sadakat"]], 13, Tema.SOLUK)
			_lbl(v, c["not"], 12, Tema.SOLUK)
			var b := _btn(h, "Tut
$%d" % int(c["fiyat"]), func(): _sonuc_goster(oyun.pazar_k.tut(i, idx)), oyun.adamlar.size() >= oyun.EKIP_MAX)
			b.tooltip_text = "Kirli para ile tutulur. Beceri %d" % int((c["yumruk"] * 0.5 + c["bicak"] * 0.3 + c["zeka"] * 0.2))
			n += 1
	_sonuc_satiri()
