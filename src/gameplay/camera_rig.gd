extends Node3D
## 固定斜 45 度相机，跟随、震屏，并支持双指缩放 / 滚轮缩放。

@export var target_path: NodePath
@export var follow_speed: float = 10.0

var _target: Node3D
var _camera: Camera3D
var _camera_base: Vector3 = Vector3.ZERO
var _shake: float = 0.0
var _zoom: float = 1.0
var _base_size: float = 9.0
var _touches: Dictionary = {}
const ZOOM_MIN := 0.55
const ZOOM_MAX := 2.2


func _ready() -> void:
	if not target_path.is_empty():
		_target = get_node_or_null(target_path) as Node3D
	if _target == null:
		_target = get_tree().get_first_node_in_group("player") as Node3D
	if _target:
		global_position = _target.global_position
	_camera = get_node_or_null("Camera3D") as Camera3D
	if _camera:
		_camera_base = _camera.position
		_base_size = _camera.size
	Events.camera_shake.connect(_on_shake)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			_touches[event.index] = event.position
		else:
			_touches.erase(event.index)
	elif event is InputEventScreenDrag and _touches.has(event.index):
		var previous := _two_finger_distance()
		_touches[event.index] = event.position
		if _touches.size() >= 2:
			var current := _two_finger_distance()
			if previous > 8.0 and current > 8.0:
				_zoom = clampf(_zoom * (previous / current), ZOOM_MIN, ZOOM_MAX)
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom = clampf(_zoom * 0.9, ZOOM_MIN, ZOOM_MAX)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom = clampf(_zoom / 0.9, ZOOM_MIN, ZOOM_MAX)


func _two_finger_distance() -> float:
	var positions := _touches.values()
	if positions.size() < 2:
		return 0.0
	return (positions[0] as Vector2).distance_to(positions[1] as Vector2)


func _process(delta: float) -> void:
	if _target and is_instance_valid(_target):
		var weight := clampf(follow_speed * delta, 0.0, 1.0)
		global_position = global_position.lerp(_target.global_position, weight)

	if _camera == null:
		return
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 1.6)
		var offset := Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), 0.0) * _shake
		_camera.position = _camera_base * _zoom + offset
	else:
		_camera.position = _camera_base * _zoom
	if _camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
		_camera.size = _base_size * _zoom


func _on_shake(strength: float) -> void:
	_shake = maxf(_shake, strength)

