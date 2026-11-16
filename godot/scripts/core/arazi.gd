@tool
extends Node3D
# Arazi: yükseklik haritasından (gri tonlamalı PNG) üretilir.
# Siyah = en alçak (min_h), beyaz = en yüksek (max_h). PNG'yi herhangi bir resim
# programında boyayıp kaydet, oyunu yeniden çalıştır. Renk PNG'si (renk_yolu) zemin rengini verir
# (koyu gri = asfalt/yol, yeşil = çim, bej = kum).
# Inspector'da "yenile" kutusuna tıklarsan editörde de güncellenir.

@export_file("*.png") var yukseklik_yolu := "res://assets/environment/terrain/yukseklik.png"
@export_file("*.png") var renk_yolu := "res://assets/environment/terrain/renk.png"
@export var x0 := -182.0           # arazinin sol-üst köşesi (metre)
@export var z0 := -258.0
@export var genislik := 364.0
@export var derinlik := 594.0
@export var min_h := -6.0
@export var max_h := 40.0
@export var adim := 3.0            # mesh ızgara aralığı (metre)
@export var yenile := false:
	set(v):
		yenile = false
		if is_inside_tree():
			_kur()

var _y: Image
var _r: Image
var _mi: MeshInstance3D
var _govde: StaticBody3D

func _ready() -> void:
	_kur()

func yuk(x: float, z: float) -> float:
	if _y == null:
		return 0.0
	var w := _y.get_width()
	var h := _y.get_height()
	var u := clampf((x - x0) / genislik * (w - 1), 0.0, w - 1.001)
	var v := clampf((z - z0) / derinlik * (h - 1), 0.0, h - 1.001)
	var i := int(u)
	var j := int(v)
	var fu := u - i
	var fv := v - j
	var a := lerpf(_y.get_pixel(i, j).r, _y.get_pixel(i + 1, j).r, fu)
	var b := lerpf(_y.get_pixel(i, j + 1).r, _y.get_pixel(i + 1, j + 1).r, fu)
	return lerpf(min_h, max_h, lerpf(a, b, fv))

func _renk(x: float, z: float) -> Color:
	if _r == null:
		return Color(0.14, 0.14, 0.15)
	var i := clampi(int((x - x0) / genislik * (_r.get_width() - 1) + 0.5), 0, _r.get_width() - 1)
	var j := clampi(int((z - z0) / derinlik * (_r.get_height() - 1) + 0.5), 0, _r.get_height() - 1)
	return _r.get_pixel(i, j)

func _kur() -> void:
	if _mi != null:
		_mi.queue_free()
		_mi = null
	if _govde != null:
		_govde.queue_free()
		_govde = null
	_y = Image.load_from_file(yukseklik_yolu)
	_r = Image.load_from_file(renk_yolu)
	if _y == null:
		push_warning("Yükseklik haritası okunamadı: " + yukseklik_yolu)
		return
	var nx := int(genislik / adim) + 1
	var nz := int(derinlik / adim) + 1
	var sx := genislik / (nx - 1)
	var sz := derinlik / (nz - 1)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var e := 1.5
	for j in nz:
		for i in nx:
			var x := x0 + i * sx
			var z := z0 + j * sz
			var n := Vector3(yuk(x - e, z) - yuk(x + e, z), 2.0 * e, yuk(x, z - e) - yuk(x, z + e)).normalized()
			st.set_uv(Vector2((x - x0) / genislik, (z - z0) / derinlik))
			st.set_normal(n)
			st.add_vertex(Vector3(x, yuk(x, z), z))
	for j in nz - 1:
		for i in nx - 1:
			var a := j * nx + i
			var b := a + 1
			var c := a + nx
			var d := c + 1
			st.add_index(a); st.add_index(b); st.add_index(c)
			st.add_index(b); st.add_index(d); st.add_index(c)
	var mesh := st.commit()
	var mat := StandardMaterial3D.new()
	if _r != null:
		_r.generate_mipmaps()
		mat.albedo_texture = ImageTexture.create_from_image(_r)
		mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	else:
		mat.albedo_color = Color(0.14, 0.14, 0.15)
	mat.roughness = 1.0
	mesh.surface_set_material(0, mat)
	_mi = MeshInstance3D.new()
	_mi.mesh = mesh
	add_child(_mi)
	if not Engine.is_editor_hint():
		_govde = StaticBody3D.new()
		var cs := CollisionShape3D.new()
		cs.shape = mesh.create_trimesh_shape()
		_govde.add_child(cs)
		add_child(_govde)
