extends Node2D

func _ready():
	Globals.mainNode = self
	Globals.bubble_cursor = $UI/HUD/BubbleCursor
	var selectedMapScene := load(Data.maps[Globals.selected_map]["scene"])
	var map = selectedMapScene.instantiate()
	map.map_type = Globals.selected_map
	add_child(map)
