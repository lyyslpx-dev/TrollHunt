class_name TeleportPanel
extends PanelContainer
## 传送面板：列出 10 张可传送地图，按等级解锁。主城和擂台不在其中。

signal closed

var _list: VBoxContainer
var _close_button: Button


func _ready() -> void:
	visible = false
	_build()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -340
	offset_right = 340
	offset_top = -300
	offset_bottom = 300
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.06, 0.11, 0.95)
	style.border_color = Color(0.5, 0.8, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 16
	style.content_margin_bottom = 16
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	add_child(column)

	var title := Label.new()
	title.text = "传送 · 选择地图"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
	column.add_child(title)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 440)
	column.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 8)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)

	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.pressed.connect(_close)
	column.add_child(_close_button)


func open() -> void:
	_refresh()
	visible = true


func _refresh() -> void:
	for child in _list.get_children():
		child.queue_free()
	var ids := MapThemes.get_map_ids()
	for map_id in ids:
		if map_id == "MAP_10_ARENA":
			continue
		var theme := MapThemes.get_theme(map_id)
		var map_name := String(theme.get("name", map_id))
		var min_level: int = int(theme.get("min_level", 0))
		var unlocked: bool = GameState.player_level >= min_level
		var b := Button.new()
		b.custom_minimum_size = Vector2(0, 52)
		b.focus_mode = Control.FOCUS_NONE
		if unlocked:
			b.text = "%s  (Lv.%d+)" % [map_name, min_level]
			b.pressed.connect(_travel.bind(String(map_id)))
		else:
			b.text = "%s  (需要 Lv.%d)" % [map_name, min_level]
			b.disabled = true
		_list.add_child(b)


func _travel(map_id: String) -> void:
	Events.travel_requested.emit(map_id)


func _close() -> void:
	visible = false
	closed.emit()
