class_name Projectile
extends Node2D

const TEX_YELLOW := preload("res://assets/bullet_yellow.png")
const TEX_BLUE := preload("res://assets/bullet_blue.png")
const TEX_RED := preload("res://assets/bullet_red.png")

enum BulletType {
	PLAYER_YELLOW,
	ENEMY_BLUE,
	SNIPER_RED,
}

var bullet_type: BulletType = BulletType.PLAYER_YELLOW
var direction := Vector2.RIGHT
var speed := 1350.0
var damage := 10.0
var max_distance := 1600.0
var target_point := Vector2.ZERO
var has_ground_stop := false

var _traveled := 0.0
var _sprite: Sprite2D = null


func setup(
	p_type: BulletType,
	start_pos: Vector2,
	p_target_pos: Vector2,
	p_damage: float,
	p_speed: float = -1.0,
	stop_at_target: bool = false
) -> void:
	bullet_type = p_type
	global_position = start_pos
	target_point = p_target_pos
	damage = p_damage
	has_ground_stop = stop_at_target

	var diff := p_target_pos - start_pos
	var dist := diff.length()
	direction = (diff / dist) if dist > 0.001 else Vector2.RIGHT
	rotation = direction.angle()

	if has_ground_stop and dist > 20.0:
		max_distance = dist
	else:
		max_distance = 1700.0

	if p_speed > 0.0:
		speed = p_speed
	else:
		match bullet_type:
			BulletType.PLAYER_YELLOW:
				speed = 1380.0
			BulletType.ENEMY_BLUE:
				speed = 540.0
			BulletType.SNIPER_RED:
				speed = 1650.0


func _ready() -> void:
	z_index = 4
	_sprite = Sprite2D.new()

	match bullet_type:
		BulletType.PLAYER_YELLOW:
			_sprite.texture = TEX_YELLOW
			_sprite.scale = Vector2(0.42, 0.38)
			_sprite.modulate = Color(1.15, 1.12, 1.05, 1.0)
		BulletType.ENEMY_BLUE:
			_sprite.texture = TEX_BLUE
			_sprite.scale = Vector2(0.42, 0.40)
			_sprite.modulate = Color(1.12, 1.15, 1.20, 1.0)
		BulletType.SNIPER_RED:
			_sprite.texture = TEX_RED
			_sprite.scale = Vector2(0.52, 0.44)
			_sprite.modulate = Color(1.22, 1.08, 1.08, 1.0)

	# Зміщуємо центр спрайта трохи назад, щоб передній носик кулі відповідав точці global_position
	_sprite.offset = Vector2(-28.0, 0.0)
	add_child(_sprite)


func _physics_process(delta: float) -> void:
	var step_dist := speed * delta
	var prev_pos := global_position
	var next_pos := prev_pos + direction * step_dist

	if bullet_type == BulletType.PLAYER_YELLOW:
		if _check_player_bullet_hit(prev_pos, next_pos):
			return
	else:
		if _check_enemy_bullet_hit(prev_pos, next_pos):
			return

	global_position = next_pos
	_traveled += step_dist

	if _traveled >= max_distance:
		if has_ground_stop:
			global_position = target_point
			_spawn_impact_sparks(target_point, false)
		queue_free()
		return

	if global_position.x < -120.0 or global_position.x > 1450.0 or global_position.y < -120.0 or global_position.y > 880.0:
		queue_free()


func _check_player_bullet_hit(from_pos: Vector2, to_pos: Vector2) -> bool:
	var space_state := get_world_2d().direct_space_state

	# 1. Промінь вздовж відрізка польоту за поточний кадр (щоб швидка куля ніколи не пролітала крізь ворога)
	var ray_query := PhysicsRayQueryParameters2D.create(from_pos, to_pos)
	ray_query.collide_with_bodies = true
	ray_query.collision_mask = 1
	var ray_hit := space_state.intersect_ray(ray_query)
	if ray_hit:
		var col: Object = ray_hit.get("collider")
		if col and col.has_method("take_damage"):
			var hit_pos: Vector2 = ray_hit.get("position", to_pos)
			col.take_damage(damage)
			_spawn_impact_sparks(hit_pos, true)
			queue_free()
			return true

	# 2. Якщо куля долетіла до точки прицілювання — перевіряємо точкове влучання під перехрестям
	var next_traveled := _traveled + from_pos.distance_to(to_pos)
	if has_ground_stop and next_traveled >= max_distance:
		var point_query := PhysicsPointQueryParameters2D.new()
		point_query.position = target_point
		point_query.collide_with_bodies = true
		point_query.collision_mask = 1
		var point_hits := space_state.intersect_point(point_query, 4)
		for hit_info in point_hits:
			var col: Object = hit_info.get("collider")
			if col and col.has_method("take_damage"):
				col.take_damage(damage)
				_spawn_impact_sparks(target_point, true)
				queue_free()
				return true

	return false


func _check_enemy_bullet_hit(from_pos: Vector2, to_pos: Vector2) -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player != null and not player.get("is_dead"):
		var player_center := player.global_position + Vector2(0.0, -8.0)
		var closest := Geometry2D.get_closest_point_to_segment(player_center, from_pos, to_pos)
		var dx := absf(closest.x - player_center.x)
		var dy := absf(closest.y - player_center.y)

		if dx <= 24.0 and dy <= 38.0:
			var in_cover := bool(player.get("is_in_cover"))
			var rolling := bool(player.get("is_rolling"))
			if not in_cover and not rolling:
				if player.has_method("take_damage"):
					player.take_damage(damage)
				_spawn_impact_sparks(closest, true)
				queue_free()
				return true
			elif in_cover:
				# Якщо гравець схований в окопі — куля вдаряється у бруствер окопу без шкоди для героя!
				var parapet_pos := Vector2(player.global_position.x + 18.0, closest.y)
				_spawn_impact_sparks(parapet_pos, false)
				queue_free()
				return true

	return false


func _spawn_impact_sparks(impact_pos: Vector2, hit_character: bool) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var spark_color := Color(1.0, 0.88, 0.38, 0.95)
	match bullet_type:
		BulletType.PLAYER_YELLOW:
			spark_color = Color(1.0, 0.34, 0.22, 0.95) if hit_character else Color(1.0, 0.88, 0.38, 0.92)
		BulletType.ENEMY_BLUE:
			spark_color = Color(0.30, 0.88, 1.0, 0.95)
		BulletType.SNIPER_RED:
			spark_color = Color(1.0, 0.22, 0.22, 0.98)

	var count := 5 if bullet_type == BulletType.SNIPER_RED else 4
	for i in range(count):
		var spark := Polygon2D.new()
		spark.color = spark_color
		spark.polygon = PackedVector2Array([
			Vector2(-4.5, -1.6),
			Vector2(4.5, 0.0),
			Vector2(-4.5, 1.6),
		])
		spark.global_position = impact_pos
		var base_angle := (-direction).angle()
		var angle := base_angle + randf_range(-1.1, 1.1)
		spark.rotation = angle
		parent_node.add_child(spark)

		var target := impact_pos + Vector2.RIGHT.rotated(angle) * randf_range(14.0, 30.0)
		var tween := spark.create_tween()
		tween.set_parallel(true)
		tween.tween_property(spark, "global_position", target, 0.13).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(spark, "scale", Vector2(0.2, 0.2), 0.13)
		tween.tween_property(spark, "modulate:a", 0.0, 0.13)
		tween.chain().tween_callback(spark.queue_free)
