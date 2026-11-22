class_name Enemy
extends CharacterBody3D
## 占位怪物：三种小怪 + 精英 + BOSS。模型后面替换，行为先跑通。

signal died(enemy: Enemy)

enum Kind { PIG, ARCHER, BUG, ELITE, BOSS }

const NAMES := {
	Kind.PIG: "野猪",
	Kind.ARCHER: "弓手",
	Kind.BUG: "自爆虫",
	Kind.ELITE: "牛魔",
	Kind.BOSS: "冰霜巨龙",
}

const COLORS := {
	Kind.PIG: Color(0.62, 0.36, 0.22),
	Kind.ARCHER: Color(0.30, 0.62, 0.34),
	Kind.BUG: Color(0.88, 0.48, 0.14),
	Kind.ELITE: Color(0.28, 0.48, 0.86),
	Kind.BOSS: Color(0.55, 0.16, 0.20),
}
const SFX_HIT := preload("res://assets/audio/sfx/hit.wav")
const SFX_DEATH := preload("res://assets/audio/sfx/death.wav")

var kind: int = Kind.PIG
var level: int = 1
var max_hp: int = 80
var hp: int = 80
var attack: int = 8
var defense: int = 2
var move_speed: float = 2.4
var aggro_range: float = 10.0
var attack_range: float = 1.9
var attack_interval: float = 1.4
var gold_reward: int = 6
var is_boss: bool = false
var drop_map_id: String = LootTable.DEFAULT_MAP_ID
var _display_name: String = ""
var _model_override: String = ""

var _player: Node3D
var _mat: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _hp_fill: MeshInstance3D
var _bar_width: float = 1.3
var _cooldown: float = 0.0
var _windup: float = 0.0
var _flash: float = 0.0
const SAFE_ZONE_RADIUS := 3.5
var _knockback: Vector3 = Vector3.ZERO
var _dead: bool = false
var _body_height: float = 1.2
var _visual_root: Node3D
var _visual_base_y: float = 0.0
var _anim_clock: float = 0.0
var _stun: float = 0.0


func setup(enemy_kind: int, enemy_level: int = 1, map_id: String = LootTable.DEFAULT_MAP_ID, display_name: String = "", model_id: String = "") -> void:
	kind = enemy_kind
	level = enemy_level
	drop_map_id = map_id
	_display_name = display_name
	_model_override = model_id
	is_boss = kind == Kind.BOSS
	match kind:
		Kind.PIG:
			max_hp = 70
			attack = 7
			defense = 2
			move_speed = 2.6
			gold_reward = 5
			_body_height = 1.2
		Kind.ARCHER:
			max_hp = 55
			attack = 6
			defense = 1
			move_speed = 2.0
			attack_range = 7.0
			attack_interval = 2.2
			gold_reward = 6
			_body_height = 1.5
		Kind.BUG:
			max_hp = 35
			attack = 14
			defense = 0
			move_speed = 4.2
			gold_reward = 4
			_body_height = 0.9
		Kind.ELITE:
			max_hp = 320
			attack = 16
			defense = 6
			move_speed = 2.2
			attack_interval = 1.8
			gold_reward = 40
			_body_height = 2.0
		Kind.BOSS:
			max_hp = 1600
			attack = 28
			defense = 10
			move_speed = 1.9
			attack_interval = 2.4
			aggro_range = 16.0
			gold_reward = 260
			_body_height = 3.4
	max_hp = roundi(max_hp * (1.0 + 0.25 * float(level - 1)))
	attack = roundi(attack * (1.0 + 0.20 * float(level - 1)))
	hp = max_hp
	_build_visuals()


func _ready() -> void:
	add_to_group("enemy")
	_player = get_tree().get_first_node_in_group("player") as Node3D


func is_dead() -> bool:
	return _dead


func _build_visuals() -> void:
	_base_color = COLORS[kind]
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = _base_color
	_mat.roughness = 0.75

	var body := MeshInstance3D.new()
	var mesh: Mesh
	var shape: Shape3D
	var color := _base_color
	match kind:
		Kind.BUG:
			var sphere := SphereMesh.new()
			sphere.radius = 0.45
			sphere.height = 0.9
			mesh = sphere
			var sphere_shape := SphereShape3D.new()
			sphere_shape.radius = 0.45
			shape = sphere_shape
		Kind.BOSS:
			var capsule := CapsuleMesh.new()
			capsule.radius = 1.1
			capsule.height = 3.4
			mesh = capsule
			var capsule_shape := CapsuleShape3D.new()
			capsule_shape.radius = 1.1
			capsule_shape.height = 3.4
			shape = capsule_shape
		_:
			var radius := 0.42 if kind != Kind.ELITE else 0.62
			var capsule := CapsuleMesh.new()
			capsule.radius = radius
			capsule.height = _body_height
			mesh = capsule
			var capsule_shape := CapsuleShape3D.new()
			capsule_shape.radius = radius
			capsule_shape.height = _body_height
			shape = capsule_shape

	body.mesh = mesh
	body.material_override = _mat
	body.position.y = _body_height * 0.5
	var model := AssetLibrary.instantiate(_model_id())
	if model:
		add_child(model)
		_visual_root = model
		_visual_base_y = model.position.y
	else:
		add_child(body)
		_visual_root = body
		_visual_base_y = body.position.y

	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.position.y = _body_height * 0.5
	add_child(collision)

	var label := Label3D.new()
	label.text = _display_name if not _display_name.is_empty() else NAMES[kind]
	label.font_size = 44 if is_boss else 36
	label.pixel_size = 0.0055
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.outline_size = 8
	label.modulate = Color(1.0, 0.95, 0.85)
	label.position.y = _body_height + 0.85
	add_child(label)

	var bar_root := Node3D.new()
	bar_root.position.y = _body_height + 0.5
	add_child(bar_root)

	var bg_material := StandardMaterial3D.new()
	bg_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_material.albedo_color = Color(0.0, 0.0, 0.0, 0.75)
	bg_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	var bg_mesh := QuadMesh.new()
	bg_mesh.size = Vector2(_bar_width, 0.14)
	var bg := MeshInstance3D.new()
	bg.mesh = bg_mesh
	bg.material_override = bg_material
	bar_root.add_child(bg)

	var fill_material := StandardMaterial3D.new()
	fill_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fill_material.albedo_color = Color(0.85, 0.18, 0.16)
	fill_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fill_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED

	var fill_mesh := QuadMesh.new()
	fill_mesh.size = Vector2(_bar_width - 0.06, 0.09)
	_hp_fill = MeshInstance3D.new()
	_hp_fill.mesh = fill_mesh
	_hp_fill.material_override = fill_material
	_hp_fill.position.z = 0.01
	bar_root.add_child(_hp_fill)


func _model_id() -> String:
	if not _model_override.is_empty():
		return _model_override
	match kind:
		Kind.PIG:
			return "MON_BOAR_01"
		Kind.ARCHER:
			return "MON_ARCHER_01"
		Kind.BUG:
			return "MON_BOMB_BUG_01"
		Kind.ELITE:
			return "MON_BULL_ELITE_01"
		Kind.BOSS:
			return "BOSS_SANDWORM_01"
	return ""


func _physics_process(delta: float) -> void:
	_anim_clock += delta
	_update_procedural_anim(delta)
	if _dead:
		return
	if not is_on_floor():
		velocity.y -= 22.0 * delta
	else:
		velocity.y = 0.0

	_cooldown = maxf(0.0, _cooldown - delta)
	_flash = maxf(0.0, _flash - delta)
	_stun = maxf(0.0, _stun - delta)
	_mat.albedo_color = Color(1, 1, 1) if _flash > 0.0 else _base_color

	if _stun > 0.0:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
		_knockback = _knockback.lerp(Vector3.ZERO, clampf(8.0 * delta, 0.0, 1.0))
		velocity += _knockback
		move_and_slide()
		return

	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player") as Node3D
	if _player == null:
		move_and_slide()
		return

	for other in get_tree().get_nodes_in_group("enemy"):
		var other_enemy := other as Enemy
		if other_enemy == null or other_enemy == self or other_enemy.is_dead():
			continue
		var separation := global_position - other_enemy.global_position
		separation.y = 0.0
		var separation_distance := separation.length()
		if separation_distance < 1.35 and separation_distance > 0.01:
			velocity += separation.normalized() * (1.35 - separation_distance) * 2.6

	for safe_node in get_tree().get_nodes_in_group("safe_zone"):
		var safe_center: Vector3 = safe_node.global_position
		var safe_radius := float(safe_node.get_meta("radius", 3.5))
		var player_offset := _player.global_position - safe_center
		player_offset.y = 0.0
		if player_offset.length() < safe_radius:
			velocity.x = 0.0
			velocity.z = 0.0
			_knockback = Vector3.ZERO
			_windup = 0.0
			move_and_slide()
			return
		var self_offset := global_position - safe_center
		self_offset.y = 0.0
		if self_offset.length() < safe_radius:
			if self_offset.length_squared() < 0.001:
				self_offset = Vector3.RIGHT
			var safe_push := self_offset.normalized()
			velocity.x = safe_push.x * maxf(move_speed, 4.0)
			velocity.z = safe_push.z * maxf(move_speed, 4.0)
			_knockback = Vector3.ZERO
			_windup = 0.0
			move_and_slide()
			return

	var safe_npc := get_tree().get_first_node_in_group("upgrade_npc") as Node3D
	if safe_npc:
		var player_offset := _player.global_position - safe_npc.global_position
		player_offset.y = 0.0
		if player_offset.length() < SAFE_ZONE_RADIUS:
			velocity.x = 0.0
			velocity.z = 0.0
			_knockback = Vector3.ZERO
			_windup = 0.0
			move_and_slide()
			return
		var self_offset := global_position - safe_npc.global_position
		self_offset.y = 0.0
		if self_offset.length() < SAFE_ZONE_RADIUS:
			if self_offset.length_squared() < 0.001:
				self_offset = Vector3.RIGHT
			var push_direction := self_offset.normalized()
			velocity.x = push_direction.x * maxf(move_speed, 4.0)
			velocity.z = push_direction.z * maxf(move_speed, 4.0)
			_knockback = Vector3.ZERO
			_windup = 0.0
			move_and_slide()
			return

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var distance := to_player.length()
	var direction := to_player.normalized() if distance > 0.01 else Vector3.ZERO

	if _windup > 0.0:
		_windup -= delta
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)
		if _windup <= 0.0:
			_strike(distance, direction)
	elif distance <= aggro_range:
		_tick_ai(delta, distance, direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)

	velocity += _knockback
	_knockback = _knockback.lerp(Vector3.ZERO, clampf(10.0 * delta, 0.0, 1.0))
	move_and_slide()


func _update_procedural_anim(delta: float) -> void:
	if _visual_root == null:
		return
	var moving := velocity.length() > 0.5
	var speed := 8.0 if moving else 3.5
	var bob := sin(_anim_clock * speed) * (0.05 if moving else 0.025)
	_visual_root.position.y = _visual_base_y + bob
	var windup_scale := 1.18 if _windup > 0.0 else 1.0
	_visual_root.scale = Vector3.ONE * windup_scale * (1.0 + sin(_anim_clock * speed * 2.0) * 0.012)


func _tick_ai(delta: float, distance: float, direction: Vector3) -> void:
	match kind:
		Kind.ARCHER:
			if distance < 3.2:
				velocity.x = -direction.x * move_speed
				velocity.z = -direction.z * move_speed
			elif distance > 6.5:
				velocity.x = direction.x * move_speed
				velocity.z = direction.z * move_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			if _cooldown <= 0.0 and distance <= attack_range:
				_cooldown = attack_interval
				_shoot()
		Kind.BUG:
			velocity.x = direction.x * move_speed
			velocity.z = direction.z * move_speed
			if distance < 1.4:
				_explode()
		_:
			if distance > attack_range * 0.9:
				velocity.x = direction.x * move_speed
				velocity.z = direction.z * move_speed
			else:
				velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
				velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _cooldown <= 0.0 and distance <= attack_range:
				_cooldown = attack_interval
				_windup = 0.7 if is_boss else 0.35
				_flash = _windup

	if direction.length_squared() > 0.001 and kind != Kind.ARCHER:
		rotation.y = lerp_angle(rotation.y, atan2(-direction.x, -direction.z), 0.15)


func _strike(distance: float, _direction: Vector3) -> void:
	if _player == null:
		return
	if is_boss:
		var target := _player.global_position
		FX.aoe(get_parent(), target, 3.4, Color(0.5, 0.75, 1.0))
		FX.pillar(get_parent(), target, Color(0.6, 0.85, 1.0), 5.0)
		Events.camera_shake.emit(0.35)
		if _player.global_position.distance_to(target) < 3.6:
			_player.take_damage(attack)
	elif distance <= attack_range + 0.6:
		player_take_hit()


func player_take_hit() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(attack)
		Events.camera_shake.emit(0.12)


func _shoot() -> void:
	var ball := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.18
	mesh.height = 0.36
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.85, 0.3)
	ball.mesh = mesh
	ball.material_override = mat
	get_parent().add_child(ball)
	ball.global_position = global_position + Vector3(0, 1.0, 0)
	var target := _player.global_position + Vector3(0, 0.9, 0)
	var tween := ball.create_tween()
	tween.tween_property(ball, "global_position", target, 0.45)
	tween.tween_callback(func() -> void:
		if is_instance_valid(_player) and _player.global_position.distance_to(target - Vector3(0, 0.9, 0)) < 1.2:
			player_take_hit()
		ball.queue_free()
	)


func _explode() -> void:
	FX.aoe(get_parent(), global_position, 2.6, Color(1.0, 0.45, 0.1))
	Events.camera_shake.emit(0.2)
	if _player and _player.global_position.distance_to(global_position) < 2.8:
		player_take_hit()
	_die()


func take_damage(amount: int, is_crit: bool, from_position: Vector3) -> void:
	if _dead:
		return
	hp -= amount
	Audio.play_sfx(SFX_HIT)
	_flash = 0.2 if is_crit else 0.12
	_stun = (0.06 if is_boss else 0.12) + (0.08 if is_crit else 0.0)
	var push := global_position - from_position
	push.y = 0.0
	if push.length_squared() > 0.001:
		_knockback += push.normalized() * (0.25 if is_boss else 1.4)
	_update_bar()
	var numbers := get_tree().get_first_node_in_group("damage_numbers")
	if numbers and numbers.has_method("spawn"):
		numbers.spawn(global_position + Vector3(0, _body_height + 0.4, 0), amount, is_crit)
	if hp <= 0:
		_die()


func _update_bar() -> void:
	if _hp_fill == null:
		return
	var ratio := clampf(float(hp) / float(max_hp), 0.0, 1.0)
	_hp_fill.scale.x = maxf(ratio, 0.001)
	_hp_fill.position.x = -(_bar_width - 0.06) * 0.5 + (_bar_width - 0.06) * 0.5 * ratio


func _die() -> void:
	if _dead:
		return
	_dead = true
	GameState.add_gold(gold_reward)
	_drop_loot()
	Audio.play_sfx(SFX_DEATH)
	FX.aoe(get_parent(), global_position, 1.6 if not is_boss else 4.0, Color(1.0, 0.8, 0.4))
	died.emit(self)
	Events.enemy_died.emit(self)
	if _visual_root:
		var death_tween := create_tween()
		death_tween.tween_property(_visual_root, "scale", Vector3(0.1, 0.1, 0.1), 0.12)
		death_tween.tween_callback(queue_free)
	else:
		queue_free()


func _drop_loot() -> void:
	if is_boss:
		for i in LootTable.boss_item_count(drop_map_id):
			var min_quality := 3 if i == 0 else 2
			var item := LootTable.roll_item(drop_map_id, "boss", min_quality)
			_spawn_drop(item, global_position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)))
		return
	var source := "elite" if kind == Kind.ELITE else "normal"
	var chance := LootTable.drop_chance(drop_map_id, source)
	if randf() < chance:
		var item := LootTable.roll_item(drop_map_id, source)
		_spawn_drop(item, global_position)


func _spawn_drop(item: ItemData, world_position: Vector3) -> void:
	var drop := LootDrop.new()
	drop.item = item
	drop.position = world_position
	get_parent().add_child(drop)

