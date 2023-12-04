@tool
@icon("res://addons/camera_action/icon/CameraActionLineRemote.svg")

extends CameraActionLine
class_name CameraActionLineRemote

@export var remote_node: Node2D:
	set(value):
		remote_node = value
		update_configuration_warnings()
	get:
		return remote_node

func _ready():
	super()
	if not remote_node:
		push_error("CameraActionFollowRemote doesn't have remote node set!")

func _get_base_target_pos(cam: Camera2D):
	return remote_node.global_position

# Display warning if remote node is not set
func _get_configuration_warnings():
	if not remote_node:
		return ["Must set the remote node in inspector"]
	
	return []
