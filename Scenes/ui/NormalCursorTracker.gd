## NormalCursorTracker.gd
## Tracks click accuracy when the Bubble Cursor is disabled.
##
## Every left-click on the game world is inspected:
##   - The nearest deployed turret is found (same search BubbleCursor uses).
##   - If the click landed inside that turret's CollisionArea it is a HIT,
##     otherwise a MISS (misclick).
##   - The pixel distance from click to the nearest tower is always recorded.
##
## Exposes get_metrics() with the same shape as BubbleCursor.get_metrics()
## so StatsExporter can treat both modes identically.

extends Node2D

# ── Internal state ──────────────────────────────────────────

var _travel_px:       float = 0.0
var _last_mouse_vp:   Vector2 = Vector2.ZERO

var _misclicks:       int   = 0
var _hits:            int   = 0

# Per-click distance list for average / worst-case reporting
var _click_distances: Array[float] = []

var _sel_start_t:     float = 0.0
var _is_dragging:     bool  = false

# ── Lifecycle ───────────────────────────────────────────────

func _ready() -> void:
	# Disabled by default; main.gd enables this only when bubble cursor is off.
	set_process(false)
	set_process_unhandled_input(false)
	_last_mouse_vp = get_viewport().get_mouse_position()

func _process(_delta: float) -> void:
	var vp_mouse: Vector2 = get_viewport().get_mouse_position()
	_travel_px += vp_mouse.distance_to(_last_mouse_vp)
	_last_mouse_vp = vp_mouse

	# Mirror BubbleCursor drag detection
	_is_dragging = false
	for node in get_tree().get_nodes_in_group("drag_textures"):
		if is_instance_valid(node) and node.get("placeholder") != null:
			_is_dragging = true
			break

# ── Input ───────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_sel_start_t = Time.get_ticks_msec() / 1000.0
		return

	# Release — evaluate the click
	if _is_dragging:
		return

	# Ignore clicks on HUD / UI panels
	if _click_is_over_ui():
		return

	var vp_mouse: Vector2 = get_viewport().get_mouse_position()
	var world_click: Vector2 = _vp_to_world(vp_mouse)

	# Find nearest deployed turret and its screen-space distance to the click
	var nearest_turret: Turret = null
	var nearest_world_dist: float = INF

	for t in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(t) or not (t is Turret):
			continue
		var turret := t as Turret
		if not turret.deployed:
			continue
		var d: float = world_click.distance_to(turret.global_position)
		if d < nearest_world_dist:
			nearest_world_dist = d
			nearest_turret = turret

	# Convert world-space distance to viewport-pixel distance for comparability
	# with BubbleCursor's pixel-space travel metric.
	var scale_x: float = get_viewport().get_canvas_transform().get_scale().x
	var nearest_px: float = nearest_world_dist * scale_x if nearest_turret != null else INF

	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - _sel_start_t

	if nearest_turret == null:
		# No towers placed yet — nothing to measure against
		_log("[NormalCursor] Click with no towers present | travel=%.0f px" % _travel_px)
		return

	_click_distances.append(nearest_px)

	# Determine hit vs miss: check whether the click's world position is inside
	# the nearest turret's CollisionArea shape (a circle = attack_range? No —
	# use the CollisionArea's actual shape radius for click detection).
	var hit := _click_hits_turret(world_click, nearest_turret)

	if hit:
		_hits += 1
		_log("[NormalCursor] HIT '%s' in %.3f s | dist=%.1f px | travel=%.0f px | misclicks=%d" \
			% [nearest_turret.turret_type, elapsed, nearest_px, _travel_px, _misclicks])
	else:
		_misclicks += 1
		_log("[NormalCursor] MISS — nearest '%s' dist=%.1f px | travel=%.0f px | misclicks=%d" \
			% [nearest_turret.turret_type, nearest_px, _travel_px, _misclicks])

# ── Helpers ─────────────────────────────────────────────────

## Returns true if world_click falls inside the turret's CollisionArea circle.
func _click_hits_turret(world_click: Vector2, turret: Turret) -> bool:
	var collision_shape = turret.get_node_or_null("CollisionArea/CollisionShape2D")
	if collision_shape == null:
		return false
	var shape = collision_shape.shape
	if shape == null:
		return false
	# The CollisionArea uses a CircleShape2D
	var radius: float = shape.radius if shape is CircleShape2D else 32.0
	return world_click.distance_to(turret.global_position) <= radius

func _vp_to_world(vp_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * vp_pos

func _click_is_over_ui() -> bool:
	var mouse_pos: Vector2 = get_viewport().get_mouse_position()
	for ctrl in get_tree().get_nodes_in_group("ui_interactive"):
		if ctrl is Control and ctrl.visible:
			if ctrl.get_global_rect().has_point(mouse_pos):
				return true
	for p in get_tree().get_nodes_in_group("hud_panels"):
		if p is Control and p.visible:
			if p.get_global_rect().has_point(mouse_pos):
				return true
	return false

func _log(msg: String) -> void:
	print(msg)

## Returns metrics in the same shape as BubbleCursor.get_metrics(),
## plus normal-cursor-specific fields.
func get_metrics() -> Dictionary:
	var avg_dist: float = 0.0
	var max_dist: float = 0.0
	if _click_distances.size() > 0:
		for d in _click_distances:
			avg_dist += d
			if d > max_dist:
				max_dist = d
		avg_dist /= _click_distances.size()
	return {
		"travel_px":            _travel_px,
		"misclicks":            _misclicks,
		"hits":                 _hits,
		"total_clicks":         _hits + _misclicks,
		"avg_dist_to_nearest_px": avg_dist,
		"max_dist_to_nearest_px": max_dist,
	}
