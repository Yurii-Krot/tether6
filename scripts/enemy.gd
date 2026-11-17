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
const AXE_PROJECTILE_SCRIPT := preload("res://scripts/axe_projectile.gd")
const WARNING_BEEP_STREAM := preload("res://assets/warning_beep.mp3")
const ENEMY_DEATH_STREAMS: Array[AudioStream] = [
	preload("res://assets/enemy_death_01.mp3"),
	preload("res://assets/enemy_death_02.mp3"),
	preload("res://assets/enemy_death_03.mp3"),
	preload("res://assets/enemy_death_04.mp3"),
	preload("res://assets/enemy_death_05.mp3"),
	preload("res://assets/enemy_death_06.mp3"),
]
const DEATH_SHEET_CONFIGS: Dictionary = {
	"res://assets/enemy_spritesheet.png": {
		"texture": preload("res://assets/enemy_death_sheet.png"),
		"offset": Vector2(32.0, -6.0),
	},
	"res://assets/shotgunner_spritesheet.png": {
		"texture": preload("res://assets/shotgunner_death_sheet.png"),
		"offset": Vector2(20.0, -6.0),
	},
	"res://assets/grenadier_spritesheet.png": {
		"texture": preload("res://assets/grenadier_death_sheet.png"),
		"offset": Vector2(52.0, -6.0),
	},
	"res://assets/boss_grenadier_spritesheet.png": {
		"texture": preload("res://assets/boss_grenadier_death_sheet.png"),
		"offset": Vector2(46.0, -6.0),
	},
	"res://assets/heavy_gunner_spritesheet.png": {
		"texture": preload("res://assets/heavy_gunner_death_sheet.png"),
		"offset": Vector2(55.0, -6.0),
	},
	"res://assets/sniper_spritesheet.png": {
		"texture": preload("res://assets/sniper_death_sheet.png"),
		"offset": Vector2(24.0, -6.0),
	},
	"res://assets/axe_thrower_spritesheet.png": {
		"texture": preload("res://assets/axe_thrower_death_sheet.png"),
		"offset": Vector2(40.0, -20.0),
	},
	"res://assets/boss_hammer_spritesheet.png": {
		"texture": preload("res://assets/boss_hammer_death_sheet.png"),
		"offset": Vector2(22.0, -20.0),
	},
}
const TRENCH_TILES_Y: Array[float] = [395.0, 495.0, 595.0]
const TILE_HALF_HEIGHT := 48.0
const TILE_HALF_WIDTH := 42.0

# Крива падіння з прискоренням гравітації: поштовх -> втрата рівноваги на п'ятах -> стрімкий зрив (g*t^2) -> важкий удар спиною -> удар ніг/зброї -> розчинення
const ENEMY_DEATH_FRAME_TIMES: Array[float] = [
	0.000, # 0: Влучання кулі
	0.032, # 1: Різке відкидання верхньої частини корпусу
	0.082, # 2: Миттєве зависання в нестійкій точці перед зривом
	0.132, # 3: Втрата рівноваги, гравітація тягне назад
	0.168, # 4: Прискорення падіння (вільний зрив)
	0.194, # 5: Стрімке наближення ранця до ґрунту
	0.215, # 6: Остання мить перед зіткненням із землею
	0.234, # 7: Важкий удар спиною та стиск ранця об ґрунт!
	0.256, # 8: Потужний удар зброєю за шолом об землю
	0.280, # 9: Мікровіддача корпусу, ноги стрімко падають вниз
	0.302, # 10: Прискорене падіння важких берців
	0.322, # 11: Гучний удар берців і кінцівки по ґрунту!
	0.340, # 12: Важке осідання тіла без відскоку
	0.365, # 13: Повне притискання до землі
	0.405, # 14: Нерухомий спокій
	0.460, # 15: Спокій
	0.540, # 16: Спокій
	0.650, # 17: Спокій
	0.780, # 18: Спокій
	0.920, # 19: Спокій
	1.060, # 20: Початок розчинення тіла
	1.180, # 21: Напівпрозоре згасання #1
	1.300, # 22: Напівпрозоре згасання #2
	1.420, # 23: Майже повне зникнення
]

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
@export var trench_launcher_rocket_count := 1
@export var use_axe_throw := false
@export var axe_flight_duration := 0.85
@export var use_hammer_sweep := false
@export var hammer_sweep_step_interval := 0.35
@export var hammer_sweep_cycles := 2
@export var hammer_flight_duration := 0.85
@export var use_exhaust_smoke := false
@export var smoke_pipe_offsets: Array[Vector2] = [Vector2(81.0, -72.0), Vector2(106.0, -64.0)]
@export var is_boss := false
## Швидкість програвання 24-кадрового циклу бігу (кадрів/с). 21 ≈ темп референсного відео (цикл ≈ 1.15 с)
@export var run_anim_fps := 24.0

var state: State = State.ADVANCE
var _max_health := 80.0
var _stop_x := 525.0
var _has_custom_stop_x := false
var _attack_timer := 0.0
var _shot_visual_timer := 0.0
var _base_color := Color.WHITE
var _has_locked_aim := false
var _locked_aim_pos := Vector2.ZERO
var _locked_aim_positions: Array[Vector2] = []
var _target_marker: Polygon2D = null
var _trench_warning_node: Node2D = null
var _trench_warning_nodes: Array[Node2D] = []
var _beep_player: AudioStreamPlayer = null
var _hp_bar_root: Node2D = null
var _hp_bar_fill: Polygon2D = null
var _hp_bar_timer := 0.0

const HP_BAR_SHOW_DURATION := 0.52
const HP_BAR_WIDTH := 64.0
const HP_BAR_HEIGHT := 7.0

static var _last_death_voice_idx := -1

var _anim_time := 0.0
var _shoot_anim_timer := 0.0
var _shoot_anim_duration := 0.24
var _hurt_anim_timer := 0.0
var _hurt_anim_duration := 0.14
var _hit_flash_timer := 0.0
var _hit_knockback_vx := 0.0
var _death_anim_timer := 0.0
var _death_anim_duration := 0.48
var _blood_splashed := false
var _boot_slapped := false
var _using_custom_death_sheet := false
var _base_sprite_scale := Vector2(0.62, 0.62)
var _base_shadow_scale := Vector2.ONE
var _last_step_col := -1
var _burst_shots_remaining := 0
var _burst_timer := 0.0
var _pending_axe_throw := false
var _pending_axe_delay := 0.0
var _hammer_sweep_queue: Array[int] = []
var _hammer_sweep_timer := 0.0
var _pending_hammer_throws: Array[Dictionary] = []
var _smoke_spawn_timer := 0.0
var _smoke_pipe_toggle := 0

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
	if shadow:
		_base_shadow_scale = shadow.scale
	if use_sniper_laser:
		_shoot_anim_duration = 0.42
		if is_equal_approx(projectile_speed, 540.0):
			projectile_speed = 1650.0
	elif pellet_count > 1:
		# Довша тривалість анімації пострілу дробовика, щоб було добре видно пересмикування помпової цівки та виліт гільзи
		_shoot_anim_duration = 0.48
	elif use_axe_throw:
		_shoot_anim_duration = 0.60
	elif use_hammer_sweep:
		_shoot_anim_duration = clampf(hammer_sweep_step_interval * 0.88, 0.16, 0.32)
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
	for wn in _trench_warning_nodes:
		if wn != null and is_instance_valid(wn):
			wn.queue_redraw()

	if _rappel_active and state != State.DEAD:
		_process_rappel(delta)
		return

	_update_sprite_animation(delta)
	if use_exhaust_smoke and state != State.DEAD:
		_process_exhaust_smoke(delta)

	match state:
		State.ADVANCE:
			_process_advance(delta)
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
		if _using_custom_death_sheet:
			var step := 0
			for i in range(ENEMY_DEATH_FRAME_TIMES.size() - 1, -1, -1):
				if _death_anim_timer >= ENEMY_DEATH_FRAME_TIMES[i]:
					step = i
					break
			body_sprite.frame_coords = Vector2i(step % 6, int(step / 6))

			# Важке прискорення падіння під гравітацією (t^2) до моменту зіткнення із землею
			if step >= 2 and step <= 6:
				var fall_t := clampf((_death_anim_timer - 0.082) / (0.234 - 0.082), 0.0, 1.0)
				var grav := fall_t * fall_t
				body_sprite.position = Vector2(lerpf(0.0, 2.0, fall_t), lerpf(0.0, 5.0, grav))
				var stretch_y := 1.0 + sin(fall_t * PI) * 0.045
				var stretch_x := 1.0 - sin(fall_t * PI) * 0.030
				body_sprite.scale = Vector2(_base_sprite_scale.x * stretch_x, _base_sprite_scale.y * stretch_y)
			elif not _blood_splashed:
				body_sprite.position = Vector2.ZERO

			var weight_mult := 1.55 if use_hammer_sweep else (1.35 if is_boss else 1.0)
			if step >= 7 and not _blood_splashed:
				_blood_splashed = true
				_spawn_ground_blood_splatter()
				var impact_center := global_position + Vector2(17.0, 110.0 if use_hammer_sweep else (88.0 if is_boss else 41.0))
				_spawn_death_dust(impact_center, true, weight_mult)
				_trigger_death_shake(weight_mult)
				if is_inside_tree():
					body_sprite.scale = Vector2(_base_sprite_scale.x * 1.15, _base_sprite_scale.y * 0.85)
					body_sprite.position = Vector2(2.0, 5.5)
					var impact_tween := create_tween()
					impact_tween.set_parallel(true)
					impact_tween.tween_property(body_sprite, "scale", _base_sprite_scale, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
					impact_tween.tween_property(body_sprite, "position", Vector2(0.0, 1.5), 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

			if step >= 11 and not _boot_slapped:
				_boot_slapped = true
				var leg_center := global_position + Vector2(-12.0, 110.0 if use_hammer_sweep else (88.0 if is_boss else 41.0))
				_spawn_death_dust(leg_center, false, weight_mult * 0.65)
				if is_inside_tree():
					body_sprite.scale = Vector2(_base_sprite_scale.x * 1.045, _base_sprite_scale.y * 0.955)
					var boot_tween := create_tween()
					boot_tween.tween_property(body_sprite, "scale", _base_sprite_scale, 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

			if shadow:
				var sh_prog := clampf((_death_anim_timer - 0.08) / 0.17, 0.0, 1.0)
				shadow.position = Vector2(lerpf(0.0, 26.0 * weight_mult, sh_prog), shadow.position.y)
				shadow.scale = Vector2(_base_shadow_scale.x * lerpf(1.0, 1.75, sh_prog), _base_shadow_scale.y * lerpf(1.0, 0.92, sh_prog))
			return

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
			shadow.scale = Vector2(_base_shadow_scale.x * lerpf(1.0, 1.55, gravity_t), _base_shadow_scale.y * lerpf(1.0, 0.92, gravity_t))
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
		body_sprite.position = Vector2.ZERO
		body_sprite.scale = _base_sprite_scale
		if shadow:
			shadow.scale = _base_shadow_scale
		var s_prog := 1.0 - (_shoot_anim_timer / maxf(_shoot_anim_duration, 0.01))
		if is_six_row:
			var s_col := clampi(1 + int(s_prog * float(cols - 1)), 1, cols - 1)
			body_sprite.frame_coords = Vector2i(s_col, row_shoot)
		else:
			var s_col := clampi(int(s_prog * float(cols)), 0, cols - 1)
			body_sprite.frame_coords = Vector2i(s_col, row_shoot)
		return

	if state == State.ADVANCE:
		body_sprite.position = Vector2.ZERO
		body_sprite.scale = _base_sprite_scale
		if is_six_row:
			# 24-кадрова покадрова анімація бігу у 2 рядках (Рядок 0 + Рядок 1, по 12 кадрів у кожному)
			var walk_fps_24 := run_anim_fps
			var total_walk_frames := cols * 2
			var step_idx := int(_anim_time * walk_fps_24) % total_walk_frames
			var w_row := step_idx / cols
			var w_col := step_idx % cols
			body_sprite.frame_coords = Vector2i(w_col, w_row)

			var cycle_phase := (_anim_time * walk_fps_24 / float(total_walk_frames)) * TAU
			if shadow:
				var stride_width := cos(cycle_phase * 2.0)
				shadow.scale = Vector2(_base_shadow_scale.x * (1.0 + 0.14 * stride_width), _base_shadow_scale.y * (1.0 - 0.05 * stride_width))

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
				shadow.scale = Vector2(_base_shadow_scale.x * (1.0 + 0.12 * stride_width), _base_shadow_scale.y * (1.0 - 0.05 * stride_width))

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
			shadow.scale = _base_shadow_scale
		if is_six_row:
			body_sprite.frame_coords = Vector2i(0, row_shoot)
			if is_boss:
				var breathe := sin(_anim_time * 3.4)
				body_sprite.position = Vector2(0.0, breathe * 2.2)
				body_sprite.scale = Vector2(
					_base_sprite_scale.x * (1.0 + breathe * 0.014),
					_base_sprite_scale.y * (1.0 - breathe * 0.014)
				)
		else:
			var ready_col := (cols - 2) + (int(_anim_time * 3.5) % 2)
			body_sprite.frame_coords = Vector2i(ready_col, row_shoot)


func _process_advance(delta: float) -> void:
	var prev_kb := _hit_knockback_vx
	_hit_knockback_vx = move_toward(_hit_knockback_vx, 0.0, 1750.0 * delta)
	var avg_kb := (prev_kb + _hit_knockback_vx) * 0.5
	var trench_x := _get_trench_x()
	var target_x := _stop_x if _has_custom_stop_x else maxf(_stop_x, trench_x + stop_distance - 60.0)
	if global_position.x <= target_x and avg_kb <= speed:
		velocity = Vector2.ZERO
		_hit_knockback_vx = 0.0
		state = State.ATTACK
		return

	var move_vx := -speed + avg_kb
	if global_position.x >= 1255.0 and move_vx > 0.0:
		move_vx = 0.0
	velocity = Vector2(move_vx, 0.0)
	move_and_slide()


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO

	var muzzle_offset := Vector2(-46.0, -3.2)
	if body_sprite != null:
		if use_sniper_laser:
			muzzle_offset = Vector2(-114.0, -8.0)
		elif use_hammer_sweep:
			muzzle_offset = Vector2(-64.0, -78.0)
		elif use_axe_throw:
			muzzle_offset = Vector2(-68.0, -24.0)
		elif use_trench_tile_launcher:
			muzzle_offset = Vector2(-144.0, -9.0) if is_boss else Vector2(-82.0, -5.0)
		elif shoot_straight or burst_count > 1:
			muzzle_offset = Vector2(-104.0, -9.0)
		elif pellet_count > 1:
			muzzle_offset = Vector2(-90.0, -15.0)
		else:
			muzzle_offset = Vector2(-75.0, 0.0)
	var muzzle_pos := global_position + muzzle_offset

	if _pending_axe_throw:
		_pending_axe_delay -= delta
		if _pending_axe_delay <= 0.0:
			_pending_axe_throw = false
			_launch_axe_projectile(global_position + Vector2(-72.0, -34.0))

	if not _pending_hammer_throws.is_empty():
		for i in range(_pending_hammer_throws.size() - 1, -1, -1):
			var entry: Dictionary = _pending_hammer_throws[i]
			entry["delay"] = float(entry["delay"]) - delta
			if float(entry["delay"]) <= 0.0:
				var t_idx := int(entry["tile_idx"])
				_pending_hammer_throws.remove_at(i)
				_launch_hammer_projectile(muzzle_pos, t_idx)
			else:
				_pending_hammer_throws[i] = entry

	if not _hammer_sweep_queue.is_empty():
		_hammer_sweep_timer -= delta
		if _hammer_sweep_timer <= 0.0:
			var next_tile_idx: int = _hammer_sweep_queue.pop_front()
			_hammer_sweep_timer = maxf(hammer_sweep_step_interval, 0.08)
			_trigger_hammer_sweep_throw(next_tile_idx, _hammer_sweep_queue.is_empty())
			if _hammer_sweep_queue.is_empty():
				_attack_timer = attack_interval
		return

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
	var lock_window := 0.0 if (use_axe_throw or use_hammer_sweep) else (0.30 if use_trench_tile_launcher else (0.85 if use_sniper_laser else 0.38))

	if not shoot_straight and not use_axe_throw and not use_hammer_sweep and _attack_timer <= lock_window and _attack_timer > 0.0 and not _has_locked_aim:
		if use_trench_tile_launcher:
			_locked_aim_positions = _choose_trench_tile_targets(maxi(trench_launcher_rocket_count, 1))
			_locked_aim_pos = _locked_aim_positions[0] if not _locked_aim_positions.is_empty() else _choose_trench_tile_target()
			_has_locked_aim = true
			_spawn_trench_tile_warnings(_locked_aim_positions)
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
		if use_hammer_sweep:
			_start_hammer_sweep_barrage()
			_has_locked_aim = false
			return
		_burst_shots_remaining = maxi(burst_count, 1) - 1
		_burst_timer = burst_interval
		_perform_attack(muzzle_pos)
		if _burst_shots_remaining == 0:
			_attack_timer = attack_interval
		_has_locked_aim = false


func _launch_axe_projectile(release_pos: Vector2) -> void:
	var target_tile := _choose_trench_tile_target()
	var parent_node := get_parent()
	if parent_node != null:
		var axe: Node2D = AXE_PROJECTILE_SCRIPT.new()
		axe.setup(release_pos, target_tile, attack_damage, axe_flight_duration)
		parent_node.add_child(axe)
	if shot_sound and shot_sound.stream != null:
		shot_sound.pitch_scale = randf_range(0.95, 1.08)
		shot_sound.play()


func _start_hammer_sweep_barrage() -> void:
	_hammer_sweep_queue.clear()
	var cycles := maxi(hammer_sweep_cycles, 1)
	var tile_count := TRENCH_TILES_Y.size()
	for _c in range(cycles):
		for t_idx in range(tile_count):
			_hammer_sweep_queue.append(t_idx)

	if _hammer_sweep_queue.is_empty():
		_attack_timer = attack_interval
		return

	var first_idx: int = _hammer_sweep_queue.pop_front()
	_hammer_sweep_timer = maxf(hammer_sweep_step_interval, 0.08)
	_trigger_hammer_sweep_throw(first_idx, _hammer_sweep_queue.is_empty())
	if _hammer_sweep_queue.is_empty():
		_attack_timer = attack_interval


func _trigger_hammer_sweep_throw(tile_idx: int, is_final_throw: bool) -> void:
	_shoot_anim_duration = 0.42 if is_final_throw else clampf(hammer_sweep_step_interval * 0.88, 0.16, 0.32)
	_shoot_anim_timer = _shoot_anim_duration
	if body_sprite:
		var is_six_row := body_sprite.vframes >= 6
		body_sprite.frame_coords = Vector2i(2 if is_six_row else 0, 2 if is_six_row else ENEMY_ROW_SHOOT)

	var release_delay := _shoot_anim_duration * (5.0 / 11.0)
	_pending_hammer_throws.append({
		"delay": release_delay,
		"tile_idx": tile_idx
	})


func _launch_hammer_projectile(release_pos: Vector2, tile_idx: int) -> void:
	var tx := _get_trench_x() + randf_range(-8.0, 8.0)
	var clamped_idx := clampi(tile_idx, 0, TRENCH_TILES_Y.size() - 1)
	var target_tile := Vector2(tx, TRENCH_TILES_Y[clamped_idx])
	var parent_node := get_parent()
	if parent_node != null:
		var hammer: Node2D = AXE_PROJECTILE_SCRIPT.new()
		hammer.setup(release_pos, target_tile, attack_damage, hammer_flight_duration, true)
		parent_node.add_child(hammer)
	if shot_sound and shot_sound.stream != null:
		shot_sound.pitch_scale = randf_range(0.84, 0.96)
		shot_sound.play()


func _process_exhaust_smoke(delta: float) -> void:
	if smoke_pipe_offsets.is_empty():
		return
	_smoke_spawn_timer -= delta
	if _smoke_spawn_timer > 0.0:
		return
	_smoke_spawn_timer = randf_range(0.07, 0.11)
	_smoke_pipe_toggle = (_smoke_pipe_toggle + 1) % smoke_pipe_offsets.size()
	var pipe_cell_offset := smoke_pipe_offsets[_smoke_pipe_toggle]
	var nozzle_local := pipe_cell_offset
	if body_sprite:
		nozzle_local = (pipe_cell_offset + body_sprite.offset) * body_sprite.scale + body_sprite.position
	_spawn_exhaust_smoke_puff(global_position + nozzle_local)


func _spawn_exhaust_smoke_puff(spawn_pos: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var puff := Node2D.new()
	puff.global_position = spawn_pos + Vector2(randf_range(-2.5, 2.5), randf_range(-2.5, 2.0))
	puff.z_index = -1
	puff.scale = Vector2(0.72, 0.72)

	var outer := Polygon2D.new()
	outer.color = Color(0.84, 0.83, 0.82, 0.48)
	var r := randf_range(6.5, 10.0)
	var pts := PackedVector2Array()
	for i in range(10):
		var a := float(i) * TAU / 10.0
		var rad := r * (0.85 + 0.25 * sin(float(i) * 2.7))
		pts.append(Vector2(cos(a) * rad, sin(a) * rad * 0.85))
	outer.polygon = pts
	puff.add_child(outer)

	var core := Polygon2D.new()
	core.color = Color(0.95, 0.94, 0.93, 0.34)
	core.position = Vector2(-1.5, -1.5)
	var cpts := PackedVector2Array()
	for i in range(8):
		var a := float(i) * TAU / 8.0
		cpts.append(Vector2(cos(a) * (r * 0.62), sin(a) * (r * 0.56)))
	core.polygon = cpts
	puff.add_child(core)

	parent_node.add_child(puff)

	var drift := Vector2(randf_range(16.0, 32.0), randf_range(-68.0, -44.0))
	var dur := randf_range(0.92, 1.28)
	var end_scale := randf_range(1.85, 2.55)
	var tw := puff.create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "global_position", puff.global_position + drift, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(puff, "scale", Vector2(end_scale, end_scale), dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(puff, "rotation", randf_range(-0.7, 0.7), dur)
	tw.tween_property(puff, "modulate:a", 0.0, dur)
	tw.chain().tween_callback(puff.queue_free)


func _perform_attack(muzzle_pos: Vector2) -> void:
	var player := _find_player()
	if player == null and not shoot_straight and not use_trench_tile_launcher and not use_axe_throw:
		return

	# Запускаємо анімацію пострілу ворога та звук пострілу (якщо заданий)
	_shoot_anim_timer = _shoot_anim_duration
	if body_sprite:
		var is_six_row := body_sprite.vframes >= 6
		body_sprite.frame_coords = Vector2i(1 if is_six_row else 0, 2 if is_six_row else ENEMY_ROW_SHOOT)
		if not use_trench_tile_launcher and not use_axe_throw:
			_spawn_enemy_shell()
	if not use_axe_throw and shot_sound and shot_sound.stream != null:
		shot_sound.pitch_scale = randf_range(0.76, 0.84) if use_trench_tile_launcher else (randf_range(0.96, 1.04) if not use_sniper_laser else randf_range(0.98, 1.02))
		shot_sound.play()

	if use_axe_throw:
		# Випускаємо сокиру точно у момент хлиста вперед (кадр 6 з 12, ≈ 45% анімації)
		_pending_axe_throw = true
		_pending_axe_delay = _shoot_anim_duration * (5.0 / 11.0)
		return

	if use_trench_tile_launcher:
		var targets := _locked_aim_positions if (_has_locked_aim and not _locked_aim_positions.is_empty()) else _choose_trench_tile_targets(maxi(trench_launcher_rocket_count, 1))
		var parent_node := get_parent()
		if parent_node != null:
			for i in range(targets.size()):
				var rocket: Node2D = GRENADIER_ROCKET_SCRIPT.new()
				var warn_to_pass: Node2D = null
				if i < _trench_warning_nodes.size():
					warn_to_pass = _trench_warning_nodes[i]
				rocket.setup(muzzle_pos, targets[i], projectile_speed, attack_damage, warn_to_pass)
				parent_node.add_child(rocket)
			_trench_warning_nodes.clear()
			_trench_warning_node = null
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

	var foot_y := 114.0 if use_hammer_sweep else (96.0 if is_boss else 43.0)
	var foot_offset := Vector2(-14.0, foot_y) if is_near_foot else Vector2(-19.0, foot_y - 2.0)
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
	if state == State.ADVANCE and not _rappel_active and speed > 0.0:
		# Легке відштовхування назад при влучанні в ворога під час бігу
		if is_boss:
			_hit_knockback_vx = clampf(maxf(_hit_knockback_vx, speed + 38.0), 0.0, speed + 45.0)
		else:
			_hit_knockback_vx = clampf(maxf(_hit_knockback_vx, speed + 115.0), 0.0, speed + 135.0)
	if not is_boss:
		_hurt_anim_timer = _hurt_anim_duration
		if body_sprite:
			var is_six_row := body_sprite.vframes >= 6
			body_sprite.frame_coords = Vector2i(0, 3 if is_six_row else ENEMY_ROW_HURT)
	_flash_hit()
	return false


func _enter_dead_state() -> void:
	var was_rappelling := _rappel_active
	_rappel_active = false
	_hit_knockback_vx = 0.0
	_pending_axe_throw = false
	_hammer_sweep_queue.clear()
	_pending_hammer_throws.clear()
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
	for wn in _trench_warning_nodes:
		if wn != null and is_instance_valid(wn):
			wn.queue_free()
	_trench_warning_nodes.clear()
	if _beep_player and _beep_player.playing:
		_beep_player.stop()
	if _hp_bar_root:
		_hp_bar_root.visible = false
	_hp_bar_timer = 0.0

	died.emit()
	_play_death_voice()

	if is_inside_tree() and was_rappelling:
		# Збитий на канаті — зривається й падає на землю в точку приземлення
		if body_sprite:
			body_sprite.rotation = 0.0
		if shadow:
			shadow.position = _shadow_base_pos
			shadow.scale = Vector2.ONE
		var drop_tween := create_tween()
		drop_tween.tween_property(self, "global_position", _rappel_to, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	if body_sprite and body_sprite.texture != null:
		var tex_path := body_sprite.texture.resource_path
		if DEATH_SHEET_CONFIGS.has(tex_path):
			var cfg: Dictionary = DEATH_SHEET_CONFIGS[tex_path]
			_using_custom_death_sheet = true
			_boot_slapped = false
			body_sprite.texture = cfg["texture"]
			body_sprite.hframes = 6
			body_sprite.vframes = 4
			body_sprite.frame_coords = Vector2i(0, 0)
			body_sprite.offset = cfg["offset"]
			body_sprite.modulate = Color.WHITE

	if is_inside_tree():
		if body_sprite:
			if not _using_custom_death_sheet:
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
			cleanup_tween.tween_interval(1.54 if _using_custom_death_sheet else 1.45)
			cleanup_tween.tween_property(self, "modulate:a", 0.0, 0.28)
			cleanup_tween.tween_callback(queue_free)
		else:
			var tween := create_tween()
			tween.set_parallel(true)
			tween.tween_property(self, "modulate", Color(0.25, 0.05, 0.05, 0.0), 0.22)
			tween.tween_property(self, "rotation", 1.25, 0.22)
			tween.chain().tween_callback(queue_free)
	else:
		queue_free()


func _play_death_voice() -> void:
	if is_boss or ENEMY_DEATH_STREAMS.is_empty() or not is_inside_tree():
		return
	var host := get_parent()
	if host == null:
		return

	var idx := randi() % ENEMY_DEATH_STREAMS.size()
	if ENEMY_DEATH_STREAMS.size() > 1 and idx == _last_death_voice_idx:
		idx = (idx + 1 + randi() % (ENEMY_DEATH_STREAMS.size() - 1)) % ENEMY_DEATH_STREAMS.size()
	_last_death_voice_idx = idx

	var stream: AudioStream = ENEMY_DEATH_STREAMS[idx]
	if stream == null:
		return
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false

	var sfx := AudioStreamPlayer.new()
	sfx.name = "EnemyDeathVoice"
	sfx.set_meta("_enemy_death_voice", true)
	sfx.stream = stream
	sfx.volume_db = -3.5
	sfx.pitch_scale = randf_range(0.95, 1.05)
	if AudioServer.get_bus_index("SFX") != -1:
		sfx.bus = "SFX"
	host.add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()


func _spawn_ground_blood_splatter() -> void:
	var parent_node := get_parent()
	if parent_node == null or not is_inside_tree():
		return

	var impact_center := global_position + Vector2(17.0, 110.0 if use_hammer_sweep else (88.0 if is_boss else 41.0))

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


func _spawn_death_dust(origin_pos: Vector2, is_main_impact: bool, weight_mult: float) -> void:
	var parent_node := get_parent()
	if parent_node == null or not is_inside_tree():
		return
	var puff_count := (8 if weight_mult > 1.2 else 6) if is_main_impact else 4
	for i in range(puff_count):
		var puff := Polygon2D.new()
		var r := randf_range(4.5, 9.0) * (0.75 + 0.25 * weight_mult)
		puff.polygon = PackedVector2Array([
			Vector2(-r * 1.15, -r * 0.45),
			Vector2(-r * 0.35, -r * 0.90),
			Vector2(r * 0.70, -r * 0.80),
			Vector2(r * 1.15, 0.0),
			Vector2(r * 0.50, r * 0.65),
			Vector2(-r * 0.85, r * 0.60),
		])
		puff.color = Color(0.46, 0.41, 0.35, 0.60 if is_main_impact else 0.44)
		puff.global_position = origin_pos + Vector2(randf_range(-16.0, 22.0) * weight_mult, randf_range(-5.0, 5.0))
		puff.rotation = randf_range(0.0, TAU)
		puff.scale = Vector2(0.42, 0.35)
		puff.z_index = -1
		parent_node.add_child(puff)

		var side_dir := 1.0 if i % 2 == 0 else -1.0
		var target_pos := puff.global_position + Vector2(side_dir * randf_range(16.0, 38.0) * weight_mult, randf_range(-18.0, -4.0))
		var tw := puff.create_tween()
		tw.set_parallel(true)
		tw.tween_property(puff, "global_position", target_pos, randf_range(0.24, 0.38)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "scale", Vector2(1.45, 1.10), 0.26).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(puff, "modulate:a", 0.0, 0.34).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.chain().tween_callback(puff.queue_free)


func _trigger_death_shake(weight_mult: float) -> void:
	var stage_node := get_parent()
	if not (stage_node is Node2D):
		return
	var stage_2d := stage_node as Node2D
	if not stage_2d.has_meta("_death_shake_base_pos"):
		stage_2d.set_meta("_death_shake_base_pos", stage_2d.position)
	var base_pos: Vector2 = stage_2d.get_meta("_death_shake_base_pos")

	if stage_2d.has_meta("_death_shake_tween"):
		var prev_tw = stage_2d.get_meta("_death_shake_tween")
		if prev_tw is Tween and is_instance_valid(prev_tw):
			(prev_tw as Tween).kill()

	var tw := stage_2d.create_tween()
	stage_2d.set_meta("_death_shake_tween", tw)
	if weight_mult > 1.1:
		var amp := clampf(weight_mult * 3.8, 3.6, 6.0)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(-2.2, amp), 0.024)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(2.6, -amp * 0.65), 0.028)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(-1.4, amp * 0.35), 0.032)
		tw.tween_property(stage_2d, "position", base_pos, 0.036)
	else:
		# Легесенька й дуже коротка труска екрана в момент смерті/падіння ворога
		tw.tween_property(stage_2d, "position", base_pos + Vector2(-0.9, 1.9), 0.022)
		tw.tween_property(stage_2d, "position", base_pos + Vector2(0.8, -1.1), 0.024)
		tw.tween_property(stage_2d, "position", base_pos, 0.028)
	tw.tween_callback(func() -> void:
		if is_instance_valid(stage_2d):
			stage_2d.remove_meta("_death_shake_base_pos")
			stage_2d.remove_meta("_death_shake_tween")
	)


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
	return 212.0


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
	var bar_w := 132.0 if is_boss else HP_BAR_WIDTH
	var bar_h := 11.0 if is_boss else HP_BAR_HEIGHT
	_hp_bar_root = Node2D.new()
	_hp_bar_root.position = Vector2(0.0, -152.0 if use_hammer_sweep else (-124.0 if is_boss else -70.0))
	_hp_bar_root.z_index = 20
	_hp_bar_root.visible = is_boss
	add_child(_hp_bar_root)

	var half_w := bar_w * 0.5
	var half_h := bar_h * 0.5

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
		Vector2(bar_w, -half_h),
		Vector2(bar_w, half_h),
		Vector2(0.0, half_h),
	])
	_hp_bar_root.add_child(_hp_bar_fill)


func _show_hp_bar() -> void:
	if _hp_bar_root == null or _hp_bar_fill == null:
		return
	var ratio := clampf(health / maxf(_max_health, 1.0), 0.0, 1.0)
	_hp_bar_fill.scale.x = ratio
	_hp_bar_timer = 15.0 if is_boss else HP_BAR_SHOW_DURATION
	_hp_bar_root.visible = true
	_hp_bar_root.modulate.a = 1.0


func _update_hp_bar(delta: float) -> void:
	if is_boss and state != State.DEAD and _hp_bar_root != null:
		_hp_bar_root.visible = true
		_hp_bar_root.modulate.a = 1.0
		return
	if _hp_bar_timer <= 0.0 or _hp_bar_root == null:
		return
	_hp_bar_timer -= delta
	if _hp_bar_timer <= 0.0:
		_hp_bar_timer = 0.0
		_hp_bar_root.visible = false
	elif _hp_bar_timer < 0.12:
		_hp_bar_root.modulate.a = clampf(_hp_bar_timer / 0.12, 0.0, 1.0)


func _choose_trench_tile_target() -> Vector2:
	var targets := _choose_trench_tile_targets(1)
	return targets[0]


func _choose_trench_tile_targets(count: int) -> Array[Vector2]:
	var tx := _get_trench_x()
	var total_tiles := TRENCH_TILES_Y.size()
	var wanted := clampi(count, 1, total_tiles)
	var chosen_indices: Array[int] = []

	var p := _find_player()
	if p != null and not p.get("is_dead"):
		var best_idx := 1
		var best_dist := INF
		for i in range(total_tiles):
			var d := absf(p.global_position.y - TRENCH_TILES_Y[i])
			if d < best_dist:
				best_dist = d
				best_idx = i
		chosen_indices.append(best_idx)

	var remaining_indices: Array[int] = []
	for i in range(total_tiles):
		if not chosen_indices.has(i):
			remaining_indices.append(i)
	remaining_indices.shuffle()

	while chosen_indices.size() < wanted and not remaining_indices.is_empty():
		chosen_indices.append(remaining_indices.pop_front())

	var result: Array[Vector2] = []
	for idx in chosen_indices:
		result.append(Vector2(tx, TRENCH_TILES_Y[idx]))
	return result


func _spawn_trench_tile_warnings(tile_positions: Array[Vector2]) -> void:
	for wn in _trench_warning_nodes:
		if wn != null and is_instance_valid(wn):
			wn.queue_free()
	_trench_warning_nodes.clear()
	if _trench_warning_node and is_instance_valid(_trench_warning_node):
		_trench_warning_node.queue_free()
		_trench_warning_node = null

	var parent_node := get_parent()
	if parent_node == null:
		return

	for tile_pos in tile_positions:
		var warn := Node2D.new()
		warn.global_position = tile_pos
		warn.z_index = 3
		warn.draw.connect(_draw_single_trench_warning.bind(warn))
		parent_node.add_child(warn)
		_trench_warning_nodes.append(warn)


func _draw_single_trench_warning(warn_node: Node2D) -> void:
	if warn_node == null or not is_instance_valid(warn_node):
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
	warn_node.draw_rect(rect, Color(1.0, 0.16, 0.08, alpha * 0.48), true)
	warn_node.draw_rect(rect, Color(1.0, 0.35, 0.12, alpha), false, 2.6)
	warn_node.draw_arc(Vector2.ZERO, lerpf(24.0, 14.0, pulse), 0.0, TAU, 24, Color(1.0, 0.90, 0.25, alpha), 2.2)
	warn_node.draw_line(Vector2(-15.0, 0.0), Vector2(15.0, 0.0), Color(1.0, 0.25, 0.12, alpha), 2.2)
	warn_node.draw_line(Vector2(0.0, -15.0), Vector2(0.0, 15.0), Color(1.0, 0.25, 0.12, alpha), 2.2)


func _exit_tree() -> void:
	if _trench_warning_node and is_instance_valid(_trench_warning_node):
		_trench_warning_node.queue_free()
		_trench_warning_node = null
	for wn in _trench_warning_nodes:
		if wn != null and is_instance_valid(wn):
			wn.queue_free()
	_trench_warning_nodes.clear()
