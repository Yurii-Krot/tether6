class_name MainMenu
extends Control

const GAME_SCENE_PATH := "res://scenes/main.tscn"

var _transitioning := false
var _hover_tween: Tween = null

@onready var play_button: TextureButton = $PlayButton
@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	if play_button:
		play_button.pivot_offset = play_button.size * 0.5
		play_button.pressed.connect(_on_play_pressed)
		play_button.mouse_entered.connect(_on_play_mouse_entered)
		play_button.mouse_exited.connect(_on_play_mouse_exited)
		play_button.button_down.connect(_on_play_button_down)
		play_button.button_up.connect(_on_play_button_up)

	# Плавна поява головного меню при запуску
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		var intro_tween := create_tween()
		intro_tween.tween_property(fade_overlay, "color:a", 0.0, 0.45).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
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
	get_tree().change_scene_to_file(GAME_SCENE_PATH)
