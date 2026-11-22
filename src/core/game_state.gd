extends Node
## 当前局内与玩家数据。真正的计算逻辑放 gameplay，这里只存状态。

var player_level: int = 1
var gold: int = 0
var kills: int = 0
var revival_count: int = 0
var selected_character_id: String = "CHR_WARRIOR_01"
var current_map_id: String = "MAP_01_ASHEN_YARD"
var selected_weapon_id: String = "WPN_SWORD_01"
var inventory: Array[ItemData] = []
var equipped: Dictionary = {}
var arena_best_wave: int = 0
var arena_history: Array[int] = []

var max_hp: int = 100
var hp: int = 100
var max_mp: int = 50
var mp: int = 50
var attack: int = 12
var defense: int = 4
var crit_rate: float = 0.05
var crit_damage: float = 1.5


func reset_run() -> void:
	hp = max_hp
	mp = max_mp
	kills = 0
	revival_count = 0


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


func unequip_item(item: ItemData) -> void:
	if item == null:
		return
	if equipped.get(item.slot) == item:
		equipped.erase(item.slot)
	attack = maxi(0, attack - item.attack)
	defense = maxi(0, defense - item.defense)


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
	return 1

