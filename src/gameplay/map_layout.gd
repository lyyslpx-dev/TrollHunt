extends Node3D
## 运行时地图白盒：从 data/map_layouts.json 铺地面、道路、危险区、安全区和道具。

const LAYOUT_PATH := "res://data/map_layouts.json"
const FONT_PATH := "res://assets/fonts/NotoSansSC-Regular.otf"

@export var map_id := ""

var _layout: Dictionary = {}
var _player: Node3D
var _safe_count := 0


func _ready() -> void:
	add_to_group("map_layout")
	if map_id.is_empty():
		map_id = GameState.current_map_id
	if map_id.is_empty():
		map_id = "MAP_01_ASHEN_YARD"
	_load_layout()
	_build_map()
	_connect_zone_signals.call_deferred()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index := _map_index_for(event.keycode)
		if index >= 0:
			var ids := MapThemes.get_map_ids()
			if index < ids.size():
				switch_map(ids[index])


func switch_map(new_map_id: String) -> void:
	if new_map_id == map_id:
		return
	for child in get_children():
		child.free()
	map_id = new_map_id
	GameState.current_map_id = new_map_id
	_load_layout()
	_build_map()
	_place_actors()
	_connect_zone_signals.call_deferred()
	Events.map_changed.emit(new_map_id)


func _map_index_for(keycode: int) -> int:
	if keycode >= KEY_1 and keycode <= KEY_9:
		return keycode - KEY_1
	if keycode == KEY_0:
		return 9
	return -1


func _load_layout() -> void:
	if not FileAccess.file_exists(LAYOUT_PATH):
		push_warning("地图布局缺失：%s" % LAYOUT_PATH)
		return
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LAYOUT_PATH))
	if not parsed is Dictionary:
		return
	var maps: Variant = (parsed as Dictionary).get("maps", {})
	if maps is Dictionary:
		var map_data: Variant = maps.get(map_id, {})
		if map_data is Dictionary:
			_layout = map_data


func player_spawn() -> Vector3:
	var point := _point_from(_layout.get("player_spawn", [0, 0]))
	return Vector3(point.x, 0.9, point.z)


func _build_map() -> void:
	if _layout.is_empty():
		return
	_build_field()
	_build_zones()
	_build_paths()
	_build_border()
	_build_props()


func _build_field() -> void:
	var field: Dictionary = _layout.get("field", {})
	var rect := _rect_array(field.get("rect", [-50, -50, 100, 100]))
	var variant := String(field.get("variant", "a"))
	_add_ground_plane(rect, variant, 0.02)
	_add_ground_collision(rect)


func _build_zones() -> void:
	for zone_value in _layout.get("zones", []):
		var zone: Dictionary = zone_value
		var rect := _rect_array(zone.get("rect", [0, 0, 10, 10]))
		var variant := String(zone.get("variant", "a"))
		if variant == "hazard":
			_add_hazard_plane(rect)
		elif bool(zone.get("safe", false)):
			_add_ground_plane(rect, "b", 0.025)
			_add_safe_zone(rect)
		elif variant != String(_layout.get("field", {}).get("variant", "a")):
			_add_ground_plane(rect, variant, 0.03)
		_add_zone_label(zone, rect)


func _build_paths() -> void:
	for path_value in _layout.get("paths", []):
		var path: Dictionary = path_value
		var points: Array = path.get("points", [])
		if points.size() < 2:
			continue
		for i in range(points.size() - 1):
			var start := _point_from(points[i])
			var end := _point_from(points[i + 1])
			_add_path_segment(start, end, float(path.get("width", 3.0)))


func _build_border() -> void:
	var half := _half_size()
	var height := 2.2
	var thickness := 2.0
	_add_wall(Vector3(0, 0, half + 1), Vector2(half * 2 + 4, thickness), height)
	_add_wall(Vector3(0, 0, -half - 1), Vector2(half * 2 + 4, thickness), height)
	_add_wall(Vector3(half + 1, 0, 0), Vector2(thickness, half * 2 + 4), height)
	_add_wall(Vector3(-half - 1, 0, 0), Vector2(thickness, half * 2 + 4), height)


func _build_props() -> void:
	for prop_value in _layout.get("props", []):
		var prop: Dictionary = prop_value
		var position_value := _point_from(prop.get("pos", [0, 0]))
		var yaw := float(prop.get("yaw", 0.0))
		_add_prop(String(prop.get("type", "")), Vector3(position_value.x, 0.0, position_value.z), yaw)


func _add_ground_plane(rect: Array, variant: String, y: float) -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(float(rect[2]), float(rect[3]))
	var node := MeshInstance3D.new()
	node.name = "Ground_%s_%s" % [variant, randi()]
	node.mesh = mesh
	node.position = Vector3(_center_x(rect), y, _center_z(rect))
	add_child(node)
	MapThemes.apply_ground_to(node, map_id, variant)


func _add_ground_collision(rect: Array) -> void:
	var body := StaticBody3D.new()
	body.name = "GroundCollision"
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(rect[2]), 0.3, float(rect[3]))
	shape.shape = box
	shape.position = Vector3(_center_x(rect), 0.0, _center_z(rect))
	body.add_child(shape)
	add_child(body)


func _add_path_segment(start: Vector3, end: Vector3, width: float) -> void:
	var direction := end - start
	var length := direction.length()
	if length < 0.01:
		return
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(length, width)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = (start + end) * 0.5
	node.position.y = 0.035
	node.rotation.y = atan2(direction.z, direction.x)
	add_child(node)
	MapThemes.apply_ground_to(node, map_id, "b")


func _add_hazard_plane(rect: Array) -> void:
	var theme := MapThemes.get_theme(map_id)
	var hazard: Dictionary = theme.get("hazard", {})
	var color := Color.from_string(String(hazard.get("color", "#ff5500")), Color(1.0, 0.4, 0.1))
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = Color(color.r, color.g, color.b, 0.42)

	var mesh := PlaneMesh.new()
	mesh.size = Vector2(float(rect[2]), float(rect[3]))
	var node := MeshInstance3D.new()
	node.name = "Hazard"
	node.mesh = mesh
	node.material_override = material
	node.position = Vector3(_center_x(rect), 0.05, _center_z(rect))
	add_child(node)

	var area := Area3D.new()
	area.name = "HazardArea"
	area.add_to_group("hazard")
	area.position = node.position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(rect[2]), 0.5, float(rect[3]))
	shape.shape = box
	area.add_child(shape)
	add_child(area)


func _add_safe_zone(rect: Array) -> void:
	var marker := Node3D.new()
	marker.name = "SafeZone"
	marker.position = Vector3(_center_x(rect), 0.0, _center_z(rect))
	marker.add_to_group("safe_zone")
	var radius := maxf(float(rect[2]), float(rect[3])) * 0.5 + 1.5
	marker.set_meta("radius", radius)
	add_child(marker)

	var area := Area3D.new()
	area.name = "SafeZoneArea"
	area.add_to_group("safe_zone_area")
	area.position = marker.position
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(float(rect[2]), 0.8, float(rect[3]))
	shape.shape = box
	area.add_child(shape)
	add_child(area)


func _add_zone_label(zone: Dictionary, rect: Array) -> void:
	var font := load(FONT_PATH) as Font
	if font == null:
		return
	var label := Label3D.new()
	label.text = String(zone.get("name", ""))
	label.font = font
	label.font_size = 52
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(0.98, 0.88, 0.62, 0.9)
	label.position = Vector3(_center_x(rect), 0.85, _center_z(rect))
	add_child(label)


func _add_wall(position_value: Vector3, footprint: Vector2, height: float) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(footprint.x, height, footprint.y)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.position = Vector3(position_value.x, height * 0.5, position_value.z)
	add_child(node)
	MapThemes.apply_ground_to(node, map_id, "b")

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(footprint.x, height, footprint.y)
	shape.shape = box
	shape.position = Vector3(position_value.x, height * 0.5, position_value.z)
	body.add_child(shape)
	add_child(body)


func _connect_zone_signals() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D
	for node in get_tree().get_nodes_in_group("hazard"):
		var area := node as Area3D
		if area == null:
			continue
		area.body_entered.connect(_on_hazard_body_entered)
		area.body_exited.connect(_on_hazard_body_exited)
	for node in get_tree().get_nodes_in_group("safe_zone_area"):
		var area := node as Area3D
		if area == null:
			continue
		area.body_entered.connect(_on_safe_body_entered)
		area.body_exited.connect(_on_safe_body_exited)


func _place_actors() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = player_spawn()
	var npc := get_tree().get_first_node_in_group("upgrade_npc") as Node3D
	if npc:
		npc.global_position = _safe_zone_position()


func _safe_zone_position() -> Vector3:
	for zone_value in _layout.get("zones", []):
		var zone: Dictionary = zone_value
		if bool(zone.get("safe", false)):
			var rect := _rect_array(zone.get("rect", [0, 0, 10, 10]))
			return Vector3(_center_x(rect), 0.0, _center_z(rect))
	return Vector3.ZERO


func _on_hazard_body_entered(body: Node3D) -> void:
	if body == _player and _player and _player.has_method("enter_hazard"):
		_player.enter_hazard()


func _on_hazard_body_exited(body: Node3D) -> void:
	if body == _player and _player and _player.has_method("exit_hazard"):
		_player.exit_hazard()


func _on_safe_body_entered(body: Node3D) -> void:
	if body != _player:
		return
	_safe_count += 1
	if _safe_count == 1:
		Events.zone_prompt_changed.emit("安全区 · 出生营地", true)


func _on_safe_body_exited(body: Node3D) -> void:
	if body != _player:
		return
	_safe_count = maxi(0, _safe_count - 1)
	if _safe_count == 0:
		Events.zone_prompt_changed.emit("", false)


func _add_prop(type: String, position_value: Vector3, yaw: float) -> void:
	var parent := Node3D.new()
	parent.position = position_value
	parent.rotation.y = yaw
	add_child(parent)

	if type == "house" or type == "cart":
		var prop_id := "ENV_HOUSE_01" if type == "house" else "ENV_CART_01"
		var prop_model := AssetLibrary.instantiate(prop_id)
		if prop_model:
			parent.add_child(prop_model)
			return

	var material := StandardMaterial3D.new()
	material.roughness = 0.9
	match type:
		"campfire":
			var stone := StandardMaterial3D.new()
			stone.albedo_color = Color(0.22, 0.21, 0.20)
			stone.roughness = 0.95
			_add_box(parent, Vector3(1.0, 0.18, 1.0), Vector3(0, 0.09, 0), stone)
			var fire := StandardMaterial3D.new()
			fire.albedo_color = Color(1.0, 0.45, 0.08)
			fire.emission_enabled = true
			fire.emission = Color(1.0, 0.32, 0.04)
			_add_box(parent, Vector3(0.34, 0.62, 0.34), Vector3(0, 0.45, 0), fire)
		"tent":
			material.albedo_color = Color(0.62, 0.47, 0.28)
			_add_box(parent, Vector3(2.2, 1.4, 1.4), Vector3(0, 0.7, 0), material)
		"dead_tree":
			material.albedo_color = Color(0.20, 0.14, 0.10)
			_add_cylinder(parent, 0.18, 0.18, 2.0, Vector3(0, 1.0, 0), material)
			var branch := StandardMaterial3D.new()
			branch.albedo_color = Color(0.16, 0.11, 0.08)
			_add_box(parent, Vector3(1.0, 0.14, 0.14), Vector3(0.4, 1.7, 0), branch)
		"cart":
			material.albedo_color = Color(0.38, 0.24, 0.15)
			_add_box(parent, Vector3(1.6, 0.8, 1.0), Vector3(0, 0.4, 0), material)
			var wheel := StandardMaterial3D.new()
			wheel.albedo_color = Color(0.10, 0.10, 0.10)
			wheel.roughness = 0.6
			_add_cylinder(parent, 0.28, 0.28, 0.18, Vector3(-0.7, 0.22, 0.5), wheel)
			_add_cylinder(parent, 0.28, 0.28, 0.18, Vector3(0.7, 0.22, 0.5), wheel)
		"rock":
			material.albedo_color = Color(0.32, 0.25, 0.18)
			_add_box(parent, Vector3(1.0, 0.8, 0.8), Vector3(0, 0.4, 0), material)
		_:
			material.albedo_color = Color(0.5, 0.4, 0.3)
			_add_box(parent, Vector3(0.8, 0.8, 0.8), Vector3.ZERO, material)


func _add_box(parent: Node3D, size: Vector3, position_value: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = position_value
	parent.add_child(node)


func _add_cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float, position_value: Vector3, material: Material) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = position_value
	parent.add_child(node)


func _rect_array(value: Variant) -> Array:
	if value is Array and value.size() == 4:
		return value
	return [-10.0, -10.0, 20.0, 20.0]


func _point_from(value: Variant) -> Vector3:
	if value is Array and value.size() >= 2:
		return Vector3(float(value[0]), 0.0, float(value[1]))
	return Vector3.ZERO


func _center_x(rect: Array) -> float:
	return float(rect[0]) + float(rect[2]) * 0.5


func _center_z(rect: Array) -> float:
	return float(rect[1]) + float(rect[3]) * 0.5


func _half_size() -> float:
	var size: Variant = _layout.get("size", [40, 40])
	if size is Array and size.size() >= 2:
		return maxf(float(size[0]), float(size[1])) * 0.5
	return 50.0
