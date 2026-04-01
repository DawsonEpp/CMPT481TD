extends Node2D

var map_type := "":
	set(val):
		map_type = val
		baseHP = Data.maps[val]["baseHp"]
		baseMaxHp = Data.maps[val]["baseHp"]
		# Starting gold = base map gold + accumulated gold from waves 1-(BLOONS_START_WAVE)
		var base_gold = Data.maps[val]["startingGold"]
		var accumulated = _calculate_accumulated_gold(val)
		gold = base_gold + accumulated
		$PathSpawner.map_type = val

var gameOver := false
var baseMaxHp := 20.0
var baseHP := baseMaxHp
var gold := 100:
	set(value):
		gold = value
		Globals.goldChanged.emit(value)

func _ready():
	Globals.turretsNode = $Turrets
	Globals.projectilesNode = $Projectiles
	Globals.currentMap = self

## Calculates how much gold the player would have earned from completing
## waves 1 through BLOONS_START_WAVE using the map's own difficulty formula.
## Uses a conservative average gold yield per enemy across all possible types.
func _calculate_accumulated_gold(map_id: String) -> int:
	var settings = Data.maps[map_id]["spawner_settings"]
	var diff_settings = settings["difficulty"]
	var spawn_count: int = settings["wave_spawn_count"]
	var start_wave: int = EnemyPath.BLOONS_START_WAVE
	var total_gold := 0

	# Average gold yield across all 8 enemy types weighted roughly equally (~14)
	const AVG_GOLD_PER_ENEMY := 10

	for w in range(1, start_wave + 1):
		var diff: float
		if diff_settings["multiplies"]:
			diff = diff_settings["initial"] * pow(diff_settings["increase"], w)
		else:
			diff = diff_settings["initial"] + diff_settings["increase"] * w
		var enemy_count = round(spawn_count * diff)
		total_gold += int(enemy_count) * AVG_GOLD_PER_ENEMY
	return total_gold

func get_base_damage(damage):
	if gameOver:
		return
	baseHP -= damage
	Globals.baseHpChanged.emit(baseHP, baseMaxHp)
	if baseHP <= 0:
		gameOver = true
		_on_game_over()

func _on_game_over():
	var stats := {
		"won": false,
		"map": Globals.selected_map,
		"display_waves_completed": $PathSpawner.display_wave,
		"total_waves": EnemyPath.DISPLAY_TOTAL_WAVES,
		"gold_remaining": gold,
		"base_hp_remaining": 0,
		"bubble_cursor_enabled": Globals.bubble_cursor_enabled,
	}
	Globals.gameEnded.emit(false, stats)
	var gameOverPanelScene := preload("res://Scenes/ui/gameOver/game_over_panel.tscn")
	var gameOverPanel := gameOverPanelScene.instantiate()
	Globals.hud.add_child(gameOverPanel)
