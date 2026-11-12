class_name AxeProjectile
extends Node2D

const THROWN_AXE_TEX := preload("res://assets/thrown_axe.png")
const IMPACT_SOUND := preload("res://assets/grenade_explosion.wav")
const TILE_HALF_HEIGHT := 46.0
const TILE_HALF_WIDTH := 38.0

enum Phase { FLIGHT, STUCK }

var _phase: Phase = Phase.FLIGHT
var _start_pos := Vector2.ZERO
var _target_pos := Vector2.ZERO
var _flight_duration := 0.85
var _damage := 30.0
var _arc_height := 115.0

var _elapsed := 0.0
var _stuck_timer := 0.0
var _stuck_duration := 0.32
var _trail_timer := 0.0
var _trail_dots: Array[Dictionary] = []

var _sprite: Sprite2D = null
var _warning_marker: Node2D = null


func setup(
	from_pos: Vector2,
	to_pos: Vector2,
	p_damage: float = 30.0,
	p_flight_duration: float = 0.85
) -> void:
	_start_pos = from_pos
	_target_pos = to_pos
	_damage = p_damage
	_flight_duration = maxf(p_flight_duration, 0.25)
	_arc_height = clampf(from_pos.distance_to(to_pos) * 0.28, 75.0, 145.0)
	global_position = from_pos
	z_index = 12


func _ready() -> void:
	_sprite = Sprite2D.new()
	_sprite.texture = THROWN_AXE_TEX
	_sprite.scale = Vector2(0.56, 0.56)
	add_child(_sprite)
	_spawn_warning_marker()


func _exit_tree() -> void:
	if is_instance_valid(_warning_marker):
		_warning_marker.queue_free()
		_warning_marker = null


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
	global_position = ground_pos + Vector2(0.0, -height)
	if _sprite:
		_sprite.rotation -= delta * 18.5

	if is_instance_valid(_warning_marker):
		_warning_marker.set("pulse_t", prog)
		_warning_marker.queue_redraw()

	_trail_timer -= delta
	if _trail_timer <= 0.0:
		_trail_timer = 0.032
		_trail_dots.append({
			"pos": global_position + Vector2(randf_range(-4.0, 4.0), randf_range(-4.0, 4.0)),
			"age": 0.0,
			"life": 0.18,
			"size": randf_range(3.0, 5.5)
		})

	_update_dots(delta)

	if prog >= 1.0:
		_on_landed()


func _process_stuck(delta: float) -> void:
	_stuck_timer += delta
	_update_dots(delta)
	var fade := clampf(1.0 - (_stuck_timer / _stuck_duration), 0.0, 1.0)
	if _sprite:
		_sprite.modulate.a = fade
	if _stuck_timer >= _stuck_duration:
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
	global_position = _target_pos + Vector2(0.0, 4.0)
	z_index = 5
	if _sprite:
		_sprite.rotation = -0.62

	if is_instance_valid(_warning_marker):
		_warning_marker.queue_free()
		_warning_marker = null

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
	sfx.volume_db = -12.0 if hit_player else -15.5
	sfx.pitch_scale = randf_range(1.75, 1.98) if hit_player else randf_range(2.05, 2.35)
	var parent_node := get_parent()
	if parent_node != null:
		parent_node.add_child(sfx)
		sfx.finished.connect(sfx.queue_free)
		sfx.play()

	_spawn_impact_burst(hit_player)


func _spawn_impact_burst(hit_player: bool) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	for i in range(6):
		var chip := Polygon2D.new()
		chip.color = Color(0.85, 0.14, 0.14, 0.9) if hit_player else Color(0.62, 0.54, 0.42, 0.85)
		chip.polygon = PackedVector2Array([Vector2(-3, -2), Vector2(3, -1), Vector2(2, 3), Vector2(-2, 2)])
		chip.global_position = _target_pos
		chip.z_index = 10
		parent_node.add_child(chip)
		var end_pos := _target_pos + Vector2(randf_range(-24.0, 24.0), randf_range(-28.0, 8.0))
		var tw := chip.create_tween()
		tw.set_parallel(true)
		tw.tween_property(chip, "global_position", end_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(chip, "modulate:a", 0.0, 0.22)
		tw.chain().tween_callback(chip.queue_free)


func _spawn_warning_marker() -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return
	_warning_marker = _AxeTileWarning.new()
	_warning_marker.global_position = _target_pos
	_warning_marker.z_index = 4
	parent_node.add_child(_warning_marker)


func _draw() -> void:
	for d in _trail_dots:
		var t := float(d["age"]) / maxf(float(d["life"]), 0.01)
		var local_p := to_local(d["pos"] as Vector2)
		draw_circle(local_p, float(d["size"]) * (1.0 - t * 0.5), Color(0.92, 0.86, 0.72, (1.0 - t) * 0.42))


class _AxeTileWarning extends Node2D:
	var pulse_t := 0.0

	func _draw() -> void:
		var pulse := 0.5 + 0.5 * sin(pulse_t * TAU * 2.5)
		var fill_alpha := lerpf(0.10, 0.28, pulse_t) + pulse * 0.06
		var edge_alpha := lerpf(0.45, 0.90, pulse_t)
		var rect := Rect2(-TILE_HALF_WIDTH, -TILE_HALF_HEIGHT, TILE_HALF_WIDTH * 2.0, TILE_HALF_HEIGHT * 2.0)
		draw_rect(rect, Color(0.95, 0.55, 0.12, fill_alpha), true)
		draw_rect(rect, Color(1.0, 0.72, 0.20, edge_alpha), false, 2.2)
