@tool
@icon("res://addons/camera_action/icon/CameraActionFollowRemote.svg")

extends CameraActionFollow
class_name CameraActionFollowRemote

## What node should the camera track, ignoring its own parent in the process
@export var remote_node: Node2D:
	set(value):
		remote_node = value
		update_configuration_warnings()
	get:
		return remote_node

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	# Remove position reference from parent super function, and add global position of remote
	_remove_tween_reference("position")
	_add_property_to_tween_reference_list("global_position", "global_position", remote_node, cam.global_position)

func update():
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	# While camera is active, update global position to this node
	cam.global_position = remote_node.global_position

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

# Display warning if remote node is not set
func _get_configuration_warnings():
	if not remote_node:
		return ["Must set the remote node in inspector"]
	
	return []
