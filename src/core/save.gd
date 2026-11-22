extends Node
## 存档：user://save.json，带版本号，便于后续迁移。

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func _ready() -> void:
	load_game()


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"character_created": GameState.character_created,
		"player_name": GameState.player_name,
		"selected_class": GameState.selected_class,
		"selected_character_id": GameState.selected_character_id,
		"player_level": GameState.player_level,
		"xp": GameState.xp,
		"xp_to_next": GameState.xp_to_next,
		"gold": GameState.gold,
		"kills": GameState.kills,
		"max_hp": GameState.max_hp,
		"hp": GameState.hp,
		"max_mp": GameState.max_mp,
		"mp": GameState.mp,
		"attack": GameState.attack,
		"defense": GameState.defense,
		"crit_rate": GameState.crit_rate,
		"crit_damage": GameState.crit_damage,
		"riddle_bonus": GameState.riddle_bonus,
		"arena_best_wave": GameState.arena_best_wave,
		"arena_history": GameState.arena_history,
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("存档写入失败：%s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(data, "\t"))


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return
	var data: Dictionary = parsed
	GameState.character_created = bool(data.get("character_created", false))
	GameState.player_name = String(data.get("player_name", "无名侠士"))
	GameState.selected_class = String(data.get("selected_class", "战士"))
	GameState.selected_character_id = String(data.get("selected_character_id", "CHR_WARRIOR_01"))
	GameState.player_level = int(data.get("player_level", 1))
	GameState.xp = int(data.get("xp", 0))
	GameState.xp_to_next = int(data.get("xp_to_next", 100))
	GameState.gold = int(data.get("gold", 0))
	GameState.kills = int(data.get("kills", 0))
	GameState.max_hp = int(data.get("max_hp", 420))
	GameState.hp = int(data.get("hp", GameState.max_hp))
	GameState.max_mp = int(data.get("max_mp", 60))
	GameState.mp = int(data.get("mp", GameState.max_mp))
	GameState.attack = int(data.get("attack", 18))
	GameState.defense = int(data.get("defense", 8))
	GameState.crit_rate = float(data.get("crit_rate", 0.05))
	GameState.crit_damage = float(data.get("crit_damage", 1.5))
	GameState.riddle_bonus = float(data.get("riddle_bonus", 0.0))
	GameState.arena_best_wave = int(data.get("arena_best_wave", 0))
	var history: Variant = data.get("arena_history", [])
	GameState.arena_history.clear()
	if history is Array:
		for value in history:
			GameState.arena_history.append(int(value))


func add_arena_score(wave: int) -> void:
	if wave <= 0:
		return
	GameState.arena_history.append(wave)
	GameState.arena_history.sort()
	GameState.arena_history.reverse()
	if GameState.arena_history.size() > 5:
		GameState.arena_history.resize(5)
	save_game()


func clear_arena_history() -> void:
	GameState.arena_history.clear()
	GameState.arena_best_wave = 0
	save_game()


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))

