class_name MainMenu
extends Control

const GAME_STATE := preload("res://scripts/game_state.gd")
const PAUSE_MENU_SCRIPT := preload("res://scripts/pause_menu.gd")
const UPGRADE_SCENE_PATH := "res://scenes/upgrade_menu.tscn"
const BATTLE_SCENE_PATH := "res://scenes/main.tscn"

var _transitioning := false
var _hover_tween: Tween = null
var _settings_hover_tween: Tween = null
var _settings_popup: PauseMenu = null
var _test_boss_btn: Button = null
var _test_lvl10_btn: Button = null

@onready var play_button: TextureButton = $PlayButton
@onready var settings_button: TextureButton = $SettingsButton
@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	GAME_STATE.apply_audio_settings()

	_settings_popup = PAUSE_MENU_SCRIPT.new()
	_settings_popup.set_can_toggle_pause(false)
	add_child(_settings_popup)

	if play_button:
		play_button.pivot_offset = play_button.size * 0.5
		play_button.pressed.connect(_on_play_pressed)
		play_button.mouse_entered.connect(_on_play_mouse_entered)
		play_button.mouse_exited.connect(_on_play_mouse_exited)
		play_button.button_down.connect(_on_play_button_down)
		play_button.button_up.connect(_on_play_button_up)

	if settings_button:
		settings_button.pivot_offset = settings_button.size * 0.5
		settings_button.pressed.connect(_on_settings_pressed)
		settings_button.mouse_entered.connect(_on_settings_mouse_entered)
		settings_button.mouse_exited.connect(_on_settings_mouse_exited)
		settings_button.button_down.connect(_on_settings_button_down)
		settings_button.button_up.connect(_on_settings_button_up)

	_create_test_level_buttons()

	# Плавна поява головного меню при запуску
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		var intro_tween := create_tween()
		intro_tween.tween_property(fade_overlay, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if _settings_popup and _settings_popup.is_open():
		return
	if not _transitioning and event.is_action_pressed("ui_accept"):
		_on_play_pressed()


func _on_play_mouse_entered() -> void:
	if _transitioning or play_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(play_button, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(play_button, "modulate", Color(1.12, 1.10, 1.04, 1.0), 0.14)


func _on_play_mouse_exited() -> void:
	if _transitioning or play_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(play_button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(play_button, "modulate", Color.WHITE, 0.14)


func _on_play_button_down() -> void:
	if _transitioning or play_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(play_button, "scale", Vector2(0.95, 0.95), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_play_button_up() -> void:
	if _transitioning or play_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(play_button, "scale", Vector2(1.04, 1.04), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_play_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	GAME_STATE.test_skip_to_boss = false
	if play_button:
		play_button.disabled = true
	if _test_boss_btn:
		_test_boss_btn.disabled = true
	if _test_lvl10_btn:
		_test_lvl10_btn.disabled = true
	_fade_to_scene(_start_game_scene)


func _create_test_level_buttons() -> void:
	var box := VBoxContainer.new()
	box.name = "TestLevel10Box"
	box.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	box.offset_left = -286.0
	box.offset_top = 24.0
	box.offset_right = -24.0
	box.offset_bottom = 128.0
	box.add_theme_constant_override("separation", 8)
	add_child(box)
	if fade_overlay:
		move_child(box, fade_overlay.get_index())

	_test_boss_btn = GAME_STATE.create_test_button("ТЕСТ: БОС 10 РІВНЯ", Color(0.46, 0.16, 0.14, 0.94))
	_test_boss_btn.custom_minimum_size = Vector2(262.0, 44.0)
	_test_boss_btn.pressed.connect(_on_test_level_10_pressed.bind(true))
	box.add_child(_test_boss_btn)

	_test_lvl10_btn = GAME_STATE.create_test_button("ТЕСТ: 10 РІВЕНЬ (ХВИЛЯ)", Color(0.20, 0.25, 0.17, 0.94))
	_test_lvl10_btn.custom_minimum_size = Vector2(262.0, 44.0)
	_test_lvl10_btn.pressed.connect(_on_test_level_10_pressed.bind(false))
	box.add_child(_test_lvl10_btn)


func _on_test_level_10_pressed(skip_to_boss: bool) -> void:
	if _transitioning:
		return
	_transitioning = true
	if play_button:
		play_button.disabled = true
	if _test_boss_btn:
		_test_boss_btn.disabled = true
	if _test_lvl10_btn:
		_test_lvl10_btn.disabled = true
	GAME_STATE.jump_to_test_level_10(skip_to_boss)
	_fade_to_scene(_start_test_battle_scene)


func _fade_to_scene(on_done: Callable) -> void:
	if fade_overlay:
		fade_overlay.visible = true
		var fade_tween := create_tween()
		fade_tween.tween_property(fade_overlay, "color:a", 1.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_callback(on_done)
	else:
		on_done.call()


func _start_game_scene() -> void:
	if GAME_STATE.current_level > GAME_STATE.TOTAL_LEVELS or GAME_STATE.current_level < 1:
		GAME_STATE.reset_campaign()
	get_tree().change_scene_to_file(UPGRADE_SCENE_PATH)


func _start_test_battle_scene() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)


func _on_settings_pressed() -> void:
	if _transitioning or _settings_popup == null:
		return
	_settings_popup.open_settings_only()


func _on_settings_mouse_entered() -> void:
	if _transitioning or settings_button == null:
		return
	if _settings_hover_tween and _settings_hover_tween.is_running():
		_settings_hover_tween.kill()
	_settings_hover_tween = create_tween().set_parallel(true)
	_settings_hover_tween.tween_property(settings_button, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_settings_hover_tween.tween_property(settings_button, "modulate", Color(1.12, 1.10, 1.04, 1.0), 0.14)


func _on_settings_mouse_exited() -> void:
	if _transitioning or settings_button == null:
		return
	if _settings_hover_tween and _settings_hover_tween.is_running():
		_settings_hover_tween.kill()
	_settings_hover_tween = create_tween().set_parallel(true)
	_settings_hover_tween.tween_property(settings_button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_settings_hover_tween.tween_property(settings_button, "modulate", Color.WHITE, 0.14)


func _on_settings_button_down() -> void:
	if _transitioning or settings_button == null:
		return
	if _settings_hover_tween and _settings_hover_tween.is_running():
		_settings_hover_tween.kill()
	_settings_hover_tween = create_tween()
	_settings_hover_tween.tween_property(settings_button, "scale", Vector2(0.95, 0.95), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_settings_button_up() -> void:
	if _transitioning or settings_button == null:
		return
	if _settings_hover_tween and _settings_hover_tween.is_running():
		_settings_hover_tween.kill()
	_settings_hover_tween = create_tween()
	_settings_hover_tween.tween_property(settings_button, "scale", Vector2(1.04, 1.04), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
