class_name TouchStick
extends Control
## 触屏摇杆，鼠标也能拖，方便桌面调试。

signal moved(direction: Vector2)

@export var knob_radius: float = 34.0

var _touch_index: int = -1
var _active: bool = false
var _knob_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	custom_minimum_size = Vector2(200, 200)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return

	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch_index == -1 and get_global_rect().has_point(touch.position):
			_touch_index = touch.index
			_active = true
			_update_from_viewport(touch.position)
		elif not touch.pressed and touch.index == _touch_index:
			_release()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch_index:
			_update_from_viewport(drag.position)
	elif event is InputEventMouseButton:
		var button := event as InputEventMouseButton
		if button.button_index == MOUSE_BUTTON_LEFT:
			if button.pressed and _touch_index == -1 and get_global_rect().has_point(button.position):
				_touch_index = 0
				_active = true
				_update_from_viewport(button.position)
			elif not button.pressed and _touch_index == 0:
				_release()
	elif event is InputEventMouseMotion and _active:
		_update_from_viewport((event as InputEventMouseMotion).position)


func _update_from_viewport(viewport_position: Vector2) -> void:
	var center := size * 0.5
	var local := viewport_position - global_position
	var offset := local - center
	var limit := minf(size.x, size.y) * 0.5 - knob_radius * 0.8
	if offset.length() > limit:
		offset = offset.normalized() * limit
	_knob_offset = offset
	var direction := offset / maxf(limit, 1.0)
	moved.emit(direction)
	queue_redraw()


func _release() -> void:
	_touch_index = -1
	_active = false
	_knob_offset = Vector2.ZERO
	moved.emit(Vector2.ZERO)
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.5 - 4.0
	draw_circle(center, radius, Color(0.08, 0.08, 0.10, 0.55))
	draw_arc(center, radius, 0.0, TAU, 48, Color(0.92, 0.78, 0.42, 0.80), 3.0, true)
	draw_circle(center + _knob_offset, knob_radius, Color(0.95, 0.80, 0.40, 0.90))

