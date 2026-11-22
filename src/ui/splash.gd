extends Control
## 启动画面：全屏铺满显示海报，3 秒后进入创建角色（点击可跳过）。

var _go_queued := false


func _ready() -> void:
	var texture := load("res://assets/brand/splash.png") as Texture2D
	var rect := TextureRect.new()
	if texture:
		rect.texture = texture
	rect.stretch_mode = TextureRect.STRETCH_SCALE
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(rect)
	get_tree().create_timer(3.0).timeout.connect(_go)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		_go()


func _go() -> void:
	if _go_queued:
		return
	_go_queued = true
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
