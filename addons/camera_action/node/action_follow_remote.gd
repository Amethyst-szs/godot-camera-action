@tool
@icon("res://addons/camera_action/icon/CameraActionFollowRemote.svg")

extends CameraActionFollow
## Identical to CameraActionFollow, except instead of following the camera's parent, you can
## follow any Node2D in the scene
class_name CameraActionFollowRemote

## What node should the camera track, ignoring its own parent in the process
@export var remote_node: Node2D:
	set(value):
		remote_node = value
		update_configuration_warnings()
	get:
		return remote_node

func _ready():
	if not remote_node:
		push_error("CameraActionFollowRemote doesn't have remote node set!\n%s" % [get_path()])
		return
	
	super()

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

# Display warning if remote node is not set
func _get_configuration_warnings():
	if not remote_node:
		return ["Must set the remote node in inspector"]
	
	return []

func _get_debug_color() -> Color:
	return Color.YELLOW_GREEN
