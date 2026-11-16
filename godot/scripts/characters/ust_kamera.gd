extends Node3D
# Mount & Blade tarzı harita kamerası: yukarıdan, karakteri takip eder.
# Sağ tık sürükle: döndür/eğ · Tekerlek: yakınlaş · WASD/ok: kaydır · C: karakteri ortala

const MAKS_MESAFE := 300.0   # en uzak yakınlaşma (eskiden 800)

var hedef: Node3D
var mesafe := 110.0
var _pitch := -1.0
var _kayma := Vector3.ZERO
var _kam: Camera3D
var _son := 0
var _poz := Vector3.ZERO      # yumuşatılmış kamera odağı
var _poz_hazir := false
var _mes := 110.0             # yumuşatılmış mesafe

func _ready() -> void:
	top_level = true
	_kam = Camera3D.new()
	_kam.current = true
	_kam.far = 900.0
	_kam.fov = 55.0
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
			mesafe = minf(MAKS_MESAFE, mesafe * 1.1)
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
		var amac := hedef.global_position + _kayma
		if not _poz_hazir or _poz.distance_to(amac) > 300.0:   # ilk kare / ışınlanma: atlama
			_poz = amac
			_mes = mesafe
			_poz_hazir = true
		_poz = _poz.lerp(amac, 1.0 - exp(-5.0 * dt))      # kare hızından bağımsız yumuşak takip
		_mes = lerpf(_mes, mesafe, 1.0 - exp(-10.0 * dt))
		global_position = _poz
	_kam.position = Vector3(0, 0, _mes).rotated(Vector3.RIGHT, _pitch)
	_kam.rotation.x = _pitch
