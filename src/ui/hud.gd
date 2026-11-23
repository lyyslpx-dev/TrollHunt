extends Control
## HUD：血蓝、金币、摇杆、技能栏（含冷却）、自动战斗、拾取提示、设置入口。

const SKILL_LABELS: Array[String] = ["普攻", "旋风斩", "冲锋", "雷霆"]
const SFX_LOOT := preload("res://assets/audio/sfx/loot.wav")
const SFX_SUCCESS := preload("res://assets/audio/sfx/success.wav")
const SFX_FAIL := preload("res://assets/audio/sfx/fail.wav")

var _player: Node = null
var _settings_menu: SettingsMenu
var _hp_bar: ProgressBar
var _mp_bar: ProgressBar
var _gold_label: Label
var _skill_buttons: Array[TextureButton] = []
var _auto_check: CheckButton
var _toast: Label
var _toast_time: float = 0.0
var _shot_frames: int = -1
var _skill_trigger: int = -1
var _npc_button: Button
var _upgrade_panel: UpgradePanel
var _npc_near: bool = false
var _zone_label: Label
var _label_title: Label
var _map_button: Button
var _character_button: Button
var _weapon_button: Button
var _inventory_button: Button
var _inventory_panel: PanelContainer
var _inventory_root: VBoxContainer
var _inventory_list: VBoxContainer
var _inventory_detail: Label
var _inventory_equipped: Label
var _equipped_box: HBoxContainer
var _detail_item: ItemData
var _disenchant_button: Button
var _strengthen_button: Button
var _inventory_close_button: Button
var _sort_inventory_button: Button
var _arena_wave_label: Label
var _leaderboard_button: Button
var _leaderboard_panel: PanelContainer
var _leaderboard_list: VBoxContainer
var _clear_leaderboard_button: Button
var _close_leaderboard_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_player = get_tree().get_first_node_in_group("player")
	_build_title()
	_build_status_bars()
	_build_joystick()
	_build_skills()
	_build_settings_button()
	_build_map_button()
	_build_character_button()
	_build_weapon_button()
	_build_inventory()
	_build_arena_wave_label()
	_build_leaderboard()
	_build_toast()
	_build_zone_prompt()
	_build_minimap()
	_build_settings_menu()
	_build_npc_interaction()
	_build_upgrade_panel()
	Events.loot_picked.connect(_on_loot_picked)
	Events.player_stats_changed.connect(_refresh_stats)
	Events.npc_prompt_changed.connect(_on_npc_prompt_changed)
	Events.npc_upgrade_requested.connect(_on_upgrade_requested)
	Events.zone_prompt_changed.connect(_on_zone_prompt_changed)
	Events.map_changed.connect(_on_map_changed)
	Events.player_died.connect(_on_player_died)
	_refresh_stats()
	if OS.get_cmdline_user_args().has("--shot"):
		_shot_frames = 180
	elif OS.get_cmdline_user_args().has("--shot-upgrade"):
		_upgrade_panel.open()
		_shot_frames = 40
	elif OS.get_cmdline_user_args().has("--shot-settings"):
		_settings_menu.open()
		_shot_frames = 40
	elif OS.get_cmdline_user_args().has("--shot-skill"):
		_shot_frames = 200
		_skill_trigger = 180


func _process(delta: float) -> void:
	_update_arena_wave()
	_refresh_stats()
	_update_skills()
	if _toast_time > 0.0:
		_toast_time -= delta
		_toast.modulate.a = 1.0 if _toast_time > 0.6 else clampf(_toast_time / 0.6, 0.0, 1.0)

	if _skill_trigger > 0:
		_skill_trigger -= 1
		if _skill_trigger == 0 and _player and _player.has_method("use_skill"):
			_player.call("use_skill", 2)

	if _shot_frames < 0:
		return
	_shot_frames -= 1
	if _shot_frames == 0:
		var image := get_viewport().get_texture().get_image()
		var path := "user://shot_main.png"
		image.save_png(path)
		print("[HUD] screenshot: ", ProjectSettings.globalize_path(path))
		get_tree().quit()


func _build_title() -> void:
	var label := Label.new()
	var map_name := "黄沙岗"
	var theme := MapThemes.get_theme(GameState.current_map_id if not GameState.current_map_id.is_empty() else MapThemes.default_map_id())
	if not theme.is_empty():
		map_name = String(theme.get("name", map_name))
	label.text = map_name
	label.add_theme_font_size_override("font_size", 22)
	label.add_theme_color_override("font_color", Color(0.96, 0.88, 0.66))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.anchor_left = 0.5
	label.anchor_right = 0.5
	label.offset_left = -180
	label.offset_right = 180
	label.offset_top = 16
	label.offset_bottom = 50
	add_child(label)
	_label_title = label


func _build_status_bars() -> void:
	var frame := TextureRect.new()
	frame.texture = load("res://assets/ui/hd/panel_wide.png") as Texture2D
	frame.stretch_mode = TextureRect.STRETCH_SCALE
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.anchor_left = 0.0
	frame.anchor_top = 0.0
	frame.offset_left = 8
	frame.offset_top = 8
	frame.offset_right = 348
	frame.offset_bottom = 168
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)

	var box := VBoxContainer.new()
	box.offset_left = 30
	box.offset_top = 26
	box.offset_right = 330
	box.offset_bottom = 156
	box.add_theme_constant_override("separation", 5)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(box)

	var name_label := Label.new()
	name_label.text = "%s · Lv.%d" % [GameState.player_name, GameState.player_level]
	name_label.add_theme_font_size_override("font_size", 15)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.55))
	box.add_child(name_label)

	_hp_bar = ProgressBar.new()
	_hp_bar.max_value = 100
	_hp_bar.value = 100
	_hp_bar.show_percentage = false
	_hp_bar.custom_minimum_size = Vector2(280, 26)
	_hp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hp_bg := StyleBoxFlat.new()
	hp_bg.bg_color = Color(0.05, 0.03, 0.04, 0.9)
	hp_bg.set_corner_radius_all(6)
	_hp_bar.add_theme_stylebox_override("background", hp_bg)
	var hp_fill := StyleBoxFlat.new()
	hp_fill.bg_color = Color(0.82, 0.18, 0.22)
	hp_fill.set_corner_radius_all(6)
	_hp_bar.add_theme_stylebox_override("fill", hp_fill)
	box.add_child(_hp_bar)

	_mp_bar = ProgressBar.new()
	_mp_bar.max_value = 50
	_mp_bar.value = 50
	_mp_bar.show_percentage = false
	_mp_bar.custom_minimum_size = Vector2(280, 18)
	_mp_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mp_bg := StyleBoxFlat.new()
	mp_bg.bg_color = Color(0.03, 0.04, 0.08, 0.9)
	mp_bg.set_corner_radius_all(5)
	_mp_bar.add_theme_stylebox_override("background", mp_bg)
	var mp_fill := StyleBoxFlat.new()
	mp_fill.bg_color = Color(0.16, 0.44, 0.9)
	mp_fill.set_corner_radius_all(5)
	_mp_bar.add_theme_stylebox_override("fill", mp_fill)
	box.add_child(_mp_bar)

	_gold_label = Label.new()
	_gold_label.text = "金币 0"
	_gold_label.add_theme_font_size_override("font_size", 16)
	_gold_label.add_theme_color_override("font_color", Color(0.98, 0.82, 0.35))
	box.add_child(_gold_label)

	_auto_check = CheckButton.new()
	_auto_check.text = "自动战斗"
	_auto_check.button_pressed = true
	_auto_check.add_theme_font_size_override("font_size", 16)
	_auto_check.toggled.connect(_on_auto_toggled)
	box.add_child(_auto_check)


func _build_joystick() -> void:
	var joystick := TouchStick.new()
	joystick.anchor_left = 0.0
	joystick.anchor_top = 1.0
	joystick.anchor_right = 0.0
	joystick.anchor_bottom = 1.0
	joystick.offset_left = 40
	joystick.offset_top = -240
	joystick.offset_right = 240
	joystick.offset_bottom = -40
	joystick.moved.connect(_on_joystick_moved)
	add_child(joystick)


func _build_skills() -> void:
	var icons: Array[String] = [
		"res://assets/ui/hd/icon_attack.png",
		"res://assets/ui/hd/icon_whirlwind.png",
		"res://assets/ui/hd/icon_charge.png",
		"res://assets/ui/hd/icon_thunder.png",
	]
	var rects: Array[Rect2] = [
		Rect2(-176, -176, 152, 152),
		Rect2(-310, -150, 98, 98),
		Rect2(-360, -286, 98, 98),
		Rect2(-196, -344, 98, 98),
	]
	for i in icons.size():
		var button := TextureButton.new()
		button.texture_normal = load(icons[i])
		button.stretch_mode = TextureButton.STRETCH_SCALE
		button.ignore_texture_size = true
		button.anchor_left = 1.0
		button.anchor_top = 1.0
		button.anchor_right = 1.0
		button.anchor_bottom = 1.0
		var r := rects[i]
		button.offset_left = r.position.x
		button.offset_top = r.position.y
		button.offset_right = r.position.x + r.size.x
		button.offset_bottom = r.position.y + r.size.y
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(_on_skill_pressed.bind(i))
		add_child(button)
		_skill_buttons.append(button)


func _build_settings_button() -> void:
	var button := Button.new()
	button.text = "设置"
	button.anchor_left = 1.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = -140
	button.offset_top = 20
	button.offset_right = -24
	button.offset_bottom = 76
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_settings_pressed)
	add_child(button)


func _build_map_button() -> void:
	var button := Button.new()
	button.text = "回主城"
	button.anchor_left = 1.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = -236
	button.offset_top = 20
	button.offset_right = -148
	button.offset_bottom = 76
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_map_button_pressed)
	add_child(button)
	_map_button = button


func _build_character_button() -> void:
	var button := Button.new()
	button.text = "换模"
	button.anchor_left = 1.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = -332
	button.offset_top = 20
	button.offset_right = -244
	button.offset_bottom = 76
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_character_button_pressed)
	add_child(button)
	_character_button = button


func _build_weapon_button() -> void:
	var button := Button.new()
	button.text = "换武"
	button.anchor_left = 1.0
	button.anchor_top = 0.0
	button.anchor_right = 1.0
	button.anchor_bottom = 0.0
	button.offset_left = -428
	button.offset_top = 20
	button.offset_right = -340
	button.offset_bottom = 76
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(_on_weapon_button_pressed)
	add_child(button)
	_weapon_button = button


func _build_inventory() -> void:
	_inventory_button = Button.new()
	_inventory_button.text = "背包"
	_inventory_button.anchor_left = 1.0
	_inventory_button.anchor_top = 0.0
	_inventory_button.anchor_right = 1.0
	_inventory_button.anchor_bottom = 0.0
	_inventory_button.offset_left = -524
	_inventory_button.offset_top = 20
	_inventory_button.offset_right = -436
	_inventory_button.offset_bottom = 76
	_inventory_button.focus_mode = Control.FOCUS_NONE
	_inventory_button.pressed.connect(_on_inventory_pressed)
	add_child(_inventory_button)

	_inventory_panel = PanelContainer.new()
	_inventory_panel.anchor_left = 0.5
	_inventory_panel.anchor_top = 0.5
	_inventory_panel.anchor_right = 0.5
	_inventory_panel.anchor_bottom = 0.5
	_inventory_panel.offset_left = -240
	_inventory_panel.offset_top = -180
	_inventory_panel.offset_right = 240
	_inventory_panel.offset_bottom = 180
	_inventory_panel.visible = false
	add_child(_inventory_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.95)
	style.border_color = Color(0.85, 0.62, 0.18)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_inventory_panel.add_theme_stylebox_override("panel", style)

	_inventory_root = VBoxContainer.new()
	_inventory_root.add_theme_constant_override("separation", 8)
	_inventory_panel.add_child(_inventory_root)

	var title := Label.new()
	title.text = "背包"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	_inventory_root.add_child(title)

	_inventory_list = VBoxContainer.new()
	_inventory_list.add_theme_constant_override("separation", 6)
	_inventory_root.add_child(_inventory_list)

	_inventory_equipped = Label.new()
	_inventory_equipped.text = "已装备：无"
	_inventory_equipped.add_theme_font_size_override("font_size", 18)
	_inventory_root.add_child(_inventory_equipped)

	_equipped_box = HBoxContainer.new()
	_equipped_box.add_theme_constant_override("separation", 8)
	_inventory_root.add_child(_equipped_box)

	_inventory_detail = Label.new()
	_inventory_detail.text = ""
	_inventory_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_inventory_detail.custom_minimum_size = Vector2(430, 90)
	_inventory_root.add_child(_inventory_detail)

	_disenchant_button = Button.new()
	_disenchant_button.text = "分解"
	_disenchant_button.focus_mode = Control.FOCUS_NONE
	_disenchant_button.pressed.connect(_on_disenchant_pressed)
	_disenchant_button.visible = false
	_inventory_root.add_child(_disenchant_button)

	_strengthen_button = Button.new()
	_strengthen_button.text = "强化"
	_strengthen_button.focus_mode = Control.FOCUS_NONE
	_strengthen_button.pressed.connect(_on_strengthen_pressed)
	_strengthen_button.visible = false
	_inventory_root.add_child(_strengthen_button)

	_inventory_close_button = Button.new()
	_inventory_close_button.text = "关闭"
	_inventory_close_button.focus_mode = Control.FOCUS_NONE
	_inventory_close_button.pressed.connect(_on_inventory_pressed)
	_inventory_root.add_child(_inventory_close_button)

	_sort_inventory_button = Button.new()
	_sort_inventory_button.text = "排序"
	_sort_inventory_button.focus_mode = Control.FOCUS_NONE
	_sort_inventory_button.pressed.connect(_on_sort_inventory_pressed)
	_inventory_root.add_child(_sort_inventory_button)


func _build_arena_wave_label() -> void:
	_arena_wave_label = Label.new()
	_arena_wave_label.text = ""
	_arena_wave_label.add_theme_font_size_override("font_size", 24)
	_arena_wave_label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	_arena_wave_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_arena_wave_label.add_theme_constant_override("outline_size", 8)
	_arena_wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_arena_wave_label.anchor_left = 0.5
	_arena_wave_label.anchor_right = 0.5
	_arena_wave_label.offset_left = -200
	_arena_wave_label.offset_right = 200
	_arena_wave_label.offset_top = 88
	_arena_wave_label.offset_bottom = 122
	_arena_wave_label.visible = false
	add_child(_arena_wave_label)


func _build_leaderboard() -> void:
	_leaderboard_button = Button.new()
	_leaderboard_button.text = "榜"
	_leaderboard_button.anchor_left = 1.0
	_leaderboard_button.anchor_top = 0.0
	_leaderboard_button.anchor_right = 1.0
	_leaderboard_button.anchor_bottom = 0.0
	_leaderboard_button.offset_left = -620
	_leaderboard_button.offset_top = 20
	_leaderboard_button.offset_right = -532
	_leaderboard_button.offset_bottom = 76
	_leaderboard_button.focus_mode = Control.FOCUS_NONE
	_leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	add_child(_leaderboard_button)

	_leaderboard_panel = PanelContainer.new()
	_leaderboard_panel.anchor_left = 0.5
	_leaderboard_panel.anchor_top = 0.5
	_leaderboard_panel.anchor_right = 0.5
	_leaderboard_panel.anchor_bottom = 0.5
	_leaderboard_panel.offset_left = -260
	_leaderboard_panel.offset_top = -160
	_leaderboard_panel.offset_right = 260
	_leaderboard_panel.offset_bottom = 160
	_leaderboard_panel.visible = false
	add_child(_leaderboard_panel)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.04, 0.05, 0.07, 0.94)
	style.border_color = Color(0.85, 0.62, 0.18)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	_leaderboard_panel.add_theme_stylebox_override("panel", style)

	var title := Label.new()
	title.text = "本地排行榜"
	title.add_theme_font_size_override("font_size", 24)
	title.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	_leaderboard_panel.add_child(title)

	_leaderboard_list = VBoxContainer.new()
	_leaderboard_list.add_theme_constant_override("separation", 6)
	_leaderboard_panel.add_child(_leaderboard_list)

	_clear_leaderboard_button = Button.new()
	_clear_leaderboard_button.text = "清空记录"
	_clear_leaderboard_button.focus_mode = Control.FOCUS_NONE
	_clear_leaderboard_button.pressed.connect(_on_clear_leaderboard_pressed)
	_leaderboard_panel.add_child(_clear_leaderboard_button)

	_close_leaderboard_button = Button.new()
	_close_leaderboard_button.text = "关闭"
	_close_leaderboard_button.focus_mode = Control.FOCUS_NONE
	_close_leaderboard_button.pressed.connect(_on_leaderboard_pressed)
	_leaderboard_panel.add_child(_close_leaderboard_button)


func _build_toast() -> void:
	_toast = Label.new()
	_toast.text = ""
	_toast.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast.add_theme_font_size_override("font_size", 24)
	_toast.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_toast.add_theme_constant_override("outline_size", 8)
	_toast.anchor_left = 0.5
	_toast.anchor_right = 0.5
	_toast.anchor_top = 1.0
	_toast.anchor_bottom = 1.0
	_toast.offset_left = -320
	_toast.offset_right = 320
	_toast.offset_top = -190
	_toast.offset_bottom = -150
	add_child(_toast)


func _build_zone_prompt() -> void:
	_zone_label = Label.new()
	_zone_label.text = ""
	_zone_label.add_theme_font_size_override("font_size", 20)
	_zone_label.add_theme_color_override("font_color", Color(0.45, 0.95, 0.55))
	_zone_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
	_zone_label.add_theme_constant_override("outline_size", 8)
	_zone_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_zone_label.anchor_left = 0.5
	_zone_label.anchor_right = 0.5
	_zone_label.offset_left = -240
	_zone_label.offset_right = 240
	_zone_label.offset_top = 58
	_zone_label.offset_bottom = 88
	_zone_label.visible = false
	add_child(_zone_label)


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
	add_child(minimap)


func _build_settings_menu() -> void:
	_settings_menu = SettingsMenu.new()
	add_child(_settings_menu)
	_settings_menu.hide()


func _build_npc_interaction() -> void:
	_npc_button = Button.new()
	_npc_button.text = "装备升级"
	_npc_button.anchor_left = 0.5
	_npc_button.anchor_right = 0.5
	_npc_button.anchor_top = 1.0
	_npc_button.anchor_bottom = 1.0
	_npc_button.offset_left = -105
	_npc_button.offset_right = 105
	_npc_button.offset_top = -258
	_npc_button.offset_bottom = -202
	_npc_button.focus_mode = Control.FOCUS_NONE
	_npc_button.visible = false
	_npc_button.pressed.connect(_on_npc_button_pressed)
	add_child(_npc_button)


func _build_upgrade_panel() -> void:
	_upgrade_panel = UpgradePanel.new()
	add_child(_upgrade_panel)
	_upgrade_panel.closed.connect(_on_upgrade_closed)


func _refresh_stats() -> void:
	if _hp_bar:
		_hp_bar.max_value = GameState.max_hp
		_hp_bar.value = GameState.hp
	if _mp_bar:
		_mp_bar.max_value = GameState.max_mp
		_mp_bar.value = GameState.mp
	if _gold_label:
		_gold_label.text = "金币 %d" % GameState.gold


func _update_skills() -> void:
	if _player == null:
		return
	for i in _skill_buttons.size():
		var button := _skill_buttons[i]
		if i == 0:
			button.modulate = Color.WHITE
			continue
		var cooldown: float = 0.0
		if _player.has_method("skill_cooldown"):
			cooldown = float(_player.call("skill_cooldown", i - 1))
		if cooldown > 0.05:
			button.modulate = Color(0.45, 0.45, 0.45)
			button.disabled = true
		else:
			button.modulate = Color.WHITE
			button.disabled = false


func _on_joystick_moved(direction: Vector2) -> void:
	if _player and _player.has_method("set_move_input"):
		_player.set_move_input(direction)


func _on_skill_pressed(index: int) -> void:
	if _player == null:
		return
	if index == 0:
		if _player.has_method("manual_attack"):
			_player.call("manual_attack")
	else:
		if _player.has_method("use_skill"):
			var used: bool = bool(_player.call("use_skill", index - 1))
			if not used:
				_show_toast("冷却中或法力不足", Color(0.95, 0.6, 0.4))


func _on_auto_toggled(on: bool) -> void:
	if _player:
		_player.set("auto_attack", on)


func _on_loot_picked(item: Resource) -> void:
	var typed := item as ItemData
	if typed == null:
		return
	GameState.add_item(typed)
	_refresh_inventory()
	Audio.play_sfx(SFX_LOOT)
	_show_toast("获得 " + typed.full_name(), typed.quality_color())


func _show_toast(text: String, color: Color) -> void:
	_toast.text = text
	_toast.add_theme_color_override("font_color", color)
	_toast.modulate.a = 1.0
	_toast_time = 2.0


func _on_settings_pressed() -> void:
	if _settings_menu.visible:
		_settings_menu.close()
	else:
		_settings_menu.open()


func _on_npc_prompt_changed(text: String, visible: bool) -> void:
	_npc_near = visible
	if _npc_button == null:
		return
	_npc_button.text = text
	_npc_button.visible = visible and not _upgrade_panel.visible


func _on_npc_button_pressed() -> void:
	Events.npc_upgrade_requested.emit()


func _on_upgrade_requested() -> void:
	if _upgrade_panel == null:
		return
	_npc_button.hide()
	_upgrade_panel.open()


func _on_upgrade_closed() -> void:
	if _npc_button and _npc_near:
		_npc_button.show()


func _on_zone_prompt_changed(text: String, visible: bool) -> void:
	if _zone_label == null:
		return
	_zone_label.text = text
	_zone_label.visible = visible


func _on_player_died() -> void:
	if GameState.current_map_id == "MAP_10_ARENA":
		Save.add_arena_score(GameState.arena_best_wave)
		_show_toast("挑战结束 · 最佳波次 %d" % GameState.arena_best_wave, Color(1.0, 0.86, 0.4))


func _on_map_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_city.tscn")


func _on_leaderboard_pressed() -> void:
	if _leaderboard_panel == null:
		return
	if not _leaderboard_panel.visible:
		_leaderboard_panel.visible = true
		Audio.play_sfx(SFX_SUCCESS)
		_refresh_leaderboard()
		_leaderboard_panel.modulate.a = 0.0
		_leaderboard_panel.scale = Vector2(0.92, 0.92)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_leaderboard_panel, "modulate:a", 1.0, 0.18)
		tween.tween_property(_leaderboard_panel, "scale", Vector2.ONE, 0.18)
	else:
		Audio.play_sfx(SFX_FAIL)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_leaderboard_panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(_leaderboard_panel, "scale", Vector2(0.92, 0.92), 0.15)
		tween.chain().tween_callback(func() -> void: _leaderboard_panel.visible = false)


func _refresh_leaderboard() -> void:
	if _leaderboard_list == null:
		return
	for child in _leaderboard_list.get_children():
		child.queue_free()
	if GameState.arena_history.is_empty():
		var empty := Label.new()
		empty.text = "暂无记录"
		empty.add_theme_font_size_override("font_size", 22)
		_leaderboard_list.add_child(empty)
		return
	for i in GameState.arena_history.size():
		var label := Label.new()
		label.text = "%d. 最佳波次 %d" % [i + 1, GameState.arena_history[i]]
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
		_leaderboard_list.add_child(label)


func _on_clear_leaderboard_pressed() -> void:
	Save.clear_arena_history()
	_refresh_leaderboard()
	_show_toast("排行榜已清空", Color(0.95, 0.6, 0.4))


func _on_character_button_pressed() -> void:
	var ids: Array[String] = [
		"CHR_WARRIOR_01",
		"CHR_MAGE_01",
		"CHR_TAOIST_01",
		"CHR_CUSTOM_MALE_01",
	]
	var current := GameState.selected_character_id
	var index := maxi(0, ids.find(current))
	var next_index := (index + 1) % ids.size()
	GameState.selected_character_id = ids[next_index]
	var player := get_tree().get_first_node_in_group("player") as Node
	if player and player.has_method("reload_model"):
		player.call("reload_model")


func _on_weapon_button_pressed() -> void:
	var ids: Array[String] = ["WPN_SWORD_01", "WPN_STAFF_01", "WPN_FAN_01"]
	var current := GameState.selected_weapon_id
	var index := maxi(0, ids.find(current))
	var next_index := (index + 1) % ids.size()
	GameState.selected_weapon_id = ids[next_index]
	var player := get_tree().get_first_node_in_group("player") as Node
	if player and player.has_method("reload_weapon"):
		player.call("reload_weapon")


func _on_inventory_pressed() -> void:
	if _inventory_panel == null:
		return
	if not _inventory_panel.visible:
		_inventory_panel.visible = true
		_refresh_inventory()
		Audio.play_sfx(SFX_SUCCESS)
		_inventory_panel.modulate.a = 0.0
		_inventory_panel.scale = Vector2(0.92, 0.92)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_inventory_panel, "modulate:a", 1.0, 0.18)
		tween.tween_property(_inventory_panel, "scale", Vector2.ONE, 0.18)
	else:
		Audio.play_sfx(SFX_FAIL)
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(_inventory_panel, "modulate:a", 0.0, 0.15)
		tween.tween_property(_inventory_panel, "scale", Vector2(0.92, 0.92), 0.15)
		tween.chain().tween_callback(func() -> void: _inventory_panel.visible = false)


func _on_sort_inventory_pressed() -> void:
	GameState.inventory.sort_custom(func(a: ItemData, b: ItemData) -> bool:
		if a.quality != b.quality:
			return a.quality > b.quality
		return a.tier > b.tier
	)
	Audio.play_sfx(SFX_SUCCESS)
	_refresh_inventory()


func _refresh_inventory() -> void:
	if _inventory_list == null:
		return
	for child in _inventory_list.get_children():
		child.queue_free()
	if GameState.inventory.is_empty():
		var empty := Label.new()
		empty.text = "暂无物品"
		empty.add_theme_font_size_override("font_size", 22)
		_inventory_list.add_child(empty)
		return
	var equipped_lines := PackedStringArray()
	for slot in GameState.equipped:
		var equipped_item: ItemData = GameState.equipped[slot]
		equipped_lines.append("%s：%s" % [slot, equipped_item.display_name])
	_inventory_equipped.text = "已装备：" + (" / ".join(equipped_lines) if equipped_lines.size() > 0 else "无")
	for child in _equipped_box.get_children():
		child.queue_free()
	for slot in GameState.equipped:
		var equipped_item: ItemData = GameState.equipped[slot]
		var icon_rect := TextureRect.new()
		var icon := _icon_for_item(equipped_item)
		if icon:
			icon_rect.texture = icon
			icon_rect.custom_minimum_size = Vector2(32, 32)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.self_modulate = equipped_item.quality_color()
		var equipped_label := Label.new()
		equipped_label.text = equipped_item.display_name
		equipped_label.add_theme_font_size_override("font_size", 14)
		var equipped_row := HBoxContainer.new()
		equipped_row.add_theme_constant_override("separation", 4)
		equipped_row.add_child(icon_rect)
		equipped_row.add_child(equipped_label)
		_equipped_box.add_child(equipped_row)
	for item: ItemData in GameState.inventory:
		var icon_rect: TextureRect
		var icon := _icon_for_item(item)
		if icon:
			icon_rect = TextureRect.new()
			icon_rect.texture = icon
			icon_rect.custom_minimum_size = Vector2(34, 34)
			icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon_rect.self_modulate = item.quality_color()
		var label := Label.new()
		label.text = item.full_name()
		label.add_theme_font_size_override("font_size", 18)
		label.add_theme_color_override("font_color", item.quality_color())
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		if icon_rect:
			row.add_child(icon_rect)
		row.add_child(label)
		var equip_button := Button.new()
		var is_equipped: bool = GameState.equipped.get(item.slot) == item
		equip_button.text = "卸下" if is_equipped else "装备"
		equip_button.disabled = false
		equip_button.focus_mode = Control.FOCUS_NONE
		equip_button.pressed.connect(_on_equip_pressed.bind(item))
		row.add_child(equip_button)
		var detail_button := Button.new()
		detail_button.text = "详情"
		detail_button.focus_mode = Control.FOCUS_NONE
		detail_button.pressed.connect(_on_detail_pressed.bind(item))
		row.add_child(detail_button)
		var panel := PanelContainer.new()
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.0, 0.0, 0.0, 0.16)
		style.border_color = item.quality_color()
		style.set_border_width_all(2)
		style.set_corner_radius_all(6)
		style.content_margin_left = 8
		style.content_margin_right = 8
		style.content_margin_top = 4
		style.content_margin_bottom = 4
		panel.add_theme_stylebox_override("panel", style)
		panel.add_child(row)
		_inventory_list.add_child(panel)


func _icon_for_item(item: ItemData) -> Texture2D:
	var id := item.id.to_lower()
	if "staff" in id:
		return load("res://assets/ui/item_icons/weapon_staff.png") as Texture2D
	if "fan" in id:
		return load("res://assets/ui/item_icons/weapon_fan.png") as Texture2D
	if "sword" in id:
		return load("res://assets/ui/item_icons/weapon_sword.png") as Texture2D
	if item.slot == "armor":
		return load("res://assets/ui/item_icons/armor.png") as Texture2D
	if item.slot == "ring":
		return load("res://assets/ui/item_icons/ring.png") as Texture2D
	return load("res://assets/ui/item_icons/default.png") as Texture2D


func _on_equip_pressed(item: ItemData) -> void:
	if GameState.equipped.get(item.slot) == item:
		GameState.unequip_item(item)
	else:
		GameState.equip_item(item)
	_refresh_inventory()
	Events.player_stats_changed.emit()


func _on_detail_pressed(item: ItemData) -> void:
	if _inventory_detail == null:
		return
	var lines := PackedStringArray()
	lines.append(item.full_name())
	lines.append("部位：%s  等级：%d" % [item.slot, item.required_level])
	if item.attack != 0:
		lines.append("攻击 +%d" % item.attack)
	if item.defense != 0:
		lines.append("防御 +%d" % item.defense)
	for line in item.extra_lines:
		lines.append(line)
	var equipped_item: ItemData = GameState.equipped.get(item.slot) as ItemData
	if equipped_item and equipped_item != item:
		lines.append("")
		lines.append("当前装备：%s" % equipped_item.full_name())
		lines.append("攻击差：%+d  防御差：%+d" % [item.attack - equipped_item.attack, item.defense - equipped_item.defense])
	_inventory_detail.text = "\n".join(lines)
	_detail_item = item
	if _disenchant_button:
		_disenchant_button.visible = true
	if _strengthen_button:
		_strengthen_button.visible = true


func _on_disenchant_pressed() -> void:
	if _detail_item == null:
		return
	if GameState.equipped.get(_detail_item.slot) == _detail_item:
		GameState.unequip_item(_detail_item)
	GameState.inventory.erase(_detail_item)
	GameState.add_gold(10 * _detail_item.tier * maxi(1, _detail_item.quality))
	_detail_item = null
	if _inventory_detail:
		_inventory_detail.text = ""
	if _disenchant_button:
		_disenchant_button.visible = false
	if _strengthen_button:
		_strengthen_button.visible = false
	_refresh_inventory()
	Events.player_stats_changed.emit()


func _on_strengthen_pressed() -> void:
	if _detail_item == null:
		return
	var cost := 100 + _detail_item.enhance_level * 50
	var result := GameState.strengthen_item(_detail_item)
	match result:
		0:
			_show_toast("金币不足", Color(0.95, 0.6, 0.4))
		1:
			_show_toast("强化成功，消耗 %d 金币" % cost, Color(0.45, 0.95, 0.55))
			Audio.play_sfx(SFX_SUCCESS)
			_flash_inventory_panel(Color(0.5, 1.0, 0.55))
			_on_detail_pressed(_detail_item)
			_refresh_inventory()
			Events.player_stats_changed.emit()
		2:
			_show_toast("强化失败，消耗 %d 金币" % cost, Color(0.95, 0.4, 0.35))
			Audio.play_sfx(SFX_FAIL)
			_flash_inventory_panel(Color(1.0, 0.4, 0.35))
			_refresh_inventory()


func _flash_inventory_panel(color: Color) -> void:
	if _inventory_panel == null:
		return
	_inventory_panel.modulate = color
	create_tween().tween_property(_inventory_panel, "modulate", Color.WHITE, 0.18)


func _on_map_changed(map_id: String) -> void:
	if _label_title == null:
		return
	var theme := MapThemes.get_theme(map_id)
	_label_title.text = String(theme.get("name", map_id))
	if _arena_wave_label:
		_arena_wave_label.visible = map_id == "MAP_10_ARENA"


func _update_arena_wave() -> void:
	if _arena_wave_label == null or not _arena_wave_label.visible:
		return
	var spawner := get_tree().get_first_node_in_group("enemy_spawner") as Node
	if spawner and spawner.has_method("arena_wave"):
		var wave := int(spawner.call("arena_wave"))
		_arena_wave_label.text = "波次：%d  最佳：%d" % [wave, GameState.arena_best_wave]


