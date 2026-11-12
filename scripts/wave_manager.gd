class_name WaveManager
extends Node

const GAME_STATE := preload("res://scripts/game_state.gd")

signal wave_started(wave_number: int)
signal subwave_changed(subwave_number: int, total_subwaves: int)
signal formation_spawned(unit_type: String, is_v_shape: bool)
signal boss_fight_started
signal wave_cleared
signal all_waves_cleared
signal enemy_killed(unit_type: String, world_pos: Vector2, reward: int)

@export var enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")
@export var shotgunner_scene: PackedScene = preload("res://scenes/shotgunner.tscn")
@export var heavy_gunner_scene: PackedScene = preload("res://scenes/heavy_gunner.tscn")
@export var grenadier_scene: PackedScene = preload("res://scenes/grenadier.tscn")
@export var axe_thrower_scene: PackedScene = preload("res://scenes/axe_thrower.tscn")
@export var boss_grenadier_scene: PackedScene = preload("res://scenes/boss_grenadier.tscn")
@export var sniper_scene: PackedScene = preload("res://scenes/sniper.tscn")
@export var helicopter_scene: PackedScene = preload("res://scenes/helicopter.tscn")
@export var spawn_interval := 2.3
@export var delay_between_waves := 3.0
@export var infantry_spawn_x := 1265.0
@export var spawn_y_min := 355.0
@export var spawn_y_max := 595.0
@export var sniper_x_min := 760.0
@export var sniper_x_max := 1150.0
@export var sniper_y_min := 175.0
@export var sniper_y_max := 220.0
@export var auto_start := true

@export var waves: Array[Dictionary] = [
	{"infantry": 4, "shotgun": 2, "heavy": 1, "snipers": 0, "heli": 1, "heli_troops": 3},
	{"infantry": 6, "shotgun": 2, "heavy": 2, "snipers": 0, "heli": 1, "heli_troops": 4},
	{"infantry": 7, "shotgun": 3, "heavy": 2, "snipers": 1, "heli": 2, "heli_troops": 5},
]

var _current_heli_troops := 4
var _sniper_spawn_idx := 0
var _formation_toggle := 0

var current_wave_index := -1
var current_subwave := 1
var total_subwaves := 3
var subwave_ratios: Array[float] = [0.33, 0.67]

var total_level_units := 1
var spawned_level_units := 0
var eliminated_level_units := 0
var total_enemy_soldiers := 1
var killed_enemy_soldiers := 0

var _spawn_queue: Array[String] = []
var _alive_enemies: Dictionary = {}
var _rewarded_enemies: Dictionary = {}
var _wave_in_progress := false
var _has_boss_fight := false
var _boss_spawned := false
var _boss_fight_active := false
var _boss_instance_id := -1

var _spawn_timer: Timer
var _wave_delay_timer: Timer
var _boss_minion_timer: Timer


func _ready() -> void:
	var level_cfg := GAME_STATE.get_current_level_data()
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

	_boss_minion_timer = Timer.new()
	_boss_minion_timer.name = "BossMinionTimer"
	_boss_minion_timer.wait_time = 3.8
	_boss_minion_timer.one_shot = false
	_boss_minion_timer.timeout.connect(_on_boss_minion_timer_timeout)
	add_child(_boss_minion_timer)

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


func get_remaining_enemies_count() -> int:
	if _boss_fight_active:
		return _alive_enemies.size()
	var base_rem := maxi(total_enemy_soldiers - killed_enemy_soldiers, 0)
	if _has_boss_fight and not _boss_spawned:
		return base_rem + 1
	return base_rem


func is_boss_fight_active() -> bool:
	return _boss_fight_active


func get_level_progress_ratio() -> float:
	if total_level_units <= 0:
		return 0.0
	if not _wave_in_progress and _spawn_queue.is_empty() and _alive_enemies.is_empty() and eliminated_level_units > 0:
		return 1.0
	if _boss_fight_active:
		return 0.96
	var spawned_frac := clampf(float(spawned_level_units) / float(total_level_units), 0.0, 1.0)
	var killed_frac := clampf(float(eliminated_level_units) / float(total_level_units), 0.0, 1.0)
	var raw_prog := clampf(killed_frac * 0.72 + spawned_frac * 0.28, 0.0, 1.0)
	if _has_boss_fight and not _boss_spawned:
		return raw_prog * 0.92
	return raw_prog


func _start_next_wave() -> void:
	current_wave_index += 1
	if current_wave_index >= waves.size():
		return

	_wave_in_progress = true
	current_subwave = 1
	spawned_level_units = 0
	eliminated_level_units = 0
	killed_enemy_soldiers = 0
	_boss_spawned = false
	_boss_fight_active = false
	_boss_instance_id = -1
	_has_boss_fight = bool(waves[current_wave_index].get("has_boss", false)) or (GAME_STATE.current_level == 5)
	_spawn_queue = _build_wave_queue(waves[current_wave_index])
	wave_started.emit(current_wave_index + 1)
	subwave_changed.emit(current_subwave, total_subwaves)

	# Спавнимо першого ворога одразу на старті хвилі, решту — за таймером
	_spawn_next_from_queue()
	if not _spawn_queue.is_empty():
		_spawn_timer.wait_time = spawn_interval
		_spawn_timer.start()


func _build_wave_queue(wave_data: Dictionary) -> Array[String]:
	var infantry_count := int(wave_data.get("infantry", 0))
	var shotgun_count := int(wave_data.get("shotgun", 0))
	var heavy_count := int(wave_data.get("heavy", 0))
	var grenadier_count := int(wave_data.get("grenadier", 0))
	var axe_count := int(wave_data.get("axe", 0))
	var sniper_count := int(wave_data.get("snipers", 0))
	_current_heli_troops = int(wave_data.get("heli_troops", 4))
	var heli_count := int(wave_data.get("heli", 0))

	total_enemy_soldiers = infantry_count + shotgun_count + heavy_count + grenadier_count + axe_count + sniper_count + (heli_count * clampi(_current_heli_troops, 1, 8))
	total_level_units = maxi(total_enemy_soldiers + heli_count, 1)

	# Формуємо загони по 5 ворогів одного типу (у вигляді V або в лінію), а решту залишаємо по одному
	var formations: Array[String] = []
	var max_infantry_formations := clampi(infantry_count / 7, 1, 3) if infantry_count >= 10 else 0
	for f in range(max_infantry_formations):
		if infantry_count >= 5:
			infantry_count -= 5
			var shape := "v" if ((_formation_toggle + f) % 2 == 0) else "line"
			formations.append("formation_%s:infantry" % shape)
	_formation_toggle += max_infantry_formations

	if shotgun_count >= 7:
		shotgun_count -= 5
		var sh_shape := "line" if (_formation_toggle % 2 == 0) else "v"
		formations.append("formation_%s:shotgun" % sh_shape)
		_formation_toggle += 1

	var max_axe_formations := clampi(axe_count / 6, 1, 2) if axe_count >= 5 else 0
	for a in range(max_axe_formations):
		if axe_count >= 5:
			axe_count -= 5
			var axe_shape := "line" if ((_formation_toggle + a) % 2 == 0) else "v"
			formations.append("formation_%s:axe" % axe_shape)
	_formation_toggle += max_axe_formations

	var single_pool: Array[String] = []
	for i in range(infantry_count):
		single_pool.append("infantry")

	# Рівномірно розподіляємо всі типи ворогів (дробовики, червоні важкі кулеметники, гранатометники, снайпери) по всій довжині рівня,
	# щоб вони гарантовано виходили в кожній хвилі
	_insert_evenly(single_pool, "shotgun", shotgun_count, 1)
	_insert_evenly(single_pool, "heavy", heavy_count, 1)
	_insert_evenly(single_pool, "grenadier", grenadier_count, 2)
	_insert_evenly(single_pool, "axe", axe_count, 2)
	_insert_evenly(single_pool, "sniper", sniper_count, 1)
	_insert_evenly(single_pool, "heli", heli_count, 3)

	# Розбиваємо рівень на 3 або 4 хвилі (subwaves) і вставляємо строї по 5 бійців у хвилі
	total_subwaves = 4 if GAME_STATE.current_level >= 8 else 3
	subwave_ratios.clear()
	for w in range(1, total_subwaves):
		subwave_ratios.append(float(w) / float(total_subwaves))

	var queue: Array[String] = []
	var total_singles := single_pool.size()
	var single_cursor := 0

	for w in range(total_subwaves):
		var remaining_waves := total_subwaves - w
		var chunk_size := int(ceil(float(total_singles - single_cursor) / float(remaining_waves)))
		var sub_items: Array[String] = []
		for k in range(chunk_size):
			if single_cursor < total_singles:
				sub_items.append(single_pool[single_cursor])
				single_cursor += 1

		# Додаємо стрій з 5 ворогів (V або в лінію) всередину хвилі (переважно у 2-гу, 3-тю, 4-ту хвилі, або і в 1-шу якщо строїв багато)
		if not formations.is_empty() and (w >= 1 or formations.size() >= total_subwaves):
			var form_cmd: String = formations.pop_front()
			var form_insert := clampi(sub_items.size() / 2, 1, maxi(sub_items.size(), 1))
			if sub_items.is_empty():
				sub_items.append(form_cmd)
			else:
				sub_items.insert(form_insert, form_cmd)

		for item in sub_items:
			queue.append(item)

		if w < total_subwaves - 1:
			queue.append("wave_break")

	# Якщо залишився ще якийсь стрій з 5 ворогів — додаємо перед фіналом
	while not formations.is_empty():
		queue.append(formations.pop_front())

	return queue


func _insert_evenly(pool: Array[String], unit_name: String, count: int, start_offset: int = 1) -> void:
	if count <= 0:
		return
	for i in range(count):
		var cur_len := pool.size()
		var ratio := (float(i) + 0.5) / float(count)
		var idx := clampi(int(roundf(ratio * float(cur_len))), mini(start_offset, cur_len), cur_len)
		pool.insert(idx, unit_name)


func _on_spawn_timer_timeout() -> void:
	_spawn_next_from_queue()
	if _spawn_queue.is_empty():
		_spawn_timer.stop()
		_check_wave_cleared()


func _spawn_next_from_queue() -> void:
	if _spawn_queue.is_empty():
		return

	var unit_type: String = _spawn_queue.pop_front()
	if unit_type == "wave_break":
		current_subwave = mini(current_subwave + 1, total_subwaves)
		subwave_changed.emit(current_subwave, total_subwaves)
		if not _spawn_queue.is_empty() and _spawn_timer:
			# Коротка пауза між хвилями всередині рівня
			_spawn_timer.start(maxf(spawn_interval * 1.85, 2.5))
		return

	if unit_type.begins_with("formation_"):
		var parts := unit_type.split(":")
		var is_v_shape := (parts[0] == "formation_v")
		var f_unit_type := parts[1] if parts.size() > 1 else "infantry"
		_spawn_five_formation(f_unit_type, is_v_shape)
		if not _spawn_queue.is_empty() and _spawn_timer:
			# Невелика пауза після виходу загону з 5 ворогів
			_spawn_timer.start(spawn_interval * 1.65)
		return

	if not _spawn_queue.is_empty() and _spawn_timer and not is_equal_approx(_spawn_timer.wait_time, spawn_interval):
		_spawn_timer.wait_time = spawn_interval

	if unit_type == "heli":
		_spawn_helicopter()
		return

	var packed: PackedScene = _get_scene_for_type(unit_type)
	if packed == null:
		return

	var unit := packed.instantiate() as Node2D
	if unit == null:
		return

	if unit_type == "sniper":
		# Розподіляємо снайперів вздовж верхнього пагорба, щоб вони не накладалися один на одного
		var slot := _sniper_spawn_idx % 6
		_sniper_spawn_idx += 1
		var slot_x := lerpf(740.0, 1185.0, float(slot) / 5.0) + randf_range(-24.0, 24.0)
		var slot_y := lerpf(sniper_y_min, sniper_y_max, float((slot * 3) % 5) / 4.0) + randf_range(-6.0, 6.0)
		unit.global_position = Vector2(clampf(slot_x, 725.0, 1210.0), clampf(slot_y, 165.0, 230.0))
	elif unit_type == "heavy":
		# Важкий кулеметник виходить на лінію окопу (y: 390..585), щоб його пряма черга з 8 червоних куль летіла впоперек окопу
		unit.global_position = Vector2(
			infantry_spawn_x,
			randf_range(390.0, 585.0)
		)
	else:
		unit.global_position = Vector2(
			infantry_spawn_x,
			randf_range(spawn_y_min, spawn_y_max)
		)

	_register_unit(unit, unit_type)

	var container := get_parent() if get_parent() != null else get_tree().current_scene
	container.add_child(unit)


## Спавнить одразу 5 ворогів одного типу у вигляді клину (V) або вертикальної шеренги (в лінію)
func _spawn_five_formation(unit_type: String, is_v_shape: bool) -> void:
	var packed := _get_scene_for_type(unit_type)
	if packed == null:
		return

	var container := get_parent() if get_parent() != null else get_tree().current_scene
	if container == null:
		return

	# 5 рівномірних вертикальних рядів поперек поля бою
	var row_ys: Array[float] = [368.0, 422.0, 476.0, 530.0, 584.0]
	var base_stop_x := 705.0
	if unit_type == "shotgun":
		base_stop_x = 635.0
	elif unit_type == "heavy":
		base_stop_x = 755.0
	elif unit_type == "grenadier":
		base_stop_x = 895.0
	elif unit_type == "axe":
		base_stop_x = 460.0

	for i in range(5):
		var unit := packed.instantiate() as Node2D
		if unit == null:
			continue

		var dist_from_center := absf(float(i - 2)) # 0 для центру (i=2), 1 для сусідніх (i=1,3), 2 для крайніх (i=0,4)
		var x_shift := (dist_from_center * 58.0) if is_v_shape else 0.0
		var spawn_x := infantry_spawn_x + x_shift
		var target_stop_x := (base_stop_x - 58.0 + dist_from_center * 58.0) if is_v_shape else base_stop_x

		unit.global_position = Vector2(spawn_x, row_ys[i])
		if unit.has_method("set_custom_stop_x"):
			unit.set_custom_stop_x(target_stop_x)

		_register_unit(unit, unit_type)
		container.add_child(unit)

	formation_spawned.emit(unit_type, is_v_shape)


func _get_scene_for_type(unit_type: String) -> PackedScene:
	match unit_type:
		"boss":
			return boss_grenadier_scene
		"sniper":
			return sniper_scene
		"heavy":
			return heavy_gunner_scene
		"grenadier":
			return grenadier_scene
		"axe":
			return axe_thrower_scene
		"shotgun":
			return shotgunner_scene
	return enemy_scene


func _register_unit(unit: Node2D, unit_type: String = "infantry", count_toward_level_total: bool = true) -> void:
	if count_toward_level_total:
		spawned_level_units += 1
	if unit_type == "boss":
		# ХП боса розраховано рівно на ~150 пострілів гвинтівки головного героя
		if "health" in unit:
			unit.health = roundf(150.0 * GAME_STATE.get_player_bullet_damage())
	else:
		var hp_mult := GAME_STATE.get_enemy_hp_multiplier(maxi(current_wave_index, 0))
		if "health" in unit:
			unit.health = roundf(float(unit.health) * hp_mult)
	var id := unit.get_instance_id()
	_alive_enemies[id] = true
	if unit.has_signal("died"):
		unit.connect("died", _on_unit_died.bind(id, unit, unit_type, count_toward_level_total), CONNECT_ONE_SHOT)
	unit.tree_exited.connect(_on_enemy_eliminated.bind(id, count_toward_level_total), CONNECT_ONE_SHOT)


func _on_unit_died(instance_id: int, unit: Node2D, unit_type: String, count_toward_level_total: bool = true) -> void:
	if not _rewarded_enemies.has(instance_id):
		_rewarded_enemies[instance_id] = true
		if count_toward_level_total:
			killed_enemy_soldiers += 1
		var pos := unit.global_position if is_instance_valid(unit) else Vector2(640.0, 480.0)
		var reward := GAME_STATE.get_kill_reward(unit_type)
		enemy_killed.emit(unit_type, pos, reward)
	_on_enemy_eliminated(instance_id, count_toward_level_total)


func _spawn_helicopter() -> void:
	if helicopter_scene == null:
		return
	var heli := helicopter_scene.instantiate() as Helicopter
	if heli == null:
		return

	# Різний десант: суміш піхоти, дробовиків, метальників сокири та важких кулеметників
	var pool: Array[String] = ["infantry", "infantry", "shotgun", "axe", "heavy"]
	pool.shuffle()
	var troops: Array[String] = []
	for i in range(clampi(_current_heli_troops, 1, 8)):
		troops.append(pool[i % pool.size()])
	heli.setup(troops)
	heli.trooper_drop_requested.connect(_on_heli_trooper_drop.bind(heli))

	# Вертоліт рахується "живим", доки не висадить усіх і не полетить — щоб хвиля не завершилась передчасно
	spawned_level_units += 1
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


func _on_enemy_eliminated(instance_id: int, count_toward_level_total: bool = true) -> void:
	if not _alive_enemies.has(instance_id):
		return
	_alive_enemies.erase(instance_id)
	if count_toward_level_total:
		eliminated_level_units += 1
	if instance_id == _boss_instance_id:
		_boss_fight_active = false
		if _boss_minion_timer:
			_boss_minion_timer.stop()
	_check_wave_cleared()


func _start_boss_fight() -> void:
	_boss_spawned = true
	_boss_fight_active = true
	boss_fight_started.emit()

	if boss_grenadier_scene != null:
		var boss := boss_grenadier_scene.instantiate() as Node2D
		if boss != null:
			boss.global_position = Vector2(infantry_spawn_x + 35.0, 485.0)
			if boss.has_method("set_custom_stop_x"):
				boss.set_custom_stop_x(915.0)
			_register_unit(boss, "boss", false)
			_boss_instance_id = boss.get_instance_id()
			var container := get_parent() if get_parent() != null else get_tree().current_scene
			container.add_child(boss)

	if _boss_minion_timer:
		_boss_minion_timer.start(3.6)


func _on_boss_minion_timer_timeout() -> void:
	if not _boss_fight_active or not _alive_enemies.has(_boss_instance_id):
		if _boss_minion_timer:
			_boss_minion_timer.stop()
		return

	# Рахуємо скільки звичайних ворогів-помічників зараз на полі (без самого боса). Максимум 3 одночасно!
	var alive_minions := maxi(_alive_enemies.size() - 1, 0)
	if alive_minions >= 3:
		return

	var available_slots := 3 - alive_minions
	var to_spawn := mini(randi_range(1, 2), available_slots)
	var minion_types: Array[String] = ["infantry", "shotgun", "heavy", "grenadier", "axe", "sniper"]
	var container := get_parent() if get_parent() != null else get_tree().current_scene
	if container == null:
		return

	for i in range(to_spawn):
		var m_type: String = minion_types[randi() % minion_types.size()]
		var packed := _get_scene_for_type(m_type)
		if packed == null:
			continue
		var unit := packed.instantiate() as Node2D
		if unit == null:
			continue

		if m_type == "sniper":
			var slot := _sniper_spawn_idx % 6
			_sniper_spawn_idx += 1
			var slot_x := lerpf(740.0, 1185.0, float(slot) / 5.0) + randf_range(-20.0, 20.0)
			var slot_y := lerpf(sniper_y_min, sniper_y_max, float((slot * 3) % 5) / 4.0) + randf_range(-5.0, 5.0)
			unit.global_position = Vector2(clampf(slot_x, 725.0, 1210.0), clampf(slot_y, 165.0, 230.0))
		elif m_type == "heavy":
			unit.global_position = Vector2(infantry_spawn_x + float(i) * 32.0, randf_range(390.0, 585.0))
		else:
			unit.global_position = Vector2(infantry_spawn_x + float(i) * 32.0, randf_range(spawn_y_min, spawn_y_max))

		_register_unit(unit, m_type, false)
		container.add_child(unit)


func _check_wave_cleared() -> void:
	if not _wave_in_progress:
		return
	if not is_inside_tree() or _spawn_timer == null or not _spawn_timer.is_inside_tree():
		return
	if not _spawn_queue.is_empty() or not _alive_enemies.is_empty():
		return

	if _has_boss_fight and not _boss_spawned:
		_start_boss_fight()
		return

	_wave_in_progress = false
	_spawn_timer.stop()
	if _boss_minion_timer:
		_boss_minion_timer.stop()
	wave_cleared.emit()

	if current_wave_index + 1 < waves.size():
		_wave_delay_timer.wait_time = delay_between_waves
		_wave_delay_timer.start()
	else:
		all_waves_cleared.emit()
