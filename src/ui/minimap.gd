class_name Minimap
extends Control
## 右上角小地图：实时显示地图范围、危险区/安全区和玩家位置，可点击收缩。

var _player: Node3D
var _bounds := Vector4(-50.0, -50.0, 50.0, 50.0)
var _zones: Array = []
var _collapsed := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_player = get_tree().get_first_node_in_group("player") as Node3D
	var layout := get_tree().get_first_node_in_group("map_layout") as Node
	if layout:
		if layout.has_method("map_bounds"):
			var b: Array = layout.map_bounds()
			if b.size() == 4:
				_bounds = Vector4(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
		if layout.has_method("map_zones"):
			_zones = layout.map_zones()
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_collapsed = not _collapsed


func _draw() -> void:
	if _collapsed:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.45))
		draw_rect(Rect2(4, 4, size.x - 8, size.y - 8), Color(0.12, 0.10, 0.14, 0.9))
		draw_string(ThemeDB.fallback_font, Vector2(18, 36), "地图", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.75, 0.4))
		return

	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.45))
	var inset := 8.0
	var map_rect := Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0)
	draw_rect(map_rect, Color(0.08, 0.10, 0.14, 0.85))
	draw_rect(map_rect, Color(0.75, 0.62, 0.30, 0.9), false, 2.0)

	for zone in _zones:
		if not zone is Dictionary:
			continue
		var rect: Array = zone.get("rect", [])
		if rect.size() < 4:
			continue
		var is_hazard: bool = String(zone.get("variant", "")) == "hazard"
		var is_safe: bool = bool(zone.get("safe", false))
		var zone_rect := _map_rect_for(float(rect[0]), float(rect[1]), float(rect[2]), float(rect[3]), map_rect)
		if is_hazard:
			draw_rect(zone_rect, Color(0.9, 0.2, 0.1, 0.55))
		elif is_safe:
			draw_rect(zone_rect, Color(0.2, 0.85, 0.35, 0.55))
		else:
			draw_rect(zone_rect, Color(0.5, 0.45, 0.35, 0.25))

	if _player == null:
		return
	var px := inverse_lerp(_bounds.x, _bounds.z, _player.global_position.x)
	var pz := inverse_lerp(_bounds.y, _bounds.w, _player.global_position.z)
	var dot := map_rect.position + Vector2(px * map_rect.size.x, pz * map_rect.size.y)
	draw_circle(dot, 6.0, Color(0.2, 0.95, 0.45))


func _map_rect_for(rx: float, rz: float, rw: float, rh: float, map_rect: Rect2) -> Rect2:
	var x0 := inverse_lerp(_bounds.x, _bounds.z, rx)
	var x1 := inverse_lerp(_bounds.x, _bounds.z, rx + rw)
	var y0 := inverse_lerp(_bounds.y, _bounds.w, rz)
	var y1 := inverse_lerp(_bounds.y, _bounds.w, rz + rh)
	var pos := map_rect.position + Vector2(minf(x0, x1) * map_rect.size.x, minf(y0, y1) * map_rect.size.y)
	var sz := Vector2(absf(x1 - x0) * map_rect.size.x, absf(y1 - y0) * map_rect.size.y)
	return Rect2(pos, sz)
