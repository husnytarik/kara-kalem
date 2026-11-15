extends Node3D
# Mount & Blade tarzı harita kamerası: yukarıdan, karakteri takip eder.
# Sağ tık sürükle: döndür/eğ · Tekerlek: yakınlaş · WASD/ok: kaydır · C: karakteri ortala

var hedef: Node3D
var mesafe := 110.0
var _pitch := -1.0
var _kayma := Vector3.ZERO
var _kam: Camera3D
var _son := 0

func _ready() -> void:
	top_level = true
	_kam = Camera3D.new()
	_kam.current = true
	_kam.far = 3000.0
	add_child(_kam)
	_son = Time.get_ticks_usec()

func kamera() -> Camera3D:
	return _kam

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and (e.button_mask & MOUSE_BUTTON_MASK_RIGHT):
		rotation.y -= e.relative.x * 0.005
		_pitch = clampf(_pitch - e.relative.y * 0.004, -1.5, -0.35)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			mesafe = maxf(25.0, mesafe * 0.9)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			mesafe = minf(380.0, mesafe * 1.1)
	elif e is InputEventKey and e.pressed and e.keycode == KEY_C:
		_kayma = Vector3.ZERO

func _process(_d: float) -> void:
	var simdi := Time.get_ticks_usec()
	var dt := float(simdi - _son) / 1000000.0   # gerçek süre: oyun duraklasa da kamera çalışır
	_son = simdi
	var g := Vector3.ZERO
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP): g.z -= 1
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN): g.z += 1
	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT): g.x -= 1
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT): g.x += 1
	if g != Vector3.ZERO:
		_kayma += g.normalized().rotated(Vector3.UP, rotation.y) * mesafe * 0.9 * dt
		_kayma = _kayma.limit_length(400.0)
	if hedef:
		global_position = hedef.global_position + _kayma
	_kam.position = Vector3(0, 0, mesafe).rotated(Vector3.RIGHT, _pitch)
	_kam.rotation.x = _pitch
