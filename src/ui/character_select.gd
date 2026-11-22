extends Control
## 创建角色：选职业、起名字、选模型，然后进入主城。

const CLASSES := ["战士", "法师", "道士"]
const CLASS_MODELS := {
	"战士": "CHR_WARRIOR_01",
	"法师": "CHR_MAGE_01",
	"道士": "CHR_TAOIST_01",
}
const MODEL_CHOICES := [
	["CHR_WARRIOR_01", "战士"],
	["CHR_MAGE_01", "法师"],
	["CHR_TAOIST_01", "道士"],
	["CHR_CUSTOM_MALE_01", "自定义男角色"],
	["CHR_PHOTO_01", "沉稳男士"],
	["CHR_PHOTO_02", "黑衫武者"],
	["CHR_PHOTO_03", "黑衫壮汉"],
	["CHR_PHOTO_04", "牛仔少女"],
	["CHR_PHOTO_05", "猫纹短裤"],
	["CHR_PHOTO_06", "少年"],
	["CHR_PHOTO_07", "中年侠客"],
	["CHR_PHOTO_08", "浴帽大叔"],
]

var _class_index := 0
var _model_index := 3
var _name_edit: LineEdit
var _class_label: Label
var _model_label: Label


func _ready() -> void:
	_build_ui()


func _build_ui() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.08, 0.06, 0.13, 1.0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var title := Label.new()
	title.text = "杨庄传奇"
	title.add_theme_font_size_override("font_size", 60)
	title.add_theme_color_override("font_color", Color(1.0, 0.82, 0.35))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.anchor_left = 0.5
	title.anchor_right = 0.5
	title.offset_left = -300
	title.offset_right = 300
	title.offset_top = 40
	title.offset_bottom = 130
	add_child(title)

	var column := VBoxContainer.new()
	column.anchor_left = 0.5
	column.anchor_right = 0.5
	column.anchor_top = 0.5
	column.anchor_bottom = 0.5
	column.offset_left = -260
	column.offset_right = 260
	column.offset_top = -150
	column.offset_bottom = 200
	column.add_theme_constant_override("separation", 14)
	add_child(column)

	var class_title := Label.new()
	class_title.text = "选择职业"
	class_title.add_theme_font_size_override("font_size", 24)
	class_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	column.add_child(class_title)

	var class_row := HBoxContainer.new()
	class_row.add_theme_constant_override("separation", 12)
	class_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(class_row)
	for i in CLASSES.size():
		var b := Button.new()
		b.text = CLASSES[i]
		b.custom_minimum_size = Vector2(120, 54)
		b.focus_mode = Control.FOCUS_NONE
		b.pressed.connect(_on_class_pressed.bind(i))
		class_row.add_child(b)

	_class_label = Label.new()
	_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_class_label.add_theme_font_size_override("font_size", 20)
	_class_label.add_theme_color_override("font_color", Color(0.6, 1.0, 0.65))
	column.add_child(_class_label)

	var name_title := Label.new()
	name_title.text = "角色名字"
	name_title.add_theme_font_size_override("font_size", 22)
	name_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	column.add_child(name_title)

	_name_edit = LineEdit.new()
	_name_edit.text = "无名侠士"
	_name_edit.custom_minimum_size = Vector2(0, 44)
	_name_edit.max_length = 8
	column.add_child(_name_edit)

	var model_title := Label.new()
	model_title.text = "角色模型"
	model_title.add_theme_font_size_override("font_size", 22)
	model_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	column.add_child(model_title)

	var model_row := HBoxContainer.new()
	model_row.add_theme_constant_override("separation", 12)
	model_row.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_child(model_row)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(60, 50)
	prev.focus_mode = Control.FOCUS_NONE
	prev.pressed.connect(_on_model_prev)
	model_row.add_child(prev)
	_model_label = Label.new()
	_model_label.custom_minimum_size = Vector2(260, 50)
	_model_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_model_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_model_label.add_theme_font_size_override("font_size", 22)
	_model_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	model_row.add_child(_model_label)
	var next := Button.new()
	next.text = "▶"
	next.custom_minimum_size = Vector2(60, 50)
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(_on_model_next)
	model_row.add_child(next)

	var start := Button.new()
	start.text = "进入杨庄村"
	start.custom_minimum_size = Vector2(0, 58)
	start.focus_mode = Control.FOCUS_NONE
	start.pressed.connect(_on_start)
	column.add_child(start)

	_refresh_class_label()
	_refresh_model_label()


func _on_class_pressed(index: int) -> void:
	_class_index = index
	_model_index = MODEL_CHOICES.find(CLASS_MODELS[CLASSES[_class_index]])
	if _model_index < 0:
		_model_index = 3
	_refresh_class_label()
	_refresh_model_label()


func _on_model_prev() -> void:
	_model_index = (_model_index - 1 + MODEL_CHOICES.size()) % MODEL_CHOICES.size()
	_refresh_model_label()


func _on_model_next() -> void:
	_model_index = (_model_index + 1) % MODEL_CHOICES.size()
	_refresh_model_label()


func _refresh_class_label() -> void:
	if _class_label:
		_class_label.text = "当前职业：%s" % CLASSES[_class_index]


func _refresh_model_label() -> void:
	if _model_label:
		_model_label.text = MODEL_CHOICES[_model_index][1]


func _on_start() -> void:
	var chosen_class: String = CLASSES[_class_index]
	GameState.selected_class = chosen_class
	GameState.selected_character_id = String(MODEL_CHOICES[_model_index][0])
	var name_text := _name_edit.text.strip_edges()
	GameState.player_name = name_text if not name_text.is_empty() else "无名侠士"
	GameState.current_map_id = ""
	get_tree().change_scene_to_file("res://scenes/main_city.tscn")
