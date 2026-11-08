class_name GameState
extends RefCounted

const TOTAL_LEVELS := 15
const MAX_UPGRADE_LEVEL := 5
const BASE_UPGRADE_COST := 50

static var current_level: int = 1
static var coins: int = 0
static var last_level_earned: int = 0

# Рівні прокачки (від 0 до MAX_UPGRADE_LEVEL = 5)
static var upg_hp_level: int = 0
static var upg_damage_level: int = 0
static var upg_grenades_level: int = 0
static var upg_coins_level: int = 0

# Таблиця 15 рівнів із збільшеною кількістю ворогів (на 1 рівні втричі більше, далі пропорційно більше, червоні важкі кулеметники є на кожному рівні)
const LEVEL_DATA: Array[Dictionary] = [
	# Рівень 1: ~3x більше ворогів (12 піхотинців + 2 дробовики + 2 червоні кулеметники + 2 гранатометники + 2 снайпери = 20 ворогів)
	{"infantry": 12, "shotgun": 2, "heavy": 2, "grenadier": 2, "snipers": 2, "heli": 0, "heli_troops": 0, "spawn_interval": 1.85, "reward": 60},
	# Рівень 2: більше піхоти + дробовики + 3 червоні кулеметники + гранатометники + снайпери
	{"infantry": 15, "shotgun": 3, "heavy": 3, "grenadier": 2, "snipers": 2, "heli": 0, "heli_troops": 0, "spawn_interval": 1.75, "reward": 75},
	# Рівень 3: перший вертоліт з десантом + 3 червоні кулеметники + стрій піхоти та дробовики
	{"infantry": 16, "shotgun": 4, "heavy": 3, "grenadier": 2, "snipers": 3, "heli": 1, "heli_troops": 3, "spawn_interval": 1.68, "reward": 95},
	# Рівень 4: 4 червоні важкі кулеметники + строї з 5 бійців
	{"infantry": 18, "shotgun": 5, "heavy": 4, "grenadier": 3, "snipers": 3, "heli": 0, "heli_troops": 0, "spawn_interval": 1.62, "reward": 110},
	# Рівень 5: вертоліт + 4 червоні кулеметники + гранатометники + снайпери
	{"infantry": 20, "shotgun": 6, "heavy": 4, "grenadier": 3, "snipers": 3, "heli": 1, "heli_troops": 4, "spawn_interval": 1.56, "reward": 130},
	# Рівень 6: інтенсивний штурм дробовиків, 5 кулеметників та піхоти у строях V і в лінію
	{"infantry": 22, "shotgun": 7, "heavy": 5, "grenadier": 4, "snipers": 4, "heli": 1, "heli_troops": 4, "spawn_interval": 1.50, "reward": 150},
	# Рівень 7: посилені хвилі з 5 кулеметниками та гранатометниками
	{"infantry": 24, "shotgun": 8, "heavy": 5, "grenadier": 4, "snipers": 4, "heli": 1, "heli_troops": 4, "spawn_interval": 1.45, "reward": 170},
	# Рівень 8: 4 підхвилі, 6 кулеметників, снайпери на пагорбі + десант
	{"infantry": 26, "shotgun": 9, "heavy": 6, "grenadier": 4, "snipers": 4, "heli": 1, "heli_troops": 5, "spawn_interval": 1.40, "reward": 195},
	# Рівень 9: подвійний вертолітний десант + 6 кулеметників + масовані хвилі
	{"infantry": 28, "shotgun": 10, "heavy": 6, "grenadier": 5, "snipers": 5, "heli": 2, "heli_troops": 4, "spawn_interval": 1.35, "reward": 220},
	# Рівень 10: рубіж екватора кампанії, 7 кулеметників
	{"infantry": 30, "shotgun": 11, "heavy": 7, "grenadier": 5, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 1.30, "reward": 250},
	# Рівень 11: важка піхота, 7 кулеметників та строї дробовиків
	{"infantry": 32, "shotgun": 12, "heavy": 7, "grenadier": 6, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 1.25, "reward": 280},
	# Рівень 12: масований штурм у 4 хвилі, 8 кулеметників
	{"infantry": 34, "shotgun": 13, "heavy": 8, "grenadier": 6, "snipers": 6, "heli": 2, "heli_troops": 5, "spawn_interval": 1.20, "reward": 310},
	# Рівень 13: потужний наступ з усіх напрямків, 9 кулеметників
	{"infantry": 36, "shotgun": 14, "heavy": 9, "grenadier": 7, "snipers": 6, "heli": 2, "heli_troops": 6, "spawn_interval": 1.15, "reward": 350},
	# Рівень 14: передостанній рубіж, 3 вертольоти + 10 кулеметників
	{"infantry": 39, "shotgun": 15, "heavy": 10, "grenadier": 8, "snipers": 6, "heli": 3, "heli_troops": 5, "spawn_interval": 1.10, "reward": 400},
	# Рівень 15: фінальна битва, 12 кулеметників
	{"infantry": 42, "shotgun": 16, "heavy": 12, "grenadier": 9, "snipers": 6, "heli": 3, "heli_troops": 6, "spawn_interval": 1.05, "reward": 500},
]


static func get_current_level_data() -> Dictionary:
	var idx := clampi(current_level - 1, 0, LEVEL_DATA.size() - 1)
	return LEVEL_DATA[idx]


static func get_enemy_hp_multiplier(wave_index: int = 0) -> float:
	# На кожній новій хвилі/рівні додається +10% від БАЗОВОГО (початкового) ХП ворога
	var step := maxi(current_level - 1, 0) + maxi(wave_index, 0)
	return 1.0 + 0.10 * float(step)


static func get_player_max_health() -> float:
	return 100.0 + float(upg_hp_level) * 25.0


static func get_player_bullet_damage() -> float:
	return 10.0 + float(upg_damage_level) * 3.0


static func get_player_max_grenades() -> int:
	return 3 + upg_grenades_level


static func get_coin_multiplier() -> float:
	return 1.0 + float(upg_coins_level) * 0.20


static func get_upgrade_level(upg_key: String) -> int:
	match upg_key:
		"hp":
			return upg_hp_level
		"damage":
			return upg_damage_level
		"grenades":
			return upg_grenades_level
		"coins":
			return upg_coins_level
	return 0


static func get_upgrade_cost(upg_key: String) -> int:
	var lvl := get_upgrade_level(upg_key)
	if lvl >= MAX_UPGRADE_LEVEL:
		return 0
	# Кожен наступний апгрейд у 2 рази дорожчий за попередній: 50, 100, 200, 400, 800
	return BASE_UPGRADE_COST * (1 << lvl)


static func can_buy_upgrade(upg_key: String) -> bool:
	var lvl := get_upgrade_level(upg_key)
	if lvl >= MAX_UPGRADE_LEVEL:
		return false
	return coins >= get_upgrade_cost(upg_key)


static func buy_upgrade(upg_key: String) -> bool:
	if not can_buy_upgrade(upg_key):
		return false
	var cost := get_upgrade_cost(upg_key)
	coins -= cost
	match upg_key:
		"hp":
			upg_hp_level += 1
		"damage":
			upg_damage_level += 1
		"grenades":
			upg_grenades_level += 1
		"coins":
			upg_coins_level += 1
	return true


static func get_kill_reward(unit_type: String) -> int:
	var base_reward := 12
	match unit_type:
		"sniper":
			base_reward = 25
		"heavy":
			base_reward = 30
		"grenadier":
			base_reward = 28
		"shotgun":
			base_reward = 20
		_:
			base_reward = 12
	return int(roundf(float(base_reward) * get_coin_multiplier()))


static func reset_campaign() -> void:
	current_level = 1
	coins = 0
	last_level_earned = 0
	upg_hp_level = 0
	upg_damage_level = 0
	upg_grenades_level = 0
	upg_coins_level = 0
