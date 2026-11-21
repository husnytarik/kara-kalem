extends Control
# Panelin altındaki şehir silueti (gazete şablonu): mürekkep tonunda, yukarı doğru solan gökdelenler.

const MUREKKEP := Color(0.26, 0.16, 0.08)

func _init() -> void:
	custom_minimum_size = Vector2(0, 64)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var rnd := RandomNumberGenerator.new()
	rnd.seed = 1923
	var w := size.x
	var h := size.y
	var x := 0.0
	while x < w:
		var bw := rnd.randf_range(10.0, 26.0)
		var bh := rnd.randf_range(0.25, 0.7) * h
		if rnd.randf() < 0.12:
			bh = rnd.randf_range(0.8, 0.98) * h   # ara sıra yüksek kule
		_bina(x, h, minf(bw, w - x), bh)
		x += bw + rnd.randf_range(0.0, 3.0)

func _bina(x: float, taban: float, bw: float, bh: float) -> void:
	var ust := Color(MUREKKEP.r, MUREKKEP.g, MUREKKEP.b, 0.10)
	var alt := Color(MUREKKEP.r, MUREKKEP.g, MUREKKEP.b, 0.34)
	var y0 := taban - bh
	draw_polygon(PackedVector2Array([Vector2(x, y0), Vector2(x + bw, y0), Vector2(x + bw, taban), Vector2(x, taban)]), PackedColorArray([ust, ust, alt, alt]))
	if bh > size.y * 0.75:   # kule: sivri tepe
		var m := x + bw * 0.5
		draw_polygon(PackedVector2Array([Vector2(m - bw * 0.25, y0), Vector2(m + bw * 0.25, y0), Vector2(m, y0 - 10.0)]), PackedColorArray([ust, ust, ust]))
