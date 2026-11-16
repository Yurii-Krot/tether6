class_name UpgradeMenu
extends Control

const GAME_SCENE_PATH := "res://scenes/main.tscn"
const MAIN_MENU_SCENE_PATH := "res://scenes/main_menu.tscn"
const GAME_STATE := preload("res://scripts/game_state.gd")
const TEX_BTN_BACK := preload("res://assets/btn_back.png")

const TEX_SOLDIER_STD := preload("res://assets/player.png")
const TEX_SOLDIER_GOLD := preload("res://assets/player_shades_gold.png")
const TEX_SOLDIER_CYBER := preload("res://assets/player_shades_cyber.png")
const TEX_SOLDIER_BLACK := preload("res://assets/player_shades_black.png")
const TEX_ARMOR_TIERS: Array[Texture2D] = [
	preload("res://assets/armor/armor_tier_1.png"),
	preload("res://assets/armor/armor_tier_2.png"),
	preload("res://assets/armor/armor_tier_3.png"),
	preload("res://assets/armor/armor_tier_4.png"),
	preload("res://assets/armor/armor_tier_5.png"),
	preload("res://assets/armor/armor_tier_6.png"),
	preload("res://assets/armor/armor_tier_7.png"),
]
const TEX_WEAPON_TIERS: Array[Texture2D] = [
	preload("res://assets/weapons/weapon_tier_1.png"),
	preload("res://assets/weapons/weapon_tier_2.png"),
	preload("res://assets/weapons/weapon_tier_3.png"),
	preload("res://assets/weapons/weapon_tier_4.png"),
	preload("res://assets/weapons/weapon_tier_5.png"),
	preload("res://assets/weapons/weapon_tier_6.png"),
	preload("res://assets/weapons/weapon_tier_7.png"),
]

const TEX_ICON_DAMAGE := preload("res://assets/upg_icon_damage.png")
const TEX_ICON_AMMO := preload("res://assets/upg_icon_ammo.png")
const TEX_ICON_HP := preload("res://assets/upg_icon_hp.png")
const TEX_ICON_MEDKIT := preload("res://assets/upg_icon_medkit.png")
const TEX_ICON_GRENADE := preload("res://assets/upg_icon_grenade.png")
const TEX_ICON_COINS := preload("res://assets/upg_icon_coins.png")

const UI_OLIVE := Color(0.608, 0.569, 0.392, 1.0)
const UI_OLIVE_HI := Color(0.753, 0.714, 0.514, 1.0)
const UI_OLIVE_LO := Color(0.431, 0.400, 0.255, 1.0)
const UI_OLIVE_DARK := Color(0.302, 0.282, 0.176, 1.0)
const UI_INK := Color(0.063, 0.071, 0.082, 1.0)
const UI_STEEL := Color(0.451, 0.467, 0.431, 1.0)
const UI_STEEL_HI := Color(0.616, 0.631, 0.592, 1.0)
const UI_STEEL_LO := Color(0.286, 0.298, 0.271, 1.0)
const UI_WELL := Color(0.082, 0.090, 0.098, 1.0)
const UI_TRAY := Color(0.220, 0.235, 0.204, 1.0)

const UPGRADE_DEFS: Array[Dictionary] = [
	{
		"key": "damage",
		"short_title": "ВАЖКИЙ СТВОЛ",
		"title": "Важкий Нарізний Ствол",
		"category": "weapon",
		"category_label": "МОДУЛЬ ЗБРОЇ",
		"desc": "Послідовне покращення штурмової гвинтівки (7 рівнів модифікації): відкриває тактичні обвіси, глушник, оптику, барабанний магазин і +3 урону за рівень.",
		"accent": Color(0.94, 0.56, 0.24, 1.0),
		"part_uv": Vector2(0.56, 0.45),
		"part_name": "ОЗБРОЄННЯ",
	},
	{
		"key": "ammo",
		"short_title": "ПОЛІПШЕНІ ПАТРОНИ",
		"title": "Поліпшені Бронебійні Патрони",
		"category": "weapon",
		"category_label": "МОДУЛЬ ЗБРОЇ",
		"desc": "Високошвидкісні кулі з вольфрамовим осердям: вища швидкість польоту та шанс критичного пострілу (x1.75 урону).",
		"accent": Color(0.96, 0.44, 0.30, 1.0),
		"part_uv": Vector2(0.52, 0.37),
		"part_name": "БОЄКОМПЛЕКТ",
	},
	{
		"key": "hp",
		"short_title": "ТИТАН-БРОНЯ",
		"title": "Комплект Броні (HP)",
		"category": "defense",
		"category_label": "МОДУЛЬ ЗАХИСТУ",
		"desc": "Послідовне покращення тактичної броні оперативника (7 рівнів спорядження): кожен рівень збільшує запас здоров'я на +25 HP.",
		"accent": Color(0.90, 0.34, 0.30, 1.0),
		"part_uv": Vector2(0.50, 0.31),
		"part_name": "БРОНЕКОМПЛЕКТ",
	},
	{
		"key": "medkit",
		"short_title": "АПТЕЧКА [F]",
		"title": "Польовий Автоін'єктор [F]",
		"category": "tactics",
		"category_label": "ТАКТИЧНИЙ МОДУЛЬ",
		"desc": "Бойові стимулятори скорочують час відновлення аптечки для швидкого порятунку під вогнем.",
		"accent": Color(0.38, 0.84, 0.54, 1.0),
		"part_uv": Vector2(0.44, 0.42),
		"part_name": "МЕД-ПІДСУМОК",
	},
	{
		"key": "grenade",
		"short_title": "ГРАНАТА [G]",
		"title": "Уламкова Граната М67 [G]",
		"category": "tactics",
		"category_label": "ТАКТИЧНИЙ МОДУЛЬ",
		"desc": "Посилений заряд вибухівки збільшує урон гранати та пришвидшує підготовку наступного кидка.",
		"accent": Color(0.94, 0.52, 0.24, 1.0),
		"part_uv": Vector2(0.54, 0.48),
		"part_name": "ТАКТИЧНИЙ ПОЯС",
	},
	{
		"key": "coins",
		"short_title": "МАРОДЕР [$]",
		"title": "Тактичний Сканер Трофеїв",
		"category": "tactics",
		"category_label": "ТАКТИЧНИЙ МОДУЛЬ",
		"desc": "Автоматичний збір цінних даних і трофеїв збільшує кількість монет за кожного знищеного ворога.",
		"accent": Color(0.96, 0.80, 0.30, 1.0),
		"part_uv": Vector2(0.32, 0.25),
		"part_name": "РАДІОРАНЕЦЬ",
	},
]

@onready var panel_frame: ColorRect = $PanelFrame
@onready var header_bar: ColorRect = $PanelFrame/HeaderBar
@onready var body_box: ColorRect = $PanelFrame/BodyBox
@onready var level_label: Label = $PanelFrame/HeaderBar/LevelLabel
@onready var title_label: Label = $PanelFrame/HeaderBar/TitleLabel
@onready var coins_label: Label = $PanelFrame/HeaderBar/CoinsLabel
@onready var earned_label: Label = $PanelFrame/BodyBox/EarnedLabel
@onready var upgrades_container: VBoxContainer = $PanelFrame/BodyBox/UpgradesContainer
@onready var next_button: TextureButton = $NextButton
@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_transitioning: bool = false
var _selected_key: String = "damage"
var _hovered_key: String = ""
var _active_category: String = "all"

var _tiles_by_key: Dictionary = {}
var _cat_buttons: Dictionary = {}
var _skin_buttons: Dictionary = {}
var _filter_buttons: Dictionary = {}

var _showcase_canvas: _SoldierShowcaseCanvas = null
var _stats_summary_label: RichTextLabel = null
var _earned_header_badge: Label = null

# Inspector UI refs
var _insp_icon_rect: TextureRect = null
var _insp_cat_label: Label = null
var _insp_title_label: Label = null
var _insp_lvl_label: Label = null
var _insp_segments_canvas: _LevelSegmentsCanvas = null
var _insp_desc_label: Label = null
var _insp_stat_curr_label: Label = null
var _insp_stat_next_label: Label = null
var _insp_buy_button: Button = null
var _insp_accent_frame: _BevelPanelCanvas = null

var _atmosphere_overlay: _AtmosphereFilterCanvas = null

# Procedural audio
var _sfx_player: AudioStreamPlayer = null
var _sfx_click: AudioStreamWAV = null
var _sfx_buy: AudioStreamWAV = null
var _sfx_skin: AudioStreamWAV = null
var _sfx_error: AudioStreamWAV = null

var _back_button: TextureButton = null
var _dev_add_coins_button: Button = null


func _ready() -> void:
	GAME_STATE.apply_audio_settings()
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null)

	_init_audio()
	_setup_chassis_and_zones()
	_setup_back_button()
	_setup_dev_test_controls()
	_refresh_ui()

	next_button.pressed.connect(_on_next_pressed)
	next_button.mouse_entered.connect(_on_button_hover.bind(next_button, true))
	next_button.mouse_exited.connect(_on_button_hover.bind(next_button, false))

	fade_overlay.color = Color(0, 0, 0, 1)
	var tw := create_tween()
	tw.tween_property(fade_overlay, "color:a", 0.0, 0.38).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _unhandled_input(event: InputEvent) -> void:
	if _is_transitioning:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			_on_buy_selected_pressed()
		elif event.keycode == KEY_ESCAPE:
			_on_back_pressed()


func _get_icon_texture(key: String) -> Texture2D:
	match key:
		"damage": return TEX_ICON_DAMAGE
		"ammo": return TEX_ICON_AMMO
		"hp": return TEX_ICON_HP
		"medkit": return TEX_ICON_MEDKIT
		"grenade": return TEX_ICON_GRENADE
		"coins": return TEX_ICON_COINS
	return TEX_ICON_DAMAGE


func _get_def(key: String) -> Dictionary:
	for d in UPGRADE_DEFS:
		if String(d["key"]) == key:
			return d
	return UPGRADE_DEFS[0]


func _get_skin_texture(skin_id: String) -> Texture2D:
	match skin_id:
		"shades_gold": return TEX_SOLDIER_GOLD
		"shades_cyber": return TEX_SOLDIER_CYBER
		"shades_black": return TEX_SOLDIER_BLACK
		_: return TEX_SOLDIER_STD


func _get_armor_tier_texture(tier: int) -> Texture2D:
	var idx := clampi(tier - 1, 0, TEX_ARMOR_TIERS.size() - 1)
	return TEX_ARMOR_TIERS[idx]


func _get_weapon_tier_texture(tier: int) -> Texture2D:
	var idx := clampi(tier - 1, 0, TEX_WEAPON_TIERS.size() - 1)
	return TEX_WEAPON_TIERS[idx]


# ── Побудова 3-зонного інтерфейсу «Тактичний Арсенал» ────────────────────────

func _setup_chassis_and_zones() -> void:
	upgrades_container.visible = false
	earned_label.visible = false

	# Прозорий фон-обгортка та злегка приглушений задній план окопів, щоб термінал виділявся об'ємом
	var dark_bg := get_node_or_null("DarkBackdrop") as ColorRect
	if dark_bg != null:
		dark_bg.color = Color(0.03, 0.04, 0.045, 0.54)

	panel_frame.clip_contents = false
	panel_frame.color = Color(0.0, 0.0, 0.0, 0.0)
	header_bar.color = Color(0.0, 0.0, 0.0, 0.0)
	body_box.color = Color(0.0, 0.0, 0.0, 0.0)

	# Головне оливково-латунне шасі терміналу з шестернями, аркою заголовка, заклепками та сканлайнами
	var console_chassis := _ConsoleChassisCanvas.new()
	console_chassis.position = Vector2.ZERO
	console_chassis.size = Vector2(1232.0, 606.0)
	console_chassis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel_frame.add_child(console_chassis)
	panel_frame.move_child(console_chassis, 0)

	# Верхня шапка: зліва рівень, у центрі CRT-арка назви, справа монети + іконка
	level_label.position = Vector2(28, 12)
	level_label.size = Vector2(364, 42)
	level_label.add_theme_font_size_override("font_size", 18)
	level_label.add_theme_color_override("font_color", Color(0.96, 0.94, 0.86, 1.0))

	title_label.position = Vector2(418, -4)
	title_label.size = Vector2(396, 56)
	title_label.text = "ТАКТИЧНИЙ АРСЕНАЛ"
	title_label.add_theme_font_size_override("font_size", 26)
	title_label.add_theme_color_override("font_color", Color(0.96, 0.96, 0.94, 1.0))

	coins_label.position = Vector2(936, 9)
	coins_label.size = Vector2(256, 28)
	coins_label.add_theme_font_size_override("font_size", 21)
	coins_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.34, 1.0))

	_earned_header_badge = Label.new()
	_earned_header_badge.position = Vector2(936, 33)
	_earned_header_badge.size = Vector2(256, 20)
	_earned_header_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_earned_header_badge.add_theme_font_size_override("font_size", 12)
	_earned_header_badge.add_theme_color_override("font_color", Color(0.58, 0.95, 0.62, 0.98))
	_earned_header_badge.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	_earned_header_badge.add_theme_constant_override("outline_size", 3)
	header_bar.add_child(_earned_header_badge)

	# ── 1. ЛІВА ЗОНА: ОПЕРАТИВНИК З АВТОМАТОМ + СКІНИ ОКУЛЯРІВ (x=12..324) ──
	var left_zone := Control.new()
	left_zone.position = Vector2(12, 10)
	left_zone.size = Vector2(312, 510)
	body_box.add_child(left_zone)

	var left_plate := _ZonePlateCanvas.new()
	left_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_plate.title_text = "ОПЕРАТИВНИК"
	left_plate.title_width = 164.0
	left_zone.add_child(left_plate)

	# Інтерактивна вітрина бійця з автоматом (повний непрозорий колір бійця)
	_showcase_canvas = _SoldierShowcaseCanvas.new()
	_showcase_canvas.position = Vector2(12, 34)
	_showcase_canvas.size = Vector2(288, 250)
	left_zone.add_child(_showcase_canvas)

	# Панель вибору скіна (Окуляри / Шолом)
	var skin_title := Label.new()
	skin_title.position = Vector2(12, 290)
	skin_title.size = Vector2(288, 18)
	skin_title.text = "СКІН БІЙЦЯ (ТАКТИЧНІ ОКУЛЯРИ):"
	skin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_title.add_theme_font_size_override("font_size", 11)
	skin_title.add_theme_color_override("font_color", Color(0.95, 0.93, 0.84))
	skin_title.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.95))
	skin_title.add_theme_constant_override("outline_size", 3)
	left_zone.add_child(skin_title)

	var skin_row := HBoxContainer.new()
	skin_row.position = Vector2(10, 310)
	skin_row.size = Vector2(292, 32)
	skin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skin_row.add_theme_constant_override("separation", 4)
	left_zone.add_child(skin_row)

	var skins_meta := [
		{"id": "shades_gold", "label": "ЗОЛОТІ"},
		{"id": "shades_cyber", "label": "КІБЕР"},
		{"id": "shades_black", "label": "ЧОРНІ"},
		{"id": "standard", "label": "ШОЛОМ"},
	]
	for sm in skins_meta:
		var sid := String(sm["id"])
		var sbtn := _make_tactical_pill_button(String(sm["label"]), Vector2(70, 30), 11, 18)
		var mini_icon := _SkinMiniIcon.new()
		mini_icon.skin_id = sid
		mini_icon.position = Vector2(5, 7)
		mini_icon.size = Vector2(15, 16)
		mini_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sbtn.add_child(mini_icon)
		sbtn.pressed.connect(_on_skin_selected.bind(sid))
		skin_row.add_child(sbtn)
		_skin_buttons[sid] = sbtn

	# Зведення бойових характеристик бійця (у заглибленому екрані з латунним повзунком)
	var stats_well := _RoundedWellCanvas.new()
	stats_well.position = Vector2(12, 348)
	stats_well.size = Vector2(288, 150)
	stats_well.bg_color = Color(0.086, 0.094, 0.106, 0.98)
	stats_well.border_color = Color(0.06, 0.07, 0.08, 1.0)
	stats_well.accent_rim_color = Color(0.56, 0.50, 0.34, 0.72)
	stats_well.corner_radius = 8
	left_zone.add_child(stats_well)

	_stats_summary_label = RichTextLabel.new()
	_stats_summary_label.position = Vector2(18, 353)
	_stats_summary_label.size = Vector2(276, 140)
	_stats_summary_label.bbcode_enabled = true
	_stats_summary_label.scroll_active = true
	_stats_summary_label.scroll_following = false
	_stats_summary_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_stats_summary_label.add_theme_font_size_override("normal_font_size", 13)
	_stats_summary_label.add_theme_font_size_override("bold_font_size", 13)
	_style_stats_scrollbar(_stats_summary_label)
	left_zone.add_child(_stats_summary_label)

	# ── 2. ЦЕНТРАЛЬНА ЗОНА: ФІЛЬТРИ КАТЕГОРІЙ + СІТКА ІКОНОК 3x3 (x=334..826) ──
	var center_zone := Control.new()
	center_zone.position = Vector2(334, 10)
	center_zone.size = Vector2(492, 510)
	body_box.add_child(center_zone)

	var center_plate := _ZonePlateCanvas.new()
	center_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_plate.title_text = ""
	center_zone.add_child(center_plate)

	# Заглиблена рамка панелі фільтрів
	var cat_well := _RoundedWellCanvas.new()
	cat_well.position = Vector2(12, 10)
	cat_well.size = Vector2(468, 38)
	cat_well.bg_color = Color(0.11, 0.12, 0.11, 0.96)
	cat_well.border_color = Color(0.06, 0.07, 0.08, 1.0)
	cat_well.accent_rim_color = Color(0.54, 0.50, 0.36, 0.72)
	cat_well.corner_radius = 8
	center_zone.add_child(cat_well)

	# Панель категорій-фільтрів зверху центральної зони
	var cat_bar := HBoxContainer.new()
	cat_bar.position = Vector2(15, 13)
	cat_bar.size = Vector2(462, 32)
	cat_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	cat_bar.add_theme_constant_override("separation", 5)
	center_zone.add_child(cat_bar)

	var cats_meta := [
		{"id": "all", "label": "ВСІ [6]"},
		{"id": "weapon", "label": "ЗБРОЯ [2]"},
		{"id": "defense", "label": "ЗАХИСТ [1]"},
		{"id": "tactics", "label": "ТАКТИКА [3]"},
		{"id": "affordable", "label": "ДОСТУПНІ [$]"},
	]
	for cm in cats_meta:
		var cbtn := _make_tactical_pill_button(String(cm["label"]), Vector2(88, 30), 12)
		var cid := String(cm["id"])
		cbtn.pressed.connect(_on_category_filter_selected.bind(cid))
		cat_bar.add_child(cbtn)
		_cat_buttons[cid] = cbtn

	# Сітка 3x2 іконок характеристик (більші об'ємні картки для 6 модулів)
	var grid_root := Control.new()
	grid_root.position = Vector2(14, 62)
	grid_root.size = Vector2(464, 434)
	center_zone.add_child(grid_root)

	var tile_w := 148.0
	var tile_h := 204.0
	var gap_x := 10.0
	var gap_y := 14.0

	for idx in range(UPGRADE_DEFS.size()):
		var def: Dictionary = UPGRADE_DEFS[idx]
		var key := String(def["key"])
		var col := idx % 3
		var row := idx / 3
		var tile := _UpgradeTile.new()
		tile.position = Vector2(col * (tile_w + gap_x), row * (tile_h + gap_y))
		tile.size = Vector2(tile_w, tile_h)
		tile.setup(def, _get_icon_texture(key))
		tile.tile_clicked.connect(_on_tile_clicked.bind(key))
		tile.tile_double_clicked.connect(_on_tile_double_clicked.bind(key))
		tile.tile_hovered.connect(_on_tile_hovered.bind(key))
		grid_root.add_child(tile)
		_tiles_by_key[key] = tile

	# ── 3. ПРАВА ЗОНА: ІНСПЕКТОР ОБРАНОГО МОДУЛЯ ТА КУПІВЛЯ (x=836..1208) ──
	var right_zone := Control.new()
	right_zone.position = Vector2(836, 10)
	right_zone.size = Vector2(372, 510)
	body_box.add_child(right_zone)

	var right_plate := _ZonePlateCanvas.new()
	right_plate.set_anchors_preset(Control.PRESET_FULL_RECT)
	right_plate.title_text = "ІНСПЕКТОР ХАРАКТЕРИСТИКИ"
	right_plate.title_width = 236.0
	right_zone.add_child(right_plate)
	_insp_accent_frame = null

	# Верхній блок інспектора: уніфіковане заглиблене гніздо іконки з золотою восьмикутною рамкою
	var icon_well := _UniformSocketCanvas.new()
	icon_well.position = Vector2(16, 36)
	icon_well.size = Vector2(96, 96)
	right_zone.add_child(icon_well)

	_insp_icon_rect = TextureRect.new()
	_insp_icon_rect.position = Vector2(28, 48)
	_insp_icon_rect.size = Vector2(72, 72)
	_insp_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_insp_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_zone.add_child(_insp_icon_rect)

	_insp_cat_label = Label.new()
	_insp_cat_label.position = Vector2(124, 38)
	_insp_cat_label.size = Vector2(232, 20)
	_insp_cat_label.add_theme_font_size_override("font_size", 12)
	_insp_cat_label.add_theme_color_override("font_color", Color(0.95, 0.78, 0.36))
	_insp_cat_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.95))
	_insp_cat_label.add_theme_constant_override("outline_size", 3)
	right_zone.add_child(_insp_cat_label)

	_insp_title_label = Label.new()
	_insp_title_label.position = Vector2(124, 58)
	_insp_title_label.size = Vector2(232, 52)
	_insp_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_title_label.add_theme_font_size_override("font_size", 18)
	_insp_title_label.add_theme_color_override("font_color", Color(0.98, 0.96, 0.90))
	_insp_title_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.95))
	_insp_title_label.add_theme_constant_override("outline_size", 4)
	right_zone.add_child(_insp_title_label)

	_insp_lvl_label = Label.new()
	_insp_lvl_label.position = Vector2(124, 110)
	_insp_lvl_label.size = Vector2(232, 22)
	_insp_lvl_label.add_theme_font_size_override("font_size", 14)
	_insp_lvl_label.add_theme_color_override("font_color", Color(0.84, 0.92, 0.98))
	_insp_lvl_label.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.95))
	_insp_lvl_label.add_theme_constant_override("outline_size", 3)
	right_zone.add_child(_insp_lvl_label)

	# 5-сегментна інтерактивна шкала рівня в стилі броньованої консолі
	_insp_segments_canvas = _LevelSegmentsCanvas.new()
	_insp_segments_canvas.position = Vector2(16, 142)
	_insp_segments_canvas.size = Vector2(340, 36)
	right_zone.add_child(_insp_segments_canvas)

	# Опис модуля
	var desc_well := _RoundedWellCanvas.new()
	desc_well.position = Vector2(16, 186)
	desc_well.size = Vector2(340, 96)
	desc_well.bg_color = Color(0.09, 0.098, 0.108, 0.97)
	desc_well.border_color = Color(0.06, 0.07, 0.08, 1.0)
	desc_well.accent_rim_color = Color(0.46, 0.44, 0.34, 0.65)
	desc_well.corner_radius = 8
	right_zone.add_child(desc_well)

	_insp_desc_label = Label.new()
	_insp_desc_label.position = Vector2(26, 194)
	_insp_desc_label.size = Vector2(320, 80)
	_insp_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_desc_label.add_theme_font_size_override("font_size", 14)
	_insp_desc_label.add_theme_color_override("font_color", Color(0.88, 0.87, 0.80))
	right_zone.add_child(_insp_desc_label)

	# Порівняння показників: Поточний -> Наступний рівень
	var stat_box := _RoundedWellCanvas.new()
	stat_box.position = Vector2(16, 290)
	stat_box.size = Vector2(340, 110)
	stat_box.bg_color = Color(0.09, 0.098, 0.108, 0.97)
	stat_box.border_color = Color(0.06, 0.07, 0.08, 1.0)
	stat_box.accent_rim_color = Color(0.46, 0.44, 0.34, 0.65)
	stat_box.corner_radius = 8
	right_zone.add_child(stat_box)

	var stat_hdr := Label.new()
	stat_hdr.position = Vector2(26, 297)
	stat_hdr.size = Vector2(320, 20)
	stat_hdr.text = "БОЙОВА ЕФЕКТИВНІСТЬ МОДУЛЯ:"
	stat_hdr.add_theme_font_size_override("font_size", 12)
	stat_hdr.add_theme_color_override("font_color", Color(0.84, 0.78, 0.58))
	right_zone.add_child(stat_hdr)

	_insp_stat_curr_label = Label.new()
	_insp_stat_curr_label.position = Vector2(26, 321)
	_insp_stat_curr_label.size = Vector2(320, 32)
	_insp_stat_curr_label.add_theme_font_size_override("font_size", 15)
	_insp_stat_curr_label.add_theme_color_override("font_color", Color(0.95, 0.94, 0.88))
	right_zone.add_child(_insp_stat_curr_label)

	_insp_stat_next_label = Label.new()
	_insp_stat_next_label.position = Vector2(26, 355)
	_insp_stat_next_label.size = Vector2(320, 36)
	_insp_stat_next_label.add_theme_font_size_override("font_size", 16)
	_insp_stat_next_label.add_theme_color_override("font_color", Color(0.48, 0.96, 0.58))
	right_zone.add_child(_insp_stat_next_label)

	# Велика тактична кнопка КУПИТИ МОДУЛЬ з заклепками та відблиском
	_insp_buy_button = Button.new()
	_insp_buy_button.position = Vector2(16, 412)
	_insp_buy_button.size = Vector2(340, 62)
	_insp_buy_button.focus_mode = Control.FOCUS_NONE
	_insp_buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_insp_buy_button.add_theme_font_size_override("font_size", 20)
	_insp_buy_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_insp_buy_button.add_theme_constant_override("outline_size", 5)
	_insp_buy_button.pressed.connect(_on_buy_selected_pressed)
	right_zone.add_child(_insp_buy_button)

	var buy_decor := _BuyButtonDecor.new()
	buy_decor.set_anchors_preset(Control.PRESET_FULL_RECT)
	buy_decor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_insp_buy_button.add_child(buy_decor)

	var hint_lbl := Label.new()
	hint_lbl.position = Vector2(16, 480)
	hint_lbl.size = Vector2(340, 22)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.text = "Подвійний клік по іконці або [Enter] — швидка купівля"
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.add_theme_color_override("font_color", Color(0.86, 0.84, 0.74))
	hint_lbl.add_theme_color_override("font_outline_color", Color(0.05, 0.06, 0.07, 0.9))
	hint_lbl.add_theme_constant_override("outline_size", 3)
	right_zone.add_child(hint_lbl)

	# ── 4. ПОВНОЕКРАННИЙ ВІЗУАЛЬНИЙ ФІЛЬТР (БУНКЕР / ТЕПЛОВІЗОР / НВБ / РАДАР) ──
	_atmosphere_overlay = _AtmosphereFilterCanvas.new()
	_atmosphere_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_atmosphere_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_atmosphere_overlay)
	move_child(fade_overlay, get_child_count() - 1)


func _make_tactical_pill_button(txt: String, min_sz: Vector2, font_sz: int, left_pad: int = 0) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = min_sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text = txt
	btn.set_meta("_left_pad", left_pad)
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.92))
	btn.add_theme_constant_override("outline_size", 3)
	return btn


func _style_pill_button(btn: Button, active: bool, accent: Color = Color(0.86, 0.74, 0.42)) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.32, 0.29, 0.18, 0.98) if active else Color(0.16, 0.17, 0.16, 0.96)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = accent if active else Color(0.06, 0.07, 0.08, 0.95)
	normal.set_corner_radius_all(6)
	var left_pad := int(btn.get_meta("_left_pad", 0))
	if left_pad > 0:
		normal.content_margin_left = float(left_pad)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.14)
	hover.border_color = accent.lightened(0.18)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override(
		"font_color",
		Color(1.0, 0.95, 0.76) if active else Color(0.86, 0.85, 0.78)
	)


func _style_stats_scrollbar(rtl: RichTextLabel) -> void:
	var vbar := rtl.get_v_scroll_bar()
	if vbar == null:
		return
	vbar.custom_minimum_size = Vector2(8.0, 0.0)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.08, 0.09, 0.11, 0.92)
	track.border_color = Color(0.32, 0.28, 0.20, 0.85)
	track.set_border_width_all(1)
	track.set_corner_radius_all(3)
	track.content_margin_left = 4
	track.content_margin_right = 4

	var grabber := StyleBoxFlat.new()
	grabber.bg_color = Color(0.76, 0.64, 0.36, 0.95)
	grabber.set_corner_radius_all(3)

	var grabber_hi := grabber.duplicate() as StyleBoxFlat
	grabber_hi.bg_color = Color(0.95, 0.82, 0.48, 1.0)

	vbar.add_theme_stylebox_override("scroll", track)
	vbar.add_theme_stylebox_override("grabber", grabber)
	vbar.add_theme_stylebox_override("grabber_highlight", grabber_hi)
	vbar.add_theme_stylebox_override("grabber_pressed", grabber_hi)


# ── Оновлення стану всіх зон ─────────────────────────────────────────────────

func _refresh_ui() -> void:
	var lvl_mult: int = int(round((GAME_STATE.get_enemy_health_multiplier_for_level() - 1.0) * 100.0))
	level_label.text = "РІВЕНЬ %d / %d  •  ХП ворогів: +%d%%" % [
		GAME_STATE.current_level,
		GAME_STATE.TOTAL_LEVELS,
		lvl_mult
	]
	coins_label.text = "МОНЕТИ: $%d" % GAME_STATE.coins
	if _earned_header_badge != null:
		_earned_header_badge.text = "За попередній бій: +$%d" % GAME_STATE.last_level_earned

	# Оновлюємо кнопки фільтрів візора
	for fid in _filter_buttons.keys():
		var fbtn: Button = _filter_buttons[fid]
		_style_pill_button(fbtn, GAME_STATE.visual_filter == fid, Color(0.48, 0.88, 0.96))
	if _atmosphere_overlay != null:
		_atmosphere_overlay.filter_mode = GAME_STATE.visual_filter
		_atmosphere_overlay.queue_redraw()

	# Оновлюємо кнопки скіна бійця
	for sid in _skin_buttons.keys():
		var sbtn: Button = _skin_buttons[sid]
		_style_pill_button(sbtn, GAME_STATE.hero_skin == sid, Color(0.95, 0.78, 0.32))

	# Оновлюємо вітрину бійця: прев'ю наступної броні ("hp") або прев'ю наступної модифікації зброї ("damage") до покупки!
	var inspect_key := _hovered_key if not _hovered_key.is_empty() else _selected_key
	var inspect_def := _get_def(inspect_key)
	var equipped_tier := GAME_STATE.get_armor_tier()
	var max_armor_tier := 1 + GAME_STATE.get_max_upgrade_level("hp")
	var is_armor_preview := (inspect_key == "hp") and (equipped_tier < max_armor_tier)
	var display_tier := (equipped_tier + 1) if is_armor_preview else equipped_tier

	var equipped_weapon_tier := GAME_STATE.get_weapon_tier()
	var max_weapon_tier := 1 + GAME_STATE.get_max_upgrade_level("damage")
	var is_weapon_preview := (inspect_key == "damage") and (equipped_weapon_tier < max_weapon_tier)
	var display_weapon_tier := (equipped_weapon_tier + 1) if is_weapon_preview else equipped_weapon_tier

	if _showcase_canvas != null:
		_showcase_canvas.soldier_tex = _get_armor_tier_texture(display_tier)
		_showcase_canvas.weapon_tex = _get_weapon_tier_texture(display_weapon_tier)
		_showcase_canvas.skin_id = GAME_STATE.hero_skin
		_showcase_canvas.filter_mode = GAME_STATE.visual_filter
		_showcase_canvas.armor_tier = equipped_tier
		_showcase_canvas.display_tier = display_tier
		_showcase_canvas.is_armor_preview = is_armor_preview
		_showcase_canvas.weapon_tier = equipped_weapon_tier
		_showcase_canvas.weapon_display_tier = display_weapon_tier
		_showcase_canvas.is_weapon_preview = is_weapon_preview
		_showcase_canvas.highlight_uv = inspect_def["part_uv"]
		if is_armor_preview:
			_showcase_canvas.highlight_label = "ПРЕВ'Ю: БРОНЯ РІВ.%d" % display_tier
			_showcase_canvas.highlight_color = Color(0.98, 0.80, 0.28)
		elif is_weapon_preview:
			_showcase_canvas.highlight_label = "ПРЕВ'Ю: ЗБРОЯ РІВ.%d" % display_weapon_tier
			_showcase_canvas.highlight_color = Color(0.98, 0.72, 0.28)
		else:
			_showcase_canvas.highlight_label = String(inspect_def["part_name"])
			_showcase_canvas.highlight_color = inspect_def["accent"]
		_showcase_canvas.queue_redraw()

	# Оновлюємо зведення характеристик під бійцем
	if _stats_summary_label != null:
		var skin_name := "Золотий Хижак"
		if GAME_STATE.hero_skin == "shades_cyber":
			skin_name = "Кібер-Неон"
		elif GAME_STATE.hero_skin == "shades_black":
			skin_name = "Чорні // ВЕНОМ"
		elif GAME_STATE.hero_skin == "standard":
			skin_name = "Стандартний Шолом"
		var dps := float(GAME_STATE.get_player_bullet_damage()) * 10.0
		var crit_pct := int(round(GAME_STATE.get_player_crit_chance() * 100.0))
		var coin_pct := int(round((GAME_STATE.get_coin_multiplier() - 1.0) * 100.0))
		_stats_summary_label.text = (
			"[color=#dfc478][b]ЗВЕДЕННЯ ОПЕРАТИВНИКА[/b][/color]\n[color=#8fa4b8]Скін: %s[/color]\n" % skin_name
			+ "• Зброя: [color=#ffd070][b]Рівень %d / 7[/b][/color]  |  Броня: [color=#7cd6ff][b]Рів.%d/7[/b][/color]\n" % [equipped_weapon_tier, equipped_tier]
			+ "• Здоров'я: [color=#ff8a7a][b]%d HP[/b][/color]\n" % int(roundf(GAME_STATE.get_player_max_health()))
			+ "• Урон автомата: [color=#ffb85c][b]%d[/b][/color]  |  Темп: [color=#ffd86b][b]10.0/с[/b][/color]\n" % int(roundf(GAME_STATE.get_player_bullet_damage()))
			+ "• Вогнева потужність: [color=#ffe28a][b]%d DPS[/b][/color]\n" % int(round(dps))
			+ "• Швидк. кулі: [color=#e5d29c][b]%d[/b][/color]  |  Крит (×1.75): [color=#ff7a66][b]%d%%[/b][/color]\n" % [int(roundf(GAME_STATE.get_player_bullet_speed())), crit_pct]
			+ "• Польова аптечка [2]: [color=#6ee89a][b]КД %dс[/b][/color]\n" % int(round(GAME_STATE.get_player_medkit_cooldown()))
			+ "• Граната М67 [1]: [color=#ff9e5e][b]%d урону[/b][/color] (КД [b]%dс[/b])\n" % [int(roundf(GAME_STATE.get_player_grenade_damage())), int(round(GAME_STATE.get_player_grenade_cooldown()))]
			+ "• Бонус трофеїв: [color=#ffe066][b]+%d%% монет[/b][/color]" % coin_pct
		)

	# Оновлюємо кнопки категорій
	for cid in _cat_buttons.keys():
		var cbtn: Button = _cat_buttons[cid]
		_style_pill_button(cbtn, _active_category == cid, Color(0.92, 0.76, 0.36))

	# Оновлюємо всі плитки у сітці
	for def in UPGRADE_DEFS:
		var key := String(def["key"])
		var tile: _UpgradeTile = _tiles_by_key.get(key)
		if tile == null:
			continue
		var lvl := GAME_STATE.get_upgrade_level(key)
		var max_lvl := GAME_STATE.get_max_upgrade_level(key)
		var maxed := not GAME_STATE.can_upgrade(key)
		var cost := GAME_STATE.get_upgrade_cost(key)
		var can_afford := (not maxed) and (GAME_STATE.coins >= cost)
		var matches_filter := _does_def_match_filter(def, can_afford)
		tile.update_state(lvl, max_lvl, cost, can_afford, maxed, key == _selected_key, matches_filter)

	# Оновлюємо правий Інспектор
	_refresh_inspector(inspect_def)


func _does_def_match_filter(def: Dictionary, can_afford: bool) -> bool:
	match _active_category:
		"all": return true
		"affordable": return can_afford
		_: return String(def["category"]) == _active_category


func _refresh_inspector(def: Dictionary) -> void:
	var key := String(def["key"])
	var lvl := GAME_STATE.get_upgrade_level(key)
	var max_lvl := GAME_STATE.get_max_upgrade_level(key)
	var maxed := not GAME_STATE.can_upgrade(key)
	var cost := GAME_STATE.get_upgrade_cost(key)
	var can_afford := (not maxed) and (GAME_STATE.coins >= cost)
	var accent: Color = def["accent"]

	_insp_icon_rect.texture = _get_icon_texture(key)
	_insp_cat_label.text = String(def["category_label"])
	_insp_cat_label.add_theme_color_override("font_color", accent.lightened(0.15))
	_insp_title_label.text = String(def["title"])
	_insp_lvl_label.text = "РІВЕНЬ МОДУЛЯ: %d / %d" % [lvl, max_lvl]
	_insp_desc_label.text = String(def["desc"])

	if _insp_accent_frame != null:
		_insp_accent_frame.border_color = accent.lerp(Color(0.74, 0.63, 0.38, 1.0), 0.45)
		_insp_accent_frame.queue_redraw()

	if _insp_segments_canvas != null:
		_insp_segments_canvas.current_level = lvl
		_insp_segments_canvas.max_level = max_lvl
		_insp_segments_canvas.accent_color = accent
		_insp_segments_canvas.can_afford_next = can_afford
		_insp_segments_canvas.queue_redraw()

	var pair := _get_stat_comparison_strings(key, lvl)
	_insp_stat_curr_label.text = "Поточний:  " + pair[0]
	if maxed:
		_insp_stat_next_label.text = "Досягнуто максимальної потужності (%d/%d)" % [max_lvl, max_lvl]
		_insp_stat_next_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.38))
	else:
		_insp_stat_next_label.text = "Наступний: " + pair[1]
		_insp_stat_next_label.add_theme_color_override("font_color", Color(0.48, 0.96, 0.58))

	_style_buy_button(maxed, can_afford, cost, max_lvl)


func _get_stat_comparison_strings(key: String, lvl: int) -> Array[String]:
	var nl := mini(lvl + 1, GAME_STATE.get_max_upgrade_level(key))
	match key:
		"damage":
			return ["Зброя Рів.%d • %d урону" % [1 + lvl, 10 + lvl * 3], "Зброя Рів.%d • %d урону (+3)" % [1 + nl, 10 + nl * 3]]
		"ammo":
			return ["Крит %d%% (x1.75) | Швидк. %d" % [lvl * 8, 1380 + lvl * 130], "Крит %d%% (+8%%) | Швидк. %d" % [nl * 8, 1380 + nl * 130]]
		"hp":
			return ["Броня Рів.%d • %d HP" % [1 + lvl, 100 + lvl * 25], "Броня Рів.%d • %d HP (+25)" % [1 + nl, 100 + nl * 25]]
		"medkit":
			return ["Перезарядка аптечки: %d сек" % (40 - lvl * 4), "Перезарядка аптечки: %d сек (-4с)" % (40 - nl * 4)]
		"grenade":
			return ["%d урону | КД %d сек" % [140 + lvl * 28, 30 - lvl * 3], "%d урону (+28) | КД %d сек (-3с)" % [140 + nl * 28, 30 - nl * 3]]
		"coins":
			return ["+%d%% монет з ворогів" % (lvl * 20), "+%d%% монет з ворогів (+20%%)" % (nl * 20)]
	return ["", ""]


func _style_buy_button(maxed: bool, can_afford: bool, cost: int, max_lvl: int = 5) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.set_corner_radius_all(9)
	sb_normal.border_width_left = 3
	sb_normal.border_width_top = 3
	sb_normal.border_width_right = 3
	sb_normal.border_width_bottom = 3
	sb_normal.shadow_color = Color(0.04, 0.045, 0.05, 0.92)
	sb_normal.shadow_size = 2
	sb_normal.shadow_offset = Vector2(0.0, 2.0)

	if maxed:
		_insp_buy_button.text = "МАКСИМАЛЬНИЙ РІВЕНЬ (%d/%d)" % [max_lvl, max_lvl]
		_insp_buy_button.disabled = true
		sb_normal.bg_color = Color(0.32, 0.26, 0.12, 0.98)
		sb_normal.border_color = Color(0.88, 0.74, 0.34, 0.96)
		_insp_buy_button.add_theme_color_override("font_disabled_color", Color(1.0, 0.90, 0.48))
	elif can_afford:
		_insp_buy_button.text = "КУПИТИ МОДУЛЬ  —  $%d" % cost
		_insp_buy_button.disabled = false
		sb_normal.bg_color = Color(0.14, 0.38, 0.20, 0.99)
		sb_normal.border_color = Color(0.46, 0.88, 0.54, 1.0)
		_insp_buy_button.add_theme_color_override("font_color", Color(0.96, 1.0, 0.94))
	else:
		_insp_buy_button.text = "НЕДОСТАТНЬО МОНЕТ ($%d)" % cost
		_insp_buy_button.disabled = true
		sb_normal.bg_color = Color(0.28, 0.12, 0.11, 0.98)
		sb_normal.border_color = Color(0.58, 0.24, 0.22, 0.95)
		_insp_buy_button.add_theme_color_override("font_disabled_color", Color(0.88, 0.38, 0.34))

	var sb_hover := sb_normal.duplicate() as StyleBoxFlat
	sb_hover.bg_color = sb_normal.bg_color.lightened(0.14)
	sb_hover.border_color = Color(0.98, 0.88, 0.48, 1.0)

	_insp_buy_button.add_theme_stylebox_override("normal", sb_normal)
	_insp_buy_button.add_theme_stylebox_override("hover", sb_hover)
	_insp_buy_button.add_theme_stylebox_override("pressed", sb_hover)
	_insp_buy_button.add_theme_stylebox_override("disabled", sb_normal)


# ── Обробники подій ──────────────────────────────────────────────────────────

func _on_tile_clicked(key: String) -> void:
	if _is_transitioning:
		return
	_selected_key = key
	_play_sfx(_sfx_click, -6.0)
	_refresh_ui()


func _on_tile_double_clicked(key: String) -> void:
	if _is_transitioning:
		return
	_selected_key = key
	_on_buy_selected_pressed()


func _on_tile_hovered(is_hovered: bool, key: String) -> void:
	if is_hovered:
		_hovered_key = key
	elif _hovered_key == key:
		_hovered_key = ""
	_refresh_ui()


func _on_buy_selected_pressed() -> void:
	if _is_transitioning:
		return
	if GAME_STATE.try_buy_upgrade(_selected_key):
		_play_sfx(_sfx_buy, -3.5)
		var def := _get_def(_selected_key)
		if _showcase_canvas != null:
			_showcase_canvas.trigger_upgrade_burst(def["part_uv"], def["accent"])
		var tile: _UpgradeTile = _tiles_by_key.get(_selected_key)
		if tile != null:
			tile.play_purchase_pulse()
		_refresh_ui()
	else:
		_play_sfx(_sfx_error, -5.0)


func _on_category_filter_selected(cat_id: String) -> void:
	_active_category = cat_id
	_play_sfx(_sfx_click, -6.0)
	# Якщо поточний обраний модуль не входить у категорію — обираємо перший модуль цієї категорії
	for def in UPGRADE_DEFS:
		var k := String(def["key"])
		var can_afford := GAME_STATE.can_upgrade(k) and GAME_STATE.coins >= GAME_STATE.get_upgrade_cost(k)
		if _does_def_match_filter(def, can_afford):
			if not _does_def_match_filter(_get_def(_selected_key), GAME_STATE.can_upgrade(_selected_key) and GAME_STATE.coins >= GAME_STATE.get_upgrade_cost(_selected_key)):
				_selected_key = k
			break
	_refresh_ui()


func _on_skin_selected(skin_id: String) -> void:
	GAME_STATE.hero_skin = skin_id
	_play_sfx(_sfx_skin, -4.0)
	if _showcase_canvas != null:
		_showcase_canvas.trigger_upgrade_burst(Vector2(0.43, 0.16), Color(0.98, 0.84, 0.38))
	_refresh_ui()


func _on_visual_filter_selected(filter_id: String) -> void:
	GAME_STATE.visual_filter = filter_id
	_play_sfx(_sfx_skin, -5.0)
	_refresh_ui()


# ── Нижня панель: Кнопка НАЗАД (ліворуч) та NEXT (праворуч) ──────────────────

func _setup_back_button() -> void:
	_back_button = get_node_or_null("BackButton") as TextureButton
	if _back_button == null:
		_back_button = TextureButton.new()
		_back_button.name = "BackButton"
		_back_button.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
		_back_button.offset_left = 24.0
		_back_button.offset_top = -94.0
		_back_button.offset_right = 316.0
		_back_button.offset_bottom = -10.0
		_back_button.pivot_offset = Vector2(146.0, 42.0)
		_back_button.focus_mode = Control.FOCUS_NONE
		_back_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		_back_button.texture_normal = TEX_BTN_BACK
		_back_button.ignore_texture_size = true
		_back_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
		add_child(_back_button)
	_back_button.pressed.connect(_on_back_pressed)
	_back_button.mouse_entered.connect(_on_button_hover.bind(_back_button, true))
	_back_button.mouse_exited.connect(_on_button_hover.bind(_back_button, false))
	if fade_overlay != null:
		move_child(fade_overlay, get_child_count() - 1)


func _setup_dev_test_controls() -> void:
	## Тимчасова тестова кнопка для швидкого додавання монет під час розробки.
	_dev_add_coins_button = GAME_STATE.create_test_button("ТЕСТ: +100 МОНЕТ", Color(0.24, 0.30, 0.16, 0.96))
	_dev_add_coins_button.name = "DevAddCoinsButton"
	_dev_add_coins_button.anchor_left = 0.5
	_dev_add_coins_button.anchor_top = 1.0
	_dev_add_coins_button.anchor_right = 0.5
	_dev_add_coins_button.anchor_bottom = 1.0
	_dev_add_coins_button.offset_left = -126.0
	_dev_add_coins_button.offset_top = -74.0
	_dev_add_coins_button.offset_right = 126.0
	_dev_add_coins_button.offset_bottom = -28.0
	_dev_add_coins_button.pivot_offset = Vector2(126.0, 23.0)
	_dev_add_coins_button.focus_mode = Control.FOCUS_NONE
	_dev_add_coins_button.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 0.92))
	_dev_add_coins_button.add_theme_constant_override("outline_size", 3)
	_dev_add_coins_button.pressed.connect(_on_dev_add_coins_pressed)
	_dev_add_coins_button.mouse_entered.connect(_on_button_hover.bind(_dev_add_coins_button, true))
	_dev_add_coins_button.mouse_exited.connect(_on_button_hover.bind(_dev_add_coins_button, false))
	add_child(_dev_add_coins_button)
	if fade_overlay != null:
		move_child(fade_overlay, get_child_count() - 1)


func _on_dev_add_coins_pressed() -> void:
	if _is_transitioning:
		return
	GAME_STATE.coins += 100
	_play_sfx(_sfx_buy, -6.0)
	_refresh_ui()


func _on_back_pressed() -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	_play_sfx(_sfx_skin, -4.0)
	var tw := create_tween()
	if _back_button != null:
		tw.tween_property(_back_button, "scale", Vector2(0.95, 0.95), 0.07).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_back_button, "scale", Vector2(1.02, 1.02), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(_enter_main_menu)


func _enter_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)


func _on_button_hover(btn: Control, is_hovered: bool) -> void:
	if _is_transitioning:
		return
	var target_scale := Vector2(1.04, 1.04) if is_hovered else Vector2.ONE
	var target_mod := Color(1.12, 1.08, 0.98, 1.0) if is_hovered else Color.WHITE
	var tw := create_tween().set_parallel(true)
	tw.tween_property(btn, "scale", target_scale, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "modulate", target_mod, 0.14).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_next_pressed() -> void:
	if _is_transitioning:
		return
	GAME_STATE.test_skip_to_boss = false
	GAME_STATE.test_boss_only_mode = false
	_start_battle_transition()


func _on_test_level_10_boss_pressed() -> void:
	if _is_transitioning:
		return
	GAME_STATE.jump_to_test_level_10(true)
	_start_battle_transition()


func _on_test_level_10_wave_pressed() -> void:
	if _is_transitioning:
		return
	GAME_STATE.jump_to_test_level_10(false)
	_start_battle_transition()


func _start_battle_transition() -> void:
	_is_transitioning = true
	_play_sfx(_sfx_skin, -3.5)
	var tw := create_tween()
	tw.tween_property(next_button, "scale", Vector2(0.95, 0.95), 0.07).set_trans(Tween.TRANS_SINE)
	tw.tween_property(next_button, "scale", Vector2(1.02, 1.02), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(fade_overlay, "color:a", 1.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_callback(_enter_battle)


func _enter_battle() -> void:
	get_tree().change_scene_to_file(GAME_SCENE_PATH)


# ── Процедурні звукові ефекти терміналу ──────────────────────────────────────

func _init_audio() -> void:
	if DisplayServer.get_name() == "headless":
		return
	_sfx_player = AudioStreamPlayer.new()
	add_child(_sfx_player)
	_sfx_click = _synth_tone(740.0, 980.0, 0.045, 0.25)
	_sfx_buy = _synth_chord([523.25, 659.25, 783.99, 1046.5], 0.18, 0.34)
	_sfx_skin = _synth_tone(480.0, 860.0, 0.085, 0.28)
	_sfx_error = _synth_tone(240.0, 165.0, 0.11, 0.30)


func _play_sfx(stream: AudioStreamWAV, vol_db: float = -4.0) -> void:
	if _sfx_player == null or stream == null:
		return
	_sfx_player.stream = stream
	_sfx_player.volume_db = vol_db
	_sfx_player.play()


func _synth_tone(f0: float, f1: float, dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * float(rate))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(rate)
		var u := float(i) / maxf(1.0, float(n - 1))
		var env := sin(u * PI) * (1.0 - u * 0.4)
		var f := lerpf(f0, f1, u)
		var s := (sin(TAU * f * t) * 0.75 + sin(TAU * f * 2.0 * t) * 0.25) * env * amp
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


func _synth_chord(freqs: Array, dur: float, amp: float) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * float(rate))
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in range(n):
		var t := float(i) / float(rate)
		var u := float(i) / maxf(1.0, float(n - 1))
		var env := (1.0 - u) * minf(1.0, u * 14.0)
		var idx := mini(int(u * float(freqs.size())), freqs.size() - 1)
		var f := float(freqs[idx])
		var s := (sin(TAU * f * t) * 0.7 + sin(TAU * f * 2.0 * t) * 0.3) * env * amp
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.data = data
	return w


# ══════════════════════════════════════════════════════════════════════════════
# ДОПОМІЖНІ ВІЗУАЛЬНІ КЛАСИ (ТЕМАТИКА TETHER6: БРОНЬОВАНА ОЛИВА + СТАЛЬ + ЛАТУНЬ)
# ══════════════════════════════════════════════════════════════════════════════

static func _draw_bevel_rect(
	canvas: CanvasItem,
	rect: Rect2,
	radius: int,
	fill: Color,
	hi: Color,
	lo: Color,
	outline: Color,
	border_w: int = 3
) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = outline
	sb.set_border_width_all(border_w)
	sb.set_corner_radius_all(radius)
	sb.draw(canvas.get_canvas_item(), rect)

	var inset := clampf(float(radius) * 0.55, 4.0, rect.size.x * 0.16)
	if hi.a > 0.01 and rect.size.x > inset * 2.5:
		var hy := rect.position.y + float(border_w) + 1.5
		canvas.draw_line(Vector2(rect.position.x + inset, hy), Vector2(rect.position.x + rect.size.x - inset, hy), hi, 1.8)
	if lo.a > 0.01 and rect.size.x > inset * 2.5:
		var ly := rect.position.y + rect.size.y - float(border_w) - 1.5
		canvas.draw_line(Vector2(rect.position.x + inset, ly), Vector2(rect.position.x + rect.size.x - inset, ly), lo, 1.8)


static func _make_octagon(rect: Rect2, inset: float, chamfer_ratio: float = 0.22) -> PackedVector2Array:
	var r := rect.grow(-inset)
	var ch := minf(r.size.x, r.size.y) * chamfer_ratio
	var x0 := r.position.x
	var y0 := r.position.y
	var x1 := r.end.x
	var y1 := r.end.y
	return PackedVector2Array([
		Vector2(x0 + ch, y0),
		Vector2(x1 - ch, y0),
		Vector2(x1, y0 + ch),
		Vector2(x1, y1 - ch),
		Vector2(x1 - ch, y1),
		Vector2(x0 + ch, y1),
		Vector2(x0, y1 - ch),
		Vector2(x0, y0 + ch),
	])


static func _draw_uniform_icon_socket(canvas: CanvasItem, rect: Rect2, highlight_gold: Color = Color(0.84, 0.68, 0.30, 1.0)) -> void:
	# Зовнішній темний округлений сокет (#0E1115) — ідентичний для всіх 6 карток та інспектора
	_draw_bevel_rect(
		canvas,
		rect,
		11,
		Color(0.055, 0.067, 0.082, 1.0),
		Color(0.18, 0.20, 0.23, 0.55),
		Color(0.42, 0.44, 0.38, 0.45),
		UI_INK,
		3
	)
	var outer_oct := _make_octagon(rect, rect.size.x * 0.065, 0.20)
	canvas.draw_colored_polygon(outer_oct, Color(0.045, 0.055, 0.070, 1.0))
	var outer_closed := outer_oct + PackedVector2Array([outer_oct[0]])
	canvas.draw_polyline(outer_closed, highlight_gold, 2.2, true)

	var inner_oct := _make_octagon(rect, rect.size.x * 0.105, 0.20)
	var inner_closed := inner_oct + PackedVector2Array([inner_oct[0]])
	canvas.draw_polyline(inner_closed, highlight_gold.lightened(0.22), 1.3, true)


static func _draw_screw(canvas: CanvasItem, center: Vector2, r: float = 5.0) -> void:
	canvas.draw_circle(center, r, UI_INK)
	canvas.draw_circle(center, r - 1.2, Color(0.72, 0.73, 0.69, 1.0))
	canvas.draw_circle(center + Vector2(-0.7, -0.7), (r - 1.2) * 0.65, Color(0.86, 0.87, 0.83, 1.0))
	var cross := r * 0.52
	canvas.draw_line(center + Vector2(-cross, 0.0), center + Vector2(cross, 0.0), Color(0.24, 0.25, 0.23, 1.0), 1.3)
	canvas.draw_line(center + Vector2(0.0, -cross), center + Vector2(0.0, cross), Color(0.24, 0.25, 0.23, 1.0), 1.3)


static func _draw_scanlines(canvas: CanvasItem, rect: Rect2, step_x: float = 4.0, alpha: float = 0.045) -> void:
	var x := rect.position.x + step_x
	var end_x := rect.position.x + rect.size.x - 2.0
	while x < end_x:
		canvas.draw_line(
			Vector2(x, rect.position.y + 3.0),
			Vector2(x, rect.position.y + rect.size.y - 3.0),
			Color(1.0, 1.0, 1.0, alpha),
			1.0
		)
		x += step_x


static func _draw_gear_drum(canvas: CanvasItem, center: Vector2, outer_r: float, teeth: int) -> void:
	canvas.draw_circle(center, outer_r + 2.0, UI_INK)
	canvas.draw_circle(center, outer_r - 2.0, UI_OLIVE_DARK)
	for i in range(teeth):
		var a := float(i) * TAU / float(teeth)
		var p1 := center + Vector2.RIGHT.rotated(a) * (outer_r - 9.0)
		var p2 := center + Vector2.RIGHT.rotated(a) * (outer_r + 3.0)
		canvas.draw_line(p1, p2, UI_INK, 7.0)
		canvas.draw_line(p1, p2 - Vector2.RIGHT.rotated(a) * 1.5, UI_OLIVE_LO, 4.0)
	canvas.draw_circle(center, outer_r - 10.0, UI_INK)
	canvas.draw_circle(center, outer_r - 13.0, UI_STEEL_LO)
	canvas.draw_circle(center, outer_r * 0.34, UI_INK)
	canvas.draw_circle(center, outer_r * 0.26, UI_OLIVE_LO)


static func _draw_gold_coin(canvas: CanvasItem, center: Vector2, r: float = 15.0) -> void:
	canvas.draw_circle(center, r + 2.0, UI_INK)
	canvas.draw_circle(center, r, Color(0.84, 0.62, 0.14, 1.0))
	canvas.draw_circle(center + Vector2(-1.2, -1.2), r * 0.78, Color(0.98, 0.80, 0.28, 1.0))
	canvas.draw_circle(center, r * 0.60, Color(0.82, 0.60, 0.14, 1.0))
	canvas.draw_arc(center, r * 0.72, 0.0, TAU, 24, Color(1.0, 0.92, 0.56, 0.85), 1.5)
	var font := ThemeDB.fallback_font
	if font != null:
		canvas.draw_string(font, center + Vector2(-9.0, 6.0), "$", HORIZONTAL_ALIGNMENT_CENTER, 18.0, 17, Color(0.32, 0.20, 0.04, 1.0))


class _ConsoleChassisCanvas extends Control:
	func _draw() -> void:
		# Декоративні шестерні та коліщатка позаду корпусу консолі
		UpgradeMenu._draw_gear_drum(self, Vector2(36.0, 560.0), 58.0, 14)
		UpgradeMenu._draw_gear_drum(self, Vector2(1196.0, 560.0), 58.0, 14)

		# Верхні бічні барабани/шестерні біля кутів шапки
		UpgradeMenu._draw_bevel_rect(self, Rect2(-18.0, 24.0, 26.0, 86.0), 6, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for ry in range(34, 104, 11):
			draw_line(Vector2(-15.0, float(ry)), Vector2(4.0, float(ry)), UI_INK, 2.0)
			draw_line(Vector2(-15.0, float(ry) + 3.0), Vector2(4.0, float(ry) + 3.0), UI_OLIVE_HI, 1.2)

		UpgradeMenu._draw_bevel_rect(self, Rect2(1224.0, 24.0, 26.0, 86.0), 6, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for ry in range(34, 104, 11):
			draw_line(Vector2(1228.0, float(ry)), Vector2(1247.0, float(ry)), UI_INK, 2.0)
			draw_line(Vector2(1228.0, float(ry) + 3.0), Vector2(1247.0, float(ry) + 3.0), UI_OLIVE_HI, 1.2)

		# Бокова нижня шестерня праворуч та ліворуч
		UpgradeMenu._draw_bevel_rect(self, Rect2(1224.0, 310.0, 20.0, 150.0), 5, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for gy in range(320, 452, 12):
			draw_line(Vector2(1227.0, float(gy)), Vector2(1241.0, float(gy)), UI_INK, 2.2)

		UpgradeMenu._draw_bevel_rect(self, Rect2(-12.0, 310.0, 20.0, 150.0), 5, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for gy in range(320, 452, 12):
			draw_line(Vector2(-9.0, float(gy)), Vector2(5.0, float(gy)), UI_INK, 2.2)

		# Нижні упори та індикаторний блок з 3 жовтогарячими LED під інспектором
		UpgradeMenu._draw_bevel_rect(self, Rect2(342.0, 600.0, 94.0, 18.0), 6, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for bx in range(354, 428, 12):
			draw_line(Vector2(float(bx), 603.0), Vector2(float(bx), 615.0), UI_INK, 2.0)

		UpgradeMenu._draw_bevel_rect(self, Rect2(812.0, 600.0, 94.0, 18.0), 6, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for bx in range(824, 898, 12):
			draw_line(Vector2(float(bx), 603.0), Vector2(float(bx), 615.0), UI_INK, 2.0)

		var led_pod := Rect2(972.0, 600.0, 96.0, 22.0)
		UpgradeMenu._draw_bevel_rect(self, led_pod, 6, UI_OLIVE_LO, UI_OLIVE, UI_OLIVE_DARK, UI_INK, 3)
		for li in range(3):
			var lr := Rect2(988.0 + float(li) * 23.0, 605.0, 14.0, 11.0)
			UpgradeMenu._draw_bevel_rect(self, lr, 3, Color(0.95, 0.66, 0.16, 1.0), Color(1.0, 0.90, 0.56, 1.0), Color(0.65, 0.36, 0.06, 1.0), UI_INK, 2)

		# Головне оливково-латунне шасі
		var body_rect := Rect2(0.0, 8.0, 1232.0, 598.0)
		UpgradeMenu._draw_bevel_rect(self, body_rect, 22, UI_OLIVE, UI_OLIVE_HI, UI_OLIVE_LO, UI_INK, 4)

		# Виступаюча центральна арка «ТАКТИЧНИЙ АРСЕНАЛ»
		var arch_outer := Rect2(400.0, -10.0, 432.0, 74.0)
		UpgradeMenu._draw_bevel_rect(self, arch_outer, 20, UI_OLIVE, UI_OLIVE_HI, UI_OLIVE_LO, UI_INK, 4)
		# Зливаємо нижню межу арки з верхньою смугою шасі без чорного розрізу
		var arch_seam := Rect2(404.0, 8.0, 424.0, 58.0)
		UpgradeMenu._draw_bevel_rect(self, arch_seam, 14, UI_OLIVE, UI_OLIVE_HI, Color.TRANSPARENT, Color.TRANSPARENT, 0)

		var arch_crt := Rect2(416.0, -2.0, 400.0, 54.0)
		UpgradeMenu._draw_bevel_rect(self, arch_crt, 14, Color(0.035, 0.04, 0.048, 1.0), Color(0.11, 0.12, 0.13, 1.0), Color.BLACK, UI_INK, 3)
		UpgradeMenu._draw_scanlines(self, arch_crt, 4.0, 0.05)

		# Ліва та права планки верхньої панелі (Рівень / Монети)
		var left_hdr := Rect2(18.0, 13.0, 376.0, 45.0)
		UpgradeMenu._draw_bevel_rect(self, left_hdr, 10, Color(0.16, 0.175, 0.155, 0.98), Color(0.28, 0.30, 0.26, 0.8), Color.BLACK, UI_INK, 3)

		var right_hdr := Rect2(838.0, 13.0, 376.0, 45.0)
		UpgradeMenu._draw_bevel_rect(self, right_hdr, 10, Color(0.16, 0.175, 0.155, 0.98), Color(0.28, 0.30, 0.26, 0.8), Color.BLACK, UI_INK, 3)
		UpgradeMenu._draw_gold_coin(self, Vector2(864.0, 35.5), 14.0)

		# Заглиблений внутрішній лоток для 3 робочих зон
		var well_outer := Rect2(10.0, 66.0, 1212.0, 528.0)
		UpgradeMenu._draw_bevel_rect(self, well_outer, 12, UI_TRAY, Color(0.11, 0.12, 0.10, 0.95), UI_OLIVE_HI, UI_INK, 3)

		# Сталеві кутові кріпильні скоби з гвинтами на внутрішній рамі
		var lb := PackedVector2Array([
			Vector2(6.0, 62.0), Vector2(44.0, 62.0), Vector2(44.0, 78.0),
			Vector2(24.0, 78.0), Vector2(24.0, 98.0), Vector2(6.0, 98.0)
		])
		draw_colored_polygon(lb, UI_STEEL)
		draw_polyline(lb + PackedVector2Array([lb[0]]), UI_INK, 2.5)
		UpgradeMenu._draw_screw(self, Vector2(16.0, 72.0), 4.5)

		var rb := PackedVector2Array([
			Vector2(1188.0, 62.0), Vector2(1226.0, 62.0), Vector2(1226.0, 98.0),
			Vector2(1208.0, 98.0), Vector2(1208.0, 78.0), Vector2(1188.0, 78.0)
		])
		draw_colored_polygon(rb, UI_STEEL)
		draw_polyline(rb + PackedVector2Array([rb[0]]), UI_INK, 2.5)
		UpgradeMenu._draw_screw(self, Vector2(1216.0, 72.0), 4.5)

		# Нижні кутові гвинти головного корпусу
		UpgradeMenu._draw_screw(self, Vector2(20.0, 588.0), 5.0)
		UpgradeMenu._draw_screw(self, Vector2(1212.0, 588.0), 5.0)


class _ZonePlateCanvas extends Control:
	var title_text: String = ""
	var title_width: float = 180.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		UpgradeMenu._draw_bevel_rect(self, r, 10, UI_STEEL, UI_STEEL_HI, UI_STEEL_LO, UI_INK, 3)

		# Тонка внутрішня фаска по периметру
		draw_rect(r.grow(-5.0), Color(0.24, 0.25, 0.23, 0.45), false, 1.0)

		# 4 металеві гвинти в кутах зони
		UpgradeMenu._draw_screw(self, Vector2(11.0, 11.0), 4.2)
		UpgradeMenu._draw_screw(self, Vector2(size.x - 11.0, 11.0), 4.2)
		UpgradeMenu._draw_screw(self, Vector2(11.0, size.y - 11.0), 4.2)
		UpgradeMenu._draw_screw(self, Vector2(size.x - 11.0, size.y - 11.0), 4.2)

		if not title_text.is_empty():
			var tab_x := roundf((size.x - title_width) * 0.5)
			var tab_rect := Rect2(tab_x, 3.0, title_width, 24.0)
			UpgradeMenu._draw_bevel_rect(self, tab_rect, 7, Color(0.35, 0.37, 0.34, 1.0), UI_STEEL_HI, UI_STEEL_LO, UI_INK, 2)
			var font := ThemeDB.fallback_font
			if font != null:
				draw_string(font, Vector2(tab_x, 20.0), title_text, HORIZONTAL_ALIGNMENT_CENTER, title_width, 13, Color(0.96, 0.95, 0.88, 1.0))


class _RoundedWellCanvas extends Control:
	var bg_color: Color = Color(0.086, 0.094, 0.106, 0.98)
	var border_color: Color = Color(0.06, 0.07, 0.08, 1.0)
	var accent_rim_color: Color = Color(0.54, 0.50, 0.36, 0.72)
	var corner_radius: int = 8
	var draw_rivets: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		UpgradeMenu._draw_bevel_rect(self, r, corner_radius, bg_color, Color(0.18, 0.20, 0.22, 0.45), accent_rim_color, border_color, 3)
		if draw_rivets:
			UpgradeMenu._draw_screw(self, Vector2(8.0, 8.0), 3.0)
			UpgradeMenu._draw_screw(self, Vector2(size.x - 8.0, 8.0), 3.0)
			UpgradeMenu._draw_screw(self, Vector2(8.0, size.y - 8.0), 3.0)
			UpgradeMenu._draw_screw(self, Vector2(size.x - 8.0, size.y - 8.0), 3.0)


class _SkinMiniIcon extends Control:
	var skin_id: String = "shades_gold"

	func _draw() -> void:
		if skin_id == "standard":
			# Тактичний шолом
			draw_circle(Vector2(7.5, 8.5), 5.5, UI_INK)
			draw_circle(Vector2(7.5, 8.0), 4.2, Color(0.45, 0.52, 0.40, 1.0))
			draw_rect(Rect2(2.5, 8.5, 10.0, 3.0), Color(0.28, 0.33, 0.25, 1.0), true)
			draw_line(Vector2(4.0, 5.5), Vector2(10.5, 5.5), Color(0.75, 0.82, 0.68, 0.85), 1.4)
			return

		var lens_col := Color(0.98, 0.78, 0.22, 1.0)
		if skin_id == "shades_cyber":
			lens_col = Color(0.24, 0.90, 1.0, 1.0)
		elif skin_id == "shades_black":
			lens_col = Color(0.16, 0.18, 0.22, 1.0)

		# Тактичні окуляри з чіткою сріблясто-сталевою оправою
		draw_rect(Rect2(0.0, 4.0, 15.0, 8.0), UI_INK, true)
		draw_rect(Rect2(0.5, 4.5, 14.0, 7.0), Color(0.58, 0.60, 0.56, 0.9), false, 1.0)
		draw_rect(Rect2(1.5, 5.5, 5.0, 4.5), lens_col, true)
		draw_rect(Rect2(8.5, 5.5, 5.0, 4.5), lens_col, true)
		draw_line(Vector2(2.2, 6.2), Vector2(4.6, 6.2), Color(1.0, 1.0, 1.0, 0.58), 1.0)
		draw_line(Vector2(9.2, 6.2), Vector2(11.6, 6.2), Color(1.0, 1.0, 1.0, 0.58), 1.0)


class _BuyButtonDecor extends Control:
	func _draw() -> void:
		if size.x <= 12.0 or size.y <= 12.0:
			return
		draw_line(Vector2(14.0, 5.0), Vector2(size.x - 14.0, 5.0), Color(1.0, 1.0, 1.0, 0.16), 2.0)
		UpgradeMenu._draw_screw(self, Vector2(12.0, 12.0), 3.4)
		UpgradeMenu._draw_screw(self, Vector2(size.x - 12.0, 12.0), 3.4)
		UpgradeMenu._draw_screw(self, Vector2(12.0, size.y - 12.0), 3.4)
		UpgradeMenu._draw_screw(self, Vector2(size.x - 12.0, size.y - 12.0), 3.4)


class _UniformSocketCanvas extends Control:
	var highlight_gold: Color = Color(0.84, 0.68, 0.30, 1.0)

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		UpgradeMenu._draw_uniform_icon_socket(self, Rect2(Vector2.ZERO, size), highlight_gold)


class _BevelPanelCanvas extends Control:
	var bg_color: Color = Color(0.08, 0.09, 0.11, 0.96)
	var border_color: Color = Color(0.68, 0.58, 0.36, 0.96)
	var draw_rivets: bool = true

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		UpgradeMenu._draw_bevel_rect(self, r, 10, bg_color, border_color.lightened(0.24), border_color.darkened(0.25), UI_INK, 3)
		if draw_rivets:
			UpgradeMenu._draw_screw(self, Vector2(10.0, 10.0), 4.0)
			UpgradeMenu._draw_screw(self, Vector2(size.x - 10.0, 10.0), 4.0)
			UpgradeMenu._draw_screw(self, Vector2(10.0, size.y - 10.0), 4.0)
			UpgradeMenu._draw_screw(self, Vector2(size.x - 10.0, size.y - 10.0), 4.0)


class _UpgradeTile extends Control:
	signal tile_clicked
	signal tile_double_clicked
	signal tile_hovered(is_hovered: bool)

	var _def: Dictionary = {}
	var _icon_tex: Texture2D = null
	var _lvl: int = 0
	var _max_lvl: int = 5
	var _cost: int = 50
	var _can_afford: bool = false
	var _maxed: bool = false
	var _selected: bool = false
	var _matches_filter: bool = true
	var _hovered: bool = false
	var _pulse_t: float = 0.0

	func setup(def: Dictionary, icon_tex: Texture2D) -> void:
		_def = def
		_icon_tex = icon_tex
		mouse_filter = Control.MOUSE_FILTER_STOP
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		mouse_entered.connect(func() -> void:
			_hovered = true
			tile_hovered.emit(true)
			queue_redraw()
		)
		mouse_exited.connect(func() -> void:
			_hovered = false
			tile_hovered.emit(false)
			queue_redraw()
		)

	func set_icon_texture(tex: Texture2D) -> void:
		if _icon_tex != tex:
			_icon_tex = tex
			queue_redraw()

	func update_state(lvl: int, max_lvl: int, cost: int, can_afford: bool, maxed: bool, selected: bool, matches_filter: bool) -> void:
		_lvl = lvl
		_max_lvl = max_lvl
		_cost = cost
		_can_afford = can_afford
		_maxed = maxed
		_selected = selected
		_matches_filter = matches_filter
		modulate.a = 1.0 if matches_filter else 0.30
		queue_redraw()

	func play_purchase_pulse() -> void:
		_pulse_t = 1.0

	func _process(delta: float) -> void:
		if _pulse_t > 0.0:
			_pulse_t = maxf(0.0, _pulse_t - delta * 2.6)
			queue_redraw()
		elif _selected or _hovered:
			queue_redraw()

	func _gui_input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if event.double_click:
				tile_double_clicked.emit()
			else:
				tile_clicked.emit()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		var accent: Color = _def.get("accent", Color(0.88, 0.74, 0.38))
		var t_sec := float(Time.get_ticks_msec()) * 0.004

		# Металева броньована плитка в стилі оливково-сталевого терміналу
		var bg := Color(0.325, 0.341, 0.310, 0.99)
		var hi := Color(0.467, 0.486, 0.447, 0.90)
		var lo := Color(0.188, 0.196, 0.176, 0.95)
		var outline := UI_INK
		var bw := 3

		if _selected:
			var glow := 0.5 + 0.5 * sin(t_sec * 2.2)
			bg = Color(0.396, 0.380, 0.278, 0.99)
			hi = Color(0.66, 0.62, 0.42, 1.0)
			outline = accent.lerp(Color(1.0, 0.92, 0.58, 1.0), 0.45 + 0.25 * glow)
		elif _hovered:
			bg = Color(0.376, 0.392, 0.357, 0.99)
			outline = accent.lightened(0.12)
		elif _maxed:
			bg = Color(0.365, 0.345, 0.245, 0.99)
			outline = Color(0.76, 0.62, 0.26, 1.0)

		UpgradeMenu._draw_bevel_rect(self, r, 8, bg, hi, lo, outline, bw)

		# 4 маленькі заклепки по кутах плитки
		var rivet_pts: Array[Vector2] = [
			Vector2(6.5, 6.5),
			Vector2(size.x - 6.5, 6.5),
			Vector2(6.5, size.y - 6.5),
			Vector2(size.x - 6.5, size.y - 6.5),
		]
		for rp in rivet_pts:
			draw_circle(rp, 2.3, UI_INK)
			draw_circle(rp, 1.4, Color(0.68, 0.69, 0.64, 1.0))

		# Спалах при купівлі
		if _pulse_t > 0.0:
			UpgradeMenu._draw_bevel_rect(self, r.grow(-2.0), 7, Color(1.0, 0.92, 0.55, _pulse_t * 0.40), Color.TRANSPARENT, Color.TRANSPARENT, Color.TRANSPARENT, 0)

		# Однакове уніфіковане темне гніздо із подвійною золотою восьмикутною рамкою на всіх картках
		var socket_sz := Vector2(114.0, 114.0)
		var socket_pos := Vector2((size.x - socket_sz.x) * 0.5, 30.0)
		var socket_rect := Rect2(socket_pos, socket_sz)
		var frame_gold := Color(0.95, 0.78, 0.36, 1.0) if _selected else Color(0.82, 0.66, 0.28, 0.96)
		UpgradeMenu._draw_uniform_icon_socket(self, socket_rect, frame_gold)

		if _icon_tex != null:
			# Іконка ідеально вписується всередину рамки зі збереженням пропорцій (як для квадратних іконок, так і для широких М4)
			var tex_sz := _icon_tex.get_size()
			var max_dim := Vector2(102.0, 86.0) if tex_sz.x > tex_sz.y * 1.35 else Vector2(86.0, 86.0)
			var fit_scale := minf(max_dim.x / maxf(tex_sz.x, 1.0), max_dim.y / maxf(tex_sz.y, 1.0))
			var icon_sz := tex_sz * fit_scale
			var icon_pos := socket_pos + (socket_sz - icon_sz) * 0.5
			draw_texture_rect(_icon_tex, Rect2(icon_pos, icon_sz), false)

		# Статусний світлодіод з глянцем зліва зверху + цінник праворуч зверху
		var led_col := Color(0.86, 0.32, 0.28, 0.95)
		if _maxed:
			led_col = Color(0.98, 0.82, 0.28, 1.0)
		elif _can_afford:
			led_col = Color(0.34, 0.96, 0.50, 1.0)
		draw_circle(Vector2(18.0, 18.0), 5.2, UI_INK)
		draw_circle(Vector2(18.0, 18.0), 3.6, led_col)
		draw_circle(Vector2(16.8, 16.8), 1.3, Color(1.0, 1.0, 1.0, 0.72))

		var font := ThemeDB.fallback_font
		if font != null:
			var badge_txt := "MAX" if _maxed else ("$%d" % _cost)
			var badge_col := Color(1.0, 0.88, 0.40) if _maxed else (Color(0.56, 0.98, 0.62) if _can_afford else Color(0.95, 0.86, 0.74))
			draw_string(font, Vector2(size.x - 54.0, 23.0), badge_txt, HORIZONTAL_ALIGNMENT_RIGHT, 44.0, 14, Color(0.0, 0.0, 0.0, 0.92))
			draw_string(font, Vector2(size.x - 55.0, 22.0), badge_txt, HORIZONTAL_ALIGNMENT_RIGHT, 44.0, 14, badge_col)

			# Назва модуля із чіткою тінню
			var short_title := String(_def.get("short_title", ""))
			var title_fs := 11 if short_title.length() > 14 else 13
			draw_string(font, Vector2(5.0, 166.0), short_title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8.0, title_fs, Color(0.04, 0.05, 0.06, 0.95))
			draw_string(font, Vector2(4.0, 165.0), short_title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8.0, title_fs, Color(0.97, 0.96, 0.90, 1.0))

		# Округлені міні-сегменти рівня в темних комірках знизу (5 або 6 для броні)
		var pip_w := 21.0 if _max_lvl <= 5 else 17.0
		var pip_h := 11.0
		var pip_gap := 4.0 if _max_lvl <= 5 else 3.5
		var total_w := float(_max_lvl) * pip_w + float(_max_lvl - 1) * pip_gap
		var start_x := (size.x - total_w) * 0.5
		var pip_y := size.y - 25.0
		for i in range(_max_lvl):
			var pr := Rect2(Vector2(start_x + float(i) * (pip_w + pip_gap), pip_y), Vector2(pip_w, pip_h))
			var fill_c := Color(0.06, 0.07, 0.08, 0.98)
			var hi_c := Color.TRANSPARENT
			if i < _lvl:
				fill_c = accent.lightened(0.10)
				hi_c = accent.lightened(0.42)
			elif i == _lvl and _can_afford and (_selected or _hovered):
				var p_alpha := 0.35 + 0.35 * sin(t_sec * 3.0)
				fill_c = Color(accent.r, accent.g, accent.b, p_alpha)
			UpgradeMenu._draw_bevel_rect(self, pr, 3, fill_c, hi_c, Color.TRANSPARENT, UI_INK, 1)

		# Золоті кутові дужки при виборі
		if _selected:
			var cl := 10.0
			var c_col := Color(1.0, 0.90, 0.48, 1.0)
			draw_line(Vector2(3, 3), Vector2(3 + cl, 3), c_col, 2.5)
			draw_line(Vector2(3, 3), Vector2(3, 3 + cl), c_col, 2.5)
			draw_line(Vector2(size.x - 3, 3), Vector2(size.x - 3 - cl, 3), c_col, 2.5)
			draw_line(Vector2(size.x - 3, 3), Vector2(size.x - 3, 3 + cl), c_col, 2.5)
			draw_line(Vector2(3, size.y - 3), Vector2(3 + cl, size.y - 3), c_col, 2.5)
			draw_line(Vector2(3, size.y - 3), Vector2(3, size.y - 3 - cl), c_col, 2.5)
			draw_line(Vector2(size.x - 3, size.y - 3), Vector2(size.x - 3 - cl, size.y - 3), c_col, 2.5)
			draw_line(Vector2(size.x - 3, size.y - 3), Vector2(size.x - 3, size.y - 3 - cl), c_col, 2.5)


class _LevelSegmentsCanvas extends Control:
	var current_level: int = 0
	var max_level: int = 5
	var accent_color: Color = Color(0.92, 0.72, 0.32)
	var can_afford_next: bool = false

	func _process(_delta: float) -> void:
		if can_afford_next:
			queue_redraw()

	func _draw() -> void:
		UpgradeMenu._draw_bevel_rect(self, Rect2(Vector2.ZERO, size), 8, Color(0.085, 0.092, 0.102, 0.98), Color(0.18, 0.20, 0.22, 0.4), Color(0.55, 0.56, 0.52, 0.5), UI_INK, 2)

		var pad := 6.0
		var gap := 6.0
		var inner_w := size.x - pad * 2.0
		var seg_w := (inner_w - gap * float(max_level - 1)) / float(max_level)
		var seg_h := size.y - 10.0
		var t_sec := float(Time.get_ticks_msec()) * 0.005

		for i in range(max_level):
			var r := Rect2(Vector2(pad + float(i) * (seg_w + gap), 5.0), Vector2(seg_w, seg_h))
			var fill_c := Color(0.14, 0.15, 0.17, 0.98)
			var hi_c := Color.TRANSPARENT
			var border_c := Color(0.28, 0.30, 0.28, 0.95)
			if i < current_level:
				fill_c = accent_color
				hi_c = accent_color.lightened(0.35)
				border_c = Color(0.95, 0.84, 0.48, 1.0)
			elif i == current_level and can_afford_next:
				var pulse := 0.28 + 0.24 * sin(t_sec * 2.2)
				fill_c = Color(accent_color.r, accent_color.g, accent_color.b, pulse)
				border_c = accent_color.lightened(0.15)
			UpgradeMenu._draw_bevel_rect(self, r, 5, fill_c, hi_c, Color.TRANSPARENT, border_c, 2)


class _SoldierShowcaseCanvas extends Control:
	var soldier_tex: Texture2D = null
	var weapon_tex: Texture2D = null
	var skin_id: String = "shades_gold"
	var filter_mode: String = "bunker"
	var armor_tier: int = 1
	var display_tier: int = 1
	var is_armor_preview: bool = false
	var weapon_tier: int = 1
	var weapon_display_tier: int = 1
	var is_weapon_preview: bool = false
	var highlight_uv: Vector2 = Vector2(0.50, 0.31)
	var highlight_label: String = "ОЗБРОЄННЯ"
	var highlight_color: Color = Color(0.94, 0.56, 0.24)

	var _time: float = 0.0
	var _sparks: Array[Dictionary] = []

	func _get_soldier_rect(bob_y: float = 0.0) -> Rect2:
		var draw_h := 178.0 if is_weapon_preview else 190.0
		var aspect := 240.0 / 396.0
		if soldier_tex != null and soldier_tex.get_size().y > 1.0:
			aspect = soldier_tex.get_size().x / soldier_tex.get_size().y
		var draw_w := draw_h * aspect
		var breath := 1.0 + 0.008 * sin(_time * 2.4)
		var sw := draw_w * breath
		var sh := draw_h * breath
		var cx := size.x * (0.24 if is_weapon_preview else 0.52)
		var bot_y := size.y - 28.0 + bob_y
		return Rect2(Vector2(cx - sw * 0.5, bot_y - sh), Vector2(sw, sh))

	func trigger_upgrade_burst(uv: Vector2, col: Color) -> void:
		var sr := _get_soldier_rect(0.0)
		var center := sr.position + Vector2(uv.x * sr.size.x, uv.y * sr.size.y)
		for i in range(22):
			var ang := randf() * TAU
			var spd := randf_range(38.0, 135.0)
			_sparks.append({
				"pos": center,
				"vel": Vector2(cos(ang), sin(ang)) * spd,
				"life": randf_range(0.35, 0.70),
				"max_life": 0.70,
				"col": col.lightened(0.25),
			})

	func _process(delta: float) -> void:
		_time += delta
		for i in range(_sparks.size() - 1, -1, -1):
			var s: Dictionary = _sparks[i]
			s["life"] = float(s["life"]) - delta
			if float(s["life"]) <= 0.0:
				_sparks.remove_at(i)
			else:
				s["pos"] = (s["pos"] as Vector2) + (s["vel"] as Vector2) * delta
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		# Фон тактичного сканера з округленими кутами
		var well_col := Color(0.052, 0.058, 0.066, 0.99)
		var grid_col := Color(0.70, 0.62, 0.34, 0.11)
		match filter_mode:
			"thermal":
				well_col = Color(0.07, 0.03, 0.09, 0.99)
				grid_col = Color(0.95, 0.48, 0.18, 0.14)
			"nvg":
				well_col = Color(0.02, 0.07, 0.035, 0.99)
				grid_col = Color(0.25, 0.92, 0.45, 0.14)
			"crt":
				well_col = Color(0.025, 0.05, 0.08, 0.99)
				grid_col = Color(0.35, 0.82, 0.98, 0.14)
		UpgradeMenu._draw_bevel_rect(self, r, 8, well_col, Color.TRANSPARENT, Color.TRANSPARENT, Color.TRANSPARENT, 0)

		# Тактична координатна сітка + радарні кола
		for x in range(24, int(size.x), 24):
			draw_line(Vector2(x, 4), Vector2(x, size.y - 4), grid_col, 1.0)
		for y in range(24, int(size.y), 24):
			draw_line(Vector2(4, y), Vector2(size.x - 4, y), grid_col, 1.0)

		var center_radar := Vector2(size.x * 0.52, size.y * 0.50)
		draw_arc(center_radar, 66.0, 0.0, TAU, 48, grid_col * Color(1, 1, 1, 1.6), 1.2)
		draw_arc(center_radar, 100.0, 0.0, TAU, 64, grid_col * Color(1, 1, 1, 1.2), 1.0)

		# Горизонтальна скануюча лінія (підсвічується золотистим у режимі прев'ю броні або зброї)
		var scan_y := fmod(_time * 48.0, size.y - 8.0) + 4.0
		var any_preview := is_armor_preview or is_weapon_preview
		var scan_alpha := 0.34 if any_preview else 0.22
		draw_line(Vector2(4, scan_y), Vector2(size.x - 4, scan_y), Color(highlight_color.r, highlight_color.g, highlight_color.b, scan_alpha), 2.0)

		# Тінь під ногами бійця
		var soldier_cx := size.x * (0.24 if is_weapon_preview else 0.52)
		var shadow_c := Vector2(soldier_cx, size.y - 30.0)
		draw_set_transform(shadow_c, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 40.0 if is_weapon_preview else 42.0, Color(0, 0, 0, 0.58))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Малюємо актуальний варіант броні (або прев'ю наступної броні при наведенні/натисканні)
		var bob_y := sin(_time * 2.4) * 1.4
		var sr := _get_soldier_rect(bob_y)
		if soldier_tex != null:
			var tint := Color.WHITE
			if filter_mode == "thermal":
				tint = Color(1.08, 0.92, 0.78, 1.0)
			elif filter_mode == "nvg":
				tint = Color(0.82, 1.08, 0.86, 1.0)
			if is_armor_preview:
				var p_glow := 0.5 + 0.5 * sin(_time * 5.0)
				var holo_r := sr.grow(4.0)
				draw_rect(holo_r, Color(0.98, 0.80, 0.28, 0.16 + 0.10 * p_glow), false, 1.5)
				tint = tint.lerp(Color(1.06, 1.03, 0.94, 1.0), 0.35 + 0.25 * p_glow)
			draw_texture_rect(soldier_tex, sr, false, tint)

		# Інтерактивний приціл-мітка на вузлі зброї або броні, який зараз обрано
		var target_pos := sr.position + Vector2(highlight_uv.x * sr.size.x, highlight_uv.y * sr.size.y)
		var pulse_r := 13.0 + 3.0 * sin(_time * 5.0)
		draw_arc(target_pos, pulse_r, 0.0, TAU, 32, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.94), 2.2)
		draw_arc(target_pos, pulse_r + 5.0, _time * 1.8, _time * 1.8 + PI * 0.65, 16, highlight_color.lightened(0.25), 2.0)
		draw_arc(target_pos, pulse_r + 5.0, _time * 1.8 + PI, _time * 1.8 + PI * 1.65, 16, highlight_color.lightened(0.25), 2.0)
		draw_circle(target_pos, 2.8, Color(1, 0.96, 0.82, 0.95))

		# Велике голографічне прев'ю наступної зброї праворуч від бійця (коли обрано/наведено на "damage"!)
		var font := ThemeDB.fallback_font
		if is_weapon_preview and weapon_tex != null:
			var p_glow := 0.5 + 0.5 * sin(_time * 5.0)
			var w_box := Rect2(Vector2(114.0, 56.0), Vector2(164.0, 128.0))
			var w_border := Color(0.98, 0.72, 0.26, 0.82 + 0.16 * p_glow)
			UpgradeMenu._draw_bevel_rect(self, w_box, 7, Color(0.06, 0.075, 0.09, 0.93), Color(0.24, 0.20, 0.12, 0.35), Color.TRANSPARENT, w_border, 2)
			draw_line(target_pos, Vector2(w_box.position.x, w_box.get_center().y), Color(w_border.r, w_border.g, w_border.b, 0.65), 1.6)
			if font != null:
				draw_string(font, Vector2(w_box.position.x + 6.0, w_box.position.y + 18.0), "МОДЕЛЬ М4 • РІВ.%d" % weapon_display_tier, HORIZONTAL_ALIGNMENT_CENTER, w_box.size.x - 12.0, 11, Color(1.0, 0.88, 0.44))
			var wt_sz := weapon_tex.get_size()
			var fit_w := minf((w_box.size.x - 14.0) / maxf(wt_sz.x, 1.0), (w_box.size.y - 36.0) / maxf(wt_sz.y, 1.0))
			var draw_wsz := wt_sz * fit_w
			var w_rect := Rect2(
				Vector2(w_box.position.x + (w_box.size.x - draw_wsz.x) * 0.5, w_box.position.y + 26.0 + (w_box.size.y - 32.0 - draw_wsz.y) * 0.5),
				draw_wsz
			)
			draw_texture_rect(weapon_tex, w_rect, false, Color(1.08, 1.05, 0.96, 1.0))

		# Виноска з назвою вузла у верхньому куті вітрини
		var callout_txt := highlight_label if any_preview else ("ВУЗОЛ: " + highlight_label)
		var callout_w := 146.0
		if font != null:
			var measured_w := font.get_string_size(callout_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
			callout_w = clampf(measured_w + 18.0, 120.0, size.x - 16.0)
		var callout_box := Rect2(Vector2(8, 6), Vector2(callout_w, 20))
		UpgradeMenu._draw_bevel_rect(self, callout_box, 5, Color(0.06, 0.07, 0.08, 0.92), Color.TRANSPARENT, Color.TRANSPARENT, highlight_color, 2)
		draw_line(Vector2(callout_box.end.x, callout_box.get_center().y), target_pos, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.65), 1.6)
		if font != null:
			draw_string(font, Vector2(14, 20), callout_txt, HORIZONTAL_ALIGNMENT_LEFT, callout_w - 10.0, 11, highlight_color.lightened(0.28))

		# Нижня плашка поточного рівня спорядження / візуального прев'ю наступного рівня
		var foot_rect := Rect2(Vector2(8.0, size.y - 25.0), Vector2(size.x - 16.0, 19.0))
		var foot_col := Color(0.16, 0.14, 0.06, 0.94) if any_preview else Color(0.07, 0.08, 0.10, 0.92)
		var foot_border := Color(0.98, 0.80, 0.30, 0.98) if any_preview else Color(0.42, 0.46, 0.50, 0.78)
		UpgradeMenu._draw_bevel_rect(self, foot_rect, 5, foot_col, Color.TRANSPARENT, Color.TRANSPARENT, foot_border, 1)
		if font != null:
			var foot_txt := "БРОНЯ: РІВ.%d/7  •  ЗБРОЯ: РІВ.%d/7" % [armor_tier, weapon_tier]
			if is_armor_preview:
				foot_txt = "ПРЕВ'Ю БРОНІ: РІВЕНЬ %d → %d" % [armor_tier, display_tier]
			elif is_weapon_preview:
				foot_txt = "ПРЕВ'Ю ЗБРОЇ: РІВЕНЬ %d → %d" % [weapon_tier, weapon_display_tier]
			var foot_txt_col := Color(1.0, 0.90, 0.45, 1.0) if any_preview else Color(0.76, 0.90, 0.98, 0.96)
			draw_string(font, Vector2(foot_rect.position.x + 4.0, foot_rect.position.y + 14.0), foot_txt, HORIZONTAL_ALIGNMENT_CENTER, foot_rect.size.x - 8.0, 11, foot_txt_col)

		# Іскри при покупці покращення або зміні скіна
		for s in _sparks:
			var ratio := clampf(float(s["life"]) / float(s["max_life"]), 0.0, 1.0)
			var c: Color = s["col"]
			c.a = ratio
			var p: Vector2 = s["pos"]
			draw_circle(p, 2.8 * ratio, c)

		# Броньована рамка вітрини зверху всього
		UpgradeMenu._draw_bevel_rect(self, r, 8, Color.TRANSPARENT, Color.TRANSPARENT, Color.TRANSPARENT, UI_INK, 3)


class _AtmosphereFilterCanvas extends Control:
	var filter_mode: String = "bunker"
	var _t: float = 0.0
	var _embers: Array[Dictionary] = []

	func _ready() -> void:
		for i in range(22):
			_embers.append({
				"x": randf() * 1280.0,
				"y": randf() * 720.0,
				"vx": randf_range(-12.0, 16.0),
				"vy": randf_range(-24.0, -8.0),
				"sz": randf_range(1.2, 2.8),
				"phase": randf() * TAU,
			})

	func _process(delta: float) -> void:
		_t += delta
		for e in _embers:
			e["x"] = fposmod(float(e["x"]) + float(e["vx"]) * delta, 1280.0)
			e["y"] = fposmod(float(e["y"]) + float(e["vy"]) * delta, 720.0)
		queue_redraw()

	func _draw() -> void:
		var w := size.x
		var h := size.y
		if w <= 1.0 or h <= 1.0:
			return

		match filter_mode:
			"thermal":
				draw_rect(Rect2(0, 0, w, h), Color(0.24, 0.06, 0.18, 0.12), true)
			"nvg":
				draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.26, 0.10, 0.12), true)
			"crt":
				draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.16, 0.26, 0.10), true)

		# Ледь помітна кінематографічна сітка без затемнення інтерфейсу
		var line_col := Color(0, 0, 0, 0.04)
		for y in range(0, int(h), 4):
			draw_line(Vector2(0, y), Vector2(w, y), line_col, 1.0)

		# Плаваючі іскри в повітрі
		for e in _embers:
			var glow := 0.35 + 0.35 * sin(_t * 2.5 + float(e["phase"]))
			var ecol := Color(0.98, 0.76, 0.32, glow * 0.42)
			if filter_mode == "nvg":
				ecol = Color(0.38, 0.98, 0.55, glow * 0.45)
			elif filter_mode == "crt":
				ecol = Color(0.42, 0.86, 1.0, glow * 0.45)
			elif filter_mode == "thermal":
				ecol = Color(1.0, 0.48, 0.22, glow * 0.48)
			draw_circle(Vector2(float(e["x"]), float(e["y"])), float(e["sz"]), ecol)
