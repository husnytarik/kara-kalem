extends RefCounted
# Haritadaki insan figürü: ince silindir gövde + küre kafa. Çıktı: ayak y=0, boy ~1.8.
# Dönen düğümün ilk çocuğu "salinim" tutucusudur (yürüme sıçraması için).
static func kisi(renk: Color, ten: Color = Color("c9a083")) -> Node3D:
	var n := Node3D.new()
	var tut := Node3D.new()
	n.add_child(tut)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = renk
	gm.roughness = 0.9
	var tm := StandardMaterial3D.new()
	tm.albedo_color = ten
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.1
	cyl.bottom_radius = 0.13
	cyl.height = 1.4
	cyl.radial_segments = 10
	cyl.material = gm
	var b := MeshInstance3D.new()
	b.mesh = cyl
	b.position.y = 0.7
	tut.add_child(b)
	var sp := SphereMesh.new()
	sp.radius = 0.17
	sp.height = 0.34
	sp.radial_segments = 12
	sp.rings = 6
	sp.material = tm
	var k := MeshInstance3D.new()
	k.mesh = sp
	k.position.y = 1.58
	tut.add_child(k)
	return n
