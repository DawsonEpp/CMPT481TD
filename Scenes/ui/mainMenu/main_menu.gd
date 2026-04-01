extends Control

var mapSelectContainer : PanelContainer

func _ready():
	# Reflect the current state of the toggle on load
	%BubbleCursorCheck.button_pressed = Globals.bubble_cursor_enabled

func _on_quit_button_pressed():
	get_tree().quit()

func _on_start_button_pressed():
	if not mapSelectContainer:
		var mscScene = preload("res://Scenes/ui/mainMenu/select_map_container.tscn")
		var msc= mscScene.instantiate()
		mapSelectContainer = msc
		add_child(msc)

func _on_bubble_cursor_check_toggled(toggled_on: bool):
	Globals.bubble_cursor_enabled = toggled_on
