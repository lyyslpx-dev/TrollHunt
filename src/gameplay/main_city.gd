extends Node3D
## 主城「杨庄村」：出生点 + 升级大师 + 传送员 + 猜谜大师。

const CITY_THEME := "MAP_01_ASHEN_YARD"


func _ready() -> void:
	_build_ground()
	_build_border()
	_build_houses()
	_place_player()
	_spawn_npcs()


func _build_ground() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(90, 90)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = mesh
	ground.position = Vector3(0, 0.01, 0)
	add_child(ground)
	MapThemes.apply_ground_to(ground, CITY_THEME, "a")

	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(90, 0.3, 90)
	shape.shape = box
	shape.position = Vector3(0, 0.0, 0)
	body.add_child(shape)
	add_child(body)


func _build_border() -> void:
	var half := 45.0
	var wall_mat := StandardMaterial3D.new()
	wall_mat.albedo_color = Color(0.30, 0.24, 0.18)
	_add_wall(Vector3(0, 0, half + 1), Vector2(94, 2), wall_mat)
	_add_wall(Vector3(0, 0, -half - 1), Vector2(94, 2), wall_mat)
	_add_wall(Vector3(half + 1, 0, 0), Vector2(2, 94), wall_mat)
	_add_wall(Vector3(-half - 1, 0, 0), Vector2(2, 94), wall_mat)


func _add_wall(pos: Vector3, footprint: Vector2, mat: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(footprint.x, 3.0, footprint.y)
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = mat
	node.position = Vector3(pos.x, 1.5, pos.z)
	add_child(node)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(footprint.x, 3.0, footprint.y)
	shape.shape = box
	shape.position = Vector3(pos.x, 1.5, pos.z)
	body.add_child(shape)
	add_child(body)


func _build_houses() -> void:
	var spots := [
		Vector3(-22, 0, -18),
		Vector3(-24, 0, 14),
		Vector3(20, 0, -20),
		Vector3(22, 0, 16),
		Vector3(-6, 0, -28),
	]
	for i in spots.size():
		var house := AssetLibrary.instantiate("ENV_HOUSE_01")
		if house == null:
			house = _blockout_house()
		house.position = spots[i]
		house.rotation.y = float(i) * 1.2
		add_child(house)


func _blockout_house() -> Node3D:
	var root := Node3D.new()
	var mesh := BoxMesh.new()
	mesh.size = Vector3(6, 4, 6)
	var body := MeshInstance3D.new()
	body.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.45, 0.36, 0.26)
	body.material_override = mat
	body.position.y = 2.0
	root.add_child(body)
	return root


func _place_player() -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		player.global_position = Vector3(0, 0.9, 0)


func _spawn_npcs() -> void:
	var upgrade := load("res://scenes/npc/upgrade_npc.tscn") as PackedScene
	if upgrade:
		var up := upgrade.instantiate()
		up.position = Vector3(0, 0, -8)
		add_child(up)

	var teleporter := Node3D.new()
	teleporter.name = "TeleporterNpc"
	teleporter.position = Vector3(8, 0, 4)
	teleporter.set_script(load("res://src/gameplay/teleporter_npc.gd"))
	add_child(teleporter)

	var riddle := Node3D.new()
	riddle.name = "RiddleNpc"
	riddle.position = Vector3(-8, 0, 4)
	riddle.set_script(load("res://src/gameplay/riddle_npc.gd"))
	add_child(riddle)
