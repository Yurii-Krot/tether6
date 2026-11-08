class_name GameState
extends RefCounted

const TOTAL_LEVELS := 15

static var current_level: int = 1
static var coins: int = 0
static var last_level_earned: int = 0

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


static func get_kill_reward(unit_type: String) -> int:
	match unit_type:
		"sniper":
			return 25
		"heavy":
			return 30
		"shotgun":
			return 20
		_:
			return 12


static func reset_campaign() -> void:
	current_level = 1
	coins = 0
	last_level_earned = 0
