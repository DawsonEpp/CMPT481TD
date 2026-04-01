extends Control

var next_wait_time := 0
var waited := 0
var open_details_pane : PanelContainer

func _ready():
	Globals.hud = self
	Globals.baseHpChanged.connect(update_hp)
	Globals.goldChanged.connect(update_gold)
	Globals.waveStarted.connect(show_wave_count)
	Globals.waveCleared.connect(show_wave_timer)
	Globals.enemyDestroyed.connect(update_enemy_count)
	%WaveLabel.text = "Press Start Waves to begin"
	%StartWavesButton.visible = true

func _on_start_waves_button_pressed():
	%StartWavesButton.visible = false
	if is_instance_valid(Globals.currentMap):
		Globals.currentMap.get_node("PathSpawner").start_waves()

func update_hp(newHp, maxHp):
	%HPLabel.text = "HP: "+str(round(newHp))+"/"+str(round(maxHp))

func update_gold(newGold):
	%GoldLabel.text = "Gold: "+str(round(newGold))

func show_wave_count(display_wave, enemies):
	$WaveWaitTimer.stop()
	waited = 0
	%WaveLabel.text = "Wave: %d/%d" % [display_wave, EnemyPath.DISPLAY_TOTAL_WAVES]
	%RemainLabel.text = "Enemies: "+str(enemies)
	%RemainLabel.visible = true

func show_wave_timer(wait_time):
	%RemainLabel.visible = false
	next_wait_time = wait_time - 1
	$WaveWaitTimer.start()

func _on_wave_wait_timer_timeout():
	%WaveLabel.text = "Next wave in "+str(next_wait_time - waited)
	waited += 1

func update_enemy_count(remain):
	%RemainLabel.text = "Enemies: "+str(remain)

func reset():
	if is_instance_valid(open_details_pane):
		open_details_pane.turret.close_details_pane()
	%StartWavesButton.visible = true
	%WaveLabel.text = "Press Start Waves to begin"
