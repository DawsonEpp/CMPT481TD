extends Node
@warning_ignore("unused_signal")
signal goldChanged(newGold)
@warning_ignore("unused_signal")
signal baseHpChanged(newHp, maxHp)
@warning_ignore("unused_signal")
signal waveStarted(wave_count, enemy_count)
@warning_ignore("unused_signal")
signal waveCleared(wait_time)
@warning_ignore("unused_signal")
signal enemyDestroyed(remain)
@warning_ignore("unused_signal")
signal gameEnded(won: bool, stats: Dictionary)


var selected_map := ""
var mainNode : Node2D
var turretsNode : Node2D
var projectilesNode : Node2D
var currentMap : Node2D
var hud : Control
var bubble_cursor: Node2D
var bubble_cursor_enabled: bool = true

func restart_current_level():
	var currentLevelScene := load(currentMap.scene_file_path)
	currentMap.queue_free()
	var newMap = currentLevelScene.instantiate()
	newMap.map_type = selected_map
	mainNode.add_child(newMap)
	hud.reset()
