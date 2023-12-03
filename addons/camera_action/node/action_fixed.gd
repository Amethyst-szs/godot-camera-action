@tool
@icon("res://example/player/player.png")

extends CameraActionSimple
class_name CameraActionFixed

#region Virtual Functions

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	_add_property_to_tween_reference_list("global_position", "global_position", self, cam.global_position)

func update():
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	# While camera is active, update global position to this node
	cam.global_position = global_position

func _draw():
	# Draw camera box if enabled
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, Color.MEDIUM_AQUAMARINE)

func _get_configuration_warnings():
	return []

#endregion
