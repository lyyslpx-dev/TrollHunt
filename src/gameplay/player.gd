extends CharacterBody3D
## 占位角色：移动 + 自动索敌 + 三段普攻 + 三个技能。

const SKILL_NAMES: Array[String] = ["旋风斩", "冲锋", "雷霆"]
const SKILL_MP: Array[int] = [8, 10, 15]
const SKILL_CD: Array[float] = [5.0, 8.0, 12.0]
const SFX_HIT := preload("res://assets/audio/sfx/hit.wav")
const SFX_CRIT := preload("res://assets/audio/sfx/crit.wav")
const SFX_SKILL := preload("res://assets/audio/sfx/skill.wav")
const SFX_DEATH := preload("res://assets/audio/sfx/death.wav")
const SFX_BREATH := preload("res://assets/audio/sfx/breath.wav")

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
var _breath_player: AudioStreamPlayer


func _ready() -> void:
	var model := AssetLibrary.instantiate(GameState.selected_character_id)
	if model:
		var placeholder := get_node_or_null("Mesh") as MeshInstance3D
		if placeholder:
			placeholder.visible = false
		model.name = "Model"
		add_child(model)
		_model = model
		_find_anim_player(model)
	_build_weapon()
	_build_breath_player()


func reload_model() -> void:
	var old_model := get_node_or_null("Model") as Node3D
	if old_model:
		old_model.queue_free()
	var model := AssetLibrary.instantiate(GameState.selected_character_id)
	if model:
		model.name = "Model"
		add_child(model)
		_model = model
		_find_anim_player(model)
	_build_weapon()


func _build_weapon() -> void:
	if _weapon_node and is_instance_valid(_weapon_node):
		_weapon_node.queue_free()
	_weapon_node = null
	var weapon := AssetLibrary.instantiate(GameState.selected_weapon_id)
	if weapon:
		weapon.name = "Weapon"
		weapon.position = Vector3(0.55, 1.0, 0.35)
		weapon.rotation.y = 0.4
		add_child(weapon)
		_weapon_node = weapon


func reload_weapon() -> void:
	_build_weapon()


func _build_breath_player() -> void:
	if _breath_player:
		return
	_breath_player = AudioStreamPlayer.new()
	_breath_player.volume_db = -18.0
	add_child(_breath_player)


func _update_breath(input_length: float) -> void:
	if _breath_player == null:
		return
	var should_play := not _dead and input_length <= 0.01 and _skill_windup <= 0.0 and _hit_stop <= 0.0
	if should_play:
		if not _breath_player.playing:
			var stream := SFX_BREATH.duplicate() as AudioStreamWAV
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = int(stream.get_length() * stream.mix_rate)
			_breath_player.stream = stream
			_breath_player.play()
	elif _breath_player.playing:
		_breath_player.stop()


func _find_anim_player(node: Node) -> void:
	if node is AnimationPlayer:
		_anim_player = node as AnimationPlayer
		return
	for child in node.get_children():
		_find_anim_player(child)
		if _anim_player:
			return


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
	var speed_multiplier := _hazard_slow_multiplier()
	if direction.length_squared() > 0.001:
		direction = direction.normalized()
		velocity.x = direction.x * move_speed * speed_multiplier
		velocity.z = direction.z * move_speed * speed_multiplier
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 6.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, move_speed * 6.0 * delta)

	if _target == null or not is_instance_valid(_target) or _target.is_dead():
		_target = _find_target()
	if auto_attack and _target and _attack_cd <= 0.0:
		if global_position.distance_to(_target.global_position) <= 2.3:
			perform_attack()

	_update_animation(input.length())
	_update_breath(input.length())
	move_and_slide()


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
	var combo_anims: Array[String] = ["human_000059", "human_000018", "human_000035"]
	_play_animation(combo_anims[_combo])
	_combo = (_combo + 1) % 3
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
	_play_animation("human_000040")
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
	_invuln = 0.4
	_hit_stop = 0.05
	_play_animation("human_000003")
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
	_play_animation("human_000014")
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
		rotation.y = atan2(-direction.x, -direction.z)


func _update_animation(input_length: float) -> void:
	if _anim_player == null:
		return
	if _dead:
		return
	if input_length > 0.01:
		_play_animation("human_000089")
	else:
		_play_animation("human_000093")


func _play_animation(anim_name: String) -> void:
	if _anim_player == null:
		return
	if not _anim_player.has_animation(anim_name):
		return
	if _current_anim == anim_name:
		return
	_current_anim = anim_name
	_anim_player.play(anim_name)

