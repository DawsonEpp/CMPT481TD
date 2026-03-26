extends Node2D

@export var min_radius: float = 10.0
@export var max_radius: float = 120.0
@export var radius_scale: float = 1.0
@export var smoothing: float = 10.0

var current_radius: float = 10.0
var target_radius: float = 10.0
var current_target: Turret = null

func _process(delta):
	global_position = get_global_mouse_position()
	
	update_bubble()
	queue_redraw()
	
	current_radius = lerp(current_radius, target_radius, smoothing * delta)


func update_bubble():
	var mouse_pos = get_global_mouse_position()
	var turrets = get_tree().get_nodes_in_group("turrets")

	var closest = INF
	var closest_turret: Turret = null

	for turret in turrets:
		if not turret is Turret:
			continue

		var dist = mouse_pos.distance_to(turret.global_position)
		dist -= turret.get_radius()

		if dist < closest:
			closest = dist
			closest_turret = turret

	# 🔥 Handle highlighting
	if current_target and current_target != closest_turret:
		current_target.set_highlighted(false)

	current_target = closest_turret

	if current_target:
		current_target.set_highlighted(true)

	# 🔥 Dynamic sizing
	if closest == INF:
		target_radius = min_radius
	elif closest > max_radius:
		target_radius = min_radius
	else:
		target_radius = clamp(closest * radius_scale, min_radius, max_radius)


func _draw():
	draw_circle(Vector2.ZERO, current_radius, Color(0.2, 0.6, 1.0, 0.25))
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 64, Color(0.2, 0.6, 1.0), 2.0)
