class_name ItemData
extends Resource
## 装备数据。占位阶段用程序生成，后续可以换成 data/*.tres。

@export var id: String = ""
@export var display_name: String = ""
@export var slot: String = "weapon"
@export var quality: int = 1
@export var tier: int = 1
@export var required_level: int = 1
@export var attack: int = 0
@export var defense: int = 0
@export var extra_lines: PackedStringArray = []
@export var enhance_level: int = 0

const QUALITY_NAMES: Array[String] = ["白", "绿", "蓝", "紫", "橙", "红", "神话"]
const QUALITY_COLORS: Array[Color] = [
	Color(0.95, 0.95, 0.95),
	Color(0.30, 0.85, 0.39),
	Color(0.23, 0.62, 1.00),
	Color(0.71, 0.36, 1.00),
	Color(1.00, 0.62, 0.04),
	Color(1.00, 0.23, 0.19),
	Color(1.00, 0.84, 0.00),
]


func quality_name() -> String:
	return QUALITY_NAMES[clampi(quality, 0, QUALITY_NAMES.size() - 1)]


func quality_color() -> Color:
	return QUALITY_COLORS[clampi(quality, 0, QUALITY_COLORS.size() - 1)]


func full_name() -> String:
	var suffix := "" if enhance_level <= 0 else " +%d" % enhance_level
	return "T%d [%s] %s%s" % [tier, quality_name(), display_name, suffix]


func can_equip(player_level: int) -> bool:
	return player_level >= required_level

