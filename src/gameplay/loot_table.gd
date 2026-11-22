class_name LootTable
extends RefCounted
## 占位掉落表。品质权重与 GDD 对齐，后续可替换为 data/*.tres。

const SLOT_LABELS := {
	"weapon": "武器",
	"armor": "衣服",
	"helmet": "头盔",
	"necklace": "项链",
	"bracelet": "手镯",
	"ring": "戒指",
	"belt": "腰带",
	"boots": "鞋子",
}

const BASE_NAMES := {
	"weapon": ["铁剑", "长刀", "战斧", "破军刃"],
	"armor": ["布甲", "锁子甲", "战神铠"],
	"helmet": ["皮帽", "铁盔", "龙纹盔"],
	"necklace": ["兽牙链", "星辰坠"],
	"bracelet": ["铜环", "雷纹镯"],
	"ring": ["古戒", "血玉戒"],
	"belt": ["麻绳带", "虎纹腰带"],
	"boots": ["草鞋", "疾风靴"],
}

const PREFIXES: Array[String] = ["", "精铁", "玄铁", "赤焰", "寒霜", "雷霆", "灭世"]

const DROP_TABLE_PATH := "res://data/drop_tables.json"
const DEFAULT_MAP_ID := "MAP_01_ASHEN_YARD"
const SLOT_ORDER: Array[String] = ["weapon", "armor", "helmet", "necklace", "bracelet", "ring", "belt", "boots"]
const SLOT_WEIGHTS: Array[float] = [14.0, 20.0, 15.0, 10.0, 9.0, 9.0, 9.0, 14.0]

static var _drop_data: Dictionary = {}


static func map_profile(map_id: String) -> Dictionary:
	_ensure_loaded()
	var maps: Dictionary = _drop_data.get("maps", {})
	return maps.get(map_id, maps.get(DEFAULT_MAP_ID, {}))


static func required_level_for_tier(tier: int) -> int:
	_ensure_loaded()
	var levels: Array = _drop_data.get("tier_start_levels", [1, 10, 20, 30, 50])
	return int(levels[clampi(tier - 1, 0, levels.size() - 1)])


static func drop_chance(map_id: String, source: String) -> float:
	var profile := map_profile(map_id)
	return float(profile.get(source + "_chance", 0.0))


static func boss_item_count(map_id: String) -> int:
	return int(map_profile(map_id).get("boss_items", 0))


static func roll_item(map_id: String, source: String = "normal", min_quality: int = 0) -> ItemData:
	var profile := map_profile(map_id)
	var tier := int(profile.get("tier", 1))
	var weights_by_source: Dictionary = profile.get("weights", {})
	var weights: Array = weights_by_source.get(source, [0, 0, 0, 0, 0, 0, 0])
	var item := ItemData.new()
	var quality := _roll_quality(weights, min_quality)
	var slot := _roll_slot()
	var names: Array = BASE_NAMES[slot]
	var base_name: String = names.pick_random()
	var prefix: String = PREFIXES[clampi(quality, 0, PREFIXES.size() - 1)]

	item.id = "T%d_%s_%d_%d" % [tier, slot, quality, randi_range(1000, 9999)]
	item.slot = slot
	item.quality = quality
	item.tier = tier
	item.required_level = required_level_for_tier(tier)
	item.display_name = (prefix + base_name) if prefix != "" else base_name

	var scale := 1.0 + float(quality) * 0.6 + float(item.required_level) * 0.15 + float(tier - 1) * 0.4
	if slot == "weapon":
		item.attack = roundi(8.0 * scale)
		item.defense = roundi(2.0 * scale)
	else:
		item.attack = roundi(2.0 * scale)
		item.defense = roundi(6.0 * scale)

	var lines: PackedStringArray = []
	if quality >= 2:
		lines.append("暴击率 +%d%%" % (quality * 2))
	if quality >= 3:
		lines.append("暴击伤害 +%d%%" % (quality * 8))
	if quality >= 4:
		lines.append("吸血 +%d%%" % (quality * 2))
	if quality >= 5:
		lines.append("切割 +%d" % (quality * 50))
	if quality >= 6:
		lines.append("全属性 +%d%%" % (quality * 4))
	item.extra_lines = lines
	return item


static func _ensure_loaded() -> void:
	if not _drop_data.is_empty():
		return
	if not FileAccess.file_exists(DROP_TABLE_PATH):
		push_warning("掉落表缺失：%s" % DROP_TABLE_PATH)
		return
	var file := FileAccess.open(DROP_TABLE_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		_drop_data = parsed


static func _roll_slot() -> String:
	var total := 0.0
	for weight in SLOT_WEIGHTS:
		total += weight
	var pick := randf() * total
	var acc := 0.0
	for i in SLOT_WEIGHTS.size():
		acc += SLOT_WEIGHTS[i]
		if pick <= acc:
			return SLOT_ORDER[i]
	return SLOT_ORDER[0]


static func _roll_quality(weights: Array, min_quality: int) -> int:
	var total := 0.0
	for i in weights.size():
		if i >= min_quality:
			total += weights[i]
	if total <= 0.0:
		return clampi(min_quality, 0, ItemData.QUALITY_NAMES.size() - 1)
	var pick := randf() * total
	var acc := 0.0
	for i in weights.size():
		if i < min_quality:
			continue
		acc += weights[i]
		if pick <= acc:
			return i
	return clampi(min_quality, 0, ItemData.QUALITY_NAMES.size() - 1)

