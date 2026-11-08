extends Node2D

const UPGRADE_SCENE_PATH := "res://scenes/upgrade_menu.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"

var _game_over := false
var _transitioning := false
var _campaign_won := false
var _elapsed_time := 0.0
var _level_earned := 0

@onready var wave_manager: WaveManager = $WaveManager
@onready var player: Node2D = $Player
@onready var wave_label: Label = $UI/WaveLabel
@onready var banner_label: Label = $UI/BannerLabel


func _ready() -> void:
	_level_earned = 0
	_update_hud()

	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	wave_manager.enemy_killed.connect(_on_enemy_killed)
	if player.has_signal("died"):
		player.connect("died", _on_player_died)

	# Плавний вихід із чорного затемнення після переходу з меню покращень
	var fade_in := ColorRect.new()
	fade_in.color = Color(0.0, 0.0, 0.0, 1.0)
	fade_in.size = Vector2(1600.0, 900.0)
	fade_in.position = Vector2(-160.0, -90.0)
	fade_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade_in)
	var tween := create_tween()
	tween.tween_property(fade_in, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fade_in.queue_free)


func _process(delta: float) -> void:
	if not _game_over:
		_elapsed_time += delta
	elif not _transitioning and Input.is_action_just_pressed("ui_accept"):
		if _campaign_won:
			GameState.reset_campaign()
			_fade_to_scene(MAIN_MENU_SCENE_PATH)
		else:
			_fade_to_scene(UPGRADE_SCENE_PATH)


func _update_hud() -> void:
	if wave_label:
		wave_label.text = "Рівень: %d / %d   |   Монети: $%d" % [GameState.current_level, GameState.TOTAL_LEVELS, GameState.coins]


func _on_wave_started(_wave_number: int) -> void:
	if _game_over:
		return
	_update_hud()
	banner_label.text = ""


func _on_enemy_killed(_unit_type: String, world_pos: Vector2, reward: int) -> void:
	GameState.coins += reward
	_level_earned += reward
	_update_hud()
	_spawn_coin_popup(world_pos, reward)


func _spawn_coin_popup(world_pos: Vector2, reward: int) -> void:
	var lbl := Label.new()
	lbl.text = "+$%d" % reward
	lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.28, 1.0))
	lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	lbl.add_theme_constant_override("outline_size", 4)
	lbl.add_theme_font_size_override("font_size", 18)
	lbl.global_position = world_pos + Vector2(-18.0, -55.0)
	lbl.z_index = 30
	add_child(lbl)

	var t := lbl.create_tween().set_parallel(true)
	t.tween_property(lbl, "global_position:y", lbl.global_position.y - 34.0, 0.65).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(lbl, "modulate:a", 0.0, 0.65).set_delay(0.15)
	t.chain().tween_callback(lbl.queue_free)


func _on_wave_cleared() -> void:
	pass


func _on_all_waves_cleared() -> void:
	if _game_over:
		return
	_game_over = true

	var clear_bonus := int(GameState.get_current_level_data().get("reward", 50))
	GameState.coins += clear_bonus
	_level_earned += clear_bonus
	GameState.last_level_earned = _level_earned
	_update_hud()

	var finished_level := GameState.current_level
	if finished_level < GameState.TOTAL_LEVELS:
		GameState.current_level += 1
		banner_label.modulate = Color(0.75, 1.0, 0.75, 1.0)
		banner_label.text = "РІВЕНЬ %d ПРОЙДЕНО!\nЗароблено за бій: +$%d" % [finished_level, _level_earned]
		var wait_tween := create_tween()
		wait_tween.tween_interval(1.35)
		wait_tween.tween_callback(_fade_to_scene.bind(UPGRADE_SCENE_PATH))
	else:
		_campaign_won = true
		GameState.current_level = GameState.TOTAL_LEVELS + 1
		banner_label.modulate = Color(1.0, 0.92, 0.4, 1.0)
		banner_label.text = "ПЕРЕМОГА! Всі %d рівнів пройдено!\nЗагальний баланс: $%d\n[Enter — у головне меню]" % [GameState.TOTAL_LEVELS, GameState.coins]


func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	GameState.last_level_earned = _level_earned
	banner_label.modulate = Color(1.0, 0.42, 0.42, 1.0)
	banner_label.text = "ПОРАЗКА! Відступаємо у вікно покращень...\n(Зароблено: +$%d)" % _level_earned
	var wait_tween := create_tween()
	wait_tween.tween_interval(1.55)
	wait_tween.tween_callback(_fade_to_scene.bind(UPGRADE_SCENE_PATH))


func _fade_to_scene(scene_path: String) -> void:
	if _transitioning or not is_inside_tree():
		return
	_transitioning = true
	var fade_out := ColorRect.new()
	fade_out.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_out.size = Vector2(1600.0, 900.0)
	fade_out.position = Vector2(-160.0, -90.0)
	fade_out.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(fade_out)

	var t := create_tween()
	t.tween_property(fade_out, "color:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	t.tween_callback(func() -> void:
		if is_inside_tree():
			get_tree().change_scene_to_file(scene_path)
	)
