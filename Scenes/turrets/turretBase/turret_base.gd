extends Node2D
class_name Turret

signal turretUpdated

func _ready():
	add_to_group("turrets")
	print("ADDED TO GROUP:", self)

var turret_type := "":
	set(value):
		turret_type = value
		$Sprite2D.texture = load(Data.turrets[value]["sprite"])
		$Sprite2D.scale = Vector2(Data.turrets[value]["scale"], Data.turrets[value]["scale"])
		rotates = Data.turrets[value]["rotates"]
		for stat in Data.turrets[value]["stats"].keys():
			set(stat, Data.turrets[value]["stats"][stat])

# Deploying
var deployed := false
var can_place := false
var draw_range := false

# Attacking
var rotates := true
var current_target = null

# Stats
var attack_speed := 1.0:
	set(value):
		attack_speed = value
		$AttackCooldown.wait_time = 1.0 / value

var attack_range := 1.0:
	set(value):
		attack_range = value
		$DetectionArea/CollisionShape2D.shape.radius = value

var damage := 1.0
var turret_level := 1

var turret_radius: float = 20.0

var is_highlighted: bool = false
var is_hovered: bool = false
var is_selected: bool = false


func _process(_delta):
	if not deployed:
		@warning_ignore("standalone_ternary")
		colliding() if $CollisionArea.has_overlapping_areas() else not_colliding()
	elif rotates:
		@warning_ignore("standalone_ternary")
		look_at(current_target.position) if is_instance_valid(current_target) else try_get_closest_target()
	
	queue_redraw()


func _draw():
	# Debug center
	draw_circle(Vector2.ZERO, 5, Color.RED)

	# Priority: selected > hovered/highlighted
	if is_selected:
		draw_circle(Vector2.ZERO, turret_radius + 10, Color(1, 0.5, 0, 0.6))
	elif is_hovered or is_highlighted:
		draw_circle(Vector2.ZERO, turret_radius + 6, Color(1, 1, 0, 0.3))


func set_placeholder():
	modulate = Color("6eff297a")


func build():
	deployed = true
	modulate = Color.WHITE


func colliding():
	can_place = false
	modulate = Color("ff5c2990")


func not_colliding():
	can_place = true
	modulate = Color("6eff297a")


func _on_detection_area_area_entered(area):
	if deployed and not current_target:
		var area_parent = area.get_parent()
		if area_parent.is_in_group("enemy"):
			current_target = area_parent


func _on_detection_area_area_exited(area):
	if deployed and current_target == area.get_parent():
		current_target = null
		try_get_closest_target()


func try_get_closest_target():
	if not deployed:
		return
	
	var closest = 1000
	var closest_area = null
	
	for area in $DetectionArea.get_overlapping_areas():
		var dist = area.position.distance_to(position)
		if dist < closest:
			closest = dist
			closest_area = area
	
	if closest_area:
		current_target = closest_area.get_parent()


func open_details_pane():
	var turretDetailsScene := preload("res://Scenes/ui/turretUI/turret_details.tscn")
	var details := turretDetailsScene.instantiate()
	details.turret = self
	
	draw_range = true
	queue_redraw()
	
	Globals.hud.add_child(details)
	Globals.hud.open_details_pane = details


var details_pane: Node = null


func close_details_pane():
	if is_instance_valid(Globals.hud.open_details_pane):
		Globals.hud.open_details_pane.queue_free()
		Globals.hud.open_details_pane = null

	draw_range = false
	queue_redraw()


func _on_collision_area_input_event(_viewport, _event, _shape_idx):
	if deployed and Input.is_action_just_pressed("LeftClick"):
		if is_instance_valid(Globals.hud.open_details_pane):
			if Globals.hud.open_details_pane.turret == self:
				close_details_pane()
				return
			
			Globals.hud.open_details_pane.turret.close_details_pane()
		
		open_details_pane()


func upgrade_turret():
	turret_level += 1
	
	for upgrade in Data.turrets[turret_type]["upgrades"].keys():
		if Data.turrets[turret_type]["upgrades"][upgrade]["multiplies"]:
			set(upgrade, get(upgrade) * Data.turrets[turret_type]["upgrades"][upgrade]["amount"])
		else:
			set(upgrade, get(upgrade) + Data.turrets[turret_type]["upgrades"][upgrade]["amount"])
	
	turretUpdated.emit()


func attack():
	if is_instance_valid(current_target):
		pass
	else:
		try_get_closest_target()


func get_radius() -> float:
	return turret_radius


func set_highlighted(state: bool):
	is_highlighted = state
	queue_redraw()


func set_selected(state: bool):
	is_selected = state
	print("SET SELECTED:", state)
	queue_redraw()


func set_hovered(state: bool):
	is_hovered = state
	queue_redraw()
