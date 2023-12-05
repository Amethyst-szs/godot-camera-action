@tool
@icon("res://addons/camera_action/icon/CameraActionPath.svg")

extends CameraActionSimple
## Camera can be attached to a PathFollow2D and animated moving along the path,
## optionally also including rotations
class_name CameraActionPath

@export var rotate_on_path: bool = false

var degrees_initial: float = 0.0
var degrees_offset: float = 0.0

func _ready():
	degrees_initial = degrees
	
	if not get_parent() is PathFollow2D:
		push_error("CameraActionRail must be a child of a PathFollow2D\n%s" % [get_path()])
		return
	
	super()

func start():
	super()
	var cam: Camera2D = CameraActionManager.get_camera()
	if not tween or not cam: return
	
	_calc_degrees_offset()
	_add_property_to_tween_reference_list("global_position", "global_position", self, cam.global_position)
	_add_property_to_tween_reference_list("rotation_degrees", "degrees_offset", self, cam.rotation_degrees)

func update_transition(delta: float, cam: Camera2D):
	_calc_degrees_offset()
	
	super(delta, cam)
	
	if show_in_game and not Engine.is_editor_hint():
		queue_redraw()

func update(delta: float, cam: Camera2D):
	cam.global_position = global_position
	if rotate_on_path:
		degrees = get_parent().global_rotation_degrees + degrees_initial
	
	super(delta, cam)
	
	if show_in_game and not Engine.is_editor_hint():
		queue_redraw()

func _draw():
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, _get_debug_color())

# Display warning if remote node is not set
func _get_configuration_warnings():
	if not get_parent() is PathFollow2D:
		return ["Must be a child of a PathFollow2D node"]
	
	return []

func _calc_degrees_offset():
	if get_parent() is PathFollow2D:
		degrees_offset = degrees
		if rotate_on_path: degrees_offset += get_parent().global_rotation_degrees

func _get_debug_color() -> Color:
	return Color.DEEP_PINK.darkened(0.2)
