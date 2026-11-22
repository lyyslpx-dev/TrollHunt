extends Node3D
## 安全区装备升级 NPC。
## 优先加载 3D 模型；模型缺失时回退到 2D 立绘。

const NPC_HEIGHT := 1.85
const MODEL_SOURCE_HEIGHT := 1.908
const INTERACT_RADIUS := 2.85
const SAFE_RADIUS := 3.2
const CAMERA_FACING_YAW := PI * 0.25
const IDLE_MIN := 3.0
const IDLE_MAX := 5.5
const SPRITE_PATHS := {
	"idle": "res://assets/sprites/npc/upgrade_npc_idle.png",
	"hammer": "res://assets/sprites/npc/upgrade_npc_hammer.png",
	"wipe": "res://assets/sprites/npc/upgrade_npc_wipe.png",
	"stretch": "res://assets/sprites/npc/upgrade_npc_stretch.png",
}

var _player: Node3D
var _sprite: Sprite3D
var _model_root: Node3D
var _model_pivot: Node3D
var _model_base_scale := Vector3.ONE
var _use_model: bool = false
var _textures: Dictionary = {}
var _near: bool = false
var _current_action: String = "idle"
var _action_time: float = 0.0
var _idle_time: float = 0.0
var _clock: float = 0.0
var _swing_left: int = 0
var _swing_time: float = 0.0
var _motion_tween: Tween


func _ready() -> void:
	add_to_group("upgrade_npc")
	_player = get_tree().get_first_node_in_group("player") as Node3D
	_build_stage()
	_use_model = _build_model()
	if not _use_model:
		_load_textures()
		_build_sprite()
	_build_labels()
	_build_collision()
	_set_action("idle", 0.0)
	_idle_time = randf_range(IDLE_MIN, IDLE_MAX)


func _process(delta: float) -> void:
	_clock += delta
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	var should_show := false
	if _player:
		should_show = global_position.distance_to(_player.global_position) <= INTERACT_RADIUS
	if should_show != _near:
		_near = should_show
		Events.npc_prompt_changed.emit("装备升级", _near)

	if _current_action == "idle":
		if _use_model:
			_model_pivot.position.y = sin(_clock * 2.1) * 0.012
		else:
			_sprite.position.y = NPC_HEIGHT * 0.5 + sin(_clock * 2.1) * 0.012
		_idle_time -= delta
		if _idle_time <= 0.0:
			_choose_action()
		return

	_action_time -= delta
	if _current_action == "hammer":
		_swing_time -= delta
		if _swing_time <= 0.0 and _swing_left > 0:
			_swing_left -= 1
			_swing_time = 0.32
			_play_swing()

	if _action_time <= 0.0:
		_set_action("idle", 0.0)
		_idle_time = randf_range(IDLE_MIN, IDLE_MAX)


func _unhandled_input(event: InputEvent) -> void:
	if _near and event.is_action_pressed("ui_accept"):
		Events.npc_upgrade_requested.emit()


func _load_textures() -> void:
	for action in SPRITE_PATHS:
		var texture := load(SPRITE_PATHS[action]) as Texture2D
		if texture:
			_textures[action] = texture
	if not _textures.has("idle"):
		push_warning("升级 NPC 缺少 idle 立绘")


func _build_stage() -> void:
	var zone_mesh := CylinderMesh.new()
	zone_mesh.top_radius = SAFE_RADIUS
	zone_mesh.bottom_radius = SAFE_RADIUS
	zone_mesh.height = 0.018
	zone_mesh.radial_segments = 48
	var zone_mat := StandardMaterial3D.new()
	zone_mat.albedo_color = Color(0.20, 0.17, 0.14, 1.0)
	zone_mat.roughness = 0.92
	var zone := MeshInstance3D.new()
	zone.mesh = zone_mesh
	zone.material_override = zone_mat
	zone.position.y = 0.009
	add_child(zone)

	var shadow_mesh := CylinderMesh.new()
	shadow_mesh.top_radius = 0.68
	shadow_mesh.bottom_radius = 0.68
	shadow_mesh.height = 0.008
	shadow_mesh.radial_segments = 32
	var shadow_mat := StandardMaterial3D.new()
	shadow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	shadow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shadow_mat.albedo_color = Color(0.0, 0.0, 0.0, 0.28)
	var shadow := MeshInstance3D.new()
	shadow.mesh = shadow_mesh
	shadow.material_override = shadow_mat
	shadow.position.y = 0.022
	add_child(shadow)

	var anvil := Node3D.new()
	anvil.position = Vector3(1.35, 0.0, 0.15)
	anvil.rotation.y = -0.35
	add_child(anvil)
	var iron := StandardMaterial3D.new()
	iron.albedo_color = Color(0.10, 0.11, 0.13, 1.0)
	iron.metallic = 0.45
	iron.roughness = 0.55
	_add_box(anvil, Vector3(0.92, 0.16, 0.38), Vector3(0, 0.72, 0), iron)
	_add_box(anvil, Vector3(0.34, 0.52, 0.28), Vector3(0, 0.36, 0), iron)
	_add_box(anvil, Vector3(0.62, 0.10, 0.42), Vector3(0, 0.08, 0), iron)
	var hot_iron := StandardMaterial3D.new()
	hot_iron.albedo_color = Color(0.95, 0.28, 0.06, 1.0)
	hot_iron.emission_enabled = true
	hot_iron.emission = Color(0.65, 0.12, 0.02, 1.0)
	_add_box(anvil, Vector3(0.26, 0.08, 0.12), Vector3(-0.18, 0.83, 0), hot_iron)


func _add_box(parent: Node3D, size: Vector3, position_value: Vector3, material: Material) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material
	node.position = position_value
	parent.add_child(node)


func _build_model() -> bool:
	var instance := AssetLibrary.instantiate("CHR_NPC_UPGRADE_01")
	if instance == null:
		push_warning("升级 NPC 3D 模型缺失，回退 2D 立绘")
		return false
	_model_root = Node3D.new()
	_model_root.name = "ModelRoot"
	_model_pivot = Node3D.new()
	_model_pivot.name = "ModelPivot"
	_model_root.add_child(_model_pivot)
	_model_pivot.add_child(instance)
	var factor := NPC_HEIGHT / MODEL_SOURCE_HEIGHT
	_model_base_scale = Vector3(factor, factor, factor)
	_model_pivot.scale = _model_base_scale
	add_child(_model_root)
	_face_camera()
	return true


func _face_camera() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		_model_root.rotation.y = CAMERA_FACING_YAW
		return
	var forward := -camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() > 0.001:
		_model_root.rotation.y = atan2(-forward.x, -forward.z)


func _build_sprite() -> void:
	_sprite = Sprite3D.new()
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_sprite.no_depth_test = false
	add_child(_sprite)
	_apply_texture("idle")


func _apply_texture(action: String) -> void:
	var texture: Texture2D = _textures.get(action, _textures.get("idle"))
	if texture == null or _sprite == null:
		return
	_sprite.texture = texture
	_sprite.pixel_size = NPC_HEIGHT / float(texture.get_height())
	_sprite.position = Vector3(0.0, NPC_HEIGHT * 0.5, 0.0)


func _build_labels() -> void:
	var font := load("res://assets/fonts/NotoSansSC-Regular.otf") as Font
	var name_label := Label3D.new()
	name_label.text = "升级大师 · 胖哥"
	name_label.font = font
	name_label.font_size = 42
	name_label.outline_size = 10
	name_label.no_depth_test = true
	name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	name_label.modulate = Color(0.98, 0.84, 0.48, 1.0)
	name_label.position = Vector3(0, 2.22, 0)
	add_child(name_label)


func _build_collision() -> void:
	var body := StaticBody3D.new()
	body.name = "Body"
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.58
	cylinder.height = 1.45
	shape.shape = cylinder
	shape.position.y = 0.72
	body.add_child(shape)
	add_child(body)


func _choose_action() -> void:
	var roll := randf()
	if roll < 0.48:
		_set_action("hammer", 2.2)
	elif roll < 0.74:
		_set_action("wipe", 2.1)
	else:
		_set_action("stretch", 2.2)


func _set_action(action: String, duration: float) -> void:
	if _motion_tween:
		_motion_tween.kill()
	_current_action = action
	_action_time = duration
	_swing_left = 0
	_swing_time = 0.0
	if _use_model:
		_reset_model_pose()
		if action == "hammer":
			_swing_left = 5
			_swing_time = 0.15
		elif action == "wipe":
			_motion_tween = create_tween().set_loops(2)
			_motion_tween.tween_property(_model_pivot, "rotation:z", 0.035, 0.35).set_trans(Tween.TRANS_SINE)
			_motion_tween.tween_property(_model_pivot, "rotation:z", -0.025, 0.35).set_trans(Tween.TRANS_SINE)
		elif action == "stretch":
			var stretched := Vector3(_model_base_scale.x, _model_base_scale.y * 1.02, _model_base_scale.z)
			_motion_tween = create_tween()
			_motion_tween.tween_property(_model_pivot, "scale", stretched, 0.35).set_trans(Tween.TRANS_SINE)
			_motion_tween.tween_property(_model_pivot, "scale", _model_base_scale, 0.45).set_trans(Tween.TRANS_SINE)
		return
	_apply_texture(action)
	_sprite.rotation = Vector3.ZERO
	_sprite.scale = Vector3.ONE
	if action == "hammer":
		_swing_left = 5
		_swing_time = 0.15
	elif action == "wipe":
		_motion_tween = create_tween().set_loops(2)
		_motion_tween.tween_property(_sprite, "position:x", 0.025, 0.35).set_trans(Tween.TRANS_SINE)
		_motion_tween.tween_property(_sprite, "position:x", -0.018, 0.35).set_trans(Tween.TRANS_SINE)
	elif action == "stretch":
		_motion_tween = create_tween()
		_motion_tween.tween_property(_sprite, "scale", Vector3(1.015, 1.035, 1.0), 0.35).set_trans(Tween.TRANS_SINE)
		_motion_tween.tween_property(_sprite, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_SINE)


func _reset_model_pose() -> void:
	_model_pivot.position = Vector3.ZERO
	_model_pivot.rotation = Vector3.ZERO
	_model_pivot.scale = _model_base_scale


func _play_swing() -> void:
	if _use_model:
		var model_tween := create_tween()
		model_tween.tween_property(_model_pivot, "rotation:x", -0.07, 0.07).set_trans(Tween.TRANS_SINE)
		model_tween.tween_property(_model_pivot, "rotation:x", 0.0, 0.13).set_trans(Tween.TRANS_SINE)
		return
	var tween := create_tween()
	tween.tween_property(_sprite, "scale", Vector3(1.035, 0.965, 1.0), 0.07)
	tween.tween_property(_sprite, "scale", Vector3.ONE, 0.13)
