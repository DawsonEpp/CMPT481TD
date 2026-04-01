extends Node

const turrets := {
	"gatling": {
		"stats": {
			"damage": 10,
			"attack_speed": 2.0,
			"attack_range": 200.0,
			"bulletSpeed": 200.0,
			"bulletPierce": 1,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Gatling Gun",
		"cost": 50,
		"upgrade_cost": 50,
		"max_level": 2,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/technoturret.png",
		"scale": 4.0,
		"rotates": true,
		"bullet": "fire",
	},
	"laser": {
		"stats": {
			"damage": 0.5,
			"attack_speed": 20.0,
			"attack_range": 250.0,
			"bulletSpeed": 400.0,
			"bulletPierce": 4,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Flamethrower",
		"cost": 70,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/projectileTurret/projectileTurret.tscn",
		"sprite": "res://Assets/turrets/laserturret.png",
		"scale": 1.0,
		"rotates": false,
		"bullet": "laser",
	},
	"ray": {
		"stats": {
			"damage": 0.5,
			"attack_speed": 0.5,
			"attack_range": 300.0,
			"ray_duration": 1.0,
			"ray_length": 300.0,
		},
		"upgrades": {
			"damage": {"amount": 1.0, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
			"ray_length": {"amount": 1.5, "multiplies": true},
			"ray_duration": {"amount": 1.5, "multiplies": true},
		},
		"name": "Raygun",
		"cost": 30,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/rayTurret/rayTurret.tscn",
		"sprite": "res://Assets/turrets/reallaser.png",
		"scale": 1.0,
		"rotates": true,
	},
	"melee": {
		"stats": {
			"damage": 5.0,
			"attack_speed": 1.0,
			"attack_range": 100.0,
		},
		"upgrades": {
			"damage": {"amount": 2.5, "multiplies": false},
			"attack_speed": {"amount": 1.5, "multiplies": true},
		},
		"name": "Explosive",
		"cost": 70,
		"upgrade_cost": 50,
		"max_level": 3,
		"scene": "res://Scenes/turrets/meleeTurret/meleeTurret.tscn",
		"sprite": "res://Assets/turrets/dynamite.png",
		"scale": 1.0,
		"rotates": false,
	},
}

const stats := {
	"damage": {"name": "Damage"},
	"attack_speed": {"name": "Speed"},
	"attack_range": {"name": "Range"},
	"bulletSpeed": {"name": "Bullet Speed"},
	"bulletPierce": {"name": "Bullet Pierce"},
	"ray_length": {"name": "Ray Length"},
	"ray_duration": {"name": "Ray Duration"},
}

const bullets := {
	"fire": {
		"frames": "res://Assets/bullets/bullet1.tres",
	},
	"laser": {
		"frames": "res://Assets/bullets/bullet2.tres",
	}
}

const enemies := {
	# ── Tier 1 — basic units, unlock early ──────────────────────────────────
	"redDino": {
		"stats": {
			"hp": 15.0,
			"speed": 1.2,
			"baseDamage": 5.0,
			"goldYield": 8.0,
		},
		"difficulty": 1.0,
		"sprite": "res://Assets/enemies/dino1.png",
	},
	"blueDino": {
		"stats": {
			"hp": 8.0,
			"speed": 2.5,
			"baseDamage": 4.0,
			"goldYield": 6.0,
		},
		"difficulty": 2.0,
		"sprite": "res://Assets/enemies/dino2.png",
	},
	"yellowDino": {
		"stats": {
			"hp": 12.0,
			"speed": 4.0,
			"baseDamage": 3.0,
			"goldYield": 7.0,
		},
		"difficulty": 3.0,
		"sprite": "res://Assets/enemies/dino3.png",
	},
	"greenDino": {
		"stats": {
			"hp": 10.0,
			"speed": 6.0,
			"baseDamage": 2.0,
			"goldYield": 6.0,
		},
		"difficulty": 4.0,
		"sprite": "res://Assets/enemies/dino4.png",
	},
	# ── Tier 2 — armoured & elite variants, unlock mid-to-late waves ────────
	"armouredRed": {
		# Tank: very high HP, slow, punishing base damage
		"stats": {
			"hp": 60.0,
			"speed": 1.0,
			"baseDamage": 10.0,
			"goldYield": 20.0,
		},
		"difficulty": 6.0,
		"sprite": "res://Assets/enemies/dino1.png",
	},
	"armouredBlue": {
		# Tanky-fast: moderate HP but harder to catch than armouredRed
		"stats": {
			"hp": 35.0,
			"speed": 2.0,
			"baseDamage": 8.0,
			"goldYield": 15.0,
		},
		"difficulty": 9.0,
		"sprite": "res://Assets/enemies/dino2.png",
	},
	"eliteYellow": {
		# Elite speedster: lower HP than armoured but outruns most turret tracking
		"stats": {
			"hp": 25.0,
			"speed": 5.5,
			"baseDamage": 6.0,
			"goldYield": 12.0,
		},
		"difficulty": 13.0,
		"sprite": "res://Assets/enemies/dino3.png",
	},
	"bossGreen": {
		# Boss: massive HP, moderate speed, devastating base damage
		"stats": {
			"hp": 100.0,
			"speed": 1.5,
			"baseDamage": 15.0,
			"goldYield": 40.0,
		},
		"difficulty": 18.0,
		"sprite": "res://Assets/enemies/dino4.png",
	},
}

const maps := {
	"map1": {
		"name": "Grass Map",
		"bg": "res://Assets/maps/map1.webp",
		"scene": "res://Scenes/maps/map1.tscn",
		"baseHp": 10,
		"startingGold": 100,
		"spawner_settings": {
			# wave_spawn_count=1 so enemy count = round(1 * difficulty) = difficulty value.
			# Additive formula keeps numbers small: wave 30 → ~20 enemies, wave 40 → ~25.
			# Difficulty gates which enemy types can spawn, so late waves mix all 8 types.
			"difficulty": {"initial": 5.0, "increase": 0.5, "multiplies": false},
			"max_waves": 10,
			"wave_spawn_count": 1,
			"special_waves": {},
		},
	},
	"map2": {
		"name": "Desert Map",
		"bg": "res://Assets/maps/map2.png",
		"scene": "res://Scenes/maps/map2.tscn",
		"baseHp": 15,
		"startingGold": 200,
		"spawner_settings": {
			# Slightly easier than map1: wave 30 → ~16 enemies, wave 40 → ~20.
			"difficulty": {"initial": 4.0, "increase": 2, "multiplies": false},
			"max_waves": 10,
			"wave_spawn_count": 1,
			"special_waves": {},
		},
	},
} #4-2-1-3 4-3-3
