class_name PauseMenu
extends CanvasLayer

signal resumed
signal restart_requested
signal menu_requested
signal closed

const GAME_STATE := preload("res://scripts/game_state.gd")
const BTN_CONTINUE_TEX := preload("res://assets/btn_continue.png")
const BTN_RESTART_TEX := preload("res://assets/btn_restart.png")
const BTN_SETTINGS_TEX := preload("res://assets/btn_settings.png")
const BTN_MENU_TEX := preload("res://assets/btn_menu.png")
const BTN_BACK_TEX := preload("res://assets/btn_back.png")
const PAUSE_PANEL_TEX := preload("res://assets/pause_panel.png")
const TITLE_PAUSE_TEX := preload("res://assets/title_pause.png")
const SLIDER_GRABBER_TEX := preload("res://assets/slider_grabber.png")

var _is_open := false
var _settings_only := false
var _can_toggle_pause := true
var _open_tween: Tween = null

var _backdrop: ColorRect = null
var _panel_holder: Control = null
var _panel_bg: TextureRect = null
var _title_label: Label = null
var _pause_title_sprite: TextureRect = null

var _pause_page: VBoxContainer = null
var _resume_btn: TextureButton = null
var _restart_btn: TextureButton = null
var _settings_btn: TextureButton = null
var _menu_btn: TextureButton = null

var _settings_page: VBoxContainer = null
var _volume_title_lbl: Label = null
var _volume_slider: HSlider = null
var _back_btn: TextureButton = null
var _hint_label: Label = null


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	GAME_STATE.apply_audio_settings()
	_build_ui()


func set_can_toggle_pause(enabled: bool) -> void:
	_can_toggle_pause = enabled


func is_open() -> bool:
	return _is_open


func open_pause() -> void:
	if _is_open:
		return
	_settings_only = false
	_is_open = true
	get_tree().paused = true
	_show_pause_page()
	_animate_open()


func open_settings_only() -> void:
	if _is_open:
		return
	_settings_only = true
	_is_open = true
	_show_settings_page()
	_animate_open()


func close() -> void:
	if not _is_open:
		return
	_is_open = false
	if not _settings_only:
		get_tree().paused = false
	if _open_tween and _open_tween.is_running():
		_open_tween.kill()
	visible = false
	if _settings_only:
		closed.emit()
	else:
		resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if _is_open:
		get_viewport().set_input_as_handled()
		if _settings_page.visible and not _settings_only:
			_show_pause_page()
		else:
			close()
	elif _can_toggle_pause and not _settings_only:
		get_viewport().set_input_as_handled()
		open_pause()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.03, 0.03, 0.04, 0.68)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_panel_holder = Control.new()
	_panel_holder.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel_holder.custom_minimum_size = Vector2(400.0, 550.0)
	_panel_holder.offset_left = -200.0
	_panel_holder.offset_top = -275.0
	_panel_holder.offset_right = 200.0
	_panel_holder.offset_bottom = 275.0
	_panel_holder.pivot_offset = Vector2(200.0, 275.0)
	add_child(_panel_holder)

	_panel_bg = TextureRect.new()
	_panel_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_panel_bg.texture = PAUSE_PANEL_TEX
	_panel_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_panel_bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_panel_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_holder.add_child(_panel_bg)

	_title_label = Label.new()
	_title_label.position = Vector2(46.0, 54.0)
	_title_label.size = Vector2(308.0, 44.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.92, 0.86, 0.68, 1.0))
	_title_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_title_label.add_theme_constant_override("outline_size", 5)
	_title_label.text = "НАЛАШТУВАННЯ"
	_panel_holder.add_child(_title_label)

	_pause_title_sprite = TextureRect.new()
	_pause_title_sprite.position = Vector2(118.0, 58.0)
	_pause_title_sprite.size = Vector2(164.0, 42.0)
	_pause_title_sprite.texture = TITLE_PAUSE_TEX
	_pause_title_sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_pause_title_sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_pause_title_sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_holder.add_child(_pause_title_sprite)

	_pause_page = VBoxContainer.new()
	_pause_page.position = Vector2(74.0, 108.0)
	_pause_page.size = Vector2(252.0, 356.0)
	_pause_page.add_theme_constant_override("separation", 8)
	_pause_page.alignment = BoxContainer.ALIGNMENT_CENTER
	_panel_holder.add_child(_pause_page)

	_resume_btn = _create_sprite_button(BTN_CONTINUE_TEX)
	_resume_btn.pressed.connect(close)
	_pause_page.add_child(_resume_btn)

	_restart_btn = _create_sprite_button(BTN_RESTART_TEX)
	_restart_btn.pressed.connect(_on_restart_pressed)
	_pause_page.add_child(_restart_btn)

	_settings_btn = _create_sprite_button(BTN_SETTINGS_TEX)
	_settings_btn.pressed.connect(_show_settings_page)
	_pause_page.add_child(_settings_btn)

	_menu_btn = _create_sprite_button(BTN_MENU_TEX)
	_menu_btn.pressed.connect(_on_menu_pressed)
	_pause_page.add_child(_menu_btn)

	_settings_page = VBoxContainer.new()
	_settings_page.position = Vector2(68.0, 118.0)
	_settings_page.size = Vector2(264.0, 344.0)
	_settings_page.add_theme_constant_override("separation", 22)
	_settings_page.alignment = BoxContainer.ALIGNMENT_CENTER
	_settings_page.visible = false
	_panel_holder.add_child(_settings_page)

	_volume_title_lbl = Label.new()
	_volume_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_volume_title_lbl.add_theme_font_size_override("font_size", 20)
	_volume_title_lbl.add_theme_color_override("font_color", Color(0.94, 0.91, 0.82, 1.0))
	_volume_title_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.95))
	_volume_title_lbl.add_theme_constant_override("outline_size", 4)
	_settings_page.add_child(_volume_title_lbl)

	_volume_slider = _create_audio_slider()
	_volume_slider.value = GAME_STATE.master_volume
	_volume_slider.value_changed.connect(_on_volume_changed)
	_settings_page.add_child(_volume_slider)
	_update_volume_label(GAME_STATE.master_volume)

	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0.0, 20.0)
	_settings_page.add_child(spacer)

	_back_btn = _create_sprite_button(BTN_BACK_TEX)
	_back_btn.pressed.connect(_on_back_pressed)
	_settings_page.add_child(_back_btn)

	_hint_label = Label.new()
	_hint_label.position = Vector2(68.0, 472.0)
	_hint_label.size = Vector2(264.0, 22.0)
	_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hint_label.add_theme_font_size_override("font_size", 13)
	_hint_label.add_theme_color_override("font_color", Color(0.75, 0.74, 0.70, 0.85))
	_hint_label.text = "ESC — закрити"
	_panel_holder.add_child(_hint_label)


func _create_sprite_button(tex: Texture2D) -> TextureButton:
	var btn := TextureButton.new()
	btn.custom_minimum_size = Vector2(242.0, 66.0)
	btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	btn.pivot_offset = Vector2(121.0, 33.0)
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.texture_normal = tex
	btn.ignore_texture_size = true
	btn.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED

	btn.mouse_entered.connect(func() -> void:
		var t := create_tween().set_parallel(true)
		t.tween_property(btn, "scale", Vector2(1.05, 1.05), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "modulate", Color(1.12, 1.10, 1.04, 1.0), 0.12)
	)
	btn.mouse_exited.connect(func() -> void:
		var t := create_tween().set_parallel(true)
		t.tween_property(btn, "scale", Vector2.ONE, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(btn, "modulate", Color.WHITE, 0.12)
	)
	btn.button_down.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(0.95, 0.95), 0.06)
	)
	btn.button_up.connect(func() -> void:
		var t := create_tween()
		t.tween_property(btn, "scale", Vector2(1.04, 1.04), 0.08)
	)
	return btn


func _create_audio_slider() -> HSlider:
	var slider := HSlider.new()
	slider.custom_minimum_size = Vector2(246.0, 36.0)
	slider.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	var track_sb := StyleBoxFlat.new()
	track_sb.bg_color = Color(0.10, 0.10, 0.12, 0.98)
	track_sb.border_color = Color(0.55, 0.46, 0.28, 1.0)
	track_sb.set_border_width_all(2)
	track_sb.set_corner_radius_all(6)
	track_sb.content_margin_top = 6
	track_sb.content_margin_bottom = 6

	var fill_sb := StyleBoxFlat.new()
	fill_sb.bg_color = Color(0.76, 0.62, 0.30, 0.98)
	fill_sb.set_corner_radius_all(5)
	fill_sb.content_margin_top = 6
	fill_sb.content_margin_bottom = 6

	slider.add_theme_stylebox_override("slider", track_sb)
	slider.add_theme_stylebox_override("grabber_area", fill_sb)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_sb)
	slider.add_theme_icon_override("grabber", SLIDER_GRABBER_TEX)
	slider.add_theme_icon_override("grabber_highlight", SLIDER_GRABBER_TEX)
	return slider


func _show_pause_page() -> void:
	_title_label.visible = false
	_pause_title_sprite.visible = true
	_pause_page.visible = true
	_settings_page.visible = false


func _show_settings_page() -> void:
	_title_label.text = "НАЛАШТУВАННЯ"
	_title_label.visible = true
	_pause_title_sprite.visible = false
	_pause_page.visible = false
	_settings_page.visible = true
	if _volume_slider:
		_volume_slider.value = GAME_STATE.master_volume
		_update_volume_label(GAME_STATE.master_volume)


func _animate_open() -> void:
	visible = true
	_backdrop.modulate.a = 0.0
	_panel_holder.scale = Vector2(0.86, 0.86)
	_panel_holder.modulate.a = 0.0

	if _open_tween and _open_tween.is_running():
		_open_tween.kill()
	_open_tween = create_tween().set_parallel(true)
	_open_tween.tween_property(_backdrop, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_open_tween.tween_property(_panel_holder, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_open_tween.tween_property(_panel_holder, "modulate:a", 1.0, 0.18).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_volume_changed(val: float) -> void:
	GAME_STATE.set_master_volume(val)
	_update_volume_label(val)


func _update_volume_label(val: float) -> void:
	if _volume_title_lbl:
		_volume_title_lbl.text = "ГУЧНІСТЬ ЗВУКУ: %d%%" % int(roundf(val * 100.0))


func _on_back_pressed() -> void:
	if _settings_only:
		close()
	else:
		_show_pause_page()


func _on_restart_pressed() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false
	restart_requested.emit()


func _on_menu_pressed() -> void:
	_is_open = false
	visible = false
	get_tree().paused = false
	menu_requested.emit()
