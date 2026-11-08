class_name UpgradeMenu
extends Control

const GAME_STATE := preload("res://scripts/game_state.gd")
const BATTLE_SCENE_PATH := "res://scenes/main.tscn"

const UPGRADE_DEFS: Array[Dictionary] = [
	{"key": "hp", "title": "Здоров'я героя (HP)"},
	{"key": "damage", "title": "Урон кулі гвинтівки"},
	{"key": "grenades", "title": "Кількість гранат"},
	{"key": "coins", "title": "Монети з ворогів"},
]

var _transitioning := false
var _hover_tween: Tween = null
var _row_widgets: Dictionary = {}

@onready var level_label: Label = $PanelFrame/HeaderBar/LevelLabel
@onready var coins_label: Label = $PanelFrame/HeaderBar/CoinsLabel
@onready var earned_label: Label = $PanelFrame/BodyBox/EarnedLabel
@onready var upgrades_container: VBoxContainer = get_node_or_null("PanelFrame/BodyBox/UpgradesContainer")
@onready var next_button: TextureButton = $NextButton
@onready var fade_overlay: ColorRect = $FadeOverlay


func _ready() -> void:
	_build_upgrade_rows()
	_refresh_ui()

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


func _build_upgrade_rows() -> void:
	if upgrades_container == null:
		return
	for child in upgrades_container.get_children():
		child.queue_free()
	_row_widgets.clear()

	for def in UPGRADE_DEFS:
		var key: String = def["key"]
		var title: String = def["title"]

		var row_bg := ColorRect.new()
		row_bg.custom_minimum_size = Vector2(0.0, 66.0)
		row_bg.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row_bg.color = Color(0.13, 0.13, 0.14, 0.95)
		upgrades_container.add_child(row_bg)

		var hbox := HBoxContainer.new()
		hbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		hbox.offset_left = 18.0
		hbox.offset_right = -18.0
		hbox.offset_top = 8.0
		hbox.offset_bottom = -8.0
		hbox.add_theme_constant_override("separation", 18)
		row_bg.add_child(hbox)

		var title_lbl := Label.new()
		title_lbl.custom_minimum_size = Vector2(270.0, 0.0)
		title_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		title_lbl.add_theme_font_size_override("font_size", 21)
		title_lbl.add_theme_color_override("font_color", Color(0.94, 0.91, 0.82, 1.0))
		title_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		title_lbl.add_theme_constant_override("outline_size", 4)
		title_lbl.text = title
		hbox.add_child(title_lbl)

		var info_lbl := Label.new()
		info_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		info_lbl.add_theme_font_size_override("font_size", 19)
		info_lbl.add_theme_color_override("font_color", Color(0.76, 0.88, 0.98, 1.0))
		info_lbl.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.9))
		info_lbl.add_theme_constant_override("outline_size", 4)
		hbox.add_child(info_lbl)

		var buy_btn := Button.new()
		buy_btn.custom_minimum_size = Vector2(210.0, 46.0)
		buy_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		buy_btn.add_theme_font_size_override("font_size", 19)
		buy_btn.pressed.connect(_on_buy_upgrade_pressed.bind(key))
		hbox.add_child(buy_btn)

		_row_widgets[key] = {
			"info": info_lbl,
			"button": buy_btn,
		}


func _refresh_ui() -> void:
	var hp_bonus_pct := int(roundf((GAME_STATE.get_enemy_hp_multiplier() - 1.0) * 100.0))
	if level_label:
		level_label.text = "РІВЕНЬ %d / %d  (ХП ворогів: +%d%%)" % [
			GAME_STATE.current_level,
			GAME_STATE.TOTAL_LEVELS,
			hp_bonus_pct,
		]
	if coins_label:
		coins_label.text = "МОНЕТИ: $%d" % GAME_STATE.coins
	if earned_label:
		if GAME_STATE.last_level_earned > 0:
			earned_label.text = "Зароблено за попередній бій: +$%d" % GAME_STATE.last_level_earned
			earned_label.visible = true
		else:
			earned_label.visible = false

	for def in UPGRADE_DEFS:
		var key: String = def["key"]
		if not _row_widgets.has(key):
			continue
		var widgets: Dictionary = _row_widgets[key]
		var info_lbl: Label = widgets["info"]
		var buy_btn: Button = widgets["button"]

		var lvl := GAME_STATE.get_upgrade_level(key)
		var max_lvl := GAME_STATE.MAX_UPGRADE_LEVEL
		var cost := GAME_STATE.get_upgrade_cost(key)

		info_lbl.text = "Рівень %d/%d   |   %s" % [lvl, max_lvl, _format_upgrade_stat(key, lvl)]

		if lvl >= max_lvl:
			buy_btn.text = "МАКС. (5/5)"
			buy_btn.disabled = true
		else:
			buy_btn.text = "КУПИТИ ($%d)" % cost
			buy_btn.disabled = not GAME_STATE.can_buy_upgrade(key)


func _format_upgrade_stat(key: String, lvl: int) -> String:
	var max_lvl := GAME_STATE.MAX_UPGRADE_LEVEL
	match key:
		"hp":
			var cur := int(100 + lvl * 25)
			if lvl >= max_lvl:
				return "%d HP" % cur
			return "%d HP -> %d HP" % [cur, cur + 25]
		"damage":
			var cur := int(10 + lvl * 3)
			if lvl >= max_lvl:
				return "%d урону" % cur
			return "%d -> %d урону" % [cur, cur + 3]
		"grenades":
			var cur := 3 + lvl
			if lvl >= max_lvl:
				return "%d шт." % cur
			return "%d -> %d шт." % [cur, cur + 1]
		"coins":
			var cur := lvl * 20
			if lvl >= max_lvl:
				return "+%d%% монет" % cur
			return "+%d%% -> +%d%% монет" % [cur, cur + 20]
	return ""


func _on_buy_upgrade_pressed(key: String) -> void:
	if _transitioning:
		return
	if GAME_STATE.buy_upgrade(key):
		_refresh_ui()


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
