extends Node
## 当前局内与玩家数据。真正的计算逻辑放 gameplay，这里只存状态。

const VALID_CHARACTER_IDS := [
	"CHR_PHOTO_07", "CHR_PHOTO_01", "CHR_PHOTO_02", "CHR_PHOTO_03",
	"CHR_PHOTO_04", "CHR_PHOTO_05", "CHR_PHOTO_06", "CHR_PHOTO_08",
	"CHR_WARRIOR_01",
]
const DEFAULT_CHARACTER_ID := "CHR_PHOTO_07"

var player_level: int = 1
var player_name: String = "无名侠士"
var selected_class: String = "战士"
var character_created: bool = false
var gold: int = 0
var kills: int = 0
var revival_count: int = 0
var selected_character_id: String = DEFAULT_CHARACTER_ID
var current_map_id: String = "MAP_01_ASHEN_YARD"
var selected_weapon_id: String = "WPN_SWORD_01"
var inventory: Array[ItemData] = []
var equipped: Dictionary = {}
var arena_best_wave: int = 0
var arena_history: Array[int] = []
var xp: int = 0
var xp_to_next: int = 100
var riddle_bonus: float = 0.0
var riddle_date: String = ""
var riddle_answered_today: int = 0

var max_hp: int = 420
var hp: int = 420
var max_mp: int = 60
var mp: int = 60
var attack: int = 18
var defense: int = 8
var crit_rate: float = 0.05
var crit_damage: float = 1.5


func add_xp(amount: int) -> void:
	xp += maxi(0, amount)
	while xp >= xp_to_next:
		xp -= xp_to_next
		level_up()


func level_up() -> void:
	player_level += 1
	xp_to_next = 80 + player_level * 60
	max_hp += 40
	max_mp += 8
	attack += 4
	defense += 2
	hp = max_hp
	mp = max_mp
	Events.player_stats_changed.emit()
	Save.save_game()


func apply_riddle_result(correct: bool) -> void:
	riddle_bonus = clampf(riddle_bonus + (0.01 if correct else -0.01), -0.03, 0.03)
	Events.player_stats_changed.emit()
	Save.save_game()


func reset_run() -> void:
	hp = max_hp
	mp = max_mp
	kills = 0
	revival_count = 0


func sanitize_character_id() -> void:
	if not VALID_CHARACTER_IDS.has(selected_character_id):
		selected_character_id = DEFAULT_CHARACTER_ID


func add_gold(amount: int) -> void:
	gold = maxi(0, gold + amount)


func add_kill() -> void:
	kills += 1


func add_item(item: ItemData) -> void:
	inventory.append(item)


func equip_item(item: ItemData) -> void:
	if equipped.has(item.slot):
		unequip_item(equipped[item.slot])
	equipped[item.slot] = item
	attack += item.attack
	defense += item.defense
	Save.save_game()


func unequip_item(item: ItemData) -> void:
	if item == null:
		return
	if equipped.get(item.slot) == item:
		equipped.erase(item.slot)
	attack = maxi(0, attack - item.attack)
	defense = maxi(0, defense - item.defense)
	Save.save_game()


func strengthen_item(item: ItemData) -> int:
	if item == null:
		return 0
	var cost := 100 + item.enhance_level * 50
	if gold < cost:
		return 0
	gold -= cost
	var success_rate := clampf(0.92 - float(item.enhance_level) * 0.05, 0.35, 0.95)
	if randf() > success_rate:
		return 2
	item.enhance_level += 1
	item.attack += 1
	item.defense += 1
	if equipped.get(item.slot) == item:
		unequip_item(item)
		equip_item(item)
	Save.save_game()
	return 1

