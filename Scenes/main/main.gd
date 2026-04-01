extends Node2D

func _ready():
	Globals.mainNode = self
	var selectedMapScene := load(Data.maps[Globals.selected_map]["scene"])
	var map = selectedMapScene.instantiate()
	map.map_type = Globals.selected_map
	add_child(map)

	var bc  = $UI/BubbleCursor
	var nct = $UI/NormalCursorTracker

	if Globals.bubble_cursor_enabled:
		# Activate bubble cursor; disable normal tracker
		bc.visible = true
		Globals.bubble_cursor = bc
		nct.set_process(false)
		nct.set_process_unhandled_input(false)
	else:
		# Activate normal cursor tracker; disable bubble cursor
		bc.visible = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		nct.set_process(true)
		nct.set_process_unhandled_input(true)
		Globals.normal_cursor_tracker = nct
