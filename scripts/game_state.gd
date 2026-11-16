class_name GameState
extends RefCounted

const TOTAL_LEVELS := 15
const BOSS_LEVEL := 10
const MAX_UPGRADE_LEVEL := 5
const MAX_ARMOR_UPGRADE_LEVEL := 6
const MAX_WEAPON_UPGRADE_LEVEL := 6
const BASE_UPGRADE_COST := 50

static var current_level: int = 1
static var coins: int = 0
static var last_level_earned: int = 0
static var last_level_coins_earned: int = 0
static var master_volume: float = 0.8
static var test_skip_to_boss: bool = false
static var test_boss_only_mode: bool = false

## Скін оперативника: "shades_gold" (Окуляри «Золотий Хижак»), "shades_cyber" (Окуляри «Кібер-Неон»), "standard" (Шолом)
static var hero_skin: String = "shades_gold"

## Візуальний фільтр терміналу: "bunker", "thermal", "nvg", "crt"
static var visual_filter: String = "bunker"

# Legacy змінні рівнів прокачки (синхронізуються зі словником upgrade_levels)
static var upg_hp_level: int = 0
static var upg_damage_level: int = 0
static var upg_coins_level: int = 0

static var upgrade_levels: Dictionary = {
	"hp": 0,
	"damage": 0,
	"coins": 0,
	"ammo": 0,
	"medkit": 0,
	"grenade": 0,
}

# Таблиця 15 рівнів із збільшеною кількістю ворогів
const LEVEL_DATA: Array[Dictionary] = [
	{"infantry": 12, "shotgun": 2, "heavy": 2, "grenadier": 2, "axe": 5, "snipers": 2, "heli": 0, "heli_troops": 0, "spawn_interval": 1.85, "reward": 60},
	{"infantry": 15, "shotgun": 3, "heavy": 3, "grenadier": 2, "axe": 6, "snipers": 2, "heli": 0, "heli_troops": 0, "spawn_interval": 1.75, "reward": 75},
	{"infantry": 16, "shotgun": 4, "heavy": 3, "grenadier": 2, "axe": 6, "snipers": 3, "heli": 1, "heli_troops": 3, "spawn_interval": 1.68, "reward": 95},
	{"infantry": 18, "shotgun": 5, "heavy": 4, "grenadier": 3, "axe": 7, "snipers": 3, "heli": 0, "heli_troops": 0, "spawn_interval": 1.62, "reward": 110},
	{"infantry": 20, "shotgun": 6, "heavy": 4, "grenadier": 3, "axe": 7, "snipers": 3, "heli": 1, "heli_troops": 4, "has_boss": true, "spawn_interval": 1.56, "reward": 200},
	{"infantry": 22, "shotgun": 7, "heavy": 5, "grenadier": 4, "axe": 8, "snipers": 4, "heli": 1, "heli_troops": 4, "spawn_interval": 1.50, "reward": 150},
	{"infantry": 24, "shotgun": 8, "heavy": 5, "grenadier": 4, "axe": 8, "snipers": 4, "heli": 1, "heli_troops": 4, "spawn_interval": 1.45, "reward": 170},
	{"infantry": 26, "shotgun": 9, "heavy": 6, "grenadier": 4, "axe": 9, "snipers": 4, "heli": 1, "heli_troops": 5, "spawn_interval": 1.40, "reward": 195},
	{"infantry": 28, "shotgun": 10, "heavy": 6, "grenadier": 5, "axe": 10, "snipers": 5, "heli": 2, "heli_troops": 4, "spawn_interval": 1.35, "reward": 220},
	{"infantry": 30, "shotgun": 11, "heavy": 7, "grenadier": 5, "axe": 10, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 1.30, "reward": 400, "has_boss": true, "boss_type": "hammer", "max_boss_minions": 4},
	{"infantry": 32, "shotgun": 12, "heavy": 7, "grenadier": 6, "axe": 11, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 1.25, "reward": 280},
	{"infantry": 34, "shotgun": 13, "heavy": 8, "grenadier": 6, "axe": 11, "snipers": 6, "heli": 2, "heli_troops": 5, "spawn_interval": 1.20, "reward": 310},
	{"infantry": 36, "shotgun": 14, "heavy": 9, "grenadier": 7, "axe": 12, "snipers": 6, "heli": 2, "heli_troops": 6, "spawn_interval": 1.15, "reward": 350},
	{"infantry": 39, "shotgun": 15, "heavy": 10, "grenadier": 8, "axe": 13, "snipers": 6, "heli": 3, "heli_troops": 5, "spawn_interval": 1.10, "reward": 400},
	{"infantry": 42, "shotgun": 16, "heavy": 12, "grenadier": 9, "axe": 14, "snipers": 6, "heli": 3, "heli_troops": 6, "spawn_interval": 1.05, "reward": 500},
]


static func get_current_level_data() -> Dictionary:
	var idx := clampi(current_level - 1, 0, LEVEL_DATA.size() - 1)
	return LEVEL_DATA[idx]


static func get_enemy_hp_multiplier(wave_index: int = 0) -> float:
	var step := maxi(current_level - 1, 0) + maxi(wave_index, 0)
	return 1.0 + 0.10 * float(step)


static func get_enemy_health_multiplier_for_level(level: int = current_level) -> float:
	var step := maxi(level - 1, 0)
	return 1.0 + 0.10 * float(step)


static func get_upgrade_level(upg_key: String) -> int:
	return int(upgrade_levels.get(upg_key, 0))


static func _set_upgrade_level(upg_key: String, val: int) -> void:
	upgrade_levels[upg_key] = val
	match upg_key:
		"hp":
			upg_hp_level = val
		"damage":
			upg_damage_level = val
		"coins":
			upg_coins_level = val


static func get_max_upgrade_level(upg_key: String) -> int:
	if upg_key == "hp":
		return MAX_ARMOR_UPGRADE_LEVEL
	if upg_key == "damage":
		return MAX_WEAPON_UPGRADE_LEVEL
	return MAX_UPGRADE_LEVEL


static func get_armor_tier() -> int:
	return 1 + clampi(get_upgrade_level("hp"), 0, MAX_ARMOR_UPGRADE_LEVEL)


static func get_weapon_tier() -> int:
	return 1 + clampi(get_upgrade_level("damage"), 0, MAX_WEAPON_UPGRADE_LEVEL)


static func can_upgrade(upg_key: String) -> bool:
	return get_upgrade_level(upg_key) < get_max_upgrade_level(upg_key)


static func get_upgrade_cost(upg_key: String) -> int:
	var lvl := get_upgrade_level(upg_key)
	if lvl >= get_max_upgrade_level(upg_key):
		return 0
	var base_cost := BASE_UPGRADE_COST
	match upg_key:
		"ammo", "grenade":
			base_cost = 60
		"medkit":
			base_cost = 45
	return base_cost * (1 << lvl)


static func can_buy_upgrade(upg_key: String) -> bool:
	var lvl := get_upgrade_level(upg_key)
	if lvl >= get_max_upgrade_level(upg_key):
		return false
	return coins >= get_upgrade_cost(upg_key)


static func buy_upgrade(upg_key: String) -> bool:
	if not can_buy_upgrade(upg_key):
		return false
	var cost := get_upgrade_cost(upg_key)
	coins -= cost
	_set_upgrade_level(upg_key, get_upgrade_level(upg_key) + 1)
	return true


static func try_buy_upgrade(upg_key: String) -> bool:
	return buy_upgrade(upg_key)


static func add_coins(amount: int) -> void:
	var gained := maxi(0, amount)
	coins += gained
	last_level_earned += gained
	last_level_coins_earned = last_level_earned


static func start_level_run() -> void:
	last_level_earned = 0
	last_level_coins_earned = 0


# ── Бойові характеристики гравця з урахуванням прокачки ─────────────────────

static func get_player_max_health() -> float:
	return 100.0 + float(get_upgrade_level("hp")) * 25.0


static func get_player_bullet_damage() -> float:
	return 10.0 + float(get_upgrade_level("damage")) * 3.0


static func get_player_bullet_speed() -> float:
	return 1380.0 + float(get_upgrade_level("ammo")) * 130.0


static func get_player_crit_chance() -> float:
	return float(get_upgrade_level("ammo")) * 0.08


static func get_player_medkit_cooldown() -> float:
	return maxf(18.0, 40.0 - float(get_upgrade_level("medkit")) * 4.0)


static func get_player_grenade_damage() -> float:
	return 140.0 + float(get_upgrade_level("grenade")) * 28.0


static func get_player_grenade_cooldown() -> float:
	return maxf(15.0, 30.0 - float(get_upgrade_level("grenade")) * 3.0)


static func get_coin_multiplier() -> float:
	return 1.0 + float(get_upgrade_level("coins")) * 0.20


static func get_kill_reward(unit_type: String) -> int:
	var base_reward := 12
	match unit_type:
		"boss":
			base_reward = 250
		"boss_hammer":
			base_reward = 350
		"sniper":
			base_reward = 25
		"heavy":
			base_reward = 30
		"grenadier":
			base_reward = 28
		"axe":
			base_reward = 24
		"shotgun":
			base_reward = 20
		_:
			base_reward = 12
	return int(roundf(float(base_reward) * get_coin_multiplier()))


static func reset_campaign() -> void:
	current_level = 1
	coins = 0
	last_level_earned = 0
	last_level_coins_earned = 0
	upg_hp_level = 0
	upg_damage_level = 0
	upg_coins_level = 0
	for k in upgrade_levels.keys():
		upgrade_levels[k] = 0
	test_skip_to_boss = false
	test_boss_only_mode = false


static func jump_to_test_level_10(skip_to_boss: bool = false) -> void:
	current_level = 10
	test_skip_to_boss = skip_to_boss
	test_boss_only_mode = skip_to_boss
	if get_upgrade_level("hp") == 0 and get_upgrade_level("damage") == 0:
		_set_upgrade_level("hp", 3)
		_set_upgrade_level("damage", 3)
		coins = maxi(coins, 500)


static func create_test_button(text_label: String, base_col: Color) -> Button:
	var btn := Button.new()
	btn.text = text_label
	btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	btn.add_theme_font_size_override("font_size", 16)
	btn.add_theme_color_override("font_color", Color(0.97, 0.94, 0.85, 1.0))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.98, 0.90, 1.0))

	var normal_sb := StyleBoxFlat.new()
	normal_sb.bg_color = base_col
	normal_sb.border_color = Color(0.76, 0.64, 0.36, 0.92)
	normal_sb.set_border_width_all(2)
	normal_sb.set_corner_radius_all(6)

	var hover_sb := normal_sb.duplicate() as StyleBoxFlat
	hover_sb.bg_color = base_col.lightened(0.14)
	hover_sb.border_color = Color(0.95, 0.82, 0.48, 1.0)

	var pressed_sb := normal_sb.duplicate() as StyleBoxFlat
	pressed_sb.bg_color = base_col.darkened(0.16)

	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", hover_sb)
	return btn


static func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	apply_audio_settings()


static func apply_audio_settings() -> void:
	var bus_idx := AudioServer.get_bus_index("Master")
	if bus_idx == -1:
		return
	if master_volume <= 0.001:
		AudioServer.set_bus_mute(bus_idx, true)
	else:
		AudioServer.set_bus_mute(bus_idx, false)
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(master_volume))
