extends Node2D

var _game_over := false
var _elapsed_time := 0.0

@onready var wave_manager: WaveManager = $WaveManager
@onready var player: Node2D = $Player
@onready var wave_label: Label = $UI/WaveLabel
@onready var banner_label: Label = $UI/BannerLabel


func _ready() -> void:
	wave_manager.wave_started.connect(_on_wave_started)
	wave_manager.wave_cleared.connect(_on_wave_cleared)
	wave_manager.all_waves_cleared.connect(_on_all_waves_cleared)
	if player.has_signal("died"):
		player.connect("died", _on_player_died)

	# Плавний вихід із чорного затемнення після переходу з головного меню
	var fade_in := ColorRect.new()
	fade_in.color = Color(0.0, 0.0, 0.0, 1.0)
	fade_in.size = Vector2(1600.0, 900.0)
	fade_in.position = Vector2(-160.0, -90.0)
	fade_in.mouse_filter = Control.MOUSE_FILTER_IGNORE
	$UI.add_child(fade_in)
	var tween := create_tween()
	tween.tween_property(fade_in, "color:a", 0.0, 0.48).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_callback(fade_in.queue_free)


func _process(delta: float) -> void:
	if not _game_over:
		_elapsed_time += delta
	elif Input.is_action_just_pressed("ui_accept"):
		get_tree().reload_current_scene()


func _on_wave_started(wave_number: int) -> void:
	if _game_over:
		return
	wave_label.text = "Хвиля: %d / %d" % [wave_number, wave_manager.waves.size()]
	banner_label.text = ""


func _on_wave_cleared() -> void:
	if _game_over:
		return
	banner_label.modulate = Color(0.75, 1.0, 0.75, 1.0)
	banner_label.text = "Хвилю %d зачищено!" % wave_manager.get_current_wave_number()


func _on_all_waves_cleared() -> void:
	_game_over = true
	var mins := int(_elapsed_time) / 60
	var secs := int(_elapsed_time) % 60
	banner_label.modulate = Color(1.0, 0.92, 0.4, 1.0)
	banner_label.text = "ПЕРЕМОГА! Всі 3 хвилі пройдено за %d:%02d\n[Enter — грати знову]" % [mins, secs]


func _on_player_died() -> void:
	_game_over = true
	banner_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
	banner_label.text = "ПОРАЗКА! Гравець загинув\n[Enter — спробувати знову]"
