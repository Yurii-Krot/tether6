class_name Enemy
extends CharacterBody2D

signal died

enum State {
	ADVANCE,
	ATTACK,
	DEAD,
}

@export var health := 30.0
@export var speed := 75.0
@export var stop_distance := 200.0
@export var attack_interval := 1.6
@export var attack_damage := 7.0
@export var is_stationary := false
@export var use_sniper_laser := false

var state: State = State.ADVANCE
var _stop_y := 450.0
var _attack_timer := 0.0
var _shot_visual_timer := 0.0
var _base_color := Color.WHITE

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var body_rect: ColorRect = $ColorRect
@onready var shot_line: Line2D = get_node_or_null("ShotLine")


func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 1
	collision_mask = 0

	if body_rect:
		_base_color = body_rect.color

	var trench_y := _get_trench_y()
	_stop_y = trench_y - stop_distance + randf_range(-20.0, 20.0)

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
	var trench_y := _get_trench_y()
	var target_y := minf(_stop_y, trench_y - stop_distance + 20.0)
	if global_position.y >= target_y:
		velocity = Vector2.ZERO
		state = State.ATTACK
		return

	velocity = Vector2.DOWN * speed
	move_and_slide()


func _process_attack(delta: float) -> void:
	velocity = Vector2.ZERO
	_attack_timer -= delta

	if use_sniper_laser and shot_line and _shot_visual_timer <= 0.0:
		if _attack_timer <= 0.85 and _attack_timer > 0.0:
			var player := _find_player()
			if player:
				shot_line.width = 1.5
				shot_line.default_color = Color(1.0, 0.15, 0.15, 0.65)
				shot_line.clear_points()
				shot_line.add_point(global_position)
				shot_line.add_point(player.global_position)
				shot_line.visible = true

	if _attack_timer <= 0.0:
		_attack_timer = attack_interval
		_perform_attack()


func _perform_attack() -> void:
	var player := _find_player()
	if player == null:
		return

	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

	if shot_line:
		_shot_visual_timer = 0.08
		shot_line.width = 3.0 if use_sniper_laser else 2.0
		shot_line.default_color = Color(1.0, 0.85, 0.3, 0.9)
		shot_line.clear_points()
		shot_line.add_point(global_position + Vector2(0.0, 16.0))
		shot_line.add_point(player.global_position + Vector2(randf_range(-10.0, 10.0), randf_range(-8.0, 8.0)))
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

	died.emit()

	if is_inside_tree():
		var tween := create_tween()
		tween.set_parallel(true)
		tween.tween_property(self, "modulate", Color(0.25, 0.05, 0.05, 0.0), 0.2)
		tween.tween_property(self, "scale", Vector2(0.85, 0.55), 0.2)
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


func _get_trench_y() -> float:
	var p := _find_player()
	if p != null:
		return p.global_position.y
	return 650.0
