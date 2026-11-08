class_name Grenade
extends Node2D

const SHEET_TEX := preload("res://assets/grenade_explosion_sheet.png")
const HFRAMES := 12
const VFRAMES := 2
const TOTAL_EXPLOSION_FRAMES := 23 # Кадри 1..23 у листі 12x2

var _start_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _damage := 140.0
var _radius := 265.0
var _flight_duration := 0.54
var _arc_height := 148.0

var _elapsed := 0.0
var _exploded := false
var _explosion_elapsed := 0.0
var _explosion_fps := 28.0
var _trail_timer := 0.0

var _sprite: Sprite2D
var _shadow: Polygon2D


func setup(from_pos: Vector2, to_pos: Vector2, damage: float = 140.0, radius: float = 265.0) -> void:
	_start_pos = from_pos
	_target_pos = to_pos
	_damage = damage
	_radius = radius
	global_position = from_pos


func _ready() -> void:
	# Тінь на землі, що біжить під гранатою вздовж лінії кидка
	_shadow = Polygon2D.new()
	_shadow.top_level = true
	_shadow.z_index = -1
	_shadow.color = Color(0.0, 0.0, 0.0, 0.35)
	_shadow.polygon = PackedVector2Array([
		Vector2(-10.0, 0.0),
		Vector2(-6.0, -3.5),
		Vector2(6.0, -3.5),
		Vector2(10.0, 0.0),
		Vector2(6.0, 3.5),
		Vector2(-6.0, 3.5),
	])
	_shadow.global_position = Vector2(_start_pos.x, _target_pos.y + 36.0)
	add_child(_shadow)

	_sprite = Sprite2D.new()
	_sprite.texture = SHEET_TEX
	_sprite.hframes = HFRAMES
	_sprite.vframes = VFRAMES
	_sprite.frame = 0
	_sprite.scale = Vector2(0.78, 0.78)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	if not _exploded:
		_process_flight(delta)
	else:
		_process_explosion(delta)


func _process_flight(delta: float) -> void:
	_elapsed += delta
	var t := clampf(_elapsed / maxf(_flight_duration, 0.1), 0.0, 1.0)

	# Висока параболічна дуга польоту гранати (як у Рядку 0 кадри 9..11 та Рядку 1 кадр 0 референсу)
	var prev_pos := global_position
	var ground_pos := _start_pos.lerp(_target_pos, t)
	var arc_offset := -4.0 * _arc_height * t * (1.0 - t)
	var curr_pos := ground_pos + Vector2(0.0, arc_offset)
	global_position = curr_pos

	var vel := curr_pos - prev_pos
	if vel.length_squared() > 0.001:
		_sprite.rotation = atan2(vel.y, vel.x)

	if _shadow:
		var ground_y := lerpf(_start_pos.y + 36.0, _target_pos.y + 38.0, t)
		_shadow.global_position = Vector2(ground_pos.x, ground_y)
		var s := lerpf(1.0, 0.55, 4.0 * t * (1.0 - t))
		_shadow.scale = Vector2(s, s)

	_trail_timer -= delta
	if _trail_timer <= 0.0 and t < 0.94:
		_trail_timer = 0.045
		_spawn_flight_smoke_puff(curr_pos)

	if t >= 1.0:
		_trigger_explosion()


func _trigger_explosion() -> void:
	_exploded = true
	_explosion_elapsed = 0.0

	if _shadow:
		_shadow.visible = false

	# Встановлюємо позицію вибуху на рівні землі в точці приземлення гранати
	var impact_ground_pos := Vector2(_target_pos.x, _target_pos.y + 34.0)
	global_position = impact_ground_pos
	z_index = 12

	# У клітинці 220x220 епіцентр вибуху на землі знаходиться на (110, 178), тобто offset.y = -68
	_sprite.rotation = 0.0
	_sprite.offset = Vector2(0.0, -68.0)
	_sprite.scale = Vector2(1.45, 1.45)
	_sprite.frame = 1

	_spawn_scorch_mark(impact_ground_pos)
	_apply_explosion_damage(impact_ground_pos)


func _process_explosion(delta: float) -> void:
	_explosion_elapsed += delta
	var frame_idx := 1 + int(_explosion_elapsed * _explosion_fps)
	if frame_idx > TOTAL_EXPLOSION_FRAMES:
		queue_free()
		return

	_sprite.frame = clampi(frame_idx, 1, TOTAL_EXPLOSION_FRAMES)
	# Плавне розсіювання димової шапки на останніх кадрах Рядка 2
	if frame_idx >= 20:
		var fade_t := float(frame_idx - 20) / 4.0
		_sprite.modulate.a = clampf(1.0 - fade_t * 0.65, 0.2, 1.0)


func _apply_explosion_damage(impact_pos: Vector2) -> void:
	if not is_inside_tree():
		return
	var enemies := get_tree().get_nodes_in_group("enemies")
	for node in enemies:
		var enemy := node as Node2D
		if enemy == null or not is_instance_valid(enemy):
			continue
		# Рахуємо відстань до ніг/корпусу ворога з урахуванням еліптичної перспективи поля бою
		var diff := (enemy.global_position + Vector2(0.0, 20.0)) - impact_pos
		var weighted_dist := Vector2(diff.x, diff.y * 1.15).length()
		if weighted_dist <= _radius and enemy.has_method("take_damage"):
			var falloff := 1.0
			if weighted_dist > _radius * 0.75:
				falloff = lerpf(1.0, 0.65, (weighted_dist - _radius * 0.75) / (_radius * 0.25))
			enemy.take_damage(_damage * falloff)


func _spawn_flight_smoke_puff(pos: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	var puff := Polygon2D.new()
	puff.color = Color(0.75, 0.74, 0.70, 0.42)
	var r := randf_range(2.2, 3.6)
	puff.polygon = PackedVector2Array([
		Vector2(-r, -r * 0.6),
		Vector2(r * 0.7, -r),
		Vector2(r, r * 0.6),
		Vector2(-r * 0.7, r),
	])
	puff.global_position = pos
	parent_node.add_child(puff)

	var t := puff.create_tween().set_parallel(true)
	t.tween_property(puff, "scale", Vector2(1.8, 1.8), 0.22)
	t.tween_property(puff, "modulate:a", 0.0, 0.22)
	t.chain().tween_callback(puff.queue_free)


func _spawn_scorch_mark(impact_pos: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var crater := Polygon2D.new()
	crater.color = Color(0.12, 0.10, 0.08, 0.55)
	crater.z_index = -2
	var pts := PackedVector2Array()
	for i in range(14):
		var ang := float(i) * TAU / 14.0
		var rx := 62.0 + sin(float(i) * 2.7) * 6.0
		var ry := 19.0 + cos(float(i) * 3.3) * 3.0
		pts.append(Vector2(cos(ang) * rx, sin(ang) * ry))
	crater.polygon = pts
	crater.global_position = impact_pos
	crater.scale = Vector2(0.3, 0.3)
	parent_node.add_child(crater)

	var ct := crater.create_tween()
	ct.tween_property(crater, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ct.tween_interval(4.0)
	ct.tween_property(crater, "modulate:a", 0.0, 1.2)
	ct.tween_callback(crater.queue_free)
