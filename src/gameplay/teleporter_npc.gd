extends Node3D
## 主城传送员：靠近可打开 10 张地图的传送面板。

const INTERACT_RADIUS := 3.4

var _player: Node3D
var _near := false


func _ready() -> void:
	add_to_group("teleporter_npc")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_build_visual()


func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	var near: bool = global_position.distance_to(_player.global_position) <= INTERACT_RADIUS
	if near != _near:
		_near = near
		Events.npc_prompt_changed.emit("传送", _near)


func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed("ui_accept"):
		Events.npc_teleport_requested.emit()


func _build_visual() -> void:
	var model := AssetLibrary.instantiate("CHR_NPC_TELEPORT_01")
	if model:
		model.name = "Model"
		add_child(model)
		_ground_model(model)
	else:
		_add_fallback(Color(0.30, 0.55, 0.80))
	var label := Label3D.new()
	label.text = "传送员 · 杨庄驿站"
	label.font_size = 44
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 10
	label.modulate = Color(0.75, 0.9, 1.0)
	label.position = Vector3(0, 2.3, 0)
	add_child(label)


func _add_fallback(color: Color) -> void:
	var mesh := CapsuleMesh.new()
	mesh.radius = 0.42
	mesh.height = 1.7
	var node := MeshInstance3D.new()
	node.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	node.material_override = mat
	node.position.y = 0.85
	add_child(node)


func _ground_model(root: Node3D) -> void:
	var aabb := AABB()
	var found := false
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var world_aabb: AABB = mi.global_transform * mi.get_aabb()
		if not found:
			aabb = world_aabb
			found = true
		else:
			aabb = aabb.merge(world_aabb)
	if found:
		root.position.y -= aabb.position.y
