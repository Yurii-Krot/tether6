class_name BattlefieldEnvironment
extends Node2D

## Об'ємне багатошарове 2.5D поле бою:
## - Шар рельєфу та окопу (z_index = -3): об'ємні дерев'яні настили в окопі, тіні глибини, трава що гойдається від вітру й гвинта вертольота, постійні 3D-вирви від вибухів, тріщини, дим зі свіжих вирв, сліди куль.
## - Шар переднього бруствера окопу (z_index = -1): мішки з піском та укріплення перед бійцем.
## - Шар переднього плану та атмосфери (z_index = 14..18): колючий дріт і дерев'яні кілки на передньому плані, попіл та дрібні іскри в повітрі, ударні хвилі від вибухів.

const MAX_CRATERS := 28
const MAX_SCORCHES := 65
const MAX_ASH_PARTICLES := 48
const MAX_EMBER_PARTICLES := 36
const MAX_SHOCKWAVES := 8
const MAX_CRATER_SMOKE := 32

const TRENCH_BAYS_Y: Array[float] = [395.0, 495.0, 595.0]
const TRENCH_X := 212.0

var _time := 0.0
var _wind_strength := 1.0
var _heli_wash_pos := Vector2(-9999.0, -9999.0)
var _heli_wash_strength := 0.0

var _terrain_layer: Node2D
var _parapet_layer: Node2D
var _foreground_layer: Node2D
var _effects_layer: Node2D

var _grass_clusters: Array[Dictionary] = []
var _craters: Array[Dictionary] = []
var _scorches: Array[Dictionary] = []
var _crater_smoke: Array[Dictionary] = []

var _ash_particles: Array[Dictionary] = []
var _ember_particles: Array[Dictionary] = []
var _shockwaves: Array[Dictionary] = []


func _ready() -> void:
	add_to_group("battlefield_environment")
	z_index = 0
	y_sort_enabled = false

	_terrain_layer = Node2D.new()
	_terrain_layer.name = "TerrainLayer"
	_terrain_layer.z_index = -3
	_terrain_layer.draw.connect(_draw_terrain_layer)
	add_child(_terrain_layer)

	_parapet_layer = Node2D.new()
	_parapet_layer.name = "ParapetLayer"
	_parapet_layer.z_index = -1
	_parapet_layer.draw.connect(_draw_parapet_layer)
	add_child(_parapet_layer)

	_foreground_layer = Node2D.new()
	_foreground_layer.name = "ForegroundLayer"
	_foreground_layer.z_index = 14
	_foreground_layer.draw.connect(_draw_foreground_layer)
	add_child(_foreground_layer)

	_effects_layer = Node2D.new()
	_effects_layer.name = "EffectsLayer"
	_effects_layer.z_index = 18
	_effects_layer.draw.connect(_draw_effects_layer)
	add_child(_effects_layer)

	_init_grass_clusters()
	_init_atmosphere_particles()


func _init_grass_clusters() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 40771
	# Трава вздовж верхнього валу, біля паркану, пеньків та каміння
	var spans: Array[Dictionary] = [
		{"x0": 35.0, "x1": 260.0, "y0": 265.0, "y1": 308.0, "count": 14},
		{"x0": 270.0, "x1": 740.0, "y0": 255.0, "y1": 318.0, "count": 26},
		{"x0": 740.0, "x1": 1255.0, "y0": 275.0, "y1": 352.0, "count": 28},
	]
	for sp in spans:
		var c := int(sp["count"])
		for i in range(c):
			var t := float(i) / float(maxi(c - 1, 1))
			var gx := lerpf(float(sp["x0"]), float(sp["x1"]), t) + rng.randf_range(-12.0, 12.0)
			var gy := rng.randf_range(float(sp["y0"]), float(sp["y1"]))
			var blades: Array[Dictionary] = []
			var b_count := rng.randi_range(4, 7)
			for b in range(b_count):
				blades.append({
					"dx": (float(b) - float(b_count - 1) * 0.5) * rng.randf_range(2.6, 3.8),
					"h": rng.randf_range(11.0, 22.0),
					"lean": rng.randf_range(-4.5, 5.5),
					"phase": rng.randf_range(0.0, TAU),
					"shade": rng.randf_range(0.75, 1.15)
				})
			_grass_clusters.append({
				"pos": Vector2(gx, gy),
				"blades": blades,
				"phase": rng.randf_range(0.0, TAU)
			})


func _init_atmosphere_particles() -> void:
	for i in range(MAX_ASH_PARTICLES):
		_ash_particles.append(_make_ash_particle(true))

	for i in range(MAX_EMBER_PARTICLES):
		_ember_particles.append(_make_ember_particle(true))


func _make_ash_particle(random_x: bool) -> Dictionary:
	var depth := randf()
	return {
		"pos": Vector2(randf_range(-40.0, 1320.0) if random_x else randf_range(-60.0, 260.0), randf_range(-20.0, 720.0)),
		"vel": Vector2(randf_range(22.0, 56.0), randf_range(8.0, 26.0)) * lerpf(0.65, 1.35, depth),
		"size": lerpf(1.3, 2.8, depth),
		"alpha": lerpf(0.20, 0.45, depth),
		"phase": randf_range(0.0, TAU),
		"wobble_speed": randf_range(1.8, 4.2),
		"depth": depth,
	}


func _make_ember_particle(random_pos: bool) -> Dictionary:
	var spawn_pos := Vector2(
		randf_range(0.0, 1300.0) if random_pos else randf_range(-40.0, 1280.0),
		randf_range(60.0, 700.0) if random_pos else randf_range(480.0, 735.0)
	)
	return {
		"pos": spawn_pos,
		"vel": Vector2(randf_range(28.0, 78.0), randf_range(-58.0, -18.0)),
		"size": randf_range(1.4, 2.8),
		"life": randf_range(0.0, 2.5) if random_pos else 0.0,
		"max_life": randf_range(2.6, 5.2),
		"phase": randf_range(0.0, TAU),
	}


func _process(delta: float) -> void:
	if delta <= 0.0:
		return
	_time += delta
	_wind_strength = 1.0 + 0.28 * sin(_time * 0.75) + 0.15 * cos(_time * 1.9)

	_update_helicopter_wash(delta)
	_update_terrain_dynamics(delta)
	_update_atmosphere(delta)
	_update_shockwaves(delta)

	_terrain_layer.queue_redraw()
	_parapet_layer.queue_redraw()
	_foreground_layer.queue_redraw()
	_effects_layer.queue_redraw()


func _update_helicopter_wash(delta: float) -> void:
	var found_heli: Node2D = null
	var scene := get_parent()
	if scene != null:
		for child in scene.get_children():
			if child is Helicopter and is_instance_valid(child):
				found_heli = child
				break
	if found_heli != null:
		_heli_wash_pos = found_heli.global_position
		var on_screen := clampf(1.0 - absf(_heli_wash_pos.x - 680.0) / 760.0, 0.0, 1.0)
		_heli_wash_strength = move_toward(_heli_wash_strength, on_screen, delta * 2.5)
	else:
		_heli_wash_strength = move_toward(_heli_wash_strength, 0.0, delta * 1.8)


func _update_terrain_dynamics(delta: float) -> void:
	# Оновлюємо вирви від вибухів і димок над ними
	for i in range(_craters.size() - 1, -1, -1):
		var c: Dictionary = _craters[i]
		var age := float(c["age"]) + delta
		var max_age := float(c["max_age"])
		if age >= max_age:
			_craters.remove_at(i)
			continue
		c["age"] = age
		if age < 8.0:
			var sm_timer := float(c["smoke_timer"]) - delta
			if sm_timer <= 0.0:
				sm_timer = randf_range(0.26, 0.52)
				var cpos: Vector2 = c["pos"]
				var crx: float = float(c["rx"])
				_spawn_crater_smoke_wisp(cpos + Vector2(randf_range(-crx * 0.35, crx * 0.35), randf_range(-4.0, 4.0)), clampf(1.0 - age / 8.0, 0.2, 0.75))
			c["smoke_timer"] = sm_timer
		_craters[i] = c

	for i in range(_scorches.size() - 1, -1, -1):
		var sc: Dictionary = _scorches[i]
		var age := float(sc["age"]) + delta
		if age >= float(sc["max_age"]):
			_scorches.remove_at(i)
		else:
			sc["age"] = age
			_scorches[i] = sc

	for i in range(_crater_smoke.size() - 1, -1, -1):
		var cs: Dictionary = _crater_smoke[i]
		var age := float(cs["age"]) + delta
		if age >= float(cs["max_age"]):
			_crater_smoke.remove_at(i)
			continue
		cs["age"] = age
		var pos: Vector2 = cs["pos"]
		var wind_push := 22.0 * _wind_strength
		if _heli_wash_strength > 0.05:
			var dx := pos.x - _heli_wash_pos.x
			wind_push += signf(dx if absf(dx) > 1.0 else 1.0) * 140.0 * _heli_wash_strength
		pos += Vector2(wind_push * delta, float(cs["vy"]) * delta)
		cs["pos"] = pos
		cs["r"] = float(cs["r"]) + delta * 8.0
		_crater_smoke[i] = cs


func _spawn_crater_smoke_wisp(pos: Vector2, intensity: float) -> void:
	if _crater_smoke.size() >= MAX_CRATER_SMOKE:
		return
	_crater_smoke.append({
		"pos": pos,
		"vy": randf_range(-32.0, -18.0),
		"r": randf_range(4.5, 8.0),
		"age": 0.0,
		"max_age": randf_range(1.1, 1.9),
		"alpha": randf_range(0.16, 0.28) * intensity,
	})


func _update_atmosphere(delta: float) -> void:
	var heli_boost := 1.0 + _heli_wash_strength * 1.45

	for i in range(_ash_particles.size()):
		var a: Dictionary = _ash_particles[i]
		var pos: Vector2 = a["pos"]
		var vel: Vector2 = a["vel"]
		var phase := float(a["phase"]) + float(a["wobble_speed"]) * delta
		a["phase"] = phase
		pos.x += (vel.x * _wind_strength * heli_boost + sin(phase) * 14.0) * delta
		pos.y += (vel.y + cos(phase * 0.8) * 9.0) * delta
		if pos.x > 1340.0 or pos.y > 745.0:
			_ash_particles[i] = _make_ash_particle(false)
		else:
			a["pos"] = pos
			_ash_particles[i] = a

	for i in range(_ember_particles.size()):
		var e: Dictionary = _ember_particles[i]
		var life := float(e["life"]) + delta
		if life >= float(e["max_life"]):
			_ember_particles[i] = _make_ember_particle(false)
			continue
		e["life"] = life
		var pos: Vector2 = e["pos"]
		var vel: Vector2 = e["vel"]
		var phase := float(e["phase"]) + delta * 5.0
		e["phase"] = phase
		pos.x += (vel.x * _wind_strength * heli_boost + sin(phase) * 24.0) * delta
		pos.y += (vel.y + cos(phase * 1.3) * 14.0) * delta
		if pos.x > 1350.0 or pos.y < -40.0:
			_ember_particles[i] = _make_ember_particle(false)
		else:
			e["pos"] = pos
			_ember_particles[i] = e


func _update_shockwaves(delta: float) -> void:
	for i in range(_shockwaves.size() - 1, -1, -1):
		var sw: Dictionary = _shockwaves[i]
		var age := float(sw["age"]) + delta
		if age >= float(sw["max_age"]):
			_shockwaves.remove_at(i)
		else:
			sw["age"] = age
			_shockwaves[i] = sw


# ══════════════════════════════════════════════════════════════════════════════
# ПУБЛІЧНЕ API ДЛЯ ЗБРОЇ, ВИБУХІВ, ГРАНАТ, РАКЕТ ТА КУЛЬ
# ══════════════════════════════════════════════════════════════════════════════

## Реєструє об'ємну 3D-вирву на полі бою з тріщинами, бруствером ґрунту, грудками землі та ударною хвилею.
func spawn_explosion_crater(world_pos: Vector2, radius: float = 58.0, is_heavy: bool = true) -> void:
	if _craters.size() >= MAX_CRATERS:
		_craters.pop_front()

	var rx := clampf(radius * 0.95, 26.0, 78.0)
	var ry := rx * 0.38
	var cracks: Array[Dictionary] = []
	var crack_count := 8 if is_heavy else 5
	for i in range(crack_count):
		var ang := (TAU / float(crack_count)) * float(i) + randf_range(-0.22, 0.22)
		var r0 := randf_range(0.55, 0.78)
		var r1 := randf_range(1.05, 1.38)
		var r2 := r1 + randf_range(0.25, 0.55)
		var bend1 := ang + randf_range(-0.28, 0.28)
		var bend2 := bend1 + randf_range(-0.34, 0.34)
		cracks.append({
			"p0": Vector2(cos(ang) * rx * r0, sin(ang) * ry * r0),
			"p1": Vector2(cos(bend1) * rx * r1, sin(bend1) * ry * r1),
			"p2": Vector2(cos(bend2) * rx * r2, sin(bend2) * ry * r2),
			"w": randf_range(1.4, 2.4) if is_heavy else randf_range(1.0, 1.7)
		})

	var clods: Array[Dictionary] = []
	var clod_count := 12 if is_heavy else 7
	for i in range(clod_count):
		var ang := randf_range(0.0, TAU)
		var dist := randf_range(0.88, 1.48)
		clods.append({
			"pos": Vector2(cos(ang) * rx * dist, sin(ang) * ry * dist),
			"r": randf_range(2.2, 4.8) if is_heavy else randf_range(1.6, 3.4),
			"shade": randf_range(0.18, 0.36),
		})

	var outer_pts := PackedVector2Array()
	var inner_pts := PackedVector2Array()
	var segs := 16
	for i in range(segs):
		var a := float(i) * TAU / float(segs)
		var jitter := 1.0 + 0.12 * sin(float(i) * 3.1 + world_pos.x)
		outer_pts.append(Vector2(cos(a) * rx * jitter, sin(a) * ry * jitter))
		inner_pts.append(Vector2(cos(a) * rx * 0.68 * jitter, sin(a) * ry * 0.65 * jitter))

	_craters.append({
		"pos": world_pos,
		"rx": rx,
		"ry": ry,
		"outer_pts": outer_pts,
		"inner_pts": inner_pts,
		"cracks": cracks,
		"clods": clods,
		"age": 0.0,
		"max_age": 24.0 if is_heavy else 16.0,
		"smoke_timer": 0.05,
		"is_heavy": is_heavy,
	})

	trigger_shockwave(world_pos, rx * (3.0 if is_heavy else 2.0), 0.30 if is_heavy else 0.20)

	# Викид розжарених іскор у повітря від вибуху
	for i in range(8 if is_heavy else 4):
		if _ember_particles.size() < MAX_EMBER_PARTICLES + 16:
			_ember_particles.append({
				"pos": world_pos + Vector2(randf_range(-18.0, 18.0), randf_range(-10.0, 6.0)),
				"vel": Vector2(randf_range(-85.0, 110.0), randf_range(-135.0, -45.0)),
				"size": randf_range(1.8, 3.4),
				"life": 0.0,
				"max_life": randf_range(0.9, 1.8),
				"phase": randf_range(0.0, TAU),
			})


## Реєструє слід від влучання кулі або осколка в ґрунт.
func spawn_bullet_ground_impact(world_pos: Vector2, _impact_color: Color = Color(1.0, 0.85, 0.35, 1.0)) -> void:
	if world_pos.y >= 310.0 and world_pos.y <= 695.0:
		if _scorches.size() >= MAX_SCORCHES:
			_scorches.pop_front()
		_scorches.append({
			"pos": world_pos,
			"r": randf_range(4.5, 8.0),
			"age": 0.0,
			"max_age": randf_range(8.0, 14.0),
		})


## Залишено сумісним методом без овальних світлових плям.
func trigger_light_pulse(_world_pos: Vector2, _color: Color, _radius: float = 140.0, _duration: float = 0.18) -> void:
	pass


## Запускає видиме кільце ударної хвилі по землі та повітрю.
func trigger_shockwave(world_pos: Vector2, max_radius: float = 180.0, duration: float = 0.28) -> void:
	if _shockwaves.size() >= MAX_SHOCKWAVES:
		_shockwaves.pop_front()
	_shockwaves.append({
		"pos": world_pos,
		"max_r": maxf(max_radius, 40.0),
		"age": 0.0,
		"max_age": maxf(duration, 0.08),
	})


# ══════════════════════════════════════════════════════════════════════════════
# ВІДМАЛЬОВКА ШАРУ РЕЛЬЄФУ, ОКОПУ, ТРАВИ ТА 3D-ВИРВ (z_index = -3)
# ══════════════════════════════════════════════════════════════════════════════

func _draw_terrain_layer() -> void:
	_draw_ground_volume_shading()
	_draw_trench_interior_depth()
	_draw_embankment_depth_and_grass()
	_draw_dynamic_scorches_and_craters()


func _draw_ground_volume_shading() -> void:
	# Розсип стріляних латунних гільз біля бруствера окопу (x = 262..325, y = 370..625)
	var brass_spots: Array[Vector2] = [
		Vector2(272.0, 388.0), Vector2(284.0, 396.0), Vector2(268.0, 412.0),
		Vector2(278.0, 468.0), Vector2(291.0, 482.0), Vector2(270.0, 498.0),
		Vector2(285.0, 512.0), Vector2(266.0, 565.0), Vector2(280.0, 584.0),
		Vector2(294.0, 596.0), Vector2(273.0, 614.0),
	]
	for idx in range(brass_spots.size()):
		var bp := brass_spots[idx]
		var ang := float(idx) * 1.15 + 0.3
		var dir := Vector2(cos(ang), sin(ang)) * 3.2
		_terrain_layer.draw_line(bp - dir + Vector2(0.0, 1.2), bp + dir + Vector2(0.0, 1.2), Color(0.05, 0.04, 0.03, 0.65), 2.4)
		_terrain_layer.draw_line(bp - dir, bp + dir, Color(0.86, 0.68, 0.24, 0.82), 1.8)


func _draw_trench_interior_depth() -> void:
	# Глибока об'ємна тінь всередині окопу вздовж лівої та передньої стінок,
	# а також 3 тактичні дерев'яні настили (duckboards) під позиціями гравця (y = 395, 495, 595)
	var trench_floor_poly := PackedVector2Array([
		Vector2(142.0, 326.0),
		Vector2(252.0, 326.0),
		Vector2(246.0, 654.0),
		Vector2(126.0, 654.0),
	])
	_terrain_layer.draw_colored_polygon(trench_floor_poly, Color(0.08, 0.06, 0.04, 0.34))

	# Тінь під лівою стінкою з мішками та дошками
	var left_wall_ao := PackedVector2Array([
		Vector2(122.0, 324.0),
		Vector2(168.0, 326.0),
		Vector2(158.0, 654.0),
		Vector2(108.0, 654.0),
	])
	_terrain_layer.draw_colored_polygon(left_wall_ao, Color(0.03, 0.02, 0.015, 0.48))

	# Тінь під передньою (правою) стінкою окопу
	var right_wall_ao := PackedVector2Array([
		Vector2(232.0, 326.0),
		Vector2(258.0, 326.0),
		Vector2(252.0, 654.0),
		Vector2(224.0, 654.0),
	])
	_terrain_layer.draw_colored_polygon(right_wall_ao, Color(0.04, 0.03, 0.02, 0.44))

	# 3 тактичні секції (бійниці) окопу з дерев'яними трапами під ногами героя
	for idx in range(TRENCH_BAYS_Y.size()):
		var bay_y := TRENCH_BAYS_Y[idx] + 44.0
		var bay_x := TRENCH_X - 4.0 + float(idx - 1) * (-3.5)

		# Дерев'яні планки настилу (duckboards) у перспективі
		for p in range(-2, 3):
			var py := bay_y + float(p) * 11.5
			var px_left := bay_x - 30.0 - float(p) * 1.2
			var px_right := bay_x + 28.0 - float(p) * 1.2
			var plank_rect := PackedVector2Array([
				Vector2(px_left, py - 3.2),
				Vector2(px_right, py - 3.2),
				Vector2(px_right - 1.5, py + 3.2),
				Vector2(px_left - 1.5, py + 3.2),
			])
			_terrain_layer.draw_colored_polygon(plank_rect, Color(0.28, 0.20, 0.12, 0.52))
			_terrain_layer.draw_polyline(
				PackedVector2Array([plank_rect[0], plank_rect[1], plank_rect[2], plank_rect[3], plank_rect[0]]),
				Color(0.09, 0.06, 0.04, 0.62),
				1.3
			)
			_terrain_layer.draw_line(plank_rect[0] + Vector2(2.0, 1.0), plank_rect[1] + Vector2(-2.0, 1.0), Color(0.46, 0.35, 0.22, 0.38), 1.0)

		# Поперечні бруси під дошками
		_terrain_layer.draw_line(Vector2(bay_x - 20.0, bay_y - 26.0), Vector2(bay_x - 24.0, bay_y + 26.0), Color(0.14, 0.10, 0.06, 0.45), 3.0)
		_terrain_layer.draw_line(Vector2(bay_x + 18.0, bay_y - 26.0), Vector2(bay_x + 14.0, bay_y + 26.0), Color(0.14, 0.10, 0.06, 0.45), 3.0)


func _draw_embankment_depth_and_grass() -> void:
	# Анімовані пучки трави вздовж валу, що колишуться від вітру та потоку повітря з вертольота
	for gc in _grass_clusters:
		var cpos: Vector2 = gc["pos"]
		var cphase: float = float(gc["phase"])
		var heli_push := 0.0
		if _heli_wash_strength > 0.02:
			var dx := cpos.x - _heli_wash_pos.x
			var dist_factor := clampf(1.0 - absf(dx) / 360.0, 0.0, 1.0)
			heli_push = signf(dx if absf(dx) > 1.0 else 1.0) * dist_factor * _heli_wash_strength * 14.0

		var blades: Array = gc["blades"]
		for b in blades:
			var bpos := cpos + Vector2(float(b["dx"]), 0.0)
			var bh := float(b["h"])
			var sway := sin(_time * 2.8 + cphase + float(b["phase"])) * 3.2 * _wind_strength + float(b["lean"]) + heli_push
			var tip := bpos + Vector2(sway, -bh)
			var mid := bpos + Vector2(sway * 0.45, -bh * 0.52)
			var shade := float(b["shade"])
			var blade_col := Color(0.24 * shade, 0.34 * shade, 0.16 * shade, 0.78)
			_terrain_layer.draw_line(bpos, mid, Color(0.11, 0.16, 0.07, 0.82), 2.4)
			_terrain_layer.draw_line(mid, tip, blade_col, 1.6)


func _draw_dynamic_scorches_and_craters() -> void:
	# 1. Дрібні сліди від куль та осколків на ґрунті
	for sc in _scorches:
		var prog := clampf(float(sc["age"]) / maxf(float(sc["max_age"]), 0.01), 0.0, 1.0)
		var alpha := clampf(1.0 - (prog - 0.65) / 0.35, 0.0, 1.0) * 0.55
		var pos: Vector2 = sc["pos"]
		var r := float(sc["r"])
		_terrain_layer.draw_set_transform(pos, 0.0, Vector2(1.0, 0.46))
		_terrain_layer.draw_circle(Vector2.ZERO, r * 1.35, Color(0.24, 0.18, 0.12, alpha * 0.65))
		_terrain_layer.draw_circle(Vector2.ZERO, r * 0.78, Color(0.07, 0.05, 0.04, alpha))
	_terrain_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# 2. Об'ємні 3D-вирви від гранат, ракет і молотів (без овальних світлових плям)
	for c in _craters:
		var age := float(c["age"])
		var max_age := float(c["max_age"])
		var fade := clampf(1.0 - (age - (max_age - 3.0)) / 3.0, 0.0, 1.0)
		if fade <= 0.01:
			continue
		var pos: Vector2 = c["pos"]

		# Радіальні тріщини в землі навколо вирви
		var cracks: Array = c["cracks"]
		for cr in cracks:
			var p0 := pos + (cr["p0"] as Vector2)
			var p1 := pos + (cr["p1"] as Vector2)
			var p2 := pos + (cr["p2"] as Vector2)
			var w := float(cr["w"])
			_terrain_layer.draw_line(p0, p1, Color(0.07, 0.05, 0.035, 0.72 * fade), w)
			_terrain_layer.draw_line(p1, p2, Color(0.07, 0.05, 0.035, 0.45 * fade), w * 0.65)

		# Зовнішній насипний валик ґрунту та темне заглиблення вирви
		_terrain_layer.draw_set_transform(pos + Vector2(0.0, 2.5), 0.0, Vector2.ONE)
		_terrain_layer.draw_colored_polygon(c["outer_pts"] as PackedVector2Array, Color(0.32, 0.24, 0.16, 0.78 * fade))
		_terrain_layer.draw_set_transform(pos, 0.0, Vector2.ONE)
		_terrain_layer.draw_colored_polygon(c["outer_pts"] as PackedVector2Array, Color(0.18, 0.13, 0.09, 0.85 * fade))
		_terrain_layer.draw_colored_polygon(c["inner_pts"] as PackedVector2Array, Color(0.06, 0.045, 0.035, 0.92 * fade))
		_terrain_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Розкидані грудки землі та камінці по периметру вирви
		var clods: Array = c["clods"]
		for cl in clods:
			var cpos := pos + (cl["pos"] as Vector2)
			var cr_r := float(cl["r"])
			var sh := float(cl["shade"])
			_terrain_layer.draw_circle(cpos + Vector2(1.0, 1.2), cr_r, Color(0.04, 0.03, 0.02, 0.65 * fade))
			_terrain_layer.draw_circle(cpos, cr_r, Color(sh + 0.08, sh, sh - 0.05, 0.88 * fade))

	# 3. Легкі цівки диму, що піднімаються зі свіжих вирв
	for cs in _crater_smoke:
		var prog := clampf(float(cs["age"]) / maxf(float(cs["max_age"]), 0.01), 0.0, 1.0)
		var env := sin(prog * PI)
		var alpha := float(cs["alpha"]) * env
		var pos: Vector2 = cs["pos"]
		var r := float(cs["r"])
		_terrain_layer.draw_circle(pos, r, Color(0.26, 0.24, 0.22, alpha))


# ══════════════════════════════════════════════════════════════════════════════
# ВІДМАЛЬОВКА ПЕРЕДНЬОГО БРУСТВЕРА ОКОПУ (z_index = -1)
# ══════════════════════════════════════════════════════════════════════════════

func _draw_parapet_layer() -> void:
	var slope_shadow := PackedVector2Array([
		Vector2(254.0, 324.0),
		Vector2(284.0, 332.0),
		Vector2(274.0, 654.0),
		Vector2(242.0, 654.0),
	])
	_parapet_layer.draw_colored_polygon(slope_shadow, Color(0.07, 0.05, 0.035, 0.24))


# ══════════════════════════════════════════════════════════════════════════════
# ВІДМАЛЬОВКА ПЕРЕДНЬОГО ПЛАНУ (ДРІТ, ПОПІЛ, ІСКРИ) (z_index = 14)
# ══════════════════════════════════════════════════════════════════════════════

func _draw_foreground_layer() -> void:
	_draw_foreground_barbed_wire()

	# Частинки попелу в повітрі
	for a in _ash_particles:
		var pos: Vector2 = a["pos"]
		var sz := float(a["size"])
		var alpha := float(a["alpha"])
		_foreground_layer.draw_circle(pos, sz, Color(0.22, 0.20, 0.19, alpha * 0.85))
		_foreground_layer.draw_circle(pos + Vector2(-0.3, -0.3), sz * 0.6, Color(0.62, 0.58, 0.54, alpha))

	# Дрібні іскри, що летять за вітром
	for e in _ember_particles:
		var prog := clampf(float(e["life"]) / maxf(float(e["max_life"]), 0.01), 0.0, 1.0)
		var env := sin(prog * PI)
		var flicker := 0.7 + 0.3 * sin(_time * 18.0 + float(e["phase"]))
		var alpha := env * flicker
		if alpha <= 0.02:
			continue
		var pos: Vector2 = e["pos"]
		var sz := float(e["size"])
		var vel: Vector2 = e["vel"]
		var tail := pos - vel.normalized() * (sz * 2.8)
		_foreground_layer.draw_line(tail, pos, Color(1.0, 0.45, 0.12, alpha * 0.65), sz * 0.85)
		_foreground_layer.draw_circle(pos, sz * 0.65, Color(1.0, 0.90, 0.50, alpha * 0.92))


func _draw_foreground_barbed_wire() -> void:
	var stakes: Array[Array] = [
		[Vector2(936.0, 725.0), Vector2(964.0, 628.0), 7.5],
		[Vector2(996.0, 725.0), Vector2(944.0, 646.0), 6.5],
		[Vector2(1148.0, 725.0), Vector2(1118.0, 616.0), 8.5],
		[Vector2(1192.0, 725.0), Vector2(1235.0, 632.0), 8.0],
	]
	for st in stakes:
		var p0: Vector2 = st[0]
		var p1: Vector2 = st[1]
		var w: float = float(st[2])
		_foreground_layer.draw_line(p0, p1, Color(0.06, 0.05, 0.04, 0.92), w + 3.0)
		_foreground_layer.draw_line(p0, p1, Color(0.28, 0.22, 0.16, 0.90), w)
		_foreground_layer.draw_line(p0 + Vector2(-1.5, 0.0), p1 + Vector2(-1.5, 0.0), Color(0.42, 0.34, 0.25, 0.55), w * 0.35)

	var coil_centers: Array[Vector2] = [
		Vector2(885.0, 685.0),
		Vector2(932.0, 672.0),
		Vector2(982.0, 668.0),
		Vector2(1035.0, 674.0),
		Vector2(1088.0, 666.0),
		Vector2(1142.0, 670.0),
		Vector2(1198.0, 664.0),
		Vector2(1248.0, 672.0),
	]
	for idx in range(coil_centers.size()):
		var c := coil_centers[idx]
		var rx := 34.0 + float(idx % 3) * 4.0
		var ry := 44.0 + float((idx + 1) % 2) * 5.0
		var rot := -0.18 + float(idx % 3) * 0.12
		_foreground_layer.draw_set_transform(c, rot, Vector2(rx / 40.0, ry / 40.0))
		_foreground_layer.draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 24, Color(0.05, 0.05, 0.06, 0.88), 3.2)
		_foreground_layer.draw_arc(Vector2.ZERO, 40.0, 0.0, TAU, 24, Color(0.36, 0.35, 0.33, 0.78), 1.5)
		for b in range(6):
			var ba := float(b) * TAU / 6.0 + float(idx) * 0.5
			var bp := Vector2(cos(ba) * 40.0, sin(ba) * 40.0)
			_foreground_layer.draw_line(bp + Vector2(-4.5, -3.5), bp + Vector2(4.5, 3.5), Color(0.10, 0.10, 0.11, 0.90), 1.8)
			_foreground_layer.draw_line(bp + Vector2(-3.5, 4.5), bp + Vector2(3.5, -4.5), Color(0.45, 0.43, 0.40, 0.82), 1.3)
	_foreground_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


# ══════════════════════════════════════════════════════════════════════════════
# ВІДМАЛЬОВКА УДАРНИХ ХВИЛЬ ВІД ВИБУХІВ (z_index = 18)
# ══════════════════════════════════════════════════════════════════════════════

func _draw_effects_layer() -> void:
	for sw in _shockwaves:
		var prog := clampf(float(sw["age"]) / maxf(float(sw["max_age"]), 0.01), 0.0, 1.0)
		var eased := 1.0 - pow(1.0 - prog, 2.2)
		var alpha := (1.0 - prog) * 0.45
		var pos: Vector2 = sw["pos"]
		var r := lerpf(18.0, float(sw["max_r"]), eased)
		_effects_layer.draw_set_transform(pos, 0.0, Vector2(1.0, 0.44))
		_effects_layer.draw_arc(Vector2.ZERO, r, 0.0, TAU, 36, Color(1.0, 0.84, 0.52, alpha), lerpf(4.0, 1.0, prog))
	_effects_layer.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
