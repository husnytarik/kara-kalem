extends Control
# Kod ile çizilen silüet portre (fötr şapkalı adam). Resim gelene kadar yer tutar; renk ile çeşitlenir.

var renk := Color("6b5a43")
var kadin := false

func _init() -> void:
	custom_minimum_size = Vector2(56, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(0, 0, w, h), Color(0.07, 0.05, 0.035))
	draw_rect(Rect2(0, 0, w, h), Color(0.4, 0.29, 0.15), false, 2.0)
	var ten := renk.lerp(Color("c9a679"), 0.6)
	var palto := renk.darkened(0.35)
	# omuzlar
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.08, h), Vector2(w * 0.16, h * 0.78), Vector2(w * 0.38, h * 0.68), Vector2(w * 0.62, h * 0.68), Vector2(w * 0.84, h * 0.78), Vector2(w * 0.92, h)]), palto)
	# gömlek/kravat
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.42, h * 0.68), Vector2(w * 0.58, h * 0.68), Vector2(w * 0.5, h * 0.9)]), Color("d9d0bd"))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.47, h * 0.72), Vector2(w * 0.53, h * 0.72), Vector2(w * 0.52, h * 0.88), Vector2(w * 0.48, h * 0.88)]), Color("7a1f1a"))
	# yüz
	draw_circle(Vector2(w * 0.5, h * 0.46), w * 0.2, ten)
	# şapka
	draw_rect(Rect2(w * 0.2, h * 0.33, w * 0.6, h * 0.06), Color(0.09, 0.07, 0.06))
	draw_colored_polygon(PackedVector2Array([Vector2(w * 0.3, h * 0.34), Vector2(w * 0.34, h * 0.14), Vector2(w * 0.66, h * 0.14), Vector2(w * 0.7, h * 0.34)]), Color(0.12, 0.09, 0.07))
	draw_rect(Rect2(w * 0.32, h * 0.28, w * 0.36, h * 0.035), Color("8b2e22"))
