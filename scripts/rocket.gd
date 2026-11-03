class_name HeliRocket
extends Node2D

## Некерована авіаційна ракета НАР С-8, яку випускає вертоліт по одній конкретній плитці окопа.

const ROCKET_SHEET := preload("res://assets/rocket_spritesheet.png")

# Висота однієї плитки окопа (відстань між 3 позиціями в окопі = 95 px, тому радіус плитки ±46 px)
const TILE_HALF_HEIGHT := 46.0
const TILE_HALF_WIDTH := 38.0

var start_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var speed := 740.0
var damage := 24.0

var _direction := Vector2.LEFT
var _total_dist := 1.0
var _traveled := 0.0
var _anim_time := 0.0
var _smoke_timer := 0.0
var _sprite: Sprite2D = null
var _warning_marker: Node2D = null


func setup(from_pos: Vector2, to_tile_pos: Vector2, p_speed: float = 740.0, p_damage: float = 24.0) -> void:
	start_pos = from_pos
	target_pos = to_tile_pos
	speed = p_speed
	damage = p_damage
	global_position = from_pos

	var diff := target_pos - start_pos
	_total_dist = maxf(diff.length(), 1.0)
	_direction = diff / _total_dist
	rotation = _direction.angle()


func _ready() -> void:
	z_index = 5

	_sprite = Sprite2D.new()
	_sprite.texture = ROCKET_SHEET
	_sprite.hframes = 1
	_sprite.vframes = 4
	_sprite.scale = Vector2(0.34, 0.34)
	# Зміщуємо спрайт так, щоб бойова частина (носик ракети) була попереду в точці global_position
	_sprite.offset = Vector2(-120.0, 0.0)
	add_child(_sprite)

	_create_tile_warning()


func _physics_process(delta: float) -> void:
	_anim_time += delta

	# Анімація реактивного полум'я ракети в польоті (4 кадри)
	if _sprite:
		var frame_idx := int(_anim_time * 24.0) % 4
		_sprite.frame = frame_idx

	if _warning_marker and is_instance_valid(_warning_marker):
		_warning_marker.queue_redraw()

	# Димовий шлейф та іскри позаду сопла ракети
	_smoke_timer -= delta
	if _smoke_timer <= 0.0:
		_smoke_timer = 0.022
		_spawn_smoke_trail()

	var step := speed * delta
	_traveled += step
	if _traveled >= _total_dist:
		global_position = target_pos
		_detonate_on_tile()
		return

	# Легка балістична дуга в польоті до окопу
	var prog := clampf(_traveled / _total_dist, 0.0, 1.0)
	var base_pt := start_pos.lerp(target_pos, prog)
	var arc_offset := Vector2(0.0, -sin(prog * PI) * 18.0)
	var next_pos := base_pt + arc_offset
	var move_vec := next_pos - global_position
	if move_vec.length_squared() > 0.01:
		rotation = move_vec.angle()
	global_position = next_pos


func _create_tile_warning() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	_warning_marker = Node2D.new()
	_warning_marker.global_position = target_pos
	_warning_marker.z_index = 2
	_warning_marker.draw.connect(_draw_tile_warning)
	parent_node.add_child(_warning_marker)


func _draw_tile_warning() -> void:
	if _warning_marker == null or not is_instance_valid(_warning_marker):
		return
	var prog := clampf(_traveled / _total_dist, 0.0, 1.0)
	var pulse := 0.5 + 0.5 * sin(_anim_time * 18.0)
	var alpha := lerpf(0.28, 0.62, pulse)

	# 1. Підсвітка рівно ОДНІЄЇ плитки окопа, куди летить ця ракета
	var rect := Rect2(
		-TILE_HALF_WIDTH,
		-TILE_HALF_HEIGHT + 4.0,
		TILE_HALF_WIDTH * 2.0,
		(TILE_HALF_HEIGHT - 4.0) * 2.0
	)
	_warning_marker.draw_rect(rect, Color(1.0, 0.18, 0.10, alpha * 0.45), true)
	_warning_marker.draw_rect(rect, Color(1.0, 0.32, 0.15, alpha), false, 2.2)

	# 2. Прицільне кільце в центрі плитки, що звужується перед ударом
	var outer_r := lerpf(26.0, 10.0, prog)
	_warning_marker.draw_arc(Vector2.ZERO, outer_r, 0.0, TAU, 24, Color(1.0, 0.85, 0.25, 0.85), 2.0)
	_warning_marker.draw_line(Vector2(-14.0, 0.0), Vector2(14.0, 0.0), Color(1.0, 0.25, 0.15, 0.85), 2.0)
	_warning_marker.draw_line(Vector2(0.0, -14.0), Vector2(0.0, 14.0), Color(1.0, 0.25, 0.15, 0.85), 2.0)


func _spawn_smoke_trail() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var nozzle_pos := global_position - Vector2.RIGHT.rotated(rotation) * 62.0

	# Клуб диму
	var puff := Polygon2D.new()
	var r := randf_range(4.5, 8.5)
	puff.polygon = PackedVector2Array([
		Vector2(-r, -r * 0.6),
		Vector2(0.0, -r),
		Vector2(r, -r * 0.5),
		Vector2(r * 0.8, r * 0.7),
		Vector2(-r * 0.7, r * 0.6),
	])
	puff.color = Color(0.78, 0.76, 0.72, 0.52)
	puff.global_position = nozzle_pos + Vector2(randf_range(-3.0, 3.0), randf_range(-3.0, 3.0))
	puff.rotation = randf_range(0.0, TAU)
	puff.z_index = 3
	parent_node.add_child(puff)

	var tw := puff.create_tween()
	tw.set_parallel(true)
	tw.tween_property(puff, "scale", Vector2(2.3, 2.3), 0.36)
	tw.tween_property(puff, "modulate:a", 0.0, 0.36)
	tw.chain().tween_callback(puff.queue_free)

	# Вогняна іскра з сопла
	if randf() < 0.65:
		var spark := Polygon2D.new()
		spark.color = Color(1.0, 0.78, 0.25, 0.92)
		spark.polygon = PackedVector2Array([
			Vector2(-3.5, -1.2),
			Vector2(3.5, 0.0),
			Vector2(-3.5, 1.2),
		])
		spark.global_position = nozzle_pos
		spark.rotation = rotation + randf_range(-0.35, 0.35)
		spark.z_index = 4
		parent_node.add_child(spark)

		var stw := spark.create_tween()
		stw.set_parallel(true)
		stw.tween_property(spark, "global_position", nozzle_pos - Vector2.RIGHT.rotated(spark.rotation) * randf_range(16.0, 32.0), 0.14)
		stw.tween_property(spark, "modulate:a", 0.0, 0.14)
		stw.chain().tween_callback(spark.queue_free)


func _detonate_on_tile() -> void:
	if _warning_marker and is_instance_valid(_warning_marker):
		_warning_marker.queue_free()
		_warning_marker = null

	# Перевіряємо, чи головний герой перебуває саме на цій плитці окопа (одна ракета атакує лише одну плитку!)
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and not player.get("is_dead"):
		var dy := absf(player.global_position.y - target_pos.y)
		if dy <= TILE_HALF_HEIGHT:
			if player.has_method("take_damage"):
				player.take_damage(damage, true)

	_spawn_explosion_effects()
	queue_free()


func _spawn_explosion_effects() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	# 1. Випалена вирва на плитці окопа
	var crater := Polygon2D.new()
	crater.color = Color(0.12, 0.09, 0.07, 0.72)
	var c_pts := PackedVector2Array()
	for i in range(14):
		var a := float(i) * TAU / 14.0
		c_pts.append(Vector2(cos(a) * 30.0, sin(a) * 18.0))
	crater.polygon = c_pts
	crater.global_position = target_pos + Vector2(0.0, 12.0)
	crater.z_index = -1
	parent_node.add_child(crater)

	var c_tw := crater.create_tween()
	c_tw.tween_interval(3.0)
	c_tw.tween_property(crater, "modulate:a", 0.0, 1.2)
	c_tw.tween_callback(crater.queue_free)

	# 2. Вогняна куля вибуху (зовнішнє полум'я + біле ядро + ударне кільце)
	var blast := Node2D.new()
	blast.global_position = target_pos
	blast.z_index = 6
	parent_node.add_child(blast)

	var outer_fire := Polygon2D.new()
	outer_fire.color = Color(1.0, 0.42, 0.12, 0.95)
	var f_pts := PackedVector2Array()
	for i in range(16):
		var a := float(i) * TAU / 16.0
		var r := 38.0 if (i % 2 == 0) else 26.0
		f_pts.append(Vector2(cos(a) * r, sin(a) * r * 0.85))
	outer_fire.polygon = f_pts
	blast.add_child(outer_fire)

	var inner_core := Polygon2D.new()
	inner_core.color = Color(1.0, 0.95, 0.65, 0.98)
	var i_pts := PackedVector2Array()
	for i in range(12):
		var a := float(i) * TAU / 12.0
		var r := 22.0 if (i % 2 == 0) else 15.0
		i_pts.append(Vector2(cos(a) * r, sin(a) * r * 0.85))
	inner_core.polygon = i_pts
	blast.add_child(inner_core)

	blast.scale = Vector2(0.25, 0.25)
	var b_tw := blast.create_tween()
	b_tw.tween_property(blast, "scale", Vector2(1.25, 1.25), 0.10).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	b_tw.parallel().tween_property(inner_core, "modulate:a", 0.0, 0.16)
	b_tw.tween_property(blast, "scale", Vector2(1.55, 1.55), 0.18)
	b_tw.parallel().tween_property(outer_fire, "color", Color(0.22, 0.20, 0.18, 0.0), 0.18)
	b_tw.tween_callback(blast.queue_free)

	# 3. Уламки, грудки землі та вогняні іскри врізнобіч у межах плитки
	for i in range(14):
		var frag := Polygon2D.new()
		var is_fire := (i % 2 == 0)
		frag.color = Color(1.0, 0.68, 0.18, 0.95) if is_fire else Color(0.28, 0.21, 0.14, 0.92)
		var r := randf_range(2.8, 5.6)
		frag.polygon = PackedVector2Array([
			Vector2(-r, -r * 0.6),
			Vector2(r * 0.8, -r * 0.4),
			Vector2(r, r * 0.7),
			Vector2(-r * 0.6, r),
		])
		frag.global_position = target_pos + Vector2(randf_range(-10.0, 10.0), randf_range(-8.0, 8.0))
		frag.rotation = randf_range(0.0, TAU)
		frag.z_index = 6
		parent_node.add_child(frag)

		var ang := randf_range(-PI * 0.92, -PI * 0.08)
		var dist := randf_range(28.0, 68.0)
		var peak := frag.global_position + Vector2(cos(ang) * dist, sin(ang) * dist)
		var land := peak + Vector2(cos(ang) * 14.0, randf_range(20.0, 38.0))
		var dur := randf_range(0.22, 0.36)

		var ftw := frag.create_tween()
		ftw.tween_property(frag, "global_position", peak, dur * 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ftw.parallel().tween_property(frag, "rotation", frag.rotation + randf_range(-4.0, 4.0), dur)
		ftw.tween_property(frag, "global_position", land, dur * 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ftw.parallel().tween_property(frag, "modulate:a", 0.0, dur * 0.45)
		ftw.tween_callback(frag.queue_free)


func _exit_tree() -> void:
	if _warning_marker and is_instance_valid(_warning_marker):
		_warning_marker.queue_free()
		_warning_marker = null
