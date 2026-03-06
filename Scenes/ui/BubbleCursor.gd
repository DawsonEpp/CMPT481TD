extends Node2D

@export var radius: float = 60.0
@export var color: Color = Color(0.4, 0.9, 1.0, 0.35)
@export var border_color: Color = Color(0.4, 0.9, 1.0, 0.85)
@export var border_width: float = 2.5
@export var max_radius: float = 120.0

var target_radius = 60.0
var hovered_turret = null

func _process(_delta):
	# Follow mouse in world space
	#var cam = get_viewport().get_camera_2d()
	#if cam:
		#global_position = get_viewport().get_mouse_position() + cam.get_screen_center_position() - get_viewport_rect().size / 2
	#else:
	global_position = get_global_mouse_position()
	
	queue_redraw()
	_check_turrets()

func _draw():
	# Filled circle
	draw_circle(Vector2.ZERO, radius, color)
	# Border ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 64, border_color, border_width, true)

func _check_turrets():
	var previous = hovered_turret
	hovered_turret = null

	var closest_dist = INF

	for turret in get_tree().get_nodes_in_group("turrets"):
		if not is_instance_valid(turret):
			continue

		var dist = global_position.distance_to(turret.global_position)

		if dist < closest_dist:
			closest_dist = dist
			hovered_turret = turret

	# Bubble radius grows to nearest object
	if hovered_turret != null:
		radius = clamp(closest_dist, 10.0, max_radius)
	else:
		radius = 10.0
	radius = lerp(radius, target_radius, 0.25)

	# Fire signals on change
	if hovered_turret != previous:
		if previous != null:
			_on_turret_exit(previous)

		if hovered_turret != null:
			_on_turret_enter(hovered_turret)

func _on_turret_enter(turret):
	# Hook into your existing selection / details pane logic
	if turret.has_method("open_details_pane"):
		turret.open_details_pane()

func _on_turret_exit(turret):                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    
	if turret.has_method("close_details_pane"):
		turret.close_details_pane()

#func register_turret(turret):
	#get_parent().get_parent().get_parent().get_child(2).add_child(turret)
