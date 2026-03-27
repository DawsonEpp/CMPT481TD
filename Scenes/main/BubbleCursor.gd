extends Node2D

@export var min_radius: float = 10.0
@export var max_radius: float = 150.0
@export var smoothing: float = 15.0

var current_radius: float = 10.0
var target_radius: float = 10.0

var hover_target: Node2D = null
var selected_target: Node2D = null


func _process(delta):
	global_position = get_global_mouse_position()
	
	update_bubble()
	queue_redraw()
	
	current_radius = lerp(current_radius, target_radius, smoothing * delta)


func update_bubble():
	var mouse_pos = get_global_mouse_position()
	var turrets = get_tree().get_nodes_in_group("turrets")

	var closest = INF
	var closest_turret = null

	for turret in turrets:
		if not turret is Node2D:
			continue

		var dist = mouse_pos.distance_to(turret.global_position)

		if dist < closest:
			closest = dist
			closest_turret = turret

	# Always track the closest turret (no threshold)
	var new_hover = closest_turret

	# Handle hover change
	if hover_target and hover_target != new_hover:
		if hover_target.has_method("set_hovered"):
			hover_target.set_hovered(false)

	hover_target = new_hover

	if hover_target and hover_target.has_method("set_hovered"):
		hover_target.set_hovered(true)

	# Bubble radius = distance to closest target
	if closest == INF:
		target_radius = min_radius
	else:
		target_radius = clamp(closest, min_radius, max_radius)


func _input(event):
	if event is InputEventMouseButton and event.pressed:

		# Bubble cursor selection:
		# Just select whatever is currently captured
		if hover_target != null:
			print("CLICKED TURRET (bubble)")
			set_selected_target(hover_target)
		else:
			print("CLICKED EMPTY")
			clear_selection()


func set_selected_target(turret):
	# Clear old selection
	if selected_target and selected_target.has_method("set_selected"):
		selected_target.set_selected(false)

	# Close old UI if needed
	if selected_target and selected_target.has_method("close_details_pane"):
		selected_target.close_details_pane()

	selected_target = turret

	if selected_target and selected_target.has_method("set_selected"):
		selected_target.set_selected(true)

	if selected_target and selected_target.has_method("open_details_pane"):
		selected_target.open_details_pane()

func clear_selection():
	if selected_target and selected_target.has_method("set_selected"):
		selected_target.set_selected(false)

	selected_target = null


func _draw():
	draw_circle(Vector2.ZERO, current_radius, Color(0.2, 0.6, 1.0, 0.25))
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, Color(0.2, 0.6, 1.0), 2.0)
