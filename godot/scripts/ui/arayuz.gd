extends CanvasLayer
# 2D arayüz şablonu: üst çubuk (tarih, para, ekip, hız), sağ panel (bina / mahalle / adamlar / defter),
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
var _arka: Control   # panelin tamamını kaplayan artwork
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
# Sağ üstteki oyuncu madalyonu (tıklayınca "Ben" paneli).
class Madalyon extends Control:
	var _tex: Texture2D = load("res://assets/ui/profil.png")
	func _init() -> void:
		custom_minimum_size = Vector2(96, 96)
		mouse_filter = Control.MOUSE_FILTER_STOP
		tooltip_text = "Sen — tıkla: Ben paneli"
	func _draw() -> void:
		var c := size / 2.0
		var r := minf(size.x, size.y) / 2.0 - 3.0
		draw_circle(c, r + 2.0, Color(0.02, 0.012, 0.008))
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for k in 48:
			var a := TAU * k / 48.0
			var d := Vector2(cos(a), sin(a))
			pts.append(c + d * (r - 4.0))
			uvs.append(Vector2(0.5, 0.5) + d * 0.5)
		draw_colored_polygon(pts, Color(1, 1, 1), uvs, _tex)
		draw_arc(c, r - 3.0, 0.0, TAU, 56, Color(0.02, 0.012, 0.008), 3.0, true)
		draw_arc(c, r, 0.0, TAU, 56, Color(0.62, 0.53, 0.36), 2.5, true)
		draw_arc(c, r - 6.0, 0.0, TAU, 56, Color(0.62, 0.53, 0.36, 0.55), 1.0, true)

const PANEL_GENISLIK := 420   # tüm sağ paneller aynı genişlikte
const YAKIN := 16.0          # bir binayla/grupla işlem için gereken en büyük uzaklık (m)

func kur(o: Node, s: Node) -> void:
	oyun = o
	sokak = s
	_ust_cubuk()
	_amac_paneli()
	_sag_panel()
	_kapat_x()
	_diyalog_kur()
	var saat := CepSaati.new()
	saat.kur(oyun)
	saat.position = Vector2(6, 4)
	add_child(saat)
	var sp := Pie.new()
	sp.kur(true, [["⚒", "İş", meslek_ac], ["⚙", "Garaj", garaj_ac], ["★", "Hedefler", zafer_ac], ["⚔", "Silahlar", silah_ac], ["✦", "Beceri", yetenek_ac]])
	sp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	sp.offset_left = 0
	sp.offset_top = -Pie.BOY
	sp.offset_right = Pie.BOY
	sp.offset_bottom = 0
	add_child(sp)
	var rp := Pie.new()
	rp.kur(false, [["♜", "Aileler", aile_ac], ["♞", "Adamlar", adamlar_ac], ["⚑", "Mahalleler", _bolge_dugmesi], ["⚖", "Polis", polis_ac], ["✎", "Defter", defter_ac]])
	rp.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	rp.offset_left = -Pie.BOY
	rp.offset_top = -Pie.BOY
	rp.offset_right = 0
	rp.offset_bottom = 0
	add_child(rp)
	_madalyon()
	_log_panel = PanelContainer.new()
	var lsb := Tema.koyu_panel(2)
	lsb.set_content_margin(SIDE_LEFT, 14)
	lsb.set_content_margin(SIDE_RIGHT, 14)
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
func _stil(arka: Color = Tema.ARKA) -> StyleBox:
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
	b.focus_mode = Control.FOCUS_NONE   # Boşluk tuşu düğmeye basmasın
	b.disabled = pasif
	b.pressed.connect(fn)
	if not _kagit_mod:
		b.text = metin
		ebeveyn.add_child(b)
		return b
	# Dönem itme düğmesi: koyu bakalit gövde, pirinç çerçeve. "Ad  (ayrıntı)" -> ad solda, ayrıntı sağda pirinç etiket.
	var ad := metin
	var ek := ""
	var k := metin.find("  (")
	if k > 0 and metin.ends_with(")"):
		ad = metin.substr(0, k)
		ek = metin.substr(k + 3, metin.length() - k - 4)
	# etiketle aynı satırdaysa dar kalır (örn. "Deftere yaz", "Başvur")
	var satir_ici: bool = ebeveyn is HBoxContainer and ebeveyn.get_child_count() > 0 and ebeveyn.get_child(0) is Label
	var simge: bool = ebeveyn is VBoxContainer and ad.length() >= 4
	var sol := 44 if simge else 10
	var sag := 10
	if ek != "":
		sag = 10
	b.text = ad
	b.custom_minimum_size = Vector2(0, 40 if simge else 34)
	b.add_theme_stylebox_override("normal", _gaz_dugme_stil(Color(0.11, 0.08, 0.055), Color(0.62, 0.48, 0.26), sol))
	b.add_theme_stylebox_override("hover", _gaz_dugme_stil(Color(0.22, 0.15, 0.08), Tema.VURGU, sol))
	b.add_theme_stylebox_override("pressed", _gaz_dugme_stil(Color(0.34, 0.23, 0.10), Color("f0d890"), sol))
	b.add_theme_stylebox_override("disabled", _gaz_dugme_stil(Color(0.2, 0.18, 0.15, 0.85), Color(0.36, 0.32, 0.25), sol))
	b.add_theme_color_override("font_color", Tema.YAZI)
	b.add_theme_color_override("font_hover_color", Color("f6e6b4"))
	b.add_theme_color_override("font_disabled_color", Color(0.78, 0.72, 0.6, 0.8))
	b.add_theme_font_size_override("font_size", Tema.boyut(16))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT if simge else HORIZONTAL_ALIGNMENT_CENTER
	if simge:
		var g := TextureRect.new()
		g.texture = load("res://assets/ui/icons/%s.png" % _glif_sec(ad))
		g.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		g.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		g.anchor_top = 0.0
		g.anchor_bottom = 1.0
		g.offset_left = 8
		g.offset_right = 38
		g.offset_top = 4
		g.offset_bottom = -4
		g.modulate = Color(1, 1, 1, 0.92 if not pasif else 0.4)
		b.add_child(g)
	if ek != "":
		var e := Label.new()
		e.text = ek
		e.mouse_filter = Control.MOUSE_FILTER_IGNORE
		e.add_theme_font_size_override("font_size", Tema.boyut(13))
		e.add_theme_color_override("font_color", Color("d9b862") if not pasif else Color(0.8, 0.7, 0.45, 0.8))
		e.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
		e.offset_right = -12
		e.offset_left = -150
		e.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		e.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		b.add_child(e)
		b.clip_text = true
		b.add_theme_stylebox_override("normal", _gaz_dugme_stil(Color(0.11, 0.08, 0.055), Color(0.62, 0.48, 0.26), sol, 150))
		b.add_theme_stylebox_override("hover", _gaz_dugme_stil(Color(0.22, 0.15, 0.08), Tema.VURGU, sol, 150))
		b.add_theme_stylebox_override("pressed", _gaz_dugme_stil(Color(0.34, 0.23, 0.10), Color("f0d890"), sol, 150))
		b.add_theme_stylebox_override("disabled", _gaz_dugme_stil(Color(0.2, 0.18, 0.15, 0.85), Color(0.36, 0.32, 0.25), sol, 150))
	if satir_ici:
		b.size_flags_horizontal = Control.SIZE_SHRINK_END
		b.autowrap_mode = TextServer.AUTOWRAP_OFF
	ebeveyn.add_child(b)
	return b

# Defter satırı: "Anahtar ......... değer" (muhasebe defteri havası).
func _satir(ebeveyn: Node, anahtar: String, deger: String, renk: Color = Color.WHITE) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	ebeveyn.add_child(h)
	var a := _lbl(h, anahtar, 15, RENK["soluk"])
	a.size_flags_horizontal = Control.SIZE_FILL
	a.autowrap_mode = TextServer.AUTOWRAP_OFF
	var nokta := Label.new()
	nokta.text = "· · · · · · · · · · · · · · · · · · · · · · · · · · · · · ·"
	nokta.clip_text = true
	nokta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nokta.add_theme_font_size_override("font_size", Tema.boyut(10))
	nokta.add_theme_color_override("font_color", Color(0.3, 0.22, 0.12, 0.45))
	nokta.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	nokta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(nokta)
	var d := _lbl(h, deger, 16, renk if renk != Color.WHITE else Color.WHITE)
	d.size_flags_horizontal = Control.SIZE_FILL
	d.autowrap_mode = TextServer.AUTOWRAP_OFF
	d.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	d.add_theme_font_override("font", Tema.kalin_fontu())

# Durum şeridi: renkli damga gibi tek satır (sahiplik / uyarı).
func _damga(ebeveyn: Node, metin: String, renk: Color) -> void:
	renk = _murekkep(renk)
	var pc := PanelContainer.new()
	var sb := Tema.stil(Color(renk.r, renk.g, renk.b, 0.12), renk, 6, 2)
	pc.add_theme_stylebox_override("panel", sb)
	pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ebeveyn.add_child(pc)
	var l := _lbl(pc, metin.to_upper() if false else metin, 16, renk)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_override("font", Tema.kalin_fontu())

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
	if _kagit_mod:
		_gazete_baslik(ebeveyn, metin, alt)
		return
	var l := _lbl(ebeveyn, metin, 30, RENK["altin"])
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if _kagit_mod:
		l.add_theme_color_override("font_color", Tema.KAGIT_YAZI)
	else:
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		l.add_theme_constant_override("outline_size", 3)
	if alt != "":
		var al := _lbl(ebeveyn, alt, 15, RENK["soluk"])
		al.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ayrac(ebeveyn)

# Panel içi bölüm başlığı: altın, orta boy; üstünde kısa boşluk.
func _bolum(ebeveyn: Node, metin: String) -> Label:
	var bosluk := Control.new()
	bosluk.custom_minimum_size = Vector2(0, 4)
	ebeveyn.add_child(bosluk)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	ebeveyn.add_child(h)
	var lc := Color(0.25, 0.17, 0.08, 0.7) if _kagit_mod else Color(0.79, 0.59, 0.17, 0.6)
	var sol := ColorRect.new()
	sol.color = lc
	sol.custom_minimum_size = Vector2(0, 1.5)
	sol.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sol.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(sol)
	var l := _lbl(h, ("→ " + metin) if _kagit_mod else metin, 18, RENK["altin"])
	l.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	if _kagit_mod:
		l.add_theme_font_override("font", Tema.kalin_fontu())
	var sag := sol.duplicate()
	h.add_child(sag)
	return l

# Yuvarlak altın çerçeveli simge (üst çubuk, hedef kutusu).
func _ikon(ebeveyn: Node, glif: String, renk: Color, boy: int = 26) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.yuvarlak_stil(Color(0.05, 0.035, 0.025), Color("8f7c52"), boy / 2))
	pc.custom_minimum_size = Vector2(boy, boy)
	pc.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebeveyn.add_child(pc)
	var l := Label.new()
	l.text = glif
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", int(boy * 0.55))
	l.add_theme_color_override("font_color", renk)
	pc.add_child(l)
	return pc

func _koyu_kutu(ebeveyn: Node, marj: int = 6) -> PanelContainer:
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Tema.koyu_panel(marj))
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ebeveyn.add_child(pc)
	return pc

# Koyu çerçeveli iç kutu (görseldeki "Eylemler" / "Adam Arayanlar" gibi).
func _kutu(ebeveyn: Node, baslik: String = "") -> VBoxContainer:
	var pc := PanelContainer.new()
	if _kagit_mod:
		var ks := Tema.stil(Color(0.55, 0.42, 0.24, 0.16), Tema.KAGIT_KENAR, 8, 2)
		pc.add_theme_stylebox_override("panel", ks)
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
	_amac_kutu.add_theme_stylebox_override("panel", Tema.koyu_panel(2))
	_amac_kutu.theme = Tema.tema()
	_amac_kutu.position = Vector2(8, 140)
	_amac_kutu.custom_minimum_size = Vector2(300, 0)
	_amac_kutu.mouse_filter = Control.MOUSE_FILTER_STOP
	_amac_kutu.tooltip_text = "Tıkla: ayrıntıyı aç/kapa"
	_amac_kutu.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			_amac_acik = not _amac_acik
			_amac_kutu.accept_event())
	add_child(_amac_kutu)
	var hh := HBoxContainer.new()
	hh.add_theme_constant_override("separation", 10)
	hh.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_amac_kutu.add_child(hh)
	_ikon(hh, "!", Tema.VURGU, 30)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hh.add_child(v)
	_amac_baslik = _lbl(v, "", 15, Color("e0b050"))
	_ayrac(v)
	_amac_yazi = _lbl(v, "", 14, Color("e8dcc0"))
	_baski_yazi = _lbl(v, "", 12, Color("b8a888"))
	for q in [_amac_baslik, _amac_yazi, _baski_yazi]:
		q.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ihtiyac_yazi = Label.new()   # eski satır: artık üstteki çubuklarda

var _amac_acik := false
var _ihc: Dictionary = {}
var _ihc_hasta: Label

# Üst çubukta: açlık / yorgunluk / stres / sıkıntı çubukları (ün değeri kaynak kutusunda).
func _ihtiyac_cubugu(h: Control) -> void:
	for e in [["aclik", "Açlık", Tema.IYI], ["yorgun", "Yorgun", Tema.UYARI], ["stres", "Stres", Tema.KOTU], ["sikinti", "Sıkıntı", Tema.BILGI]]:
		var c := VBoxContainer.new()
		c.add_theme_constant_override("separation", 1)
		c.tooltip_text = e[1]
		h.add_child(c)
		var l := Label.new()
		l.text = e[1]
		l.add_theme_font_size_override("font_size", 11)
		l.add_theme_color_override("font_color", Tema.SOLUK)
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		c.add_child(l)
		var p := ProgressBar.new()
		p.min_value = 0
		p.max_value = 100
		p.show_percentage = false
		p.custom_minimum_size = Vector2(48, 7)
		var f := StyleBoxFlat.new()
		f.bg_color = e[2]
		f.set_corner_radius_all(2)
		p.add_theme_stylebox_override("fill", f)
		var bg := StyleBoxFlat.new()
		bg.bg_color = Color(0, 0, 0, 0.6)
		bg.set_corner_radius_all(2)
		p.add_theme_stylebox_override("background", bg)
		c.add_child(p)
		_ihc[e[0]] = [p, f]
	_ihc_hasta = Label.new()
	_ihc_hasta.text = "✚ HASTA"
	_ihc_hasta.add_theme_font_size_override("font_size", 12)
	_ihc_hasta.add_theme_color_override("font_color", Tema.KOTU)
	_ihc_hasta.visible = false
	h.add_child(_ihc_hasta)

func _ihtiyac_guncelle() -> void:
	var k: Dictionary = oyun.kis
	var v := {"aclik": float(k["aclik"]), "yorgun": float(k["yorgun"]), "stres": float(k["stres"]), "sikinti": float(k["sikinti"]), "un": float(oyun.kis_k.taninma())}
	for a in v:
		if not _ihc.has(a):
			continue
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
	var acilis_adim := false
	if not oyun.acilis["daire"]:
		yazi = "Havaalanından çıktın. Dedenden kalan daire seni bekliyor: H tuşu seni oraya götürür, kapısına tıkla."
		acilis_adim = true
	elif sahip == 0 and haracli == 0 and oyun.adamlar.is_empty():
		yazi = "Cebin ince. Bir dükkâna ya da atölyeye git ve 'Burada çalış' de; ya da bir tezgâh satın alıp kendi işini kur ($300'dan başlar: Produce Stand, Shoe Repair)."
		acilis_adim = true
	elif sahip > 0 and haracli == 0 and oyun.adamlar.is_empty():
		yazi = "İlk işin hazır. Büyüt: ikinci dükkân, personel, itibar. Büyüdükçe mafya ve polis kapını çalar; ya da adam tutup başka bir yol seç."
		acilis_adim = true
	if acilis_adim:
		pass
	elif oyun.adamlar.is_empty():
		yazi = "Önce bir adam tut: T tuşu (Adamlar). Tek başına esnafı sıkıştıramazsın."
	elif haracli + sahip == 0:
		yazi = "Bir esnafa git, paneli aç ve adamınla haraç bağla. Gelir oradan başlar."
	elif bolgeler == 0:
		yazi = "Nüfuzunu büyüt: haraç bağladıkça mahalle senin olur. Haraçlı iş: %d" % (haracli + sahip)
	else:
		yazi = "%d mahalle senin. Rakip ailelere karşı büyü: Hedefler panelinde kazanım yollarına bak." % bolgeler
	if oyun.arama >= 60.0:
		baslik = "TEHLİKE"
		yazi = "Polis dosyan kabarık (%d). Ortalıkta görünme, rüşvet ver ya da evine gir." % int(oyun.arama)
	var ac: Dictionary = oyun.kis_k.acil()
	if not ac.is_empty() and oyun.arama < 60.0:
		baslik = "İHTİYAÇ"
		yazi = ac["mesaj"]
	if baslik == "HEDEF":
		baslik = "HEDEF · " + oyun.yol_adi().to_upper()
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

# Kaynak kutusundaki bir kalem: yuvarlak simge + değer. Değer etiketini döndürür.
func _hap(h: Node, glif: String, renk: Color, ipucu: String, resim: String = "") -> Label:
	var c := HBoxContainer.new()
	c.add_theme_constant_override("separation", 5)
	c.tooltip_text = ipucu
	c.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	h.add_child(c)
	if resim != "" and ResourceLoader.exists("res://assets/ui/icons/%s.png" % resim):
		var tr := TextureRect.new()
		tr.texture = load("res://assets/ui/icons/%s.png" % resim)
		tr.custom_minimum_size = Vector2(30, 30)
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		tr.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(tr)
	else:
		_ikon(c, glif, renk, 24)
	var l := Label.new()
	l.add_theme_font_size_override("font_size", Tema.boyut(20))
	l.add_theme_color_override("font_color", Tema.YAZI)
	l.autowrap_mode = TextServer.AUTOWRAP_OFF
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	c.add_child(l)
	return l

var _hiz_dugmeleri: Array = []

func _ust_cubuk() -> void:
	# koyu deri şeritler: tarih/konum | kaynaklar | ihtiyaçlar | hız düğmeleri
	_saat = Label.new()   # saat cep saatinde; metin yine de tutulur
	var kok := HBoxContainer.new()
	kok.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	kok.offset_left = 130
	kok.offset_right = -92
	kok.offset_top = 8
	kok.add_theme_constant_override("separation", 6)
	kok.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.theme = Tema.tema()
	add_child(kok)
	# tarih + konum
	var p1 := _koyu_kutu(kok, 2)
	var v1 := VBoxContainer.new()
	v1.add_theme_constant_override("separation", 0)
	v1.custom_minimum_size = Vector2(230, 0)
	p1.add_child(v1)
	_tarih = Label.new()
	_tarih.add_theme_font_size_override("font_size", Tema.boyut(21))
	_tarih.add_theme_color_override("font_color", Tema.YAZI)
	_tarih.autowrap_mode = TextServer.AUTOWRAP_OFF
	v1.add_child(_tarih)
	var v1b := HBoxContainer.new()
	v1b.add_theme_constant_override("separation", 8)
	v1.add_child(v1b)
	_konum = Label.new()
	_konum.add_theme_font_size_override("font_size", Tema.boyut(14))
	_konum.add_theme_color_override("font_color", Tema.SOLUK)
	_konum.autowrap_mode = TextServer.AUTOWRAP_OFF
	v1b.add_child(_konum)
	_durum = Label.new()
	_durum.add_theme_font_size_override("font_size", Tema.boyut(14))
	_durum.add_theme_color_override("font_color", Tema.KOTU)
	_durum.autowrap_mode = TextServer.AUTOWRAP_OFF
	v1b.add_child(_durum)
	# kaynaklar
	var p2 := _koyu_kutu(kok, 4)
	var r := HBoxContainer.new()
	r.add_theme_constant_override("separation", 14)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p2.add_child(r)
	_temiz = _hap(r, "$", Tema.VURGU, "Temiz para", "temiz")
	_kirli = _hap(r, "▮", Tema.KOTU, "Kirli para", "kirli")
	_ekip = _hap(r, "♟", Tema.YAZI, "Ekip: adam sayısı / üst sınır", "ekip")
	_arama = _hap(r, "⚠", Tema.UYARI, "Polis seni arıyor: 30 ve üstünde devriyeler kovalar.", "arama")
	_un = _hap(r, "★", Tema.VURGU, "Ünün", "un")
	# ihtiyaçlar
	var p3 := _koyu_kutu(kok, 4)
	var nb := HBoxContainer.new()
	nb.add_theme_constant_override("separation", 10)
	nb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p3.add_child(nb)
	_ihtiyac_cubugu(nb)
	var bosluk := Control.new()
	bosluk.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bosluk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kok.add_child(bosluk)
	# hız düğmeleri
	var p4 := _koyu_kutu(kok, 4)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 5)
	sh.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	p4.add_child(sh)
	for hv in [["II", 0.0], ["▶", 1.0], ["▶▶", 2.0], ["▶▶▶", 4.0]]:
		var hb := Button.new()
		hb.text = hv[0]
		hb.focus_mode = Control.FOCUS_NONE
		hb.custom_minimum_size = Vector2(34, 34)
		hb.add_theme_font_size_override("font_size", 12)
		for dn in ["normal", "hover", "pressed", "focus"]:
			hb.add_theme_stylebox_override(dn, Tema.yuvarlak_stil(Color(0.2, 0.05, 0.05) if dn != "hover" else Color(0.34, 0.09, 0.07), Color("8f7c52"), 17))
		hb.add_theme_color_override("font_color", Tema.YAZI)
		hb.pressed.connect(sokak.hiz_ayarla.bind(hv[1]))
		sh.add_child(hb)
		_hiz_dugmeleri.append([hb, hv[1]])

func _madalyon() -> void:
	var m := Madalyon.new()
	m.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	m.offset_left = -8      # çeyrek dairenin merkezine (sol alt köşe) doğru
	m.offset_right = 76
	m.offset_top = -76
	m.offset_bottom = 8
	m.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
			ben_ac()
			m.accept_event())
	add_child(m)

func _kapat_x() -> void:
	var x := Button.new()
	x.text = "✕"
	x.focus_mode = Control.FOCUS_NONE
	x.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	x.offset_left = -50
	x.offset_right = -18
	x.offset_top = 100
	x.offset_bottom = 132
	x.add_theme_font_size_override("font_size", 14)
	for dn in ["normal", "hover", "pressed", "focus"]:
		x.add_theme_stylebox_override(dn, Tema.yuvarlak_stil(Color(0.08, 0.055, 0.04) if dn != "hover" else Color(0.3, 0.08, 0.06), Color("8f7c52"), 16))
	x.add_theme_color_override("font_color", Tema.YAZI)
	x.pressed.connect(kapat)
	x.visible = false
	add_child(x)
	_sag.visibility_changed.connect(func(): x.visible = _sag.visible)

func _sag_panel() -> void:
	_sag = PanelContainer.new()
	_sag.add_theme_stylebox_override("panel", Tema.kagit_panel())
	_sag.set_anchors_and_offsets_preset(Control.PRESET_RIGHT_WIDE)
	_sag.offset_left = -(PANEL_GENISLIK + 8)
	_sag.offset_right = -8
	_sag.offset_top = 92
	_sag.offset_bottom = -200
	_sag.visible = false
	_sag.theme = Tema.tema_kagit()
	add_child(_sag)
	_arka = load("res://scripts/ui/kagit_gorsel.gd").new()
	_sag.add_child(_arka)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_sag.add_child(sc)
	_ic = VBoxContainer.new()
	_ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ic.add_theme_constant_override("separation", 6)
	sc.add_child(_ic)

# ---------- açma / kapama ----------
func bina_ac(i: int) -> void:
	if i == oyun._ev:
		oyun.acilis["daire"] = true
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
	if g.has("sakin"):
		return   # isimli sakinlerin paneli yok; sadece rutinleriyle yaşarlar
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

func silah_ac() -> void:
	if _mod == "silah":
		kapat()
		return
	_mod = "silah"
	_yenile(true)

func yetenek_ac() -> void:
	if _mod == "yetenek":
		kapat()
		return
	_mod = "yetenek"
	_yenile(true)

var _ailem_slot := -1

func ailem_ac() -> void:
	if _mod == "ailem":
		kapat()
		return
	_mod = "ailem"
	_ailem_slot = -1
	_yenile(true)

func kazanim_ac() -> void:
	if _mod == "kazanim":
		kapat()
		return
	_mod = "kazanim"
	_yenile(true)

func nufuz_ac() -> void:
	if _mod == "nufuz":
		kapat()
		return
	_mod = "nufuz"
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
	if oyun.uyku_hedef >= 0:
		return
	if _mod == "bina" and sokak.oyuncu.iceride >= 0:
		sokak.oyuncu.cik()   # paneli kapatmak = binadan çıkmak
	_mod = ""
	_sag.visible = false
	sokak.harita_modu_ayarla(false)

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
	_temiz.text = oyun.para(oyun.temiz)
	_kirli.text = oyun.para(oyun.kirli)
	_un.text = "%d" % int(oyun.kis_k.taninma())
	_ekip.text = "%d/%d" % [oyun.adamlar.size(), oyun.EKIP_MAX]
	_arama.text = "%d" % int(oyun.arama)
	_arama.add_theme_color_override("font_color", Tema.KOTU if oyun.arama >= 30.0 else (Tema.UYARI if oyun.arama >= 10.0 else Tema.YAZI))
	for hd in _hiz_dugmeleri:
		hd[0].add_theme_color_override("font_color", Tema.VURGU if is_equal_approx(Engine.time_scale, hd[1]) else Tema.YAZI)
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
			return str([oyun.kis, oyun.kis_k.taninma(), oyun.yol["puan"], oyun.un, oyun.arama, oyun.temiz, oyun.kirli])
		"defter":
			return str(oyun.defter.size())
		"silah":
			return str([oyun.sil, oyun.sil_k.kusur("miyop"), oyun.kis.get("gozluk", false), oyun.temiz, oyun.kirli, _sonuc, _sil_acik, oyun.arac.get("tip", ""), oyun.t / 1440])
		"yetenek":
			return str([oyun.yet, _sonuc])
		"ailem":
			return str([oyun.aile, _sonuc, _ailem_slot, oyun.t / 1440])
		"kazanim":
			return str(oyun.kaz)
		"nufuz":
			return str([oyun.nuf, oyun.kotu, _sonuc, oyun.temiz, oyun.kirli, oyun.adamlar])
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
	sokak.harita_modu_ayarla(_mod == "bolge")
	var imza := _imza()
	if not zorla and imza == _son_imza:
		return
	_son_imza = imza
	for c in _ic.get_children():
		c.queue_free()
	_sag.visible = true
	_kagit_mod = true
	_sag.offset_left = -(PANEL_GENISLIK + 8)
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
		"silah": _silah_paneli()
		"yetenek": _yetenek_paneli()
		"ailem": _ailem_paneli()
		"nufuz": _nufuz_paneli()
		"kazanim": _kazanim_paneli()
	_kagit_mod = false
	_arka.visible = _arka.ayarla(_gorsel_anahtarlari())

func _buyuk(t: String) -> String:
	if _mod == "bina" or _mod == "bolge":
		return t.to_upper()
	return t.replace("i", "İ").replace("ı", "I").to_upper()

func _gaz_dugme_stil(arka: Color, kenar: Color, sol: int, sag: int = -1) -> StyleBox:
	var sb := Tema.dugme_stil(arka, kenar)
	sb.content_margin_left = sol
	sb.content_margin_right = sol if sag < 0 else sag
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb

# Düğme metnine göre simge dosyası (assets/ui/icons/<ad>.png).
func _glif_sec(metin: String) -> String:
	var dusuk := metin.to_lower()
	for kv in [["dışarı çık", "kapi"], ["mahalle bilgisi", "bilgi_rulo"], ["haracı topla", "haraci_topla"], ["1 saat bekle", "saat"], ["sabaha kadar", "yastik"], ["pencere başında", "saat"]]:
		if dusuk.begins_with(kv[0]):
			return kv[1]
	var kelimeler := dusuk.split(" ")
	var tablo := [["satın", "temiz"], ["öde", "temiz"], ["sat", "temiz"], ["yatırım", "temiz"], ["rüşvet", "kirli"], ["hesaplaş", "kirli"], ["saldır", "guc"], ["silah", "guc"], ["ateş", "guc"], ["infaz", "guc"], ["haraç", "tehdit"], ["kov", "tehdit"], ["soruştur", "tehdit"], ["koru", "ittifak"], ["mahalle", "ittifak"], ["af", "ittifak"], ["tazminat", "ittifak"], ["başvur", "ittifak"]]
	for kv in tablo:
		for w in kelimeler:
			if w.begins_with(kv[0]):
				return kv[1]
	for kv in [["buraya", "ok"], ["git", "ok"], ["bilgi", "bilgi"], ["emir", "emir"], ["adam", "adamlar"], ["çete", "adamlar"], ["aile", "aileler"], ["polis", "polis"], ["haritada", "bolgeler"]]:
		for w in kelimeler:
			if w.begins_with(kv[0]):
				return kv[1]
	return "saygi"

# Gazete şablonu: gazete künyesi + sol büyük dar manşet / sağ çerçeveli fotoğraf.
func _gazete_baslik(ebeveyn: Node, metin: String, alt: String) -> void:
	var ink := Tema.KAGIT_YAZI
	var bas := _buyuk(metin)
	var boy := 40 if bas.length() <= 12 else (32 if bas.length() <= 18 else 26)
	var t := _lbl(ebeveyn, bas, boy, ink)
	t.add_theme_font_override("font", Tema.baslik_fontu())
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	t.add_theme_constant_override("line_spacing", -8)
	t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t.custom_minimum_size = Vector2(0, 0)
	t.clip_text = false
	if alt != "":
		var al := _lbl(ebeveyn, _buyuk(alt), 11, Tema.SOLUK)
		al.add_theme_constant_override("line_spacing", 0)
	_ayrac(ebeveyn)

# Panel arkası görsel için dosya adı adayları (assets/ui/panel/).
func _gorsel_anahtarlari() -> Array:
	var G = load("res://scripts/ui/kagit_gorsel.gd")
	match _mod:
		"bina":
			var i: int = _hedef
			var tur: String = oyun.isy[i]["tur"] if oyun.isy.has(i) else ("ozel" if oyun.harita.yerler[i]["ozel"] else "resmi")
			var ad_k: String = String(oyun.harita.yerler[i]["ad"]).to_lower()
			var ozel: Array = [G.slug(oyun.harita.yerler[i]["ad"])]
			if i == oyun._ev and sokak.oyuncu.iceride == i:
				ozel.push_front("home_ii")   # evin icindeyken ikinci ev gorseli
			var taban: String = G.slug(String(oyun.harita.yerler[i]["ad"]).trim_suffix(" III").trim_suffix(" II"))
			if not ozel.has(taban):
				ozel.append(taban)   # "Bakeshop II" -> bakeshop.png
			for ek in ["_ii", "_iii"]:
				if not ozel.has(taban + ek):
					ozel.append(taban + ek)   # taban dosya yoksa kardeş varyasyon
			for kv in [["church", "kilise"], ["chapel", "kilise"], ["cathedral", "kilise"], ["precinct", "polis"], ["airport", "havaalani"], ["airfield", "havaalani"], ["butcher", "butcher"], ["boxing", "boks_salonu"], ["gym", "boks_salonu"]]:
				if ad_k.contains(kv[0]):
					ozel.append(kv[1])
			if oyun.isy.has(i) and oyun.isy[i].get("bos", false):
				if oyun.isy[i]["tur"] == "konut":
					var sv: int = oyun.bolge[oyun.harita.yerler[i]["bolge"]]["servet"]
					var s_ev: Array = ["satilik_ev_luks", "satilik_ev"] if sv >= 4 else (["satilik_daire", "satilik_ev"] if sv <= 2 else ["satilik_ev", "satilik_daire"])
					s_ev.reverse()
					for e in s_ev:
						ozel.push_front(e)
				else:
					ozel.push_front("bos_dukkan")
			return ozel + [tur, "bina"]
		"bolge":
			return ["bolge_" + str(_hedef), "bolge"]
		"grup":
			return ["grup_" + str(_hedef.get("tur", "")), "grup"]
	return [_mod]

# İçerideyken: haritada görünmezsin, kimse sana bulaşamaz. Ev ise dinlenip zaman geçirebilirsin.
func _ic_bolumu(i: int) -> void:
	_ayrac(_ic)
	if oyun.uyku_hedef >= 0:
		_lbl(_ic, "Zaman akıyor… (dünya hızlı işliyor)", 16, RENK["warn"])
		return
	_lbl(_ic, "İçeridesin — haritada görünmüyorsun.", 16, RENK["good"])
	if i == oyun._ev:
		_lbl(_ic, "Evin güvenli: kimse bulaşamaz. Dinlenirken zaman akar, ama borç ve kira beklemez.", 14, RENK["soluk"])
		_btn(_ic, "1 saat bekle", func(): oyun.bekle_hizli(60); _yenile(true))
		_btn(_ic, "Sabaha kadar uyu (07:00)", func(): oyun.uyu(); _yenile(true))
	elif oyun.pazar_k.konak_mi(i):
		var ucret := 20.0
		_lbl(_ic, "Oda tuttun: odan kapalı, kimse bulaşamaz. Ev bilinen adrestir; aranıyorsan burada yatmak daha güvenli. Gecelik $%d." % int(ucret), 14, RENK["soluk"])
		_btn(_ic, "1 saat bekle", func(): oyun.bekle_hizli(60); _yenile(true))
		_btn(_ic, "Sabaha kadar kal (07:00) — $%d" % int(ucret), func():
			if oyun.harcama(ucret, "kirli"):
				oyun.uyu()
			else:
				_sonuc_goster(oyun.hata("Oda parası yok."))
			_yenile(true))
		if oyun.isler_k.pusu_var(i):
			_lbl(_ic, "Pusu kurdun: hedef bu civarda görünebilir.", 14, RENK["warn"])
			_btn(_ic, "Pencere başında bekle (2 saat)", func(): _sonuc_goster(oyun.isler_k.pusu_bekle(i)))
	_btn(_ic, "Dışarı çık", kapat)

func _sonuc_satiri() -> void:
	if _sonuc != "":
		_lbl(_ic, _sonuc, 15, RENK[_sonuc_tur])

# ---------- bina paneli ----------
func _bina_paneli() -> void:
	var i: int = _hedef
	var y: Dictionary = oyun.harita.yerler[i]
	var bid: String = y["bolge"]
	_baslik(_ic, y["ad"])
	var kunye := HBoxContainer.new()
	_ic.add_child(kunye)
	var kl := _lbl(kunye, "%s · %s" % [oyun.harita.bolgeler[bid]["ad"], oyun.tur_ad(i)], 14, RENK["soluk"])
	kl.autowrap_mode = TextServer.AUTOWRAP_OFF
	var bb := _btn(kunye, "Mahalle bilgisi", bolge_ac.bind(bid))
	bb.size_flags_horizontal = Control.SIZE_SHRINK_END
	bb.custom_minimum_size = Vector2(0, 26)
	bb.add_theme_font_size_override("font_size", Tema.boyut(13))
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
	if r.get("bos", false):
		_bos_ilan_paneli(i, r)
		return
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
	_damga(_ic, kontrol_yazi, kontrol_renk)
	_satir(_ic, "Haftalık gelir", oyun.para(oyun.haftalik(i)))
	if r["haracli"]:
		_satir(_ic, "Biriken haraç", oyun.para(r["birikim"]), RENK["altin"])
	_satir(_ic, "Direnç", str(oyun.TURLER[r["tur"]]["direnc"] * 10))
	_satir(_ic, "Fiyat", oyun.para(oyun.fiyat(i)))
	for g in oyun.gorevler:
		if g["hedef"] == i:
			var a: Dictionary = oyun.adam_bul(g["adam"])
			var kalan: int = maxi(1, int(ceil((g["bitis"] - oyun.t) / 60.0)))
			_lbl(_ic, "%s: %s (~%d saat)" % [a.get("ad", "?"), "tutuklu" if g["gorev"] == "tutuklu" else oyun.GOREVLER[g["gorev"]]["ad"].to_lower(), kalan], 15, RENK["warn"])
	var bos: Array = oyun.bos_adamlar()
	_adam_idler = [0]
	var ob := OptionButton.new()
	ob.focus_mode = Control.FOCUS_NONE
	ob.custom_minimum_size = Vector2(0, 34)
	for dn in ["normal", "hover", "pressed", "disabled"]:
		ob.add_theme_stylebox_override(dn, _gaz_dugme_stil(Color(0.11, 0.08, 0.055) if dn != "hover" else Color(0.22, 0.15, 0.08), Color(0.62, 0.48, 0.26), 10))
	ob.add_theme_color_override("font_color", Tema.YAZI)
	ob.add_theme_color_override("font_hover_color", Color("f6e6b4"))
	ob.add_theme_font_size_override("font_size", Tema.boyut(15))
	ob.add_item("Görevli: otomatik (en uygun adam)")
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
	var bag: Dictionary = r.get("bagimsiz", {})
	if not bag.is_empty():
		_bolum(_ic, "Bağımsız sahip")
		_lbl(_ic, "%s: %s. Haraç vermez; zorlarsan adamların dayak yer." % [bag["ad"], bag["neden"]], 14, RENK["warn"])
		if bag.get("dost", false):
			_lbl(_ic, "Seninle dost.", 14, RENK["good"])
		else:
			_btn(_ic, "Dostluk kur  (%s temiz)" % oyun.para(int(bag["guc"]) * 8), func(): _sonuc_goster(oyun.dostluk_kur(i), "Dost oldunuz."), not yakin)
	_bolum(_ic, "Eylemler")
	for gk in ["haraclan", "topla", "koru"]:
		_btn(_ic, "%s  (%d dk iş)" % [oyun.GOREVLER[gk]["ad"], oyun.GOREVLER[gk]["is"]], func(): _sonuc_goster(oyun.gorev_ver(i, gk, secili), "Adam yola çıktı."), not yakin)
	_btn(_ic, "Satın al  (%s temiz)" % oyun.para(oyun.fiyat(i)), func(): _sonuc_goster(oyun.satin_al(i), "Satın aldın."), r["sahip"] or not yakin)
	var Mi: Dictionary = oyun.mes["is"]
	if not Mi.is_empty() and Mi.get("bina", -1) == i and oyun.vardiya.is_empty():
		_ayrac(_ic)
		_lbl(_ic, "Senin iş yerin: %s · mesai ücreti %s (07–16 arası başla)" % [oyun.meslek.MESLEKLER[Mi["j"]]["ad"], oyun.para(oyun.meslek.mesai_ucret())], 15, RENK["good"])
		_btn(_ic, "Mesaiye başla (8 saat)", func(): _sonuc_goster(oyun.meslek.mesai_baslat(i), "Mesaiye başladın."), not yakin)
	elif not r["sahip"]:
		_ayrac(_ic)
		if oyun.vardiya.is_empty():
			_btn(_ic, "Burada çalış  (8 saat · %s)" % oyun.para(oyun.ucret(i)), func(): _sonuc_goster(oyun.calis(i), "Mesaiye başladın."), not yakin)
		elif oyun.vardiya["bina"] == i:
			_lbl(_ic, "Burada çalışıyorsun (~%d saat kaldı)." % maxi(1, int(ceil((oyun.vardiya["bitis"] - oyun.t) / 60.0))), 15, RENK["info"])
			_btn(_ic, "Mesaiyi bırak (ücret yok)", func(): oyun.mesai_birak(); _yenile(true))
		else:
			_lbl(_ic, "Başka yerde çalışıyorsun.", 15, RENK["soluk"])
	load("res://scripts/ui/kimler.gd").kur(self, oyun, sokak, i)
	_hareket_bolumu(i)
	if r["sahip"] and r.has("itibar"):
		_isletme_bolumu(i, r)
	_btn(_ic, "Buraya git", func(): sokak.oyuncu.git(y["pos"]))
	_sonuc_satiri()

# Boş dükkân ilanı: kiralık/satılık yazısı, ilan metni, ucuz satın alma.
func _bos_ilan_paneli(i: int, r: Dictionary) -> void:
	var y: Dictionary = oyun.harita.yerler[i]
	var ev: bool = r["tur"] == "konut"
	var elde: String = r.get("elde", "")
	var ku: Dictionary = r.get("kurulum", {})
	var baslik := "SATILIK EV" if ev else "KİRALIK / SATILIK"
	if elde == "kira":
		baslik = "KİRADA — SENDE"
	elif elde == "mulk":
		baslik = "MÜLKÜN"
	_damga(_ic, baslik, RENK["warn"] if elde == "" else RENK["good"])
	if elde == "":
		_lbl(_ic, "Boş ev, camda ilan: \"Satılıktır, görüşmek için kapıyı çalın.\"" if ev else "Eski iş yeri kapanmış. Camda soluk bir ilan: \"Dükkân kiralık ya da satılıktır.\"", 15, RENK["soluk"])
		_satir(_ic, "Mahalle zenginliği", "★".repeat(oyun.bolge[y["bolge"]]["servet"]))
		_satir(_ic, "Satın alma", oyun.para(oyun.ilan_fiyat(i)))
		_satir(_ic, "Kira (haftalık)", oyun.para(oyun.ilan_kira(i)))
		_lbl(_ic, "Kirada ilk iki hafta peşin alınır. Kira iki hafta ödenmezse yer elinden gider. Aldıktan sonra istediğin işe çevirebilirsin.", 14, RENK["soluk"])
	else:
		_satir(_ic, "Durum", ("Kiracısın · haftalık " + oyun.para(oyun.ilan_kira(i))) if elde == "kira" else "Tapu senin")
	var yakin := yakin_bina(i)
	if not yakin:
		_lbl(_ic, "Uzaktasın: işlem yapmak için binaya yaklaş.", 15, RENK["warn"])
	if elde == "":
		_bolum(_ic, "Edin")
		_btn(_ic, "Satın al  (%s temiz)" % oyun.para(oyun.ilan_fiyat(i)), func(): _sonuc_goster(oyun.bos_edin(i, "mulk"), "Mülkü aldın."), not yakin)
		_btn(_ic, "Kirala  (%s peşin)" % oyun.para(oyun.ilan_kira(i) * 2), func(): _sonuc_goster(oyun.bos_edin(i, "kira"), "Kiraladın."), not yakin)
	elif not ku.is_empty():
		_bolum(_ic, "Kurulum")
		var kalan: float = float(ku["bitis"] - oyun.t) / float(oyun.DAY)
		_satir(_ic, oyun.TURLER[ku["tur"]]["ad"], "%.1f gün kaldı" % maxf(kalan, 0.0), RENK["warn"])
	else:
		_bolum(_ic, "İşe çevir")
		for tur in ["esnaf", "eglence", "atolye", "depo", "luks", "konut"]:
			var kt: String = tur
			_btn(_ic, "%s  ·  %s · %d gün" % [oyun.TURLER[kt]["ad"], oyun.para(oyun.kurulum_maliyet(i, kt)), oyun.KURULUM[kt][1]], func(): _sonuc_goster(oyun.donustur(i, kt), "Kurulum başladı."), not yakin)
		if elde == "kira":
			_btn(_ic, "Kirayı bırak", func(): _sonuc_goster(oyun.birak(i), "Bıraktın."), not yakin)
	_btn(_ic, "Buraya git", func(): sokak.oyuncu.git(y["pos"]))
	_sonuc_satiri()

func _hareket_bolumu(i: int) -> void:
	var g: Node3D = sokak.gorus
	_ayrac(_ic)
	_bolum(_ic, "Gözlem")
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
	for k in range(log.size() - 1, maxi(-1, log.size() - 6), -1):
		var e: Dictionary = log[k]
		var renk: Color = RENK["warn"] if e["tur"] != "sivil" else RENK["soluk"]
		_lbl(_ic, "%s  %s (%d kişi) %s" % [oyun.saat_yazi(e["t"]), e["ad"], e["kisi"], e["ne"]], 13, renk)

func _isletme_bolumu(i: int, r: Dictionary) -> void:
	var isl = oyun.isl
	_ayrac(_ic)
	_bolum(_ic, "İşletme · gelir %s" % isl.gelir_yazi(i))
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

# ---------- mahalle paneli ----------
func _bolge_paneli() -> void:
	var id: String = _hedef
	var b: Dictionary = oyun.bolge[id]
	var hk: String = oyun.hakim_of(id)
	_baslik(_ic, oyun.harita.bolgeler[id]["ad"])
	for ml in [_lbl(_ic, oyun.ACIKLAMA[id], 15, RENK["soluk"]), _lbl(_ic, oyun.KARAKTER[id]["ac"], 15, RENK["soluk"])]:
		ml.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_ayrac(_ic)
	_lbl(_ic, "Hakim: %s" % oyun.hakim_ad(hk), 18, oyun.FAK[hk]["renk"] if hk != "" else Color.WHITE)
	if hk != "oyuncu":
		_lbl(_ic, "Hakim olmak için +%.1f nüfuz gerekir." % oyun.hakim_icin_kalan(id), 15, RENK["soluk"])
	_bolum(_ic, "Nüfuz")
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
		_lbl(_ic, "Buraya girmek için önce komşu bir mahalleye hakim ol.", 15, RENK["warn"])
	else:
		_bolum(_ic, "Mahalle işleri")
		var ici := bolgede_mi(id)
		if not ici:
			_lbl(_ic, "Mahalle işleri için bu mahallede olmalısın.", 15, RENK["warn"])
			_btn(_ic, "Mahalleye git", func(): sokak.oyuncu.git(oyun.harita.merkez(id)))
		for tur in ["himaye", "hediye", "gozdagi"]:
			_btn(_ic, "%s  (%s)" % [oyun.IS_AD[tur], oyun.IS_BEDEL[tur]], func(): _sonuc_goster(oyun.bolge_is(id, tur)), not ici)
	if hk == "oyuncu":
		_ayrac(_ic)
		_bolum(_ic, "Yönetim")
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
	var sozl: Array = oyun.gorevler.filter(func(g): return g["gorev"] == "sozlesme")
	if not sozl.is_empty():
		_bolum(_ic, "Devam eden kirli işler")
		for g in sozl:
			var jj: Dictionary = g["is"]
			var ekip_ad: Array = []
			for aid in g["adamlar"]:
				ekip_ad.append(oyun.adam_bul(aid).get("ad", "?"))
			var kl: int = maxi(1, int(ceil((g["bitis"] - oyun.t) / 60.0)))
			var kv2 := _kutu(_ic)
			_lbl(kv2, oyun.isler_k.baslik(jj), 16)
			_lbl(kv2, "Ekip: %s · ~%d saat sonra döner · getirisi ~$%d" % [", ".join(ekip_ad), kl, int(jj["para"])], 13, RENK["warn"])
		_ayrac(_ic)
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
		_lbl(v, "Görev: " + durum, 15, Color(0.55, 0.3, 0.05) if a["gorev"] != "" else Color(0.15, 0.4, 0.15))
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
		_lbl(v, "Mahalle: %d" % bs, 14, Tema.SOLUK)
	for f in oyun.NPC:
		var fd: Dictionary = oyun.FAK[f]
		_ayrac(_ic)
		_lbl(_ic, "%s  ·  öfke %d" % [fd["ad"], int(oyun.ofke[f])], 18, fd["renk"])
		_lbl(_ic, oyun.rakip_k.ozet(f), 13, RENK["soluk"])
		if oyun.gerginlik.savasta("oyuncu", f):
			_btn(_ic, "Barış teklif et ($%d kirli)" % int(oyun.rakip_k.BARIS_BEDEL), func():
				var rs: Dictionary = oyun.rakip_k.baris_teklif(f)
				_sonuc_goster({"ok": rs["ok"], "msg": rs["m"]}))
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
			var ur := HBoxContainer.new()
			_ic.add_child(ur)
			_lbl(ur, "%s %s — %s · ilişki %+d" % ["♛" if u["rutbe"] == "don" else "•", oyun.uye_ad(u), yer, u["iliski"]], 14, renk)
			var uid_: int = u["uid"]
			if not oyun.kara_k.kayit_var(uid_):
				_btn(ur, "Deftere yaz", func(): _kd_secili = uid_; _yenile(true))
		var oluler: Array = oyun.uyeler.filter(func(u): return u["fak"] == f and u["durum"] == "olu")
		if not oluler.is_empty():
			_lbl(_ic, "Ölenler: %s" % ", ".join(oluler.map(func(u): return oyun.uye_ad(u))), 13, RENK["soluk"])
	_kara_defter_bolumu()

var _kd_secili := 0
var _kd_agirlik := 2

func _kara_defter_bolumu() -> void:
	_ayrac(_ic)
	_bolum(_ic, "Kara Defter")
	_lbl(_ic, "Seni kıranların kaydı. Kayıt bedava ama kin seni yorar. Kapatmak: af (öfke düşer), tazminat (korkuna bağlı), hesaplaşma ($%d kirli, adam gerekir; hedef ölür, dosyan kabarır)." % int(oyun.kara_k.HESAP_BEDEL), 13, RENK["soluk"])
	if _kd_secili > 0:
		var h: Dictionary = oyun.uye(_kd_secili)
		if h.is_empty() or h["durum"] != "aktif" or oyun.kara_k.kayit_var(_kd_secili):
			_kd_secili = 0
		else:
			_lbl(_ic, "Deftere yazılacak: %s · ağırlık %d" % [oyun.uye_ad(h), _kd_agirlik], 15, Color.WHITE)
			var ag := HBoxContainer.new()
			_ic.add_child(ag)
			for n in [1, 2, 3]:
				var nn: int = n
				_btn(ag, "Ağırlık %d" % n, func(): _kd_agirlik = nn; _yenile(true), _kd_agirlik == n)
			var nh := HBoxContainer.new()
			_ic.add_child(nh)
			for nd in oyun.kara_k.NEDENLER:
				var nds: String = nd
				_btn(nh, nds, func():
					var r: Dictionary = oyun.kara_k.ac(_kd_secili, nds, _kd_agirlik)
					_kd_secili = 0
					_sonuc_goster(r, "Deftere yazıldı."))
	var liste: Array = oyun.kara["liste"]
	if liste.is_empty():
		_lbl(_ic, "Defter boş.", 14, RENK["soluk"])
	for k in liste:
		var u: Dictionary = oyun.uye(k["hedef"])
		if u.is_empty():
			continue
		var kid: int = k["id"]
		_lbl(_ic, "%s — %s · ağırlık %d · kin %d" % [oyun.uye_ad(u), k["neden"], k["agirlik"], int(k["kin"])], 14, Color.WHITE)
		var br := HBoxContainer.new()
		_ic.add_child(br)
		_btn(br, "Affet", func(): _sonuc_goster(oyun.kara_k.kapat(kid, "af"), ""))
		_btn(br, "Tazminat iste (%%%d)" % int(oyun.kara_k.tazminat_olasilik(k["agirlik"]) * 100.0), func(): _sonuc_goster(oyun.kara_k.kapat(kid, "tazminat"), ""))
		_btn(br, "Hesaplaş ($%d kirli)" % int(oyun.kara_k.HESAP_BEDEL), func(): _sonuc_goster(oyun.kara_k.kapat(kid, "hesap"), ""), oyun.kirli < oyun.kara_k.HESAP_BEDEL or oyun.adamlar.is_empty())

# ---------- defter ----------
func _defter_paneli() -> void:
	_baslik(_ic, "Defter")
	var n: int = oyun.defter.size()
	for k in range(n - 1, maxi(-1, n - 41), -1):
		var e: Dictionary = oyun.defter[k]
		_lbl(_ic, "%s %s" % [oyun.saat_yazi(e["t"]), e["metin"]], 14, RENK[e["tur"]])

# ---------- polis / bodrum ----------
func _polis_paneli() -> void:
	var P: RefCounted = oyun.polis
	var p: Dictionary = oyun.pol
	_baslik(_ic, "Polis ve bodrum")
	_bar(_ic, "Dosya", oyun.arama, Color("a86a6a"), "%d · %s" % [int(oyun.arama), P.asama_ad()])
	_lbl(_ic, "Dosya 100'e çıkarsa dava açılır. 75'te arama emri: baskın gelir. Kanıt girmeyen her gün dosya biraz erir.", 13, RENK["soluk"])
	var dl := ""
	for x in P.dikkat_satirlari():
		dl += "%s %+d · " % [x[0], int(x[1])]
	_lbl(_ic, "Polis dikkati %d  (%s)" % [int(P.dikkat()), dl.trim_suffix(" · ")], 13, RENK["info"])
	if p["baskin"] != 0:
		_lbl(_ic, "Baskın yaklaşıyor: ~%d sa sonra." % maxi(1, int(ceil((p["baskin"] - oyun.t) / 60.0))), 15, RENK["bad"])
	_ayrac(_ic)
	_bolum(_ic, "Dedektif Dolan")
	var rh := HBoxContainer.new()
	_ic.add_child(rh)
	for m in [100, 300, 600]:
		var e: Dictionary = P.rusvet_tahmin(float(m))
		_btn(rh, "$%d · %%%d" % [m, int(round(e["p"] * 100.0))], func(): _sonuc_goster(P.rusvet(float(m))))
	_lbl(_ic, "Rüşvet: tutar · kabul ihtimali. Kabul edilirse dosya erir. Aylığa bağlarsan dikkat −15 olur ve baskını önceden haber verir.", 13, RENK["soluk"])
	_btn(_ic, "Aylığı kes" if p["aylik"] else "Aylığa bağla ($%d/ay)" % P.AYLIK_DOLAN, func(): _sonuc_goster(P.aylik_ver(not p["aylik"])))
	_ayrac(_ic)
	_bolum(_ic, "Bodrum imalathanesi")
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
	_baslik(_ic, "Meslek ve borç")
	if oyun.borc_k.var_mi():
		var b: Dictionary = oyun.borc
		_lbl(_ic, "Tefeci borcu: %s · aylık taksit %s · kaçırılan %d/3" % [oyun.para(b["ana"]), oyun.para(b["taksit"]), b["kacirilan"]], 15, RENK["bad"] if b["kacirilan"] > 0 else RENK["warn"])
		var bh := HBoxContainer.new()
		_ic.add_child(bh)
		for m in [100, 500, 1000]:
			_btn(bh, "Öde $%d" % m, func(): _sonuc_goster(oyun.borc_k.ode(float(m))), oyun.temiz < minf(m, b["ana"]))
		_ayrac(_ic)
	if M["is"].is_empty():
		_lbl(_ic, "İşsizsin. Bulunduğun mahalle: %s. Düz iş temiz gelir, tecrübe ve meşru bir yüz verir." % (oyun.harita.bolgeler[bid]["ad"] if bid != "" else "—"), 14, RENK["soluk"])
	else:
		var j: String = M["is"]["j"]
		var iy: String = oyun.harita.yerler[M["is"]["bina"]]["ad"] if M["is"].get("bina", -1) >= 0 else "?"
		var yokg: int = oyun.tarih()["gun"] - int(M["is"].get("son", 0))
		_lbl(_ic, "Çalıştığın iş: %s · iş yeri: %s (%s)" % [K.MESLEKLER[j]["ad"], iy, oyun.harita.bolgeler[M["is"]["b"]]["ad"]], 16, RENK["good"])
		_lbl(_ic, "Mesai başına ~%s, iş yerinde mesai bitince ödenir. Son mesai: %d gün önce." % [oyun.para(K.mesai_ucret()), yokg], 14, RENK["warn"] if yokg >= 3 else RENK["info"])
		_btn(_ic, "İşten ayrıl", func(): _sonuc_goster(K.is_birak()))
	_ayrac(_ic)
	var th: String = K.tatil_adi()
	_bolum(_ic, "GAZETE · İş İlanları — %s%s" % [oyun.tarih_yazi(), (" · " + th) if th != "" else ""])
	_lbl(_ic, "%s. İlanlar her gün değişir; işe girince ilandaki iş yerine gidip mesai yapmalısın." % K.donem_yazi(), 13, RENK["soluk"])
	for ad in K.ilanlar():
		var aj: String = ad["j"]
		var k2: Dictionary = K.kabul(aj, ad["bolge"])
		var ah2 := HBoxContainer.new()
		_ic.add_child(ah2)
		var mu: int = int(round(K.maas_gun(aj, ad["bolge"]) * ad["carpan"] * K.donem_carpan(aj)))
		_lbl(ah2, "%s · %s (%s) · mesai ~%s " % [K.MESLEKLER[aj]["ad"], oyun.harita.yerler[ad["bina"]]["ad"], oyun.harita.bolgeler[ad["bolge"]]["ad"], oyun.para(mu)], 14)
		_btn(ah2, "Başvur (%d/%d)" % [k2["puan"], k2["esik"]], func(): _sonuc_goster(K.is_gir(aj, ad["bolge"], ad["bina"], ad["carpan"])), not M["is"].is_empty())
	_ayrac(_ic)
	var A: RefCounted = oyun.aklama_k
	var pl: Dictionary = A.plan()
	_bolum(_ic, "Aklama ve maliye")
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
		if M["isletme"].has(j):
			_lbl(h, "✔ %s senin · ay geliri ~%s (doğrudan kasana)" % [m["isletme"], oyun.para(int(K.isletme_gelir(j) * K.donem_carpan(j)))], 14, RENK["good"])
		else:
			_btn(h, "%s al (%s)" % [m["isletme"], oyun.para(m["fiyat"])], func(): _sonuc_goster(K.isletme_al(j)), xp < 20.0 or oyun.temiz < m["fiyat"])
	_sonuc_satiri()

# ---------- garaj ----------
func _garaj_paneli() -> void:
	var K: RefCounted = oyun.arac_k
	var Ar: Dictionary = K.ARACLAR
	var a: Dictionary = oyun.arac
	_baslik(_ic, "Garaj")
	if a["tip"] == "":
		_lbl(_ic, "Araban yok. Araba yürümekten çok hızlıdır ama yakıt ve bakım ister; ekibin, paran ve mahallelerin büyüdükçe masrafı azalır.", 14, RENK["soluk"])
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
	_baslik(_ic, "Hedefler")
	_lbl(_ic, "Bu koşullar tutunca kazanım alırsın; oyun bitmez, istediğin kadar devam edersin. Koşullar ay sonunda kontrol edilir.", 14, RENK["soluk"])
	var D: Dictionary = oyun.zafer.durum()
	var yollar := [["durust", "Dürüst iş (2 ay üst üste)", oyun.zf["durust_ay"]], ["baskan", "Belediye başkanlığı (yıllık seçim, 12. ay)", -1], ["hakim", "Hâkimiyet (2 ay üst üste)", oyun.zf["hakim_ay"]]]
	for y in yollar:
		_ayrac(_ic)
		var ad: String = y[1]
		if y[2] >= 0:
			ad += " · %d/2 ay" % y[2]
		_bolum(_ic, ad)
		for x in D[y[0]]:
			var h := HBoxContainer.new()
			_ic.add_child(h)
			_lbl(h, "%s %s" % ["✔" if x["ok"] else "✘", x["k"]], 15, RENK["good"] if x["ok"] else RENK["soluk"])
			var v := _lbl(h, x["v"], 15)
			v.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ayrac(_ic)
	_bolum(_ic, "Seçim kampanyası")
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
	var olum: bool = oyun.son["tur"] == "olum"
	var b := _lbl(v, "HAYATIN SONU", 28, RENK["bad"])
	b.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if oyun.son["tur"] == "yenilgi":
		pc.custom_minimum_size = Vector2(760, 0)
		_ozet_paneli(v)
	else:
		_lbl(v, oyun.son["metin"], 16)
	if olum:
		_lbl(v, "Devam edelim mi? Ailenin başına kim geçsin? (Servetin %%%d'i kaybolur.)" % int(round(oyun.kisi_k.kayip_orani() * 100.0)), 16, RENK["warn"])
		var K := preload("res://scripts/core/kisiler.gd")
		for k in oyun.kisi_k.adaylar():
			var kid: int = int(k["id"])
			_btn(v, "%s — %s, %d yaş · %s" % [k["ad"], K.ROL_AD[k["rol"]], oyun.kisi_k.yas(k), oyun.kisi_k.oz_yazi(k["oz"])], func(): _miras_sec(kid))
		_btn(v, "Hayır, hayat burada bitsin", func():
			oyun.son = {"tur": "yenilgi", "metin": oyun.son["metin"] + "\n\n" + oyun.kisi_k.ozet_yazi()}
			_son_ortu.queue_free()
			_son_ortu = null
			_son_kontrol())
	if not olum:
		_btn(v, "Ana menü", _ana_menu)
	add_child(_son_ortu)
	Engine.time_scale = 0.0
	modal = true

func _miras_sec(id: int) -> void:
	var r: Dictionary = oyun.kisi_k.miras_al(id)
	if not r["ok"]:
		return
	_son_ortu.queue_free()
	_son_ortu = null
	modal = false
	Engine.time_scale = sokak._hiz

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
func _saat_yazi(h: float) -> String:
	return "%02d:%02d" % [int(h), int(round((h - int(h)) * 60.0))]

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
	_lbl(_ic, "Mahallesi: %s" % oyun.harita.bolgeler[g["ev"]]["ad"], 16)
	var simdi: String = oyun.harita.bolge_at(g["pos"])
	if simdi != "":
		_lbl(_ic, "Şu an: %s" % oyun.harita.bolgeler[simdi]["ad"], 16)
	match g["tur"]:
		"polis":
			_lbl(_ic, "Devriye gezen polisler. Yanlarında kirli iş yapma; ileride delil ve arama buraya bağlanacak.", 15, RENK["warn"])
		"rakip":
			var f: Dictionary = oyun.FAK[g["fak"]]
			_lbl(_ic, "Fraksiyon: %s" % f["ad"], 16, f["renk"])
			_lbl(_ic, "Bu ekibin mahallesinde rakip sayılırsın. İleride pazarlık, baskın ve çatışma buradan açılacak.", 15, RENK["warn"])
		"sivil":
			_lbl(_ic, "Mahalle halkı.", 15, RENK["soluk"])
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
var _dlg_arka: TextureRect

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
	_dlg_arka = TextureRect.new()
	_dlg_arka.texture = load("res://assets/ui/panel/karsilasma.png")
	_dlg_arka.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_dlg_arka.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_dlg_arka.modulate = Color(0.42, 0.40, 0.38)
	_dlg_arka.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dlg_arka.clip_contents = true
	_dlg.add_child(_dlg_arka)
	_dlg_ic = VBoxContainer.new()
	_dlg_ic.add_theme_constant_override("separation", 8)
	_dlg.add_child(_dlg_ic)
	_kars = load("res://scripts/core/karsilasma.gd").new(oyun, sokak.gruplar)

var _kumar: Control

func kumar_ac() -> void:
	if modal:
		return
	modal = true
	sokak.modal_duraklat(true)
	_kumar = load("res://scripts/ui/kumar_pencere.gd").new()
	add_child(_kumar)
	_kumar.kur(oyun, self)

func kumar_kapandi() -> void:
	modal = false
	sokak.modal_duraklat(false)
	_kumar = null
	_yenile(true)

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
	_dlg.custom_minimum_size = Vector2(480, 460)
	_dlg_arka.visible = true
	var arka_ad := "karsilasma"
	if str(g.get("tur", "")) == "polis" and ResourceLoader.exists("res://assets/ui/panel/karsilasma_polis.png"):
		arka_ad = "karsilasma_polis"
	if str(g.get("tur", "")) == "sivil" and ResourceLoader.exists("res://assets/ui/panel/grup_sivil.png"):
		arka_ad = "grup_sivil"
	match str(_dlg_sonuc.get("savas_sonuc", "")):
		"zafer":
			arka_ad = "savas_win"
		"yenilgi":
			arka_ad = "savas_lose"
	_dlg_arka.texture = load("res://assets/ui/panel/%s.png" % arka_ad)
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
			r["savas_sonuc"] = str(s.get("sonuc", ""))
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
	if modal or oyun.yol["bekleyen"] == "" or oyun.t < oyun.yol.get("acilis", 0):
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
	_dlg_arka.visible = false
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
	var sg: Dictionary = K.salgin()
	if not sg.is_empty():
		_lbl(kim, "⚠ Şehirde %s salgını var" % K.HASTALIK[sg["id"]]["ad"], 15, RENK["bad"])
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
	for kid in oyun.sil_k.KUSUR:
		if oyun.sil_k.kusur(kid):
			_lbl(_ic, "✘ %s: %s" % [oyun.sil_k.KUSUR[kid]["ad"], oyun.sil_k.KUSUR[kid]["ac"]], 13, RENK["bad"])
	var kisa := HBoxContainer.new()
	_ic.add_child(kisa)
	_btn(kisa, "Silahlar", silah_ac)
	_btn(kisa, "Beceri ağacı", yetenek_ac)
	_btn(kisa, "Ailem", ailem_ac)
	_btn(kisa, "Nüfuz", nufuz_ac)
	_btn(kisa, "Kazanımlar (%d)" % oyun.kaz_k.sayi(), kazanim_ac)
	_un_bolumu()
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
		for id in l:
			var e: Dictionary = K.EYLEM[id]
			var b := Button.new()
			b.focus_mode = Control.FOCUS_NONE
			b.custom_minimum_size = Vector2(0, 38)
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			b.add_theme_stylebox_override("normal", _gaz_dugme_stil(Color(0.11, 0.08, 0.055), Color(0.62, 0.48, 0.26), 10))
			b.add_theme_stylebox_override("hover", _gaz_dugme_stil(Color(0.22, 0.15, 0.08), Tema.VURGU, 10))
			b.add_theme_stylebox_override("pressed", _gaz_dugme_stil(Color(0.34, 0.23, 0.10), Color("f0d890"), 10))
			b.pressed.connect(func(): kumar_ac() if id == "kumar" else _sonuc_goster(K.yap(id)))
			var hb := HBoxContainer.new()
			hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			hb.offset_left = 12.0
			hb.offset_right = -12.0
			hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hb.add_theme_constant_override("separation", 12)
			b.add_child(hb)
			var parcalar := [[String(e["ad"]), Tema.YAZI, 15, true], ["$%d" % int(e["ucret"]), Tema.VURGU, 14, false], ["%d dk" % int(e["dk"]), Color(0.78, 0.72, 0.6), 14, false], [_efekt_yazi(e["d"]), Color("8fd08f"), 13, false]]
			for pc in parcalar:
				var lb := Label.new()
				lb.text = pc[0]
				lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
				lb.add_theme_font_size_override("font_size", Tema.boyut(pc[2]))
				lb.add_theme_color_override("font_color", pc[1])
				if pc[3]:
					lb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(lb)
			kv.add_child(b)
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
			b.icon = load("res://assets/ui/icons/tokalasma.png")
			b.expand_icon = true
			b.add_theme_constant_override("icon_max_width", 30)
			b.tooltip_text = "Kirli para ile tutulur. Beceri %d" % int((c["yumruk"] * 0.5 + c["bicak"] * 0.3 + c["zeka"] * 0.2))
			n += 1
		var jv := _kutu(_ic, "Kirli İşler (ün %d)" % int(oyun.kis_k.taninma()))
		var teklifler: Array = oyun.isler_k.liste(i)
		if teklifler.is_empty():
			_lbl(jv, "Bugün iş yok.", 14, RENK["soluk"])
		var m := 0
		for j in teklifler:
			var jdx := m
			var T: Dictionary = oyun.isler_k.TURLER[j["id"]]
			var jh := HBoxContainer.new()
			jh.add_theme_constant_override("separation", 8)
			jv.add_child(jh)
			var jvb := VBoxContainer.new()
			jvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			jh.add_child(jvb)
			_lbl(jvb, oyun.isler_k.baslik(j), 16)
			_lbl(jvb, "%s · %d adam · %s · ~%d sa" % [oyun.isler_k.risk_yazi(j), T["kisi"], j["veren"], int(T["sure"] / 60.0)], 12, Tema.SOLUK)
			var jt := _lbl(jvb, T["ac"], 12, Tema.SOLUK)
			jt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			jt.custom_minimum_size = Vector2(280, 0)
			var jb := _btn(jh, "Al
$%d" % int(j["para"]), func(): _sonuc_goster(oyun.isler_k.kabul(i, jdx)), oyun.bos_adamlar().size() < T["kisi"])
			if j.get("pusu", -1) >= 0:
				var pb := _btn(jv, "Pusuya yat: %s (kendin, +%%25)" % oyun.harita.yerler[j["pusu"]]["ad"], func(): _sonuc_goster(oyun.isler_k.pusu_kur(i, jdx)))
				pb.tooltip_text = "Hedef o otelde kalıyor olabilir. Orada oda tutup bekle; adam gerekmez, risk sende."
			jb.tooltip_text = "Boşta en az %d adam gerekir. Başarısızlıkta polis dosyası kabarır, adamlar yaralanabilir." % T["kisi"]
			m += 1
	_sonuc_satiri()

# ---------- silahlar ----------
var _sil_acik := 0   # ayrıntısı açık silah (uid)

func _silah_paneli() -> void:
	var K: RefCounted = oyun.sil_k
	_baslik(_ic, "Silahlar", "Elindeki silah senin imzan.")
	var kap: float = K.kapasite("u")
	var yk: float = K.yuk("u")
	_bar(_ic, "Taşıma yükü", minf(100.0, yk / maxf(kap, 0.1) * 100.0), RENK["bad"] if yk > kap else Color("a89870"), "%.1f / %.1f kg" % [yk, kap])
	if K.kapasite("b") > 0.0:
		_bar(_ic, "Araç bagajı", minf(100.0, K.yuk("b") / K.kapasite("b") * 100.0), Color("8a7a58"), "%.1f / %.1f kg" % [K.yuk("b"), K.kapasite("b")])
	var ek: Label = _lbl(_ic, "Güçlü ve kalabalık gezersen daha çok taşırsın; araba bagajı ek yer verir. Üstündeki yasa dışı silah ve fazla mermi polis aramasında seni yakar.", 13, RENK["soluk"])
	ek.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if K.asiri() > 0.0:
		_lbl(_ic, "Yük fazla: nişanın sapıyor, doldurman yavaşlıyor. Fazlasını eve bırak.", 14, RENK["bad"])
	for kid in K.KUSUR:
		if K.kusur(kid):
			_lbl(_ic, "✘ %s — %s" % [K.KUSUR[kid]["ad"], K.KUSUR[kid]["ac"]], 13, RENK["bad"])
	if K.kusur("miyop") and not oyun.kis.get("gozluk", false):
		_btn(_ic, "Gözlük yaptır ($45)", func(): _sonuc_goster(K.gozluk_al()))
	var ru: String = "geçerli (%d gün)" % int((oyun.sil["ruhsat"] - oyun.t) / oyun.DAY) if K.ruhsat_var() else "yok"
	_lbl(_ic, "Tabanca ruhsatı: %s" % ru, 14, RENK["good"] if K.ruhsat_var() else RENK["warn"])
	if not K.ruhsat_var():
		_btn(_ic, "Ruhsat çıkar ($200 temiz)", func(): _sonuc_goster(K.ruhsat_al()))
	_ayrac(_ic)
	_bolum(_ic, "Silahların")
	var el: Dictionary = K.eldeki()
	_lbl(_ic, "Elinde: %s" % (K.ad(el) if not el.is_empty() else "yalnızca yumruk"), 16, RENK["altin"])
	if oyun.sil["liste"].is_empty():
		_lbl(_ic, "Hiç silahın yok. Aşağıdan satın alabilirsin.", 14, RENK["soluk"])
	for yer in ["u", "b", "e"]:
		for w in oyun.sil["liste"]:
			if w["yer"] == yer:
				_silah_kutusu(w)
	_ayrac(_ic)
	_bolum(_ic, "Mermi")
	for kal in K.KAL:
		_lbl(_ic, "%s — üstünde %d · bagajda %d · evde %d" % [K.KAL[kal]["ad"], K.muh("u", kal), K.muh("b", kal), K.muh("e", kal)], 14)
		var mh := HBoxContainer.new()
		_ic.add_child(mh)
		_btn(mh, "Kutu al (%s)" % oyun.para(K.mermi_fiyat(kal)), func(): _sonuc_goster(K.mermi_al(kal)), oyun.kirli + oyun.temiz < K.mermi_fiyat(kal))
		_btn(mh, "Evden 20 al", func(): _sonuc_goster(K.muh_tasi(kal, 20, "e", "u")), K.muh("e", kal) <= 0)
		_btn(mh, "Eve 20 bırak", func(): _sonuc_goster(K.muh_tasi(kal, 20, "u", "e")), K.muh("u", kal) <= 0)
		if K.kapasite("b") > 0.0:
			_btn(mh, "Bagaja 20", func(): _sonuc_goster(K.muh_tasi(kal, 20, "u", "b")), K.muh("u", kal) <= 0)
	_ayrac(_ic)
	_bolum(_ic, "Antrenman")
	_lbl(_ic, "Poligonda atış çalışırsın: nişan ve silah ustalığı artar, silah alışır. 15 mermi + $20 gider, 3 saat sürer.", 13, RENK["soluk"])
	_btn(_ic, "Poligona git", func(): _sonuc_goster(K.poligon()))
	if not oyun.sil["emanet"].is_empty():
		_ayrac(_ic)
		_bolum(_ic, "Polis emaneti")
		for w in oyun.sil["emanet"]:
			var eh := HBoxContainer.new()
			_ic.add_child(eh)
			_lbl(eh, K.ad(w), 14)
			var wid: int = w["uid"]
			_btn(eh, "Rüşvetle geri al (%s)" % oyun.para(K.emanet_fiyat(w)), func(): _sonuc_goster(K.emanetten_al(wid)))
	if not oyun.sil["kayip"].is_empty():
		_ayrac(_ic)
		_bolum(_ic, "Kaybettiklerin")
		for kw in oyun.sil["kayip"]:
			_lbl(_ic, "• %s%s" % [kw["ad"], (" (%d kurban)" % kw["kills"]) if kw["kills"] > 0 else ""], 13, RENK["soluk"])
	_ayrac(_ic)
	_bolum(_ic, "Silah dükkânı")
	for tip in K.KATALOG:
		if tip == "yumruk":
			continue
		var T: Dictionary = K.KATALOG[tip]
		var dh := HBoxContainer.new()
		_ic.add_child(dh)
		_lbl(dh, "%s (%s)" % [T["ad"], "iki el" if T["el"] == 2 else "tek el"], 14)
		var ff: int = K.fiyat(tip)
		_btn(dh, oyun.para(ff), func(): _sonuc_goster(K.al(tip)), oyun.kirli + oyun.temiz < ff)
		var tt := _lbl(_ic, T["ac"], 12, RENK["soluk"])
		tt.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sonuc_satiri()

func _silah_kutusu(w: Dictionary) -> void:
	var K: RefCounted = oyun.sil_k
	var kat: Dictionary = K.KATALOG[w["tip"]]
	var el: Dictionary = K.eldeki()
	var elde: bool = not el.is_empty() and el["uid"] == w["uid"]
	var uid: int = w["uid"]
	var v := _kutu(_ic)
	var un: String = K.unvan(w)
	_lbl(v, "%s%s%s" % ["► " if elde else "", K.ad(w), ("  [%s]" % un) if un != "" else ""], 17, RENK["altin"] if elde else Color.WHITE)
	var alt := "%s · %s · %s" % [K.YER_AD[w["yer"]], "iki el" if kat["el"] == 2 else "tek el", ("%s mermi" % kat["kal"]) if kat["kal"] != "" else "yakın dövüş"]
	if w["kills"] > 0:
		alt += " · %d kurban" % w["kills"]
	if w["sahip"] != "":
		alt += " · %s'ın malı" % oyun.FAK[w["sahip"]]["ad"]
	_lbl(v, alt, 13, RENK["soluk"])
	var yazi: String = w["yazi"] if w["yazi"] != "" else kat["ac"]
	var yl := _lbl(v, yazi, 13, RENK["soluk"])
	yl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bar(v, "Durum", w["durum"], Color("a89870"), "%d%%" % int(w["durum"]))
	var h := HBoxContainer.new()
	v.add_child(h)
	if w["yer"] == "u" and not elde:
		_btn(h, "Eline al", func(): _sonuc_goster(K.kusan(uid)))
	for y in ["u", "b", "e"]:
		if y != w["yer"] and (y != "b" or K.kapasite("b") > 0.0):
			var yy: String = y
			_btn(h, "→ " + K.YER_AD[y], func(): _sonuc_goster(K.tasi(uid, yy)))
	_btn(h, "Kapat" if _sil_acik == uid else "Ayrıntı", func():
		_sil_acik = 0 if _sil_acik == uid else uid
		_yenile(true))
	if _sil_acik != uid:
		return
	var kr: Dictionary = K.karne(w)
	for k in kr["d"]:
		_bar(v, k, kr["d"][k], Color("8a7a58"), "%d" % int(kr["d"][k]))
	for ys in kr["yorum"]:
		var yo := _lbl(v, "• " + ys, 13)
		yo.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl(v, kr["uyum"] + " Alışma: %d%%" % int(w["alisma"]), 13, RENK["info"])
	_lbl(v, "İmza değeri (gösteriş): %d" % int(K.prestij(w)), 13, RENK["altin"])
	for pid in K.parca_listesi(w["tip"]):
		var pd: Dictionary = K.PARCA[pid]
		var mal: int = K.parca_maliyet(w, pid)
		var ph := HBoxContainer.new()
		v.add_child(ph)
		_lbl(ph, "%s %d/3" % [pd["ad"], K.lv(w, pid)], 14)
		var pp: String = pid
		_btn(ph, "Son seviye" if mal < 0 else "Geliştir (%s)" % oyun.para(mal), func(): _sonuc_goster(K.parca_yap(uid, pp)), mal < 0 or oyun.kirli + oyun.temiz < mal)
		var pa := _lbl(v, pd["ac"], 12, RENK["soluk"])
		pa.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var bh := HBoxContainer.new()
	v.add_child(bh)
	_btn(bh, "Bakım yap", func(): _sonuc_goster(K.bakim(uid)), w["durum"] >= 99.0)
	_btn(bh, "Adlandır", func(): _sonuc_goster(K.lakap(uid)))
	var sf: int = K.sat_fiyat(w)
	_btn(bh, "Sat (%s)" % oyun.para(sf), func(): _sonuc_goster(K.sat(uid)), w["prestij_ek"] >= 15.0 or w["sahip"] != "")

# ---------- beceri ağacı ----------
func _yetenek_paneli() -> void:
	var Y: RefCounted = oyun.yet_k
	_baslik(_ic, "Beceri ağacı", "Yaptıkların seni şekillendirir; kullanılmayan beceri körelir.")
	for d in Y.dallar():
		_bolum(_ic, Y.DAL_AD[d[0]])
		for id in d[1]:
			var T: Dictionary = Y.YET[id]
			var pu: float = Y.puan(id)
			var acik: bool = Y.acik(id)
			var v := _kutu(_ic)
			_bar(v, "%s · sv %d" % [T["ad"], Y.seviye(id)], pu, Color("a89870") if acik else Color("6a6a6a"), "%d" % int(pu))
			var ya := _lbl(v, T["ac"], 13, RENK["soluk"])
			ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			if not acik:
				_lbl(v, "Kilitli: %s %d puana ulaşınca açılır." % [Y.YET[T["ust"][0]]["ad"], int(T["ust"][1])], 13, RENK["bad"])
	_ayrac(_ic)
	_bolum(_ic, "Neyi besler, neyi köreltir?")
	var ipucu := [
		"Poligon, bilardo, çatışma → nişan ve silah becerileri (+).",
		"İçki → nişan, hızlı el, direksiyon (−).",
		"Taksicilik → direksiyon ve kaçış, biraz ikna ve sokak aklı (+); nişan hafif (−).",
		"Sohbet, berberlik → ikna; kumar → pazarlık ve sokak aklı.",
		"Antrenman, hamallık → yakın dövüş.",
		"Dua etmek gözdağını köreltir; kâtiplik pazarlığı büyütür.",
	]
	for ip in ipucu:
		var il := _lbl(_ic, "• " + ip, 13, RENK["soluk"])
		il.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_sonuc_satiri()


# ---------- ailem (kültür: köken, inanç, değerler, gelenekler) ----------
func _ailem_secenek(ebeveyn: Node, ad: String, ac: String, secili: bool, pasif: bool, fn: Callable) -> void:
	var v := _kutu(ebeveyn)
	_btn(v, ("✔ " if secili else "") + ad, fn, pasif)
	var ya := _lbl(v, ac, 13, RENK["soluk"])
	ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _ailem_paneli() -> void:
	var A: RefCounted = oyun.aile_k
	var a: Dictionary = oyun.aile
	var kuruldu: bool = a["kuruldu"]
	_baslik(_ic, "Ailem", "Kültürün her seçimi bir bonus ve bir bedel getirir.")
	_lbl(_ic, "Aile Namı: %d" % int(a["nam"]), 15, RENK["altin"])
	if not kuruldu:
		var u := _lbl(_ic, "Aile henüz kurulmadı: köken, inanç ve değerler şimdi seçilir, onaylayınca kilitlenir. Gelenekler sonradan değişebilir (bedelli).", 13, RENK["soluk"])
		u.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bolum(_ic, "Köken")
	for id in A.KOKEN:
		var T: Dictionary = A.KOKEN[id]
		var ac: String = T["ac"] + (" · " + A.etki_yazi(T["e"]) if not T["e"].is_empty() else "")
		_ailem_secenek(_ic, T["ad"], ac, a["koken"] == id, kuruldu, func(): _sonuc_goster(A.koken_sec(id)))
	_bolum(_ic, "İnanç")
	for id in A.INANC:
		var T: Dictionary = A.INANC[id]
		_ailem_secenek(_ic, T["ad"], T["ac"] + " · " + A.etki_yazi(T["e"]), a["inanc"] == id, kuruldu, func(): _sonuc_goster(A.inanc_sec(id)))
	_bolum(_ic, "Değerler (en fazla iki)")
	for k in A.DEGER:
		var D: Dictionary = A.DEGER[k]
		var h := _kutu(_ic, D["ad"])
		for taraf in ["sol", "sag"]:
			var T: Dictionary = D[taraf]
			_btn(h, ("✔ " if a["deger"].get(k, "") == taraf else "") + T["ad"] + " — " + A.etki_yazi(T["e"]), func(): _sonuc_goster(A.deger_sec(k, taraf)), kuruldu)
	_bolum(_ic, "Gelenekler (%d slot)" % A.GEL_SLOT)
	for s in A.GEL_SLOT:
		var id: String = a["gel"][s]
		var v := _kutu(_ic, "Slot %d" % (s + 1))
		if id == "":
			_lbl(v, "Boş", 14, RENK["soluk"])
		else:
			var G: Dictionary = A.GEL[id]
			var yari: bool = A.yari_mi(id)
			_lbl(v, G["ad"] + (" (alışıyor: yarım etki)" if yari else ""), 15)
			var ya := _lbl(v, A.etki_yazi(G["e"], yari), 13, RENK["soluk"])
			ya.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_btn(v, "Seç" if id == "" else "Değiştir", func():
			_ailem_slot = -1 if _ailem_slot == s else s
			_yenile(true))
		if _ailem_slot == s:
			var grup := ""
			for gid in A.GEL:
				var G2: Dictionary = A.GEL[gid]
				if G2["g"] != grup:
					grup = G2["g"]
					_lbl(v, grup, 14, RENK["altin"])
				var secili: bool = a["gel"].has(gid)
				var cak: String = A._cakisan(gid)
				var engel: bool = secili or (cak != "" and cak != id)
				var ad: String = G2["ad"] + ("  (çatışır: %s)" % A.GEL[cak]["ad"] if engel and not secili else "")
				_btn(v, ad + " — " + A.etki_yazi(G2["e"]), func():
					_ailem_slot = -1
					_sonuc_goster(A.gelenek_sec(s, gid)), engel)
	if not kuruldu:
		_ayrac(_ic)
		_btn(_ic, "Aileyi kur (onayla)", func(): _sonuc_goster(A.kur_onayla()))
	_ayrac(_ic)
	_uyeler_bolumu()
	_ayrac(_ic)
	_bolum(_ic, "Toplam etkiler")
	var te: Dictionary = A.toplam_etkiler()
	if te.is_empty():
		_lbl(_ic, "Henüz etki yok.", 13, RENK["soluk"])
	for k in te:
		var v2: float = te[k]
		_lbl(_ic, "%s: %s%d%%" % [A.ETKI_AD[k], "+" if v2 > 0 else "−", int(round(absf(v2) * 100.0))], 14, RENK["good"] if v2 > 0 else RENK["bad"])
	_sonuc_satiri()

func _kazanim_paneli() -> void:
	var KZ: RefCounted = oyun.kaz_k
	_baslik(_ic, "Kazanımlar", "%d / %d — oyun bitmez; her dönüm noktası bir kazanımdır." % [KZ.sayi(), KZ.LISTE.size()])
	for id in KZ.LISTE:
		var al: bool = KZ.var_mi(id)
		var v := _kutu(_ic, ("★ " if al else "☆ ") + KZ.LISTE[id]["ad"])
		var tl := _lbl(v, KZ.LISTE[id]["ac"], 13, RENK["good"] if al else RENK["soluk"])
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

# Hayat özeti: ün eksenleri çubuk grafiği, kuşak zaman çizgisi, kazanımlar ve sonuç.
func _ozet_paneli(v: VBoxContainer) -> void:
	var K: RefCounted = oyun.kisi_k
	var U: RefCounted = oyun.un_k
	var tip: Dictionary = U.tip()
	var ana: String = str(oyun.son["metin"]).split("\n\n")[0]
	var l0 := _lbl(v, ana, 15, RENK["soluk"])
	l0.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_lbl(v, "%s — %s" % [oyun.profil.get("ad", "Sen"), tip["ad"]], 24, RENK["warn"])
	_lbl(v, "%d yaşında öldü · %d nesil · %d yıl" % [K.oyuncu_yas(), int(oyun.aile["nesil"]), oyun.tarih()["yil"]], 14, RENK["soluk"])
	_bolum(v, "Ün eksenleri")
	for e in U.EKSENLER:
		_bar(v, U.AD[e], U.deger(e), U.RENK[e])
	_bolum(v, "Kuşaklar")
	var zc := HBoxContainer.new()
	zc.add_theme_constant_override("separation", 6)
	v.add_child(zc)
	for g in oyun.aile["gecmis"]:
		var gl := _lbl(zc, "%s\n%s\n%d yaş" % [g["ad"], g["tip"], g["yas"]], 12, RENK["soluk"])
		gl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_lbl(zc, "→", 16, RENK["soluk"])
	var sl := _lbl(zc, "%s\n%s\n%d yaş" % [oyun.profil.get("ad", "Sen"), tip["ad"], K.oyuncu_yas()], 12, RENK["warn"])
	sl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_bolum(v, "Kazanımlar (%d/%d)" % [oyun.kaz_k.sayi(), oyun.kaz_k.LISTE.size()])
	var ad: PackedStringArray = []
	for id in oyun.kaz_k.LISTE:
		if oyun.kaz_k.var_mi(id):
			ad.append("★ " + oyun.kaz_k.LISTE[id]["ad"])
	var kl := _lbl(v, "  ".join(ad) if not ad.is_empty() else "Hiç kazanım yok.", 13, RENK["good"])
	kl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_bolum(v, "Sonuç")
	var sy := _lbl(v, K.ozet_anisi() + "\n" + K.sonuc_yazi(), 15)
	sy.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _nufuz_paneli() -> void:
	var N: RefCounted = oyun.nuf_k
	_baslik(_ic, "Nüfuz", "Dokunulmazlık, federal baskı, sadakat ve malikâne.")
	_bolum(_ic, "Dokunulmazlık (rüşvet kirli paradan, her ay −6)")
	for k in N.KISI:
		var v := _kutu(_ic, "%s — %d" % [N.KISI[k]["ad"], int(N.dokun(k))])
		_bar(v, "", N.dokun(k), RENK["altin"], "%d" % int(N.dokun(k)))
		_lbl(v, N.KISI[k]["ac"], 13, RENK["soluk"])
		_btn(v, "Rüşvet ver (%s)" % oyun.para(N.ucret_k(k)), func(): _sonuc_goster(N.rusvet_ver(k)))
	_bolum(_ic, "Federal ilgi")
	_bar(_ic, "Federal", N.fed(), RENK["bad"], "%d" % int(N.fed()))
	_lbl(_ic, "60 üstünde ajanlar kasaya el koyar, vergi keser. 100'de dava açılır.", 13, RENK["soluk"])
	_btn(_ic, "Avukat tut (%s)" % oyun.para(N.AVUKAT_UCRET), func(): _sonuc_goster(N.avukat()))
	_bolum(_ic, "Adamların sadakati")
	if oyun.adamlar.is_empty():
		_lbl(_ic, "Ekibinde adam yok.", 13, RENK["soluk"])
	for a in oyun.adamlar:
		var s: float = N.sadakat(a)
		_bar(_ic, a["ad"], s, RENK["good"] if s >= 40.0 else RENK["bad"], "%d%s" % [int(s), " ⚠ darbe riski" if s < 30.0 else ""])
	_bolum(_ic, "Kötü yol")
	var K: RefCounted = oyun.kotu_k
	_lbl(_ic, "Tefeci borcu: %s · rezillik %d · hapis %d kez" % [oyun.para(oyun.kotu["tef"]), int(oyun.kotu["rezil"]), int(oyun.kotu["hapis_say"])], 14, RENK["bad"] if oyun.kotu["tef"] > 0.0 else RENK["soluk"])
	var kh := HBoxContainer.new()
	_ic.add_child(kh)
	_btn(kh, "Tefeciden $500", func(): _sonuc_goster(K.tefeci_al(500.0)))
	_btn(kh, "Borç öde $500", func(): _sonuc_goster(K.tefeci_ode(500.0)))
	var kh2 := HBoxContainer.new()
	_ic.add_child(kh2)
	_btn(kh2, "Kumar masası (zar · poker · rulet)", func(): kumar_ac())
	_btn(_ic, "Küçük soygun yap (riskli)", func(): _sonuc_goster(K.soygun()))
	_bolum(_ic, "Malikâne")
	if oyun.nuf["mal"]:
		_lbl(_ic, "Malikânen var: sadakat +, saygı +.", 14, RENK["good"])
		_btn(_ic, "Parti ver (%s)" % oyun.para(N.PARTI_UCRET), func(): _sonuc_goster(N.parti()))
	else:
		_btn(_ic, "Malikâne satın al (%s)" % oyun.para(N.MAL_FIYAT), func(): _sonuc_goster(N.mal_al()))
	_sonuc_satiri()

func _uyeler_bolumu() -> void:
	var KS: RefCounted = oyun.kisi_k
	var K := preload("res://scripts/core/kisiler.gd")
	_bolum(_ic, "Aile üyeleri — nesil %d" % int(oyun.aile["nesil"]))
	_lbl(_ic, "Sen: %s, %d yaşında · %s" % [oyun.profil.get("ad", "Sen"), KS.oyuncu_yas(), KS.oz_yazi(oyun.aile["oz"])], 14, RENK["altin"])
	var l: Array = KS.canlilar()
	if l.is_empty():
		_lbl(_ic, "Henüz kimse yok.", 13, RENK["soluk"])
	for k in l:
		var kid: int = int(k["id"])
		var v := _kutu(_ic, "%s (%s, %d yaş)" % [k["ad"], K.ROL_AD[k["rol"]], KS.yas(k)])
		var tl := _lbl(v, "%s · bağ %d" % [KS.oz_yazi(k["oz"]), int(k["sevgi"])], 13, RENK["soluk"])
		tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_btn(v, "Konuş", func(): _sonuc_goster(KS.konus(kid)))
	if KS.evlenebilir():
		if oyun.aile["adaylar"].is_empty():
			_btn(_ic, "Eş ara", func():
				KS.es_adaylari_uret()
				_yenile(true))
		else:
			_lbl(_ic, "Evlilik adayları (düğün %s):" % oyun.para(K.EVLEN_UCRET), 14)
			for i in oyun.aile["adaylar"].size():
				var c: Dictionary = oyun.aile["adaylar"][i]
				_btn(_ic, "%s, %d yaş · %s" % [c["ad"], KS.yas(c), KS.oz_yazi(c["oz"])], func(): _sonuc_goster(KS.evlen(i)))

func _un_bolumu() -> void:
	var U: RefCounted = oyun.un_k
	var tip: Dictionary = U.tip()
	_bolum(_ic, "Ün: %s" % tip["ad"])
	var tl := _lbl(_ic, tip["ac"], 13, RENK["soluk"])
	tl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for e in U.EKSENLER:
		_bar(_ic, U.AD[e], U.deger(e), U.RENK[e], "%d" % int(U.deger(e)))
	_btn(_ic, "Mahalleye bağış (%s)" % oyun.para(U.BAGIS_FIYAT), func(): _sonuc_goster(U.bagis()))
