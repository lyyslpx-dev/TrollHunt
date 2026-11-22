extends Node
## 地图主题库：读取 data/map_themes.json，创建地面材质并应用到场景。
## 布局概念图只用于取样和配色，运行时不直接使用等距渲染图。

const THEME_PATH := "res://data/map_themes.json"

var _themes: Dictionary = {}
var _default_map_id := ""


func _ready() -> void:
	_load_themes()


func _load_themes() -> void:
	if not FileAccess.file_exists(THEME_PATH):
		push_warning("地图主题缺失：%s" % THEME_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(THEME_PATH))
	if not parsed is Dictionary:
		push_warning("地图主题 JSON 格式错误：%s" % THEME_PATH)
		return
	var data := parsed as Dictionary
	_default_map_id = String(data.get("default_map", ""))
	var themes: Variant = data.get("themes", {})
	if themes is Dictionary:
		_themes = themes


func default_map_id() -> String:
	if _default_map_id.is_empty() and not _themes.is_empty():
		return String(_themes.keys()[0])
	return _default_map_id


func get_theme(map_id: String) -> Dictionary:
	var theme: Variant = _themes.get(map_id, {})
	if theme is Dictionary:
		return theme
	return {}


func get_map_ids() -> PackedStringArray:
	var ids: Array = _themes.keys()
	ids.sort_custom(func(a: String, b: String) -> bool:
		return int(_themes[a].get("index", 0)) < int(_themes[b].get("index", 0))
	)
	return PackedStringArray(ids)


func get_ground_path(map_id: String, variant: String = "a") -> String:
	var theme := get_theme(map_id)
	if theme.is_empty():
		return ""
	var ground: Dictionary = theme.get("ground", {})
	return String(ground.get("tile_%s" % variant, ""))


func apply_ground_to(mesh: MeshInstance3D, map_id: String, variant: String = "a") -> bool:
	if mesh == null or mesh.mesh == null:
		return false
	var theme := get_theme(map_id)
	if theme.is_empty():
		push_warning("未知地图主题：%s" % map_id)
		return false
	var ground: Dictionary = theme.get("ground", {})
	var texture_path := get_ground_path(map_id, variant)
	if texture_path.is_empty() or not ResourceLoader.exists(texture_path):
		push_warning("地面材质缺失：%s" % texture_path)
		return false

	var aabb := mesh.mesh.get_aabb()
	var meters_per_tile := maxf(float(ground.get("meters_per_tile", 2.0)), 0.25)

	var shader := Shader.new()
	shader.code = """
shader_type spatial;
uniform sampler2D tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float tiles_x = 1.0;
uniform float tiles_y = 1.0;
uniform float rough = 0.92;
void fragment() {
	ALBEDO = texture(tex, UV * vec2(tiles_x, tiles_y)).rgb;
	ROUGHNESS = rough;
}
"""
	var material := ShaderMaterial.new()
	material.shader = shader
	material.set_shader_parameter("tex", load(texture_path))
	material.set_shader_parameter("tiles_x", maxf(aabb.size.x, 1.0) / meters_per_tile)
	material.set_shader_parameter("tiles_y", maxf(aabb.size.z, 1.0) / meters_per_tile)
	material.set_shader_parameter("rough", float(ground.get("roughness", 0.92)))
	mesh.material_override = material
	return true


func color_from(theme: Dictionary, section: String, key: String, fallback: Color) -> Color:
	var data: Dictionary = theme.get(section, {})
	return Color.from_string(String(data.get(key, "")), fallback)
