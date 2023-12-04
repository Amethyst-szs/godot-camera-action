@tool
@icon("res://addons/camera_action/icon/CameraActionFixed.svg")

extends CameraActionSimple
## A simple fixed camera position
class_name CameraActionFixed

#region Virtual Functions

# Add global position to tween list
func start():
	super()
	var cam: Camera2D = CameraActionManager.get_camera()
	if not tween or not cam: return
	
	_add_property_to_tween_reference_list("global_position", "global_position", self, cam.global_position)

# Every _physics_process, update global position
func update(delta: float, cam: Camera2D):
	# While camera is active, update global position to this node
	cam.global_position = global_position
	
	super(delta, cam)

# Draw camera bounding box with zoom and rotation
func _draw():
	# Draw camera box if enabled
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, _get_debug_color())

# Cannot have config error
func _get_configuration_warnings():
	return []

func _get_debug_color() -> Color:
	return Color.MEDIUM_AQUAMARINE

#endregion
