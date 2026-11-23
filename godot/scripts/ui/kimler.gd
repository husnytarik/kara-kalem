extends RefCounted
const Tema := preload("res://scripts/ui/tema.gd")
# Bina içi "Kimler var": özel kişiler (koruyucu, başka mafyanın haraççısı, polis, rakip ekip) belirgin kartlarda,
# diğer herkes yatay kaydırmalı portre şeridinde. Portre sanatı yok: prosedürel siluet (assets/ui/portre/<ad>.png varsa o kullanılır).

class Portre extends Control:
	var renk: Color = Color(0.5, 0.5, 0.5)
	var tex: Texture2D
	func _draw() -> void:
		var s: Vector2 = size
		draw_rect(Rect2(Vector2.ZERO, s), renk.darkened(0.55))
		if tex != null:
			draw_texture_rect(tex, Rect2(Vector2.ZERO, s), false)
			return
		draw_circle(Vector2(s.x * 0.5, s.y * 0.38), s.x * 0.2, renk.lightened(0.25))
		draw_circle(Vector2(s.x * 0.5, s.y * 1.02), s.x * 0.42, renk)

static func _portre(ad: String, renk: Color, boyut: float) -> Control:
	var p := Portre.new()
	p.renk = renk
	p.clip_contents = true
	var yol := "res://assets/ui/portre/%s.png" % ad
	if ResourceLoader.exists(yol):
		p.tex = load(yol)
	p.custom_minimum_size = Vector2(boyut, boyut)
	return p

static func _renk_of(ad: String) -> Color:
	var h: int = absi(hash(ad))
	return Color.from_hsv(float(h % 360) / 360.0, 0.35, 0.62)

static func _kart(ebeveyn: Node, ad: String, alt: String, renk: Color, kenar: Color, ozel: bool, ui: Node) -> void:
	var pc := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(kenar.r, kenar.g, kenar.b, 0.22 if ozel else 0.08)
	sb.border_color = kenar
	sb.set_border_width_all(2 if ozel else 1)
	if ozel:
		sb.border_width_left = 6
	sb.set_corner_radius_all(4)
	sb.set_content_margin_all(6)
	pc.add_theme_stylebox_override("panel", sb)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 2)
	pc.add_child(v)
	var pr := _portre(ad, renk, 64.0 if not ozel else 48.0)
	if ozel:
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 8)
		v.add_child(h)
		h.add_child(pr)
		var vv := VBoxContainer.new()
		vv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(vv)
		var la: Label = ui._lbl(vv, ad, 15, kenar)
		la.custom_minimum_size = Vector2(120, 0)
		var lb: Label = ui._lbl(vv, alt, 13, Tema.SOLUK)
		lb.custom_minimum_size = Vector2(120, 0)
		pc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		pr.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		v.add_child(pr)
		var l1: Label = ui._lbl(v, ad, 12, Tema.YAZI)
		l1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l1.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l1.custom_minimum_size = Vector2(84, 0)
		var l2: Label = ui._lbl(v, alt, 11, Tema.SOLUK)
		l2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l2.custom_minimum_size = Vector2(84, 0)
	ebeveyn.add_child(pc)

# i: bina; ui: arayuz.gd (yardımcı fonksiyonlar), oyun/sokak düğümleri.
static func kur(ui: Node, oyun: Node, sokak: Node, i: int) -> void:
	var ic: Node = ui._ic
	var iceride: bool = sokak.oyuncu.iceride == i
	if not (iceride or sokak.gorus.bina_gorunur(i)):
		return
	var y: Dictionary = oyun.harita.yerler[i]
	var r: Dictionary = oyun.isy.get(i, {})
	var ozel: Array = []   # [ad, alt, renk]
	var sivil: Array = []
	# koruyucu: görevli adamın veya satın alınan koruma
	for g in oyun.gorevler:
		if g["hedef"] == i and g["gorev"] == "koru":
			var a: Dictionary = oyun.adam_bul(g["adam"])
			if not a.is_empty():
				ozel.append([a["ad"], "Koruyucun · kapıda nöbet", Tema.IYI])
	if r.get("korumaBitis", 0) > oyun.t and r.get("sahip", false) == false and r.get("haracli", false):
		ozel.append(["Adamların", "Koruma altında (%d gün)" % int((r["korumaBitis"] - oyun.t) / oyun.DAY), Tema.IYI])
	# başka mafyanın haraççısı
	var k: String = oyun.kontrol(i)
	if k != "" and k != "sahip" and k != "haraci" and oyun.FAK.has(k) and k != "oyuncu" and not r.is_empty():
		var u: Array = oyun.aile_uyeleri(k)
		var ad: String = String(u[u.size() - 1]["ad"]) if not u.is_empty() else "Haraççı"
		ozel.append([ad, "%s için koruma parası alıyor" % oyun.FAK[k]["ad"], oyun.FAK[k]["renk"]])
	# haritadaki gruplar
	var ab: AABB = (oyun.harita.yerler[i]["aabb"] as AABB).grow(sokak.gorus.IN_MESAFE)
	for g in sokak.gruplar.liste:
		var p: Vector3 = g["pos"]
		if g["tur"] == "sivil" or not ab.has_point(Vector3(p.x, ab.position.y + ab.size.y * 0.5, p.z)):
			continue
		if g["tur"] == "polis":
			ozel.append(["Polis devriyesi", "%d memur" % g["kisi"], Color("5f8fc4")])
		else:
			ozel.append([g["ad"], "%s · %d silahlı" % [oyun.FAK[g["fak"]]["ad"], g["kisi"]], oyun.FAK[g["fak"]]["renk"]])
	# personel
	for pk in r.get("personel", []):
		sivil.append([pk["ad"], str(pk.get("rol", "Çalışan"))])
	# isimli sakinler
	for g in sokak.gruplar.liste:
		if g.has("sakin") and str(g.get("sakin_durum", "")).begins_with("Şurada: "):
			var bn: String = str(g["sakin_durum"]).substr(8)
			if String(y["ad"]).begins_with(bn):
				sivil.append([g["ad"], g["sakin"]["is"]])
	# müşteri/ziyaretçi sayısı kadar adsız yüz
	var n: Dictionary = sokak.gorus.nufus(i)
	var adsiz: int = mini(int(n["musteri"]), 8)
	for j in adsiz:
		sivil.append(["Müşteri", "ziyaretçi"])
	ui._ayrac(ic)
	ui._bolum(ic, "Kimler var")
	for o in ozel:
		_kart(ic, o[0], o[1], o[2], o[2], true, ui)
	if sivil.is_empty():
		if ozel.is_empty():
			ui._lbl(ic, "Şu an kimse görünmüyor.", 14, Tema.SOLUK)
		return
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 132)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ic.add_child(sc)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)
	sc.add_child(hb)
	for s in sivil:
		_kart(hb, s[0], s[1], _renk_of(s[0]), Tema.KENAR, false, ui)
