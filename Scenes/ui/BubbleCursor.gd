## BubbleCursor.gd
## Implements the Bubble Cursor HCI technique for improved selection efficiency.
##
## Each frame the bubble finds the nearest deployed Turret in world space and
## expands its radius to encompass it. On left-click the bubble selects that
## nearest turret — even if the physical mouse pointer is nowhere near it —
## opening the upgrade/sell detail pane. The existing CollisionArea input on
## each turret is suppressed so the two systems don't fight each other.

extends Node2D

# ──────────────────────────────────────────────────────────
# Inspector-tweakable properties
# ──────────────────────────────────────────────────────────

@export var smoothing_speed: float = 12.0
@export var min_radius:      float = 10.0
@export var max_radius:      float = 130.0
@export var idle_color:      Color = Color(0.55, 0.85, 1.0, 0.50)
@export var locked_color:    Color = Color(0.2,  1.0,  0.5, 0.70)
@export var stroke_width:    float = 2.0
@export var dot_radius:      float = 3.5
@export var tower_highlight: Color = Color(0.55, 1.0, 0.65, 1.0)

# ──────────────────────────────────────────────────────────
# Internal state
# ──────────────────────────────────────────────────────────

var _radius:       float  = 0.0
var _target:       Node2D = null   # nearest deployed turret this frame
var _prev_target:  Node2D = null   # previous frame — used for highlight transitions
var _is_dragging:  bool   = false

# Metrics
var _travel_px:    float = 0.0
var _last_mouse_vp: Vector2 = Vector2.ZERO
var _misclicks:    int   = 0
var _sel_start_t:  float = 0.0

# ──────────────────────────────────────────────────────────
# Lifecycle
# ──────────────────────────────────────────────────────────

func _ready() -> void:
	if not Globals.bubble_cursor_enabled:
		set_process(false)
		set_process_input(false)
		visible = false
		return
	Globals.bubble_cursor = self
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_last_mouse_vp = get_viewport().get_mouse_position()
	_radius = min_radius

func _process(delta: float) -> void:
	var vp_mouse: Vector2 = get_viewport().get_mouse_position()

	# Travel metric
	_travel_px += vp_mouse.distance_to(_last_mouse_vp)
	_last_mouse_vp = vp_mouse

	# World-space mouse for distance maths
	var world_mouse: Vector2 = _vp_to_world(vp_mouse)

	# Drag detection
	_is_dragging = false
	for node in get_tree().get_nodes_in_group("drag_textures"):
		if is_instance_valid(node) and node.get("placeholder") != null:
			_is_dragging = true
			break

	# ── Find nearest valid turret ──
	var nearest: Node2D  = null
	var nearest_dist: float = INF

	for t in get_tree().get_nodes_in_group("towers"):
		if not is_instance_valid(t) or not (t is Turret):
			continue
		var turret := t as Turret
		# During drag: target the undeployed placeholder only.
		# Otherwise:  target deployed turrets only.
		if _is_dragging:
			if turret.deployed:
				continue
		else:
			if not turret.deployed:
				continue

		var d: float = world_mouse.distance_to(turret.global_position)
		if d < nearest_dist:
			nearest_dist = d
			nearest = turret

	_target = nearest

	# ── Bubble radius ──
	var target_r: float = min_radius
	if is_instance_valid(_target):
		var scale_x: float = get_viewport().get_canvas_transform().get_scale().x
		target_r = clamp(nearest_dist * scale_x, min_radius, max_radius)

	_radius = lerp(_radius, target_r, delta * smoothing_speed)

	_apply_highlights()
	queue_redraw()

func _draw() -> void:
	var mp: Vector2 = get_local_mouse_position()
	var ring_col: Color = locked_color if is_instance_valid(_target) else idle_color

	var fill := ring_col
	fill.a = 0.07
	draw_circle(mp, _radius, fill)
	draw_arc(mp, _radius, 0.0, TAU, 64, ring_col, stroke_width, true)
	draw_circle(mp, dot_radius, Color(1, 1, 1, 0.92))

# ──────────────────────────────────────────────────────────
# Input — this is where bubble selection happens
# ──────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventMouseButton):
		return
	var mb := event as InputEventMouseButton
	if mb.button_index != MOUSE_BUTTON_LEFT:
		return

	if mb.pressed:
		_sel_start_t = Time.get_ticks_msec() / 1000.0
		return

	# ── Left-click released ──

	# Skip if a drag just finished (turret_drag_texture handles that).
	if _is_dragging:
		return

	# Skip if the click landed on a UI element (HUD, buttons, etc.).
	# We check this by seeing whether any Control consumed the event.
	if _click_is_over_ui():
		return

	if not is_instance_valid(_target):
		_misclicks += 1
		_log("[BubbleCursor] Misclick #%d | travel=%.0f px" % [_misclicks, _travel_px])
		return

	# ── Select the bubble's current target ──
	var turret := _target as Turret
	if turret == null or not turret.deployed:
		return

	var elapsed := (Time.get_ticks_msec() / 1000.0) - _sel_start_t
	_log("[BubbleCursor] Selected '%s' in %.3f s | travel=%.0f px | misclicks=%d" \
		% [turret.turret_type, elapsed, _travel_px, _misclicks])

	# Toggle or switch the detail pane, mirroring the original click logic.
	if is_instance_valid(Globals.hud.open_details_pane):
		var open_pane = Globals.hud.open_details_pane
		if open_pane.turret == turret:
			# Clicking the already-selected turret: close its pane.
			turret.close_details_pane()
			turret.modulate = Color.WHITE
			return
		else:
			# Different turret: close old pane, open new one.
			open_pane.turret.close_details_pane()

	turret.open_details_pane()
	# get_viewport().set_input_as_handled() tells Godot that this click is done,
	# preventing the CollisionArea on the same turret from firing again.
	get_viewport().set_input_as_handled()

# ──────────────────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────────────────

func _vp_to_world(vp_pos: Vector2) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * vp_pos

## Returns true if the mouse is currently over any visible Control node
## (HUD panels, buttons, labels, etc.) so we don't steal those clicks.
func _click_is_over_ui() -> bool:
	var vp := get_viewport()
	# get_focused_viewport is unnecessary; use gui_get_focus_owner to check
	# whether the GUI layer captured this event.
	# A simpler reliable method: test if any Control under the mouse is
	# mouse-interactive (filter != MOUSE_FILTER_IGNORE).
	var mouse_pos: Vector2 = vp.get_mouse_position()
	for ctrl in get_tree().get_nodes_in_group("ui_interactive"):
		if ctrl is Control and ctrl.visible:
			var rect = ctrl.get_global_rect()
			if rect.has_point(mouse_pos):
				return true
	# Fallback: check the TurretsPanel directly (it is always present).
	var panels := get_tree().get_nodes_in_group("hud_panels")
	for p in panels:
		if p is Control and p.visible:
			if p.get_global_rect().has_point(mouse_pos):
				return true
	return false

func _apply_highlights() -> void:
	if is_instance_valid(_prev_target) and _prev_target != _target:
		var prev := _prev_target as Turret
		if prev != null and prev.deployed:
			_prev_target.modulate = Color.WHITE

	if is_instance_valid(_target) and _target != _prev_target:
		var cur := _target as Turret
		if cur != null and cur.deployed:
			_target.modulate = tower_highlight

	_prev_target = _target

func _log(msg: String) -> void:
	print(msg)

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func get_metrics() -> Dictionary:
	return {"travel_px": _travel_px, "misclicks": _misclicks}
