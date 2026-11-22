extends Node3D
## 地图刷怪：从 data/map_layouts.json 读取点位与数量。
## 当前怪物模型仍是占位体，名字沿用旧占位名，后续按 map_id 接正式模型。

const LEVEL := 3
const MAP_ID := "MAP_01_ASHEN_YARD"
const LAYOUT_PATH := "res://data/map_layouts.json"

@export var map_id := MAP_ID

var _spawn_defs: Array[Dictionary] = []
var _kind_rects: Dictionary = {}
var _kind_names: Dictionary = {}
var _kind_models: Dictionary = {}
var _has_layout := false
var _arena_wave := 0
var _arena_timer: Timer


func _ready() -> void:
	add_to_group("enemy_spawner")
	Events.enemy_died.connect(_on_enemy_died)
	Events.map_changed.connect(reload)
	if map_id.is_empty() or map_id == MAP_ID:
		map_id = GameState.current_map_id
	if map_id.is_empty():
		map_id = MAP_ID
	_load_spawn_defs()
	if not _has_layout:
		_spawn_fallback()
		return
	if _spawn_defs.is_empty():
		return
	for spawn_def in _spawn_defs:
		var kind := _kind_for(String(spawn_def.get("kind", "")))
		for i in int(spawn_def.get("count", 0)):
			_spawn(kind, _point_in_rect(spawn_def.get("rect", [])), String(spawn_def.get("name", "")))
	_setup_arena()


func arena_wave() -> int:
	return _arena_wave


func _load_spawn_defs() -> void:
	if not FileAccess.file_exists(LAYOUT_PATH):
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	if not parsed is Dictionary:
		return
	var maps: Variant = (parsed as Dictionary).get("maps", {})
	if not maps is Dictionary:
		return
	var map_data: Variant = maps.get(map_id, {})
	if not map_data is Dictionary:
		return
	_has_layout = true
	for spawn_value in map_data.get("spawns", []):
		if not spawn_value is Dictionary:
			continue
		var spawn_def := spawn_value as Dictionary
		_spawn_defs.append(spawn_def)
		var kind := _kind_for(String(spawn_def.get("kind", "")))
		if not _kind_rects.has(kind):
			_kind_rects[kind] = []
		_kind_rects[kind].append(spawn_def.get("rect", []))
		_kind_names[kind] = String(spawn_def.get("name", ""))
		if String(spawn_def.get("model", "")) != "":
			_kind_models[kind] = String(spawn_def.get("model", ""))


func _spawn_fallback() -> void:
	for i in 5:
		_spawn(Enemy.Kind.PIG, Vector3(cos(float(i) * 1.15) * 8.0, 0.0, sin(float(i) * 1.15) * 8.0))
	for i in 3:
		_spawn(Enemy.Kind.ARCHER, Vector3(cos(float(i) * 1.9 + 1.0) * 9.0, 0.0, sin(float(i) * 1.9 + 1.0) * 9.0))


func _kind_for(kind_name: String) -> int:
	match kind_name:
		"thin_wolf", "archer", "dark_archer", "ice_mage", "water_mage", "blood_guard", "thunder_bird", "wraith":
			return Enemy.Kind.ARCHER
		"bomb_bug", "spore_bomb", "fire_bug", "succubus", "necromancer":
			return Enemy.Kind.BUG
		"sand_rat_king", "bull_elite", "corrupted_elite", "heavy_guard", "frost_troll", "fire_hound", "reaper", "stone_guard", "storm_priest", "crab_general", "turtle_elite", "abyss_lord":
			return Enemy.Kind.ELITE
		"sandworm", "tree_demon", "frost_dragon", "lava_demon", "ghost_king", "thunder_peng", "dragon_king", "demon_emperor":
			return Enemy.Kind.BOSS
		_:
			return Enemy.Kind.PIG


func _point_in_rect(value: Variant) -> Vector3:
	if not value is Array or value.size() < 4:
		return Vector3.ZERO
	var rect := value as Array
	var x := float(rect[0]) + randf_range(0.0, float(rect[2]))
	var z := float(rect[1]) + randf_range(0.0, float(rect[3]))
	return Vector3(x, 0.0, z)


func _spawn(kind: int, position_value: Vector3, display_name: String = "") -> void:
	var enemy := Enemy.new()
	enemy.setup(kind, LEVEL, map_id, display_name, String(_kind_models.get(kind, "")))
	enemy.position = position_value
	add_child(enemy)


func _on_enemy_died(enemy: Node) -> void:
	var typed := enemy as Enemy
	if typed == null:
		return
	var delay := 30.0 if typed.is_boss else _interval_for(typed.kind)
	get_tree().create_timer(delay).timeout.connect(_respawn.bind(typed.kind))


func _interval_for(kind: int) -> float:
	for spawn_def in _spawn_defs:
		if _kind_for(String(spawn_def.get("kind", ""))) == kind:
			return float(spawn_def.get("interval", 7.0))
	return 7.0


func _respawn(kind: int) -> void:
	var rects: Array = _kind_rects.get(kind, [])
	if rects.is_empty():
		_spawn(kind, Vector3(randf_range(-4.0, 4.0), 0.0, randf_range(-4.0, 4.0)))
		return
	_spawn(kind, _point_in_rect(rects[randi_range(0, rects.size() - 1)]), String(_kind_names.get(kind, "")))


func _setup_arena() -> void:
	if map_id != "MAP_10_ARENA":
		if _arena_timer:
			_arena_timer.stop()
		return
	if _arena_timer == null:
		_arena_timer = Timer.new()
		_arena_timer.one_shot = false
		_arena_timer.wait_time = 30.0
		_arena_timer.timeout.connect(_on_arena_wave_timeout)
		add_child(_arena_timer)
	_arena_wave = 0
	_arena_timer.start()


func _on_arena_wave_timeout() -> void:
	_arena_wave += 1
	if _arena_wave > GameState.arena_best_wave:
		GameState.arena_best_wave = _arena_wave
		Save.save_game()
	if _arena_wave % 5 == 0:
		GameState.add_gold(100)
		var boss := Enemy.new()
		boss.setup(Enemy.Kind.BOSS, LEVEL, map_id, "竞技场BOSS", "BOSS_DEMON_EMPEROR_01")
		boss.position = Vector3.ZERO
		add_child(boss)
		return
	GameState.add_gold(20 * _arena_wave)
	for i in 4 + _arena_wave:
		var kind := Enemy.Kind.PIG if i % 2 == 0 else Enemy.Kind.ARCHER
		_spawn(kind, Vector3(randf_range(-18.0, 18.0), 0.0, randf_range(-18.0, 18.0)), "竞技场怪物")


func reload(new_map_id: String) -> void:
	map_id = new_map_id
	for child in get_children():
		child.queue_free()
	_spawn_defs.clear()
	_kind_rects.clear()
	_kind_names.clear()
	_has_layout = false
	_load_spawn_defs()
	if not _has_layout:
		_spawn_fallback()
		return
	for spawn_def in _spawn_defs:
		var kind := _kind_for(String(spawn_def.get("kind", "")))
		for i in int(spawn_def.get("count", 0)):
			_spawn(kind, _point_in_rect(spawn_def.get("rect", [])), String(spawn_def.get("name", "")))
	_setup_arena()
