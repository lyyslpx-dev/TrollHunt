extends Control
## 创建角色：第一页选职业（3D 卡片），第二页起名 + 选模型（大预览）。

const CLASSES := ["战士", "法师", "道士"]
const CLASS_MODELS := {
	"战士": "CHR_PHOTO_02",
	"法师": "CHR_PHOTO_01",
	"道士": "CHR_PHOTO_03",
}
const CLASS_DESCS := {
	"战士": "近战肉搏 · 防御出众",
	"法师": "远程法术 · 爆发强力",
	"道士": "符咒辅助 · 灵活多变",
}
const MODEL_CHOICES := [
	["CHR_PHOTO_07", "中年侠客"],
	["CHR_DEFAULT_01", "四视图男"],
	["CHR_PHOTO_01", "沉稳男士"],
	["CHR_PHOTO_02", "黑衫武者"],
	["CHR_PHOTO_03", "黑衫壮汉"],
	["CHR_PHOTO_04", "牛仔少女"],
	["CHR_PHOTO_05", "猫纹短裤"],
	["CHR_PHOTO_06", "少年"],
	["CHR_PHOTO_08", "浴帽大叔"],
	["CHR_Photo_09", "Polo衫男"],
	["CHR_Photo_10", "人体艺术"],
	["CHR_Photo_11", "赤膊男"],
	["CHR_WARRIOR_01", "战士原型"],
]

var _class_index := 0
var _model_index := 0
var _name_edit: LineEdit
var _page1: Control
var _page2: Control
var _model_label: Label
var _preview_root: Node3D
var _class_previews: Array[Node3D] = []


func _ready() -> void:
	_build_background()
	_build_page1()
	_build_page2()
	_apply_current()


func _process(delta: float) -> void:
	if _preview_root:
		_preview_root.rotation.y += delta * 0.7
	for root in _class_previews:
		if root and is_instance_valid(root):
			root.rotation.y += delta * 0.7


func _build_background() -> void:
	var texture := load("res://assets/brand/splash.png") as Texture2D
	var bg := TextureRect.new()
	if texture:
		bg.texture = texture
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var dim := ColorRect.new()
	dim.color = Color(0.04, 0.03, 0.08, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)


func _panel_style(border_color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.06, 0.10, 0.92)
	style.border_color = border_color
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.shadow_color = Color(0, 0, 0, 0.5)
	style.shadow_size = 10
	return style


func _card_style() -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = load("res://assets/ui/hd/card_frame.png") as Texture2D
	style.texture_margin_left = 30.0
	style.texture_margin_right = 30.0
	style.texture_margin_top = 30.0
	style.texture_margin_bottom = 30.0
	style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_STRETCH
	return style


func _title_label(text: String) -> PanelContainer:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.10, 0.08, 0.05, 0.95)
	style.border_color = Color(0.9, 0.72, 0.3)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 30
	style.content_margin_right = 30
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	var label := Label.new()
	label.name = "Label"
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	panel.add_child(label)
	return panel


func _make_preview(model_id: String, view_size: Vector2i) -> SubViewportContainer:
	var container := SubViewportContainer.new()
	container.stretch = true
	container.custom_minimum_size = Vector2(view_size)
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var viewport := SubViewport.new()
	viewport.size = view_size
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	container.add_child(viewport)

	var camera := Camera3D.new()
	camera.position = Vector3(0, 1.2, 2.9)
	camera.fov = 34.0
	viewport.add_child(camera)
	camera.look_at_from_position(Vector3(0, 1.2, 2.9), Vector3(0, 1.05, 0))

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-40, -35, 0)
	light.light_energy = 1.5
	viewport.add_child(light)

	var root := Node3D.new()
	viewport.add_child(root)
	var model := AssetLibrary.instantiate(model_id)
	if model == null:
		model = _fallback_capsule(Color(0.35, 0.55, 0.9))
	root.add_child(model)
	_fit_model(model, 1.9)
	root.set_meta("fit_height", 1.9)
	return container


func _fit_model(model: Node3D, target_height: float) -> void:
	var aabb := _model_aabb(model)
	if aabb.size.y > 0.01:
		var scale := target_height / aabb.size.y
		model.scale = Vector3.ONE * scale
		model.position.y = -aabb.position.y * scale


func _model_aabb(model: Node3D) -> AABB:
	var aabb := AABB()
	var found := false
	for child in model.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var world_aabb: AABB = mi.transform * mi.get_aabb()
		if not found:
			aabb = world_aabb
			found = true
		else:
			aabb = aabb.merge(world_aabb)
	return aabb


func _fallback_capsule(color: Color) -> Node3D:
	var root := Node3D.new()
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.42
	mesh.height = 1.7
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mi.material_override = mat
	mi.position.y = 0.85
	root.add_child(mi)
	return root


func _build_page1() -> void:
	_page1 = Control.new()
	_page1.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_page1)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 18)
	column.offset_left = 40
	column.offset_right = -40
	column.offset_top = 30
	column.offset_bottom = -30
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_page1.add_child(column)

	var title_holder := CenterContainer.new()
	column.add_child(title_holder)
	title_holder.add_child(_title_label("角色选择"))

	var cards := HBoxContainer.new()
	cards.add_theme_constant_override("separation", 18)
	cards.alignment = BoxContainer.ALIGNMENT_CENTER
	cards.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(cards)

	for i in CLASSES.size():
		var cname: String = CLASSES[i]
		var card := PanelContainer.new()
		card.add_theme_stylebox_override("panel", _card_style())
		card.custom_minimum_size = Vector2(240, 420)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.size_flags_vertical = Control.SIZE_EXPAND_FILL
		cards.add_child(card)

		var card_column := VBoxContainer.new()
		card_column.add_theme_constant_override("separation", 6)
		card.add_child(card_column)

		var preview := _make_preview(String(CLASS_MODELS[cname]), Vector2i(220, 300))
		card_column.add_child(preview)
		_class_previews.append(preview.get_child(0).get_child(2))

		var button := Button.new()
		button.text = "选择" + cname
		button.custom_minimum_size = Vector2(0, 52)
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_class_card.bind(i))
		card_column.add_child(button)

		var desc := Label.new()
		desc.text = String(CLASS_DESCS[cname])
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.add_theme_font_size_override("font_size", 14)
		desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.78))
		card_column.add_child(desc)

	if GameState.character_created:
		var continue_holder := CenterContainer.new()
		column.add_child(continue_holder)
		var continue_button := Button.new()
		continue_button.text = "继续游戏（%s · %s）" % [GameState.player_name, GameState.selected_class]
		continue_button.custom_minimum_size = Vector2(360, 54)
		continue_button.focus_mode = Control.FOCUS_NONE
		continue_button.pressed.connect(_on_continue)
		continue_holder.add_child(continue_button)


func _build_page2() -> void:
	_page2 = Control.new()
	_page2.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_page2.visible = false
	add_child(_page2)

	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.add_theme_constant_override("separation", 14)
	column.offset_left = 40
	column.offset_right = -40
	column.offset_top = 26
	column.offset_bottom = -26
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	_page2.add_child(column)

	var title_holder := CenterContainer.new()
	column.add_child(title_holder)
	_page2_title = _title_label("创建角色 · " + CLASSES[_class_index])
	title_holder.add_child(_page2_title)

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 24)
	body.alignment = BoxContainer.ALIGNMENT_CENTER
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_child(body)

	var preview_holder := CenterContainer.new()
	preview_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(preview_holder)
	preview_holder.add_child(_make_preview(String(MODEL_CHOICES[_model_index][0]), Vector2i(380, 470)))
	_preview_root = preview_holder.get_child(0).get_child(0).get_child(2) as Node3D

	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(360, 0)
	side.add_theme_constant_override("separation", 14)
	side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(side)

	var name_title := Label.new()
	name_title.text = "角色名字"
	name_title.add_theme_font_size_override("font_size", 24)
	name_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	side.add_child(name_title)

	_name_edit = LineEdit.new()
	_name_edit.text = GameState.player_name
	_name_edit.custom_minimum_size = Vector2(0, 46)
	_name_edit.max_length = 8
	side.add_child(_name_edit)

	var model_title := Label.new()
	model_title.text = "角色模型"
	model_title.add_theme_font_size_override("font_size", 24)
	model_title.add_theme_color_override("font_color", Color(0.95, 0.88, 0.7))
	side.add_child(model_title)

	var model_row := HBoxContainer.new()
	model_row.add_theme_constant_override("separation", 12)
	model_row.alignment = BoxContainer.ALIGNMENT_CENTER
	side.add_child(model_row)
	var prev := Button.new()
	prev.text = "◀"
	prev.custom_minimum_size = Vector2(64, 52)
	prev.focus_mode = Control.FOCUS_NONE
	prev.pressed.connect(_on_model_prev)
	model_row.add_child(prev)
	_model_label = Label.new()
	_model_label.custom_minimum_size = Vector2(200, 52)
	_model_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_model_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_model_label.add_theme_font_size_override("font_size", 24)
	_model_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	model_row.add_child(_model_label)
	var next := Button.new()
	next.text = "▶"
	next.custom_minimum_size = Vector2(64, 52)
	next.focus_mode = Control.FOCUS_NONE
	next.pressed.connect(_on_model_next)
	model_row.add_child(next)

	var start := Button.new()
	start.text = "开始冒险"
	start.custom_minimum_size = Vector2(0, 60)
	start.focus_mode = Control.FOCUS_NONE
	start.pressed.connect(_on_start)
	side.add_child(start)

	var back := Button.new()
	back.text = "返回选择职业"
	back.custom_minimum_size = Vector2(0, 50)
	back.focus_mode = Control.FOCUS_NONE
	back.pressed.connect(func() -> void: _show_page(0))
	side.add_child(back)


func _show_page(index: int) -> void:
	_page1.visible = index == 0
	_page2.visible = index == 1


func _on_class_card(index: int) -> void:
	_class_index = index
	var wanted: String = CLASS_MODELS[CLASSES[index]]
	_model_index = 0
	for i in MODEL_CHOICES.size():
		if String(MODEL_CHOICES[i][0]) == wanted:
			_model_index = i
			break
	_title_label_refresh()
	_show_page(1)


var _page2_title: PanelContainer


func _title_label_refresh() -> void:
	if _page2_title and _page2_title.has_node("Label"):
		var label := _page2_title.get_node("Label") as Label
		label.text = "创建角色 · " + CLASSES[_class_index]


func _on_model_prev() -> void:
	_model_index = (_model_index - 1 + MODEL_CHOICES.size()) % MODEL_CHOICES.size()
	_refresh_model_label()


func _on_model_next() -> void:
	_model_index = (_model_index + 1) % MODEL_CHOICES.size()
	_refresh_model_label()


func _refresh_model_label() -> void:
	if _model_label:
		_model_label.text = MODEL_CHOICES[_model_index][1]
	_refresh_preview()


func _refresh_preview() -> void:
	if _preview_root == null:
		return
	for child in _preview_root.get_children():
		child.queue_free()
	var id: String = String(MODEL_CHOICES[_model_index][0])
	var model := AssetLibrary.instantiate(id)
	if model == null:
		model = _fallback_capsule(Color(0.35, 0.55, 0.9))
	_preview_root.add_child(model)
	_fit_model(model, 1.9)


func _on_start() -> void:
	GameState.selected_class = CLASSES[_class_index]
	GameState.selected_character_id = String(MODEL_CHOICES[_model_index][0])
	var name_text := _name_edit.text.strip_edges()
	GameState.player_name = name_text if not name_text.is_empty() else "无名侠士"
	GameState.character_created = true
	GameState.current_map_id = ""
	Save.save_game()
	get_tree().change_scene_to_file("res://scenes/main_city.tscn")


func _on_continue() -> void:
	GameState.current_map_id = ""
	get_tree().change_scene_to_file("res://scenes/main_city.tscn")


func _apply_current() -> void:
	if GameState.character_created:
		var saved_class := CLASSES.find(GameState.selected_class)
		if saved_class >= 0:
			_class_index = saved_class
		var saved_model := MODEL_CHOICES.find(GameState.selected_character_id)
		if saved_model >= 0:
			_model_index = saved_model
