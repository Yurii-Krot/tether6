extends CharacterBody2D

var health := 30.0
var speed := 80.0

func _physics_process(_delta: float) -> void:
	velocity = Vector2.DOWN * speed
	move_and_slide()

func take_damage(amount: float) -> bool:
	health -= amount
	if health <= 0.0:
		queue_free()
		return true
	return false
