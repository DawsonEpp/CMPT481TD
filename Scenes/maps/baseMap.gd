extends Node2D

var map_type := "":
	set(val):
		map_type = val
		baseHP = Data.maps[val]["baseHp"]
		baseMaxHp = Data.maps[val]["baseHp"]
		gold = Data.maps[val]["startingGold"]
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
## waves 1 through BLOONS_START_WAVE (i.e., rounds 1-29 equivalent).
func _calculate_accumulated_gold(map_id: String) -> int:
	var settings = Data.maps[map_id]["spawner_settings"]
	var diff_settings = settings["difficulty"]
	var spawn_count: int = settings["wave_spawn_count"]
	var start_wave: int = EnemyPath.BLOONS_START_WAVE
	var total_gold = 0
	for w in range(1, start_wave + 1):
		var diff: float
		if diff_settings["multiplies"]:
			diff = diff_settings["initial"] * pow(diff_settings["increase"], w)
		else:
			diff = diff_settings["initial"] + diff_settings["increase"] * w
		var enemy_count = round(spawn_count * diff)
		# Each enemy yields an average goldYield — use redDino baseline of 10
		total_gold += int(enemy_count) * 10
	return total_gold


func get_base_damage(damage):
	if gameOver:
		return
	baseHP -= damage
	Globals.baseHpChanged.emit(baseHP, baseMaxHp)
	if baseHP <= 0:
		gameOver = true
		var gameOverPanelScene := preload("res://Scenes/ui/gameOver/game_over_panel.tscn")
		var gameOverPanel := gameOverPanelScene.instantiate()
		Globals.hud.add_child(gameOverPanel)
