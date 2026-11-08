class_name Helicopter
extends Node2D

## Транспортний вертоліт: прилітає зліва, розвертається над полем бою,
## висаджує десант по канатах прямо під собою та відлітає.

signal trooper_drop_requested(unit_type: String, from_pos: Vector2, land_pos: Vector2)
signal finished

enum Phase {
	ENTER,
	TURN,
	DESCEND,
	DROP,
	ROCKET_ATTACK,
	ASCEND,
	LEAVE,
}

const BLADE_TEX := preload("res://assets/heli_blade.png")
const TRENCH_X := 185.0
const TRENCH_TILES_Y: Array[float] = [395.0, 495.0, 595.0]

# Координати в пікселях текстури heli_body.png (центр спрайта = 0,0), ніс дивиться вліво
const ROTOR_HUB := Vector2(-84.0, -113.0)
const TAIL_HUB := Vector2(278.0, -85.0)
const DOOR_ANCHOR := Vector2(-80.0, 30.0)
const ROCKET_POD_POS := Vector2(-22.0, 58.0)
const EXHAUST_POS := Vector2(60.0, -20.0)
const MAIN_ROTOR_RADIUS := 300.0
const MAIN_ROTOR_TILT := 11.0
const TAIL_ROTOR_RADIUS := 58.0
const VISUAL_SCALE := 0.9

@export var hover_position := Vector2(700.0, 165.0)
@export var enter_from := Vector2(-460.0, 70.0)
@export var exit_to := Vector2(-560.0, 30.0)
@export var enter_duration := 3.8
@export var drop_interval := 0.6
@export var rocket_count := 4
@export var rocket_interval := 1.05
@export var rocket_speed := 740.0
@export var rocket_damage := 24.0
@export var ground_dust_y := 355.0
@export var land_y_min := 385.0
@export var land_y_max := 575.0

var troop_types: Array[String] = []

var _phase: Phase = Phase.ENTER
var _phase_time := 0.0
var _time := 0.0
var _main_angle := 0.0
var _tail_angle := 0.0
var _main_speed := 15.5
var _tail_speed := 42.0
var _base_pos := Vector2.ZERO
var _prev_pos := Vector2.ZERO
var _vel := Vector2.ZERO
var _acc := Vector2.ZERO
var _tilt := 0.0
var _drop_index := 0
var _drop_timer := 0.0
var _last_land_time := 0.0
var _rockets_fired := 0
var _rocket_timer := 0.0
var _last_targeted_tile_idx := -1
var _dust_timer := 0.0
var _smoke_timer := 0.0
var _hover_amount := 0.0

var _visual: Node2D
var _body: Sprite2D
var _rotor_back: Node2D
var _rotor_front: Node2D
var _tail_rotor: Node2D
var _swirl: Node2D
var _ground_shadow: Polygon2D
var _rotor_sound: AudioStreamPlayer
var _rocket_sound: AudioStreamPlayer


func setup(p_troops: Array[String]) -> void:
	troop_types = p_troops.duplicate()


func _ready() -> void:
	_visual = $Visual
	_body = $Visual/Body
	_rotor_back = $Visual/RotorBack
	_rotor_front = $Visual/RotorFront
	_tail_rotor = $Visual/TailRotor
	_swirl = $Visual/Swirl
	_rotor_sound = get_node_or_null("RotorSound")
	_rocket_sound = get_node_or_null("RocketLaunchSound")

	if _rotor_sound:
		_rotor_sound.volume_db = -24.0
		_rotor_sound.play()
		_rotor_sound.finished.connect(_on_rotor_sound_finished)

	_rotor_back.draw.connect(_draw_main_rotor.bind(_rotor_back, false))
	_rotor_front.draw.connect(_draw_main_rotor.bind(_rotor_front, true))
	_tail_rotor.draw.connect(_draw_tail_rotor)
	_swirl.draw.connect(_draw_swirls)

	_create_ground_shadow()

	# Прилітає зліва носом уперед (вправо), тому спочатку дзеркалимо спрайт
	_visual.scale = Vector2(-VISUAL_SCALE, VISUAL_SCALE)
	_main_angle = randf() * TAU
	_base_pos = enter_from
	global_position = enter_from
	_prev_pos = enter_from
	_set_phase(Phase.ENTER)


func get_rope_anchor() -> Vector2:
	return _visual.get_global_transform() * DOOR_ANCHOR


func _set_phase(p: Phase) -> void:
	_phase = p
	_phase_time = 0.0


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_time += delta
	_phase_time += delta
	_main_angle = wrapf(_main_angle + _main_speed * delta, 0.0, TAU)
	_tail_angle = wrapf(_tail_angle + _tail_speed * delta, 0.0, TAU)

	match _phase:
		Phase.ENTER:
			var t := clampf(_phase_time / enter_duration, 0.0, 1.0)
			# Швидкий підліт і плавне гальмування над точкою висадки
			var e := 1.0 - pow(1.0 - t, 2.6)
			_base_pos = enter_from.lerp(hover_position + Vector2(0.0, -18.0), e)
			_base_pos.y -= sin(t * PI) * 22.0
			_hover_amount = lerpf(0.0, 1.0, clampf((t - 0.7) / 0.3, 0.0, 1.0))
			if t >= 1.0:
				_set_phase(Phase.TURN)
		Phase.TURN:
			# Розворот на 180° носом до окопу (класичний 2D-розворот через стискання по X)
			var t := clampf(_phase_time / 1.0, 0.0, 1.0)
			var s := -cos(t * PI)
			_visual.scale.x = VISUAL_SCALE * s
			if absf(s) < 0.12:
				_visual.scale.x = 0.12 * VISUAL_SCALE * (signf(s) if s != 0.0 else 1.0)
			_base_pos = hover_position + Vector2(0.0, -18.0 - sin(t * PI) * 8.0)
			_hover_amount = 1.0
			if t >= 1.0:
				_visual.scale.x = VISUAL_SCALE
				_set_phase(Phase.DESCEND)
		Phase.DESCEND:
			var t := clampf(_phase_time / 0.7, 0.0, 1.0)
			var e := t * t * (3.0 - 2.0 * t)
			_base_pos = hover_position + Vector2(0.0, lerpf(-18.0, 0.0, e))
			if t >= 1.0:
				_drop_index = 0
				_drop_timer = 0.15
				_set_phase(Phase.DROP)
		Phase.DROP:
			_base_pos = hover_position
			_process_drop(delta)
		Phase.ROCKET_ATTACK:
			# Зависає в повітрі після висадки десанту й послідовно випускає ракети по плитках окопа
			_base_pos = hover_position + Vector2(0.0, -4.0)
			_process_rocket_attack(delta)
		Phase.ASCEND:
			var t := clampf(_phase_time / 0.8, 0.0, 1.0)
			_base_pos = hover_position + Vector2(10.0 * t, -30.0 * t * t)
			if t >= 1.0:
				_set_phase(Phase.LEAVE)
		Phase.LEAVE:
			# Відлітає вліво носом уперед з наростаючою швидкістю
			var t := clampf(_phase_time / 3.6, 0.0, 1.0)
			var e := pow(t, 2.1)
			var from := hover_position + Vector2(10.0, -30.0)
			_base_pos = from.lerp(exit_to, e)
			_hover_amount = lerpf(1.0, 0.0, clampf(t * 2.5, 0.0, 1.0))
			if t >= 1.0:
				finished.emit()
				queue_free()
				return

	_update_motion(delta)
	_update_effects(delta)

	_rotor_back.queue_redraw()
	_rotor_front.queue_redraw()
	_tail_rotor.queue_redraw()
	_swirl.queue_redraw()


func _process_drop(delta: float) -> void:
	if _drop_index < troop_types.size():
		_drop_timer -= delta
		if _drop_timer <= 0.0:
			_drop_timer = drop_interval
			var from := get_rope_anchor()
			var land := Vector2(
				from.x + randf_range(-34.0, 30.0),
				randf_range(land_y_min, land_y_max)
			)
			trooper_drop_requested.emit(troop_types[_drop_index], from, land)
			_drop_index += 1
			var slide_time := clampf((land.y - from.y) / 430.0, 0.6, 1.35)
			_last_land_time = _phase_time + slide_time
	elif _phase_time >= _last_land_time + 0.45:
		_rockets_fired = 0
		_rocket_timer = 0.25
		_last_targeted_tile_idx = -1
		_set_phase(Phase.ROCKET_ATTACK)


func _process_rocket_attack(delta: float) -> void:
	if _rockets_fired < rocket_count:
		_rocket_timer -= delta
		if _rocket_timer <= 0.0:
			_rocket_timer = rocket_interval
			_fire_next_rocket()
			_rockets_fired += 1
	elif _phase_time >= float(rocket_count) * rocket_interval + 0.55:
		_set_phase(Phase.ASCEND)


func _fire_next_rocket() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var pod_world_pos := _visual.get_global_transform() * ROCKET_POD_POS
	var tile_idx := _choose_trench_tile_index()
	_last_targeted_tile_idx = tile_idx
	var tile_target := Vector2(TRENCH_X, TRENCH_TILES_Y[tile_idx])

	var rocket := HeliRocket.new()
	rocket.setup(pod_world_pos, tile_target, rocket_speed, rocket_damage)
	parent_node.add_child(rocket)

	# Віддача корпусу вертольота при пуску ракети + спалах з блоку НАР
	_tilt -= 0.045
	_spawn_rocket_launch_flash(pod_world_pos)

	if _rocket_sound:
		_rocket_sound.pitch_scale = randf_range(0.96, 1.04)
		_rocket_sound.play()


func _choose_trench_tile_index() -> int:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and not player.get("is_dead"):
		# Знаходимо плитку окопа, на якій зараз стоїть гравець
		var best_idx := 1
		var best_dist := INF
		for i in range(TRENCH_TILES_Y.size()):
			var d := absf(player.global_position.y - TRENCH_TILES_Y[i])
			if d < best_dist:
				best_dist = d
				best_idx = i
		# Якщо попередня ракета вже летіла в цю ж саму плитку і гравець не встиг переміститись — чергуємо з сусідньою
		if best_idx == _last_targeted_tile_idx and randf() < 0.45:
			return (best_idx + 1 + randi() % 2) % TRENCH_TILES_Y.size()
		return best_idx
	return (_rockets_fired + randi() % 2) % TRENCH_TILES_Y.size()


func _spawn_rocket_launch_flash(pod_pos: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	# Яскравий спалах пуску спереду блоку НАР С-8
	var flash := Polygon2D.new()
	flash.color = Color(1.0, 0.82, 0.30, 0.96)
	flash.polygon = PackedVector2Array([
		Vector2(0.0, -7.0),
		Vector2(-26.0, -12.0),
		Vector2(-16.0, -2.0),
		Vector2(-34.0, 2.0),
		Vector2(-15.0, 5.0),
		Vector2(-24.0, 13.0),
		Vector2(0.0, 7.0),
	])
	flash.global_position = pod_pos + Vector2(-12.0, 2.0)
	flash.z_index = 4
	parent_node.add_child(flash)

	var ftw := flash.create_tween()
	ftw.tween_property(flash, "scale", Vector2(1.3, 1.3), 0.08)
	ftw.parallel().tween_property(flash, "modulate:a", 0.0, 0.12)
	ftw.tween_callback(flash.queue_free)

	# Хмарка реактивного диму позаду блоку НАР
	var back_puff := Polygon2D.new()
	back_puff.color = Color(0.82, 0.80, 0.76, 0.65)
	back_puff.polygon = PackedVector2Array([
		Vector2(-8.0, -6.0),
		Vector2(10.0, -8.0),
		Vector2(18.0, 0.0),
		Vector2(10.0, 8.0),
		Vector2(-8.0, 6.0),
	])
	back_puff.global_position = pod_pos + Vector2(18.0, 2.0)
	back_puff.z_index = 2
	parent_node.add_child(back_puff)

	var btw := back_puff.create_tween()
	btw.set_parallel(true)
	btw.tween_property(back_puff, "global_position", back_puff.global_position + Vector2(36.0, 10.0), 0.32)
	btw.tween_property(back_puff, "scale", Vector2(2.2, 1.8), 0.32)
	btw.tween_property(back_puff, "modulate:a", 0.0, 0.32)
	btw.chain().tween_callback(back_puff.queue_free)


func _on_rotor_sound_finished() -> void:
	if _rotor_sound and is_inside_tree():
		_rotor_sound.play()


func _update_motion(delta: float) -> void:
	# Погойдування в зависанні (вертоліт "дихає" на повітряній подушці)
	var bob := Vector2(
		sin(_time * 1.3) * 3.0,
		sin(_time * 2.3) * 4.5 + sin(_time * 5.1) * 1.2
	) * _hover_amount
	global_position = _base_pos + bob

	var new_vel := (global_position - _prev_pos) / delta
	_acc = _acc.lerp((new_vel - _vel) / delta, clampf(delta * 6.0, 0.0, 1.0))
	_vel = new_vel
	_prev_pos = global_position

	# Нахил носом вниз у напрямку руху та "задирання носа" при гальмуванні
	var target_tilt := clampf(_vel.x * 0.00075 + _acc.x * 0.00022, -0.24, 0.24)
	target_tilt += sin(_time * 1.7) * 0.012 * _hover_amount
	_tilt = lerpf(_tilt, target_tilt, clampf(delta * 4.0, 0.0, 1.0))
	_visual.rotation = _tilt


func _update_effects(delta: float) -> void:
	# Тінь на землі під вертольотом
	if _ground_shadow:
		_ground_shadow.global_position = Vector2(global_position.x - 10.0, ground_dust_y - 70.0)
		var alt := clampf(1.0 - absf(global_position.y - hover_position.y) / 220.0, 0.0, 1.0)
		var on_screen := clampf((global_position.x + 200.0) / 300.0, 0.0, 1.0)
		_ground_shadow.modulate.a = 0.55 * alt * on_screen
		_ground_shadow.scale = Vector2(lerpf(0.8, 1.0, alt), 1.0)

	# Плавне регулювання гучності гвинтів залежно від положення вертольота на екрані (трохи тихіше, щоб не глушило постріли)
	if _rotor_sound:
		var screen_presence := clampf((global_position.x + 360.0) / 520.0, 0.0, 1.0)
		_rotor_sound.volume_db = lerpf(-26.0, -10.5, screen_presence)

	# Пил від потоку повітря з гвинта, що розлітається по полю в обидва боки
	if _hover_amount > 0.3 and global_position.x > -100.0 and global_position.x < 1380.0:
		_dust_timer -= delta
		if _dust_timer <= 0.0:
			_dust_timer = 0.05
			_spawn_rotor_dust()

	# Вихлоп двигуна
	_smoke_timer -= delta
	if _smoke_timer <= 0.0:
		_smoke_timer = 0.09
		_spawn_exhaust_puff()


func _spawn_rotor_dust() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var dir := -1.0 if randf() < 0.5 else 1.0
	var puff := Polygon2D.new()
	var r := randf_range(6.0, 13.0)
	var pts := PackedVector2Array()
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var rr := r * randf_range(0.75, 1.15)
		pts.append(Vector2(cos(a) * rr, sin(a) * rr * 0.6))
	puff.polygon = pts
	puff.color = Color(0.62, 0.53, 0.40, 0.42 * _hover_amount)
	var y := ground_dust_y + randf_range(-30.0, 40.0)
	puff.global_position = Vector2(global_position.x + randf_range(-40.0, 40.0), y)
	puff.z_index = -2
	parent_node.add_child(puff)

	var dist := randf_range(160.0, 300.0)
	var target := puff.global_position + Vector2(dir * dist, randf_range(-26.0, -6.0))
	var dur := randf_range(0.7, 1.1)
	var tw := puff.create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "global_position", target, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(puff, "scale", Vector2(2.6, 2.0), dur)
	tw.tween_property(puff, "modulate:a", 0.0, dur).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(puff.queue_free)


func _spawn_exhaust_puff() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var puff := Polygon2D.new()
	var r := randf_range(4.0, 7.0)
	puff.polygon = PackedVector2Array([
		Vector2(-r, -r * 0.5), Vector2(0.0, -r), Vector2(r, -r * 0.4),
		Vector2(r * 0.8, r * 0.6), Vector2(-r * 0.6, r * 0.7),
	])
	puff.color = Color(0.32, 0.31, 0.30, 0.45)
	puff.global_position = _visual.get_global_transform() * EXHAUST_POS
	puff.z_index = 1
	parent_node.add_child(puff)

	# Дим відноситься назад (до хвоста) і вниз потоком від гвинта
	var back_dir := signf(_visual.scale.x)
	var target := puff.global_position + Vector2(back_dir * randf_range(40.0, 70.0), randf_range(10.0, 30.0))
	var tw := puff.create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "global_position", target, 0.6)
	tw.tween_property(puff, "scale", Vector2(2.4, 2.4), 0.6)
	tw.tween_property(puff, "modulate:a", 0.0, 0.6)
	tw.chain().tween_callback(puff.queue_free)


func _create_ground_shadow() -> void:
	_ground_shadow = Polygon2D.new()
	_ground_shadow.top_level = true
	_ground_shadow.z_index = -3
	_ground_shadow.color = Color(0.0, 0.0, 0.0, 0.5)
	var pts := PackedVector2Array()
	for i in range(20):
		var a := float(i) * TAU / 20.0
		pts.append(Vector2(cos(a) * 230.0, sin(a) * 26.0))
	_ground_shadow.polygon = pts
	add_child(_ground_shadow)


## Малює лопаті головного гвинта у бічній проєкції: лопать скорочується за косинусом кута,
## задні лопаті малюються за корпусом, передні — перед ним, плюс шлейф розмиття руху.
func _draw_main_rotor(canvas: Node2D, front: bool) -> void:
	var blade_count := 4
	var tex_w := float(BLADE_TEX.get_width())
	var tex_h := float(BLADE_TEX.get_height())

	# Напівпрозорий диск обертання
	if front:
		var disc := PackedVector2Array()
		for i in range(24):
			var a := float(i) * TAU / 24.0
			disc.append(ROTOR_HUB + Vector2(cos(a) * MAIN_ROTOR_RADIUS, sin(a) * MAIN_ROTOR_TILT * 1.1))
		canvas.draw_colored_polygon(disc, Color(0.85, 0.88, 0.80, 0.07))

	var ghosts := [0.0, 0.09, 0.18, 0.27]
	var ghost_alpha := [1.0, 0.32, 0.17, 0.08]
	for g in range(ghosts.size() - 1, -1, -1):
		for b in range(blade_count):
			var theta: float = _main_angle + float(b) * TAU / float(blade_count) - ghosts[g]
			var depth := sin(theta)
			if (depth >= 0.0) != front:
				continue
			var tip := Vector2(cos(theta) * MAIN_ROTOR_RADIUS, depth * MAIN_ROTOR_TILT)
			var length := tip.length()
			if length < 4.0:
				continue
			var ang := tip.angle()
			var flip_y := -1.0 if cos(theta) < 0.0 else 1.0
			var sx := length / tex_w
			var sy := 0.24 * flip_y
			# Ближчі до камери лопаті трохи світліші, дальні — темніші
			var shade := lerpf(0.72, 1.0, (depth + 1.0) * 0.5)
			var col := Color(shade, shade, shade, ghost_alpha[g])
			canvas.draw_set_transform(ROTOR_HUB, ang, Vector2(sx, sy))
			canvas.draw_texture(BLADE_TEX, Vector2(0.0, -tex_h * 0.5), col)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Ковпак втулки гвинта поверх лопатей
	if front:
		canvas.draw_circle(ROTOR_HUB + Vector2(0.0, -2.0), 9.0, Color(0.10, 0.09, 0.07))
		canvas.draw_circle(ROTOR_HUB + Vector2(0.0, -2.0), 6.5, Color(0.42, 0.29, 0.17))
		canvas.draw_circle(ROTOR_HUB + Vector2(-1.5, -3.5), 2.2, Color(0.66, 0.50, 0.32))


## Хвостовий гвинт обертається у площині екрана (бачимо його збоку анфас)
func _draw_tail_rotor() -> void:
	var tex_w := float(BLADE_TEX.get_width())
	var tex_h := float(BLADE_TEX.get_height())
	_tail_rotor.draw_circle(TAIL_HUB, TAIL_ROTOR_RADIUS, Color(0.85, 0.88, 0.80, 0.10))
	_tail_rotor.draw_arc(TAIL_HUB, TAIL_ROTOR_RADIUS, 0.0, TAU, 32, Color(0.1, 0.1, 0.08, 0.18), 1.5)

	var ghosts := [0.0, 0.14, 0.28, 0.42]
	var ghost_alpha := [1.0, 0.35, 0.18, 0.08]
	for g in range(ghosts.size() - 1, -1, -1):
		for b in range(4):
			var theta: float = _tail_angle + float(b) * TAU / 4.0 - ghosts[g]
			var sx := TAIL_ROTOR_RADIUS / tex_w
			_tail_rotor.draw_set_transform(TAIL_HUB, theta, Vector2(sx, 0.2))
			_tail_rotor.draw_texture(BLADE_TEX, Vector2(0.0, -tex_h * 0.5), Color(1, 1, 1, ghost_alpha[g]))
	_tail_rotor.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	_tail_rotor.draw_circle(TAIL_HUB, 7.0, Color(0.10, 0.09, 0.07))
	_tail_rotor.draw_circle(TAIL_HUB, 4.6, Color(0.45, 0.31, 0.18))


## Білі "вихори" повітря навколо гвинтів, як на референсі
func _draw_swirls() -> void:
	var col := Color(0.92, 0.94, 0.96, 0.22)
	# Навколо хвостового гвинта — кільця, що обертаються
	for i in range(3):
		var r := TAIL_ROTOR_RADIUS + 8.0 + float(i) * 7.0
		var start := _tail_angle * (0.35 + 0.1 * float(i)) + float(i) * 2.1
		_swirl.draw_arc(TAIL_HUB, r, start, start + 2.2, 18, col, 2.0)
	# Навколо головного гвинта — пласкі еліптичні дуги
	for i in range(3):
		var rx := MAIN_ROTOR_RADIUS * (0.55 + 0.17 * float(i))
		var ry := 16.0 + float(i) * 7.0
		var start := _main_angle * 0.25 + float(i) * 2.3
		var pts := PackedVector2Array()
		for k in range(16):
			var a := start + float(k) / 15.0 * 1.9
			pts.append(ROTOR_HUB + Vector2(cos(a) * rx, sin(a) * ry - 6.0))
		_swirl.draw_polyline(pts, Color(col.r, col.g, col.b, col.a * 0.8), 2.0, true)
