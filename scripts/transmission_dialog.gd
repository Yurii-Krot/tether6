class_name TransmissionDialog
extends CanvasLayer

signal finished

const MAX_SLOTS := 3
const TYPEWRITER_CPS := 72.0

const COLOR_CHASSIS := Color(0.651, 0.616, 0.420, 1.0)
const COLOR_CHASSIS_HI := Color(0.765, 0.729, 0.525, 1.0)
const COLOR_CHASSIS_LO := Color(0.506, 0.471, 0.294, 1.0)
const COLOR_CHASSIS_DARK := Color(0.369, 0.345, 0.212, 1.0)
const COLOR_OUTLINE := Color(0.067, 0.075, 0.086, 1.0)
const COLOR_WELL_BG := Color(0.239, 0.251, 0.224, 1.0)
const COLOR_WELL_SHADOW := Color(0.145, 0.153, 0.137, 1.0)
const COLOR_STEEL := Color(0.588, 0.596, 0.565, 1.0)
const COLOR_STEEL_HI := Color(0.718, 0.725, 0.694, 1.0)
const COLOR_STEEL_LO := Color(0.412, 0.420, 0.392, 1.0)
const COLOR_CRT_BG := Color(0.024, 0.027, 0.035, 1.0)

var _messages: Array[Dictionary] = []
var _revealed_count: int = 0
var _window_start: int = 0
var _active_slot: int = -1
var _typing_chars: float = 0.0
var _typing_target: int = 0
var _is_closing: bool = false

var _backdrop: ColorRect
var _panel_root: Control
var _chassis: Control
var _title_label: Label
var _slot_rows: Array[TransmissionSlot] = []
var _skip_btn: Button
var _next_btn: Button

var _portraits: Dictionary = {}
var _sfx_player: AudioStreamPlayer
var _blip_next_stream: AudioStreamWAV
var _blip_skip_stream: AudioStreamWAV


func _ready() -> void:
	layer = 18
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_portraits()
	_init_audio()
	_build_ui()
	_center_panel()
	if _messages.size() > 0:
		_begin_sequence()


func setup(messages: Array[Dictionary], title_text: String = "ПЕРЕХОПЛЕНІ ПЕРЕГОВОРИ") -> void:
	_messages.clear()
	for entry in messages:
		_messages.append(entry.duplicate(true))
	if is_instance_valid(_title_label):
		_title_label.text = title_text
		_begin_sequence()


func get_visible_slot_texts() -> Array[String]:
	var result: Array[String] = []
	for slot in _slot_rows:
		result.append(slot.get_message_text())
	return result


func get_visible_slot_speakers() -> Array[String]:
	var result: Array[String] = []
	for slot in _slot_rows:
		result.append(slot.get_speaker())
	return result


func get_next_button_text() -> String:
	return _next_btn.text if is_instance_valid(_next_btn) else ""


func is_typing() -> bool:
	return _active_slot >= 0 and _typing_chars < float(_typing_target)


func advance_or_complete(instant_complete: bool = false) -> void:
	if _is_closing:
		return
	if _messages.is_empty():
		_finish_dialog(true)
		return
	if is_typing():
		_typing_chars = float(_typing_target)
		_slot_rows[_active_slot].set_visible_chars(_typing_target)
		if not instant_complete:
			_play_sfx(_blip_next_stream, -12.0)
			return
	if _revealed_count >= _messages.size():
		_finish_dialog(false)
		return
	_play_sfx(_blip_next_stream, -10.0)
	_reveal_next_message()


func skip_dialog() -> void:
	if _is_closing:
		return
	_play_sfx(_blip_skip_stream, -10.0)
	_finish_dialog(true)


func _process(delta: float) -> void:
	if _is_closing or _active_slot < 0:
		return
	if _typing_chars < float(_typing_target):
		_typing_chars = minf(_typing_chars + TYPEWRITER_CPS * delta, float(_typing_target))
		_slot_rows[_active_slot].set_visible_chars(int(floor(_typing_chars)))


func _unhandled_input(event: InputEvent) -> void:
	if _is_closing:
		return
	if event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		advance_or_complete(false)
	elif event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		skip_dialog()


func _load_portraits() -> void:
	var hero_path := "res://assets/portrait_hero.png"
	match GameState.hero_skin:
		"shades_gold":
			hero_path = "res://assets/portrait_hero_shades_gold.png"
		"shades_cyber":
			hero_path = "res://assets/portrait_hero_shades_cyber.png"
		"shades_black":
			hero_path = "res://assets/portrait_hero_shades_black.png"
	var hero_tex := ResourceLoader.load(hero_path) as Texture2D
	var enemy_tex := ResourceLoader.load("res://assets/portrait_enemy_gray.png") as Texture2D
	_portraits["hero"] = hero_tex
	_portraits["enemy"] = enemy_tex


func _init_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_sfx_player = AudioStreamPlayer.new()
	_sfx_player.process_mode = Node.PROCESS_MODE_ALWAYS
	if AudioServer.get_bus_index("SFX") != -1:
		_sfx_player.bus = "SFX"
	add_child(_sfx_player)
	_blip_next_stream = _make_radio_blip(680.0, 920.0, 0.055)
	_blip_skip_stream = _make_radio_blip(520.0, 320.0, 0.065)


func _make_radio_blip(freq_a: float, freq_b: float, dur: float) -> AudioStreamWAV:
	var mix_rate := 22050
	var count := int(dur * float(mix_rate))
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / float(mix_rate)
		var norm := float(i) / maxf(float(count - 1), 1.0)
		var env := sin(norm * PI) * (1.0 - norm * 0.35)
		var freq := lerpf(freq_a, freq_b, norm)
		var tone := sin(TAU * freq * t) * 0.65 + sin(TAU * freq * 2.0 * t) * 0.15
		var sample := int(clampf(tone * env * 0.32, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, sample)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = data
	return wav


func _play_sfx(stream: AudioStreamWAV, volume_db: float) -> void:
	if not is_instance_valid(_sfx_player) or stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = volume_db
	_sfx_player.play()


func _build_ui() -> void:
	_backdrop = ColorRect.new()
	_backdrop.color = Color(0.02, 0.025, 0.035, 0.58)
	_backdrop.size = Vector2(1600.0, 900.0)
	_backdrop.position = Vector2(-160.0, -90.0)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_panel_root = Control.new()
	_panel_root.size = Vector2(780.0, 526.0)
	_panel_root.pivot_offset = _panel_root.size * 0.5
	_panel_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_panel_root)

	_chassis = _ChassisCanvas.new()
	_chassis.size = _panel_root.size
	_chassis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(_chassis)

	_title_label = Label.new()
	_title_label.position = Vector2(146.0, 12.0)
	_title_label.size = Vector2(488.0, 52.0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_title_label.text = "ПЕРЕХОПЛЕНІ ПЕРЕГОВОРИ"
	_title_label.add_theme_font_size_override("font_size", 26)
	_title_label.add_theme_color_override("font_color", Color(0.95, 0.96, 0.94, 1.0))
	_title_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.9))
	_title_label.add_theme_constant_override("shadow_offset_x", 2)
	_title_label.add_theme_constant_override("shadow_offset_y", 2)
	_panel_root.add_child(_title_label)

	_slot_rows.clear()
	for i in range(MAX_SLOTS):
		var slot := TransmissionSlot.new()
		slot.position = Vector2(34.0, 92.0 + float(i) * 108.0)
		slot.size = Vector2(712.0, 100.0)
		_panel_root.add_child(slot)
		_slot_rows.append(slot)

	_skip_btn = _create_pill_button("ПРОПУСТИТИ", Vector2(88.0, 434.0), Vector2(236.0, 60.0))
	_skip_btn.pressed.connect(skip_dialog)
	_panel_root.add_child(_skip_btn)

	_next_btn = _create_pill_button("ДАЛІ", Vector2(354.0, 434.0), Vector2(338.0, 60.0))
	_next_btn.pressed.connect(func() -> void: advance_or_complete(false))
	_panel_root.add_child(_next_btn)


func _create_pill_button(label_text: String, pos: Vector2, btn_size: Vector2) -> Button:
	var btn := Button.new()
	btn.text = label_text
	btn.position = pos
	btn.size = btn_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 24)
	btn.add_theme_color_override("font_color", Color(0.95, 0.96, 0.93, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.85, 1.0))
	btn.add_theme_color_override("font_pressed_color", Color(0.84, 0.85, 0.80, 1.0))

	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.114, 0.125, 0.137, 1.0)
	normal.border_color = Color(0.369, 0.376, 0.345, 1.0)
	normal.set_border_width_all(3)
	normal.set_corner_radius_all(28)
	normal.shadow_color = Color(0.05, 0.055, 0.06, 0.95)
	normal.shadow_size = 2
	normal.shadow_offset = Vector2(0.0, 2.0)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color(0.176, 0.192, 0.212, 1.0)
	hover.border_color = Color(0.56, 0.56, 0.44, 1.0)

	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color(0.075, 0.082, 0.090, 1.0)
	pressed.border_color = Color(0.31, 0.32, 0.29, 1.0)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", pressed)
	return btn


func _center_panel() -> void:
	var vp := get_viewport()
	var vp_size := vp.get_visible_rect().size if vp != null else Vector2(1280.0, 720.0)
	if vp_size.x <= 1.0 or vp_size.y <= 1.0:
		vp_size = Vector2(1280.0, 720.0)
	_panel_root.position = Vector2(
		roundf((vp_size.x - _panel_root.size.x) * 0.5),
		roundf((vp_size.y - _panel_root.size.y) * 0.5)
	)


func _begin_sequence() -> void:
	_revealed_count = 0
	_window_start = 0
	_active_slot = -1
	_typing_chars = 0.0
	_typing_target = 0
	for slot in _slot_rows:
		slot.clear_message()

	_panel_root.scale = Vector2(0.92, 0.92)
	_panel_root.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel_root, "scale", Vector2.ONE, 0.20).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel_root, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	_reveal_next_message()


func _reveal_next_message() -> void:
	if _revealed_count >= _messages.size():
		return
	_revealed_count += 1
	_window_start = maxi(0, _revealed_count - MAX_SLOTS)

	for slot_idx in range(MAX_SLOTS):
		var msg_idx := _window_start + slot_idx
		var slot := _slot_rows[slot_idx]
		if msg_idx < _revealed_count:
			var entry: Dictionary = _messages[msg_idx]
			var speaker := String(entry.get("speaker", "enemy"))
			var text := String(entry.get("text", ""))
			var tex: Texture2D = _portraits.get(speaker, _portraits.get("enemy"))
			var is_latest := (msg_idx == _revealed_count - 1)
			slot.set_message(speaker, text, tex, is_latest)
			if is_latest:
				_active_slot = slot_idx
				_typing_target = text.length()
				_typing_chars = 0.0
				slot.set_visible_chars(0)
			else:
				slot.set_visible_chars(-1)
		else:
			slot.clear_message()

	if _revealed_count >= _messages.size():
		_next_btn.text = "У БІЙ!"
	else:
		_next_btn.text = "ДАЛІ"


func _finish_dialog(_skipped: bool) -> void:
	if _is_closing:
		return
	_is_closing = true
	if is_instance_valid(_skip_btn):
		_skip_btn.disabled = true
	if is_instance_valid(_next_btn):
		_next_btn.disabled = true

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(_panel_root, "scale", Vector2(0.95, 0.95), 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_panel_root, "modulate:a", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(_backdrop, "color:a", 0.0, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func() -> void:
		finished.emit()
		queue_free()
	)


static func _draw_bevel_rounded_rect(canvas: CanvasItem, rect: Rect2, radius: float, fill: Color, hi: Color, lo: Color, outline: Color, border_w: float = 3.0) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = outline
	sb.set_border_width_all(int(border_w))
	sb.set_corner_radius_all(int(radius))
	sb.draw(canvas.get_canvas_item(), rect)

	var inset_x := minf(radius * 0.55, rect.size.x * 0.15)
	var hi_y := rect.position.y + border_w + 1.5
	canvas.draw_line(
		Vector2(rect.position.x + inset_x, hi_y),
		Vector2(rect.position.x + rect.size.x - inset_x, hi_y),
		hi,
		2.0
	)
	var lo_y := rect.position.y + rect.size.y - border_w - 1.5
	canvas.draw_line(
		Vector2(rect.position.x + inset_x, lo_y),
		Vector2(rect.position.x + rect.size.x - inset_x, lo_y),
		lo,
		2.0
	)


static func _draw_screw(canvas: CanvasItem, center: Vector2, r: float = 5.0) -> void:
	canvas.draw_circle(center, r, COLOR_OUTLINE)
	canvas.draw_circle(center, r - 1.3, Color(0.75, 0.76, 0.72, 1.0))
	canvas.draw_circle(center + Vector2(-0.7, -0.7), (r - 1.3) * 0.65, Color(0.87, 0.88, 0.84, 1.0))
	var cross := r * 0.52
	canvas.draw_line(center + Vector2(-cross, 0.0), center + Vector2(cross, 0.0), Color(0.28, 0.29, 0.27, 1.0), 1.4)
	canvas.draw_line(center + Vector2(0.0, -cross), center + Vector2(0.0, cross), Color(0.28, 0.29, 0.27, 1.0), 1.4)


static func _draw_scanlines(canvas: CanvasItem, rect: Rect2, step_x: float = 4.0) -> void:
	var x := rect.position.x + step_x
	var end_x := rect.position.x + rect.size.x - 2.0
	while x < end_x:
		canvas.draw_line(
			Vector2(x, rect.position.y + 3.0),
			Vector2(x, rect.position.y + rect.size.y - 3.0),
			Color(1.0, 1.0, 1.0, 0.045),
			1.0
		)
		x += step_x


class _ChassisCanvas extends Control:
	func _draw() -> void:
		# Bottom decorative mechanical wheels/gears peeking under chassis
		for raw_wheel_x in [72.0, 488.0]:
			var wheel_x := float(raw_wheel_x)
			var w_rect := Rect2(wheel_x, 502.0, 108.0, 20.0)
			TransmissionDialog._draw_bevel_rounded_rect(self, w_rect, 6.0, COLOR_CHASSIS_LO, COLOR_CHASSIS, COLOR_CHASSIS_DARK, COLOR_OUTLINE, 3.0)
			for i in range(1, 9):
				var tx := wheel_x + float(i) * 12.0
				draw_line(Vector2(tx, 505.0), Vector2(tx, 519.0), COLOR_OUTLINE, 2.0)

		# Right serrated rotary gear peeking out along lower-right edge
		var gear_rect := Rect2(760.0, 324.0, 20.0, 164.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, gear_rect, 5.0, COLOR_CHASSIS_LO, COLOR_CHASSIS, COLOR_CHASSIS_DARK, COLOR_OUTLINE, 3.0)
		for y in range(334, 482, 12):
			draw_line(Vector2(764.0, float(y)), Vector2(777.0, float(y)), COLOR_OUTLINE, 2.2)
			draw_line(Vector2(764.0, float(y) + 3.0), Vector2(777.0, float(y) + 3.0), COLOR_CHASSIS_HI, 1.2)

		# Left knurled rotary knob beside top arch
		var stem_rect := Rect2(102.0, 18.0, 26.0, 28.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, stem_rect, 3.0, COLOR_CHASSIS_LO, COLOR_CHASSIS, COLOR_CHASSIS_DARK, COLOR_OUTLINE, 3.0)
		var knob_rect := Rect2(56.0, 8.0, 50.0, 44.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, knob_rect, 6.0, COLOR_CHASSIS, COLOR_CHASSIS_HI, COLOR_CHASSIS_LO, COLOR_OUTLINE, 3.0)
		for i in range(1, 5):
			var rx := 56.0 + float(i) * 10.0
			draw_line(Vector2(rx, 11.0), Vector2(rx, 49.0), COLOR_OUTLINE, 1.8)

		# Top mounting shoulders connecting arch and main chassis
		var arch_base := Rect2(118.0, 0.0, 544.0, 68.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, arch_base, 22.0, COLOR_CHASSIS, COLOR_CHASSIS_HI, COLOR_CHASSIS_LO, COLOR_OUTLINE, 3.5)

		# Main olive chassis body
		var body_rect := Rect2(0.0, 48.0, 766.0, 464.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, body_rect, 22.0, COLOR_CHASSIS, COLOR_CHASSIS_HI, COLOR_CHASSIS_LO, COLOR_OUTLINE, 3.5)

		# Header CRT inset (drawn over top seam cleanly)
		var hdr_bezel := Rect2(124.0, 4.0, 532.0, 68.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, hdr_bezel, 18.0, COLOR_CHASSIS, COLOR_CHASSIS_HI, COLOR_CHASSIS_LO, Color.TRANSPARENT, 0.0)
		var hdr_screen := Rect2(142.0, 12.0, 496.0, 52.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, hdr_screen, 14.0, COLOR_CRT_BG, Color(0.08, 0.09, 0.11, 1.0), Color.BLACK, COLOR_OUTLINE, 3.0)
		TransmissionDialog._draw_scanlines(self, hdr_screen, 4.0)

		# Recessed dark well holding the 3 message slots
		var well_outer := Rect2(20.0, 76.0, 726.0, 344.0)
		TransmissionDialog._draw_bevel_rounded_rect(self, well_outer, 10.0, COLOR_WELL_SHADOW, Color(0.32, 0.31, 0.22, 1.0), COLOR_CHASSIS_HI, COLOR_OUTLINE, 3.0)
		var well_inner := Rect2(26.0, 82.0, 714.0, 332.0)
		draw_rect(well_inner, COLOR_WELL_BG)

		# Metallic L-brackets on top-left and top-right of the recessed well
		var lb := PackedVector2Array([
			Vector2(14.0, 72.0), Vector2(56.0, 72.0), Vector2(56.0, 90.0),
			Vector2(34.0, 90.0), Vector2(34.0, 114.0), Vector2(14.0, 114.0)
		])
		draw_colored_polygon(lb, COLOR_STEEL)
		draw_polyline(lb + PackedVector2Array([lb[0]]), COLOR_OUTLINE, 2.5)
		TransmissionDialog._draw_screw(self, Vector2(26.0, 82.0), 5.0)

		var rb := PackedVector2Array([
			Vector2(710.0, 72.0), Vector2(752.0, 72.0), Vector2(752.0, 114.0),
			Vector2(732.0, 114.0), Vector2(732.0, 90.0), Vector2(710.0, 90.0)
		])
		draw_colored_polygon(rb, COLOR_STEEL)
		draw_polyline(rb + PackedVector2Array([rb[0]]), COLOR_OUTLINE, 2.5)
		TransmissionDialog._draw_screw(self, Vector2(740.0, 82.0), 5.0)

		# Bottom corner chassis screws
		TransmissionDialog._draw_screw(self, Vector2(26.0, 486.0), 5.5)
		TransmissionDialog._draw_screw(self, Vector2(740.0, 486.0), 5.5)


class TransmissionSlot extends Control:
	var _speaker: String = ""
	var _message: String = ""
	var _has_message: bool = false
	var _is_latest: bool = false

	var _label: Label
	var _portrait_rect: TextureRect

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		_label = Label.new()
		_label.position = Vector2(30.0, 12.0)
		_label.size = Vector2(564.0, 76.0)
		_label.custom_minimum_size = Vector2(564.0, 76.0)
		_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		_label.add_theme_font_size_override("font_size", 23)
		_label.add_theme_color_override("font_shadow_color", Color(0.0, 0.0, 0.0, 0.85))
		_label.add_theme_constant_override("shadow_offset_x", 1)
		_label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(_label)

		_portrait_rect = TextureRect.new()
		_portrait_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_portrait_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_portrait_rect.visible = false
		add_child(_portrait_rect)

	func clear_message() -> void:
		_speaker = ""
		_message = ""
		_has_message = false
		_is_latest = false
		_label.text = ""
		_label.visible_characters = -1
		_portrait_rect.texture = null
		_portrait_rect.visible = false
		queue_redraw()

	func set_message(speaker: String, text: String, portrait_tex: Texture2D, is_latest: bool) -> void:
		_speaker = speaker
		_message = text
		_has_message = true
		_is_latest = is_latest

		_layout_children()
		_label.text = text
		var text_col := Color(0.96, 0.97, 0.94, 1.0) if is_latest else Color(0.82, 0.84, 0.80, 1.0)
		_label.add_theme_color_override("font_color", text_col)

		if portrait_tex != null:
			_portrait_rect.texture = portrait_tex
			_portrait_rect.visible = true
		else:
			_portrait_rect.visible = false

		queue_redraw()

	func set_visible_chars(count: int) -> void:
		_label.visible_characters = count

	func get_message_text() -> String:
		return _message

	func get_speaker() -> String:
		return _speaker

	func _layout_children() -> void:
		var w := size.x if size.x > 1.0 else 712.0
		var p_box_size := 82.0
		var port_x := 10.0 if _speaker == "hero" else (w - 10.0 - p_box_size)
		_portrait_rect.position = Vector2(port_x + 4.0, 13.0)
		_portrait_rect.size = Vector2(p_box_size - 8.0, p_box_size - 8.0)

		var crt_x := 102.0 if _speaker == "hero" else 14.0
		var crt_w := w - 116.0
		_label.position = Vector2(crt_x + 16.0, 12.0)
		_label.custom_minimum_size = Vector2(crt_w - 32.0, 76.0)
		_label.size = Vector2(crt_w - 32.0, 76.0)

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var plate := Rect2(0.0, 0.0, w, h)
		TransmissionDialog._draw_bevel_rounded_rect(self, plate, 8.0, COLOR_STEEL, COLOR_STEEL_HI, COLOR_STEEL_LO, COLOR_OUTLINE, 3.0)

		if not _has_message:
			var empty_crt := Rect2(14.0, 10.0, w - 28.0, h - 20.0)
			TransmissionDialog._draw_bevel_rounded_rect(self, empty_crt, 6.0, Color(0.035, 0.039, 0.047, 1.0), Color(0.10, 0.11, 0.12, 1.0), Color.BLACK, COLOR_OUTLINE, 2.5)
			TransmissionDialog._draw_scanlines(self, empty_crt, 4.0)
			return

		var p_box_size := 82.0
		var port_x := 10.0 if _speaker == "hero" else (w - 10.0 - p_box_size)
		var crt_x := 102.0 if _speaker == "hero" else 14.0
		var crt_w := w - 116.0

		var crt_rect := Rect2(crt_x, 10.0, crt_w, h - 20.0)
		var crt_border := Color(0.75, 0.72, 0.45, 1.0) if _is_latest else COLOR_OUTLINE
		TransmissionDialog._draw_bevel_rounded_rect(self, crt_rect, 6.0, COLOR_CRT_BG, Color(0.09, 0.10, 0.12, 1.0), Color.BLACK, crt_border, 2.5)
		TransmissionDialog._draw_scanlines(self, crt_rect, 4.0)

		# Portrait dark socket + frame
		var port_rect := Rect2(port_x, 9.0, p_box_size, p_box_size)
		TransmissionDialog._draw_bevel_rounded_rect(self, port_rect, 5.0, Color(0.08, 0.09, 0.10, 1.0), COLOR_STEEL_HI, COLOR_STEEL_LO, COLOR_OUTLINE, 2.5)

		# Corner screws flanking the CRT frame
		TransmissionDialog._draw_screw(self, Vector2(crt_x - 3.0, 7.0), 3.6)
		TransmissionDialog._draw_screw(self, Vector2(crt_x + crt_w + 3.0, 7.0), 3.6)
		TransmissionDialog._draw_screw(self, Vector2(crt_x - 3.0, h - 7.0), 3.6)
		TransmissionDialog._draw_screw(self, Vector2(crt_x + crt_w + 3.0, h - 7.0), 3.6)

		# Corner screws on outer corners of portrait frame
		TransmissionDialog._draw_screw(self, Vector2(port_x + 2.0, 6.0), 3.2)
		TransmissionDialog._draw_screw(self, Vector2(port_x + p_box_size - 2.0, 6.0), 3.2)
		TransmissionDialog._draw_screw(self, Vector2(port_x + 2.0, h - 6.0), 3.2)
		TransmissionDialog._draw_screw(self, Vector2(port_x + p_box_size - 2.0, h - 6.0), 3.2)
