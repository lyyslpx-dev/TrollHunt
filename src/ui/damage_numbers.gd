class_name DamageNumbers
extends CanvasLayer
## 伤害飘字：世界坐标投影到屏幕，对象池复用。

const POOL_SIZE := 32
const LIFETIME := 0.75

var _labels: Array[Label] = []
var _active: Array[Dictionary] = []


func _ready() -> void:
	layer = 20
	add_to_group("damage_numbers")
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)
	for i in POOL_SIZE:
		var label := Label.new()
		label.visible = false
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(label)
		_labels.append(label)


func spawn(world_position: Vector3, amount: int, is_crit: bool) -> void:
	var label := _free_label()
	if label == null:
		return
	label.visible = true
	label.text = str(amount)
	label.add_theme_font_size_override("font_size", 44 if is_crit else 28)
	label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.25) if is_crit else Color(1.0, 1.0, 1.0))
	label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	label.add_theme_constant_override("outline_size", 8)
	label.scale = Vector2(1.25, 1.25) if is_crit else Vector2.ONE
	_active.append({
		"label": label,
		"world": world_position,
		"time": 0.0,
		"drift": randf_range(-26.0, 26.0),
	})


func _process(delta: float) -> void:
	if _active.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var finished: Array[Dictionary] = []
	for entry: Dictionary in _active:
		var time: float = entry["time"] + delta
		entry["time"] = time
		var label: Label = entry["label"]
		if time >= LIFETIME:
			label.visible = false
			finished.append(entry)
			continue
		var world: Vector3 = entry["world"] + Vector3(0, 1.0 + time * 1.4, 0)
		var screen := camera.unproject_position(world)
		label.position = screen + Vector2(entry["drift"] * time, 0)
		label.modulate.a = 1.0 - time / LIFETIME
	for entry in finished:
		_active.erase(entry)


func _free_label() -> Label:
	for label in _labels:
		var busy := false
		for entry: Dictionary in _active:
			if entry["label"] == label:
				busy = true
				break
		if not busy:
			return label
	return null

