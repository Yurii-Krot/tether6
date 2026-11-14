class_name MainMenu
extends Control

const GAME_STATE := preload("res://scripts/game_state.gd")
const PAUSE_MENU_SCRIPT := preload("res://scripts/pause_menu.gd")
const UPGRADE_SCENE_PATH := "res://scenes/upgrade_menu.tscn"

var _transitioning := false
var _hover_tween: Tween = null
var _settings_hover_tween: Tween = null
var _settings_popup: PauseMenu = null

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
	if play_button:
		play_button.disabled = true

	if fade_overlay:
		fade_overlay.visible = true
		var fade_tween := create_tween()
		fade_tween.tween_property(fade_overlay, "color:a", 1.0, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_callback(_start_game_scene)
	else:
		_start_game_scene()


func _start_game_scene() -> void:
	if GAME_STATE.current_level > GAME_STATE.TOTAL_LEVELS or GAME_STATE.current_level < 1:
		GAME_STATE.reset_campaign()
	get_tree().change_scene_to_file(UPGRADE_SCENE_PATH)


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
