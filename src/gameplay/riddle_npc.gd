extends Node3D
## 主城猜谜大师：靠近可答题，每天 3 题，答对 +1% 全能属性，答错 -1%。

const INTERACT_RADIUS := 3.4
const IDLE_ACTIONS := ["human_000093", "human_000025", "human_000063", "human_000000", "human_000012", "human_000040"]

var _player: Node3D
var _near := false
var _anim_player: AnimationPlayer
var _idle_timer: float = 0.0


func _ready() -> void:
	add_to_group("riddle_npc")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_build_visual()


func _process(_delta: float) -> void:
	_update_idle(_delta)
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		return
	var near: bool = global_position.distance_to(_player.global_position) <= INTERACT_RADIUS
	if near != _near:
		_near = near
		Events.npc_prompt_changed.emit("猜谜", _near)


func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed("ui_accept"):
		Events.npc_riddle_requested.emit()


func _build_visual() -> void:
	var model := AssetLibrary.instantiate("CHR_NPC_RIDDLE_01")
	if model:
		model.name = "Model"
		add_child(model)
		_find_anim_player(model)
	else:
		_add_fallback(Color(0.82, 0.50, 0.28))
	var label := Label3D.new()
	label.text = "猜谜大师 · 短裤哥"
	label.font_size = 44
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 10
	label.modulate = Color(1.0, 0.82, 0.45)
	label.position = Vector3(0, 2.3, 0)
	add_child(label)


func _find_anim_player(node: Node) -> void:
	if node is AnimationPlayer:
		_anim_player = node as AnimationPlayer
		return
	for child in node.get_children():
		_find_anim_player(child)
		if _anim_player:
			return


func _update_idle(delta: float) -> void:
	if _anim_player == null:
		return
	_idle_timer -= delta
	if _idle_timer > 0.0:
		return
	_idle_timer = randf_range(3.0, 6.5)
	for action in IDLE_ACTIONS:
		if _anim_player.has_animation(action):
			_anim_player.play(action)
			return


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
