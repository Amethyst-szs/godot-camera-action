@tool
@icon("res://example/player/player.png")

extends CameraActionFollow
class_name CameraActionFollowFocus

@export var focus_node: Node2D:
	set(value):
		focus_node = value
		update_configuration_warnings()
	get:
		return focus_node

@export_range(0.0, 1.0, 0.05) var midpoint: float = 0.5

var target_pos: Vector2 = Vector2.ZERO
var initial_zoom: float = 0.0

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	_calc_target(cam)
	
	_remove_tween_reference("position")
	_add_property_to_tween_reference_list("global_position", "target_pos", self, cam.global_position)

func update_transition(delta: float):
	super(delta)
	
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	_calc_target(cam)

func update():
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	_calc_target(cam)
	cam.global_position = target_pos

func pause():
	super()

func _calc_target(cam: Camera2D):
	var cam_parent: Node2D = cam.get_parent()
	if not cam_parent: return
	
	# Calculate target position using cam parent and focus node
	var dist := cam_parent.global_position.distance_to(focus_node.global_position)
	target_pos = cam_parent.global_position.move_toward(focus_node.global_position, dist * midpoint)

func _draw():
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, Color.YELLOW.darkened(0.2))
	
	if apply_limits and _is_limit_drawing_available():
		var limit_points: Array[Vector2] = [
			Vector2(-limit_left, -limit_top),
			Vector2(limit_right, -limit_top),
			Vector2(limit_right, limit_bottom),
			Vector2(-limit_left, limit_bottom)
		]
		
		_draw_rect_from_points(limit_points, Color.YELLOW, 5)

func _get_configuration_warnings():
	if not focus_node:
		return ["Must set the focus node in inspector"]
	
	return []
