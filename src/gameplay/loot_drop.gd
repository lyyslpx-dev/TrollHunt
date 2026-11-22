class_name LootDrop
extends Node3D
## 地面掉落：品质光柱 + 悬浮方块 + 名称，靠近自动拾取。

var item: ItemData

var _player: Node3D
var _age: float = 0.0
var _taken: bool = false
var _core: MeshInstance3D
var _label: Label3D


func _ready() -> void:
	add_to_group("loot")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_build()


func _build() -> void:
	if item == null:
		queue_free()
		return
	var color := item.quality_color()

	var beam_mesh := CylinderMesh.new()
	beam_mesh.top_radius = 0.16
	beam_mesh.bottom_radius = 0.32
	beam_mesh.height = 3.0
	beam_mesh.radial_segments = 16
	var beam_mat := StandardMaterial3D.new()
	beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	beam_mat.albedo_color = Color(color.r, color.g, color.b, 0.55)
	beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	var beam := MeshInstance3D.new()
	beam.mesh = beam_mesh
	beam.material_override = beam_mat
	beam.position.y = 1.5
	add_child(beam)

	var core_mesh := BoxMesh.new()
	core_mesh.size = Vector3(0.32, 0.32, 0.32)
	var core_mat := StandardMaterial3D.new()
	core_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	core_mat.albedo_color = color
	_core = MeshInstance3D.new()
	_core.mesh = core_mesh
	_core.material_override = core_mat
	_core.position.y = 0.45
	add_child(_core)

	_label = Label3D.new()
	_label.text = item.full_name()
	_label.font_size = 34
	_label.pixel_size = 0.005
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.outline_size = 8
	_label.modulate = color
	_label.position.y = 1.05
	add_child(_label)


func _process(delta: float) -> void:
	if _taken or item == null:
		return
	_age += delta
	if _core:
		_core.rotation.y += delta * 2.4
		_core.position.y = 0.45 + sin(_age * 3.0) * 0.08
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
		return
	if _age < 0.35:
		return
	var distance := global_position.distance_to(_player.global_position)
	if distance < 3.0:
		global_position = global_position.lerp(_player.global_position, clampf(6.0 * delta, 0.0, 1.0))
	if distance < 0.9:
		_take()


func _take() -> void:
	if _taken:
		return
	_taken = true
	Events.item_picked.emit(item.id)
	Events.loot_picked.emit(item)
	queue_free()

