extends Node2D

@export var damage := 10.0
@export var fire_rate := 8.0
@export var magazine_size := 30

var ammo := 30
var cooldown := 0.0

func _process(delta: float) -> void:
	cooldown -= delta
	if Input.is_action_pressed("shoot") and cooldown <= 0.0 and ammo > 0:
		ammo -= 1
		cooldown = 1.0 / fire_rate
		shoot(get_global_mouse_position())
		print("Патрони: ", ammo)

func shoot(aim: Vector2) -> void:
	var dir := (aim - global_position).normalized()
	var query := PhysicsRayQueryParameters2D.create(global_position, global_position + dir * 2000.0)
	var hit := get_world_2d().direct_space_state.intersect_ray(query)
	if hit and hit.collider.has_method("take_damage"):
		hit.collider.take_damage(damage)
