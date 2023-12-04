@tool
@icon("res://addons/camera_action/icon/CameraActionFollow.svg")

extends CameraActionSimple
## Camera will follow its parent node, much like normal behavior, but with added
## control over animation due to inheriting CameraActionSimple
class_name CameraActionFollow

#region Variables & Exports

## Should this camera action have some outer bounds on how far the camera is able to travel?
@export var apply_limits: bool = false
@export_range(0, 1, 1, "or_greater", "hide_slider", "suffix:px") var limit_left: float = 1000
@export_range(0, 1, 1, "or_greater", "hide_slider", "suffix:px") var limit_top: float = 600
@export_range(0, 1, 1, "or_greater", "hide_slider", "suffix:px") var limit_right: float = 1000
@export_range(0, 1, 1, "or_greater", "hide_slider", "suffix:px") var limit_bottom: float = 600

#endregion

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	# Tween the position of the camera to zero (ensures it ends up centered again)
	_add_property_to_tween_reference_list("position", "zero_vec", self, cam.position)
	
	# Enable the limits if enabled
	if apply_limits:
		cam.limit_left = global_position.x - limit_left
		cam.limit_top = global_position.y - limit_top
		cam.limit_right = global_position.x + limit_right
		cam.limit_bottom = global_position.y + limit_bottom

# Draw camera bounds and limits
func _draw():
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, _get_debug_color().darkened(0.2))
	
	if apply_limits and _is_limit_drawing_available():
		var limit_points: Array[Vector2] = [
			Vector2(-limit_left, -limit_top),
			Vector2(limit_right, -limit_top),
			Vector2(limit_right, limit_bottom),
			Vector2(-limit_left, limit_bottom)
		]
		
		_draw_rect_from_points(limit_points, _get_debug_color(), 5)

# Cannot have configuration warnings
func _get_configuration_warnings():
	return []

func _get_debug_color() -> Color:
	return Color.ORANGE
