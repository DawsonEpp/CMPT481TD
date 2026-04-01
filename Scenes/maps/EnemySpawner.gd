extends Path2D
class_name EnemyPath

# ── Constants ──────────────────────────────────────────────
const BLOONS_START_WAVE := 29  # current_wave before first increment → becomes wave 30
const DISPLAY_TOTAL_WAVES := 10

var map_type := "":
	set(val):
		map_type = val
		for config in Data.maps[val]["spawner_settings"].keys():
			set(config, Data.maps[val]["spawner_settings"][config])

var difficulty := {}
var spawnable_enemies := []
var max_waves := 3
var special_waves := {}
var wave_spawn_count := 10

var current_wave_spawn_count := 0
var current_difficulty := 1.0
var current_wave := BLOONS_START_WAVE   # start as if 29 waves already passed
var display_wave := 0                   # 1-based counter shown to player (1/10 … 10/10)
var enemies_spawned_this_wave := 0
var killed_this_wave := 0

# Paused until player presses Start Waves
var waiting_for_start := true

func spawn_new_enemy():
	var enemyScene := preload("res://Scenes/enemies/enemy_mover.tscn")
	var enemy = enemyScene.instantiate()
	enemy.enemy_type = spawnable_enemies.pick_random()
	add_child(enemy)
	enemies_spawned_this_wave += 1

func get_spawnable_enemies():
	var enemies := []
	for enemy in Data.enemies.keys():
		if current_difficulty >= Data.enemies[enemy]["difficulty"]:
			enemies.append(enemy)
	return enemies

func get_current_difficulty() -> float:
	var default_diff = difficulty["initial"]
	var increase = difficulty["increase"]
	var calculated_diff = default_diff * pow(increase, current_wave) if difficulty["multiplies"] \
		else default_diff + increase * current_wave
	return calculated_diff

# Called by HUD's "Start Waves" button
func start_waves():
	waiting_for_start = false
	_advance_to_next_wave()

func _advance_to_next_wave():
	current_wave += 1
	display_wave += 1
	killed_this_wave = 0
	enemies_spawned_this_wave = 0
	current_difficulty = get_current_difficulty()
	current_wave_spawn_count = round(wave_spawn_count * current_difficulty)
	spawnable_enemies = get_spawnable_enemies()
	Globals.waveStarted.emit(display_wave, current_wave_spawn_count)
	$SpawnDelay.start()

func _on_spawn_delay_timeout():
	if enemies_spawned_this_wave < current_wave_spawn_count:
		spawn_new_enemy()
		$SpawnDelay.start()

func _on_wave_delay_timer_timeout():
	_advance_to_next_wave()

func enemy_destroyed():
	killed_this_wave += 1
	Globals.enemyDestroyed.emit(current_wave_spawn_count - killed_this_wave)
	check_wave_clear()

func check_wave_clear():
	if killed_this_wave == current_wave_spawn_count:
		if display_wave < DISPLAY_TOTAL_WAVES:
			# More waves to go
			Globals.waveCleared.emit($WaveDelayTimer.wait_time)
			$WaveDelayTimer.start()
			return
		# All 10 waves survived → Victory!
		_trigger_victory()

func _trigger_victory():
	var stats := _build_stats(true)
	Globals.gameEnded.emit(true, stats)
	var wonScene := preload("res://Scenes/ui/mapCompleted/mapCompleted.tscn")
	var wonPanel := wonScene.instantiate()
	Globals.hud.add_child(wonPanel)

func _build_stats(won: bool) -> Dictionary:
	return {
		"won": won,
		"map": Globals.selected_map,
		"display_waves_completed": display_wave,
		"total_waves": DISPLAY_TOTAL_WAVES,
		"gold_remaining": Globals.currentMap.gold if is_instance_valid(Globals.currentMap) else 0,
		"base_hp_remaining": Globals.currentMap.baseHP if is_instance_valid(Globals.currentMap) else 0,
		"bubble_cursor_enabled": Globals.bubble_cursor_enabled,
	}
