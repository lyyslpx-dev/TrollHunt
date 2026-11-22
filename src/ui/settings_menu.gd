class_name SettingsMenu
extends Control
## 设置页：八项画质参数，自动档只做默认值，手动修改后进入自定义。

var _syncing: bool = false

var _preset_option: OptionButton
var _scale_slider: HSlider
var _scale_value: Label
var _shadow_option: OptionButton
var _fx_slider: HSlider
var _fx_value: Label
var _post_check: CheckButton
var _msaa_option: OptionButton
var _fps_option: OptionButton
var _dyn_check: CheckButton

const PRESET_LABELS: Array[String] = ["自动", "低", "中", "高", "自定义"]


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build()
	Settings.changed.connect(_on_settings_changed)


func open() -> void:
	_refresh()
	visible = true


func close() -> void:
	visible = false


func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0.0, 0.0, 0.0, 0.65)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -360
	panel.offset_top = -270
	panel.offset_right = 360
	panel.offset_bottom = 270
	panel.add_theme_stylebox_override("panel", _panel_style())
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	margin.add_child(column)

	var title := Label.new()
	title.text = "设置"
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.96, 0.85, 0.55))
	column.add_child(title)

	var note := Label.new()
	note.text = "自动档只决定首次默认值，手动修改后进入自定义。"
	note.add_theme_font_size_override("font_size", 13)
	note.add_theme_color_override("font_color", Color(0.72, 0.70, 0.66))
	column.add_child(note)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	column.add_child(scroll)

	var rows := VBoxContainer.new()
	rows.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rows.add_theme_constant_override("separation", 8)
	scroll.add_child(rows)

	_preset_option = OptionButton.new()
	for label in PRESET_LABELS:
		_preset_option.add_item(label)
	_preset_option.item_selected.connect(_on_preset_selected)
	_add_row(rows, "画质预设", _preset_option, 220.0)

	_scale_slider = HSlider.new()
	_scale_slider.min_value = 0.5
	_scale_slider.max_value = 1.0
	_scale_slider.step = 0.05
	_scale_slider.custom_minimum_size = Vector2(240, 0)
	_scale_slider.value_changed.connect(_on_scale_changed)
	_scale_value = _value_label("85%")
	var scale_row := _add_row(rows, "渲染精度", _scale_slider, 240.0)
	scale_row.add_child(_scale_value)

	_shadow_option = OptionButton.new()
	for label in ["关", "低", "高"]:
		_shadow_option.add_item(label)
	_shadow_option.item_selected.connect(_on_shadow_selected)
	_add_row(rows, "阴影", _shadow_option, 160.0)

	_fx_slider = HSlider.new()
	_fx_slider.min_value = 0.0
	_fx_slider.max_value = 1.0
	_fx_slider.step = 0.05
	_fx_slider.custom_minimum_size = Vector2(240, 0)
	_fx_slider.value_changed.connect(_on_fx_changed)
	_fx_value = _value_label("100%")
	var fx_row := _add_row(rows, "特效强度", _fx_slider, 240.0)
	fx_row.add_child(_fx_value)

	_post_check = CheckButton.new()
	_post_check.toggled.connect(_on_post_toggled)
	_add_row(rows, "后处理", _post_check, 0.0)

	_msaa_option = OptionButton.new()
	for label in ["关", "2x"]:
		_msaa_option.add_item(label)
	_msaa_option.item_selected.connect(_on_msaa_selected)
	_add_row(rows, "抗锯齿", _msaa_option, 160.0)

	_fps_option = OptionButton.new()
	for label in ["30", "60", "不限制"]:
		_fps_option.add_item(label)
	_fps_option.item_selected.connect(_on_fps_selected)
	_add_row(rows, "帧率上限", _fps_option, 160.0)

	_dyn_check = CheckButton.new()
	_dyn_check.toggled.connect(_on_dyn_toggled)
	_add_row(rows, "动态分辨率", _dyn_check, 0.0)

	var buttons := HBoxContainer.new()
	buttons.add_theme_constant_override("separation", 12)
	buttons.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(buttons)

	var reset_button := Button.new()
	reset_button.text = "恢复默认"
	reset_button.custom_minimum_size = Vector2(140, 48)
	reset_button.focus_mode = Control.FOCUS_NONE
	reset_button.pressed.connect(_on_reset_pressed)
	buttons.add_child(reset_button)

	var close_button := Button.new()
	close_button.text = "关闭"
	close_button.custom_minimum_size = Vector2(120, 48)
	close_button.focus_mode = Control.FOCUS_NONE
	close_button.pressed.connect(close)
	buttons.add_child(close_button)

	_refresh()


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.075, 0.070, 0.085, 0.98)
	style.border_color = Color(0.82, 0.66, 0.30, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.5)
	style.shadow_size = 12
	return style


func _add_row(parent: VBoxContainer, label_text: String, control: Control, control_width: float) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(150, 0)
	label.add_theme_color_override("font_color", Color(0.88, 0.86, 0.80))
	row.add_child(label)

	if control_width > 0.0:
		control.custom_minimum_size.x = maxf(control.custom_minimum_size.x, control_width)
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	return row


func _value_label(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.custom_minimum_size = Vector2(64, 0)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label.add_theme_color_override("font_color", Color(0.96, 0.85, 0.55))
	return label


func _refresh() -> void:
	_syncing = true

	var preset := Settings.get_preset()
	var preset_index := 0
	match preset:
		"low":
			preset_index = 1
		"mid":
			preset_index = 2
		"high":
			preset_index = 3
		"custom":
			preset_index = 4
		_:
			preset_index = 0
	_preset_option.select(preset_index)

	var scale_value := float(Settings.get_value("graphics/render_scale", 0.85))
	_scale_slider.value = scale_value
	_scale_value.text = "%d%%" % roundi(scale_value * 100.0)

	match String(Settings.get_value("graphics/shadows", "high")):
		"off":
			_shadow_option.select(0)
		"low":
			_shadow_option.select(1)
		_:
			_shadow_option.select(2)

	var fx_value := float(Settings.get_value("graphics/fx_intensity", 1.0))
	_fx_slider.value = fx_value
	_fx_value.text = "%d%%" % roundi(fx_value * 100.0)

	_post_check.button_pressed = bool(Settings.get_value("graphics/post", true))
	_msaa_option.select(1 if String(Settings.get_value("graphics/msaa", "off")) == "2x" else 0)

	match int(Settings.get_value("graphics/fps_cap", 60)):
		30:
			_fps_option.select(0)
		0:
			_fps_option.select(2)
		_:
			_fps_option.select(1)

	_dyn_check.button_pressed = bool(Settings.get_value("graphics/dynamic_resolution", true))
	_syncing = false


func _on_settings_changed(_key: String, _value: Variant) -> void:
	if not _syncing:
		_refresh()


func _on_preset_selected(index: int) -> void:
	if _syncing:
		return
	match index:
		0:
			Settings.set_preset("auto")
		1:
			Settings.set_preset("low")
		2:
			Settings.set_preset("mid")
		3:
			Settings.set_preset("high")
		_:
			_refresh()
			return
	_refresh()


func _on_scale_changed(value: float) -> void:
	if _syncing:
		return
	Settings.set_value("graphics/render_scale", value)
	_scale_value.text = "%d%%" % roundi(value * 100.0)


func _on_shadow_selected(index: int) -> void:
	if _syncing:
		return
	var quality: String = ["off", "low", "high"][index]
	Settings.set_value("graphics/shadows", quality)


func _on_fx_changed(value: float) -> void:
	if _syncing:
		return
	Settings.set_value("graphics/fx_intensity", value)
	_fx_value.text = "%d%%" % roundi(value * 100.0)


func _on_post_toggled(on: bool) -> void:
	if _syncing:
		return
	Settings.set_value("graphics/post", on)


func _on_msaa_selected(index: int) -> void:
	if _syncing:
		return
	Settings.set_value("graphics/msaa", "2x" if index == 1 else "off")


func _on_fps_selected(index: int) -> void:
	if _syncing:
		return
	var cap: int = [30, 60, 0][index]
	Settings.set_value("graphics/fps_cap", cap)


func _on_dyn_toggled(on: bool) -> void:
	if _syncing:
		return
	Settings.set_value("graphics/dynamic_resolution", on)


func _on_reset_pressed() -> void:
	Settings.reset_to_defaults()
	_refresh()

