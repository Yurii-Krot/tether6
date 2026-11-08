class_name GrenadierRocket
extends Node2D

## Постріл підствольного гранатомета/ракети нового ворога по одній конкретній клітинці окопу.

const ROCKET_SMOKE_SHEET := preload("res://assets/grenadier_rocket_sheet.png")
const EXPLOSION_SHEET := preload("res://assets/grenade_explosion_sheet.png")
const EXPLOSION_SOUND := preload("res://assets/grenade_explosion.wav")

const TILE_HALF_HEIGHT := 46.0
const TILE_HALF_WIDTH := 38.0

var start_pos := Vector2.ZERO
var target_pos := Vector2.ZERO
var speed := 1840.0
var damage := 25.0

var _direction := Vector2.LEFT
var _total_dist := 1.0
var _traveled := 0.0
var _anim_time := 0.0
var _smoke_timer := 0.0
var _sprite: Sprite2D = null
var _warning_marker: Node2D = null


func setup(
	from_pos: Vector2,
	to_tile_pos: Vector2,
	p_speed: float = 1840.0,
	p_damage: float = 25.0,
	existing_warning: Node2D = null
) -> void:
	start_pos = from_pos
	target_pos = to_tile_pos
	speed = p_speed
	damage = p_damage
	_warning_marker = existing_warning
	global_position = from_pos

	var diff := target_pos - start_pos
	_total_dist = maxf(diff.length(), 1.0)
	_direction = diff / _total_dist
	rotation = _direction.angle()


func _ready() -> void:
	z_index = 6

	_sprite = Sprite2D.new()
	_sprite.texture = ROCKET_SMOKE_SHEET
	_sprite.hframes = 12
	_sprite.vframes = 2
	_sprite.frame = 0
	_sprite.scale = Vector2(1.35, 1.35)
	add_child(_sprite)

	if _warning_marker == null or not is_instance_valid(_warning_marker):
		_create_tile_warning()


func _physics_process(delta: float) -> void:
	_anim_time += delta

	# Анімація полум'я реактивної гранати в польоті (кадри 0..3 верхнього рядка)
	if _sprite:
		_sprite.frame = int(_anim_time * 24.0) % 4

	if _warning_marker and is_instance_valid(_warning_marker):
		_warning_marker.queue_redraw()

	# Димовий шлейф із кадрів 0..11 нижнього рядка (індекси 12..23)
	_smoke_timer -= delta
	if _smoke_timer <= 0.0:
		_smoke_timer = 0.025
		_spawn_smoke_puff()

	var step := speed * delta
	_traveled += step
	if _traveled >= _total_dist:
		global_position = target_pos
		_detonate_on_tile()
		return

	var prog := clampf(_traveled / _total_dist, 0.0, 1.0)
	var base_pt := start_pos.lerp(target_pos, prog)
	var arc_offset := Vector2(0.0, -sin(prog * PI) * 26.0)
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
	_warning_marker.z_index = 3
	_warning_marker.draw.connect(_draw_tile_warning)
	parent_node.add_child(_warning_marker)


func _draw_tile_warning() -> void:
	if _warning_marker == null or not is_instance_valid(_warning_marker):
		return
	var pulse := 0.5 + 0.5 * sin(_anim_time * 42.0)
	var alpha := lerpf(0.32, 0.88, pulse)

	var rect := Rect2(
		-TILE_HALF_WIDTH,
		-TILE_HALF_HEIGHT + 4.0,
		TILE_HALF_WIDTH * 2.0,
		(TILE_HALF_HEIGHT - 4.0) * 2.0
	)
	_warning_marker.draw_rect(rect, Color(1.0, 0.16, 0.08, alpha * 0.45), true)
	_warning_marker.draw_rect(rect, Color(1.0, 0.35, 0.12, alpha), false, 2.5)
	_warning_marker.draw_arc(Vector2.ZERO, 16.0, 0.0, TAU, 24, Color(1.0, 0.90, 0.25, alpha), 2.2)
	_warning_marker.draw_line(Vector2(-14.0, 0.0), Vector2(14.0, 0.0), Color(1.0, 0.25, 0.12, alpha), 2.0)
	_warning_marker.draw_line(Vector2(0.0, -14.0), Vector2(0.0, 14.0), Color(1.0, 0.25, 0.12, alpha), 2.0)


func _spawn_smoke_puff() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var tail_pos := global_position - Vector2.RIGHT.rotated(rotation) * 24.0
	var puff := Sprite2D.new()
	puff.texture = ROCKET_SMOKE_SHEET
	puff.hframes = 12
	puff.vframes = 2
	puff.frame = 12
	puff.global_position = tail_pos + Vector2(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0))
	puff.scale = Vector2(1.15, 1.15)
	puff.z_index = 4
	parent_node.add_child(puff)

	# Програємо 12 кадрів диму (кадри 12..23) з плавним розчиненням
	var tw := puff.create_tween()
	tw.tween_method(
		func(f: float) -> void:
			if is_instance_valid(puff):
				puff.frame = clampi(int(f), 12, 23),
		12.0,
		23.9,
		0.34
	)
	tw.parallel().tween_property(puff, "modulate:a", 0.0, 0.34)
	tw.tween_callback(puff.queue_free)


func _detonate_on_tile() -> void:
	if _warning_marker and is_instance_valid(_warning_marker):
		_warning_marker.queue_free()
		_warning_marker = null

	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and not player.get("is_dead"):
		var dy := absf(player.global_position.y - target_pos.y)
		if dy <= TILE_HALF_HEIGHT:
			if player.has_method("take_damage"):
				player.take_damage(damage, true)

	_spawn_explosion_visual()
	queue_free()


func _spawn_explosion_visual() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var sfx := AudioStreamPlayer.new()
	sfx.stream = EXPLOSION_SOUND
	sfx.volume_db = -1.5
	parent_node.add_child(sfx)
	sfx.finished.connect(sfx.queue_free)
	sfx.play()

	var exp_sprite := Sprite2D.new()
	exp_sprite.texture = EXPLOSION_SHEET
	exp_sprite.hframes = 12
	exp_sprite.vframes = 2
	exp_sprite.frame = 1
	exp_sprite.offset = Vector2(0.0, -68.0)
	exp_sprite.scale = Vector2(0.95, 0.95)
	exp_sprite.global_position = target_pos + Vector2(0.0, 26.0)
	exp_sprite.z_index = 8
	parent_node.add_child(exp_sprite)

	var tw := exp_sprite.create_tween()
	tw.tween_method(
		func(f: float) -> void:
			if is_instance_valid(exp_sprite):
				exp_sprite.frame = clampi(int(f), 1, 23),
		1.0,
		23.9,
		0.55
	)
	tw.tween_callback(exp_sprite.queue_free)


func _exit_tree() -> void:
	if _warning_marker and is_instance_valid(_warning_marker):
		_warning_marker.queue_free()
		_warning_marker = null
