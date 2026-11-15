extends CharacterBody3D
# WASD: yürü · Shift: koş · Ctrl: çömel. Hareket kameranın baktığı yöne göre.

const YURU := 3.5
const KOS := 6.5
const COMEL := 1.8
var kamera: Node3D
var _govde: Node3D

func _ready() -> void:
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.8
	cs.shape = cap
	add_child(cs)
	# Geçici görünüm: kapsül + yüzün baktığı yönü gösteren küçük kutu (-Z ileri).
	_govde = Node3D.new()
	add_child(_govde)
	var m := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = 0.35
	cm.height = 1.8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	cm.material = mat
	m.mesh = cm
	_govde.add_child(m)
	var burun := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.2, 0.2, 0.3)
	burun.mesh = bm
	burun.position = Vector3(0, 0.5, -0.4)
	_govde.add_child(burun)

func _physics_process(delta: float) -> void:
	var gir := Vector2.ZERO
	if Input.is_physical_key_pressed(KEY_W): gir.y -= 1
	if Input.is_physical_key_pressed(KEY_S): gir.y += 1
	if Input.is_physical_key_pressed(KEY_A): gir.x -= 1
	if Input.is_physical_key_pressed(KEY_D): gir.x += 1
	var hiz := YURU
	if Input.is_physical_key_pressed(KEY_SHIFT): hiz = KOS
	if Input.is_physical_key_pressed(KEY_CTRL): hiz = COMEL
	var yaw := kamera.rotation.y if kamera else 0.0
	var yon := Vector3(gir.x, 0, gir.y).normalized().rotated(Vector3.UP, yaw)
	velocity.x = yon.x * hiz
	velocity.z = yon.z * hiz
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = 0.0
	move_and_slide()
	if yon.length() > 0.1:
		var hedef_aci := atan2(-yon.x, -yon.z)
		_govde.rotation.y = lerp_angle(_govde.rotation.y, hedef_aci, 12.0 * delta)
	_govde.scale.y = lerp(_govde.scale.y, 0.7 if hiz == COMEL else 1.0, 10.0 * delta)
