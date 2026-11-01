class_name Enemy
extends CharacterBody2D

signal died

enum State {
	ADVANCE,
	ATTACK,
	DEAD,
}

@export var health := 30.0
@export var speed := 95.0
@export var stop_distance := 340.0
@export var attack_interval := 1.6
@export var attack_damage := 7.0
@export var is_stationary := false
@export var use_sniper_laser := false

var state: State = State.ADVANCE
var _stop_x := 525.0
var _attack_timer := 0.0
var _shot_visual_timer := 0.0
var _base_color := Color.WHITE
var _has_locked_aim := false
var _locked_aim_pos := Vector2.ZERO
var _target_marker: Polygon2D = null

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_rect: ColorRect = $ColorRect
@onready var shot_line: Line2D = get_node_or_null("ShotLine")


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 0
	_create_target_marker()

	if body_rect:
		_base_color = body_rect.color

	var trench_x := _get_trench_x()
	_stop_x = trench_x + stop_distance + randf_range(-55.0, 75.0)

	if is_stationary:
		state = State.ATTACK
		_attack_timer = attack_interval * randf_range(0.6, 1.0)
	else:
		state = State.ADVANCE
		_attack_timer = attack_interval * 0.5


func _physics_process(delta: float) -> void:
	_update_shot_visual(delta)

	match state:
		State.ADVANCE:
			_process_advance()
		State.ATTACK:
			_process_attack(delta)
		State.DEAD:
			velocity = Vector2.ZERO


func _process_advance() -> void:
	var trench_x := _get_trench_x()
	var target_x := maxf(_stop_x, trench_x + stop_distance - 60.0)
	if global_position.x <= target_x:
		velocity = Vector2.ZERO
		state = State.ATTACK
		return

	velocity = Vector2.LEFT * speed
	move_and_slide()


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_timer -= delta

	var muzzle_pos := global_position + Vector2(-30.0, -2.0)
	var lock_window := 0.85 if use_sniper_laser else 0.38

	if _attack_timer <= lock_window and _attack_timer > 0.0 and not _has_locked_aim:
		var p := _find_player()
		if p:
			_locked_aim_pos = p.global_position + Vector2(0.0, -8.0)
			_has_locked_aim = true
			if _target_marker:
				_target_marker.global_position = Vector2(_locked_aim_pos.x, _locked_aim_pos.y + 30.0)
				_target_marker.visible = true

	if use_sniper_laser and shot_line and _shot_visual_timer <= 0.0:
		if _attack_timer <= 0.85 and _attack_timer > 0.0:
			var aim_point := _locked_aim_pos
			if not _has_locked_aim:
				var player := _find_player()
				if player:
					aim_point = player.global_position + Vector2(0.0, -8.0)
			if aim_point != Vector2.ZERO:
				shot_line.width = 1.5
				shot_line.default_color = Color(1.0, 0.15, 0.15, 0.7)
				shot_line.clear_points()
				shot_line.add_point(muzzle_pos)
				shot_line.add_point(aim_point)
				shot_line.visible = true

	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		if _target_marker:
			_target_marker.visible = false
		_perform_attack(muzzle_pos)
		_has_locked_aim = false


func _perform_attack(muzzle_pos: Vector2) -> void:
	var player := _find_player()
	if player == null:
		return

	var target_pos := _locked_aim_pos if _has_locked_aim else (player.global_position + Vector2(0.0, -8.0))
	var dodged_by_roll := absf(player.global_position.y - target_pos.y) > 42.0

	if not dodged_by_roll and player.has_method("take_damage"):
		player.take_damage(attack_damage)

	if shot_line:
		_shot_visual_timer = 0.08
		shot_line.width = 3.0 if use_sniper_laser else 2.0
		shot_line.default_color = Color(1.0, 0.88, 0.35, 0.92)
		shot_line.clear_points()
		shot_line.add_point(muzzle_pos)
		shot_line.add_point(target_pos + Vector2(randf_range(-8.0, 8.0), randf_range(-10.0, 10.0)))
		shot_line.visible = true


func take_damage(amount: float) -> bool:
	if state == State.DEAD or amount <= 0.0:
		return false

	health -= amount
	if health <= 0.0:
		_enter_dead_state()
		return true

	_flash_hit()
	return false


func _enter_dead_state() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	collision_layer = 0
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if shot_line:
		shot_line.visible = false
	if _target_marker:
		_target_marker.visible = false

	died.emit()

	if is_inside_tree():
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate", Color(0.25, 0.05, 0.05, 0.0), 0.22)
		tween.tween_property(self, "rotation", 1.25, 0.22)
		tween.chain().tween_callback(queue_free)
	else:
		queue_free()


func _flash_hit() -> void:
	if body_rect == null or not is_inside_tree():
		return
	body_rect.color = Color(1.0, 0.9, 0.75, 1.0)
	var tween := create_tween()
	tween.tween_property(body_rect, "color", _base_color, 0.09)


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
	return 185.0


func _create_target_marker() -> void:
	# Червоний овальний маркер прицілу на землі в окопі (як у The Peacekeeper)
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
