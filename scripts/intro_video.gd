class_name IntroVideo
extends Control

const GAME_STATE := preload("res://scripts/game_state.gd")
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const INTRO_STREAM_PATH := "res://assets/nulestek_intro.ogv"

const FADE_IN_DURATION := 0.22
const FADE_OUT_START_SEC := 12.15
const NATURAL_FADE_OUT_DURATION := 1.10
const SKIP_FADE_OUT_DURATION := 0.45

@onready var video_player: VideoStreamPlayer = $VideoContainer/VideoPlayer
@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_transitioning: bool = false
var _elapsed: float = 0.0
var _active_tween: Tween = null


func _ready() -> void:
	GAME_STATE.apply_audio_settings()
	if fade_overlay:
		fade_overlay.visible = true
		fade_overlay.color = Color(0.0, 0.0, 0.0, 1.0)

	if video_player == null:
		_enter_main_menu()
		return

	var stream_res := ResourceLoader.load(INTRO_STREAM_PATH) as VideoStream
	if stream_res == null:
		_enter_main_menu()
		return

	video_player.stream = stream_res
	video_player.volume_db = 0.0
	video_player.finished.connect(_on_video_finished)
	video_player.play()

	# Коротка плавна поява після старту декодування першого кадру
	if fade_overlay:
		_active_tween = create_tween()
		_active_tween.tween_property(fade_overlay, "color:a", 0.0, FADE_IN_DURATION).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_elapsed += delta
	if _is_transitioning or video_player == null:
		return
	if video_player.is_playing() and video_player.stream_position >= FADE_OUT_START_SEC:
		_begin_fade_out_to_menu(NATURAL_FADE_OUT_DURATION)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning or _elapsed < 0.2:
		return
	var wants_skip := false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT:
			wants_skip = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ESCAPE, KEY_SPACE, KEY_ENTER, KEY_KP_ENTER]:
			wants_skip = true
	if wants_skip:
		get_viewport().set_input_as_handled()
		_begin_fade_out_to_menu(SKIP_FADE_OUT_DURATION)


func _on_video_finished() -> void:
	if not _is_transitioning:
		_begin_fade_out_to_menu(NATURAL_FADE_OUT_DURATION * 0.65)


func _begin_fade_out_to_menu(duration: float) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	if _active_tween and _active_tween.is_running():
		_active_tween.kill()

	_active_tween = create_tween().set_parallel(true)
	if fade_overlay:
		fade_overlay.visible = true
		_active_tween.tween_property(fade_overlay, "color:a", 1.0, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if video_player:
		_active_tween.tween_property(video_player, "volume_db", -45.0, duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_active_tween.chain().tween_callback(_enter_main_menu)


func _enter_main_menu() -> void:
	if video_player and video_player.is_playing():
		video_player.stop()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
