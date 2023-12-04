@tool
@icon("res://addons/camera_action/icon/CameraActionLineRemote.svg")

extends CameraActionLine
## Identical to CameraActionLine, except instead of following the camera's parent, you can
## follow any Node2D in the scene
class_name CameraActionLineRemote

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

func _get_base_target_pos(cam: Camera2D):
	return remote_node.global_position

# Display warning if remote node is not set
func _get_configuration_warnings():
	if not remote_node:
		return ["Must set the remote node in inspector"]
	
	return []

func _get_debug_color() -> Color:
	return Color.MEDIUM_PURPLE.lightened(0.2)
