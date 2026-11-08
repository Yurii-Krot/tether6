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

const GRENADIER_ROCKET_SCRIPT := preload("res://scripts/grenadier_rocket.gd")
const WARNING_BEEP_STREAM := preload("res://assets/warning_beep.mp3")
const TRENCH_TILES_Y: Array[float] = [395.0, 495.0, 595.0]
const TILE_HALF_HEIGHT := 48.0
const TILE_HALF_WIDTH := 42.0

@export var health := 80.0
@export var speed := 155.0
@export var stop_distance := 520.0
@export var attack_interval := 1.6
@export var attack_damage := 7.0
@export var projectile_speed := 540.0
@export var burst_count := 1
@export var burst_interval := 0.12
@export var pellet_count := 1
@export var spread_angle_deg := 28.0
@export var shoot_straight := false
@export var use_red_bullet := false
@export var is_stationary := false
@export var use_sniper_laser := false
@export var use_trench_tile_launcher := false

var state: State = State.ADVANCE
var _max_health := 80.0
var _stop_x := 525.0
var _has_custom_stop_x := false
var _attack_timer := 0.0
var _shot_visual_timer := 0.0
var _base_color := Color.WHITE
var _has_locked_aim := false
var _locked_aim_pos := Vector2.ZERO
var _target_marker: Polygon2D = null
var _trench_warning_node: Node2D = null
var _beep_player: AudioStreamPlayer = null
var _hp_bar_root: Node2D = null
var _hp_bar_fill: Polygon2D = null
var _hp_bar_timer := 0.0

const HP_BAR_SHOW_DURATION := 0.52
const HP_BAR_WIDTH := 64.0
const HP_BAR_HEIGHT := 7.0

var _anim_time := 0.0
var _shoot_anim_timer := 0.0
var _shoot_anim_duration := 0.24
var _hurt_anim_timer := 0.0
var _hurt_anim_duration := 0.14
var _hit_flash_timer := 0.0
var _death_anim_timer := 0.0
var _death_anim_duration := 0.48
var _blood_splashed := false
var _base_sprite_scale := Vector2(0.62, 0.62)
var _last_step_col := -1
var _burst_shots_remaining := 0
var _burst_timer := 0.0

# Десантування з вертольота по канату (fast-rope)
var _rappel_active := false
var _rappel_anchor_node: Node2D = null
var _rappel_from := Vector2.ZERO
var _rappel_to := Vector2.ZERO
var _rappel_t := 0.0
var _rappel_duration := 1.0
var _rappel_rope: Line2D = null
var _shadow_base_pos := Vector2.ZERO

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_sprite: Sprite2D = get_node_or_null("BodySprite")
@onready var body_rect: ColorRect = get_node_or_null("ColorRect")
@onready var shadow: Polygon2D = get_node_or_null("Shadow")
@onready var shot_line: Line2D = get_node_or_null("ShotLine")
@onready var shot_sound: AudioStreamPlayer = get_node_or_null("ShotSound")


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 0
	_max_health = maxf(health, 1.0)
	_create_target_marker()
	_create_hp_bar()
	if use_trench_tile_launcher:
		_beep_player = AudioStreamPlayer.new()
		_beep_player.stream = WARNING_BEEP_STREAM
		_beep_player.volume_db = -1.0
		add_child(_beep_player)

	# Невеликий випадковий зсув фази кроку, щоб загін ворогів крокував природно, а не синхронно
	_anim_time = randf_range(0.0, 10.0)

	if body_sprite:
		_base_sprite_scale = body_sprite.scale
	if use_sniper_laser:
		_shoot_anim_duration = 0.42
		if is_equal_approx(projectile_speed, 540.0):
			projectile_speed = 1650.0
	elif pellet_count > 1:
		# Довша тривалість анімації пострілу дробовика, щоб було добре видно пересмикування помпової цівки та виліт гільзи
		_shoot_anim_duration = 0.48
	if shot_line:
		shot_line.visible = false
	if body_rect:
		_base_color = body_rect.color

	if not _has_custom_stop_x:
		var trench_x := _get_trench_x()
		_stop_x = trench_x + stop_distance + randf_range(-55.0, 75.0)

	if is_stationary:
		state = State.ATTACK
		_attack_timer = attack_interval * randf_range(0.6, 1.0)
	else:
		state = State.ADVANCE
		_attack_timer = attack_interval * 0.5


func set_custom_stop_x(custom_x: float) -> void:
	_has_custom_stop_x = true
	_stop_x = custom_x


func _physics_process(delta: float) -> void:
	_anim_time += delta
	_update_shot_visual(delta)
	_update_hit_flash(delta)
	_update_hp_bar(delta)
	if _trench_warning_node and is_instance_valid(_trench_warning_node):
		_trench_warning_node.queue_redraw()

	if _rappel_active and state != State.DEAD:
		_process_rappel(delta)
		return

	_update_sprite_animation(delta)

	match state:
		State.ADVANCE:
			_process_advance()
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			velocity = Vector2.ZERO


## Запускає спуск по канату з вертольота: anchor_node має метод get_rope_anchor() -> Vector2 (глобальна точка кріплення каната в дверях).
func start_rappel(anchor_node: Node2D, from_pos: Vector2, land_pos: Vector2) -> void:
	_rappel_active = true
	_rappel_anchor_node = anchor_node
	_rappel_from = from_pos
	_rappel_to = land_pos
	_rappel_t = 0.0
	_rappel_duration = clampf((land_pos.y - from_pos.y) / 430.0, 0.6, 1.35)
	global_position = from_pos
	velocity = Vector2.ZERO
	if shadow:
		_shadow_base_pos = shadow.position

	_rappel_rope = Line2D.new()
	_rappel_rope.top_level = true
	_rappel_rope.width = 3.0
	_rappel_rope.default_color = Color(0.16, 0.12, 0.08, 0.95)
	_rappel_rope.z_index = -1
	_rappel_rope.points = PackedVector2Array([from_pos, from_pos])
	add_child(_rappel_rope)


func _get_rope_top() -> Vector2:
	if _rappel_anchor_node != null and is_instance_valid(_rappel_anchor_node) and _rappel_anchor_node.has_method("get_rope_anchor"):
		return _rappel_anchor_node.get_rope_anchor()
	return _rappel_from


func _process_rappel(delta: float) -> void:
	_rappel_t = minf(_rappel_t + delta / _rappel_duration, 1.0)
	# Різкий стрибок з дверей, швидке ковзання вниз і гальмування руками перед самою землею
	var eased := _rappel_t * _rappel_t * (3.0 - 2.0 * _rappel_t)
	eased = lerpf(_rappel_t, eased, 0.65)

	var rope_top := _get_rope_top()
	# Канат тягнеться від дверей до точки приземлення, боєць ковзає по ньому
	var rope_bottom := Vector2(_rappel_to.x, _rappel_to.y - 30.0)
	var pos := rope_top.lerp(Vector2(_rappel_to.x, _rappel_to.y), eased)
	pos.y = lerpf(_rappel_from.y, _rappel_to.y, eased)
	global_position = pos

	if _rappel_rope:
		_rappel_rope.points = PackedVector2Array([rope_top, rope_bottom.lerp(rope_bottom + Vector2(0.0, 20.0), eased)])

	if body_sprite:
		# Поза "ноги разом" з кадру ходьби + легке розгойдування на канаті
		var cols := maxi(body_sprite.hframes, 1)
		body_sprite.frame_coords = Vector2i(cols / 4, ENEMY_ROW_WALK)
		body_sprite.rotation = sin(_anim_time * 9.0) * 0.06 * (1.0 - _rappel_t)

	# Тінь лишається на землі в точці приземлення й росте при наближенні бійця
	if shadow:
		var height := _rappel_to.y - global_position.y
		shadow.position = _shadow_base_pos + Vector2(0.0, height)
		var s := lerpf(0.45, 1.0, clampf(1.0 - height / 380.0, 0.0, 1.0))
		shadow.scale = Vector2(s, s)

	if _rappel_t >= 1.0:
		_finish_rappel()


func _finish_rappel() -> void:
	_rappel_active = false
	global_position = _rappel_to
	if shadow:
		shadow.position = _shadow_base_pos
		shadow.scale = Vector2.ONE
	if body_sprite:
		body_sprite.rotation = 0.0
		# Присідання при приземленні
		body_sprite.scale = Vector2(_base_sprite_scale.x * 1.14, _base_sprite_scale.y * 0.84)
		var land_tween := create_tween()
		land_tween.tween_property(body_sprite, "scale", _base_sprite_scale, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_spawn_step_dust(true)
	_spawn_step_dust(false)
	_release_rope()
	state = State.ADVANCE
	_attack_timer = attack_interval * randf_range(0.5, 0.9)


func _release_rope() -> void:
	if _rappel_rope == null or not is_instance_valid(_rappel_rope):
		return
	var rope := _rappel_rope
	_rappel_rope = null
	# Відпущений канат підтягується вгору до вертольота й зникає
	var top := rope.points[0]
	var rt := rope.create_tween()
	rt.set_parallel(true)
	rt.tween_method(func(v: float) -> void:
		if is_instance_valid(rope) and rope.points.size() == 2:
			rope.points = PackedVector2Array([rope.points[0], rope.points[1].lerp(top, v)])
	, 0.0, 0.35, 0.35)
	rt.tween_property(rope, "modulate:a", 0.0, 0.35)
	rt.chain().tween_callback(rope.queue_free)


func _update_sprite_animation(delta: float) -> void:
	if body_sprite == null:
		return

	var cols := maxi(body_sprite.hframes, 1)
	var rows := maxi(body_sprite.vframes, 1)
	var is_six_row := (rows >= 6)
	var row_shoot := 2 if is_six_row else ENEMY_ROW_SHOOT
	var row_hurt := 3 if is_six_row else ENEMY_ROW_HURT
	var row_death := 4 if is_six_row else ENEMY_ROW_DEATH

	if state == State.DEAD:
		_death_anim_timer += delta
		var raw_t := clampf(_death_anim_timer / _death_anim_duration, 0.0, 1.0)
		var gravity_t := raw_t if is_six_row else pow(raw_t, 1.65)
		var d_col := clampi(int(gravity_t * float(cols)), 0, cols - 1)

		if is_six_row and _death_anim_timer > _death_anim_duration:
			# Рядок 5 (кадри 0..5): тіло лежить на землі й поступово вицвітає у прозорий білий силует, як на референсі
			var fade_t := clampf((_death_anim_timer - _death_anim_duration) / 0.85, 0.0, 1.0)
			var f_col := clampi(int(fade_t * 6.0), 0, 5)
			body_sprite.frame_coords = Vector2i(f_col, 5)
		else:
			body_sprite.frame_coords = Vector2i(d_col, row_death)

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
		var hurt_frames := 3 if is_six_row else cols
		var h_col := clampi(int(h_prog * float(hurt_frames)), 0, hurt_frames - 1)
		body_sprite.frame_coords = Vector2i(h_col, row_hurt)
		return

	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		var s_prog := 1.0 - (_shoot_anim_timer / _shoot_anim_duration)
		if is_six_row:
			var s_col := clampi(1 + int(s_prog * float(cols - 1)), 1, cols - 1)
			body_sprite.frame_coords = Vector2i(s_col, row_shoot)
		else:
			var s_col := clampi(int(s_prog * float(cols)), 0, cols - 1)
			body_sprite.frame_coords = Vector2i(s_col, row_shoot)
		return

	if state == State.ADVANCE:
		if is_six_row:
			# 24-кадрова покадрова анімація бігу у 2 рядках (Рядок 0 + Рядок 1, по 12 кадрів у кожному)
			var walk_fps_24 := 24.0
			var total_walk_frames := cols * 2
			var step_idx := int(_anim_time * walk_fps_24) % total_walk_frames
			var w_row := step_idx / cols
			var w_col := step_idx % cols
			body_sprite.frame_coords = Vector2i(w_col, w_row)

			var cycle_phase := (_anim_time * walk_fps_24 / float(total_walk_frames)) * TAU
			if shadow:
				var stride_width := cos(cycle_phase * 2.0)
				shadow.scale = Vector2(1.0 + 0.14 * stride_width, 1.0 - 0.05 * stride_width)

			if step_idx != _last_step_col:
				_last_step_col = step_idx
				if step_idx == 0 or step_idx == cols:
					_spawn_step_dust(step_idx == 0)
		else:
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
		# У режимі атаки між пострілами тримає бойову стійку
		if shadow:
			shadow.scale = Vector2.ONE
		if is_six_row:
			body_sprite.frame_coords = Vector2i(0, row_shoot)
		else:
			var ready_col := (cols - 2) + (int(_anim_time * 3.5) % 2)
			body_sprite.frame_coords = Vector2i(ready_col, row_shoot)


func _process_advance() -> void:
	var trench_x := _get_trench_x()
	var target_x := _stop_x if _has_custom_stop_x else maxf(_stop_x, trench_x + stop_distance - 60.0)
	if global_position.x <= target_x:
		velocity = Vector2.ZERO
		state = State.ATTACK
		return

	velocity = Vector2.LEFT * speed
	move_and_slide()


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO

	var muzzle_offset := Vector2(-46.0, -3.2)
	if body_sprite != null:
		if use_sniper_laser:
			muzzle_offset = Vector2(-114.0, -8.0)
		elif use_trench_tile_launcher:
			muzzle_offset = Vector2(-82.0, -5.0)
		elif shoot_straight or burst_count > 1:
			muzzle_offset = Vector2(-104.0, -9.0)
		elif pellet_count > 1:
			muzzle_offset = Vector2(-90.0, -15.0)
		else:
			muzzle_offset = Vector2(-75.0, 0.0)
	var muzzle_pos := global_position + muzzle_offset

	# Якщо триває черга пострілів (наприклад, 8 куль поспіль у кулеметника)
	if _burst_shots_remaining > 0:
		_burst_timer -= delta
		if _burst_timer <= 0.0:
			_burst_shots_remaining -= 1
			_burst_timer = burst_interval
			_perform_attack(muzzle_pos)
			if _burst_shots_remaining == 0:
				_attack_timer = attack_interval
		return

	_attack_timer -= delta
	var lock_window := 0.30 if use_trench_tile_launcher else (0.85 if use_sniper_laser else 0.38)

	if not shoot_straight and _attack_timer <= lock_window and _attack_timer > 0.0 and not _has_locked_aim:
		if use_trench_tile_launcher:
			_locked_aim_pos = _choose_trench_tile_target()
			_has_locked_aim = true
			_spawn_trench_tile_warning(_locked_aim_pos)
			if _beep_player:
				_beep_player.play()
		else:
			var p := _find_player()
			if p:
				_locked_aim_pos = p.global_position + Vector2(0.0, -8.0)
				_has_locked_aim = true
				if _target_marker:
					_target_marker.global_position = Vector2(_locked_aim_pos.x, _locked_aim_pos.y + 30.0)
					_target_marker.visible = true

	if _attack_timer <= 0.0:
		if _target_marker:
			_target_marker.visible = false
		_burst_shots_remaining = maxi(burst_count, 1) - 1
		_burst_timer = burst_interval
		_perform_attack(muzzle_pos)
		if _burst_shots_remaining == 0:
			_attack_timer = attack_interval
		_has_locked_aim = false


func _perform_attack(muzzle_pos: Vector2) -> void:
	var player := _find_player()
	if player == null and not shoot_straight and not use_trench_tile_launcher:
		return

	# Запускаємо анімацію пострілу ворога та звук пострілу (якщо заданий)
	_shoot_anim_timer = _shoot_anim_duration
	if body_sprite:
		var is_six_row := body_sprite.vframes >= 6
		body_sprite.frame_coords = Vector2i(1 if is_six_row else 0, 2 if is_six_row else ENEMY_ROW_SHOOT)
		if not use_trench_tile_launcher:
			_spawn_enemy_shell()
	if shot_sound:
		shot_sound.pitch_scale = randf_range(0.76, 0.84) if use_trench_tile_launcher else (randf_range(0.96, 1.04) if not use_sniper_laser else randf_range(0.98, 1.02))
		shot_sound.play()

	if use_trench_tile_launcher:
		var tile_target := _locked_aim_pos if _has_locked_aim else _choose_trench_tile_target()
		var parent_node := get_parent()
		if parent_node != null:
			var rocket: Node2D = GRENADIER_ROCKET_SCRIPT.new()
			var warn_to_pass := _trench_warning_node
			_trench_warning_node = null
			rocket.setup(muzzle_pos, tile_target, projectile_speed, attack_damage, warn_to_pass)
			parent_node.add_child(rocket)
		return

	var target_pos: Vector2
	if shoot_straight:
		# Стріляє строго прямо горизонтально вліво
		target_pos = muzzle_pos + Vector2(-1200.0, 0.0)
	else:
		target_pos = _locked_aim_pos if _has_locked_aim else (player.global_position + Vector2(0.0, -8.0))
		if not use_sniper_laser:
			target_pos += Vector2(randf_range(-6.0, 6.0), randf_range(-9.0, 9.0))

	if shot_line:
		shot_line.visible = false

	var parent_node := get_parent()
	if parent_node != null:
		var b_type := Projectile.BulletType.SNIPER_RED if (use_sniper_laser or use_red_bullet) else Projectile.BulletType.ENEMY_BLUE
		var total_pellets := maxi(pellet_count, 1)
		if total_pellets == 1:
			var proj := Projectile.new()
			proj.setup(
				b_type,
				muzzle_pos,
				target_pos,
				attack_damage,
				projectile_speed,
				false
			)
			parent_node.add_child(proj)
		else:
			# Постріл з дробовика віялом: одразу 5 куль одночасно під різними кутами!
			var base_dir := (target_pos - muzzle_pos).normalized()
			if base_dir.length_squared() < 0.001:
				base_dir = Vector2.LEFT
			for i in range(total_pellets):
				var frac := (float(i) / float(total_pellets - 1)) - 0.5
				var angle_rad := deg_to_rad(frac * spread_angle_deg + randf_range(-1.2, 1.2))
				var pellet_dir := base_dir.rotated(angle_rad)
				var pellet_target := muzzle_pos + pellet_dir * 1000.0
				var proj := Projectile.new()
				proj.setup(
					b_type,
					muzzle_pos,
					pellet_target,
					attack_damage,
					projectile_speed * randf_range(0.96, 1.04),
					false
				)
				parent_node.add_child(proj)


func _spawn_step_dust(is_near_foot: bool) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var foot_offset := Vector2(-14.0, 43.0) if is_near_foot else Vector2(-19.0, 41.0)
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
	if pellet_count > 1:
		# Червона гільза 12-го калібру для дробовика
		shell.color = Color(0.85, 0.16, 0.16, 0.96)
		shell.polygon = PackedVector2Array([
			Vector2(-3.4, -1.5),
			Vector2(3.4, -1.5),
			Vector2(3.4, 1.5),
			Vector2(-3.4, 1.5),
		])
	else:
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

	if health > _max_health:
		_max_health = health
	health -= amount
	if health <= 0.0:
		_enter_dead_state()
		return true

	_show_hp_bar()
	_hurt_anim_timer = _hurt_anim_duration
	if body_sprite:
		var is_six_row := body_sprite.vframes >= 6
		body_sprite.frame_coords = Vector2i(0, 3 if is_six_row else ENEMY_ROW_HURT)
	_flash_hit()
	return false


func _enter_dead_state() -> void:
	var was_rappelling := _rappel_active
	_rappel_active = false
	_hit_flash_timer = 0.0
	_release_rope()
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
	if _trench_warning_node and is_instance_valid(_trench_warning_node):
		_trench_warning_node.queue_free()
		_trench_warning_node = null
	if _beep_player and _beep_player.playing:
		_beep_player.stop()
	if _hp_bar_root:
		_hp_bar_root.visible = false
	_hp_bar_timer = 0.0

	died.emit()

	if is_inside_tree() and was_rappelling:
		# Збитий на канаті — зривається й падає на землю в точку приземлення
		if body_sprite:
			body_sprite.rotation = 0.0
		if shadow:
			shadow.position = _shadow_base_pos
			shadow.scale = Vector2.ONE
		var drop_tween := create_tween()
		drop_tween.tween_property(self, "global_position", _rappel_to, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if is_inside_tree():
		if body_sprite:
			var is_six_row := body_sprite.vframes >= 6
			body_sprite.frame_coords = Vector2i(0, 4 if is_six_row else ENEMY_ROW_DEATH)
			if is_six_row:
				body_sprite.modulate = Color.WHITE
				var fall_tween := create_tween()
				fall_tween.tween_property(body_sprite, "position", Vector2(10.0, 4.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				body_sprite.modulate = Color(1.6, 0.55, 0.55, 1.0)
				# Інерційний зсув тіла назад під час падіння під власною вагою
				var fall_tween := create_tween()
				fall_tween.set_parallel(true)
				fall_tween.tween_property(body_sprite, "position", Vector2(16.0, 8.0), 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				fall_tween.tween_property(body_sprite, "modulate", Color(0.75, 0.65, 0.65, 1.0), 0.28)

			var cleanup_tween := create_tween()
			cleanup_tween.tween_interval(1.35)
			cleanup_tween.tween_property(self, "modulate:a", 0.0, 0.25)
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

	var impact_center := global_position + Vector2(17.0, 41.0)

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
	_hit_flash_timer = 0.072
	if body_sprite:
		body_sprite.modulate = Color(2.35, 0.28, 0.28, 1.0)
	elif body_rect:
		body_rect.color = Color(1.0, 0.35, 0.35, 1.0)


func _update_hit_flash(delta: float) -> void:
	if state == State.DEAD or _hit_flash_timer <= 0.0:
		return
	_hit_flash_timer = maxf(_hit_flash_timer - delta, 0.0)
	if body_sprite:
		if _hit_flash_timer > 0.028:
			body_sprite.modulate = Color(2.35, 0.28, 0.28, 1.0)
		elif _hit_flash_timer > 0.0:
			var t := _hit_flash_timer / 0.028
			body_sprite.modulate = Color.WHITE.lerp(Color(2.35, 0.28, 0.28, 1.0), t)
		else:
			body_sprite.modulate = Color.WHITE
	elif body_rect:
		if _hit_flash_timer <= 0.0:
			body_rect.color = _base_color


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


func _create_hp_bar() -> void:
	_hp_bar_root = Node2D.new()
	_hp_bar_root.position = Vector2(0.0, -70.0)
	_hp_bar_root.z_index = 20
	_hp_bar_root.visible = false
	add_child(_hp_bar_root)

	var half_w := HP_BAR_WIDTH * 0.5
	var half_h := HP_BAR_HEIGHT * 0.5

	# Напівпрозора темна тінь знизу-справа (точно як на скріншоті)
	var bar_shadow := Polygon2D.new()
	bar_shadow.color = Color(0.0, 0.0, 0.0, 0.42)
	bar_shadow.position = Vector2(1.8, 1.8)
	bar_shadow.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	])
	_hp_bar_root.add_child(bar_shadow)

	# Чорна підкладка шкали HP
	var bar_bg := Polygon2D.new()
	bar_bg.color = Color(0.05, 0.05, 0.05, 0.96)
	bar_bg.polygon = PackedVector2Array([
		Vector2(-half_w, -half_h),
		Vector2(half_w, -half_h),
		Vector2(half_w, half_h),
		Vector2(-half_w, half_h),
	])
	_hp_bar_root.add_child(bar_bg)

	# Яскраво-червоне заповнення HP (масштабується зліва направо)
	_hp_bar_fill = Polygon2D.new()
	_hp_bar_fill.color = Color(0.95, 0.08, 0.08, 1.0)
	_hp_bar_fill.position = Vector2(-half_w, 0.0)
	_hp_bar_fill.polygon = PackedVector2Array([
		Vector2(0.0, -half_h),
		Vector2(HP_BAR_WIDTH, -half_h),
		Vector2(HP_BAR_WIDTH, half_h),
		Vector2(0.0, half_h),
	])
	_hp_bar_root.add_child(_hp_bar_fill)


func _show_hp_bar() -> void:
	if _hp_bar_root == null or _hp_bar_fill == null:
		return
	var ratio := clampf(health / maxf(_max_health, 1.0), 0.0, 1.0)
	_hp_bar_fill.scale.x = ratio
	_hp_bar_timer = HP_BAR_SHOW_DURATION
	_hp_bar_root.visible = true
	_hp_bar_root.modulate.a = 1.0


func _update_hp_bar(delta: float) -> void:
	if _hp_bar_timer <= 0.0 or _hp_bar_root == null:
		return
	_hp_bar_timer -= delta
	if _hp_bar_timer <= 0.0:
		_hp_bar_timer = 0.0
		_hp_bar_root.visible = false
	elif _hp_bar_timer < 0.12:
		_hp_bar_root.modulate.a = clampf(_hp_bar_timer / 0.12, 0.0, 1.0)


func _choose_trench_tile_target() -> Vector2:
	var tx := _get_trench_x()
	var p := _find_player()
	if p != null and not p.get("is_dead"):
		var best_idx := 1
		var best_dist := INF
		for i in range(TRENCH_TILES_Y.size()):
			var d := absf(p.global_position.y - TRENCH_TILES_Y[i])
			if d < best_dist:
				best_dist = d
				best_idx = i
		return Vector2(tx, TRENCH_TILES_Y[best_idx])
	return Vector2(tx, TRENCH_TILES_Y[randi() % TRENCH_TILES_Y.size()])


func _spawn_trench_tile_warning(tile_pos: Vector2) -> void:
	if _trench_warning_node and is_instance_valid(_trench_warning_node):
		_trench_warning_node.queue_free()
		_trench_warning_node = null

	var parent_node := get_parent()
	if parent_node == null:
		return

	_trench_warning_node = Node2D.new()
	_trench_warning_node.global_position = tile_pos
	_trench_warning_node.z_index = 3
	_trench_warning_node.draw.connect(_draw_trench_tile_warning)
	parent_node.add_child(_trench_warning_node)


func _draw_trench_tile_warning() -> void:
	if _trench_warning_node == null or not is_instance_valid(_trench_warning_node):
		return
	# Швидке мигання попереджувальної мітки в окопі під час 0.3 с звуку "пі-пі-пі"
	var pulse := 0.5 + 0.5 * sin(_anim_time * 52.0)
	var alpha := lerpf(0.28, 0.92, pulse)

	var rect := Rect2(
		-TILE_HALF_WIDTH,
		-TILE_HALF_HEIGHT + 4.0,
		TILE_HALF_WIDTH * 2.0,
		(TILE_HALF_HEIGHT - 4.0) * 2.0
	)
	_trench_warning_node.draw_rect(rect, Color(1.0, 0.16, 0.08, alpha * 0.48), true)
	_trench_warning_node.draw_rect(rect, Color(1.0, 0.35, 0.12, alpha), false, 2.6)
	_trench_warning_node.draw_arc(Vector2.ZERO, lerpf(24.0, 14.0, pulse), 0.0, TAU, 24, Color(1.0, 0.90, 0.25, alpha), 2.2)
	_trench_warning_node.draw_line(Vector2(-15.0, 0.0), Vector2(15.0, 0.0), Color(1.0, 0.25, 0.12, alpha), 2.2)
	_trench_warning_node.draw_line(Vector2(0.0, -15.0), Vector2(0.0, 15.0), Color(1.0, 0.25, 0.12, alpha), 2.2)


func _exit_tree() -> void:
	if _trench_warning_node and is_instance_valid(_trench_warning_node):
		_trench_warning_node.queue_free()
		_trench_warning_node = null
