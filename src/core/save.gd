extends Node
## 存档：user://save.json，带版本号，便于后续迁移。

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func _ready() -> void:
	load_game()


func save_game() -> void:
	var data := {
		"version": SAVE_VERSION,
		"player_level": GameState.player_level,
		"gold": GameState.gold,
		"kills": GameState.kills,
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
	GameState.player_level = int(data.get("player_level", 1))
	GameState.gold = int(data.get("gold", 0))
	GameState.kills = int(data.get("kills", 0))
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

