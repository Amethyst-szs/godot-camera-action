@tool
@icon("res://addons/camera_action/icon/CameraActionRail.svg")

extends CameraActionSimple
class_name CameraActionRail

@export var rotate_on_path: bool = false

var degrees_offset: float = 0.0

func _ready():
	if not get_parent() is PathFollow2D:
		push_error("CameraActionRail must be a child of a PathFollow2D\n%s" % [get_path()])
		return
	
	super()

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	_calc_degrees_offset()
	_add_property_to_tween_reference_list("global_position", "global_position", self, cam.global_position)
	_add_property_to_tween_reference_list("rotation_degrees", "degrees_offset", self, cam.rotation_degrees)

func update_transition(delta: float):
	super(delta)
	_calc_degrees_offset()

func update():
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	_calc_degrees_offset()
	cam.global_position = global_position
	cam.rotation_degrees = degrees_offset

# Display warning if remote node is not set
func _get_configuration_warnings():
	if not get_parent() is PathFollow2D:
		return ["Must be a child of a PathFollow2D node"]
	
	return []

func _calc_degrees_offset():
	if get_parent() is PathFollow2D:
		degrees_offset = degrees
		if rotate_on_path: degrees_offset += get_parent().rotation_degrees
