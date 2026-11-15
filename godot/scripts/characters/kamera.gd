extends Node3D
# Üçüncü şahıs kamera. Fare: bak · Esc: fareyi bırak/yakala · Tekerlek: yakınlık.

var hedef: Node3D
var mesafe := 4.5
var _pitch := -0.25
const HASSASIYET := 0.003
var _kam: Camera3D

func _ready() -> void:
	top_level = true
	_kam = Camera3D.new()
	_kam.current = true
	add_child(_kam)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= e.relative.x * HASSASIYET
		_pitch = clamp(_pitch - e.relative.y * HASSASIYET, -1.2, 0.5)
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP: mesafe = max(2.0, mesafe - 0.4)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN: mesafe = min(10.0, mesafe + 0.4)
		elif Input.mouse_mode != Input.MOUSE_MODE_CAPTURED: Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif e is InputEventKey and e.pressed and e.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED

func _process(_d: float) -> void:
	if not hedef:
		return
	global_position = hedef.global_position + Vector3(0, 1.5, 0)
	_kam.position = Vector3(0, 0, mesafe).rotated(Vector3.RIGHT, _pitch)
	_kam.rotation.x = _pitch
