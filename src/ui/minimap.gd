class_name Minimap
extends Control
## 右上角小地图：显示地图范围和玩家位置。

var _player: Node3D
var _bounds := Vector4(-50.0, -50.0, 50.0, 50.0)


func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	var layout := get_tree().get_first_node_in_group("map_layout") as Node
	if layout and layout.has_method("map_bounds"):
		var b: Array = layout.map_bounds()
		if b.size() == 4:
			_bounds = Vector4(float(b[0]), float(b[1]), float(b[2]), float(b[3]))
	set_process(true)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.0, 0.0, 0.0, 0.35))
	var inset := 8.0
	var map_rect := Rect2(inset, inset, size.x - inset * 2.0, size.y - inset * 2.0)
	draw_rect(map_rect, Color(0.08, 0.10, 0.14, 0.85))
	draw_rect(map_rect, Color(0.75, 0.62, 0.30, 0.9), false, 2.0)
	if _player == null:
		return
	var px := inverse_lerp(_bounds.x, _bounds.z, _player.global_position.x)
	var pz := inverse_lerp(_bounds.y, _bounds.w, _player.global_position.z)
	var dot := map_rect.position + Vector2(px * map_rect.size.x, pz * map_rect.size.y)
	draw_circle(dot, 6.0, Color(0.2, 0.95, 0.45))
