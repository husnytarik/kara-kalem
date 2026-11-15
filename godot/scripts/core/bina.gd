@tool
extends Node3D
# Haritadaki bir bina. Şimdilik küp; ileride "Model" adında bir alt düğüm eklersen
# (kendi 3D modelin) küp gizlenir. Değerleri Inspector'dan değiştirebilirsin.
# Konum (position) binanın TABAN ORTASIDIR.

static var _mats := {}

@export var ad := "":
	set(v):
		ad = v
		_yenile()
@export var bolge := ""
@export var ozel := false:
	set(v):
		ozel = v
		_yenile()
@export var boyut := Vector3(12.0, 10.0, 12.0):   # genişlik, yükseklik, derinlik
	set(v):
		boyut = v
		_yenile()
@export var renk := Color(0.5, 0.4, 0.3):
	set(v):
		renk = v
		_yenile()

var _kutu: MeshInstance3D
var _govde: StaticBody3D
var _etiket: Label3D

func _ready() -> void:
	add_to_group("bina")
	_yenile()

func _yenile() -> void:
	if not is_inside_tree():
		return
	if get_node_or_null("Model") == null:
		if _kutu == null:
			_kutu = MeshInstance3D.new()
			_kutu.mesh = BoxMesh.new()
			add_child(_kutu)
		(_kutu.mesh as BoxMesh).size = boyut
		_kutu.position = Vector3(0, boyut.y / 2.0, 0)
		_kutu.material_override = _malzeme(renk)
	elif _kutu != null:
		_kutu.queue_free()
		_kutu = null
	if not Engine.is_editor_hint():
		if _govde == null:
			_govde = StaticBody3D.new()
			var cs := CollisionShape3D.new()
			cs.shape = BoxShape3D.new()
			_govde.add_child(cs)
			add_child(_govde)
		((_govde.get_child(0) as CollisionShape3D).shape as BoxShape3D).size = boyut
		_govde.position = Vector3(0, boyut.y / 2.0, 0)
	if _etiket == null:
		_etiket = Label3D.new()
		_etiket.font_size = 40
		_etiket.pixel_size = 0.03
		_etiket.outline_size = 10
		_etiket.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_etiket.no_depth_test = true
		_etiket.visibility_range_end = 220.0
		add_child(_etiket)
	_etiket.text = ad
	_etiket.modulate = Color(1.0, 0.85, 0.4) if ozel else Color(0.95, 0.95, 0.95)
	_etiket.position = Vector3(0, boyut.y + 3.0, 0)

func _malzeme(c: Color) -> StandardMaterial3D:
	var k := c.to_html()
	if not _mats.has(k):
		var m := StandardMaterial3D.new()
		m.albedo_color = c
		m.roughness = 0.9
		_mats[k] = m
	return _mats[k]

# Dünya koordinatlarında kutu (yön döndürülmüşse onu kapsar).
func dunya_aabb() -> AABB:
	var t := global_transform
	var yari := Vector3(boyut.x / 2.0, 0, boyut.z / 2.0)
	var a := AABB(t * Vector3(-yari.x, 0, -yari.z), Vector3.ZERO)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			for y in [0.0, boyut.y]:
				a = a.expand(t * Vector3(sx * yari.x, y, sz * yari.z))
	return a
