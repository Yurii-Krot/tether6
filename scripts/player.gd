extends Node2D

signal died
signal health_changed(current_health: float, max_health: float)
signal ammo_changed(current_ammo: int, magazine_size: int)
signal cover_changed(in_cover: bool)
signal roll_started(direction: float)
signal roll_finished

const CROSSHAIR_TEXTURE := preload("res://assets/crosshair.png")

@export var damage := 10.0
@export var fire_rate := 10.0 # 0.1 с між пострілами
@export var magazine_size := 30
@export var reload_time := 1.5
@export var max_health := 100.0
@export var recoil_distance := 7.0
@export var recoil_recovery_speed := 45.0

@export_group("Trench Roll")
@export var trench_min_y := 425.0
@export var trench_max_y := 630.0
@export var roll_distance := 95.0
@export var roll_duration := 0.22
@export var roll_cooldown := 0.08

var ammo := 30
var health := 100.0
var cooldown := 0.0
var is_in_cover := false
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

@onready var body: ColorRect = $Body
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var barrel: Node2D = $WeaponPivot/Barrel
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

	_update_hud()


func _process(delta: float) -> void:
	_update_shot_effects(delta)

	if is_dead:
		return

	_roll_cooldown_timer = maxf(_roll_cooldown_timer - delta, 0.0)

	if is_rolling:
		_process_roll(delta)
	else:
		_handle_roll_input()

	var mouse_pos := get_global_mouse_position()
	weapon_pivot.look_at(mouse_pos)
	weapon_pivot.rotation += _recoil_angle

	var wants_cover := Input.is_action_pressed("cover") and not is_rolling
	if wants_cover != is_in_cover:
		_set_cover(wants_cover)

	cooldown = maxf(cooldown - delta, 0.0)

	if is_in_cover:
		_process_reload_in_cover(delta)
	else:
		_reload_accumulator = 0.0
		if Input.is_action_pressed("shoot") and cooldown <= 0.0 and ammo > 0:
			ammo -= 1
			cooldown = 1.0 / fire_rate
			shoot(mouse_pos)
			ammo_changed.emit(ammo, magazine_size)
			_update_hud()


func shoot(aim: Vector2) -> void:
	var space_state := get_world_2d().direct_space_state
	var origin := weapon_pivot.global_position
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

	if target_collider != null:
		target_collider.take_damage(damage)

	_trigger_shot_feedback(ray_end)


func take_damage(amount: float) -> void:
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
	if is_in_cover:
		_set_cover(false)

	is_rolling = true
	_roll_dir = direction
	_roll_elapsed = 0.0
	_afterimage_timer = 0.0
	_roll_start_y = position.y
	_roll_target_y = target_y

	# Центруємо pivot для красивого сальто/перекату в окопі
	body.pivot_offset = Vector2(18.0, 26.0)
	body.position = Vector2(-18.0, -28.0)
	_spawn_roll_afterimage()
	roll_started.emit(direction)
	_update_hud()


func _process_roll(delta: float) -> void:
	_roll_elapsed += delta
	var duration := maxf(roll_duration, 0.05)
	var t := clampf(_roll_elapsed / duration, 0.0, 1.0)
	var eased := 1.0 - pow(1.0 - t, 2.2)

	position.y = lerpf(_roll_start_y, _roll_target_y, eased)

	# Повний оберт у напрямку перекату + легке групування тіла
	body.rotation = _roll_dir * TAU * t
	var tuck := sin(t * PI)
	body.scale = Vector2(1.0 - 0.18 * tuck, 1.0 - 0.24 * tuck)

	_afterimage_timer -= delta
	if _afterimage_timer <= 0.0 and t < 0.9:
		_afterimage_timer = 0.045
		_spawn_roll_afterimage()

	if t >= 1.0:
		_finish_roll()


func _finish_roll() -> void:
	is_rolling = false
	position.y = _roll_target_y
	_roll_cooldown_timer = roll_cooldown
	body.rotation = 0.0
	body.pivot_offset = Vector2(18.0, 52.0)
	body.scale = Vector2.ONE
	body.position = Vector2(-18.0, -28.0)
	roll_finished.emit()
	_update_hud()


func _spawn_roll_afterimage() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	# Шлейф перекату в стилі Peacekeeper (жовто-золотавий силует, що швидко згасає)
	var ghost := ColorRect.new()
	ghost.size = body.size
	ghost.pivot_offset = Vector2(18.0, 26.0)
	ghost.global_position = global_position + body.position
	ghost.rotation = body.rotation
	ghost.scale = body.scale
	ghost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ghost.color = Color(0.95, 0.82, 0.28, 0.55)
	ghost.z_index = -1
	parent_node.add_child(ghost)

	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.16)
	tween.tween_callback(ghost.queue_free)


func _set_cover(active: bool) -> void:
	is_in_cover = active
	cover_changed.emit(is_in_cover)

	if is_in_cover:
		# Присідає глибше в окоп зліва
		body.rotation = 0.0
		body.pivot_offset = Vector2(18.0, 52.0)
		body.position = Vector2(-30.0, -14.0)
		body.scale = Vector2(0.88, 0.58)
		body.color = Color(0.16, 0.25, 0.2, 0.9)
		weapon_pivot.visible = false
		muzzle_flash.visible = false
		tracer_line.visible = false
		if ammo < magazine_size:
			reload_sound.pitch_scale = 0.95
			reload_sound.play()
	else:
		body.rotation = 0.0
		body.pivot_offset = Vector2(18.0, 52.0)
		body.position = Vector2(-18.0, -28.0)
		body.scale = Vector2.ONE
		body.color = Color(0.26, 0.42, 0.34, 1.0)
		weapon_pivot.visible = true

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


func _trigger_shot_feedback(target_point: Vector2) -> void:
	# Спалах
	_flash_timer = 0.045
	muzzle_flash.visible = true
	muzzle_flash.scale = Vector2(randf_range(0.85, 1.25), randf_range(0.85, 1.2))
	tracer_line.clear_points()
	tracer_line.add_point(muzzle.global_position)
	tracer_line.add_point(target_point)
	tracer_line.visible = true

	# Звук
	shot_sound.pitch_scale = randf_range(0.95, 1.06)
	shot_sound.play()

	# Невеликий відбій
	_recoil_offset = recoil_distance
	_recoil_angle = randf_range(-0.045, 0.045)
	barrel.position.x = -_recoil_offset


func _update_shot_effects(delta: float) -> void:
	if _flash_timer > 0.0:
		_flash_timer -= delta
		if _flash_timer <= 0.0:
			muzzle_flash.visible = false
			tracer_line.visible = false

	_recoil_offset = move_toward(_recoil_offset, 0.0, recoil_recovery_speed * delta)
	_recoil_angle = move_toward(_recoil_angle, 0.0, 0.45 * delta)
	barrel.position.x = -_recoil_offset


func _flash_damage() -> void:
	body.modulate = Color(1.8, 0.45, 0.45, 1.0)
	var tween := create_tween()
	tween.tween_property(body, "modulate", Color.WHITE, 0.15)


func _die() -> void:
	is_dead = true
	weapon_pivot.visible = false
	muzzle_flash.visible = false
	tracer_line.visible = false
	body.color = Color(0.35, 0.1, 0.1, 0.85)
	_update_hud()
	died.emit()


func _update_hud() -> void:
	var hp_ratio := clampf(health / maxf(max_health, 1.0), 0.0, 1.0)
	health_bar_fill.size.x = 90.0 * hp_ratio
	health_bar_fill.color = Color(0.22, 0.82, 0.32, 1.0).lerp(Color(0.9, 0.2, 0.2, 1.0), 1.0 - hp_ratio)

	if is_dead:
		status_label.text = "ЗАГИНУВ"
	elif is_rolling:
		status_label.text = "[ПЕРЕКАТ] Патрони: %d/%d" % [ammo, magazine_size]
	elif is_in_cover:
		if ammo < magazine_size:
			status_label.text = "[УКРИТТЯ] Перезарядка: %d/%d" % [ammo, magazine_size]
		else:
			status_label.text = "[УКРИТТЯ] Повний: %d/%d" % [ammo, magazine_size]
	elif ammo == 0:
		status_label.text = "ПОРОЖНЬО! [Пробіл — укриття]"
	else:
		status_label.text = "Патрони: %d/%d" % [ammo, magazine_size]


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
