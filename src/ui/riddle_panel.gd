class_name RiddlePanel
extends PanelContainer
## 猜谜面板：每天 3 题，答对 +1% 全能属性，答错 -1%。

signal closed

const RIDDLE_PATH := "res://data/riddles.json"
const DAILY_LIMIT := 3

var _riddles: Array = []
var _current: Dictionary = {}
var _title: Label
var _options_box: VBoxContainer
var _hint: Label
var _close_button: Button


func _ready() -> void:
	visible = false
	_build()
	_load_riddles()


func _build() -> void:
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -360
	offset_right = 360
	offset_top = -220
	offset_bottom = 220
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.10, 0.95)
	style.border_color = Color(0.9, 0.65, 0.2)
	style.set_border_width_all(2)
	style.set_corner_radius_all(14)
	style.content_margin_left = 22
	style.content_margin_right = 22
	style.content_margin_top = 18
	style.content_margin_bottom = 18
	add_theme_stylebox_override("panel", style)

	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	add_child(column)

	_title = Label.new()
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_title.add_theme_font_size_override("font_size", 26)
	_title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.45))
	column.add_child(_title)

	_options_box = VBoxContainer.new()
	_options_box.add_theme_constant_override("separation", 10)
	column.add_child(_options_box)

	_hint = Label.new()
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint.add_theme_font_size_override("font_size", 18)
	_hint.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	column.add_child(_hint)

	_close_button = Button.new()
	_close_button.text = "关闭"
	_close_button.focus_mode = Control.FOCUS_NONE
	_close_button.pressed.connect(_close)
	column.add_child(_close_button)


func _load_riddles() -> void:
	if not FileAccess.file_exists(RIDDLE_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RIDDLE_PATH))
	if parsed is Dictionary:
		var list: Variant = (parsed as Dictionary).get("riddles", [])
		if list is Array:
			_riddles = list


func open() -> void:
	var today := Time.get_date_string_from_system()
	if GameState.riddle_date != today:
		GameState.riddle_date = today
		GameState.riddle_answered_today = 0
	if GameState.riddle_answered_today >= DAILY_LIMIT:
		_title.text = "今日答题次数已用完"
		_clear_options()
		_hint.text = "当前全能属性加成：%+.0f%%" % (GameState.riddle_bonus * 100.0)
		visible = true
		return
	if _riddles.is_empty():
		_title.text = "题库暂时为空"
		_clear_options()
		visible = true
		return
	_current = _riddles.pick_random()
	_title.text = "第 %d/3 题\n%s" % [GameState.riddle_answered_today + 1, _current.get("q", "")]
	_hint.text = ""
	_build_options()
	visible = true


func _build_options() -> void:
	_clear_options()
	var options: Array = _current.get("options", [])
	var answer: int = int(_current.get("a", 0))
	for i in options.size():
		var b := Button.new()
		b.text = str(options[i])
		b.custom_minimum_size = Vector2(0, 50)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_answer.bind(i, answer))
		_options_box.add_child(b)


func _clear_options() -> void:
	for child in _options_box.get_children():
		child.queue_free()


func _on_answer(picked: int, answer: int) -> void:
	var correct: bool = picked == answer
	GameState.apply_riddle_result(correct)
	GameState.riddle_answered_today += 1
	_clear_options()
	_hint.text = "答对了！属性 +1%" if correct else "答错了，属性 -1%"
	_hint.add_theme_color_override("font_color", Color(0.5, 1.0, 0.6) if correct else Color(1.0, 0.5, 0.45))
	if GameState.riddle_answered_today >= DAILY_LIMIT:
		await get_tree().create_timer(1.0).timeout
		open()
	else:
		await get_tree().create_timer(1.0).timeout
		open()


func _close() -> void:
	visible = false
	closed.emit()
