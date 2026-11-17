class_name BattleEndDialog
extends CanvasLayer

signal continue_pressed

const PANEL_WIDTH := 464.0
const PANEL_HEIGHT := 526.0
const PLATE_WIDTH := 442.0
const PLATE_HEIGHT := 378.0
const BTN_WIDTH := 396.0
const BTN_HEIGHT := 72.0
const CONTINUE_GRACE_SEC := 0.35

const COL_INK := Color(0.055, 0.06, 0.068, 1.0)
const COL_STEEL_PLATE := Color(0.445, 0.435, 0.410, 1.0)
const COL_STEEL_HI := Color(0.58, 0.57, 0.54, 1.0)
const COL_STEEL_LO := Color(0.28, 0.275, 0.26, 1.0)
const COL_INSET_PLATE := Color(0.305, 0.300, 0.285, 1.0)
const COL_BRASS_DARK := Color(0.48, 0.46, 0.28, 1.0)
const COL_BRASS_LIGHT := Color(0.72, 0.69, 0.43, 1.0)
const COL_BTN_FILL := Color(0.145, 0.155, 0.148, 1.0)
const COL_BTN_HOVER := Color(0.22, 0.24, 0.215, 1.0)
const COL_BTN_PRESSED := Color(0.10, 0.11, 0.105, 1.0)

var _is_victory: bool = false
var _is_campaign_won: bool = false
var _level_number: int = 1
var _earned_coins: int = 0
var _total_coins: int = 0
var _killed_count: int = 0
var _lit_sockets: int = 1
var _upgrade_unlocked: bool = false
var _upgrade_hint_text: String = ""

var _elapsed: float = 0.0
var _continue_emitted: bool = false
var _btn_hovered: bool = false
var _btn_pressed: bool = false

var _backdrop: ColorRect = null
var _panel_root: Control = null
var _chassis_canvas: _ConsoleArtwork = null
var _continue_btn: Button = null


func setup(
	is_victory: bool,
	is_campaign_won: bool,
	level_number: int,
	earned_coins: int,
	total_coins: int,
	killed_count: int,
	upgraded_levels_total: int,
	next_upgrade_ready: bool,
	upgrade_hint_text: String
) -> void:
	_is_victory = is_victory
	_is_campaign_won = is_campaign_won
	_level_number = level_number
	_earned_coins = earned_coins
	_total_coins = total_coins
	_killed_count = killed_count
	_lit_sockets = clampi(1 + (upgraded_levels_total / 3), 1, 4) if upgraded_levels_total > 0 else 1
	_upgrade_unlocked = next_upgrade_ready
	_upgrade_hint_text = upgrade_hint_text


func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS

	_backdrop = ColorRect.new()
	_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	_backdrop.color = Color(0.015, 0.02, 0.025, 0.0)
	_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_backdrop)

	_panel_root = Control.new()
	_panel_root.set_anchors_preset(Control.PRESET_CENTER)
	_panel_root.offset_left = -PANEL_WIDTH * 0.5
	_panel_root.offset_top = -PANEL_HEIGHT * 0.5
	_panel_root.offset_right = PANEL_WIDTH * 0.5
	_panel_root.offset_bottom = PANEL_HEIGHT * 0.5
	_panel_root.pivot_offset = Vector2(PANEL_WIDTH * 0.5, PANEL_HEIGHT * 0.5)
	_panel_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(_panel_root)

	_chassis_canvas = _ConsoleArtwork.new()
	_chassis_canvas.dialog = self
	_chassis_canvas.position = Vector2.ZERO
	_chassis_canvas.size = Vector2(PANEL_WIDTH, PANEL_HEIGHT)
	_chassis_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel_root.add_child(_chassis_canvas)

	_build_content_labels()
	_build_continue_button()

	# Плавна поява вікна з легким пружинним масштабом
	_panel_root.scale = Vector2(0.88, 0.88)
	_panel_root.modulate.a = 0.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_backdrop, "color:a", 0.56, 0.24).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel_root, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(_panel_root, "modulate:a", 1.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	_elapsed += delta
	if _chassis_canvas != null:
		_chassis_canvas.pulse_time = _elapsed
		_chassis_canvas.queue_redraw()


func _input(event: InputEvent) -> void:
	if _continue_emitted or _elapsed < CONTINUE_GRACE_SEC:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] or event.physical_keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			var vp := get_viewport()
			if vp != null:
				vp.set_input_as_handled()
			_emit_continue()


func _build_content_labels() -> void:
	var plate_x := (PANEL_WIDTH - PLATE_WIDTH) * 0.5
	var inset_x := plate_x + 20.0
	var inset_w := PLATE_WIDTH - 40.0

	var title_lbl := Label.new()
	title_lbl.position = Vector2(inset_x + 12.0, 38.0)
	title_lbl.size = Vector2(inset_w - 24.0, 88.0)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 32 if not _is_campaign_won else 28)
	title_lbl.add_theme_color_override("font_color", Color(0.95, 0.94, 0.90) if _is_victory else Color(0.96, 0.90, 0.86))
	title_lbl.add_theme_color_override("font_outline_color", COL_INK)
	title_lbl.add_theme_constant_override("outline_size", 6)
	if _is_campaign_won:
		title_lbl.text = "ПЕРЕМОГА!\nВСІ РІВНІ ПРОЙДЕНО"
	elif _is_victory:
		title_lbl.text = "РІВЕНЬ %d\nПРОЙДЕНО!" % _level_number
	else:
		title_lbl.text = "ПОРАЗКА\nБІЙ ЗАВЕРШЕНО"
	_panel_root.add_child(title_lbl)

	var stats_lbl := Label.new()
	stats_lbl.position = Vector2(inset_x + 14.0, 130.0)
	stats_lbl.size = Vector2(inset_w - 28.0, 32.0)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stats_lbl.add_theme_font_size_override("font_size", 15)
	stats_lbl.add_theme_color_override("font_color", Color(0.98, 0.86, 0.44) if _is_victory else Color(0.95, 0.72, 0.48))
	stats_lbl.add_theme_color_override("font_outline_color", COL_INK)
	stats_lbl.add_theme_constant_override("outline_size", 4)
	if _is_campaign_won:
		stats_lbl.text = "За бій: +$%d   •   Баланс: $%d" % [_earned_coins, _total_coins]
	else:
		stats_lbl.text = "Зароблено: +$%d   •   Знищено: %d" % [_earned_coins, _killed_count]
	_panel_root.add_child(stats_lbl)

	var sec_hdr := Label.new()
	sec_hdr.position = Vector2(plate_x + 20.0, 194.0)
	sec_hdr.size = Vector2(PLATE_WIDTH - 40.0, 30.0)
	sec_hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sec_hdr.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sec_hdr.add_theme_font_size_override("font_size", 21)
	sec_hdr.add_theme_color_override("font_color", Color(0.94, 0.93, 0.89))
	sec_hdr.add_theme_color_override("font_outline_color", COL_INK)
	sec_hdr.add_theme_constant_override("outline_size", 5)
	sec_hdr.text = "ФІНАЛ КАМПАНІЇ" if _is_campaign_won else "НАСТУПНЕ ПОКРАЩЕННЯ"
	_panel_root.add_child(sec_hdr)

	if not _upgrade_hint_text.is_empty():
		var hint_lbl := Label.new()
		hint_lbl.position = Vector2(plate_x + 20.0, 344.0)
		hint_lbl.size = Vector2(PLATE_WIDTH - 40.0, 22.0)
		hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hint_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		hint_lbl.add_theme_font_size_override("font_size", 12)
		hint_lbl.add_theme_color_override(
			"font_color",
			Color(0.62, 0.95, 0.64) if _upgrade_unlocked else Color(0.84, 0.83, 0.78)
		)
		hint_lbl.add_theme_color_override("font_outline_color", COL_INK)
		hint_lbl.add_theme_constant_override("outline_size", 3)
		hint_lbl.text = _upgrade_hint_text
		_panel_root.add_child(hint_lbl)


func _build_continue_button() -> void:
	var btn_x := (PANEL_WIDTH - BTN_WIDTH) * 0.5
	var btn_y := 424.0

	_continue_btn = Button.new()
	_continue_btn.position = Vector2(btn_x, btn_y)
	_continue_btn.size = Vector2(BTN_WIDTH, BTN_HEIGHT)
	_continue_btn.flat = true
	_continue_btn.focus_mode = Control.FOCUS_NONE
	_continue_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_continue_btn.text = "У ГОЛОВНЕ МЕНЮ" if _is_campaign_won else "ПРОДОВЖИТИ"
	_continue_btn.add_theme_font_size_override("font_size", 28)
	_continue_btn.add_theme_color_override("font_color", Color(0.96, 0.95, 0.91))
	_continue_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.96, 0.80))
	_continue_btn.add_theme_color_override("font_pressed_color", Color(0.88, 0.86, 0.78))
	_continue_btn.add_theme_color_override("font_outline_color", COL_INK)
	_continue_btn.add_theme_constant_override("outline_size", 5)

	var empty_sb := StyleBoxEmpty.new()
	_continue_btn.add_theme_stylebox_override("normal", empty_sb)
	_continue_btn.add_theme_stylebox_override("hover", empty_sb)
	_continue_btn.add_theme_stylebox_override("pressed", empty_sb)
	_continue_btn.add_theme_stylebox_override("focus", empty_sb)

	_continue_btn.mouse_entered.connect(func() -> void:
		_btn_hovered = true
		if _chassis_canvas:
			_chassis_canvas.queue_redraw()
	)
	_continue_btn.mouse_exited.connect(func() -> void:
		_btn_hovered = false
		_btn_pressed = false
		if _chassis_canvas:
			_chassis_canvas.queue_redraw()
	)
	_continue_btn.button_down.connect(func() -> void:
		_btn_pressed = true
		if _chassis_canvas:
			_chassis_canvas.queue_redraw()
	)
	_continue_btn.button_up.connect(func() -> void:
		_btn_pressed = false
		if _chassis_canvas:
			_chassis_canvas.queue_redraw()
	)
	_continue_btn.pressed.connect(_emit_continue)
	_panel_root.add_child(_continue_btn)


func _emit_continue() -> void:
	if _continue_emitted:
		return
	_continue_emitted = true
	if _continue_btn:
		_continue_btn.disabled = true
	continue_pressed.emit()


static func _draw_panel_box(canvas: CanvasItem, rect: Rect2, radius: int, fill: Color, hi: Color, lo: Color, border_w: float = 3.5) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = COL_INK
	sb.set_border_width_all(int(roundf(border_w)))
	sb.set_corner_radius_all(radius)
	sb.draw(canvas.get_canvas_item(), rect)

	var inset := clampf(float(radius) * 0.65, 6.0, rect.size.x * 0.14)
	if hi.a > 0.01:
		canvas.draw_line(
			Vector2(rect.position.x + inset, rect.position.y + border_w + 1.5),
			Vector2(rect.end.x - inset, rect.position.y + border_w + 1.5),
			hi,
			2.0
		)
	if lo.a > 0.01:
		canvas.draw_line(
			Vector2(rect.position.x + inset, rect.end.y - border_w - 1.5),
			Vector2(rect.end.x - inset, rect.end.y - border_w - 1.5),
			lo,
			2.0
		)


static func _draw_screw(canvas: CanvasItem, center: Vector2, r: float = 5.2) -> void:
	canvas.draw_circle(center, r, COL_INK)
	canvas.draw_circle(center, r - 1.3, Color(0.68, 0.68, 0.65, 1.0))
	canvas.draw_circle(center + Vector2(-0.8, -0.8), (r - 1.3) * 0.65, Color(0.84, 0.84, 0.81, 1.0))
	var cross := r * 0.48
	canvas.draw_line(center + Vector2(-cross, 0.0), center + Vector2(cross, 0.0), Color(0.20, 0.20, 0.19, 1.0), 1.3)
	canvas.draw_line(center + Vector2(0.0, -cross), center + Vector2(0.0, cross), Color(0.20, 0.20, 0.19, 1.0), 1.3)


static func _draw_corner_bracket(canvas: CanvasItem, origin: Vector2, dir_x: float, dir_y: float) -> void:
	var pts := PackedVector2Array([
		origin,
		origin + Vector2(dir_x * 26.0, 0.0),
		origin + Vector2(dir_x * 26.0, dir_y * 10.0),
		origin + Vector2(dir_x * 16.0, dir_y * 22.0),
		origin + Vector2(0.0, dir_y * 22.0),
	])
	canvas.draw_colored_polygon(pts, Color(0.60, 0.59, 0.56, 1.0))
	var closed := pts + PackedVector2Array([pts[0]])
	canvas.draw_polyline(closed, COL_INK, 2.4, true)
	_draw_screw(canvas, origin + Vector2(dir_x * 11.0, dir_y * 10.0), 4.6)


class _ConsoleArtwork extends Control:
	var dialog: BattleEndDialog = null
	var pulse_time: float = 0.0

	func _draw() -> void:
		if dialog == null:
			return
		var w := size.x
		var plate_x := (w - PLATE_WIDTH) * 0.5
		var plate_rect := Rect2(plate_x, 0.0, PLATE_WIDTH, PLATE_HEIGHT)

		# 1. Виступаючі з боків латунно-оливкові кріпильні вали / амортизатори
		for side in [-1.0, 1.0]:
			var base_x := plate_x if side < 0.0 else plate_rect.end.x
			var outer_r := Rect2(
				base_x + (side * 12.0 if side < 0.0 else 0.0),
				274.0,
				12.0,
				54.0
			)
			var inner_tip := Rect2(
				base_x + (side * 22.0 if side < 0.0 else 10.0),
				283.0,
				12.0,
				36.0
			)
			BattleEndDialog._draw_panel_box(self, inner_tip, 3, COL_BRASS_DARK, COL_BRASS_LIGHT, COL_INK, 2.5)
			BattleEndDialog._draw_panel_box(self, outer_r, 4, COL_BRASS_LIGHT, Color(0.86, 0.83, 0.56), COL_BRASS_DARK, 3.0)

		# 2. Три вертикальні оливкові опори під основною панеллю
		var strut_xs := [w * 0.5 - 102.0, w * 0.5 - 12.0, w * 0.5 + 78.0]
		for sx in strut_xs:
			var strut_r := Rect2(sx, PLATE_HEIGHT - 6.0, 24.0, 44.0)
			BattleEndDialog._draw_panel_box(self, strut_r, 3, COL_BRASS_DARK, COL_BRASS_LIGHT, COL_INK, 3.0)
			draw_rect(Rect2(sx + 5.0, PLATE_HEIGHT - 2.0, 6.0, 36.0), Color(0.80, 0.77, 0.50, 0.35), true)

		# 3. Основна броньована сталева плита корпусу
		BattleEndDialog._draw_panel_box(self, plate_rect, 14, COL_STEEL_PLATE, COL_STEEL_HI, COL_STEEL_LO, 4.0)

		# Тонкі металеві подряпини для індустріальної фактури
		var scratches := [
			[Vector2(plate_x + 28.0, 212.0), Vector2(plate_x + 56.0, 198.0)],
			[Vector2(plate_x + 345.0, 244.0), Vector2(plate_x + 392.0, 268.0)],
			[Vector2(plate_x + 68.0, 336.0), Vector2(plate_x + 92.0, 354.0)],
			[Vector2(plate_x + 312.0, 326.0), Vector2(plate_x + 350.0, 314.0)],
		]
		for sc in scratches:
			draw_line(sc[0], sc[1], Color(0.18, 0.18, 0.17, 0.28), 1.4, true)

		# 4 кутові броньовані накладки з гвинтами на головній плиті
		BattleEndDialog._draw_corner_bracket(self, Vector2(plate_x, 0.0), 1.0, 1.0)
		BattleEndDialog._draw_corner_bracket(self, Vector2(plate_rect.end.x, 0.0), -1.0, 1.0)
		BattleEndDialog._draw_corner_bracket(self, Vector2(plate_x, plate_rect.end.y), 1.0, -1.0)
		BattleEndDialog._draw_corner_bracket(self, Vector2(plate_rect.end.x, plate_rect.end.y), -1.0, -1.0)

		# 4. Верхній врізаний сталевий екран заголовка бою
		var inset_rect := Rect2(plate_x + 20.0, 16.0, PLATE_WIDTH - 40.0, 164.0)
		BattleEndDialog._draw_panel_box(self, inset_rect, 8, COL_INSET_PLATE, Color(0.22, 0.22, 0.21, 0.9), Color(0.42, 0.41, 0.39, 0.7), 3.0)
		BattleEndDialog._draw_screw(self, inset_rect.position + Vector2(14.0, 14.0), 4.6)
		BattleEndDialog._draw_screw(self, Vector2(inset_rect.end.x - 14.0, inset_rect.position.y + 14.0), 4.6)
		BattleEndDialog._draw_screw(self, Vector2(inset_rect.position.x + 14.0, inset_rect.end.y - 14.0), 4.6)
		BattleEndDialog._draw_screw(self, inset_rect.end - Vector2(14.0, 14.0), 4.6)

		# Верхня довгаста сигнальна лампа (як у референсі) з м'яким багатошаровим свіченням
		var lamp_rect := Rect2(w * 0.5 - 26.0, 12.0, 52.0, 11.0)
		var base_glow := Color(0.55, 0.98, 0.65) if dialog._is_victory else Color(1.0, 0.76, 0.48)
		var lamp_center := lamp_rect.get_center()
		draw_circle(lamp_center, 30.0, Color(base_glow.r, base_glow.g, base_glow.b, 0.07))
		draw_circle(lamp_center, 21.0, Color(base_glow.r, base_glow.g, base_glow.b, 0.12))
		draw_circle(lamp_center, 13.0, Color(base_glow.r, base_glow.g, base_glow.b, 0.18))
		BattleEndDialog._draw_panel_box(
			self,
			lamp_rect,
			5,
			Color(0.88, 1.0, 0.90) if dialog._is_victory else Color(1.0, 0.92, 0.80),
			Color.WHITE,
			Color(0.55, 0.65, 0.58),
			2.5
		)

		# 5. Секція круглих гнізд прогресу / наступного покращення (5 слотів + шестерня із замком)
		var sock_positions: Array[Vector2] = [
			Vector2(w * 0.5 - 82.0, 256.0),
			Vector2(w * 0.5 + 4.0, 256.0),
			Vector2(w * 0.5 + 90.0, 256.0),
			Vector2(w * 0.5 - 38.0, 312.0),
		]
		for i in range(sock_positions.size()):
			var c := sock_positions[i]
			var is_lit := (i == 0) or (i < dialog._lit_sockets)
			draw_circle(c, 22.0, Color(0.58, 0.57, 0.54, 0.65))
			draw_circle(c, 20.0, COL_INK)
			draw_circle(c, 16.0, Color(0.10, 0.11, 0.11, 1.0))
			if is_lit:
				var pulse := 0.86 + 0.14 * sin(pulse_time * 3.8 + float(i))
				draw_circle(c, 15.0, Color(0.92, 0.90, 0.74, 0.25 * pulse))
				draw_circle(c, 10.5, Color(0.95, 0.93, 0.82, 0.85 * pulse))
				draw_circle(c + Vector2(-1.5, -1.5), 6.0, Color(1.0, 1.0, 0.96, 0.95))

		# Золота шестерня з замком і стрілкою (справа знизу)
		var gear_center := Vector2(w * 0.5 + 56.0, 312.0)
		var teeth := 12
		draw_circle(gear_center, 27.0, COL_INK)
		for ti in range(teeth):
			var a := float(ti) * TAU / float(teeth)
			var p0 := gear_center + Vector2.RIGHT.rotated(a) * 18.0
			var p1 := gear_center + Vector2.RIGHT.rotated(a) * 29.0
			draw_line(p0, p1, COL_INK, 7.2)
			draw_line(p0, gear_center + Vector2.RIGHT.rotated(a) * 27.0, COL_BRASS_LIGHT, 4.4)
		draw_circle(gear_center, 21.5, COL_INK)
		draw_circle(gear_center, 18.5, Color(0.22, 0.23, 0.21, 1.0))
		if dialog._upgrade_unlocked:
			draw_circle(gear_center, 15.0, Color(0.45, 0.86, 0.42, 0.24))

		# Іконка замка всередині шестерні (відкритий при доступності апгрейду / закритий інакше)
		var body_lock := Rect2(gear_center.x - 7.5, gear_center.y - 2.0, 15.0, 12.0)
		var shackle_col := Color(0.95, 0.88, 0.45) if dialog._upgrade_unlocked else Color(0.76, 0.76, 0.74)
		if dialog._upgrade_unlocked:
			draw_arc(Vector2(gear_center.x + 1.5, gear_center.y - 5.0), 5.0, PI, TAU * 0.92, 12, shackle_col, 2.4)
		else:
			draw_arc(Vector2(gear_center.x, gear_center.y - 3.5), 4.6, PI, TAU, 12, shackle_col, 2.4)
		BattleEndDialog._draw_panel_box(self, body_lock, 2, Color(0.76, 0.74, 0.70), Color(0.92, 0.90, 0.86), Color(0.42, 0.40, 0.36), 2.0)
		draw_circle(gear_center + Vector2(0.0, 3.5), 2.0, COL_INK)

		# Невелика тактична стрілка вправо біля шестерні (як у референсі)
		var arrow_x := gear_center.x + 36.0
		var arrow_pts := PackedVector2Array([
			Vector2(arrow_x, gear_center.y - 9.0),
			Vector2(arrow_x + 16.0, gear_center.y),
			Vector2(arrow_x, gear_center.y + 9.0),
		])
		draw_colored_polygon(arrow_pts, Color(0.22, 0.22, 0.21, 0.65))

		# 6. Масивна нижня рамка кнопки ПРОДОВЖИТИ з оливково-латунними боковими скосами
		var btn_outer := Rect2((w - (BTN_WIDTH + 34.0)) * 0.5, 412.0, BTN_WIDTH + 34.0, BTN_HEIGHT + 24.0)
		BattleEndDialog._draw_panel_box(self, btn_outer, 14, COL_BRASS_LIGHT, Color(0.86, 0.84, 0.56), COL_BRASS_DARK, 4.0)
		BattleEndDialog._draw_screw(self, btn_outer.position + Vector2(11.0, btn_outer.size.y * 0.5), 4.2)
		BattleEndDialog._draw_screw(self, Vector2(btn_outer.end.x - 11.0, btn_outer.position.y + btn_outer.size.y * 0.5), 4.2)

		var btn_inner := Rect2((w - BTN_WIDTH) * 0.5, 424.0, BTN_WIDTH, BTN_HEIGHT)
		var inner_col := COL_BTN_PRESSED if dialog._btn_pressed else (COL_BTN_HOVER if dialog._btn_hovered else COL_BTN_FILL)
		BattleEndDialog._draw_panel_box(
			self,
			btn_inner,
			10,
			inner_col,
			Color(0.42, 0.44, 0.40, 0.85),
			Color(0.05, 0.06, 0.06, 0.95),
			3.5
		)
