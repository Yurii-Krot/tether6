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

# Таблиця 15 рівнів із поступовим зростанням складності та збільшеною кількістю снайперів
const LEVEL_DATA: Array[Dictionary] = [
	# Рівень 1: розминка, перші піхотинці та 1 снайпер
	{"infantry": 4, "shotgun": 0, "heavy": 0, "snipers": 1, "heli": 0, "heli_troops": 0, "spawn_interval": 3.2, "reward": 50},
	# Рівень 2: більше піхоти + дробовик + 2 снайпери
	{"infantry": 5, "shotgun": 1, "heavy": 0, "snipers": 2, "heli": 0, "heli_troops": 0, "spawn_interval": 3.0, "reward": 65},
	# Рівень 3: з'являється перший вертоліт з десантом + 2 снайпери
	{"infantry": 5, "shotgun": 2, "heavy": 0, "snipers": 2, "heli": 1, "heli_troops": 3, "spawn_interval": 2.9, "reward": 80},
	# Рівень 4: перший важкий кулеметник + 2 снайпери
	{"infantry": 6, "shotgun": 2, "heavy": 1, "snipers": 2, "heli": 0, "heli_troops": 0, "spawn_interval": 2.8, "reward": 95},
	# Рівень 5: вертоліт + кулеметник + 3 снайпери
	{"infantry": 6, "shotgun": 2, "heavy": 1, "snipers": 3, "heli": 1, "heli_troops": 3, "spawn_interval": 2.7, "reward": 110},
	# Рівень 6: інтенсивний штурм дробовиків та 3 снайпери
	{"infantry": 7, "shotgun": 3, "heavy": 1, "snipers": 3, "heli": 1, "heli_troops": 4, "spawn_interval": 2.6, "reward": 125},
	# Рівень 7: 2 кулеметники + 3 снайпери
	{"infantry": 8, "shotgun": 3, "heavy": 2, "snipers": 3, "heli": 1, "heli_troops": 4, "spawn_interval": 2.5, "reward": 140},
	# Рівень 8: 4 снайпери на позиціях + десант
	{"infantry": 8, "shotgun": 3, "heavy": 2, "snipers": 4, "heli": 1, "heli_troops": 4, "spawn_interval": 2.4, "reward": 160},
	# Рівень 9: подвійний вертолітний десант + 4 снайпери
	{"infantry": 9, "shotgun": 4, "heavy": 2, "snipers": 4, "heli": 2, "heli_troops": 4, "spawn_interval": 2.3, "reward": 180},
	# Рівень 10: 3 кулеметники + 4 снайпери
	{"infantry": 10, "shotgun": 4, "heavy": 3, "snipers": 4, "heli": 2, "heli_troops": 4, "spawn_interval": 2.2, "reward": 200},
	# Рівень 11: 5 снайперів + важка піхота
	{"infantry": 10, "shotgun": 4, "heavy": 3, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 2.1, "reward": 225},
	# Рівень 12: масований штурм + 5 снайперів
	{"infantry": 11, "shotgun": 5, "heavy": 3, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 2.0, "reward": 250},
	# Рівень 13: 4 кулеметники + 5 снайперів + 2 вертольоти
	{"infantry": 12, "shotgun": 5, "heavy": 4, "snipers": 5, "heli": 2, "heli_troops": 5, "spawn_interval": 1.95, "reward": 280},
	# Рівень 14: передостанній рубіж, 6 снайперів + 3 вертольоти
	{"infantry": 13, "shotgun": 6, "heavy": 4, "snipers": 6, "heli": 3, "heli_troops": 5, "spawn_interval": 1.85, "reward": 320},
	# Рівень 15: фінальна битва, 6 снайперів + 3 вертольоти з десантом
	{"infantry": 15, "shotgun": 6, "heavy": 5, "snipers": 6, "heli": 3, "heli_troops": 6, "spawn_interval": 1.75, "reward": 400},
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
