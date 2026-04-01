extends Node2D

func _ready():
	Globals.mainNode = self
	var selectedMapScene := load(Data.maps[Globals.selected_map]["scene"])
	var map = selectedMapScene.instantiate()
	map.map_type = Globals.selected_map
	add_child(map)

	# Honour bubble cursor setting chosen on main menu when implemented
	var bc = $UI/BubbleCursor
	if Globals.bubble_cursor_enabled:
		bc.visible = true
		Globals.bubble_cursor = bc
	else:
		bc.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
