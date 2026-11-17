extends Node2D

signal died
signal health_changed(current_health: float, max_health: float)
signal ammo_changed(current_ammo: int, magazine_size: int)
signal cover_changed(in_cover: bool)
signal roll_started(direction: float)
signal roll_finished

const CROSSHAIR_TEXTURE := preload("res://assets/crosshair.png")
const ICON_GRENADE := preload("res://assets/icon_grenade.png")
const ICON_MEDKIT := preload("res://assets/icon_medkit.png")
const GRENADE_SCRIPT := preload("res://scripts/grenade.gd")
const GAME_STATE := preload("res://scripts/game_state.gd")
const ARMOR_BODY_SHEETS: Array[Texture2D] = [
	preload("res://assets/armor/armor_tier_1_sheet.png"),
	preload("res://assets/armor/armor_tier_2_sheet.png"),
	preload("res://assets/armor/armor_tier_3_sheet.png"),
	preload("res://assets/armor/armor_tier_4_sheet.png"),
	preload("res://assets/armor/armor_tier_5_sheet.png"),
	preload("res://assets/armor/armor_tier_6_sheet.png"),
	preload("res://assets/armor/armor_tier_7_sheet.png"),
]
const ARMOR_DEATH_SHEETS: Array[Texture2D] = [
	preload("res://assets/armor/armor_tier_1_death_sheet.png"),
	preload("res://assets/armor/armor_tier_2_death_sheet.png"),
	preload("res://assets/armor/armor_tier_3_death_sheet.png"),
	preload("res://assets/armor/armor_tier_4_death_sheet.png"),
	preload("res://assets/armor/armor_tier_5_death_sheet.png"),
	preload("res://assets/armor/armor_tier_6_death_sheet.png"),
	preload("res://assets/armor/armor_tier_7_death_sheet.png"),
]
const ARMOR_REAR_SLEEVE_SHEETS: Array[Texture2D] = [
	preload("res://assets/armor/armor_tier_1_rear_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_2_rear_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_3_rear_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_4_rear_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_5_rear_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_6_rear_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_7_rear_sleeve_sheet.png"),
]
const ARMOR_FRONT_SLEEVE_SHEETS: Array[Texture2D] = [
	preload("res://assets/armor/armor_tier_1_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_2_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_3_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_4_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_5_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_6_sleeve_sheet.png"),
	preload("res://assets/armor/armor_tier_7_sleeve_sheet.png"),
]
const WEAPON_SHEETS: Array[Texture2D] = [
	preload("res://assets/weapons/weapon_tier_1_sheet.png"),
	preload("res://assets/weapons/weapon_tier_2_sheet.png"),
	preload("res://assets/weapons/weapon_tier_3_sheet.png"),
	preload("res://assets/weapons/weapon_tier_4_sheet.png"),
	preload("res://assets/weapons/weapon_tier_5_sheet.png"),
	preload("res://assets/weapons/weapon_tier_6_sheet.png"),
	preload("res://assets/weapons/weapon_tier_7_sheet.png"),
]
const WEAPON_MUZZLE_LOCAL_POSITIONS: Array[Vector2] = [
	Vector2(109.7, -0.8), # Weapon Tier 1
	Vector2(114.1, -0.8), # Weapon Tier 2
	Vector2(118.4, -0.8), # Weapon Tier 3
	Vector2(121.3, -0.8), # Weapon Tier 4 (Suppressor)
	Vector2(118.0, -0.8), # Weapon Tier 5 (Suppressor + ACOG)
	Vector2(118.9, -0.8), # Weapon Tier 6 (Suppressor + PMAG)
	Vector2(121.8, -0.8), # Weapon Tier 7 (Suppressor + Drum)
]
const DEATH_THUD_SOUND := preload("res://assets/grenade_explosion.wav")
const BASE_SPRITE_SCALE := Vector2(0.78, 0.78)
const BODY_TEXTURE_OFFSET := Vector2(32.0, -40.0)
const RIFLE_TEXTURE_OFFSET := Vector2(64.0, 0.0)
const ARMOR_SHOULDER_STAND_OFFSETS: Array[Vector2] = [
	Vector2(-25.0, -60.8), # Tier 1
	Vector2(-25.0, -60.8), # Tier 2
	Vector2(-25.0, -60.8), # Tier 3
	Vector2(-25.0, -60.8), # Tier 4
	Vector2(-25.0, -60.8), # Tier 5
	Vector2(-25.0, -60.8), # Tier 6
	Vector2(-25.0, -60.8), # Tier 7
]
const ARMOR_SHOULDER_CROUCH_OFFSETS: Array[Vector2] = [
	Vector2(-21.8, -7.8), # Tier 1
	Vector2(-21.8, -7.8), # Tier 2
	Vector2(-21.8, -7.8), # Tier 3
	Vector2(-21.8, -7.8), # Tier 4
	Vector2(-21.8, -7.8), # Tier 5
	Vector2(-21.8, -7.8), # Tier 6
	Vector2(-21.8, -7.8), # Tier 7
]
const EJECT_LOCAL_POS := Vector2(45.0, -4.0)

# Рядки у спрайт-листі броні (12x8 кадрів) та окремому листі смерті (12x4)
const ANIM_COLS := 12
const ANIM_ROW_IDLE := 0
const ANIM_ROW_SHOOT := 1
const ANIM_ROW_CROUCH := 2
const ANIM_ROW_ROLL := 3
const DEATH_TOTAL_FRAMES := 41

# Плавний графік 41-кадрової багатосуглобової смерті: удар -> згинання колін -> падіння на спину -> відскок та фіксація на землі
const DEATH_FRAME_TIMES: Array[float] = [
	0.000, 0.022, 0.044, 0.066, 0.088, 0.110, 0.132, 0.155, 0.178, 0.200,
	0.222, 0.244, 0.266, 0.288, 0.312, 0.336, 0.360, 0.384, 0.408, 0.432,
	0.456, 0.480, 0.504, 0.528, 0.552, 0.576, 0.600, 0.625, 0.650, 0.675,
	0.700, 0.725, 0.750, 0.775, 0.800, 0.825, 0.850, 0.875, 0.900, 0.925,
	0.950,
]

@export var damage := 10.0
@export var fire_rate := 10.0 # 0.1 с між пострілами
@export var bullet_speed := 1380.0
@export var magazine_size := 30
@export var reload_time := 3.5
@export var empty_hold_reload_multiplier := 0.25
@export var trickle_penalty_duration := 0.85
@export var max_health := 100.0
@export var recoil_distance := 4.5
@export var recoil_recovery_speed := 45.0
const OPENING_BURST_STACK_SPACING := 3.5
const OPENING_BURST_SPREAD_DEG := 2.3

@export_group("Trench Roll")
@export var trench_min_y := 390.0
@export var trench_max_y := 600.0
@export var roll_distance := 100.0
@export var roll_duration := 0.28
@export var roll_cooldown := 0.07

@export_group("Grenade")
@export var grenade_cooldown := 30.0
@export var grenade_throw_distance := 540.0
@export var grenade_damage := 140.0
@export var grenade_radius := 265.0

@export_group("Heal")
@export var heal_cooldown := 40.0
@export var heal_anim_duration := 0.85

var ammo := 30
var health := 100.0
var crit_chance := 0.0
var opening_burst_max := 1
var _opening_burst_count := 1
var cooldown := 0.0
# У стані спокою боєць за замовчуванням захований в окопі (не отримує урон)
var is_in_cover := true
var is_rolling := false
var is_dead := false

var _reload_accumulator := 0.0
var _mag_was_empty := false
var _trickle_reload_timer := 0.0
var _flash_timer := 0.0
var _recoil_offset := 0.0
var _recoil_angle := 0.0
var _roll_elapsed := 0.0
var _roll_cooldown_timer := 0.0
var _roll_start_y := 495.0
var _roll_target_y := 495.0
var _roll_dir := 0.0
var _afterimage_timer := 0.0
var _anim_time := 0.0
var _shoot_anim_timer := 0.0
var _shoot_anim_duration := 0.10
var _shoulder_stand_offset := Vector2(-7.7, -58.3)
var _shoulder_crouch_offset := Vector2(-9.7, -39.3)
var _combat_expose_timer := 0.0
var _landing_squash_timer := 0.0
var _current_aim_angle := 0.0
var _damage_tint_timer := 0.0
var _hurt_flinch_timer := 0.0
var _grenade_cooldown_timer := 0.0
var _grenade_throw_timer := 0.0
var _grenade_throw_duration := 0.30
var _grenade_launched := false
var _heal_cooldown_timer := 0.0
var _heal_anim_timer := 0.0
var _heal_applied := false
var _death_anim_elapsed := 0.0
var _death_dust_spawned := false

# Візуальні бари ХП та Патронів у лівому нижньому куті екрана (Тактична консоль)
const BAR_MAX_WIDTH := 308.0
const BAR_HEIGHT := 26.0
var _hud_layer: CanvasLayer = null
var _hp_bar_trail: ColorRect = null
var _hp_bar_main: ColorRect = null
var _hp_bar_shine: ColorRect = null
var _hp_bar_label: Label = null
var _hp_armor_label: Label = null
var _ammo_bar_trail: ColorRect = null
var _ammo_bar_main: ColorRect = null
var _ammo_bar_shine: ColorRect = null
var _ammo_bar_edge: ColorRect = null
var _ammo_bar_label: Label = null
var _ammo_state_label: Label = null
var _grenade_slot_panel: Panel = null
var _grenade_cd_fill: ColorRect = null
var _grenade_icon_rect: TextureRect = null
var _grenade_hud_label: Label = null
var _medkit_slot_panel: Panel = null
var _medkit_cd_fill: ColorRect = null
var _medkit_icon_rect: TextureRect = null
var _medkit_hud_label: Label = null
var _hp_trail_ratio := 1.0
var _hp_trail_hold_timer := 0.0
var _ammo_trail_ratio := 1.0
var _ammo_trail_hold_timer := 0.0
var _input_locked := false
var _input_release_grace := 0.0
var _require_shoot_release := false

@onready var shadow: Polygon2D = get_node_or_null("Shadow")
@onready var body: Sprite2D = $Body
@onready var weapon_pivot: Node2D = $WeaponPivot
@onready var barrel: Node2D = $WeaponPivot/Barrel
@onready var rear_arm_sprite: Sprite2D = get_node_or_null("WeaponPivot/Barrel/RearArmSprite")
@onready var weapon_sprite: Sprite2D = get_node_or_null("WeaponPivot/Barrel/WeaponSprite")
@onready var front_arm_sprite: Sprite2D = get_node_or_null("WeaponPivot/Barrel/FrontArmSprite")
@onready var muzzle: Marker2D = $WeaponPivot/Barrel/Muzzle
@onready var muzzle_flash: Polygon2D = $WeaponPivot/Barrel/Muzzle/MuzzleFlash
@onready var tracer_line: Line2D = $TracerLine
@onready var local_hud: Node2D = get_node_or_null("HUD")
@onready var health_bar_fill: ColorRect = $HUD/HealthBarFill
@onready var status_label: Label = $HUD/StatusLabel
@onready var shot_sound: AudioStreamPlayer = $ShotSound
@onready var reload_sound: AudioStreamPlayer = $ReloadSound
@onready var heal_sound: AudioStreamPlayer = get_node_or_null("HealSound") as AudioStreamPlayer


func _ready() -> void:
	add_to_group("player")
	_ensure_input_actions()

	max_health = float(GAME_STATE.get_player_max_health())
	damage = float(GAME_STATE.get_player_bullet_damage())
	bullet_speed = GAME_STATE.get_player_bullet_speed()
	crit_chance = GAME_STATE.get_player_crit_chance()
	opening_burst_max = maxi(1, GAME_STATE.get_player_opening_burst_bullets())
	_opening_burst_count = opening_burst_max
	heal_cooldown = GAME_STATE.get_player_medkit_cooldown()
	grenade_damage = float(GAME_STATE.get_player_grenade_damage())
	grenade_cooldown = GAME_STATE.get_player_grenade_cooldown()

	var tier_idx := clampi(GAME_STATE.get_armor_tier() - 1, 0, ARMOR_BODY_SHEETS.size() - 1)
	var weapon_idx := clampi(GAME_STATE.get_weapon_tier() - 1, 0, WEAPON_SHEETS.size() - 1)
	_shoulder_stand_offset = ARMOR_SHOULDER_STAND_OFFSETS[tier_idx]
	_shoulder_crouch_offset = ARMOR_SHOULDER_CROUCH_OFFSETS[tier_idx]
	if body != null:
		body.texture = ARMOR_BODY_SHEETS[tier_idx]
		body.hframes = ANIM_COLS
		body.vframes = 8
		body.offset = BODY_TEXTURE_OFFSET
		body.scale = BASE_SPRITE_SCALE
	for arm_sp in [rear_arm_sprite, front_arm_sprite]:
		if arm_sp != null:
			arm_sp.hframes = ANIM_COLS
			arm_sp.offset = RIFLE_TEXTURE_OFFSET
			arm_sp.scale = BASE_SPRITE_SCALE
	if rear_arm_sprite != null:
		rear_arm_sprite.texture = ARMOR_REAR_SLEEVE_SHEETS[tier_idx]
	if front_arm_sprite != null:
		front_arm_sprite.texture = ARMOR_FRONT_SLEEVE_SHEETS[tier_idx]
	if weapon_sprite != null:
		weapon_sprite.texture = WEAPON_SHEETS[weapon_idx]
		weapon_sprite.hframes = ANIM_COLS
		weapon_sprite.offset = RIFLE_TEXTURE_OFFSET
		weapon_sprite.scale = BASE_SPRITE_SCALE
	if muzzle != null:
		muzzle.position = WEAPON_MUZZLE_LOCAL_POSITIONS[weapon_idx]

	ammo = magazine_size
	health = max_health
	_hp_trail_ratio = 1.0
	_ammo_trail_ratio = 1.0
	position.y = clampf(position.y, trench_min_y, trench_max_y)

	if local_hud:
		local_hud.visible = false
	_create_bottom_left_bars()

	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(CROSSHAIR_TEXTURE, Input.CURSOR_ARROW, Vector2(16, 16))

	_set_cover(true)
	_update_hud()


func set_input_locked(locked: bool, release_grace: float = 0.0) -> void:
	_input_locked = locked
	if locked:
		_input_release_grace = 0.0
		_require_shoot_release = false
	else:
		_input_release_grace = maxf(release_grace, 0.0)
		_require_shoot_release = Input.is_action_pressed("shoot")


func is_input_locked() -> bool:
	return _input_locked


func _process(delta: float) -> void:
	_anim_time += delta
	_update_shot_effects(delta)
	_update_hud_bars(delta)

	if is_dead:
		_process_death_anim(delta)
		return

	_roll_cooldown_timer = maxf(_roll_cooldown_timer - delta, 0.0)
	_landing_squash_timer = maxf(_landing_squash_timer - delta, 0.0)
	_hurt_flinch_timer = maxf(_hurt_flinch_timer - delta, 0.0)
	_grenade_cooldown_timer = maxf(_grenade_cooldown_timer - delta, 0.0)
	_heal_cooldown_timer = maxf(_heal_cooldown_timer - delta, 0.0)
	_trickle_reload_timer = maxf(_trickle_reload_timer - delta, 0.0)
	_input_release_grace = maxf(_input_release_grace - delta, 0.0)
	if _require_shoot_release and not Input.is_action_pressed("shoot"):
		_require_shoot_release = false

	var inputs_blocked := _input_locked or (_input_release_grace > 0.0) or _require_shoot_release

	if is_rolling:
		_process_roll(delta)
	elif not inputs_blocked:
		_handle_roll_input()
		_handle_grenade_input()
		_handle_heal_input()

	if _grenade_throw_timer > 0.0:
		_process_grenade_throw(delta)
	if _heal_anim_timer > 0.0:
		_process_heal_anim(delta)

	var mouse_pos := get_global_mouse_position()
	cooldown = maxf(cooldown - delta, 0.0)

	# Логіка укриття: у стані спокою (коли не стріляємо) боєць захований в окопі й не отримує урон.
	# Коли затискаємо ЛКМ (shoot) і є патрони — висовується з окопу, веде гвинтівку за прицілом і стріляє.
	var busy_action := (_grenade_throw_timer > 0.0) or (_heal_anim_timer > 0.0)
	var force_cover := (not inputs_blocked) and Input.is_action_pressed("cover") and not busy_action
	var wants_to_shoot := (not inputs_blocked) and Input.is_action_pressed("shoot") and ammo > 0 and not force_cover and not is_rolling and not busy_action

	if not wants_to_shoot:
		reset_opening_burst()

	if wants_to_shoot or busy_action:
		_combat_expose_timer = 0.16
	else:
		_combat_expose_timer = maxf(_combat_expose_timer - delta, 0.0)

	var should_be_in_cover := (_combat_expose_timer <= 0.0) or force_cover or (ammo <= 0 and not busy_action)
	if not is_rolling and should_be_in_cover != is_in_cover:
		_set_cover(should_be_in_cover)

	_update_weapon_aim(delta, mouse_pos)

	if not is_rolling and _heal_anim_timer <= 0.0:
		_update_sprite_frame_animation(delta)

	if is_in_cover or is_rolling:
		_process_reload_in_cover(delta)
	else:
		_reload_accumulator = 0.0
		if wants_to_shoot and cooldown <= 0.0 and ammo > 0:
			var shooting_trickle := _mag_was_empty and ammo <= 3
			ammo -= 1
			if ammo <= 0:
				_mag_was_empty = true
			if shooting_trickle:
				_trickle_reload_timer = trickle_penalty_duration
			_ammo_trail_hold_timer = 0.18
			cooldown = 1.0 / fire_rate
			shoot(mouse_pos)
			ammo_changed.emit(ammo, magazine_size)
			_update_hud()


func _set_weapon_frame(frame_idx: int) -> void:
	for sp in [rear_arm_sprite, weapon_sprite, front_arm_sprite]:
		if sp != null:
			sp.frame = frame_idx


func _set_weapon_modulate(col: Color) -> void:
	for sp in [rear_arm_sprite, weapon_sprite, front_arm_sprite]:
		if sp != null:
			sp.modulate = col


func _update_weapon_aim(delta: float, mouse_pos: Vector2) -> void:
	if is_rolling:
		weapon_pivot.visible = false
		return

	weapon_pivot.visible = true
	var to_mouse := mouse_pos - weapon_pivot.global_position
	var raw_angle := atan2(to_mouse.y, maxf(to_mouse.x, 25.0))
	var clamped_aim := clampf(raw_angle, -0.78, 0.78)

	if is_in_cover and _grenade_throw_timer <= 0.0 and _heal_anim_timer <= 0.0:
		# У присяді на одному коліні: в спокої (та на початку/в кінці циклу) ствол опущений вниз (~15°),
		# а під час активної перезарядки піднімається горизонтально до грудей (як у 5-кадровому референсі)
		var crouch_col := int(_anim_time * 8.0) % ANIM_COLS if ammo < magazine_size else 0
		var reload_angle := 0.26
		if ammo < magazine_size and crouch_col >= 2 and crouch_col <= 9:
			reload_angle = 0.02 + sin(_anim_time * 16.0) * 0.03
		_current_aim_angle = lerp_angle(_current_aim_angle, reload_angle, minf(delta * 16.0, 1.0))
		weapon_pivot.position = body.position + _shoulder_crouch_offset
		weapon_pivot.rotation = _current_aim_angle
		_set_weapon_frame(0)
		_set_weapon_modulate(body.modulate)
	elif _heal_anim_timer > 0.0:
		# Анімація хілки: плавно піднімає гвинтівку вертикально вгору (-90°), тримає над головою і опускає назад
		var raise_env := _get_heal_raise_envelope()
		var target_heal_angle := lerpf(0.0, -PI * 0.5, raise_env)
		_current_aim_angle = target_heal_angle
		weapon_pivot.position = body.position + _shoulder_stand_offset + Vector2(-4.5 * raise_env, -15.0 * raise_env)
		weapon_pivot.rotation = _current_aim_angle
		_set_weapon_frame(0)
		_set_weapon_modulate(body.modulate)
	elif _grenade_throw_timer > 0.0:
		# Фаза метання/пуску гранати: піднімає ствол вгору під кутом ~40° і робить постріл гранатою по навісній траєкторії
		var throw_angle := -0.68
		_current_aim_angle = lerp_angle(_current_aim_angle, throw_angle, minf(delta * 28.0, 1.0))
		weapon_pivot.position = body.position + _shoulder_stand_offset
		weapon_pivot.rotation = _current_aim_angle + _recoil_angle
		_set_weapon_modulate(body.modulate)
	else:
		# Під час стрільби гвинтівка з руками точно ходить за перехрестям мишки!
		_current_aim_angle = lerp_angle(_current_aim_angle, clamped_aim, minf(delta * 24.0, 1.0))
		weapon_pivot.position = body.position + _shoulder_stand_offset
		weapon_pivot.rotation = _current_aim_angle + _recoil_angle
		_set_weapon_modulate(body.modulate)


func _update_sprite_frame_animation(delta: float) -> void:
	body.rotation = 0.0

	# Пружинисте приземлення після перекату (squash & stretch)
	var land_squash := 0.0
	if _landing_squash_timer > 0.0:
		land_squash = sin((_landing_squash_timer / 0.14) * PI)

	if is_in_cover:
		# Рядок 2: присяд на одному коліні в окопі (кадр 0 у спокої; кадри 0..11 під час перезарядки)
		var reload_bob := sin(_anim_time * 9.0) * 0.6 if ammo < magazine_size else 0.0
		body.position = Vector2(-1.5, 2.0 + reload_bob + land_squash * 4.0)
		body.scale = Vector2(
			BASE_SPRITE_SCALE.x * (1.0 + 0.09 * land_squash),
			BASE_SPRITE_SCALE.y * (1.0 - 0.11 * land_squash)
		)
		var crouch_col := int(_anim_time * 8.0) % ANIM_COLS if ammo < magazine_size else 0
		body.frame_coords = Vector2i(crouch_col, ANIM_ROW_CROUCH)
		if shadow:
			shadow.position = Vector2(-1.5, 58.0)
			shadow.scale = Vector2(1.58 + 0.10 * land_squash, 1.32)
		return

	# Бойова стійка під час стрільби (+ легке сіпання корпусу назад при отриманні болю)
	var hurt_flinch := sin((_hurt_flinch_timer / 0.20) * PI) if _hurt_flinch_timer > 0.0 else 0.0
	body.position = Vector2(-hurt_flinch * 6.5, land_squash * 3.5)
	body.rotation = -hurt_flinch * 0.09
	body.scale = Vector2(
		BASE_SPRITE_SCALE.x * (1.0 + 0.08 * land_squash - 0.04 * hurt_flinch),
		BASE_SPRITE_SCALE.y * (1.0 - 0.10 * land_squash + 0.03 * hurt_flinch)
	)
	if shadow:
		shadow.position = Vector2(0.0, 58.0)
		shadow.scale = Vector2(1.48, 1.48)

	if _shoot_anim_timer > 0.0:
		_shoot_anim_timer = maxf(_shoot_anim_timer - delta, 0.0)
		var progress := clampf(1.0 - (_shoot_anim_timer / maxf(_shoot_anim_duration, 0.02)), 0.0, 0.999)
		var shoot_col := clampi(int(progress * float(ANIM_COLS)), 0, ANIM_COLS - 1)
		body.frame_coords = Vector2i(shoot_col, ANIM_ROW_SHOOT)
		# Кадри 1..11 на листах зброї та рукавів — плавні фази пострілу, полум'я, газів та диму
		_set_weapon_frame(clampi(1 + int(progress * float(ANIM_COLS - 1)), 1, ANIM_COLS - 1))
	else:
		var idle_col := int(_anim_time * 7.0) % ANIM_COLS
		body.frame_coords = Vector2i(idle_col, ANIM_ROW_IDLE)
		_set_weapon_frame(0)


func reset_opening_burst() -> void:
	_opening_burst_count = maxi(1, opening_burst_max)


func shoot(aim: Vector2) -> void:
	var origin := muzzle.global_position
	var target_pos := aim
	if target_pos.x < origin.x + 40.0:
		target_pos = origin + Vector2.RIGHT.rotated(weapon_pivot.rotation) * 900.0

	var volley_count := clampi(_opening_burst_count, 1, maxi(opening_burst_max, 1))
	_opening_burst_count = maxi(1, volley_count - 1)

	var aim_dir := (target_pos - origin).normalized()
	if aim_dir.length_squared() < 0.001:
		aim_dir = Vector2.RIGHT
	var stack_axis := Vector2(-aim_dir.y, aim_dir.x)
	var travel_dist := maxf((target_pos - origin).length(), 900.0)

	var parent_node := get_parent()
	if parent_node != null:
		for i in range(volley_count):
			var idx_centered := float(i) - float(volley_count - 1) * 0.5
			var start_i := origin + stack_axis * (idx_centered * OPENING_BURST_STACK_SPACING)
			var spread_rad := deg_to_rad(idx_centered * OPENING_BURST_SPREAD_DEG)
			var dir_i := aim_dir.rotated(spread_rad)
			var target_i := start_i + dir_i * travel_dist
			var shot_damage := damage
			if crit_chance > 0.0 and randf() < crit_chance:
				shot_damage = roundf(damage * 1.75)
			var proj := Projectile.new()
			proj.setup(
				Projectile.BulletType.PLAYER_YELLOW,
				start_i,
				target_i,
				shot_damage,
				bullet_speed,
				false
			)
			parent_node.add_child(proj)

	_trigger_shot_feedback()


func take_damage(amount: float, ignore_cover: bool = false) -> void:
	# У стані спокою (is_in_cover) звичайні кулі не ранять, але вибух ракети в плитці окопа пробиває укриття (рятує перекат W/S на іншу плитку)
	if is_dead or is_rolling or amount <= 0.0:
		return
	if is_in_cover and not ignore_cover:
		return

	health = maxf(health - amount, 0.0)
	_hp_trail_hold_timer = 0.30
	health_changed.emit(health, max_health)
	_update_hud()
	_flash_damage()

	if health <= 0.0:
		_die()


func _handle_grenade_input() -> void:
	if _grenade_cooldown_timer > 0.0 or _grenade_throw_timer > 0.0 or _heal_anim_timer > 0.0:
		return
	if Input.is_action_just_pressed("throw_grenade"):
		_start_grenade_throw()


func _handle_heal_input() -> void:
	if _heal_cooldown_timer > 0.0 or _heal_anim_timer > 0.0 or _grenade_throw_timer > 0.0:
		return
	if Input.is_action_just_pressed("use_heal"):
		_start_heal()


func _start_heal() -> void:
	_heal_cooldown_timer = heal_cooldown
	_heal_anim_timer = heal_anim_duration
	_heal_applied = false
	_combat_expose_timer = heal_anim_duration + 0.06
	if is_in_cover:
		_set_cover(false)
	if heal_sound:
		heal_sound.pitch_scale = 1.0
		heal_sound.play()
	_update_hud()


func _get_heal_raise_envelope() -> float:
	if _heal_anim_timer <= 0.0:
		return 0.0
	var prog := clampf(1.0 - (_heal_anim_timer / maxf(heal_anim_duration, 0.1)), 0.0, 1.0)
	# Як на скріні (22 кадри): кадри 0..4 — підйом гвинтівки вертикально вгору, кадри 4..16 — утримання вертикально над головою, кадри 17..21 — опускання в бойову стійку
	if prog < 0.22:
		var t := prog / 0.22
		return t * t * (3.0 - 2.0 * t)
	elif prog <= 0.78:
		var hold_t := (prog - 0.22) / 0.56
		return 1.0 + 0.04 * sin(hold_t * PI * 2.0)
	else:
		var t := (1.0 - prog) / 0.22
		return clampf(t * t * (3.0 - 2.0 * t), 0.0, 1.0)


func _process_heal_anim(delta: float) -> void:
	_heal_anim_timer = maxf(_heal_anim_timer - delta, 0.0)
	var prog := clampf(1.0 - (_heal_anim_timer / maxf(heal_anim_duration, 0.1)), 0.0, 1.0)
	var raise_env := _get_heal_raise_envelope()

	# Стійка бійця під час підняття зброї вгору (як на референсному скріні)
	body.frame_coords = Vector2i(0, ANIM_ROW_SHOOT)
	body.position = Vector2(-3.5 * raise_env, -2.5 * raise_env)
	body.rotation = -0.10 * raise_env
	body.scale = Vector2(
		BASE_SPRITE_SCALE.x * (1.0 - 0.03 * raise_env),
		BASE_SPRITE_SCALE.y * (1.0 + 0.04 * raise_env)
	)
	if _damage_tint_timer <= 0.0:
		var glow := sin(prog * PI) * 0.45
		body.modulate = Color(1.0 - glow * 0.2, 1.0 + glow * 0.45, 1.0 - glow * 0.2, 1.0)
		_set_weapon_modulate(body.modulate)

	# На піку підняття пушки (0.26 прогресу) відновлюємо все ХП на 100% і запускаємо ефект лікування
	if prog >= 0.26 and not _heal_applied:
		_heal_applied = true
		health = max_health
		_hp_trail_ratio = 1.0
		_hp_trail_hold_timer = 0.0
		health_changed.emit(health, max_health)
		_spawn_heal_vfx()
		_update_hud()

	if _heal_anim_timer <= 0.0:
		body.position = Vector2.ZERO
		body.rotation = 0.0
		body.scale = BASE_SPRITE_SCALE
		if _damage_tint_timer <= 0.0:
			body.modulate = Color(0.72, 0.76, 0.80, 0.98) if is_in_cover else Color.WHITE
			_set_weapon_modulate(body.modulate)
		_update_hud()


func _spawn_heal_vfx() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	# Спливаючі зелені хрестики "+" навколо бійця під час відновлення ХП
	for i in range(5):
		var cross := Node2D.new()
		cross.global_position = global_position + Vector2(randf_range(-28.0, 28.0), randf_range(-36.0, 6.0))
		cross.z_index = 25

		var h_bar := Polygon2D.new()
		h_bar.color = Color(0.25, 0.96, 0.42, 0.95)
		h_bar.polygon = PackedVector2Array([
			Vector2(-6.0, -2.0), Vector2(6.0, -2.0), Vector2(6.0, 2.0), Vector2(-6.0, 2.0)
		])
		cross.add_child(h_bar)

		var v_bar := Polygon2D.new()
		v_bar.color = Color(0.25, 0.96, 0.42, 0.95)
		v_bar.polygon = PackedVector2Array([
			Vector2(-2.0, -6.0), Vector2(2.0, -6.0), Vector2(2.0, 6.0), Vector2(-2.0, 6.0)
		])
		cross.add_child(v_bar)

		parent_node.add_child(cross)
		var tw := cross.create_tween().set_parallel(true)
		tw.tween_property(cross, "global_position:y", cross.global_position.y - randf_range(28.0, 46.0), 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(cross, "modulate:a", 0.0, 0.55).set_delay(0.12)
		tw.chain().tween_callback(cross.queue_free)


func _start_grenade_throw() -> void:
	_grenade_cooldown_timer = grenade_cooldown
	_grenade_throw_timer = _grenade_throw_duration
	_grenade_launched = false
	_combat_expose_timer = _grenade_throw_duration + 0.06
	if is_in_cover:
		_set_cover(true)
	_update_hud()


func _process_grenade_throw(delta: float) -> void:
	_grenade_throw_timer = maxf(_grenade_throw_timer - delta, 0.0)
	var prog := 1.0 - (_grenade_throw_timer / maxf(_grenade_throw_duration, 0.05))

	# Легкий замах корпусом назад перед пуском гранати (кадри 0..7 Рядка 0 референсу)
	body.position = Vector2(-sin(prog * PI) * 5.0, 0.0)
	body.rotation = -sin(prog * PI) * 0.08

	if prog >= 0.45 and not _grenade_launched:
		_grenade_launched = true
		_launch_grenade_projectile()


func _launch_grenade_projectile() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var launch_from := muzzle.global_position if muzzle != null else (global_position + Vector2(36.0, -24.0))
	var target_pos := Vector2(global_position.x + grenade_throw_distance, global_position.y)

	var gren: Node2D = GRENADE_SCRIPT.new()
	gren.setup(launch_from, target_pos, grenade_damage, grenade_radius)
	parent_node.add_child(gren)

	# Візуальна та звукова віддача пуску гранати
	_shoot_anim_timer = _shoot_anim_duration
	_set_weapon_frame(2)
	_recoil_offset = recoil_distance * 1.45
	_recoil_angle = -0.10
	barrel.position.x = -_recoil_offset
	if shot_sound:
		shot_sound.pitch_scale = 0.62
		shot_sound.play()


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
		shadow.position = Vector2(arc * 12.0, 58.0)
		shadow.scale = Vector2((1.0 - 0.42 * arc) * 1.48, (1.0 - 0.42 * arc) * 1.48)

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
	else:
		if _damage_tint_timer <= 0.0:
			body.modulate = Color.WHITE
		body.position = Vector2.ZERO
		body.scale = BASE_SPRITE_SCALE
		body.frame_coords = Vector2i(0, ANIM_ROW_SHOOT)

	_set_weapon_modulate(body.modulate)

	_update_hud()


func _is_slow_reloading() -> bool:
	var trying_to_shoot := Input.is_action_pressed("shoot") and not Input.is_action_pressed("cover")
	return _mag_was_empty and (trying_to_shoot or _trickle_reload_timer > 0.0)


func _process_reload_in_cover(delta: float) -> void:
	if ammo >= magazine_size:
		_mag_was_empty = false
		return

	var bullets_per_sec := float(magazine_size) / maxf(reload_time, 0.05)
	if _is_slow_reloading():
		bullets_per_sec *= clampf(empty_hold_reload_multiplier, 0.05, 1.0)
	_reload_accumulator += delta * bullets_per_sec
	var added := int(_reload_accumulator)
	if added > 0:
		_reload_accumulator -= float(added)
		ammo = mini(ammo + added, magazine_size)
		if ammo >= 4 or ammo == magazine_size:
			_mag_was_empty = false
		ammo_changed.emit(ammo, magazine_size)
		if ammo == magazine_size:
			_reload_accumulator = 0.0
		_update_hud()


func _trigger_shot_feedback() -> void:
	_shoot_anim_timer = _shoot_anim_duration
	body.frame_coords = Vector2i(0, ANIM_ROW_SHOOT)
	_set_weapon_frame(1)

	muzzle_flash.visible = false
	tracer_line.visible = false

	# Звук
	shot_sound.pitch_scale = randf_range(0.95, 1.06)
	shot_sound.play()

	# Віддача вздовж лінії прицілювання
	_recoil_offset = recoil_distance
	_recoil_angle = randf_range(-0.055, -0.015)
	barrel.position.x = -_recoil_offset

	if is_inside_tree() and muzzle != null:
		var env := get_tree().get_first_node_in_group("battlefield_environment")
		if env != null and env.has_method("trigger_light_pulse"):
			env.trigger_light_pulse(muzzle.global_position, Color(1.0, 0.82, 0.34, 0.42), 115.0, 0.09)

	_spawn_shell_casing()


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
			_set_weapon_modulate(body.modulate)

	_recoil_offset = move_toward(_recoil_offset, 0.0, recoil_recovery_speed * delta)
	_recoil_angle = move_toward(_recoil_angle, 0.0, 0.55 * delta)
	barrel.position.x = -_recoil_offset


func _flash_damage() -> void:
	# Запускаємо 1-секундне мигання світло-червоним та анімацію поштовху від болю
	_damage_tint_timer = 1.0
	_hurt_flinch_timer = 0.20
	body.modulate = Color(2.1, 0.52, 0.52, 1.0)
	_set_weapon_modulate(body.modulate)


func _die() -> void:
	is_dead = true
	is_rolling = false
	_death_anim_elapsed = 0.0
	_death_dust_spawned = false
	_damage_tint_timer = 0.0
	weapon_pivot.visible = false
	muzzle_flash.visible = false
	tracer_line.visible = false
	var tier_idx := clampi(GAME_STATE.get_armor_tier() - 1, 0, ARMOR_DEATH_SHEETS.size() - 1)
	body.texture = ARMOR_DEATH_SHEETS[tier_idx]
	body.hframes = ANIM_COLS
	body.vframes = 4
	body.offset = BODY_TEXTURE_OFFSET
	body.rotation = 0.0
	body.scale = BASE_SPRITE_SCALE
	body.position = Vector2.ZERO
	body.modulate = Color(1.75, 0.62, 0.62, 1.0)
	body.frame_coords = Vector2i(0, 0)
	_update_hud()
	died.emit()


func _process_death_anim(delta: float) -> void:
	_death_anim_elapsed += delta

	var step := 0
	for i in range(DEATH_TOTAL_FRAMES - 1, -1, -1):
		if _death_anim_elapsed >= DEATH_FRAME_TIMES[i]:
			step = i
			break

	var row := int(step / ANIM_COLS)
	var col := step % ANIM_COLS
	body.frame_coords = Vector2i(col, row)
	body.rotation = 0.0
	# Сама 41-кадрова анімація вже містить реалістичне опускання на коліна, відрив рук та фіксацію тіла на підлозі окопу!
	if step >= 25 and step <= 29:
		var imp := sin((float(step - 25) / 4.0) * PI)
		body.position = Vector2(0.0, imp * 1.8)
		body.scale = Vector2(BASE_SPRITE_SCALE.x * (1.0 + imp * 0.03), BASE_SPRITE_SCALE.y * (1.0 - imp * 0.03))
	else:
		body.position = Vector2.ZERO
		body.scale = BASE_SPRITE_SCALE

	# Короткий спалах від фатального удару переходить у чисті кольори героя
	var flash_t := clampf(_death_anim_elapsed / 0.14, 0.0, 1.0)
	body.modulate = Color(1.75, 0.62, 0.62, 1.0).lerp(Color(0.95, 0.94, 0.94, 1.0), flash_t)

	# Розширення тіні під корпусом та ногами при падінні на дно окопу
	if shadow:
		var fall_prog := clampf((_death_anim_elapsed - 0.28) / 0.32, 0.0, 1.0)
		shadow.position = Vector2(lerpf(0.0, 26.0, fall_prog), 58.0)
		shadow.scale = Vector2(lerpf(1.48, 2.50, fall_prog), 1.38)

	# У момент важкого удару спиною/ранцем об землю (step >= 25) — тряска екрана, пил і глухий удар
	if step >= 25 and not _death_dust_spawned:
		_death_dust_spawned = true
		_spawn_trench_dust(global_position + Vector2(-8.0, 48.0), 0.45)
		_spawn_trench_dust(global_position + Vector2(28.0, 50.0), 0.35)
		_play_death_ground_thud()
		_trigger_death_ground_shake()


func _play_death_ground_thud() -> void:
	var parent_node := get_parent()
	if parent_node == null or not is_inside_tree():
		return
	var thud := AudioStreamPlayer.new()
	thud.stream = DEATH_THUD_SOUND
	thud.volume_db = -10.5
	thud.pitch_scale = 1.58
	parent_node.add_child(thud)
	thud.finished.connect(thud.queue_free)
	if thud.is_inside_tree():
		thud.play()


func _trigger_death_ground_shake() -> void:
	var stage_node := get_parent()
	if stage_node is Node2D:
		var stage_2d := stage_node as Node2D
		var base_pos := stage_2d.position
		var tw := stage_2d.create_tween()
		# Різкий вертикально-акцентований поштовх екрана від падіння важкого бійця
		tw.tween_property(stage_2d, "position", base_pos + Vector2(-4.0, 9.5), 0.032)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(5.5, -7.0), 0.038)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(-4.5, 5.5), 0.042)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(3.0, -3.8), 0.045)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(-2.0, 2.4), 0.048)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(1.0, -1.2), 0.050)
		tw.tween_property(stage_2d, "position", base_pos, 0.055)

	if _hud_layer:
		var htw := create_tween()
		htw.tween_property(_hud_layer, "offset", Vector2(-2.5, 5.5), 0.035)
		htw.tween_property(_hud_layer, "offset", Vector2(3.0, -4.0), 0.040)
		htw.tween_property(_hud_layer, "offset", Vector2(-2.0, 2.5), 0.045)
		htw.tween_property(_hud_layer, "offset", Vector2.ZERO, 0.060)


func _create_bottom_left_bars() -> void:
	_hud_layer = CanvasLayer.new()
	_hud_layer.layer = 5
	add_child(_hud_layer)

	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hud_layer.add_child(root)

	# Броньований корпус тактичної консолі внизу зліва (у латунно-сталевій гамі Tether6)
	var panel := _TacticalHudChassis.new()
	panel.position = Vector2(14.0, 576.0)
	panel.size = Vector2(332.0, 130.0)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(panel)

	# ── ВЕРХНІЙ РЯДОК: СЛОТ ГРАНАТИ [1] ТА СЛОТ АПТЕЧКИ [2] ──
	_grenade_slot_panel = Panel.new()
	_grenade_slot_panel.position = Vector2(12.0, 10.0)
	_grenade_slot_panel.size = Vector2(150.0, 38.0)
	_grenade_slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_grenade_slot_panel)

	_grenade_cd_fill = ColorRect.new()
	_grenade_cd_fill.position = Vector2(2.0, 32.0)
	_grenade_cd_fill.size = Vector2(146.0, 4.0)
	_grenade_cd_fill.color = Color(0.95, 0.58, 0.22, 0.90)
	_grenade_cd_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grenade_slot_panel.add_child(_grenade_cd_fill)

	var gren_icon_well := ColorRect.new()
	gren_icon_well.position = Vector2(5.0, 4.0)
	gren_icon_well.size = Vector2(28.0, 28.0)
	gren_icon_well.color = Color(0.05, 0.06, 0.08, 0.92)
	gren_icon_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grenade_slot_panel.add_child(gren_icon_well)

	_grenade_icon_rect = TextureRect.new()
	_grenade_icon_rect.position = Vector2(6.0, 5.0)
	_grenade_icon_rect.size = Vector2(26.0, 26.0)
	_grenade_icon_rect.texture = ICON_GRENADE
	_grenade_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_grenade_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_grenade_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grenade_slot_panel.add_child(_grenade_icon_rect)

	_grenade_hud_label = Label.new()
	_grenade_hud_label.position = Vector2(38.0, 4.0)
	_grenade_hud_label.size = Vector2(108.0, 28.0)
	_grenade_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_grenade_hud_label.add_theme_font_size_override("font_size", 13)
	_grenade_hud_label.add_theme_color_override("font_color", Color(0.95, 0.91, 0.80, 1.0))
	_grenade_hud_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_grenade_hud_label.add_theme_constant_override("outline_size", 4)
	_grenade_slot_panel.add_child(_grenade_hud_label)

	# Слот Аптечки [2]
	_medkit_slot_panel = Panel.new()
	_medkit_slot_panel.position = Vector2(170.0, 10.0)
	_medkit_slot_panel.size = Vector2(150.0, 38.0)
	_medkit_slot_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_medkit_slot_panel)

	_medkit_cd_fill = ColorRect.new()
	_medkit_cd_fill.position = Vector2(2.0, 32.0)
	_medkit_cd_fill.size = Vector2(146.0, 4.0)
	_medkit_cd_fill.color = Color(0.35, 0.92, 0.56, 0.90)
	_medkit_cd_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_medkit_slot_panel.add_child(_medkit_cd_fill)

	var med_icon_well := ColorRect.new()
	med_icon_well.position = Vector2(5.0, 4.0)
	med_icon_well.size = Vector2(28.0, 28.0)
	med_icon_well.color = Color(0.05, 0.06, 0.08, 0.92)
	med_icon_well.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_medkit_slot_panel.add_child(med_icon_well)

	_medkit_icon_rect = TextureRect.new()
	_medkit_icon_rect.position = Vector2(6.0, 5.0)
	_medkit_icon_rect.size = Vector2(26.0, 26.0)
	_medkit_icon_rect.texture = ICON_MEDKIT
	_medkit_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_medkit_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_medkit_icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_medkit_slot_panel.add_child(_medkit_icon_rect)

	_medkit_hud_label = Label.new()
	_medkit_hud_label.position = Vector2(38.0, 4.0)
	_medkit_hud_label.size = Vector2(108.0, 28.0)
	_medkit_hud_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_medkit_hud_label.add_theme_font_size_override("font_size", 13)
	_medkit_hud_label.add_theme_color_override("font_color", Color(0.95, 0.91, 0.80, 1.0))
	_medkit_hud_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_medkit_hud_label.add_theme_constant_override("outline_size", 4)
	_medkit_slot_panel.add_child(_medkit_hud_label)

	# ── 1) БАР ЗДОРОВ'Я (РУБІНОВО-ГРАНАТОВИЙ ІЗ ЛАТУННОЮ РАМКОЮ ТА ПОДІЛКАМИ) ──
	var hp_frame := ColorRect.new()
	hp_frame.position = Vector2(10.0, 54.0)
	hp_frame.size = Vector2(BAR_MAX_WIDTH + 4.0, BAR_HEIGHT + 4.0)
	hp_frame.color = Color(0.58, 0.48, 0.30, 0.95)
	hp_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(hp_frame)

	var hp_bg := ColorRect.new()
	hp_bg.position = Vector2(2.0, 2.0)
	hp_bg.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	hp_bg.color = Color(0.14, 0.05, 0.06, 0.98)
	hp_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.add_child(hp_bg)

	_hp_bar_trail = ColorRect.new()
	_hp_bar_trail.position = Vector2(2.0, 2.0)
	_hp_bar_trail.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	_hp_bar_trail.color = Color(0.98, 0.66, 0.32, 0.92)
	_hp_bar_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.add_child(_hp_bar_trail)

	_hp_bar_main = ColorRect.new()
	_hp_bar_main.position = Vector2(2.0, 2.0)
	_hp_bar_main.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	_hp_bar_main.color = Color(0.78, 0.17, 0.18, 1.0)
	_hp_bar_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.add_child(_hp_bar_main)

	_hp_bar_shine = ColorRect.new()
	_hp_bar_shine.position = Vector2(2.0, 2.0)
	_hp_bar_shine.size = Vector2(BAR_MAX_WIDTH, 8.0)
	_hp_bar_shine.color = Color(1.0, 0.68, 0.62, 0.24)
	_hp_bar_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.add_child(_hp_bar_shine)

	var hp_ticks := _HudBarTicks.new()
	hp_ticks.position = Vector2(2.0, 2.0)
	hp_ticks.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	hp_ticks.segments = 10
	hp_ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hp_frame.add_child(hp_ticks)

	_hp_bar_label = Label.new()
	_hp_bar_label.position = Vector2(10.0, 1.0)
	_hp_bar_label.size = Vector2(BAR_MAX_WIDTH - 16.0, BAR_HEIGHT)
	_hp_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_bar_label.add_theme_font_size_override("font_size", 14)
	_hp_bar_label.add_theme_color_override("font_color", Color(1.0, 0.96, 0.90, 1.0))
	_hp_bar_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_hp_bar_label.add_theme_constant_override("outline_size", 4)
	hp_frame.add_child(_hp_bar_label)

	_hp_armor_label = Label.new()
	_hp_armor_label.position = Vector2(10.0, 1.0)
	_hp_armor_label.size = Vector2(BAR_MAX_WIDTH - 18.0, BAR_HEIGHT)
	_hp_armor_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_hp_armor_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_hp_armor_label.add_theme_font_size_override("font_size", 12)
	_hp_armor_label.add_theme_color_override("font_color", Color(0.96, 0.86, 0.56, 0.96))
	_hp_armor_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_hp_armor_label.add_theme_constant_override("outline_size", 4)
	hp_frame.add_child(_hp_armor_label)

	# ── 2) БАР ПАТРОНІВ (ТАКТИЧНО-ЛАТУННИЙ / БУРШТИНОВИЙ ІЗ СЕГМЕНТАМИ) ──
	var ammo_frame := ColorRect.new()
	ammo_frame.position = Vector2(10.0, 90.0)
	ammo_frame.size = Vector2(BAR_MAX_WIDTH + 4.0, BAR_HEIGHT + 4.0)
	ammo_frame.color = Color(0.58, 0.48, 0.30, 0.95)
	ammo_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(ammo_frame)

	var ammo_bg := ColorRect.new()
	ammo_bg.position = Vector2(2.0, 2.0)
	ammo_bg.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	ammo_bg.color = Color(0.08, 0.09, 0.11, 0.98)
	ammo_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_frame.add_child(ammo_bg)

	_ammo_bar_trail = ColorRect.new()
	_ammo_bar_trail.position = Vector2(2.0, 2.0)
	_ammo_bar_trail.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	_ammo_bar_trail.color = Color(0.98, 0.88, 0.54, 0.80)
	_ammo_bar_trail.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_frame.add_child(_ammo_bar_trail)

	_ammo_bar_main = ColorRect.new()
	_ammo_bar_main.position = Vector2(2.0, 2.0)
	_ammo_bar_main.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	_ammo_bar_main.color = Color(0.76, 0.58, 0.22, 1.0)
	_ammo_bar_main.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_frame.add_child(_ammo_bar_main)

	_ammo_bar_shine = ColorRect.new()
	_ammo_bar_shine.position = Vector2(2.0, 2.0)
	_ammo_bar_shine.size = Vector2(BAR_MAX_WIDTH, 8.0)
	_ammo_bar_shine.color = Color(1.0, 0.94, 0.72, 0.24)
	_ammo_bar_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_frame.add_child(_ammo_bar_shine)

	var ammo_ticks := _HudBarTicks.new()
	ammo_ticks.position = Vector2(2.0, 2.0)
	ammo_ticks.size = Vector2(BAR_MAX_WIDTH, BAR_HEIGHT)
	ammo_ticks.segments = 15
	ammo_ticks.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_frame.add_child(ammo_ticks)

	_ammo_bar_edge = ColorRect.new()
	_ammo_bar_edge.position = Vector2(2.0, 2.0)
	_ammo_bar_edge.size = Vector2(4.0, BAR_HEIGHT)
	_ammo_bar_edge.color = Color(1.0, 0.96, 0.75, 0.98)
	_ammo_bar_edge.visible = false
	_ammo_bar_edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ammo_frame.add_child(_ammo_bar_edge)

	_ammo_bar_label = Label.new()
	_ammo_bar_label.position = Vector2(10.0, 1.0)
	_ammo_bar_label.size = Vector2(BAR_MAX_WIDTH - 16.0, BAR_HEIGHT)
	_ammo_bar_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ammo_bar_label.add_theme_font_size_override("font_size", 14)
	_ammo_bar_label.add_theme_color_override("font_color", Color(1.0, 0.97, 0.88, 1.0))
	_ammo_bar_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_ammo_bar_label.add_theme_constant_override("outline_size", 4)
	ammo_frame.add_child(_ammo_bar_label)

	_ammo_state_label = Label.new()
	_ammo_state_label.position = Vector2(10.0, 1.0)
	_ammo_state_label.size = Vector2(BAR_MAX_WIDTH - 18.0, BAR_HEIGHT)
	_ammo_state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_ammo_state_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_ammo_state_label.add_theme_font_size_override("font_size", 12)
	_ammo_state_label.add_theme_color_override("font_color", Color(0.95, 0.90, 0.74, 0.95))
	_ammo_state_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_ammo_state_label.add_theme_constant_override("outline_size", 4)
	ammo_frame.add_child(_ammo_state_label)


func _style_hud_slot(slot: Panel, ready_state: bool, ready_border: Color) -> void:
	if slot == null:
		return
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.11, 0.13, 0.15, 0.96) if ready_state else Color(0.08, 0.09, 0.11, 0.92)
	sb.border_color = ready_border if ready_state else Color(0.38, 0.34, 0.25, 0.80)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(5)
	slot.add_theme_stylebox_override("panel", sb)


func _update_hud_bars(delta: float) -> void:
	var hp_ratio := clampf(health / maxf(max_health, 1.0), 0.0, 1.0)
	if hp_ratio < _hp_trail_ratio:
		if _hp_trail_hold_timer > 0.0:
			_hp_trail_hold_timer = maxf(_hp_trail_hold_timer - delta, 0.0)
		else:
			_hp_trail_ratio = move_toward(_hp_trail_ratio, hp_ratio, delta * 0.48)
	else:
		_hp_trail_ratio = hp_ratio

	var is_reloading_now := (is_in_cover or is_rolling) and not is_dead and ammo < magazine_size
	var exact_ammo := clampf(
		float(ammo) + (_reload_accumulator if is_reloading_now else 0.0),
		0.0,
		float(magazine_size)
	)
	var ammo_ratio := clampf(exact_ammo / float(maxi(magazine_size, 1)), 0.0, 1.0)

	if ammo_ratio < _ammo_trail_ratio:
		if _ammo_trail_hold_timer > 0.0:
			_ammo_trail_hold_timer = maxf(_ammo_trail_hold_timer - delta, 0.0)
		else:
			_ammo_trail_ratio = move_toward(_ammo_trail_ratio, ammo_ratio, delta * 0.65)
	else:
		_ammo_trail_ratio = ammo_ratio

	if _hp_bar_main:
		_hp_bar_main.size.x = BAR_MAX_WIDTH * hp_ratio
	if _hp_bar_shine:
		_hp_bar_shine.size.x = BAR_MAX_WIDTH * hp_ratio
	if _hp_bar_trail:
		_hp_bar_trail.size.x = BAR_MAX_WIDTH * _hp_trail_ratio
	if _hp_bar_label:
		_hp_bar_label.text = "♥ ХП: %d / %d" % [int(ceilf(health)), int(roundf(max_health))]
	if _hp_armor_label:
		_hp_armor_label.text = "УКРИТТЯ" if is_in_cover else "ВОГОНЬ"

	var is_slow_reload := is_reloading_now and _is_slow_reloading()
	if _ammo_bar_main:
		_ammo_bar_main.size.x = BAR_MAX_WIDTH * ammo_ratio
		if is_reloading_now:
			var pulse := 0.5 + 0.5 * sin(_anim_time * 10.0)
			if is_slow_reload:
				_ammo_bar_main.color = Color(0.84, 0.42, 0.14, 1.0).lerp(Color(0.98, 0.64, 0.22, 1.0), pulse * 0.55)
			else:
				_ammo_bar_main.color = Color(0.68, 0.54, 0.20, 1.0).lerp(Color(0.94, 0.78, 0.34, 1.0), pulse * 0.6)
		else:
			_ammo_bar_main.color = Color(0.76, 0.58, 0.22, 1.0)
	if _ammo_bar_shine:
		_ammo_bar_shine.size.x = BAR_MAX_WIDTH * ammo_ratio
	if _ammo_bar_trail:
		_ammo_bar_trail.size.x = BAR_MAX_WIDTH * _ammo_trail_ratio
	if _ammo_bar_edge:
		_ammo_bar_edge.visible = is_reloading_now and ammo_ratio > 0.01 and ammo_ratio < 0.995
		_ammo_bar_edge.position.x = 2.0 + maxf(BAR_MAX_WIDTH * ammo_ratio - 3.0, 0.0)
	if _ammo_bar_label:
		_ammo_bar_label.text = "▮ НАБОЇ: %d / %d" % [ammo, magazine_size]
	if _ammo_state_label:
		if is_slow_reload:
			_ammo_state_label.text = "ПОВІЛЬНО..."
			_ammo_state_label.add_theme_color_override("font_color", Color(1.0, 0.66, 0.32, 0.98))
		elif is_reloading_now:
			_ammo_state_label.text = "ЗАРЯДЖАННЯ..."
			_ammo_state_label.add_theme_color_override("font_color", Color(0.98, 0.88, 0.48, 0.98))
		elif ammo == 0:
			_ammo_state_label.text = "ПОРОЖНЬО!"
			_ammo_state_label.add_theme_color_override("font_color", Color(1.0, 0.42, 0.36, 0.98))
		else:
			_ammo_state_label.text = "БОЄГОТОВИЙ"
			_ammo_state_label.add_theme_color_override("font_color", Color(0.78, 0.86, 0.76, 0.88))

	# Оновлення капсули Гранати [1]
	var gren_ready := _grenade_cooldown_timer <= 0.0
	_style_hud_slot(_grenade_slot_panel, gren_ready, Color(0.88, 0.68, 0.32, 0.96))
	if _grenade_cd_fill:
		var g_prog := 1.0 if gren_ready else clampf(1.0 - (_grenade_cooldown_timer / maxf(grenade_cooldown, 0.1)), 0.0, 1.0)
		_grenade_cd_fill.size.x = 146.0 * g_prog
		_grenade_cd_fill.color = Color(0.94, 0.76, 0.32, 0.95) if gren_ready else Color(0.86, 0.48, 0.20, 0.85)
	if _grenade_hud_label:
		if gren_ready:
			_grenade_hud_label.text = "ГРАНАТА [1]"
			_grenade_hud_label.add_theme_color_override("font_color", Color(0.98, 0.92, 0.72, 1.0))
		else:
			_grenade_hud_label.text = "КД: %dс  [1]" % int(ceilf(_grenade_cooldown_timer))
			_grenade_hud_label.add_theme_color_override("font_color", Color(0.78, 0.72, 0.62, 0.9))
	if _grenade_icon_rect:
		_grenade_icon_rect.modulate = Color.WHITE if gren_ready else Color(0.55, 0.55, 0.55, 0.75)

	# Оновлення капсули Аптечки [2]
	var med_ready := _heal_cooldown_timer <= 0.0
	_style_hud_slot(_medkit_slot_panel, med_ready, Color(0.46, 0.84, 0.54, 0.96))
	if _medkit_cd_fill:
		var m_prog := 1.0 if med_ready else clampf(1.0 - (_heal_cooldown_timer / maxf(heal_cooldown, 0.1)), 0.0, 1.0)
		_medkit_cd_fill.size.x = 146.0 * m_prog
		_medkit_cd_fill.color = Color(0.42, 0.90, 0.56, 0.95) if med_ready else Color(0.32, 0.65, 0.42, 0.82)
	if _medkit_hud_label:
		if med_ready:
			_medkit_hud_label.text = "АПТЕЧКА [2]"
			_medkit_hud_label.add_theme_color_override("font_color", Color(0.76, 0.98, 0.80, 1.0))
		else:
			_medkit_hud_label.text = "КД: %dс  [2]" % int(ceilf(_heal_cooldown_timer))
			_medkit_hud_label.add_theme_color_override("font_color", Color(0.74, 0.78, 0.74, 0.9))
	if _medkit_icon_rect:
		_medkit_icon_rect.modulate = Color.WHITE if med_ready else Color(0.55, 0.55, 0.55, 0.75)


func _update_hud() -> void:
	var hp_ratio := clampf(health / maxf(max_health, 1.0), 0.0, 1.0)
	health_bar_fill.size.x = 90.0 * hp_ratio
	health_bar_fill.color = Color(0.22, 0.82, 0.32, 1.0).lerp(Color(0.9, 0.2, 0.2, 1.0), 1.0 - hp_ratio)
	_update_hud_bars(0.0)


func _ensure_input_actions() -> void:
	if not InputMap.has_action("throw_grenade"):
		InputMap.add_action("throw_grenade")
		for key in [KEY_1, KEY_KP_1]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event("throw_grenade", ev)
	if not InputMap.has_action("use_heal"):
		InputMap.add_action("use_heal")
		for key in [KEY_2, KEY_KP_2]:
			var ev := InputEventKey.new()
			ev.physical_keycode = key
			InputMap.action_add_event("use_heal", ev)
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


class _TacticalHudChassis extends Control:
	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Тінь під панеллю
		draw_rect(Rect2(Vector2(3.0, 4.0), size), Color(0.0, 0.0, 0.0, 0.55), true)
		# Основна темно-сталева плита
		draw_rect(r, Color(0.065, 0.075, 0.09, 0.94), true)
		# Тонкі горизонтальні лінії сканера
		for y in range(6, int(size.y) - 6, 4):
			draw_line(Vector2(4, y), Vector2(size.x - 4, y), Color(1, 1, 1, 0.018), 1.0)
		# Зовнішня темна кромка та латунна фаска
		draw_rect(r, Color(0.03, 0.035, 0.045, 0.98), false, 3.0)
		var brass := Color(0.72, 0.60, 0.35, 0.96)
		draw_rect(r.grow(-2.0), brass, false, 2.0)
		draw_line(Vector2(4.0, 3.0), Vector2(size.x - 4.0, 3.0), brass.lightened(0.28), 1.5)
		draw_rect(r.grow(-5.0), Color(0.18, 0.20, 0.24, 0.70), false, 1.0)

		# 4 кутові заклепки
		var rivets := [
			Vector2(7.0, 7.0),
			Vector2(size.x - 7.0, 7.0),
			Vector2(7.0, size.y - 7.0),
			Vector2(size.x - 7.0, size.y - 7.0),
		]
		for p in rivets:
			draw_circle(p, 3.0, Color(0.10, 0.09, 0.07, 1.0))
			draw_circle(p, 1.9, brass.lightened(0.18))


class _HudBarTicks extends Control:
	var segments: int = 10

	func _draw() -> void:
		if segments <= 1:
			return
		var step := size.x / float(segments)
		for i in range(1, segments):
			var x := roundf(float(i) * step)
			draw_line(Vector2(x, 0.0), Vector2(x, 6.0), Color(0.04, 0.04, 0.05, 0.55), 1.5)
			draw_line(Vector2(x, size.y - 6.0), Vector2(x, size.y), Color(0.04, 0.04, 0.05, 0.55), 1.5)
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.02, 0.03, 0.85), false, 1.5)
