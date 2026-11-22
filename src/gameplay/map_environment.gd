extends Node3D
## 把地图主题套到主场景的地面、环境光和方向光。

@export var map_id := "MAP_01_ASHEN_YARD"


func _ready() -> void:
	Events.map_changed.connect(apply_theme)
	if map_id.is_empty():
		map_id = MapThemes.default_map_id()
	apply_theme(map_id)


func apply_theme(id: String) -> void:
	var theme := MapThemes.get_theme(id)
	if theme.is_empty():
		push_warning("无法应用地图主题：%s" % id)
		return
	map_id = id

	var primary := get_node_or_null("Ground/Mesh") as MeshInstance3D
	if primary:
		MapThemes.apply_ground_to(primary, id, "a")
	var secondary := get_node_or_null("Ground/PathMesh") as MeshInstance3D
	if secondary:
		MapThemes.apply_ground_to(secondary, id, "b")

	var world_env := get_tree().get_first_node_in_group("world_env") as WorldEnvironment
	if world_env and world_env.environment:
		var environment := world_env.environment.duplicate() as Environment
		var lighting: Dictionary = theme.get("lighting", {})
		environment.background_color = Color.from_string(
			String(lighting.get("background_color", "")),
			environment.background_color
		)
		environment.ambient_light_color = Color.from_string(
			String(lighting.get("ambient_color", "")),
			environment.ambient_light_color
		)
		environment.ambient_light_energy = float(
			lighting.get("ambient_energy", environment.ambient_light_energy)
		)
		world_env.environment = environment

	var sun := get_tree().get_first_node_in_group("sun") as DirectionalLight3D
	if sun:
		var lighting: Dictionary = theme.get("lighting", {})
		sun.light_color = Color.from_string(
			String(lighting.get("sun_color", "")),
			sun.light_color
		)
		sun.light_energy = float(lighting.get("sun_energy", sun.light_energy))
