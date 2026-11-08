class_name WaveManager
extends Node

signal wave_started(wave_number: int)
signal wave_cleared
signal all_waves_cleared
signal enemy_killed(unit_type: String, world_pos: Vector2, reward: int)

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var shotgunner_scene: PackedScene = preload("res://scenes/shotgunner.tscn")
@export var heavy_gunner_scene: PackedScene = preload("res://scenes/heavy_gunner.tscn")
@export var sniper_scene: PackedScene = preload("res://scenes/sniper.tscn")
@export var helicopter_scene: PackedScene = preload("res://scenes/helicopter.tscn")
@export var spawn_interval := 3.2
@export var delay_between_waves := 3.5
@export var infantry_spawn_x := 1295.0
@export var spawn_y_min := 405.0
@export var spawn_y_max := 625.0
@export var sniper_x_min := 820.0
@export var sniper_x_max := 1150.0
@export var sniper_y_min := 275.0
@export var sniper_y_max := 315.0
@export var auto_start := true

@export var waves: Array[Dictionary] = [
	{"infantry": 4, "shotgun": 2, "heavy": 1, "snipers": 0, "heli": 1, "heli_troops": 3},
	{"infantry": 6, "shotgun": 2, "heavy": 2, "snipers": 0, "heli": 1, "heli_troops": 4},
	{"infantry": 7, "shotgun": 3, "heavy": 2, "snipers": 1, "heli": 2, "heli_troops": 5},
]

var _current_heli_troops := 4
var _sniper_spawn_idx := 0

var current_wave_index := -1
var _spawn_queue: Array[String] = []
var _alive_enemies: Dictionary = {}
var _rewarded_enemies: Dictionary = {}
var _wave_in_progress := false

var _spawn_timer: Timer
var _wave_delay_timer: Timer


func _ready() -> void:
	var level_cfg := GameState.get_current_level_data()
	waves = [level_cfg]
	spawn_interval = float(level_cfg.get("spawn_interval", spawn_interval))

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
	_sniper_spawn_idx = 0
	_alive_enemies.clear()
	_rewarded_enemies.clear()
	_spawn_queue.clear()
	_wave_delay_timer.start(0.8)


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
	var shotgun_count := int(wave_data.get("shotgun", 0))
	var heavy_count := int(wave_data.get("heavy", 0))
	var sniper_count := int(wave_data.get("snipers", 0))
	var queue: Array[String] = []

	for i in range(infantry_count):
		queue.append("infantry")

	# Вставляємо бійців з дробовиками серед хвилі
	for sh in range(shotgun_count):
		var sh_idx := mini(1 + sh * 2, queue.size())
		queue.insert(sh_idx, "shotgun")

	# Вставляємо важких кулеметників серед хвилі піхоти
	for h in range(heavy_count):
		var h_idx := mini(2 + h * 3, queue.size())
		queue.insert(h_idx, "heavy")

	# Вставляємо снайперів рівномірно впродовж рівня, щоб тримали окоп під прицілом зверху справа
	for s in range(sniper_count):
		var insert_idx := mini(1 + s * 2, queue.size())
		queue.insert(insert_idx, "sniper")

	# Вертоліт з десантом прилітає зліва посеред хвилі
	_current_heli_troops = int(wave_data.get("heli_troops", 4))
	var heli_count := int(wave_data.get("heli", 0))
	for hc in range(heli_count):
		var heli_idx := mini(2 + hc * 5, queue.size())
		queue.insert(heli_idx, "heli")

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
	if unit_type == "heli":
		_spawn_helicopter()
		return

	var packed: PackedScene = enemy_scene
	if unit_type == "sniper":
		packed = sniper_scene
	elif unit_type == "heavy":
		packed = heavy_gunner_scene
	elif unit_type == "shotgun":
		packed = shotgunner_scene
	if packed == null:
		return

	var unit := packed.instantiate() as Node2D
	if unit == null:
		return

	if unit_type == "sniper":
		# Розподіляємо снайперів вздовж верхнього пагорба, щоб вони не накладалися один на одного
		var slot := _sniper_spawn_idx % 6
		_sniper_spawn_idx += 1
		var slot_x := lerpf(765.0, 1205.0, float(slot) / 5.0) + randf_range(-24.0, 24.0)
		var slot_y := lerpf(sniper_y_min, sniper_y_max, float((slot * 3) % 5) / 4.0) + randf_range(-6.0, 6.0)
		unit.global_position = Vector2(clampf(slot_x, 750.0, 1220.0), clampf(slot_y, 265.0, 326.0))
	elif unit_type == "heavy":
		# Важкий кулеметник виходить на лінію окопу (y: 435..615), щоб його пряма черга з 8 червоних куль летіла впоперек окопу
		unit.global_position = Vector2(
			infantry_spawn_x,
			randf_range(435.0, 615.0)
		)
	else:
		unit.global_position = Vector2(
			infantry_spawn_x,
			randf_range(spawn_y_min, spawn_y_max)
		)

	_register_unit(unit, unit_type)

	var container := get_parent() if get_parent() != null else get_tree().current_scene
	container.add_child(unit)


func _get_scene_for_type(unit_type: String) -> PackedScene:
	match unit_type:
		"sniper":
			return sniper_scene
		"heavy":
			return heavy_gunner_scene
		"shotgun":
			return shotgunner_scene
	return enemy_scene


func _register_unit(unit: Node2D, unit_type: String = "infantry") -> void:
	var id := unit.get_instance_id()
	_alive_enemies[id] = true
	if unit.has_signal("died"):
		unit.connect("died", _on_unit_died.bind(id, unit, unit_type), CONNECT_ONE_SHOT)
	unit.tree_exited.connect(_on_enemy_eliminated.bind(id), CONNECT_ONE_SHOT)


func _on_unit_died(instance_id: int, unit: Node2D, unit_type: String) -> void:
	if not _rewarded_enemies.has(instance_id):
		_rewarded_enemies[instance_id] = true
		var pos := unit.global_position if is_instance_valid(unit) else Vector2(640.0, 480.0)
		var reward := GameState.get_kill_reward(unit_type)
		enemy_killed.emit(unit_type, pos, reward)
	_on_enemy_eliminated(instance_id)


func _spawn_helicopter() -> void:
	if helicopter_scene == null:
		return
	var heli := helicopter_scene.instantiate() as Helicopter
	if heli == null:
		return

	# Різний десант: суміш піхоти, дробовиків та важких кулеметників
	var pool: Array[String] = ["infantry", "infantry", "shotgun", "shotgun", "heavy"]
	pool.shuffle()
	var troops: Array[String] = []
	for i in range(clampi(_current_heli_troops, 1, 8)):
		troops.append(pool[i % pool.size()])
	heli.setup(troops)
	heli.trooper_drop_requested.connect(_on_heli_trooper_drop.bind(heli))

	# Вертоліт рахується "живим", доки не висадить усіх і не полетить — щоб хвиля не завершилась передчасно
	var id := heli.get_instance_id()
	_alive_enemies[id] = true
	heli.tree_exited.connect(_on_enemy_eliminated.bind(id), CONNECT_ONE_SHOT)

	var container := get_parent() if get_parent() != null else get_tree().current_scene
	container.add_child(heli)


func _on_heli_trooper_drop(unit_type: String, from_pos: Vector2, land_pos: Vector2, heli: Node2D) -> void:
	var packed := _get_scene_for_type(unit_type)
	if packed == null:
		return
	var unit := packed.instantiate() as Node2D
	if unit == null:
		return
	unit.global_position = from_pos
	_register_unit(unit, unit_type)
	var container := get_parent() if get_parent() != null else get_tree().current_scene
	container.add_child(unit)
	if unit.has_method("start_rappel"):
		unit.start_rappel(heli, from_pos, land_pos)
	else:
		unit.global_position = land_pos


func _on_enemy_eliminated(instance_id: int) -> void:
	if not _alive_enemies.has(instance_id):
		return
	_alive_enemies.erase(instance_id)
	_check_wave_cleared()


func _check_wave_cleared() -> void:
	if not _wave_in_progress:
		return
	if not is_inside_tree() or _spawn_timer == null or not _spawn_timer.is_inside_tree():
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
