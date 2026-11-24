extends Control
# Kumar masası: Zar (kazanma ihtimali gösterilir), Poker (5 kâğıt, bir değişim), Rulet.
# Kazanma ihtimali kişisel özelliklere (zeka, kumarbaz, pazarlık, sokak aklı) ve rakibin becerisine bağlı.

const Tema := preload("res://scripts/ui/tema.gd")
const BAHISLER := [10, 25, 50, 100, 250, 500]
const RAKIPLER := ["Sakallı Mick", "Kör Tony", "Madam Rose", "Şapkalı Leo", "Dişçi Hank", "Tatlı Vinnie"]
const RENKLI := [1, 3, 5, 7, 9, 12, 14, 16, 18, 19, 21, 23, 25, 27, 30, 32, 34, 36]
const TAKIM := ["♠", "♥", "♦", "♣"]
const DEGER := ["2", "3", "4", "5", "6", "7", "8", "9", "10", "J", "Q", "K", "A"]
const EL_AD := ["Yüksek kâğıt", "Bir çift", "İki çift", "Üçlü", "Seri", "Renk", "Full", "Dörtlü", "Düz seri (straight flush)"]

var oyun: Node
var arayuz: Node
var rng := RandomNumberGenerator.new()
var _bahis := 25
var _oyun_ad := "zar"
var _rakip_ad := ""
var _rakip := 0.5      # rakip becerisi 0..1
var _ben := 0.5        # senin becerin 0..1
var _ic: VBoxContainer
var _kutu: PanelContainer
var _bilgi: Label
var _durum: Label
var _para: Label
var _alan: VBoxContainer
# poker
var _deste: Array = []
var _el: Array = []
var _rel: Array = []
var _tut: Array = [false, false, false, false, false]
var _poker_faz := 0     # 0 dağıtılmadı, 1 seçim, 2 bitti
var _poker_bahis := 0
var _ihtimal_lbl: Label
# rulet
var _rulet_sec := {"tur": "renk", "deger": "kirmizi"}

func kur(o: Node, a: Node) -> void:
	oyun = o
	arayuz = a
	rng.randomize()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	theme = Tema.tema()
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	_kutu = PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.12, 0.08, 0.98)
	sb.border_color = Color(0.62, 0.48, 0.26)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(8)
	sb.set_content_margin_all(16)
	_kutu.add_theme_stylebox_override("panel", sb)
	_kutu.custom_minimum_size = Vector2(760, 560)
	_kutu.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_kutu.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_kutu.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(_kutu)
	_ic = VBoxContainer.new()
	_ic.add_theme_constant_override("separation", 8)
	_kutu.add_child(_ic)
	_rakip_sec()
	_ciz()

func _rakip_sec() -> void:
	_rakip_ad = RAKIPLER[rng.randi() % RAKIPLER.size()]
	_rakip = rng.randf_range(0.3, 0.8)
	var z: float = float(oyun.ozet.get("stat", {}).get("zeka", 5))
	var k: RefCounted = oyun.kis_k
	_ben = clampf(0.45 + 0.03 * (z - 5.0) + 0.25 * k.oz("kumarbaz") + 0.15 * k.oz("pazarlik") + 0.2 * oyun.yet_k.etki("sokak") + oyun.aile_k.etki("kumar_gelir"), 0.15, 0.9)

# Zar/poker kazanma ihtimali: beceri farkı + hafif ev payı.
func _p_kazan() -> float:
	return clampf(0.46 + (_ben - _rakip) * 0.4, 0.15, 0.78)

func _l(ebeveyn: Node, t: String, boy: int = 15, renk: Color = Tema.YAZI) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", boy)
	l.add_theme_color_override("font_color", renk)
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

func _ciz() -> void:
	for c in _ic.get_children():
		c.queue_free()
	var ust := HBoxContainer.new()
	_ic.add_child(ust)
	var bs := _l(ust, "KUMAR MASASI", 22, Tema.VURGU)
	bs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_para = _l(ust, "", 16, Tema.YAZI)
	_b(ust, "Kapat", kapat)
	var sek := HBoxContainer.new()
	_ic.add_child(sek)
	for g in [["zar", "Zar"], ["poker", "Poker"], ["rulet", "Rulet"]]:
		var id: String = g[0]
		var bt := _b(sek, g[1], func():
			_oyun_ad = id
			_ciz())
		bt.disabled = id == _oyun_ad
	_l(_ic, "Rakip: %s  ·  Senin becerin %%%d · Rakibin %%%d" % [_rakip_ad, int(_ben * 100.0), int(_rakip * 100.0)], 14, Tema.SOLUK)
	_bahis_satiri()
	_alan = VBoxContainer.new()
	_alan.add_theme_constant_override("separation", 8)
	_alan.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_ic.add_child(_alan)
	_durum = _l(_ic, "", 16, Tema.UYARI)
	match _oyun_ad:
		"zar": _zar_ciz()
		"poker": _poker_ciz()
		"rulet": _rulet_ciz()
	_para_yaz()

func _para_yaz() -> void:
	if _para != null:
		_para.text = "Kirli: %s · Temiz: %s" % [oyun.para(oyun.kirli), oyun.para(oyun.temiz)]

func _bahis_satiri() -> void:
	var h := HBoxContainer.new()
	_ic.add_child(h)
	_l(h, "Bahis:", 15)
	for b in BAHISLER:
		var v: int = b
		var bt := _b(h, "$%d" % v, func():
			_bahis = v
			_ciz())
		bt.disabled = v == _bahis or (_oyun_ad == "poker" and _poker_faz == 1)

func _ode(f: float) -> bool:
	if not oyun.harcama(f, "kirli"):
		_durum.text = "Kirli para yetmiyor (%s)." % oyun.para(f)
		return false
	return true

func _sonuc(net: float, metin: String) -> void:
	# net: bahise göre kazanç (bahis zaten düşüldü; kazançta geri verilen toplam eklenir)
	if net > 0.0:
		oyun.kirli += net
		if net - _bahis >= 200.0:
			oyun.kaz_k.ver("kumar_zengin")
		oyun.kayit("Kumar: %s (%s)" % [metin, oyun.para(net - _bahis)], "good")
	elif net == 0.0:
		oyun.kis["stres"] = minf(100.0, oyun.kis["stres"] + 1.5)
		oyun.kayit("Kumar: %s (−%s)" % [metin, oyun.para(_bahis)], "bad")
	oyun.bekle(10)
	oyun.degisti.emit()
	_para_yaz()

# ---------------------------------------------------------------- ZAR
func _zar_ciz() -> void:
	var p := _p_kazan()
	_l(_alan, "İkişer zar atılır, toplamı yüksek olan kazanır. Eşitlikte bahis iade.", 14, Tema.SOLUK)
	_l(_alan, "Kazanma ihtimalin: %%%d   ·   Kaybetme: %%%d   ·   Beraberlik: %%10" % [int(p * 90.0), int((1.0 - p) * 90.0)], 18, Tema.IYI if p >= 0.5 else Tema.UYARI)
	_l(_alan, "Kazanırsan bahsin 2 katını alırsın.", 13, Tema.SOLUK)
	_zar_alani = HBoxContainer.new()
	_zar_alani.alignment = BoxContainer.ALIGNMENT_CENTER
	_zar_alani.add_theme_constant_override("separation", 22)
	_alan.add_child(_zar_alani)
	_b(_alan, "Zarları at", _zar_at)

var _zar_alani: HBoxContainer

func _zar_kutu(ad: String, a: int, b: int) -> Control:
	var v := VBoxContainer.new()
	var t := _l(v, ad, 14, Tema.SOLUK)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var s := _l(v, "⚀⚁⚂⚃⚄⚅"[a - 1] + " " + "⚀⚁⚂⚃⚄⚅"[b - 1], 64, Tema.YAZI)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var top := _l(v, "Toplam: %d" % (a + b), 16, Tema.VURGU)
	top.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return v

func _zar_at() -> void:
	if not _ode(_bahis):
		return
	var p := _p_kazan()
	var r := rng.randf()
	var sonuc := 0   # 1 kazan, -1 kayıp, 0 beraber
	if r < 0.10:
		sonuc = 0
	elif r < 0.10 + p * 0.90:
		sonuc = 1
	else:
		sonuc = -1
	var a1 := 1
	var a2 := 1
	var b1 := 1
	var b2 := 1
	for _n in 100:
		a1 = rng.randi_range(1, 6)
		a2 = rng.randi_range(1, 6)
		b1 = rng.randi_range(1, 6)
		b2 = rng.randi_range(1, 6)
		var d := (a1 + a2) - (b1 + b2)
		if (sonuc == 1 and d > 0) or (sonuc == -1 and d < 0) or (sonuc == 0 and d == 0):
			break
	for c in _zar_alani.get_children():
		c.queue_free()
	_zar_alani.add_child(_zar_kutu("Sen", a1, a2))
	_zar_alani.add_child(_zar_kutu(_rakip_ad, b1, b2))
	match sonuc:
		1:
			_durum.text = "Kazandın! +%s" % oyun.para(_bahis)
			_sonuc(_bahis * 2.0, "zarda kazandın")
		-1:
			_durum.text = "Kaybettin: −%s" % oyun.para(_bahis)
			_sonuc(0.0, "zarda kaybettin")
		_:
			_durum.text = "Berabere, bahis iade."
			oyun.kirli += _bahis
			_para_yaz()

# ---------------------------------------------------------------- RULET
func _rulet_ciz() -> void:
	_l(_alan, "Avrupa ruleti: 0–36. Tamamen şans; kişisel özellik ya da rakip etkisi yok, ev avantajı 0 (yeşil) için %2,7.", 14, Tema.SOLUK)
	var sec := HBoxContainer.new()
	_alan.add_child(sec)
	var secenekler := [
		["Kırmızı", "renk", "kirmizi", 18], ["Siyah", "renk", "siyah", 18],
		["Tek", "tek", "tek", 18], ["Çift", "tek", "cift", 18],
		["1–18", "aralik", "alt", 18], ["19–36", "aralik", "ust", 18],
	]
	for s in secenekler:
		var sd: Array = s
		var bt := _b(sec, "%s (×2)" % sd[0], func():
			_rulet_sec = {"tur": sd[1], "deger": sd[2], "adet": sd[3], "ad": sd[0]}
			_ciz())
		bt.disabled = _rulet_sec.get("deger", "") == sd[2]
	var sn := HBoxContainer.new()
	_alan.add_child(sn)
	_l(sn, "Tek sayı (×36):", 14)
	var sp := SpinBox.new()
	sp.min_value = 0
	sp.max_value = 36
	sp.value = int(_rulet_sec["deger"]) if _rulet_sec["tur"] == "sayi" else 7
	sn.add_child(sp)
	_b(sn, "Sayıya yatır", func():
		_rulet_sec = {"tur": "sayi", "deger": int(sp.value), "adet": 1, "ad": "Sayı %d" % int(sp.value)}
		_ciz())
	var adet: int = int(_rulet_sec.get("adet", 18))
	if _rulet_sec["tur"] == "renk" and not _rulet_sec.has("ad"):
		_rulet_sec["ad"] = "Kırmızı"
	var ihtimal := float(adet) / 37.0
	_l(_alan, "Seçimin: %s  ·  Kazanma ihtimali: %%%.1f" % [_rulet_sec.get("ad", "Kırmızı"), ihtimal * 100.0], 18, Tema.IYI if adet == 18 else Tema.UYARI)
	_rulet_sonuc = _l(_alan, "🎡", 56, Tema.VURGU)
	_rulet_sonuc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_b(_alan, "Çarkı çevir", _rulet_cevir)

var _rulet_sonuc: Label

func _rulet_cevir() -> void:
	if not _ode(_bahis):
		return
	var n := rng.randi_range(0, 36)
	var kir := RENKLI.has(n)
	var rk := "yeşil" if n == 0 else ("kırmızı" if kir else "siyah")
	_rulet_sonuc.text = "%d  (%s)" % [n, rk]
	_rulet_sonuc.add_theme_color_override("font_color", Color("5fb45f") if n == 0 else (Color("d65a4a") if kir else Color("d8d2c4")))
	var kazandi := false
	var carpan := 2.0
	match _rulet_sec["tur"]:
		"renk":
			kazandi = n != 0 and ((_rulet_sec["deger"] == "kirmizi") == kir)
		"tek":
			kazandi = n != 0 and ((_rulet_sec["deger"] == "tek") == (n % 2 == 1))
		"aralik":
			kazandi = (n >= 1 and n <= 18) if _rulet_sec["deger"] == "alt" else (n >= 19)
		"sayi":
			kazandi = n == int(_rulet_sec["deger"])
			carpan = 36.0
	if kazandi:
		_durum.text = "%d geldi — kazandın! +%s" % [n, oyun.para(_bahis * (carpan - 1.0))]
		_sonuc(_bahis * carpan, "ruletta kazandın")
	else:
		_durum.text = "%d geldi — kaybettin: −%s" % [n, oyun.para(_bahis)]
		_sonuc(0.0, "ruletta kaybettin")

# ---------------------------------------------------------------- POKER
func _kart_yaz(k: int) -> String:
	return DEGER[k % 13] + TAKIM[k / 13]

func _karistir() -> void:
	_deste = range(52)
	_deste.shuffle()

func _el_puan(el: Array) -> int:
	var r: Array = []
	var takimlar := {}
	for k in el:
		r.append(int(k) % 13)
		takimlar[int(k) / 13] = true
	r.sort()
	var say := {}
	for x in r:
		say[x] = int(say.get(x, 0)) + 1
	var gr: Array = say.values()
	gr.sort()
	var renk: bool = takimlar.size() == 1
	var seri: bool = false
	if say.size() == 5:
		seri = r[4] - r[0] == 4 or r == [0, 1, 2, 3, 12]
	var kat := 0
	if seri and renk:
		kat = 8
	elif gr == [1, 4]:
		kat = 7
	elif gr == [2, 3]:
		kat = 6
	elif renk:
		kat = 5
	elif seri:
		kat = 4
	elif gr == [1, 1, 3]:
		kat = 3
	elif gr == [1, 2, 2]:
		kat = 2
	elif gr == [1, 1, 1, 2]:
		kat = 1
	# kâğıtları önce çok adetliye, sonra yükseğe göre sırala
	var sirali: Array = say.keys()
	sirali.sort_custom(func(a, b): return int(say[a]) > int(say[b]) or (int(say[a]) == int(say[b]) and a > b))
	var puan := kat
	for x in sirali:
		puan = puan * 13 + int(x)
	for _i in range(sirali.size(), 5):
		puan = puan * 13
	return puan

func _kat_bul(el: Array) -> int:
	var r: Array = []
	var takimlar := {}
	for k in el:
		r.append(int(k) % 13)
		takimlar[int(k) / 13] = true
	r.sort()
	var say := {}
	for x in r:
		say[x] = int(say.get(x, 0)) + 1
	var gr: Array = say.values()
	gr.sort()
	var renk: bool = takimlar.size() == 1
	var seri: bool = say.size() == 5 and (r[4] - r[0] == 4 or r == [0, 1, 2, 3, 12])
	if seri and renk:
		return 8
	if gr == [1, 4]:
		return 7
	if gr == [2, 3]:
		return 6
	if renk:
		return 5
	if seri:
		return 4
	if gr == [1, 1, 3]:
		return 3
	if gr == [1, 2, 2]:
		return 2
	if gr == [1, 1, 1, 2]:
		return 1
	return 0

# Değişimde becerili oyuncu, çektiği kâğıdın kötü olması halinde bazen bir kez daha çeker.
func _cek(deste: Array, beceri: float) -> int:
	var k: int = deste.pop_back()
	if rng.randf() < (beceri - 0.4) * 0.5 and deste.size() > 0:
		var k2: int = deste.pop_back()
		if k2 % 13 > k % 13:
			return k2
	return k

# Rakip yapay zekâsı: beceriye göre çiftleri/yüksekleri tutar, bazen hata yapar.
func _rakip_degis(el: Array, deste: Array) -> Array:
	var yeni: Array = el.duplicate()
	var say := {}
	for k in yeni:
		say[int(k) % 13] = int(say.get(int(k) % 13, 0)) + 1
	for i in 5:
		var k: int = yeni[i]
		var tut: bool = int(say[k % 13]) >= 2 or k % 13 >= 10
		if _kat_bul(yeni) >= 4:
			tut = true
		if rng.randf() > _rakip + 0.25:
			tut = not tut   # hata
		if not tut and deste.size() > 0:
			yeni[i] = _cek(deste, _rakip)
	return yeni

func _poker_ciz() -> void:
	_l(_alan, "5 kâğıt: tutmak istediklerine tıkla, sonra değiştir. Elin yüksek olan kazanır (iki katı ödenir, beraberlikte iade).", 14, Tema.SOLUK)
	_kartlar_kutu = HBoxContainer.new()
	_kartlar_kutu.alignment = BoxContainer.ALIGNMENT_CENTER
	_kartlar_kutu.add_theme_constant_override("separation", 10)
	_alan.add_child(_kartlar_kutu)
	_ihtimal_lbl = _l(_alan, "", 18, Tema.IYI)
	_ihtimal_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rakip_kutu = HBoxContainer.new()
	_rakip_kutu.alignment = BoxContainer.ALIGNMENT_CENTER
	_rakip_kutu.add_theme_constant_override("separation", 10)
	_alan.add_child(_rakip_kutu)
	var dg := HBoxContainer.new()
	dg.alignment = BoxContainer.ALIGNMENT_CENTER
	_alan.add_child(dg)
	if _poker_faz == 1:
		_b(dg, "Değiştir ve aç", _poker_ac)
	else:
		_b(dg, "Dağıt (bahis %s)" % oyun.para(_bahis), _poker_dagit)
	_poker_kartlari_ciz()

var _kartlar_kutu: HBoxContainer
var _rakip_kutu: HBoxContainer

func _kart_dugme(ebeveyn: Node, metin: String, secili: bool, f: Callable, kapali: bool) -> void:
	var b := Button.new()
	b.text = metin
	b.focus_mode = Control.FOCUS_NONE
	b.custom_minimum_size = Vector2(86, 120)
	b.add_theme_font_size_override("font_size", 28)
	var kirmizi := metin.contains("♥") or metin.contains("♦")
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("efe4c6") if not secili else Color("f7e9a8")
	sb.border_color = Color("c9a227") if secili else Color("14110d")
	sb.set_border_width_all(4 if secili else 2)
	sb.set_corner_radius_all(8)
	for st in ["normal", "hover", "pressed", "disabled"]:
		b.add_theme_stylebox_override(st, sb)
	var rk := Color("b3261e") if kirmizi else Color("14110d")
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, rk)
	b.disabled = kapali
	b.pressed.connect(f)
	ebeveyn.add_child(b)

func _poker_kartlari_ciz() -> void:
	for c in _kartlar_kutu.get_children():
		c.queue_free()
	for c in _rakip_kutu.get_children():
		c.queue_free()
	if _poker_faz == 0 and _el.is_empty():
		_ihtimal_lbl.text = "Kâğıtlar henüz dağıtılmadı."
		return
	for i in _el.size():
		var ix: int = i
		_kart_dugme(_kartlar_kutu, _kart_yaz(_el[i]) + ("\nTUT" if _poker_faz == 1 and _tut[i] else ""), _poker_faz == 1 and _tut[i], func():
			_tut[ix] = not _tut[ix]
			_poker_kartlari_ciz(), _poker_faz != 1)
	if _poker_faz == 1:
		var p := _poker_tahmin()
		_ihtimal_lbl.text = "Mevcut seçimle tahmini kazanma ihtimalin: %%%d  (şu an: %s)" % [int(p * 100.0), EL_AD[_kat_bul(_el)]]
	elif _poker_faz == 2:
		for k in _rel:
			_kart_dugme(_rakip_kutu, _kart_yaz(k), false, func(): pass, true)

func _poker_tahmin() -> float:
	var kazan := 0.0
	var N := 220
	for _n in N:
		var d: Array = range(52)
		for k in _el:
			d.erase(k)
		d.shuffle()
		var rel: Array = []
		for _i in 5:
			rel.append(d.pop_back())
		rel = _rakip_degis(rel, d)
		var ben: Array = _el.duplicate()
		for i in 5:
			if not _tut[i]:
				ben[i] = _cek(d, _ben)
		var a := _el_puan(ben)
		var b := _el_puan(rel)
		if a > b:
			kazan += 1.0
		elif a == b:
			kazan += 0.5
	return kazan / float(N)

func _poker_dagit() -> void:
	if not _ode(_bahis):
		return
	_poker_bahis = _bahis
	_karistir()
	_el = []
	_rel = []
	for _i in 5:
		_el.append(_deste.pop_back())
	for _i in 5:
		_rel.append(_deste.pop_back())
	_tut = [false, false, false, false, false]
	_poker_faz = 1
	_durum.text = ""
	_ciz()

func _poker_ac() -> void:
	for i in 5:
		if not _tut[i]:
			_el[i] = _cek(_deste, _ben)
	_rel = _rakip_degis(_rel, _deste)
	_poker_faz = 2
	var a := _el_puan(_el)
	var b := _el_puan(_rel)
	var bs: float = float(_poker_bahis)
	var eski := _bahis
	_bahis = _poker_bahis
	if a > b:
		_durum.text = "Sen: %s  —  %s: %s.  Kazandın! +%s" % [EL_AD[_kat_bul(_el)], _rakip_ad, EL_AD[_kat_bul(_rel)], oyun.para(bs)]
		_sonuc(bs * 2.0, "pokerde kazandın")
	elif a == b:
		_durum.text = "Berabere, bahis iade."
		oyun.kirli += bs
		_para_yaz()
	else:
		_durum.text = "Sen: %s  —  %s: %s.  Kaybettin: −%s" % [EL_AD[_kat_bul(_el)], _rakip_ad, EL_AD[_kat_bul(_rel)], oyun.para(bs)]
		_sonuc(0.0, "pokerde kaybettin")
	_bahis = eski
	_poker_faz = 2
	# durum yazısını _ciz() silmesin diye sadece el alanını güncelle
	var m := _durum.text
	_ciz_koru(m)

func _ciz_koru(m: String) -> void:
	_ciz()
	_durum.text = m

func kapat() -> void:
	arayuz.kumar_kapandi()
	queue_free()
