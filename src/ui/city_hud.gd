extends Control
## 主城 HUD：状态、摇杆、NPC 交互按钮、擂台入口、各功能面板。

var _player: Node3D
var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _info_label: Label
var _npc_button: Button
var _npc_action: String = ""
var _arena_button: Button
var _upgrade_panel: UpgradePanel
var _teleport_panel: TeleportPanel
var _riddle_panel: RiddlePanel


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_tree().get_first_node_in_group("player")
	_build_stats()
	_build_joystick()
	_build_npc_button()
	_build_arena_button()
	_build_minimap()
	_build_panels()
	Events.player_stats_changed.connect(_refresh_stats)
	Events.npc_prompt_changed.connect(_on_npc_prompt)
	Events.npc_upgrade_requested.connect(_on_upgrade_requested)
	Events.npc_teleport_requested.connect(_on_teleport_requested)
	Events.npc_riddle_requested.connect(_on_riddle_requested)
	Events.travel_requested.connect(_on_travel)
	_refresh_stats()


func _build_stats() -> void:
	var box := VBoxContainer.new()
	box.offset_left = 22
	box.offset_top = 18
	box.offset_right = 330
	box.offset_bottom = 160
	box.add_theme_constant_override("separation", 5)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	_info_label = Label.new()
	_info_label.text = "杨庄村"
	_info_label.add_theme_font_size_override("font_size", 17)
	_info_label.add_theme_color_override("font_color", Color(0.98, 0.86, 0.55))
	box.add_child(_info_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(300, 24)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_hp_bar)

	_mp_bar = ProgressBar.new()
	_mp_bar.show_percentage = false
	_mp_bar.custom_minimum_size = Vector2(300, 16)
	_mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_mp_bar)


func _build_joystick() -> void:
	var stick := TouchStick.new()
	stick.anchor_left = 0.0
	stick.anchor_top = 1.0
	stick.anchor_right = 0.0
	stick.anchor_bottom = 1.0
	stick.offset_left = 40
	stick.offset_top = -240
	stick.offset_right = 240
	stick.offset_bottom = -40
	stick.moved.connect(_on_joystick)
	add_child(stick)


func _build_npc_button() -> void:
	_npc_button = Button.new()
	_npc_button.anchor_left = 0.5
	_npc_button.anchor_right = 0.5
	_npc_button.anchor_top = 1.0
	_npc_button.anchor_bottom = 1.0
	_npc_button.offset_left = -110
	_npc_button.offset_right = 110
	_npc_button.offset_top = -270
	_npc_button.offset_bottom = -210
	_npc_button.focus_mode = Control.FOCUS_NONE
	_npc_button.visible = false
	_npc_button.pressed.connect(_on_npc_pressed)
	add_child(_npc_button)


func _build_arena_button() -> void:
	_arena_button = Button.new()
	_arena_button.text = "擂台"
	_arena_button.anchor_left = 1.0
	_arena_button.anchor_top = 0.0
	_arena_button.anchor_right = 1.0
	_arena_button.anchor_bottom = 0.0
	_arena_button.offset_left = -150
	_arena_button.offset_top = 20
	_arena_button.offset_right = -24
	_arena_button.offset_bottom = 76
	_arena_button.focus_mode = Control.FOCUS_NONE
	_arena_button.pressed.connect(_on_arena_pressed)
	add_child(_arena_button)


func _build_minimap() -> void:
	var minimap := Minimap.new()
	minimap.anchor_left = 1.0
	minimap.anchor_right = 1.0
	minimap.anchor_top = 0.0
	minimap.anchor_bottom = 0.0
	minimap.offset_left = -208
	minimap.offset_right = -24
	minimap.offset_top = 92
	minimap.offset_bottom = 276
	minimap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap._bounds = Vector4(-45.0, -45.0, 45.0, 45.0)
	add_child(minimap)


func _build_panels() -> void:
	_upgrade_panel = UpgradePanel.new()
	add_child(_upgrade_panel)
	_upgrade_panel.closed.connect(_on_panel_closed)
	_teleport_panel = TeleportPanel.new()
	add_child(_teleport_panel)
	_teleport_panel.closed.connect(_on_panel_closed)
	_riddle_panel = RiddlePanel.new()
	add_child(_riddle_panel)
	_riddle_panel.closed.connect(_on_panel_closed)


func _refresh_stats() -> void:
	if _hp_bar:
		_hp_bar.max_value = GameState.max_hp
		_hp_bar.value = GameState.hp
	if _mp_bar:
		_mp_bar.max_value = GameState.max_mp
		_mp_bar.value = GameState.mp
	if _info_label:
		_info_label.text = "%s · %s  Lv.%d  金币 %d" % [GameState.player_name, GameState.selected_class, GameState.player_level, GameState.gold]


func _on_joystick(dir: Vector2) -> void:
	if _player and _player.has_method("set_move_input"):
		_player.set_move_input(dir)


func _on_npc_prompt(text: String, visible: bool) -> void:
	_npc_action = text if visible else ""
	if _npc_button:
		_npc_button.text = text
		_npc_button.visible = visible and not _any_panel_open()


func _on_npc_pressed() -> void:
	match _npc_action:
		"装备升级":
			Events.npc_upgrade_requested.emit()
		"传送":
			Events.npc_teleport_requested.emit()
		"猜谜":
			Events.npc_riddle_requested.emit()


func _on_upgrade_requested() -> void:
	_npc_button.hide()
	_upgrade_panel.open()


func _on_teleport_requested() -> void:
	_npc_button.hide()
	_teleport_panel.open()


func _on_riddle_requested() -> void:
	_npc_button.hide()
	_riddle_panel.open()


func _on_arena_pressed() -> void:
	GameState.current_map_id = "MAP_10_ARENA"
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_travel(map_id: String) -> void:
	GameState.current_map_id = String(map_id)
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _on_panel_closed() -> void:
	if _npc_action != "" and not _any_panel_open():
		_npc_button.show()


func _any_panel_open() -> bool:
	return (_upgrade_panel and _upgrade_panel.visible) or (_teleport_panel and _teleport_panel.visible) or (_riddle_panel and _riddle_panel.visible)
