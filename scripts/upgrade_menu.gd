class_name UpgradeMenu
extends Control

const BATTLE_SCENE_PATH := "res://scenes/main.tscn"

var _transitioning := false
var _hover_tween: Tween = null

@onready var level_label: Label = $PanelFrame/HeaderBar/LevelLabel
@onready var coins_label: Label = $PanelFrame/HeaderBar/CoinsLabel
@onready var earned_label: Label = $PanelFrame/BodyBox/EarnedLabel
@onready var next_button: TextureButton = $NextButton
@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	if level_label:
		level_label.text = "РІВЕНЬ %d / %d" % [GameState.current_level, GameState.TOTAL_LEVELS]
	if coins_label:
		coins_label.text = "МОНЕТИ: $%d" % GameState.coins
	if earned_label:
		if GameState.last_level_earned > 0:
			earned_label.text = "Зароблено за попередній бій: +$%d" % GameState.last_level_earned
			earned_label.visible = true
		else:
			earned_label.visible = false

	if next_button:
		next_button.pivot_offset = next_button.size * 0.5
		next_button.pressed.connect(_on_next_pressed)
		next_button.mouse_entered.connect(_on_next_mouse_entered)
		next_button.mouse_exited.connect(_on_next_mouse_exited)
		next_button.button_down.connect(_on_next_button_down)
		next_button.button_up.connect(_on_next_button_up)

	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)
		var intro_tween := create_tween()
		intro_tween.tween_property(fade_overlay, "color:a", 0.0, 0.42).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if not _transitioning and event.is_action_pressed("ui_accept"):
		_on_next_pressed()


func _on_next_mouse_entered() -> void:
	if _transitioning or next_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(next_button, "scale", Vector2(1.06, 1.06), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(next_button, "modulate", Color(1.12, 1.10, 1.04, 1.0), 0.14)


func _on_next_mouse_exited() -> void:
	if _transitioning or next_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween().set_parallel(true)
	_hover_tween.tween_property(next_button, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_hover_tween.tween_property(next_button, "modulate", Color.WHITE, 0.14)


func _on_next_button_down() -> void:
	if _transitioning or next_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(next_button, "scale", Vector2(0.95, 0.95), 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _on_next_button_up() -> void:
	if _transitioning or next_button == null:
		return
	if _hover_tween and _hover_tween.is_running():
		_hover_tween.kill()
	_hover_tween = create_tween()
	_hover_tween.tween_property(next_button, "scale", Vector2(1.04, 1.04), 0.09).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _on_next_pressed() -> void:
	if _transitioning:
		return
	_transitioning = true
	if next_button:
		next_button.disabled = true

	if fade_overlay:
		fade_overlay.visible = true
		var fade_tween := create_tween()
		fade_tween.tween_property(fade_overlay, "color:a", 1.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		fade_tween.tween_callback(_start_battle_scene)
	else:
		_start_battle_scene()


func _start_battle_scene() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE_PATH)
