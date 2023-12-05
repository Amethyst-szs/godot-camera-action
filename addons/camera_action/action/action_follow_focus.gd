@tool
@icon("res://addons/camera_action/icon/CameraActionFollowFocus.svg")

extends CameraActionFollow
## Target a mid-point between the camera's parent node and another node,
## attempting to frame both in the shot
class_name CameraActionFollowFocus

## What node should should be the endpoint
@export var focus_node: Node2D:
	set(value):
		focus_node = value
		update_configuration_warnings()
	get:
		return focus_node

## What point between the camera's parent and the focus node should be targetted (Range 0-1)
@export_range(0.0, 1.0, 0.05) var midpoint: float = 0.5

var target_pos: Vector2 = Vector2.ZERO
var initial_zoom: float = 0.0

func _ready():
	if not focus_node:
		push_error("CameraActionFollowFocus doesn't have focus node set!\n%s" % [get_path()])
		return
	
	super()

func start():
	super()
	var cam: Camera2D = CameraActionManager.get_camera()
	if not tween or not cam: return
	
	_calc_target(cam)
	
	_remove_tween_reference("position")
	_add_property_to_tween_reference_list("global_position", "target_pos", self, cam.global_position)

func update_transition(delta: float, cam: Camera2D):
	_calc_target(cam)
	
	super(delta, cam)

func update(delta: float, cam: Camera2D):
	_calc_target(cam)
	cam.global_position = target_pos
	
	super(delta, cam)

func _calc_target(cam: Camera2D):
	var cam_parent: Node2D = cam.get_parent()
	if not cam_parent: return
	
	# Calculate target position using cam parent and focus node
	var dist := cam_parent.global_position.distance_to(focus_node.global_position)
	target_pos = cam_parent.global_position.move_toward(focus_node.global_position, dist * midpoint)

func _get_configuration_warnings():
	if not focus_node:
		return ["Must set the focus node in inspector"]
	
	return []

func _get_debug_color() -> Color:
	return Color.YELLOW
