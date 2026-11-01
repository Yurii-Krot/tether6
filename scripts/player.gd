extends Node2D

signal died
signal health_changed(current_health: float, max_health: float)
signal ammo_changed(current_ammo: int, magazine_size: int)
signal cover_changed(in_cover: bool)
signal roll_started(direction: float)
signal roll_finished

const CROSSHAIR_TEXTURE := preload("res://assets/crosshair.png")
const BASE_SPRITE_SCALE := Vector2(0.42, 0.42)
const SHOULDER_OFFSET_STAND := Vector2(-7.5, -5.0)
const SHOULDER_OFFSET_CROUCH := Vector2(-10.0, 5.5)
const EJECT_LOCAL_POS := Vector2(24.0, -4.0)

# Рядки у спрайт-листі тіла res://assets/player_spritesheet.png (6x4 кадри)
const ANIM_COLS := 6
const ANIM_ROW_IDLE := 0
const ANIM_ROW_SHOOT := 1
const ANIM_ROW_CROUCH := 2
const ANIM_ROW_ROLL := 3

@export var damage := 10.0
@export var fire_rate := 10.0 # 0.1 с між пострілами
@export var magazine_size := 30
@export var reload_time := 1.5
@export var max_health := 100.0
@export var recoil_distance := 4.5
@export var recoil_recovery_speed := 45.0

@export_group("Trench Roll")
@export var trench_min_y := 425.0
@export var trench_max_y := 630.0
@export var roll_distance := 95.0
@export var roll_duration := 0.28
@export var roll_cooldown := 0.07

var ammo := 30
var health := 100.0
var cooldown := 0.0
# У стані спокою боєць за замовчуванням захований в окопі (не отримує урон)
var is_in_cover := true
var is_rolling := false
var is_dead := false

var _reload_accumulator := 0.0
var _flash_timer := 0.0
var _recoil_offset := 0.0
var _recoil_angle := 0.0
var _roll_elapsed := 0.0
var _roll_cooldown_timer := 0.0
var _roll_start_y := 535.0
var _roll_target_y := 535.0
var _roll_dir := 0.0
var _afterimage_timer := 0.0
var _anim_time := 0.0
var _shoot_anim_timer := 0.0
var _shoot_anim_duration := 0.20
var _combat_expose_timer := 0.0
var _landing_squash_timer := 0.0
var _current_aim_angle := 0.0
var _damage_tint_timer := 0.0
var _hurt_flinch_timer := 0.0

@onready var shadow: Polygon2D = get_node_or_null("Shadow")
@onready var body: Sprite2D = $Body
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var barrel: Node2D = $WeaponPivot/Barrel
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponPivot/Barrel/WeaponSprite")
@onready var muzzle: Marker2D = $WeaponPivot/Barrel/Muzzle
@onready var muzzle_flash: Polygon2D = $WeaponPivot/Barrel/Muzzle/MuzzleFlash
@onready var tracer_line: Line2D = $TracerLine
@onready var health_bar_fill: ColorRect = $HUD/HealthBarFill
@onready var status_label: Label = $HUD/StatusLabel
@onready var shot_sound: AudioStreamPlayer = $ShotSound
@onready var reload_sound: AudioStreamPlayer = $ReloadSound


func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()

	ammo = magazine_size
	health = max_health
	position.y = clampf(position.y, trench_min_y, trench_max_y)

	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(CROSSHAIR_TEXTURE, Input.CURSOR_ARROW, Vector2(16, 16))

	_set_cover(true)
	_update_hud()


func _process(delta: float) -> void:
	_anim_time += delta
	_update_shot_effects(delta)

	if is_dead:
		return

	_roll_cooldown_timer = maxf(_roll_cooldown_timer - delta, 0.0)
	_landing_squash_timer = maxf(_landing_squash_timer - delta, 0.0)
	_hurt_flinch_timer = maxf(_hurt_flinch_timer - delta, 0.0)

	if is_rolling:
		_process_roll(delta)
	else:
		_handle_roll_input()

	var mouse_pos := get_global_mouse_position()
	cooldown = maxf(cooldown - delta, 0.0)

	# Логіка укриття: у стані спокою (коли не стріляємо) боєць захований в окопі й не отримує урон.
	# Коли затискаємо ЛКМ (shoot) і є патрони — висовується з окопу, веде гвинтівку за прицілом і стріляє.
	var force_cover := Input.is_action_pressed("cover")
	var wants_to_shoot := Input.is_action_pressed("shoot") and ammo > 0 and not force_cover and not is_rolling

	if wants_to_shoot:
		_combat_expose_timer = 0.16
	else:
		_combat_expose_timer = maxf(_combat_expose_timer - delta, 0.0)

	var should_be_in_cover := (_combat_expose_timer <= 0.0) or force_cover or (ammo <= 0)
	if not is_rolling and should_be_in_cover != is_in_cover:
		_set_cover(should_be_in_cover)

	_update_weapon_aim(delta, mouse_pos)

	if not is_rolling:
		_update_sprite_frame_animation(delta)

	if is_in_cover and not is_rolling:
		_process_reload_in_cover(delta)
	else:
		_reload_accumulator = 0.0
		if wants_to_shoot and cooldown <= 0.0 and ammo > 0:
			ammo -= 1
			cooldown = 1.0 / fire_rate
			shoot(mouse_pos)
			ammo_changed.emit(ammo, magazine_size)
			_update_hud()


func _update_weapon_aim(delta: float, mouse_pos: Vector2) -> void:
	if is_rolling:
		weapon_pivot.visible = false
		return

	weapon_pivot.visible = true
	var to_mouse := mouse_pos - weapon_pivot.global_position
	var raw_angle := atan2(to_mouse.y, maxf(to_mouse.x, 25.0))
	var clamped_aim := clampf(raw_angle, -0.78, 0.78)

	if is_in_cover:
		# В окопі гвинтівка опущена вниз-вперед і рухається під час перезарядки
		var reload_angle := 0.22 + (sin(_anim_time * 11.0) * 0.12 if ammo < magazine_size else sin(_anim_time * 3.0) * 0.03)
		_current_aim_angle = lerp_angle(_current_aim_angle, reload_angle, minf(delta * 14.0, 1.0))
		weapon_pivot.position = body.position + SHOULDER_OFFSET_CROUCH
		weapon_pivot.rotation = _current_aim_angle
		if weapon_sprite:
			weapon_sprite.frame = 0
			weapon_sprite.modulate = body.modulate
	else:
		# Під час стрільби гвинтівка з руками точно ходить за перехрестям мишки!
		_current_aim_angle = lerp_angle(_current_aim_angle, clamped_aim, minf(delta * 24.0, 1.0))
		weapon_pivot.position = body.position + SHOULDER_OFFSET_STAND
		weapon_pivot.rotation = _current_aim_angle + _recoil_angle
		if weapon_sprite:
			weapon_sprite.modulate = body.modulate


func _update_sprite_frame_animation(delta: float) -> void:
	body.rotation = 0.0

	# Пружинисте приземлення після перекату (squash & stretch)
	var land_squash := 0.0
	if _landing_squash_timer > 0.0:
		land_squash = sin((_landing_squash_timer / 0.14) * PI)

	if is_in_cover:
		# Рядок 2: у стані спокою боєць сидить пригнувшись глибоко в окопі (в безпеці)
		var reload_bob := sin(_anim_time * 11.0) * 1.5 if ammo < magazine_size else sin(_anim_time * 3.0) * 0.6
		body.position = Vector2(-10.0, 6.0 + reload_bob + land_squash * 4.0)
		body.scale = Vector2(
			BASE_SPRITE_SCALE.x * (1.0 + 0.12 * land_squash),
			BASE_SPRITE_SCALE.y * (1.0 - 0.14 * land_squash)
		)
		var col := int(_anim_time * 9.0) % ANIM_COLS if ammo < magazine_size else 0
		body.frame_coords = Vector2i(col, ANIM_ROW_CROUCH)
		if shadow:
			shadow.position = Vector2(-8.0, 38.0)
			shadow.scale = Vector2(1.12 + 0.1 * land_squash, 0.9)
		return

	# Бойова стійка під час стрільби (+ легке сіпання корпусу назад при отриманні болю)
	var hurt_flinch := sin((_hurt_flinch_timer / 0.20) * PI) if _hurt_flinch_timer > 0.0 else 0.0
	body.position = Vector2(-hurt_flinch * 6.5, land_squash * 3.5)
	body.rotation = -hurt_flinch * 0.09
	body.scale = Vector2(
		BASE_SPRITE_SCALE.x * (1.0 + 0.10 * land_squash - 0.05 * hurt_flinch),
		BASE_SPRITE_SCALE.y * (1.0 - 0.12 * land_squash + 0.04 * hurt_flinch)
	)
	if shadow:
		shadow.position = Vector2(0.0, 38.0)
		shadow.scale = Vector2.ONE

	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		var progress := 1.0 - (_shoot_anim_timer / _shoot_anim_duration)
		var shoot_col := clampi(int(progress * float(ANIM_COLS)), 0, ANIM_COLS - 1)
		body.frame_coords = Vector2i(shoot_col, ANIM_ROW_SHOOT)
		if weapon_sprite:
			# Кадри 1..5 на листі гвинтівки — фази пострілу, полум'я, газів та диму
			weapon_sprite.frame = clampi(1 + int(progress * 5.0), 1, 5)
	else:
		var idle_col := int(_anim_time * 6.5) % ANIM_COLS
		body.frame_coords = Vector2i(idle_col, ANIM_ROW_IDLE)
		if weapon_sprite:
			weapon_sprite.frame = 0


func shoot(aim: Vector2) -> void:
	var space_state := get_world_2d().direct_space_state
	var origin := muzzle.global_position
	var dir := (aim - origin).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.RIGHT

	var ray_end := origin + dir * 2000.0
	var target_collider: Object = null

	# Спочатку перевіряємо точне наведення хрестика (як у Peacekeeper)
	var point_query := PhysicsPointQueryParameters2D.new()
	point_query.position = aim
	point_query.collide_with_bodies = true
	var point_hits := space_state.intersect_point(point_query, 4)
	for hit_info in point_hits:
		var col: Object = hit_info.get("collider")
		if col and col.has_method("take_damage"):
			target_collider = col
			ray_end = aim
			break

	# Якщо під самим курсором ворога немає — пускаємо промінь вздовж лінії пострілу
	if target_collider == null:
		var ray_query := PhysicsRayQueryParameters2D.create(origin, ray_end)
		var ray_hit := space_state.intersect_ray(ray_query)
		if ray_hit:
			ray_end = ray_hit.position
			if ray_hit.collider and ray_hit.collider.has_method("take_damage"):
				target_collider = ray_hit.collider

	var hit_enemy := false
	if target_collider != null:
		hit_enemy = true
		target_collider.take_damage(damage)

	_trigger_shot_feedback(ray_end, hit_enemy)


func take_damage(amount: float) -> void:
	# У стані спокою (is_in_cover) та під час кувирка (is_rolling) боєць невразливий!
	if is_dead or is_in_cover or is_rolling or amount <= 0.0:
		return

	health = maxf(health - amount, 0.0)
	health_changed.emit(health, max_health)
	_update_hud()
	_flash_damage()

	if health <= 0.0:
		_die()


func _handle_roll_input() -> void:
	if _roll_cooldown_timer > 0.0:
		return

	var dir := 0.0
	if Input.is_action_just_pressed("roll_up"):
		dir = -1.0
	elif Input.is_action_just_pressed("roll_down"):
		dir = 1.0
	else:
		dir = Input.get_axis("roll_up", "roll_down")

	if is_zero_approx(dir):
		return

	var sign_dir := -1.0 if dir < 0.0 else 1.0
	var target_y := clampf(position.y + sign_dir * roll_distance, trench_min_y, trench_max_y)
	if absf(target_y - position.y) < 4.0:
		return

	_start_roll(sign_dir, target_y)


func _start_roll(direction: float, target_y: float) -> void:
	is_rolling = true
	_roll_dir = direction
	_roll_elapsed = 0.0
	_afterimage_timer = 0.0
	_roll_start_y = position.y
	_roll_target_y = target_y

	weapon_pivot.visible = false
	body.position = Vector2.ZERO
	body.rotation = 0.0
	body.modulate = Color.WHITE
	body.frame_coords = Vector2i(0, ANIM_ROW_ROLL)

	# Бризки землі та пилу з-під черевиків на старті стрибка-кувирка
	_spawn_trench_dust(global_position + Vector2(-4.0, 34.0), -direction)
	_spawn_roll_afterimage()
	roll_started.emit(direction)
	_update_hud()


func _process_roll(delta: float) -> void:
	_roll_elapsed += delta
	var duration := maxf(roll_duration, 0.05)
	var t := clampf(_roll_elapsed / duration, 0.0, 1.0)
	# Плавна S-подібна крива прискорення та гальмування з легким вильотом
	var eased := 1.0 - pow(1.0 - t, 2.4)

	position.y = lerpf(_roll_start_y, _roll_target_y, eased)

	# Дуга стрибка в окопі + плавне обертання + динамічний squash & stretch для живого кувирка!
	var arc := sin(t * PI)
	var step := clampi(int(t * float(ANIM_COLS)), 0, ANIM_COLS - 1)
	var roll_col := step if _roll_dir >= 0.0 else ((ANIM_COLS - 1) - step)
	body.frame_coords = Vector2i(roll_col, ANIM_ROW_ROLL)

	body.position = Vector2(arc * 15.0, -arc * 8.0)
	body.rotation = _roll_dir * (t * 0.55)
	var stretch := sin(t * PI * 2.0) * 0.12
	body.scale = Vector2(
		BASE_SPRITE_SCALE.x * (1.0 - stretch * 0.6),
		BASE_SPRITE_SCALE.y * (1.0 + stretch)
	)

	if shadow:
		shadow.position = Vector2(arc * 12.0, 38.0)
		shadow.scale = Vector2(1.0 - 0.42 * arc, 1.0 - 0.42 * arc)

	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0 and t < 0.92:
		_afterimage_timer = 0.042
		_spawn_roll_afterimage()

	if t >= 1.0:
		_finish_roll()


func _finish_roll() -> void:
	is_rolling = false
	position.y = _roll_target_y
	_roll_cooldown_timer = roll_cooldown
	_landing_squash_timer = 0.14
	body.rotation = 0.0
	body.scale = BASE_SPRITE_SCALE
	body.position = Vector2.ZERO

	# Пил і грудки землі при приземленні після кувирка
	_spawn_trench_dust(global_position + Vector2(0.0, 36.0), _roll_dir)

	var wants_to_shoot := Input.is_action_pressed("shoot") and ammo > 0 and not Input.is_action_pressed("cover")
	_set_cover(not wants_to_shoot)
	roll_finished.emit()
	_update_hud()


func _spawn_trench_dust(origin_pos: Vector2, push_dir: float) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	# Хмарки пилу та грудки окопної землі під час старту й приземлення кувирка
	for i in range(6):
		var particle := Polygon2D.new()
		var is_clod := (i % 2 == 0)
		particle.color = Color(0.36, 0.27, 0.18, 0.88) if is_clod else Color(0.62, 0.52, 0.40, 0.65)
		var r := randf_range(2.5, 4.8) if is_clod else randf_range(5.0, 8.5)
		particle.polygon = PackedVector2Array([
			Vector2(-r, -r * 0.7),
			Vector2(r * 0.8, -r),
			Vector2(r, r * 0.6),
			Vector2(-r * 0.7, r),
		])
		particle.global_position = origin_pos + Vector2(randf_range(-12.0, 12.0), randf_range(-4.0, 4.0))
		particle.rotation = randf_range(0.0, TAU)
		particle.z_index = -1
		parent_node.add_child(particle)

		var vel := Vector2(randf_range(-28.0, 28.0), randf_range(-26.0, -8.0) + push_dir * 10.0)
		var target_pos := particle.global_position + vel
		var dur := randf_range(0.18, 0.30)

		var tween := particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "global_position", target_pos, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(particle, "rotation", particle.rotation + randf_range(-3.0, 3.0), dur)
		tween.tween_property(particle, "scale", Vector2(1.4, 1.4) if not is_clod else Vector2(0.4, 0.4), dur)
		tween.tween_property(particle, "modulate:a", 0.0, dur)
		tween.chain().tween_callback(particle.queue_free)


func _spawn_roll_afterimage() -> void:
	var parent_node := get_parent()
	if parent_node == null or body.texture == null:
		return

	var ghost := Sprite2D.new()
	ghost.texture = body.texture
	ghost.hframes = body.hframes
	ghost.vframes = body.vframes
	ghost.frame_coords = body.frame_coords
	ghost.offset = body.offset
	ghost.global_position = body.global_position
	ghost.global_rotation = body.global_rotation
	ghost.scale = body.scale
	ghost.modulate = Color(1.0, 0.86, 0.32, 0.48)
	ghost.z_index = -1
	parent_node.add_child(ghost)

	var tween := ghost.create_tween()
	tween.set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.18)
	tween.tween_property(ghost, "scale", body.scale * 0.88, 0.18)
	tween.chain().tween_callback(ghost.queue_free)


func _set_cover(active: bool) -> void:
	is_in_cover = active
	cover_changed.emit(is_in_cover)

	if is_in_cover:
		if _damage_tint_timer <= 0.0:
			body.modulate = Color(0.72, 0.76, 0.80, 0.98)
		body.frame_coords = Vector2i(0, ANIM_ROW_CROUCH)
		muzzle_flash.visible = false
		tracer_line.visible = false
		if ammo < magazine_size:
			reload_sound.pitch_scale = 0.95
			reload_sound.play()
	else:
		if _damage_tint_timer <= 0.0:
			body.modulate = Color.WHITE
		body.position = Vector2.ZERO
		body.scale = BASE_SPRITE_SCALE
		body.frame_coords = Vector2i(0, ANIM_ROW_SHOOT)

	if weapon_sprite:
		weapon_sprite.modulate = body.modulate

	_update_hud()


func _process_reload_in_cover(delta: float) -> void:
	if ammo >= magazine_size:
		return

	var bullets_per_sec := float(magazine_size) / maxf(reload_time, 0.05)
	_reload_accumulator += delta * bullets_per_sec
	var added := int(_reload_accumulator)
	if added > 0:
		_reload_accumulator -= float(added)
		ammo = mini(ammo + added, magazine_size)
		ammo_changed.emit(ammo, magazine_size)
		if ammo == magazine_size:
			_reload_accumulator = 0.0
			reload_sound.pitch_scale = 1.12
			reload_sound.play()
		_update_hud()


func _trigger_shot_feedback(target_point: Vector2, hit_enemy: bool = false) -> void:
	_shoot_anim_timer = _shoot_anim_duration
	body.frame_coords = Vector2i(0, ANIM_ROW_SHOOT)
	if weapon_sprite:
		weapon_sprite.frame = 1

	# Трасер пострілу
	_flash_timer = 0.045
	muzzle_flash.visible = false
	tracer_line.clear_points()
	tracer_line.add_point(muzzle.global_position)
	tracer_line.add_point(target_point)
	tracer_line.visible = true

	# Звук
	shot_sound.pitch_scale = randf_range(0.95, 1.06)
	shot_sound.play()

	# Віддача вздовж лінії прицілювання
	_recoil_offset = recoil_distance
	_recoil_angle = randf_range(-0.055, -0.015)
	barrel.position.x = -_recoil_offset

	_spawn_shell_casing()
	_spawn_hit_sparks(target_point, hit_enemy)


func _spawn_shell_casing() -> void:
	var parent_node := get_parent()
	if parent_node == null or weapon_pivot == null:
		return

	var shell := Polygon2D.new()
	shell.color = Color(0.96, 0.80, 0.28, 0.98)
	shell.polygon = PackedVector2Array([
		Vector2(-3.2, -1.3),
		Vector2(3.2, -1.3),
		Vector2(3.2, 1.3),
		Vector2(-3.2, 1.3),
	])
	shell.global_position = barrel.to_global(EJECT_LOCAL_POS)
	shell.rotation = weapon_pivot.rotation + randf_range(-0.4, 0.4)
	parent_node.add_child(shell)

	var peak_pos := shell.global_position + Vector2(randf_range(-28.0, -14.0), randf_range(-28.0, -16.0))
	var land_pos := global_position + Vector2(randf_range(-34.0, -8.0), randf_range(26.0, 38.0))
	var bounce_pos := land_pos + Vector2(randf_range(-10.0, -4.0), randf_range(-5.0, 2.0))
	var spin := randf_range(-10.0, -5.0)

	var tween := shell.create_tween()
	tween.tween_property(shell, "global_position", peak_pos, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(shell, "rotation", shell.rotation + spin * 0.45, 0.10)
	tween.tween_property(shell, "global_position", land_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(shell, "rotation", shell.rotation + spin, 0.15)
	tween.tween_property(shell, "global_position", bounce_pos, 0.08).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tween.tween_interval(0.35)
	tween.tween_property(shell, "modulate:a", 0.0, 0.25)
	tween.tween_callback(shell.queue_free)


func _spawn_hit_sparks(impact_pos: Vector2, hit_enemy: bool) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	for i in range(3):
		var spark := Polygon2D.new()
		spark.color = Color(1.0, 0.32, 0.22, 0.95) if hit_enemy else Color(1.0, 0.88, 0.42, 0.92)
		spark.polygon = PackedVector2Array([
			Vector2(-4.0, -1.5),
			Vector2(4.0, 0.0),
			Vector2(-4.0, 1.5),
		])
		spark.global_position = impact_pos
		var angle := randf_range(-PI * 0.85, PI * 0.85)
		spark.rotation = angle
		parent_node.add_child(spark)

		var target := impact_pos + Vector2.RIGHT.rotated(angle) * randf_range(12.0, 26.0)
		var tween := spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", target, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector2(0.2, 0.2), 0.12)
		tween.tween_property(spark, "modulate:a", 0.0, 0.12)
		tween.chain().tween_callback(spark.queue_free)


func _update_shot_effects(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			muzzle_flash.visible = false
			tracer_line.visible = false

	if _damage_tint_timer > 0.0:
		_damage_tint_timer = maxf(_damage_tint_timer - delta, 0.0)
		if not is_dead:
			var base_col := Color(0.72, 0.76, 0.80, 0.98) if is_in_cover else Color.WHITE
			if _damage_tint_timer > 0.0:
				# Протягом 1 секунди мигає світло-червоним (6 пульсацій за секунду)
				var pulse := 0.5 + 0.5 * cos((1.0 - _damage_tint_timer) * TAU * 6.0)
				var hurt_col := Color(2.1, 0.52, 0.52, 1.0)
				body.modulate = base_col.lerp(hurt_col, pulse * 0.85)
			else:
				body.modulate = base_col
			if weapon_sprite:
				weapon_sprite.modulate = body.modulate

	_recoil_offset = move_toward(_recoil_offset, 0.0, recoil_recovery_speed * delta)
	_recoil_angle = move_toward(_recoil_angle, 0.0, 0.55 * delta)
	barrel.position.x = -_recoil_offset


func _flash_damage() -> void:
	# Запускаємо 1-секундне мигання світло-червоним та анімацію поштовху від болю
	_damage_tint_timer = 1.0
	_hurt_flinch_timer = 0.20
	body.modulate = Color(2.1, 0.52, 0.52, 1.0)
	if weapon_sprite:
		weapon_sprite.modulate = body.modulate


func _die() -> void:
	is_dead = true
	weapon_pivot.visible = false
	muzzle_flash.visible = false
	tracer_line.visible = false
	body.frame_coords = Vector2i(0, ANIM_ROW_CROUCH)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(body, "rotation", -1.45, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(body, "position", Vector2(-18.0, 26.0), 0.28)
	tween.tween_property(body, "modulate", Color(0.45, 0.2, 0.2, 0.88), 0.28)
	_update_hud()
	died.emit()


func _update_hud() -> void:
	var hp_ratio := clampf(health / maxf(max_health, 1.0), 0.0, 1.0)
	health_bar_fill.size.x = 90.0 * hp_ratio
	health_bar_fill.color = Color(0.22, 0.82, 0.32, 1.0).lerp(Color(0.9, 0.2, 0.2, 1.0), 1.0 - hp_ratio)

	if is_dead:
		status_label.text = "ЗАГИНУВ"
	elif is_rolling:
		status_label.text = "[КУВИРОК] Патрони: %d/%d" % [ammo, magazine_size]
	elif is_in_cover:
		if ammo < magazine_size:
			status_label.text = "[В ОКОПІ] Перезарядка: %d/%d" % [ammo, magazine_size]
		else:
			status_label.text = "[В ОКОПІ] Патрони: %d/%d" % [ammo, magazine_size]
	else:
		status_label.text = "[ВОГОНЬ!] Патрони: %d/%d" % [ammo, magazine_size]


func _ensure_input_actions() -> void:
	if not InputMap.has_action("cover"):
		InputMap.add_action("cover")
		var ev := InputEventKey.new()
		ev.physical_keycode = KEY_SPACE
		InputMap.action_add_event("cover", ev)

	if not InputMap.has_action("roll_up"):
		InputMap.add_action("roll_up")
		for key in [KEY_W, KEY_UP]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event("roll_up", ev)

	if not InputMap.has_action("roll_down"):
		InputMap.add_action("roll_down")
		for key in [KEY_S, KEY_DOWN]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event("roll_down", ev)
