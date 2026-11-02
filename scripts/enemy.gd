class_name Enemy
extends CharacterBody2D

signal died

enum State {
	ADVANCE,
	ATTACK,
	DEAD,
}

const ANIM_COLS := 6
const ENEMY_ROW_WALK := 0
const ENEMY_ROW_SHOOT := 1
const ENEMY_ROW_HURT := 2
const ENEMY_ROW_DEATH := 3

@export var health := 30.0
@export var speed := 95.0
@export var stop_distance := 340.0
@export var attack_interval := 1.6
@export var attack_damage := 7.0
@export var projectile_speed := 540.0
@export var is_stationary := false
@export var use_sniper_laser := false

var state: State = State.ADVANCE
var _stop_x := 525.0
var _attack_timer := 0.0
var _shot_visual_timer := 0.0
var _base_color := Color.WHITE
var _has_locked_aim := false
var _locked_aim_pos := Vector2.ZERO
var _target_marker: Polygon2D = null

var _anim_time := 0.0
var _shoot_anim_timer := 0.0
var _shoot_anim_duration := 0.24
var _hurt_anim_timer := 0.0
var _hurt_anim_duration := 0.22
var _death_anim_timer := 0.0
var _death_anim_duration := 0.48
var _blood_splashed := false
var _base_sprite_scale := Vector2(0.4, 0.4)
var _last_step_col := -1

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_sprite: Sprite2D = get_node_or_null("BodySprite")
@onready var body_rect: ColorRect = get_node_or_null("ColorRect")
@onready var shadow: Polygon2D = get_node_or_null("Shadow")
@onready var shot_line: Line2D = get_node_or_null("ShotLine")


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 0
	_create_target_marker()

	# Невеликий випадковий зсув фази кроку, щоб загін ворогів крокував природно, а не синхронно
	_anim_time = randf_range(0.0, 10.0)

	if body_sprite:
		_base_sprite_scale = body_sprite.scale
	if use_sniper_laser:
		_shoot_anim_duration = 0.42
		if is_equal_approx(projectile_speed, 540.0):
			projectile_speed = 1650.0
	if shot_line:
		shot_line.visible = false
	if body_rect:
		_base_color = body_rect.color

	var trench_x := _get_trench_x()
	_stop_x = trench_x + stop_distance + randf_range(-55.0, 75.0)

	if is_stationary:
		state = State.ATTACK
		_attack_timer = attack_interval * randf_range(0.6, 1.0)
	else:
		state = State.ADVANCE
		_attack_timer = attack_interval * 0.5


func _physics_process(delta: float) -> void:
	_anim_time += delta
	_update_shot_visual(delta)
	_update_sprite_animation(delta)

	match state:
		State.ADVANCE:
			_process_advance()
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			velocity = Vector2.ZERO


func _update_sprite_animation(delta: float) -> void:
	if body_sprite == null:
		return

	var cols := maxi(body_sprite.hframes, 1)

	if state == State.DEAD:
		_death_anim_timer = minf(_death_anim_timer + delta, _death_anim_duration)
		var raw_t := clampf(_death_anim_timer / _death_anim_duration, 0.0, 1.0)
		# Прискорення під вагою власного тіла (спочатку підгинаються коліна, потім важке падіння спиною об землю)
		var gravity_t := pow(raw_t, 1.65)
		var d_col := clampi(int(gravity_t * float(cols)), 0, cols - 1)
		body_sprite.frame_coords = Vector2i(d_col, ENEMY_ROW_DEATH)

		# У момент удару тілом об землю (половина анімації) — важкий "гуп" (squash) і бризки крові врізнобіч!
		var impact_frame := maxi(cols / 2, 3)
		if d_col >= impact_frame and not _blood_splashed:
			_blood_splashed = true
			_spawn_ground_blood_splatter()
			var impact_tween := create_tween()
			body_sprite.scale = Vector2(_base_sprite_scale.x * 1.15, _base_sprite_scale.y * 0.85)
			impact_tween.tween_property(body_sprite, "scale", _base_sprite_scale, 0.14).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

		if shadow:
			shadow.position = Vector2(lerpf(0.0, 14.0, gravity_t), shadow.position.y)
			shadow.scale = Vector2(lerpf(1.0, 1.55, gravity_t), lerpf(1.0, 0.92, gravity_t))
		return

	if _hurt_anim_timer > 0.0:
		_hurt_anim_timer = maxf(_hurt_anim_timer - delta, 0.0)
		var h_prog := 1.0 - (_hurt_anim_timer / _hurt_anim_duration)
		var h_col := clampi(int(h_prog * float(cols)), 0, cols - 1)
		body_sprite.frame_coords = Vector2i(h_col, ENEMY_ROW_HURT)
		return

	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		var s_prog := 1.0 - (_shoot_anim_timer / _shoot_anim_duration)
		var s_col := clampi(int(s_prog * float(cols)), 0, cols - 1)
		body_sprite.frame_coords = Vector2i(s_col, ENEMY_ROW_SHOOT)
		return

	if state == State.ADVANCE:
		# Рядок 0: плавна 12-кадрова ІК-анімація ходьби (два повних кроки за цикл)
		var walk_fps := 14.5 if cols >= 12 else 9.5
		var walk_col := int(_anim_time * walk_fps) % cols
		body_sprite.frame_coords = Vector2i(walk_col, ENEMY_ROW_WALK)

		# Динаміка тіні та пилу під черевиками на кожному кроці
		var cycle_phase := (_anim_time * walk_fps / float(cols)) * TAU
		if shadow:
			var stride_width := cos(cycle_phase * 2.0)
			shadow.scale = Vector2(1.0 + 0.12 * stride_width, 1.0 - 0.05 * stride_width)

		if walk_col != _last_step_col:
			_last_step_col = walk_col
			if walk_col == 0 or walk_col == (cols / 2):
				_spawn_step_dust(walk_col == 0)
	elif use_sniper_laser:
		# Для снайпера Рядок 0 — це прицілювання в оптику та розгоряння червоного бліку прицілу перед пострілом!
		if _attack_timer <= 0.85 and _attack_timer > 0.0:
			var aim_prog := clampf(1.0 - (_attack_timer / 0.85), 0.0, 1.0)
			var aim_col := clampi(1 + int(aim_prog * float(cols - 1)), 1, cols - 1)
			body_sprite.frame_coords = Vector2i(aim_col, ENEMY_ROW_WALK)
		else:
			var breathe_col := int(_anim_time * 2.5) % 2
			body_sprite.frame_coords = Vector2i(breathe_col, ENEMY_ROW_WALK)
	else:
		# У режимі атаки між пострілами тримає бойову стійку з легким диханням
		if shadow:
			shadow.scale = Vector2.ONE
		var ready_col := (cols - 2) + (int(_anim_time * 3.5) % 2)
		body_sprite.frame_coords = Vector2i(ready_col, ENEMY_ROW_SHOOT)


func _process_advance() -> void:
	var trench_x := _get_trench_x()
	var target_x := maxf(_stop_x, trench_x + stop_distance - 60.0)
	if global_position.x <= target_x:
		velocity = Vector2.ZERO
		state = State.ATTACK
		return

	velocity = Vector2.LEFT * speed
	move_and_slide()


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_timer -= delta

	var muzzle_offset := Vector2(-30.0, -2.0)
	if body_sprite != null:
		muzzle_offset = Vector2(-75.0, -5.5) if use_sniper_laser else Vector2(-49.0, 0.0)
	var muzzle_pos := global_position + muzzle_offset
	var lock_window := 0.85 if use_sniper_laser else 0.38

	if _attack_timer <= lock_window and _attack_timer > 0.0 and not _has_locked_aim:
		var p := _find_player()
		if p:
			_locked_aim_pos = p.global_position + Vector2(0.0, -8.0)
			_has_locked_aim = true
			if _target_marker:
				_target_marker.global_position = Vector2(_locked_aim_pos.x, _locked_aim_pos.y + 30.0)
				_target_marker.visible = true

	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		if _target_marker:
			_target_marker.visible = false
		_perform_attack(muzzle_pos)
		_has_locked_aim = false


func _perform_attack(muzzle_pos: Vector2) -> void:
	var player := _find_player()
	if player == null:
		return

	# Запускаємо 6-кадрову анімацію пострілу ворога (Рядок 1)
	_shoot_anim_timer = _shoot_anim_duration
	if body_sprite:
		body_sprite.frame_coords = Vector2i(0, ENEMY_ROW_SHOOT)
		_spawn_enemy_shell()

	var target_pos := _locked_aim_pos if _has_locked_aim else (player.global_position + Vector2(0.0, -8.0))
	if not use_sniper_laser:
		target_pos += Vector2(randf_range(-6.0, 6.0), randf_range(-9.0, 9.0))

	if shot_line:
		shot_line.visible = false

	var parent_node := get_parent()
	if parent_node != null:
		var proj := Projectile.new()
		var b_type := Projectile.BulletType.SNIPER_RED if use_sniper_laser else Projectile.BulletType.ENEMY_BLUE
		proj.setup(
			b_type,
			muzzle_pos,
			target_pos,
			attack_damage,
			projectile_speed,
			true
		)
		parent_node.add_child(proj)


func _spawn_step_dust(is_near_foot: bool) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var foot_offset := Vector2(-12.0, 36.0) if is_near_foot else Vector2(-16.0, 34.0)
	for i in range(2):
		var puff := Polygon2D.new()
		puff.color = Color(0.58, 0.49, 0.38, 0.48)
		var r := randf_range(2.6, 4.2)
		puff.polygon = PackedVector2Array([
			Vector2(-r, -r * 0.6),
			Vector2(r * 0.7, -r),
			Vector2(r, r * 0.5),
			Vector2(-r * 0.6, r),
		])
		puff.global_position = global_position + foot_offset + Vector2(randf_range(-4.0, 4.0), randf_range(-2.0, 2.0))
		puff.z_index = -1
		parent_node.add_child(puff)

		var target := puff.global_position + Vector2(randf_range(8.0, 18.0), randf_range(-10.0, -3.0))
		var tween := puff.create_tween()
		tween.set_parallel(true)
		tween.tween_property(puff, "global_position", target, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(puff, "scale", Vector2(1.4, 1.4), 0.22)
		tween.tween_property(puff, "modulate:a", 0.0, 0.22)
		tween.chain().tween_callback(puff.queue_free)


func _spawn_enemy_shell() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var shell := Polygon2D.new()
	shell.color = Color(0.95, 0.78, 0.28, 0.95)
	shell.polygon = PackedVector2Array([
		Vector2(-2.8, -1.1),
		Vector2(2.8, -1.1),
		Vector2(2.8, 1.1),
		Vector2(-2.8, 1.1),
	])
	shell.global_position = global_position + Vector2(-10.0, -4.0)
	parent_node.add_child(shell)

	var peak := shell.global_position + Vector2(randf_range(10.0, 22.0), randf_range(-22.0, -12.0))
	var land := shell.global_position + Vector2(randf_range(16.0, 32.0), randf_range(24.0, 36.0))
	var tween := shell.create_tween()
	tween.tween_property(shell, "global_position", peak, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(shell, "rotation", 3.5, 0.10)
	tween.tween_property(shell, "global_position", land, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(shell, "rotation", 8.0, 0.14)
	tween.tween_property(shell, "modulate:a", 0.0, 0.20)
	tween.tween_callback(shell.queue_free)


func take_damage(amount: float) -> bool:
	if state == State.DEAD or amount <= 0.0:
		return false

	health -= amount
	if health <= 0.0:
		_enter_dead_state()
		return true

	_hurt_anim_timer = _hurt_anim_duration
	if body_sprite:
		body_sprite.frame_coords = Vector2i(0, ENEMY_ROW_HURT)
	_flash_hit()
	return false


func _enter_dead_state() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	_death_anim_timer = 0.0
	_blood_splashed = false
	collision_layer = 0
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if shot_line:
		shot_line.visible = false
	if _target_marker:
		_target_marker.visible = false

	died.emit()

	if is_inside_tree():
		if body_sprite:
			body_sprite.frame_coords = Vector2i(0, ENEMY_ROW_DEATH)
			body_sprite.modulate = Color(1.6, 0.55, 0.55, 1.0)
			# Інерційний зсув тіла назад під час падіння під власною вагою
			var fall_tween := create_tween()
			fall_tween.set_parallel(true)
			fall_tween.tween_property(body_sprite, "position", Vector2(16.0, 8.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			fall_tween.tween_property(body_sprite, "modulate", Color(0.75, 0.65, 0.65, 1.0), 0.28)

			var cleanup_tween := create_tween()
			cleanup_tween.tween_interval(1.15)
			cleanup_tween.tween_property(self, "modulate:a", 0.0, 0.35)
			cleanup_tween.tween_callback(queue_free)
		else:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(self, "modulate", Color(0.25, 0.05, 0.05, 0.0), 0.22)
			tween.tween_property(self, "rotation", 1.25, 0.22)
			tween.chain().tween_callback(queue_free)
	else:
		queue_free()


func _spawn_ground_blood_splatter() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var impact_center := global_position + Vector2(14.0, 34.0)

	# 1. Калюжа крові на землі під тілом (як у The Peacekeeper)
	var puddle := Node2D.new()
	puddle.global_position = impact_center
	puddle.z_index = -2
	puddle.scale = Vector2(0.15, 0.15)
	parent_node.add_child(puddle)

	var main_pool := Polygon2D.new()
	main_pool.color = Color(0.52, 0.05, 0.07, 0.86)
	var pool_pts := PackedVector2Array()
	for i in range(14):
		var ang := float(i) * TAU / 14.0
		var rx := 34.0 + sin(float(i) * 2.3) * 6.0
		var ry := 10.0 + cos(float(i) * 3.1) * 2.2
		pool_pts.append(Vector2(cos(ang) * rx, sin(ang) * ry))
	main_pool.polygon = pool_pts
	puddle.add_child(main_pool)

	var inner_pool := Polygon2D.new()
	inner_pool.color = Color(0.74, 0.08, 0.10, 0.90)
	var inner_pts := PackedVector2Array()
	for i in range(12):
		var ang := float(i) * TAU / 12.0
		inner_pts.append(Vector2(cos(ang) * 22.0, sin(ang) * 6.5))
	inner_pool.polygon = inner_pts
	puddle.add_child(inner_pool)

	var puddle_tween := puddle.create_tween()
	puddle_tween.tween_property(puddle, "scale", Vector2(1.0, 1.0), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	puddle_tween.tween_interval(4.5)
	puddle_tween.tween_property(puddle, "modulate:a", 0.0, 1.2)
	puddle_tween.tween_callback(puddle.queue_free)

	# 2. Бризки крові, що розлітаються вгору та вбоки при ударі тіла об землю
	for i in range(14):
		var drop := Polygon2D.new()
		var is_bright := (i % 3 == 0)
		drop.color = Color(0.86, 0.10, 0.12, 0.95) if is_bright else Color(0.60, 0.05, 0.07, 0.92)
		var r := randf_range(2.2, 4.8)
		drop.polygon = PackedVector2Array([
			Vector2(-r, -r * 0.65),
			Vector2(0.0, -r),
			Vector2(r, 0.0),
			Vector2(0.0, r * 0.75),
		])
		drop.global_position = impact_center + Vector2(randf_range(-16.0, 16.0), randf_range(-10.0, -2.0))
		drop.rotation = randf_range(0.0, TAU)
		parent_node.add_child(drop)

		var spread_x := randf_range(-52.0, 56.0)
		var peak_y := randf_range(-38.0, -14.0)
		var peak_pos := drop.global_position + Vector2(spread_x * 0.55, peak_y)
		var land_pos := impact_center + Vector2(spread_x, randf_range(-6.0, 10.0))
		var t_up := randf_range(0.09, 0.14)
		var t_down := randf_range(0.11, 0.17)

		var dtween := drop.create_tween()
		dtween.tween_property(drop, "global_position", peak_pos, t_up).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		dtween.parallel().tween_property(drop, "rotation", drop.rotation + randf_range(-2.5, 2.5), t_up)
		dtween.tween_property(drop, "global_position", land_pos, t_down).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		dtween.tween_property(drop, "scale", Vector2(1.35, 0.55), 0.06)
		dtween.tween_interval(1.8)
		dtween.tween_property(drop, "modulate:a", 0.0, 0.6)
		dtween.tween_callback(drop.queue_free)


func _flash_hit() -> void:
	if not is_inside_tree():
		return
	if body_sprite:
		body_sprite.modulate = Color(2.0, 0.55, 0.50, 1.0)
		var tween := create_tween()
		tween.tween_property(body_sprite, "modulate", Color.WHITE, 0.14)
	elif body_rect:
		body_rect.color = Color(1.0, 0.9, 0.75, 1.0)
		var tween := create_tween()
		tween.tween_property(body_rect, "color", _base_color, 0.09)


func _update_shot_visual(delta: float) -> void:
	if _shot_visual_timer > 0.0:
		_shot_visual_timer -= delta
		if _shot_visual_timer <= 0.0 and shot_line:
			shot_line.visible = false


func _find_player() -> Node2D:
	if not is_inside_tree():
		return null
	var p := get_tree().get_first_node_in_group("player") as Node2D
	if p != null:
		return p
	var scene := get_tree().current_scene
	if scene != null:
		return scene.find_child("Player", true, false) as Node2D
	return null


func _get_trench_x() -> float:
	var p := _find_player()
	if p != null:
		return minf(p.global_position.x, 260.0)
	return 185.0


func _create_target_marker() -> void:
	_target_marker = Polygon2D.new()
	_target_marker.top_level = true
	_target_marker.visible = false
	_target_marker.z_index = -1
	_target_marker.color = Color(1.0, 0.18, 0.12, 0.72)
	var pts := PackedVector2Array()
	for i in range(16):
		var angle := float(i) * TAU / 16.0
		pts.append(Vector2(cos(angle) * 20.0, sin(angle) * 7.0))
	_target_marker.polygon = pts
	add_child(_target_marker)
