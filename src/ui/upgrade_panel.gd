class_name UpgradePanel
extends Control
## 装备升级 NPC 的占位面板，后续接背包与强化数据。

signal closed

var _gold_label: Label


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false
	closed.emit()


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -280
	panel.offset_top = -190
	panel.offset_right = 280
	panel.offset_bottom = 190
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_bottom", 20)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	margin.add_child(column)

	var title := Label.new()
	title.text = "装备升级"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.98, 0.84, 0.48))
	column.add_child(title)

	var quote := Label.new()
	quote.text = "胖哥：把装备拿来，我给你敲两下。"
	quote.add_theme_font_size_override("font_size", 18)
	quote.add_theme_color_override("font_color", Color(0.86, 0.82, 0.72))
	column.add_child(quote)

	_gold_label = Label.new()
	_gold_label.add_theme_font_size_override("font_size", 17)
	_gold_label.add_theme_color_override("font_color", Color(0.98, 0.78, 0.32))
	column.add_child(_gold_label)

	var note := Label.new()
	note.text = "升级系统接入中。\n背包与装备面板完成后，这里接强化 +1 到 +15。"
	note.add_theme_font_size_override("font_size", 17)
	note.add_theme_color_override("font_color", Color(0.72, 0.70, 0.66))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(note)

	var spacer := Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(spacer)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(140, 50)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	column.add_child(close_button)


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.070, 0.085, 0.98)
	style.border_color = Color(0.82, 0.66, 0.30, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 12
	return style


func _refresh() -> void:
	if _gold_label:
		_gold_label.text = "当前金币：%d" % GameState.gold
