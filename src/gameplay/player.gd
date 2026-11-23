extends CharacterBody3D
## 占位角色：移动 + 自动索敌 + 三段普攻 + 三个技能。

const SKILL_NAMES: Array[String] = ["旋风斩", "冲锋", "雷霆"]
const SKILL_MP: Array[int] = [8, 10, 15]
const SKILL_CD: Array[float] = [5.0, 8.0, 12.0]
const SFX_HIT := preload("res://assets/audio/sfx/hit.wav")
const SFX_CRIT := preload("res://assets/audio/sfx/crit.wav")
const SFX_SKILL := preload("res://assets/audio/sfx/skill.wav")
const SFX_DEATH := preload("res://assets/audio/sfx/death.wav")
const ANIM_CANDIDATES := {
	"walk": ["human_000089", "walking", "Walking", "run", "Run", "walk", "Walk", "Armature|run", "Armature|Run"],
	"idle": ["human_000093", "idle", "Idle", "Armature|idle"],
	"attack1": ["human_000059", "attack1", "Attack1", "attack", "Attack"],
	"attack2": ["human_000018", "attack2", "Attack2"],
	"attack3": ["human_000035", "attack3", "Attack3"],
	"hit": ["human_000003", "hit", "Hit"],
	"die": ["human_000014", "dying", "Dying", "die", "Die", "death", "Death"],
	"skill": ["human_000040", "skill", "Skill", "cast", "Cast"],
}

@export var move_speed: float = 5.0
@export var gravity: float = 22.0
@export var auto_attack: bool = true

var _joystick_input: Vector2 = Vector2.ZERO
var _target: Enemy = null
var _attack_cd: float = 0.0
var _combo: int = 0
var _skill_cd: Array[float] = [0.0, 0.0, 0.0]
var _invuln: float = 0.0
var _dead: bool = false
var _mp_regen: float = 4.0
var _hazard_level: int = 0
var _anim_player: AnimationPlayer
var _current_anim := ""
var _skill_windup := 0.0
var _pending_skill := -1
var _hit_stop := 0.0
var _model: Node3D
var _weapon_node: Node3D
var _model_base_y: float = 0.0
var _walk_clock: float = 0.0
var _anim_lock: float = 0.0


func _ready() -> void:
	_reload_visual()
	_build_weapon()


func reload_model() -> void:
	_reload_visual()
	_build_weapon()


func _reload_visual() -> void:
	var old_model := get_node_or_null("Model") as Node3D
	if old_model:
		old_model.queue_free()
	_model = null
	_anim_player = null
	var model := AssetLibrary.instantiate(GameState.selected_character_id)
	var placeholder := get_node_or_null("Mesh") as MeshInstance3D
	if model:
		model.name = "Model"
		add_child(model)
		_model = model
		_ground_model(model)
		_model_base_y = model.position.y
		if placeholder:
			placeholder.visible = false
		_find_anim_player(model)
	else:
		if placeholder:
			placeholder.visible = true


func _build_weapon() -> void:
	if _weapon_node and is_instance_valid(_weapon_node):
		_weapon_node.queue_free()
	_weapon_node = null
	var weapon := AssetLibrary.instantiate(GameState.selected_weapon_id)
	if weapon == null:
		return
	weapon.name = "Weapon"
	if _attach_weapon_to_hand(weapon):
		pass
	elif _model and is_instance_valid(_model):
		weapon.position = Vector3(0.42, 0.98, 0.18)
		weapon.rotation.y = 0.35
		_model.add_child(weapon)
	else:
		weapon.position = Vector3(0.55, 1.0, 0.35)
		weapon.rotation.y = 0.4
		add_child(weapon)
	_weapon_node = weapon


func _attach_weapon_to_hand(weapon: Node3D) -> bool:
	if _model == null or not is_instance_valid(_model):
		return false
	var skeleton := _find_skeleton(_model)
	if skeleton == null:
		return false
	var bone := _find_hand_bone(skeleton)
	if bone.is_empty():
		return false
	var attach := BoneAttachment3D.new()
	attach.name = "WeaponHand"
	attach.bone_name = bone
	skeleton.add_child(attach)
	attach.add_child(weapon)
	weapon.position = Vector3(0.0, 0.85, 0.08)
	weapon.rotation_degrees = Vector3(8.0, 0.0, 0.0)
	return true


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null


func _find_hand_bone(skeleton: Skeleton3D) -> String:
	for i in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(i)
		if bone_name.contains("Hand") and (bone_name.contains("Right") or bone_name.contains("_R") or bone_name.to_lower().contains("hand_r")):
			return bone_name
	for i in skeleton.get_bone_count():
		var bone_name: String = skeleton.get_bone_name(i)
		if bone_name.contains("Hand"):
			return bone_name
	return ""


func reload_weapon() -> void:
	_build_weapon()


func _find_anim_player(node: Node) -> void:
	if node is AnimationPlayer:
		_anim_player = node as AnimationPlayer
		_anim_player.root_motion_track = NodePath()
		return
	for child in node.get_children():
		_find_anim_player(child)
		if _anim_player:
			return


func _ground_model(root: Node3D) -> void:
	var aabb := AABB()
	var found := false
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		var world_aabb: AABB = mi.transform * mi.get_aabb()
		if not found:
			aabb = world_aabb
			found = true
		else:
			aabb = aabb.merge(world_aabb)
	if found:
		root.position.y -= aabb.position.y


func set_move_input(direction: Vector2) -> void:
	_joystick_input = direction.limit_length(1.0)


func enter_hazard() -> void:
	_hazard_level += 1


func exit_hazard() -> void:
	_hazard_level = maxi(0, _hazard_level - 1)


func _hazard_slow_multiplier() -> float:
	return 0.45 if _hazard_level > 0 else 1.0


func _physics_process(delta: float) -> void:
	_attack_cd = maxf(0.0, _attack_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_anim_lock = maxf(0.0, _anim_lock - delta)
	if _model:
		_model.visible = _invuln <= 0.0 or (Time.get_ticks_msec() / 80) % 2 < 1
	if _hit_stop > 0.0:
		_hit_stop -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	if _skill_windup > 0.0:
		_skill_windup -= delta
		if _skill_windup <= 0.0 and _pending_skill >= 0:
			_execute_skill(_pending_skill)
			_pending_skill = -1
	for i in _skill_cd.size():
		_skill_cd[i] = maxf(0.0, _skill_cd[i] - delta)
	GameState.mp = mini(GameState.max_mp, GameState.mp + roundi(_mp_regen * delta))

	if _dead:
		return
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0.0

	var input := _joystick_input
	var keyboard := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if keyboard.length_squared() > 0.01:
		input = keyboard

	var camera := get_viewport().get_camera_3d()
	var forward := Vector3.FORWARD
	var right := Vector3.RIGHT
	if camera:
		forward = -camera.global_transform.basis.z
		right = camera.global_transform.basis.x
		forward.y = 0.0
		right.y = 0.0
		if forward.length_squared() < 0.001:
			forward = Vector3.FORWARD
		if right.length_squared() < 0.001:
			right = Vector3.RIGHT
		forward = forward.normalized()
		right = right.normalized()

	var direction := right * input.x + forward * (-input.y)
	var input_length := input.length()
	var running := input_length > 0.6
	var speed_multiplier := _hazard_slow_multiplier() * (1.55 if running else 1.0)
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed * speed_multiplier
		velocity.z = direction.z * move_speed * speed_multiplier
		rotation.y = atan2(direction.x, direction.z)
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)

	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_target = _find_target()
	if auto_attack and _target and _attack_cd <= 0.0:
		if global_position.distance_to(_target.global_position) <= 2.3:
			perform_attack()

	_update_animation(input.length())
	move_and_slide()
	_clamp_to_bounds()


func _clamp_to_bounds() -> void:
	var layout := get_tree().get_first_node_in_group("map_layout") as Node
	if layout == null or not layout.has_method("map_bounds"):
		return
	var b: Array = layout.map_bounds()
	if b.size() != 4:
		return
	global_position.x = clampf(global_position.x, float(b[0]), float(b[2]))
	global_position.z = clampf(global_position.z, float(b[1]), float(b[3]))


func _find_target() -> Enemy:
	var best: Enemy = null
	var best_distance := 7.5
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		var distance := global_position.distance_to(enemy.global_position)
		if distance < best_distance:
			best_distance = distance
			best = enemy
	return best


func perform_attack() -> void:
	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		return
	if global_position.distance_to(_target.global_position) > 2.6:
		return
	var multiplier: float = [1.0, 1.0, 1.55][_combo]
	var combo_anims: Array[String] = ["attack1", "attack2", "attack3"]
	_play_action(combo_anims[_combo])
	_combo = (_combo + 1) % 3
	_anim_lock = 0.5
	_deal_damage(_target, multiplier)
	FX.slash(get_parent(), _target.global_position)
	_face(_target.global_position)
	_attack_cd = 0.55
	if multiplier > 1.5:
		Events.camera_shake.emit(0.14)


func manual_attack() -> void:
	if _dead:
		return
	if _target == null or not is_instance_valid(_target):
		_target = _find_target()
	if _target and _attack_cd <= 0.0:
		perform_attack()


func use_skill(index: int) -> bool:
	if _dead or index < 0 or index >= SKILL_NAMES.size():
		return false
	if _skill_cd[index] > 0.0:
		return false
	if GameState.mp < SKILL_MP[index]:
		return false
	GameState.mp -= SKILL_MP[index]
	_skill_cd[index] = SKILL_CD[index]
	_pending_skill = index
	_skill_windup = 0.18
	_anim_lock = 0.5
	_play_action("skill")
	Events.player_stats_changed.emit()
	return true


func _execute_skill(index: int) -> void:
	Audio.play_sfx(SFX_SKILL)
	match index:
		0:
			_whirlwind()
		1:
			_charge()
		2:
			_thunder()


func skill_cooldown(index: int) -> float:
	if index < 0 or index >= _skill_cd.size():
		return 0.0
	return _skill_cd[index]


func is_dead() -> bool:
	return _dead


func _whirlwind() -> void:
	_hit_stop = maxf(_hit_stop, 0.08)
	FX.aoe(get_parent(), global_position, 2.9, Color(1.0, 0.55, 0.12))
	FX.aoe(get_parent(), global_position, 2.2, Color(1.0, 0.85, 0.35))
	Events.camera_shake.emit(0.25)
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		if global_position.distance_to(enemy.global_position) <= 2.9:
			_deal_damage(enemy, 2.2)


func _charge() -> void:
	_hit_stop = maxf(_hit_stop, 0.05)
	var direction := -global_transform.basis.z
	if _target and is_instance_valid(_target):
		direction = _target.global_position - global_position
		direction.y = 0.0
		if direction.length_squared() < 0.01:
			direction = -global_transform.basis.z
	direction = direction.normalized()
	global_position += direction * 3.4
	_face(global_position + direction)
	FX.aoe(get_parent(), global_position, 2.2, Color(0.35, 0.65, 1.0))
	Events.camera_shake.emit(0.22)
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		if global_position.distance_to(enemy.global_position) <= 2.2:
			_deal_damage(enemy, 1.8)


func _thunder() -> void:
	_hit_stop = maxf(_hit_stop, 0.1)
	var target_position := global_position + (-global_transform.basis.z) * 4.0
	if _target and is_instance_valid(_target):
		target_position = _target.global_position
	FX.pillar(get_parent(), target_position, Color(1.0, 0.85, 0.4), 7.0)
	FX.aoe(get_parent(), target_position, 3.2, Color(1.0, 0.9, 0.5))
	Events.camera_shake.emit(0.32)
	for node in get_tree().get_nodes_in_group("enemy"):
		var enemy := node as Enemy
		if enemy == null or enemy.is_dead():
			continue
		if target_position.distance_to(enemy.global_position) <= 3.2:
			_deal_damage(enemy, 3.2)


func _deal_damage(enemy: Enemy, multiplier: float) -> void:
	var crit := randf() < GameState.crit_rate
	var raw := float(GameState.attack) * multiplier - float(enemy.defense) * 0.5
	var amount := maxi(1, roundi(raw * randf_range(0.9, 1.1) * (GameState.crit_damage if crit else 1.0)))
	enemy.take_damage(amount, crit, global_position)
	if crit:
		_hit_stop = maxf(_hit_stop, 0.07)
		Events.camera_shake.emit(0.22)
	Audio.play_sfx(SFX_CRIT if crit else SFX_HIT)


func take_damage(amount: int) -> void:
	if _dead or _invuln > 0.0:
		return
	amount = maxi(1, roundi(float(amount) * 0.4))
	_invuln = 0.4
	_hit_stop = 0.05
	_anim_lock = 0.35
	_play_action("hit")
	FX.slash(get_parent(), global_position, Color(1.0, 0.35, 0.25))
	Audio.play_sfx(SFX_HIT)
	GameState.hp = maxi(0, GameState.hp - amount)
	Events.player_stats_changed.emit()
	Events.camera_shake.emit(0.18)
	var numbers := get_tree().get_first_node_in_group("damage_numbers")
	if numbers and numbers.has_method("spawn"):
		numbers.spawn(global_position + Vector3(0, 1.8, 0), amount, false)
	if GameState.hp <= 0:
		_die()


func _die() -> void:
	if _dead:
		return
	_dead = true
	_play_action("die")
	Audio.play_sfx(SFX_DEATH)
	Events.camera_shake.emit(0.4)
	Events.player_died.emit()
	await get_tree().create_timer(2.0).timeout
	var map_layout := get_tree().get_first_node_in_group("map_layout") as Node3D
	if map_layout and map_layout.has_method("player_spawn"):
		global_position = map_layout.player_spawn()
	else:
		global_position = Vector3.ZERO
	GameState.hp = GameState.max_hp
	GameState.mp = GameState.max_mp
	_dead = false
	Events.player_stats_changed.emit()


func _face(world_position: Vector3) -> void:
	var direction := world_position - global_position
	direction.y = 0.0
	if direction.length_squared() > 0.001:
		rotation.y = atan2(direction.x, direction.z)


func _update_animation(input_length: float) -> void:
	if _dead:
		return
	if _anim_lock > 0.0:
		return
	var moving := input_length > 0.01
	var running := input_length > 0.6
	var played := _play_action("walk" if moving else "idle")
	if _anim_player and played:
		_anim_player.speed_scale = 1.45 if running else 1.0



func _play_action(action: String) -> bool:
	if _anim_player == null:
		return false
	var names: Array = ANIM_CANDIDATES.get(action, [])
	for candidate in names:
		if _anim_player.has_animation(candidate):
			if _current_anim != candidate:
				_current_anim = candidate
				_anim_player.play(candidate)
			return true
	return false


func _apply_walk_motion(moving: bool, played: bool) -> void:
	if _model == null:
		return
	_walk_clock += get_physics_process_delta_time()
	if played:
		_model.position.y = _model_base_y
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, 0.2)
		return
	var speed := 9.0 if moving else 3.0
	var bob := sin(_walk_clock * speed) * (0.07 if moving else 0.03)
	_model.position.y = _model_base_y + bob
	if moving:
		_model.rotation.x = sin(_walk_clock * speed) * 0.05
	else:
		_model.rotation.x = lerpf(_model.rotation.x, 0.0, 0.2)




