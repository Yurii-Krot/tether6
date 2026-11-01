class_name WaveManager
extends Node

signal wave_started(wave_number: int)
signal wave_cleared
signal all_waves_cleared

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var sniper_scene: PackedScene = preload("res://scenes/sniper.tscn")
@export var spawn_interval := 3.2
@export var delay_between_waves := 3.5
@export var spawn_x_min := 150.0
@export var spawn_x_max := 1130.0
@export var infantry_spawn_y := 45.0
@export var sniper_spawn_y := 70.0
@export var auto_start := true

@export var waves: Array[Dictionary] = [
	{"infantry": 5, "snipers": 0},
	{"infantry": 8, "snipers": 0},
	{"infantry": 8, "snipers": 1},
]

var current_wave_index := -1
var _spawn_queue: Array[String] = []
var _alive_enemies: Dictionary = {}
var _wave_in_progress := false

var _spawn_timer: Timer
var _wave_delay_timer: Timer


func _ready() -> void:
	_spawn_timer = Timer.new()
	_spawn_timer.name = "SpawnTimer"
	_spawn_timer.wait_time = spawn_interval
	_spawn_timer.one_shot = false
	_spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(_spawn_timer)

	_wave_delay_timer = Timer.new()
	_wave_delay_timer.name = "WaveDelayTimer"
	_wave_delay_timer.wait_time = delay_between_waves
	_wave_delay_timer.one_shot = true
	_wave_delay_timer.timeout.connect(_start_next_wave)
	add_child(_wave_delay_timer)

	if auto_start:
		call_deferred("start_waves")


func start_waves() -> void:
	current_wave_index = -1
	_alive_enemies.clear()
	_spawn_queue.clear()
	_wave_delay_timer.start(1.0)


func get_current_wave_number() -> int:
	return current_wave_index + 1


func get_alive_enemy_count() -> int:
	return _alive_enemies.size()


func _start_next_wave() -> void:
	current_wave_index += 1
	if current_wave_index >= waves.size():
		return

	_wave_in_progress = true
	_spawn_queue = _build_wave_queue(waves[current_wave_index])
	wave_started.emit(current_wave_index + 1)

	# Спавнимо першого ворога одразу на старті хвилі, решту — за таймером
	_spawn_next_from_queue()
	if not _spawn_queue.is_empty():
		_spawn_timer.wait_time = spawn_interval
		_spawn_timer.start()


func _build_wave_queue(wave_data: Dictionary) -> Array[String]:
	var infantry_count := int(wave_data.get("infantry", 0))
	var sniper_count := int(wave_data.get("snipers", 0))
	var queue: Array[String] = []

	for i in range(infantry_count):
		queue.append("infantry")

	# Вставляємо снайпера після перших 2 піхотинців (або на початок), щоб тримав гравця під вогнем протягом хвилі
	for s in range(sniper_count):
		var insert_idx := mini(2 + s * 3, queue.size())
		queue.insert(insert_idx, "sniper")

	return queue


func _on_spawn_timer_timeout() -> void:
	_spawn_next_from_queue()
	if _spawn_queue.is_empty():
		_spawn_timer.stop()
		_check_wave_cleared()


func _spawn_next_from_queue() -> void:
	if _spawn_queue.is_empty():
		return

	var unit_type: String = _spawn_queue.pop_front()
	var packed: PackedScene = sniper_scene if unit_type == "sniper" else enemy_scene
	if packed == null:
		return

	var unit := packed.instantiate() as Node2D
	if unit == null:
		return

	if unit_type == "sniper":
		unit.global_position = Vector2(randf_range(spawn_x_min + 70.0, spawn_x_max - 70.0), sniper_spawn_y)
	else:
		unit.global_position = Vector2(randf_range(spawn_x_min, spawn_x_max), infantry_spawn_y)

	var id := unit.get_instance_id()
	_alive_enemies[id] = true

	if unit.has_signal("died"):
		unit.connect("died", _on_enemy_eliminated.bind(id), CONNECT_ONE_SHOT)
	unit.tree_exited.connect(_on_enemy_eliminated.bind(id), CONNECT_ONE_SHOT)

	var container := get_parent() if get_parent() != null else get_tree().current_scene
	container.add_child(unit)


func _on_enemy_eliminated(instance_id: int) -> void:
	if not _alive_enemies.has(instance_id):
		return
	_alive_enemies.erase(instance_id)
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if not _wave_in_progress:
		return
	if not _spawn_queue.is_empty() or not _alive_enemies.is_empty():
		return

	_wave_in_progress = false
	_spawn_timer.stop()
	wave_cleared.emit()

	if current_wave_index + 1 < waves.size():
		_wave_delay_timer.wait_time = delay_between_waves
		_wave_delay_timer.start()
	else:
		all_waves_cleared.emit()
