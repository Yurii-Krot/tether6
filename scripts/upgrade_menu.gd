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

const TEX_ICON_DAMAGE := preload("res://assets/upg_icon_damage.png")
const TEX_ICON_FIRE_RATE := preload("res://assets/upg_icon_fire_rate.png")
const TEX_ICON_MAG := preload("res://assets/upg_icon_mag.png")
const TEX_ICON_AMMO := preload("res://assets/upg_icon_ammo.png")
const TEX_ICON_HP := preload("res://assets/upg_icon_hp.png")
const TEX_ICON_ARMOR := preload("res://assets/upg_icon_armor.png")
const TEX_ICON_MEDKIT := preload("res://assets/upg_icon_medkit.png")
const TEX_ICON_GRENADE := preload("res://assets/upg_icon_grenade.png")
const TEX_ICON_COINS := preload("res://assets/upg_icon_coins.png")

const UPGRADE_DEFS: Array[Dictionary] = [
	{
		"key": "damage",
		"short_title": "ВАЖКИЙ СТВОЛ",
		"title": "Важкий Нарізний Ствол",
		"category": "weapon",
		"category_label": "МОДУЛЬ ЗБРОЇ",
		"desc": "Посилений хромований ствол і дульне гальмо збільшують пробивну силу кожної кулі штурмової гвинтівки.",
		"accent": Color(0.94, 0.56, 0.24, 1.0),
		"part_uv": Vector2(0.84, 0.48),
		"part_name": "ДУЛЬНИЙ ЗРІЗ",
	},
	{
		"key": "fire_rate",
		"short_title": "БОЙОВИЙ ЗАТВОР",
		"title": "Полегшений Бойовий Затвор",
		"category": "weapon",
		"category_label": "МОДУЛЬ ЗБРОЇ",
		"desc": "Модернізована газова автоматика та титановий затвор підвищують скорострільність автомата в бою.",
		"accent": Color(0.96, 0.76, 0.28, 1.0),
		"part_uv": Vector2(0.56, 0.43),
		"part_name": "СТВОЛЬНА КОРОБКА",
	},
	{
		"key": "mag",
		"short_title": "ШТУРМ-МАГАЗИН",
		"title": "Спарений Штурмовий Магазин",
		"category": "weapon",
		"category_label": "МОДУЛЬ ЗБРОЇ",
		"desc": "Збільшує ємність магазина та пришвидшує тактичну перезарядку в укритті.",
		"accent": Color(0.84, 0.72, 0.42, 1.0),
		"part_uv": Vector2(0.54, 0.53),
		"part_name": "МАГАЗИН",
	},
	{
		"key": "ammo",
		"short_title": "ЕКСПАНСИВНІ",
		"title": "Експансивні Бронебійні Набої",
		"category": "weapon",
		"category_label": "МОДУЛЬ ЗБРОЇ",
		"desc": "Високошвидкісні кулі з вольфрамовим осердям: вища швидкість польоту та шанс критичного пострілу (x1.75 урону).",
		"accent": Color(0.96, 0.44, 0.30, 1.0),
		"part_uv": Vector2(0.68, 0.45),
		"part_name": "ПАТРОННИК І ПРИЦІЛ",
	},
	{
		"key": "hp",
		"short_title": "ТИТАН-БРОНЯ",
		"title": "Титановий Бронежилет (HP)",
		"category": "defense",
		"category_label": "МОДУЛЬ ЗАХИСТУ",
		"desc": "Керамічні бронеплити класу IV значно збільшують максимальний запас здоров'я оперативника.",
		"accent": Color(0.90, 0.34, 0.30, 1.0),
		"part_uv": Vector2(0.45, 0.37),
		"part_name": "НАГРУДНА ПЛИТА",
	},
	{
		"key": "armor",
		"short_title": "КЕВЛАР-ЩИТ",
		"title": "Кевларовий Підбій та Розвантаження",
		"category": "defense",
		"category_label": "МОДУЛЬ ЗАХИСТУ",
		"desc": "Поглинає частину вхідного урону від куль і вибухів та зменшує паузу між перекатами в окопі.",
		"accent": Color(0.44, 0.72, 0.92, 1.0),
		"part_uv": Vector2(0.43, 0.16),
		"part_name": "ШОЛОМ І ЗАХИСТ",
	},
	{
		"key": "medkit",
		"short_title": "АПТЕЧКА [F]",
		"title": "Польовий Автоін'єктор [F]",
		"category": "tactics",
		"category_label": "ТАКТИЧНИЙ МОДУЛЬ",
		"desc": "Бойові стимулятори скорочують час відновлення аптечки для швидкого порятунку під вогнем.",
		"accent": Color(0.38, 0.84, 0.54, 1.0),
		"part_uv": Vector2(0.34, 0.56),
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
		"part_uv": Vector2(0.62, 0.51),
		"part_name": "ПІДСТВОЛЬНИК / ГРАНАТИ",
	},
	{
		"key": "coins",
		"short_title": "МАРОДЕР [$]",
		"title": "Тактичний Сканер Трофеїв",
		"category": "tactics",
		"category_label": "ТАКТИЧНИЙ МОДУЛЬ",
		"desc": "Автоматичний збір цінних даних і трофеїв збільшує кількість монет за кожного знищеного ворога.",
		"accent": Color(0.96, 0.80, 0.30, 1.0),
		"part_uv": Vector2(0.22, 0.30),
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


func _ready() -> void:
	GAME_STATE.apply_audio_settings()
	if DisplayServer.get_name() != "headless":
		Input.set_custom_mouse_cursor(null)

	_init_audio()
	_setup_chassis_and_zones()
	_setup_back_button()
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
		"fire_rate": return TEX_ICON_FIRE_RATE
		"mag": return TEX_ICON_MAG
		"ammo": return TEX_ICON_AMMO
		"hp": return TEX_ICON_HP
		"armor": return TEX_ICON_ARMOR
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


# ── Побудова 3-зонного інтерфейсу «Тактичний Арсенал» ────────────────────────

func _setup_chassis_and_zones() -> void:
	upgrades_container.visible = false
	earned_label.visible = false

	# Металева рамка головного вікна з заклепками
	var main_bevel := _BevelPanelCanvas.new()
	main_bevel.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_bevel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_bevel.border_color = Color(0.74, 0.63, 0.38, 1.0)
	main_bevel.bg_color = Color(0.08, 0.09, 0.11, 0.0)
	main_bevel.draw_rivets = true
	panel_frame.add_child(main_bevel)

	# Налаштування верхньої шапки без налізання тексту (без перемикача ВІЗОР)
	level_label.position = Vector2(18, 9)
	level_label.size = Vector2(390, 40)
	level_label.add_theme_font_size_override("font_size", 19)

	title_label.position = Vector2(440, 9)
	title_label.size = Vector2(340, 40)
	title_label.text = "ТАКТИЧНИЙ АРСЕНАЛ"
	title_label.add_theme_font_size_override("font_size", 22)

	coins_label.position = Vector2(930, 6)
	coins_label.size = Vector2(272, 28)
	coins_label.add_theme_font_size_override("font_size", 21)

	_earned_header_badge = Label.new()
	_earned_header_badge.position = Vector2(930, 32)
	_earned_header_badge.size = Vector2(272, 20)
	_earned_header_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_earned_header_badge.add_theme_font_size_override("font_size", 12)
	_earned_header_badge.add_theme_color_override("font_color", Color(0.58, 0.92, 0.62, 0.95))
	header_bar.add_child(_earned_header_badge)

	# ── 1. ЛІВА ЗОНА: ОПЕРАТИВНИК З АВТОМАТОМ + СКІНИ ОКУЛЯРІВ (x=12..324) ──
	var left_zone := Control.new()
	left_zone.position = Vector2(12, 10)
	left_zone.size = Vector2(312, 510)
	body_box.add_child(left_zone)

	var left_bevel := _BevelPanelCanvas.new()
	left_bevel.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_bevel.bg_color = Color(0.075, 0.085, 0.10, 0.98)
	left_bevel.border_color = Color(0.56, 0.48, 0.30, 0.95)
	left_bevel.draw_rivets = true
	left_zone.add_child(left_bevel)

	var op_header := Label.new()
	op_header.position = Vector2(14, 8)
	op_header.size = Vector2(284, 22)
	op_header.text = "ОПЕРАТИВНИК // ОГЛЯД СПОРЯДЖЕННЯ"
	op_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	op_header.add_theme_font_size_override("font_size", 13)
	op_header.add_theme_color_override("font_color", Color(0.86, 0.76, 0.48))
	left_zone.add_child(op_header)

	# Інтерактивна вітрина бійця з автоматом
	_showcase_canvas = _SoldierShowcaseCanvas.new()
	_showcase_canvas.position = Vector2(12, 34)
	_showcase_canvas.size = Vector2(288, 252)
	left_zone.add_child(_showcase_canvas)

	# Панель вибору скіна (Окуляри / Шолом)
	var skin_title := Label.new()
	skin_title.position = Vector2(12, 292)
	skin_title.size = Vector2(288, 18)
	skin_title.text = "СКІН БІЙЦЯ (ТАКТИЧНІ ОКУЛЯРИ):"
	skin_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	skin_title.add_theme_font_size_override("font_size", 12)
	skin_title.add_theme_color_override("font_color", Color(0.82, 0.78, 0.66))
	left_zone.add_child(skin_title)

	var skin_row := HBoxContainer.new()
	skin_row.position = Vector2(10, 312)
	skin_row.size = Vector2(292, 32)
	skin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skin_row.add_theme_constant_override("separation", 4)
	left_zone.add_child(skin_row)

	var skins_meta := [
		{"id": "shades_gold", "label": "🕶 ЗОЛОТІ"},
		{"id": "shades_cyber", "label": "🕶 КІБЕР"},
		{"id": "shades_black", "label": "🕶 ЧОРНІ"},
		{"id": "standard", "label": "🪖 ШОЛОМ"},
	]
	for sm in skins_meta:
		var sbtn := _make_tactical_pill_button(String(sm["label"]), Vector2(69, 29), 11)
		var sid := String(sm["id"])
		sbtn.pressed.connect(_on_skin_selected.bind(sid))
		skin_row.add_child(sbtn)
		_skin_buttons[sid] = sbtn

	# Зведення бойових характеристик бійця (зі стилізованим повзунком прокрутки)
	var stats_bg := ColorRect.new()
	stats_bg.position = Vector2(12, 348)
	stats_bg.size = Vector2(288, 150)
	stats_bg.color = Color(0.045, 0.052, 0.064, 0.96)
	left_zone.add_child(stats_bg)

	var stats_border := ReferenceRect.new()
	stats_border.position = Vector2(12, 348)
	stats_border.size = Vector2(288, 150)
	stats_border.border_color = Color(0.46, 0.40, 0.26, 0.85)
	stats_border.border_width = 1.5
	stats_border.editor_only = false
	stats_border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left_zone.add_child(stats_border)

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

	var center_bevel := _BevelPanelCanvas.new()
	center_bevel.set_anchors_preset(Control.PRESET_FULL_RECT)
	center_bevel.bg_color = Color(0.085, 0.095, 0.112, 0.98)
	center_bevel.border_color = Color(0.58, 0.50, 0.32, 0.95)
	center_bevel.draw_rivets = true
	center_zone.add_child(center_bevel)

	# Панель категорій-фільтрів зверху центральної зони
	var cat_bar := HBoxContainer.new()
	cat_bar.position = Vector2(12, 10)
	cat_bar.size = Vector2(468, 34)
	cat_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	cat_bar.add_theme_constant_override("separation", 6)
	center_zone.add_child(cat_bar)

	var cats_meta := [
		{"id": "all", "label": "ВСІ [9]"},
		{"id": "weapon", "label": "ЗБРОЯ [4]"},
		{"id": "defense", "label": "ЗАХИСТ [2]"},
		{"id": "tactics", "label": "ТАКТИКА [3]"},
		{"id": "affordable", "label": "ДОСТУПНІ [$]"},
	]
	for cm in cats_meta:
		var cbtn := _make_tactical_pill_button(String(cm["label"]), Vector2(88, 32), 12)
		var cid := String(cm["id"])
		cbtn.pressed.connect(_on_category_filter_selected.bind(cid))
		cat_bar.add_child(cbtn)
		_cat_buttons[cid] = cbtn

	# Сітка 3x3 іконок характеристик
	var grid_root := Control.new()
	grid_root.position = Vector2(14, 52)
	grid_root.size = Vector2(464, 446)
	center_zone.add_child(grid_root)

	var tile_w := 148.0
	var tile_h := 142.0
	var gap_x := 10.0
	var gap_y := 9.0

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

	_insp_accent_frame = _BevelPanelCanvas.new()
	_insp_accent_frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	_insp_accent_frame.bg_color = Color(0.075, 0.085, 0.102, 0.98)
	_insp_accent_frame.border_color = Color(0.68, 0.56, 0.34, 0.98)
	_insp_accent_frame.draw_rivets = true
	right_zone.add_child(_insp_accent_frame)

	var insp_header := Label.new()
	insp_header.position = Vector2(14, 8)
	insp_header.size = Vector2(344, 20)
	insp_header.text = "ІНСПЕКТОР ХАРАКТЕРИСТИКИ"
	insp_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	insp_header.add_theme_font_size_override("font_size", 13)
	insp_header.add_theme_color_override("font_color", Color(0.86, 0.76, 0.48))
	right_zone.add_child(insp_header)

	# Верхній блок інспектора: велика іконка + категорія + назва
	var icon_well := ColorRect.new()
	icon_well.position = Vector2(16, 36)
	icon_well.size = Vector2(96, 96)
	icon_well.color = Color(0.04, 0.045, 0.055, 0.95)
	right_zone.add_child(icon_well)

	_insp_icon_rect = TextureRect.new()
	_insp_icon_rect.position = Vector2(20, 40)
	_insp_icon_rect.size = Vector2(88, 88)
	_insp_icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_insp_icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	right_zone.add_child(_insp_icon_rect)

	_insp_cat_label = Label.new()
	_insp_cat_label.position = Vector2(122, 38)
	_insp_cat_label.size = Vector2(236, 20)
	_insp_cat_label.add_theme_font_size_override("font_size", 12)
	_insp_cat_label.add_theme_color_override("font_color", Color(0.92, 0.72, 0.34))
	right_zone.add_child(_insp_cat_label)

	_insp_title_label = Label.new()
	_insp_title_label.position = Vector2(122, 58)
	_insp_title_label.size = Vector2(236, 52)
	_insp_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_title_label.add_theme_font_size_override("font_size", 18)
	_insp_title_label.add_theme_color_override("font_color", Color(0.96, 0.93, 0.85))
	_insp_title_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	_insp_title_label.add_theme_constant_override("outline_size", 4)
	right_zone.add_child(_insp_title_label)

	_insp_lvl_label = Label.new()
	_insp_lvl_label.position = Vector2(122, 110)
	_insp_lvl_label.size = Vector2(236, 22)
	_insp_lvl_label.add_theme_font_size_override("font_size", 14)
	_insp_lvl_label.add_theme_color_override("font_color", Color(0.75, 0.85, 0.98))
	right_zone.add_child(_insp_lvl_label)

	# 5-сегментна інтерактивна шкала рівня в стилі Peacekeeper + Tether6
	_insp_segments_canvas = _LevelSegmentsCanvas.new()
	_insp_segments_canvas.position = Vector2(16, 142)
	_insp_segments_canvas.size = Vector2(340, 34)
	right_zone.add_child(_insp_segments_canvas)

	# Опис модуля
	var desc_well := ColorRect.new()
	desc_well.position = Vector2(16, 186)
	desc_well.size = Vector2(340, 96)
	desc_well.color = Color(0.045, 0.052, 0.064, 0.92)
	right_zone.add_child(desc_well)

	_insp_desc_label = Label.new()
	_insp_desc_label.position = Vector2(26, 194)
	_insp_desc_label.size = Vector2(320, 80)
	_insp_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_insp_desc_label.add_theme_font_size_override("font_size", 14)
	_insp_desc_label.add_theme_color_override("font_color", Color(0.84, 0.82, 0.75))
	right_zone.add_child(_insp_desc_label)

	# Порівняння показників: Поточний -> Наступний рівень
	var stat_box := ColorRect.new()
	stat_box.position = Vector2(16, 292)
	stat_box.size = Vector2(340, 108)
	stat_box.color = Color(0.05, 0.06, 0.075, 0.96)
	right_zone.add_child(stat_box)

	var stat_hdr := Label.new()
	stat_hdr.position = Vector2(26, 298)
	stat_hdr.size = Vector2(320, 20)
	stat_hdr.text = "БОЙОВА ЕФЕКТИВНІСТЬ МОДУЛЯ:"
	stat_hdr.add_theme_font_size_override("font_size", 12)
	stat_hdr.add_theme_color_override("font_color", Color(0.76, 0.70, 0.54))
	right_zone.add_child(stat_hdr)

	_insp_stat_curr_label = Label.new()
	_insp_stat_curr_label.position = Vector2(26, 322)
	_insp_stat_curr_label.size = Vector2(320, 32)
	_insp_stat_curr_label.add_theme_font_size_override("font_size", 15)
	_insp_stat_curr_label.add_theme_color_override("font_color", Color(0.92, 0.90, 0.84))
	right_zone.add_child(_insp_stat_curr_label)

	_insp_stat_next_label = Label.new()
	_insp_stat_next_label.position = Vector2(26, 356)
	_insp_stat_next_label.size = Vector2(320, 36)
	_insp_stat_next_label.add_theme_font_size_override("font_size", 16)
	_insp_stat_next_label.add_theme_color_override("font_color", Color(0.48, 0.96, 0.58))
	right_zone.add_child(_insp_stat_next_label)

	# Велика тактична кнопка КУПИТИ МОДУЛЬ
	_insp_buy_button = Button.new()
	_insp_buy_button.position = Vector2(16, 414)
	_insp_buy_button.size = Vector2(340, 62)
	_insp_buy_button.focus_mode = Control.FOCUS_NONE
	_insp_buy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_insp_buy_button.add_theme_font_size_override("font_size", 20)
	_insp_buy_button.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.95))
	_insp_buy_button.add_theme_constant_override("outline_size", 5)
	_insp_buy_button.pressed.connect(_on_buy_selected_pressed)
	right_zone.add_child(_insp_buy_button)

	var hint_lbl := Label.new()
	hint_lbl.position = Vector2(16, 480)
	hint_lbl.size = Vector2(340, 22)
	hint_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_lbl.text = "Подвійний клік по іконці або [Enter] — швидка купівля"
	hint_lbl.add_theme_font_size_override("font_size", 11)
	hint_lbl.add_theme_color_override("font_color", Color(0.60, 0.58, 0.50))
	right_zone.add_child(hint_lbl)

	# ── 4. ПОВНОЕКРАННИЙ ВІЗУАЛЬНИЙ ФІЛЬТР (БУНКЕР / ТЕПЛОВІЗОР / НВБ / РАДАР) ──
	_atmosphere_overlay = _AtmosphereFilterCanvas.new()
	_atmosphere_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_atmosphere_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_atmosphere_overlay)
	move_child(fade_overlay, get_child_count() - 1)


func _make_tactical_pill_button(txt: String, min_sz: Vector2, font_sz: int) -> Button:
	var btn := Button.new()
	btn.custom_minimum_size = min_sz
	btn.focus_mode = Control.FOCUS_NONE
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.text = txt
	btn.add_theme_font_size_override("font_size", font_sz)
	btn.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	btn.add_theme_constant_override("outline_size", 3)
	return btn


func _style_pill_button(btn: Button, active: bool, accent: Color = Color(0.86, 0.74, 0.42)) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.22, 0.20, 0.14, 0.98) if active else Color(0.12, 0.13, 0.16, 0.95)
	normal.border_width_left = 2
	normal.border_width_top = 2
	normal.border_width_right = 2
	normal.border_width_bottom = 2
	normal.border_color = accent if active else Color(0.38, 0.35, 0.26, 0.85)
	normal.set_corner_radius_all(5)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = normal.bg_color.lightened(0.12)
	hover.border_color = accent.lightened(0.2)

	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_color_override(
		"font_color",
		Color(1.0, 0.95, 0.78) if active else Color(0.78, 0.76, 0.70)
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

	# Оновлюємо вітрину бійця з автоматом
	var inspect_key := _hovered_key if not _hovered_key.is_empty() else _selected_key
	var inspect_def := _get_def(inspect_key)
	if _showcase_canvas != null:
		_showcase_canvas.soldier_tex = _get_skin_texture(GAME_STATE.hero_skin)
		_showcase_canvas.skin_id = GAME_STATE.hero_skin
		_showcase_canvas.filter_mode = GAME_STATE.visual_filter
		_showcase_canvas.highlight_uv = inspect_def["part_uv"]
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
		var dps := float(GAME_STATE.get_player_bullet_damage()) * GAME_STATE.get_player_fire_rate()
		var crit_pct := int(round(GAME_STATE.get_player_crit_chance() * 100.0))
		var armor_pct := int(round(GAME_STATE.get_player_damage_reduction() * 100.0))
		var coin_pct := int(round((GAME_STATE.get_coin_multiplier() - 1.0) * 100.0))
		_stats_summary_label.text = (
			"[color=#dfc478][b]ЗВЕДЕННЯ ОПЕРАТИВНИКА[/b][/color]\n[color=#8fa4b8]Скін: %s[/color]\n" % skin_name
			+ "• Здоров'я: [color=#ff8a7a][b]%d HP[/b][/color]\n" % int(roundf(GAME_STATE.get_player_max_health()))
			+ "• Кевларовий захист: [color=#7ec8ff][b]-%d%% урону[/b][/color]\n" % armor_pct
			+ "• Урон автомата: [color=#ffb85c][b]%d[/b][/color]  |  Темп: [color=#ffd86b][b]%.1f/с[/b][/color]\n" % [int(roundf(GAME_STATE.get_player_bullet_damage())), GAME_STATE.get_player_fire_rate()]
			+ "• Вогнева потужність: [color=#ffe28a][b]%d DPS[/b][/color]\n" % int(round(dps))
			+ "• Магазин: [color=#e5d29c][b]%d наб.[/b][/color] (перезар. [b]%.2fс[/b])\n" % [GAME_STATE.get_player_magazine_size(), GAME_STATE.get_player_reload_time()]
			+ "• Шанс криту (×1.75): [color=#ff7a66][b]%d%%[/b][/color]\n" % crit_pct
			+ "• Польова аптечка [2]: [color=#6ee89a][b]КД %dс[/b][/color]\n" % int(round(GAME_STATE.get_player_medkit_cooldown()))
			+ "• Граната М67 [1]: [color=#ff9e5e][b]%d урону[/b][/color] (КД [b]%dс[/b])\n" % [int(roundf(GAME_STATE.get_player_grenade_damage())), int(round(GAME_STATE.get_player_grenade_cooldown()))]
			+ "• Бонус трофеїв: [color=#ffe066][b]+%d%% монет[/b][/color]" % coin_pct
		)

	# Оновлюємо кнопки категорій
	for cid in _cat_buttons.keys():
		var cbtn: Button = _cat_buttons[cid]
		_style_pill_button(cbtn, _active_category == cid, Color(0.92, 0.76, 0.36))

	# Оновлюємо всі 9 плиток у сітці
	for def in UPGRADE_DEFS:
		var key := String(def["key"])
		var tile: _UpgradeTile = _tiles_by_key.get(key)
		if tile == null:
			continue
		var lvl := GAME_STATE.get_upgrade_level(key)
		var maxed := not GAME_STATE.can_upgrade(key)
		var cost := GAME_STATE.get_upgrade_cost(key)
		var can_afford := (not maxed) and (GAME_STATE.coins >= cost)
		var matches_filter := _does_def_match_filter(def, can_afford)
		tile.update_state(lvl, GAME_STATE.MAX_UPGRADE_LEVEL, cost, can_afford, maxed, key == _selected_key, matches_filter)

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
	var max_lvl := GAME_STATE.MAX_UPGRADE_LEVEL
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
		_insp_stat_next_label.text = "Досягнуто максимальної потужності (5/5)"
		_insp_stat_next_label.add_theme_color_override("font_color", Color(0.98, 0.84, 0.38))
	else:
		_insp_stat_next_label.text = "Наступний: " + pair[1]
		_insp_stat_next_label.add_theme_color_override("font_color", Color(0.48, 0.96, 0.58))

	_style_buy_button(maxed, can_afford, cost)


func _get_stat_comparison_strings(key: String, lvl: int) -> Array[String]:
	var nl := mini(lvl + 1, GAME_STATE.MAX_UPGRADE_LEVEL)
	match key:
		"damage":
			return ["%d урону за постріл" % (10 + lvl * 3), "%d урону за постріл (+3)" % (10 + nl * 3)]
		"fire_rate":
			return ["%.1f постр./сек" % (10.0 + lvl * 1.2), "%.1f постр./сек (+1.2/с)" % (10.0 + nl * 1.2)]
		"mag":
			return ["%d набоїв | %.2fс перезарядка" % [30 + lvl * 5, 3.5 - lvl * 0.30], "%d набоїв | %.2fс (-0.30с)" % [30 + nl * 5, 3.5 - nl * 0.30]]
		"ammo":
			return ["Крит %d%% (x1.75) | Швидк. %d" % [lvl * 8, 1380 + lvl * 130], "Крит %d%% (+8%%) | Швидк. %d" % [nl * 8, 1380 + nl * 130]]
		"hp":
			return ["%d HP макс. здоров'я" % (100 + lvl * 25), "%d HP макс. здоров'я (+25 HP)" % (100 + nl * 25)]
		"armor":
			return ["-%d%% вхідного урону" % (lvl * 6), "-%d%% вхідного урону (+6%% захисту)" % (nl * 6)]
		"medkit":
			return ["Перезарядка аптечки: %d сек" % (40 - lvl * 4), "Перезарядка аптечки: %d сек (-4с)" % (40 - nl * 4)]
		"grenade":
			return ["%d урону | КД %d сек" % [140 + lvl * 28, 30 - lvl * 3], "%d урону (+28) | КД %d сек (-3с)" % [140 + nl * 28, 30 - nl * 3]]
		"coins":
			return ["+%d%% монет з ворогів" % (lvl * 20), "+%d%% монет з ворогів (+20%%)" % (nl * 20)]
	return ["", ""]


func _style_buy_button(maxed: bool, can_afford: bool, cost: int) -> void:
	var sb_normal := StyleBoxFlat.new()
	sb_normal.set_corner_radius_all(7)
	sb_normal.border_width_left = 3
	sb_normal.border_width_top = 3
	sb_normal.border_width_right = 3
	sb_normal.border_width_bottom = 3

	if maxed:
		_insp_buy_button.text = "★ МАКСИМАЛЬНИЙ РІВЕНЬ (5/5)"
		_insp_buy_button.disabled = true
		sb_normal.bg_color = Color(0.24, 0.21, 0.12, 0.95)
		sb_normal.border_color = Color(0.86, 0.72, 0.32, 0.9)
		_insp_buy_button.add_theme_color_override("font_disabled_color", Color(0.98, 0.86, 0.44))
	elif can_afford:
		_insp_buy_button.text = "КУПИТИ МОДУЛЬ  —  $%d" % cost
		_insp_buy_button.disabled = false
		sb_normal.bg_color = Color(0.18, 0.38, 0.22, 0.98)
		sb_normal.border_color = Color(0.52, 0.92, 0.58, 1.0)
		_insp_buy_button.add_theme_color_override("font_color", Color(0.96, 1.0, 0.94))
	else:
		_insp_buy_button.text = "НЕДОСТАТНЬО МОНЕТ ($%d)" % cost
		_insp_buy_button.disabled = true
		sb_normal.bg_color = Color(0.18, 0.14, 0.14, 0.95)
		sb_normal.border_color = Color(0.52, 0.30, 0.28, 0.85)
		_insp_buy_button.add_theme_color_override("font_disabled_color", Color(0.82, 0.56, 0.52))

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
# ДОПОМІЖНІ ВІЗУАЛЬНІ КЛАСИ (ТЕМАТИКА TETHER6: ЗНОШЕНА ЛАТУНЬ + ТЕМНА СТАЛЬ)
# ══════════════════════════════════════════════════════════════════════════════

class _BevelPanelCanvas extends Control:
	var bg_color: Color = Color(0.08, 0.09, 0.11, 0.96)
	var border_color: Color = Color(0.68, 0.58, 0.36, 0.96)
	var draw_rivets: bool = true

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		if bg_color.a > 0.01:
			draw_rect(r, bg_color, true)
		# Подвійна латунна рамка зі скошеним металевим відблиском
		draw_rect(r, Color(0.04, 0.045, 0.055, 0.95), false, 3.0)
		draw_rect(r.grow(-2.0), border_color, false, 2.0)
		draw_line(Vector2(3, 3), Vector2(size.x - 3, 3), border_color.lightened(0.28), 1.5)
		draw_rect(r.grow(-5.0), Color(0.18, 0.20, 0.24, 0.75), false, 1.0)

		if draw_rivets:
			var pts := [
				Vector2(9, 9),
				Vector2(size.x - 9, 9),
				Vector2(9, size.y - 9),
				Vector2(size.x - 9, size.y - 9),
			]
			for p in pts:
				draw_circle(p, 3.5, Color(0.12, 0.11, 0.09, 1.0))
				draw_circle(p, 2.3, border_color.lightened(0.15))


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

	func update_state(lvl: int, max_lvl: int, cost: int, can_afford: bool, maxed: bool, selected: bool, matches_filter: bool) -> void:
		_lvl = lvl
		_max_lvl = max_lvl
		_cost = cost
		_can_afford = can_afford
		_maxed = maxed
		_selected = selected
		_matches_filter = matches_filter
		modulate.a = 1.0 if matches_filter else 0.28
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

		# Базова підкладка плитки
		var bg := Color(0.11, 0.125, 0.15, 0.98)
		if _selected:
			bg = Color(0.17, 0.18, 0.21, 0.99)
		elif _hovered:
			bg = Color(0.14, 0.155, 0.185, 0.99)
		draw_rect(r, bg, true)

		# Рамка плитки
		var border_col := Color(0.42, 0.38, 0.28, 0.9)
		var border_w := 2.0
		if _selected:
			var glow := 0.5 + 0.5 * sin(t_sec * 2.2)
			border_col = accent.lerp(Color(1.0, 0.92, 0.62, 1.0), 0.35 + 0.25 * glow)
			border_w = 2.5
		elif _hovered:
			border_col = accent.lightened(0.15)
		elif _maxed:
			border_col = Color(0.86, 0.72, 0.32, 0.92)
		draw_rect(r.grow(-1.0), border_col, false, border_w)

		# Спалах при купівлі
		if _pulse_t > 0.0:
			draw_rect(r.grow(-2.0), Color(1.0, 0.92, 0.55, _pulse_t * 0.42), true)

		# Іконка в центрі-вгорі
		if _icon_tex != null:
			var icon_sz := Vector2(74, 74)
			var icon_pos := Vector2((size.x - icon_sz.x) * 0.5, 16.0)
			draw_texture_rect(_icon_tex, Rect2(icon_pos, icon_sz), false)

		# Статусний світлодіод у лівому верхньому куті + бейдж вартості / MAX у правому
		var led_col := Color(0.42, 0.44, 0.48, 0.9)
		if _maxed:
			led_col = Color(0.98, 0.82, 0.28, 1.0)
		elif _can_afford:
			led_col = Color(0.35, 0.95, 0.50, 1.0)
		else:
			led_col = Color(0.85, 0.32, 0.28, 0.85)
		draw_circle(Vector2(12, 12), 4.5, Color(0.05, 0.05, 0.06, 0.95))
		draw_circle(Vector2(12, 12), 3.2, led_col)

		var font := ThemeDB.fallback_font
		if font != null:
			var badge_txt := "MAX" if _maxed else ("$%d" % _cost)
			var badge_col := Color(0.98, 0.86, 0.38) if _maxed else (Color(0.55, 0.98, 0.62) if _can_afford else Color(0.82, 0.55, 0.52))
			draw_string(font, Vector2(size.x - 48, 16), badge_txt, HORIZONTAL_ALIGNMENT_RIGHT, 42, 12, badge_col)

			# Назва модуля
			var short_title := String(_def.get("short_title", ""))
			draw_string(font, Vector2(4, 108), short_title, HORIZONTAL_ALIGNMENT_CENTER, size.x - 8, 12, Color(0.95, 0.92, 0.84))

		# 5 міні-сегментів рівня внизу плитки
		var pip_w := 21.0
		var pip_h := 7.0
		var pip_gap := 4.0
		var total_w := _max_lvl * pip_w + (_max_lvl - 1) * pip_gap
		var start_x := (size.x - total_w) * 0.5
		var pip_y := size.y - 16.0
		for i in range(_max_lvl):
			var pr := Rect2(Vector2(start_x + i * (pip_w + pip_gap), pip_y), Vector2(pip_w, pip_h))
			if i < _lvl:
				draw_rect(pr, accent.lightened(0.12), true)
			elif i == _lvl and _can_afford and (_selected or _hovered):
				var p_alpha := 0.35 + 0.35 * sin(t_sec * 3.0)
				draw_rect(pr, Color(accent.r, accent.g, accent.b, p_alpha), true)
			else:
				draw_rect(pr, Color(0.06, 0.07, 0.09, 0.95), true)
			draw_rect(pr, Color(0.32, 0.30, 0.24, 0.85), false, 1.0)

		# Латунні кутові дужки при виборі
		if _selected:
			var cl := 10.0
			var c_col := Color(1.0, 0.90, 0.52, 1.0)
			draw_line(Vector2(2, 2), Vector2(2 + cl, 2), c_col, 2.5)
			draw_line(Vector2(2, 2), Vector2(2, 2 + cl), c_col, 2.5)
			draw_line(Vector2(size.x - 2, 2), Vector2(size.x - 2 - cl, 2), c_col, 2.5)
			draw_line(Vector2(size.x - 2, 2), Vector2(size.x - 2, 2 + cl), c_col, 2.5)
			draw_line(Vector2(2, size.y - 2), Vector2(2 + cl, size.y - 2), c_col, 2.5)
			draw_line(Vector2(2, size.y - 2), Vector2(2, size.y - 2 - cl), c_col, 2.5)
			draw_line(Vector2(size.x - 2, size.y - 2), Vector2(size.x - 2 - cl, size.y - 2), c_col, 2.5)
			draw_line(Vector2(size.x - 2, size.y - 2), Vector2(size.x - 2, size.y - 2 - cl), c_col, 2.5)


class _LevelSegmentsCanvas extends Control:
	var current_level: int = 0
	var max_level: int = 5
	var accent_color: Color = Color(0.92, 0.72, 0.32)
	var can_afford_next: bool = false

	func _process(_delta: float) -> void:
		if can_afford_next:
			queue_redraw()

	func _draw() -> void:
		var gap := 8.0
		var seg_w := (size.x - gap * float(max_level - 1)) / float(max_level)
		var seg_h := size.y
		var t_sec := float(Time.get_ticks_msec()) * 0.005

		for i in range(max_level):
			var r := Rect2(Vector2(i * (seg_w + gap), 0.0), Vector2(seg_w, seg_h))
			draw_rect(r, Color(0.05, 0.06, 0.08, 0.98), true)
			if i < current_level:
				var fill_r := r.grow(-3.0)
				draw_rect(fill_r, accent_color, true)
				draw_rect(Rect2(fill_r.position, Vector2(fill_r.size.x, fill_r.size.y * 0.38)), accent_color.lightened(0.28), true)
			elif i == current_level and can_afford_next:
				var pulse := 0.25 + 0.25 * sin(t_sec * 2.2)
				draw_rect(r.grow(-3.0), Color(accent_color.r, accent_color.g, accent_color.b, pulse), true)
			draw_rect(r, Color(0.62, 0.54, 0.34, 0.92) if i < current_level else Color(0.32, 0.30, 0.25, 0.85), false, 2.0)


class _SoldierShowcaseCanvas extends Control:
	var soldier_tex: Texture2D = null
	var skin_id: String = "shades_gold"
	var filter_mode: String = "bunker"
	var highlight_uv: Vector2 = Vector2(0.84, 0.48)
	var highlight_label: String = "ДУЛЬНИЙ ЗРІЗ"
	var highlight_color: Color = Color(0.94, 0.56, 0.24)

	var _time: float = 0.0
	var _sparks: Array[Dictionary] = []

	func trigger_upgrade_burst(uv: Vector2, col: Color) -> void:
		var center := Vector2(36.0 + uv.x * 212.0, 14.0 + uv.y * 220.0)
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
		# Фон тактичного сканера
		var well_col := Color(0.035, 0.042, 0.052, 0.98)
		var grid_col := Color(0.68, 0.58, 0.34, 0.09)
		match filter_mode:
			"thermal":
				well_col = Color(0.07, 0.03, 0.09, 0.98)
				grid_col = Color(0.95, 0.48, 0.18, 0.14)
			"nvg":
				well_col = Color(0.02, 0.07, 0.035, 0.98)
				grid_col = Color(0.25, 0.92, 0.45, 0.14)
			"crt":
				well_col = Color(0.025, 0.05, 0.08, 0.98)
				grid_col = Color(0.35, 0.82, 0.98, 0.14)
		draw_rect(r, well_col, true)

		# Тактична координатна сітка + радарні кола
		for x in range(24, int(size.x), 24):
			draw_line(Vector2(x, 0), Vector2(x, size.y), grid_col, 1.0)
		for y in range(24, int(size.y), 24):
			draw_line(Vector2(0, y), Vector2(size.x, y), grid_col, 1.0)

		var center_radar := Vector2(size.x * 0.46, size.y * 0.52)
		draw_arc(center_radar, 72.0, 0.0, TAU, 48, grid_col * Color(1, 1, 1, 1.6), 1.2)
		draw_arc(center_radar, 108.0, 0.0, TAU, 64, grid_col * Color(1, 1, 1, 1.2), 1.0)

		# Горизонтальна скануюча лінія
		var scan_y := fmod(_time * 48.0, size.y)
		draw_line(Vector2(2, scan_y), Vector2(size.x - 2, scan_y), Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.22), 2.0)

		# Тінь під ногами бійця
		var shadow_c := Vector2(120, 224)
		draw_set_transform(shadow_c, 0.0, Vector2(1.0, 0.28))
		draw_circle(Vector2.ZERO, 62.0, Color(0, 0, 0, 0.55))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

		# Малюємо бійця з автоматом з живим диханням
		var bob_y := sin(_time * 2.4) * 2.2
		var sprite_origin := Vector2(36.0, 12.0 + bob_y)
		var sprite_size := Vector2(212.0, 220.0)
		if soldier_tex != null:
			var tint := Color.WHITE
			if filter_mode == "thermal":
				tint = Color(1.08, 0.92, 0.78, 1.0)
			elif filter_mode == "nvg":
				tint = Color(0.82, 1.08, 0.86, 1.0)
			draw_texture_rect(soldier_tex, Rect2(sprite_origin, sprite_size), false, tint)

		# Тактичний лазерний промінь з ЛЦВ автомата
		var laser_start := sprite_origin + Vector2(174.0, 102.0)
		var laser_end := Vector2(size.x - 4.0, laser_start.y + 19.0)
		var laser_col := Color(0.98, 0.24, 0.18, 0.55 + 0.25 * sin(_time * 8.0))
		if skin_id == "shades_cyber":
			laser_col = Color(0.25, 0.90, 1.0, 0.60 + 0.25 * sin(_time * 8.0))
		draw_line(laser_start, laser_end, laser_col, 2.0)
		draw_circle(laser_start, 3.0, laser_col.lightened(0.35))

		# Інтерактивний приціл-мітка на вузлі зброї або броні, який зараз обрано
		var target_pos := sprite_origin + Vector2(highlight_uv.x * sprite_size.x, highlight_uv.y * sprite_size.y)
		var pulse_r := 13.0 + 3.0 * sin(_time * 5.0)
		draw_arc(target_pos, pulse_r, 0.0, TAU, 32, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.92), 2.0)
		draw_arc(target_pos, pulse_r + 5.0, _time * 1.8, _time * 1.8 + PI * 0.65, 16, highlight_color.lightened(0.25), 2.0)
		draw_arc(target_pos, pulse_r + 5.0, _time * 1.8 + PI, _time * 1.8 + PI * 1.65, 16, highlight_color.lightened(0.25), 2.0)
		draw_circle(target_pos, 2.5, Color(1, 0.96, 0.82, 0.95))

		# Виноска з назвою вузла у верхньому куті вітрини
		var callout_box := Rect2(Vector2(8, 8), Vector2(168, 22))
		draw_rect(callout_box, Color(0.05, 0.06, 0.08, 0.88), true)
		draw_rect(callout_box, highlight_color, false, 1.5)
		draw_line(Vector2(callout_box.end.x, callout_box.get_center().y), target_pos, Color(highlight_color.r, highlight_color.g, highlight_color.b, 0.55), 1.5)
		var font := ThemeDB.fallback_font
		if font != null:
			draw_string(font, Vector2(14, 23), "ВУЗОЛ: " + highlight_label, HORIZONTAL_ALIGNMENT_LEFT, 156, 11, highlight_color.lightened(0.25))

		# Іскри при покупці покращення або зміні скіна
		for s in _sparks:
			var ratio := clampf(float(s["life"]) / float(s["max_life"]), 0.0, 1.0)
			var c: Color = s["col"]
			c.a = ratio
			var p: Vector2 = s["pos"]
			draw_circle(p, 2.8 * ratio, c)

		# Металева рамка вітрини
		draw_rect(r, Color(0.56, 0.48, 0.30, 0.95), false, 2.0)


class _AtmosphereFilterCanvas extends Control:
	var filter_mode: String = "bunker"
	var _t: float = 0.0
	var _embers: Array[Dictionary] = []

	func _ready() -> void:
		for i in range(28):
			_embers.append({
				"x": randf() * 1280.0,
				"y": randf() * 720.0,
				"vx": randf_range(-14.0, 18.0),
				"vy": randf_range(-28.0, -10.0),
				"sz": randf_range(1.4, 3.2),
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

		# Tinted atmosphere overlay per filter
		match filter_mode:
			"thermal":
				draw_rect(Rect2(0, 0, w, h), Color(0.24, 0.06, 0.18, 0.14), true)
			"nvg":
				draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.26, 0.10, 0.14), true)
			"crt":
				draw_rect(Rect2(0, 0, w, h), Color(0.04, 0.16, 0.26, 0.12), true)
			_:
				draw_rect(Rect2(0, 0, w, h), Color(0.18, 0.13, 0.05, 0.06), true)

		# Тонкі CRT скан-лінії
		var line_col := Color(0, 0, 0, 0.12)
		for y in range(0, int(h), 4):
			draw_line(Vector2(0, y), Vector2(w, y), line_col, 1.0)

		# Плаваючі іскри / пил в повітрі
		for e in _embers:
			var glow := 0.35 + 0.35 * sin(_t * 2.5 + float(e["phase"]))
			var ecol := Color(0.98, 0.76, 0.32, glow * 0.55)
			if filter_mode == "nvg":
				ecol = Color(0.38, 0.98, 0.55, glow * 0.55)
			elif filter_mode == "crt":
				ecol = Color(0.42, 0.86, 1.0, glow * 0.55)
			elif filter_mode == "thermal":
				ecol = Color(1.0, 0.48, 0.22, glow * 0.60)
			draw_circle(Vector2(float(e["x"]), float(e["y"])), float(e["sz"]), ecol)
