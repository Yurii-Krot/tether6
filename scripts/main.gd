extends Node2D

const GAME_STATE := preload("res://scripts/game_state.gd")
const PAUSE_MENU_SCRIPT := preload("res://scripts/pause_menu.gd")
const BATTLE_BGM_STREAM := preload("res://assets/battle_bgm.mp3")
const BOSS_BGM_STREAM := preload("res://assets/boss_bgm.mp3")
const UPGRADE_SCENE_PATH := "res://scenes/upgrade_menu.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const PROGRESS_TRACK_WIDTH := 356.0
const PROGRESS_TRACK_HEIGHT := 14.0

var _game_over := false
var _transitioning := false
var _campaign_won := false
var _elapsed_time := 0.0
var _level_earned := 0
var _bgm_player: AudioStreamPlayer = null
var _pause_menu: PauseMenu = null
var _pause_hud_btn: Button = null

# Смужка прогресу рівня з повзунком справа зверху
var _progress_panel: ColorRect = null
var _progress_title_label: Label = null
var _progress_fill: ColorRect = null
var _progress_ticks_container: Control = null
var _progress_slider_thumb: Node2D = null
var _displayed_progress := 0.0

@onready var wave_manager: WaveManager = $WaveManager
@onready var player: Node2D = $Player
@onready var wave_label: Label = $UI/WaveLabel
@onready var banner_label: Label = $UI/BannerLabel


func _ready() -> void:
	_level_earned = 0
	GAME_STATE.apply_audio_settings()
	_start_battle_bgm()
	_create_top_right_progress_bar()
	_create_pause_hud_button()
	_setup_pause_menu()
	_update_hud()

	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.subwave_changed.connect(_on_subwave_changed)
	wave_manager.boss_fight_started.connect(_on_boss_fight_started)
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
	_update_progress_bar(delta)
	if not _game_over:
		_elapsed_time += delta
	elif not _transitioning and Input.is_action_just_pressed("ui_accept"):
		if _campaign_won:
			GAME_STATE.reset_campaign()
			_fade_to_scene(MAIN_MENU_SCENE_PATH)
		else:
			_fade_to_scene(UPGRADE_SCENE_PATH)


func _create_top_right_progress_bar() -> void:
	var panel_border := ColorRect.new()
	panel_border.position = Vector2(874.0, 10.0)
	panel_border.size = Vector2(390.0, 54.0)
	panel_border.color = Color(0.24, 0.27, 0.32, 0.90)
	panel_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(panel_border)

	_progress_panel = ColorRect.new()
	_progress_panel.position = Vector2(876.0, 12.0)
	_progress_panel.size = Vector2(386.0, 50.0)
	_progress_panel.color = Color(0.06, 0.07, 0.09, 0.86)
	_progress_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(_progress_panel)

	_progress_title_label = Label.new()
	_progress_title_label.position = Vector2(12.0, 4.0)
	_progress_title_label.size = Vector2(362.0, 20.0)
	_progress_title_label.add_theme_font_size_override("font_size", 13)
	_progress_title_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.98, 1.0))
	_progress_title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_progress_title_label.add_theme_constant_override("outline_size", 3)
	_progress_title_label.text = "ПРОГРЕС РІВНЯ  |  Хвиля 1/3  |  Залишилось: 0"
	_progress_panel.add_child(_progress_title_label)

	var track_border := ColorRect.new()
	track_border.position = Vector2(13.0, 27.0)
	track_border.size = Vector2(PROGRESS_TRACK_WIDTH + 4.0, PROGRESS_TRACK_HEIGHT + 4.0)
	track_border.color = Color(0.02, 0.02, 0.03, 0.96)
	track_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_panel.add_child(track_border)

	var track_bg := ColorRect.new()
	track_bg.position = Vector2(15.0, 29.0)
	track_bg.size = Vector2(PROGRESS_TRACK_WIDTH, PROGRESS_TRACK_HEIGHT)
	track_bg.color = Color(0.16, 0.18, 0.23, 0.96)
	track_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress_panel.add_child(track_bg)

	_progress_fill = ColorRect.new()
	_progress_fill.position = Vector2(0.0, 0.0)
	_progress_fill.size = Vector2(0.0, PROGRESS_TRACK_HEIGHT)
	_progress_fill.color = Color(0.92, 0.68, 0.18, 0.96)
	_progress_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_bg.add_child(_progress_fill)

	var top_shine := ColorRect.new()
	top_shine.position = Vector2(0.0, 0.0)
	top_shine.size = Vector2(PROGRESS_TRACK_WIDTH, 4.0)
	top_shine.color = Color(1.0, 1.0, 1.0, 0.12)
	top_shine.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_bg.add_child(top_shine)

	_progress_ticks_container = Control.new()
	_progress_ticks_container.position = Vector2.ZERO
	_progress_ticks_container.size = Vector2(PROGRESS_TRACK_WIDTH, PROGRESS_TRACK_HEIGHT)
	_progress_ticks_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track_bg.add_child(_progress_ticks_container)

	# Повзунок (slider thumb), який рухається вздовж полоски прогресу рівня
	_progress_slider_thumb = Node2D.new()
	_progress_slider_thumb.position = Vector2(0.0, PROGRESS_TRACK_HEIGHT * 0.5)
	_progress_slider_thumb.z_index = 5
	track_bg.add_child(_progress_slider_thumb)

	var thumb_outer := Polygon2D.new()
	thumb_outer.color = Color(0.05, 0.06, 0.08, 0.98)
	thumb_outer.polygon = PackedVector2Array([
		Vector2(-7.0, -11.0),
		Vector2(7.0, -11.0),
		Vector2(7.0, 6.0),
		Vector2(0.0, 12.0),
		Vector2(-7.0, 6.0),
	])
	_progress_slider_thumb.add_child(thumb_outer)

	var thumb_inner := Polygon2D.new()
	thumb_inner.color = Color(1.0, 0.92, 0.38, 1.0)
	thumb_inner.polygon = PackedVector2Array([
		Vector2(-5.0, -9.0),
		Vector2(5.0, -9.0),
		Vector2(5.0, 5.0),
		Vector2(0.0, 9.5),
		Vector2(-5.0, 5.0),
	])
	_progress_slider_thumb.add_child(thumb_inner)

	var thumb_core := Polygon2D.new()
	thumb_core.color = Color(1.0, 1.0, 1.0, 0.95)
	thumb_core.polygon = PackedVector2Array([
		Vector2(-2.0, -6.0),
		Vector2(2.0, -6.0),
		Vector2(2.0, 3.0),
		Vector2(-2.0, 3.0),
	])
	_progress_slider_thumb.add_child(thumb_core)


func _rebuild_wave_ticks() -> void:
	if _progress_ticks_container == null or wave_manager == null:
		return
	for child in _progress_ticks_container.get_children():
		child.queue_free()

	for ratio in wave_manager.subwave_ratios:
		var tick := ColorRect.new()
		tick.position = Vector2(roundf(ratio * PROGRESS_TRACK_WIDTH) - 1.0, -2.0)
		tick.size = Vector2(2.0, PROGRESS_TRACK_HEIGHT + 4.0)
		tick.color = Color(0.95, 0.95, 0.98, 0.72)
		tick.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_progress_ticks_container.add_child(tick)


func _update_progress_bar(delta: float) -> void:
	if wave_manager == null or _progress_fill == null or _progress_slider_thumb == null:
		return

	var target_ratio := wave_manager.get_level_progress_ratio()
	_displayed_progress = lerpf(_displayed_progress, target_ratio, minf(delta * 8.5, 1.0))
	if absf(target_ratio - _displayed_progress) < 0.002:
		_displayed_progress = target_ratio

	var fill_w := clampf(_displayed_progress * PROGRESS_TRACK_WIDTH, 0.0, PROGRESS_TRACK_WIDTH)
	_progress_fill.size.x = fill_w
	_progress_fill.color = Color(0.92, 0.65, 0.18, 0.96).lerp(Color(0.24, 0.88, 0.42, 0.96), _displayed_progress)
	_progress_slider_thumb.position.x = fill_w

	if _progress_title_label:
		var rem := wave_manager.get_remaining_enemies_count()
		var pct := int(roundf(_displayed_progress * 100.0))
		if wave_manager.is_boss_fight_active():
			_progress_title_label.text = "БОС-ФАЙТ!  |  Ворогів на полі: %d" % rem
			_progress_fill.color = Color(0.95, 0.22, 0.18, 0.96)
		else:
			_progress_title_label.text = "ДО КІНЦЯ РІВНЯ: %d%%  |  Хвиля %d/%d  |  Ворогів: %d" % [
				pct,
				wave_manager.current_subwave,
				wave_manager.total_subwaves,
				rem
			]


func _update_hud() -> void:
	if wave_label:
		wave_label.text = "Рівень: %d / %d   |   Монети: $%d" % [GAME_STATE.current_level, GAME_STATE.TOTAL_LEVELS, GAME_STATE.coins]


func _on_wave_started(_wave_number: int) -> void:
	if _game_over:
		return
	_displayed_progress = 0.0
	_rebuild_wave_ticks()
	_update_hud()
	banner_label.text = ""


func _on_subwave_changed(_subwave_num: int, _total_subwaves: int) -> void:
	_update_hud()


func _on_boss_fight_started() -> void:
	if _game_over:
		return
	_switch_to_boss_bgm()
	banner_label.modulate = Color(1.0, 0.32, 0.24, 1.0)
	banner_label.text = "УВАГА! БОС ВИХОДИТЬ НА ПОЛЕ БОЮ!"
	var t := create_tween()
	t.tween_interval(2.2)
	t.tween_callback(func() -> void:
		if not _game_over and banner_label:
			banner_label.text = ""
	)


func _switch_to_boss_bgm() -> void:
	var boss_stream: AudioStream = BOSS_BGM_STREAM
	if boss_stream is AudioStreamMP3:
		(boss_stream as AudioStreamMP3).loop = true
	if _bgm_player != null and is_instance_valid(_bgm_player):
		_bgm_player.stop()
		_bgm_player.stream = boss_stream
		_bgm_player.volume_db = -8.0
		_bgm_player.play()


func _on_enemy_killed(_unit_type: String, world_pos: Vector2, reward: int) -> void:
	GAME_STATE.coins += reward
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

	var clear_bonus := int(GAME_STATE.get_current_level_data().get("reward", 50))
	GAME_STATE.coins += clear_bonus
	_level_earned += clear_bonus
	GAME_STATE.last_level_earned = _level_earned
	_update_hud()

	var finished_level := GAME_STATE.current_level
	if finished_level < GAME_STATE.TOTAL_LEVELS:
		GAME_STATE.current_level += 1
		banner_label.modulate = Color(0.75, 1.0, 0.75, 1.0)
		banner_label.text = "РІВЕНЬ %d ПРОЙДЕНО!\nЗароблено за бій: +$%d" % [finished_level, _level_earned]
		var wait_tween := create_tween()
		wait_tween.tween_interval(1.35)
		wait_tween.tween_callback(_fade_to_scene.bind(UPGRADE_SCENE_PATH))
	else:
		_campaign_won = true
		GAME_STATE.current_level = GAME_STATE.TOTAL_LEVELS + 1
		banner_label.modulate = Color(1.0, 0.92, 0.4, 1.0)
		banner_label.text = "ПЕРЕМОГА! Всі %d рівнів пройдено!\nЗагальний баланс: $%d\n[Enter — у головне меню]" % [GAME_STATE.TOTAL_LEVELS, GAME_STATE.coins]


func _on_player_died() -> void:
	if _game_over:
		return
	_game_over = true
	GAME_STATE.last_level_earned = _level_earned
	banner_label.modulate = Color(1.0, 0.42, 0.42, 1.0)
	banner_label.text = "ПОРАЗКА! Відступаємо у вікно покращень...\n(Зароблено: +$%d)" % _level_earned
	var wait_tween := create_tween()
	wait_tween.tween_interval(1.55)
	wait_tween.tween_callback(_fade_to_scene.bind(UPGRADE_SCENE_PATH))


func _start_battle_bgm() -> void:
	var bgm_stream: AudioStream = BATTLE_BGM_STREAM
	if bgm_stream is AudioStreamMP3:
		(bgm_stream as AudioStreamMP3).loop = true
	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.name = "BattleBGM"
	_bgm_player.stream = bgm_stream
	_bgm_player.volume_db = -9.5
	_bgm_player.finished.connect(_on_bgm_finished)
	add_child(_bgm_player)
	_bgm_player.play()


func _on_bgm_finished() -> void:
	if not _transitioning and _bgm_player != null and is_inside_tree():
		_bgm_player.play()


func _exit_tree() -> void:
	if is_inside_tree() and get_tree():
		get_tree().paused = false
	if _bgm_player != null and is_instance_valid(_bgm_player):
		_bgm_player.stop()
		_bgm_player.stream = null


func _setup_pause_menu() -> void:
	_pause_menu = PAUSE_MENU_SCRIPT.new()
	add_child(_pause_menu)
	_pause_menu.restart_requested.connect(_on_pause_restart_requested)
	_pause_menu.menu_requested.connect(_on_pause_menu_requested)


func _create_pause_hud_button() -> void:
	_pause_hud_btn = Button.new()
	_pause_hud_btn.position = Vector2(1166.0, 70.0)
	_pause_hud_btn.size = Vector2(96.0, 30.0)
	_pause_hud_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_pause_hud_btn.focus_mode = Control.FOCUS_NONE
	_pause_hud_btn.text = "|| ПАУЗА"
	_pause_hud_btn.add_theme_font_size_override("font_size", 13)
	_pause_hud_btn.add_theme_color_override("font_color", Color(0.92, 0.88, 0.76, 1.0))

	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.10, 0.11, 0.13, 0.90)
	sb.border_color = Color(0.62, 0.53, 0.34, 0.95)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(6)

	var sb_hover := sb.duplicate()
	sb_hover.bg_color = Color(0.18, 0.18, 0.20, 0.96)
	sb_hover.border_color = Color(0.84, 0.74, 0.48, 1.0)

	_pause_hud_btn.add_theme_stylebox_override("normal", sb)
	_pause_hud_btn.add_theme_stylebox_override("hover", sb_hover)
	_pause_hud_btn.add_theme_stylebox_override("pressed", sb)
	_pause_hud_btn.pressed.connect(func() -> void:
		if _pause_menu and not _game_over and not _transitioning:
			_pause_menu.open_pause()
	)
	$UI.add_child(_pause_hud_btn)


func _on_pause_restart_requested() -> void:
	_fade_to_scene("res://scenes/main.tscn")


func _on_pause_menu_requested() -> void:
	_fade_to_scene(MAIN_MENU_SCENE_PATH)


func _fade_to_scene(scene_path: String) -> void:
	if _transitioning or not is_inside_tree():
		return
	_transitioning = true
	if _pause_menu:
		_pause_menu.set_can_toggle_pause(false)
	if _pause_hud_btn:
		_pause_hud_btn.visible = false
	get_tree().paused = false
	var fade_out := ColorRect.new()
	fade_out.color = Color(0.0, 0.0, 0.0, 0.0)
	fade_out.size = Vector2(1600.0, 900.0)
	fade_out.position = Vector2(-160.0, -90.0)
	fade_out.mouse_filter = Control.MOUSE_FILTER_STOP
	$UI.add_child(fade_out)

	var t := create_tween()
	t.set_parallel(true)
	t.tween_property(fade_out, "color:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if _bgm_player != null and is_instance_valid(_bgm_player):
		t.tween_property(_bgm_player, "volume_db", -40.0, 0.45)
	t.chain().tween_callback(func() -> void:
		if _bgm_player != null and is_instance_valid(_bgm_player):
			_bgm_player.stop()
		if is_inside_tree():
			get_tree().change_scene_to_file(scene_path)
	)
