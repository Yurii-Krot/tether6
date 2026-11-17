class_name AxeProjectile
extends Node2D

const THROWN_AXE_TEX := preload("res://assets/thrown_axe.png")
const THROWN_BOSS_HAMMER_TEX := preload("res://assets/thrown_boss_hammer.png")
const IMPACT_SOUND := preload("res://assets/grenade_explosion.wav")
const TILE_HALF_HEIGHT := 46.0

enum Phase { FLIGHT, STUCK }

var _phase: Phase = Phase.FLIGHT
var _start_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _flight_duration := 0.85
var _damage := 30.0
var _arc_height := 118.0
var _is_boss_hammer := false

var _elapsed := 0.0
var _stuck_timer := 0.0
var _stuck_hold_duration := 0.50
var _stuck_fade_duration := 0.25
var _base_stuck_angle := -0.76
var _base_scale := 0.56
var _trail_timer := 0.0
var _trail_dots: Array[Dictionary] = []
var _crater_cracks: Array[Dictionary] = []
var _crater_clumps: Array[Dictionary] = []

var _sprite: Sprite2D = null
var _front_rim: Polygon2D = null
var _front_rim_shadow: Polygon2D = null
var _shadow_pos := Vector2.ZERO
var _hole_pos := Vector2.ZERO
var _flight_height := 0.0


func setup(
	from_pos: Vector2,
	to_pos: Vector2,
	p_damage: float = 30.0,
	p_flight_duration: float = 0.85,
	p_is_boss_hammer: bool = false
) -> void:
	_start_pos = from_pos
	_target_pos = to_pos
	_damage = p_damage
	_flight_duration = maxf(p_flight_duration, 0.25)
	_is_boss_hammer = p_is_boss_hammer
	_base_scale = 0.68 if _is_boss_hammer else 0.56
	_stuck_hold_duration = 0.55 if _is_boss_hammer else 0.50
	_stuck_fade_duration = 0.30 if _is_boss_hammer else 0.25
	var arc_mult := 0.31 if _is_boss_hammer else 0.28
	var arc_min := 94.0 if _is_boss_hammer else 78.0
	var arc_max := 168.0 if _is_boss_hammer else 148.0
	_arc_height = clampf(from_pos.distance_to(to_pos) * arc_mult, arc_min, arc_max)
	_shadow_pos = from_pos
	_hole_pos = to_pos + Vector2(0.0, 8.0)
	global_position = from_pos
	z_index = 12


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = THROWN_BOSS_HAMMER_TEX if _is_boss_hammer else THROWN_AXE_TEX
	_sprite.scale = Vector2(_base_scale, _base_scale)
	add_child(_sprite)


func _process(delta: float) -> void:
	if _phase == Phase.FLIGHT:
		_process_flight(delta)
	else:
		_process_stuck(delta)
	queue_redraw()


func _process_flight(delta: float) -> void:
	_elapsed += delta
	var prog := clampf(_elapsed / _flight_duration, 0.0, 1.0)
	var ground_pos := _start_pos.lerp(_target_pos, prog)
	var height := sin(prog * PI) * _arc_height
	_shadow_pos = ground_pos + Vector2(0.0, 12.0)
	_flight_height = height
	global_position = ground_pos + Vector2(0.0, -height)

	if _sprite:
		var spin_speed := -17.5 if _is_boss_hammer else -19.5
		_sprite.rotation += delta * spin_speed
		var min_air := 0.62 if _is_boss_hammer else 0.52
		var max_air := 0.74 if _is_boss_hammer else 0.62
		var air_scale := lerpf(min_air, max_air, sin(prog * PI) * 0.65 + prog * 0.35)
		_sprite.scale = Vector2(air_scale, air_scale)

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.018 if _is_boss_hammer else 0.026
		_trail_dots.append({
			"pos": global_position + Vector2(randf_range(-5.0, 5.0), randf_range(-5.0, 5.0)),
			"age": 0.0,
			"life": 0.25 if _is_boss_hammer else 0.20,
			"size": randf_range(4.2, 7.2) if _is_boss_hammer else randf_range(3.2, 5.8)
		})

	_update_dots(delta)

	if prog >= 1.0:
		_on_landed()


func _process_stuck(delta: float) -> void:
	_stuck_timer += delta
	_update_dots(delta)

	var current_alpha := 1.0
	if _stuck_timer > _stuck_hold_duration:
		var fade_t := clampf((_stuck_timer - _stuck_hold_duration) / _stuck_fade_duration, 0.0, 1.0)
		current_alpha = 1.0 - (fade_t * fade_t * (3.0 - 2.0 * fade_t))

	# Пружна вібрація руків'я щойно застряглої в окопі сокири / молота
	if _sprite:
		if _stuck_timer < 0.34:
			var amp := 0.16 if _is_boss_hammer else 0.22
			var freq := 38.0 if _is_boss_hammer else 46.0
			var wobble := sin(_stuck_timer * freq) * exp(-_stuck_timer * 10.0) * amp
			_sprite.rotation = _base_stuck_angle + wobble
		else:
			_sprite.rotation = _base_stuck_angle
		_sprite.modulate.a = current_alpha

	if _front_rim:
		_front_rim.modulate.a = current_alpha
	if _front_rim_shadow:
		_front_rim_shadow.modulate.a = current_alpha

	if _stuck_timer >= (_stuck_hold_duration + _stuck_fade_duration):
		queue_free()


func _update_dots(delta: float) -> void:
	for i in range(_trail_dots.size() - 1, -1, -1):
		var d: Dictionary = _trail_dots[i]
		d["age"] = float(d["age"]) + delta
		if float(d["age"]) >= float(d["life"]):
			_trail_dots.remove_at(i)
		else:
			_trail_dots[i] = d


func _on_landed() -> void:
	_phase = Phase.STUCK
	_stuck_timer = 0.0
	_flight_height = 0.0
	_hole_pos = _target_pos + Vector2(0.0, 8.0)
	global_position = _hole_pos if _is_boss_hammer else (_target_pos + Vector2(-4.0, 8.0))
	_shadow_pos = _target_pos + Vector2(0.0, 14.0)
	z_index = 5

	if _sprite:
		if _is_boss_hammer:
			_base_stuck_angle = randf_range(-0.46, -0.30)
			_sprite.position = Vector2(12.0, -11.0)
			_sprite.rotation = _base_stuck_angle
			# Потужне вдавлювання молота в ґрунт окопу
			_sprite.scale = Vector2(_base_scale * 1.16, _base_scale * 0.84)
			var impact_tw := _sprite.create_tween()
			impact_tw.tween_property(_sprite, "scale", Vector2(_base_scale, _base_scale), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			_build_hammer_crater_hole()
		else:
			_base_stuck_angle = randf_range(-0.84, -0.68)
			_sprite.rotation = _base_stuck_angle
			# Легке стискання від удару в землю / бруствер
			_sprite.scale = Vector2(0.64, 0.48)
			var impact_tw := _sprite.create_tween()
			impact_tw.tween_property(_sprite, "scale", Vector2(0.56, 0.56), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var hit_player := false
	var players := get_tree().get_nodes_in_group("player")
	if not players.is_empty():
		var player := players[0]
		if player != null and not bool(player.get("is_dead")):
			var dy := absf(float(player.global_position.y) - _target_pos.y)
			if dy <= TILE_HALF_HEIGHT and player.has_method("take_damage"):
				player.take_damage(_damage, true)
				hit_player = true

	var sfx := AudioStreamPlayer.new()
	sfx.stream = IMPACT_SOUND
	if _is_boss_hammer:
		sfx.volume_db = -9.5 if hit_player else -12.5
		sfx.pitch_scale = randf_range(0.84, 0.98) if hit_player else randf_range(0.95, 1.12)
	else:
		sfx.volume_db = -12.0 if hit_player else -15.5
		sfx.pitch_scale = randf_range(1.75, 1.98) if hit_player else randf_range(2.05, 2.35)
	var parent_node := get_parent()
	if parent_node != null:
		parent_node.add_child(sfx)
		sfx.finished.connect(sfx.queue_free)
		sfx.play()

	_spawn_impact_burst(hit_player)
	if is_inside_tree():
		var env := get_tree().get_first_node_in_group("battlefield_environment")
		if env != null:
			if _is_boss_hammer and env.has_method("spawn_explosion_crater"):
				env.spawn_explosion_crater(_hole_pos, 38.0, false)
			elif env.has_method("trigger_shockwave"):
				env.trigger_shockwave(_target_pos, 55.0, 0.18)


func _build_hammer_crater_hole() -> void:
	_crater_cracks.clear()
	for i in range(7):
		var angle := (TAU / 7.0) * float(i) + randf_range(-0.22, 0.22)
		var start_r := randf_range(8.5, 12.5)
		var mid_r := start_r + randf_range(5.5, 8.5)
		var end_r := mid_r + randf_range(4.5, 7.5)
		var p0 := Vector2(cos(angle) * start_r, sin(angle) * start_r * 0.45)
		var bend := angle + randf_range(-0.35, 0.35)
		var p1 := Vector2(cos(bend) * mid_r, sin(bend) * mid_r * 0.46)
		var bend2 := bend + randf_range(-0.45, 0.45)
		var p2 := Vector2(cos(bend2) * end_r, sin(bend2) * end_r * 0.48)
		_crater_cracks.append({
			"p0": p0,
			"p1": p1,
			"p2": p2,
			"width": randf_range(1.3, 2.1)
		})

	_crater_clumps.clear()
	for i in range(9):
		var angle := randf_range(0.0, TAU)
		var dist := randf_range(12.5, 19.5)
		_crater_clumps.append({
			"pos": Vector2(cos(angle) * dist, sin(angle) * dist * 0.44 + 1.5),
			"r": randf_range(1.6, 3.2),
			"col": Color(0.28, 0.21, 0.14, 0.90) if (i % 2 == 0) else Color(0.20, 0.15, 0.10, 0.88)
		})

	# Передній валик ґрунту поверх нижньої частини молота — створює ілюзію компактної глибокої дірки
	_front_rim_shadow = Polygon2D.new()
	_front_rim_shadow.color = Color(0.08, 0.05, 0.03, 0.92)
	_front_rim_shadow.polygon = PackedVector2Array([
		Vector2(-18, 0), Vector2(-11, 4), Vector2(-2, 6), Vector2(7, 5),
		Vector2(16, 2), Vector2(19, 5), Vector2(9, 9), Vector2(-2, 10),
		Vector2(-13, 8), Vector2(-19, 4)
	])
	add_child(_front_rim_shadow)

	_front_rim = Polygon2D.new()
	_front_rim.color = Color(0.35, 0.26, 0.18, 0.98)
	_front_rim.polygon = PackedVector2Array([
		Vector2(-17, 2), Vector2(-10, 6), Vector2(-1, 7), Vector2(8, 6),
		Vector2(16, 3), Vector2(18, 7), Vector2(8, 11), Vector2(-3, 12),
		Vector2(-12, 10), Vector2(-18, 6)
	])
	add_child(_front_rim)


func _spawn_impact_burst(hit_player: bool) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var count := 14 if _is_boss_hammer else 8
	var spread_x := 40.0 if _is_boss_hammer else 28.0
	var spread_y_min := -44.0 if _is_boss_hammer else -32.0
	for i in range(count):
		var chip := Polygon2D.new()
		if hit_player and i % 2 == 0:
			chip.color = Color(0.85, 0.14, 0.14, 0.9)
		elif _is_boss_hammer and i % 3 == 0:
			chip.color = Color(0.38, 0.30, 0.22, 0.92)
		else:
			chip.color = Color(0.58, 0.48, 0.36, 0.88)
		var sz := 1.25 if _is_boss_hammer else 1.0
		chip.polygon = PackedVector2Array([
			Vector2(-3.5 * sz, -2.0 * sz),
			Vector2(3.5 * sz, -1.0 * sz),
			Vector2(2.5 * sz, 3.0 * sz),
			Vector2(-2.5 * sz, 2.0 * sz)
		])
		chip.global_position = _target_pos + Vector2(0.0, 6.0)
		chip.z_index = 10
		parent_node.add_child(chip)
		var end_pos := _target_pos + Vector2(randf_range(-spread_x, spread_x), randf_range(spread_y_min, 12.0))
		var tw := chip.create_tween()
		tw.set_parallel(true)
		var dur := 0.28 if _is_boss_hammer else 0.24
		tw.tween_property(chip, "global_position", end_pos, dur).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(chip, "rotation", randf_range(-6.0, 6.0), dur)
		tw.tween_property(chip, "modulate:a", 0.0, dur)
		tw.chain().tween_callback(chip.queue_free)


func _draw() -> void:
	# Легка тінь самої зброї на землі під траєкторією (без попереджувальної мітки)
	if _phase == Phase.FLIGHT:
		var h_ratio := clampf(1.0 - (_flight_height / maxf(_arc_height, 1.0)), 0.35, 1.0)
		var shadow_local := to_local(_shadow_pos)
		var base_r := 22.0 if _is_boss_hammer else 16.0
		draw_set_transform(shadow_local, 0.0, Vector2(1.0, 0.42))
		draw_circle(Vector2.ZERO, base_r * h_ratio, Color(0.0, 0.0, 0.0, 0.30 * h_ratio))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	else:
		var stuck_alpha := _sprite.modulate.a if _sprite else 1.0
		if _is_boss_hammer:
			# Кратер/дірка в землі окопу під вбитим молотом
			for c in _crater_cracks:
				var col_crack := Color(0.08, 0.05, 0.04, 0.78 * stuck_alpha)
				draw_line(c["p0"], c["p1"], col_crack, float(c["width"]))
				draw_line(c["p1"], c["p2"], Color(0.08, 0.05, 0.04, 0.45 * stuck_alpha), float(c["width"]) * 0.65)

			draw_set_transform(Vector2(0.0, 2.0), 0.0, Vector2(1.0, 0.46))
			draw_circle(Vector2.ZERO, 19.0, Color(0.28, 0.20, 0.13, 0.88 * stuck_alpha))
			draw_circle(Vector2.ZERO, 15.0, Color(0.05, 0.03, 0.02, 0.96 * stuck_alpha))
			draw_circle(Vector2(-1.5, -0.5), 10.5, Color(0.015, 0.01, 0.008, 0.98 * stuck_alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

			for clump in _crater_clumps:
				var ccol: Color = clump["col"]
				ccol.a *= stuck_alpha
				draw_circle(clump["pos"], float(clump["r"]), ccol)

			if _stuck_timer < 0.24:
				var ring_t := _stuck_timer / 0.24
				draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0, 0.44))
				draw_arc(Vector2.ZERO, lerpf(10.0, 28.0, ring_t), 0.0, TAU, 24, Color(0.84, 0.76, 0.62, (1.0 - ring_t) * 0.55), 2.4 * (1.0 - ring_t))
				draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			var shadow_local := to_local(_shadow_pos)
			draw_set_transform(shadow_local, 0.0, Vector2(1.0, 0.40))
			draw_circle(Vector2.ZERO, 14.0, Color(0.0, 0.0, 0.0, 0.32 * stuck_alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	for d in _trail_dots:
		var t := float(d["age"]) / maxf(float(d["life"]), 0.01)
		var local_p := to_local(d["pos"] as Vector2)
		var trail_col := Color(0.88, 0.78, 0.62, (1.0 - t) * 0.48) if _is_boss_hammer else Color(0.92, 0.86, 0.72, (1.0 - t) * 0.42)
		draw_circle(local_p, float(d["size"]) * (1.0 - t * 0.5), trail_col)
