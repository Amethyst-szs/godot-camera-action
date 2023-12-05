@tool
@icon("res://addons/camera_action/icon/CameraActionSimple.svg")

extends CameraAction
## A base for all more complex camera action types
## Can be used to animate zoom, rotation, offset, and some other optional overrides
class_name CameraActionSimple

#region Enums

enum OverrideType {
	## Don't change this property when starting this camera action
	UNCHANGED,
	## Disable this camera feature when starting this camera action
	DISABLED,
	## Enable this camera feature when starting this camera action
	ENABLED
}

#endregion

#region Variables & Exports

## How far in/out should the camera be zoomed while this camera action is active
@export var zoom: float = 1:
	set(value):
		zoom = value
		zoom_vector = Vector2(zoom, zoom)
	get:
		return zoom

var zoom_vector: Vector2 = Vector2.ONE

## Degrees to rotate camera by while this camera action is active
@export_range(-360, 360, 0.1, "or_greater", "or_less", "degrees") var degrees: float = 0

## Camera's offset from target position
@export var offset: Vector2 = Vector2.ZERO

@export_group("Optional Overrides")

@export_subgroup("Position Smoothing")
@export var pos_override := OverrideType.UNCHANGED
@export_range(0.5, 25.0, 0.5, "or_greater") var pos_speed: float = 5.0
var pos_override_old: bool = false
var pos_speed_old: float = 0.0

@export_subgroup("Rotation Smoothing")
@export var rot_override := OverrideType.UNCHANGED
@export_range(0.5, 25.0, 0.5, "or_greater") var rot_speed: float = 5.0
var rot_override_old: bool = false
var rot_speed_old: float = 0.0

#endregion

#region Virtual Functions

func start():
	super()
	var cam: Camera2D = CameraActionManager.get_camera()
	if not tween or not cam: return
	
	_add_property_to_tween_reference_list("zoom", "zoom_vector", self, cam.zoom)
	_add_property_to_tween_reference_list("rotation_degrees", "degrees", self, cam.rotation_degrees)
	_add_property_to_tween_reference_list("offset", "offset", self, cam.offset)
	
	if not pos_override == OverrideType.UNCHANGED:
		pos_override_old = cam.position_smoothing_enabled
		pos_speed_old = cam.position_smoothing_speed
		_add_property_to_tween_reference_list("position_smoothing_speed", "pos_speed", self, cam.position_smoothing_speed)
		cam.position_smoothing_enabled = (pos_override == OverrideType.ENABLED)
	
	if not rot_override == OverrideType.UNCHANGED:
		rot_override_old = cam.rotation_smoothing_enabled
		rot_speed_old = cam.rotation_smoothing_speed
		_add_property_to_tween_reference_list("rotation_smoothing_speed", "rot_speed", self, cam.rotation_smoothing_speed)
		cam.rotation_smoothing_enabled = (rot_override == OverrideType.ENABLED)

func update(delta: float, cam: Camera2D):
	cam.zoom = zoom_vector
	cam.rotation_degrees = degrees
	cam.offset = offset
	
	super(delta, cam)

func pause():
	super()
	
	var cam: Camera2D = CameraActionManager.get_camera()
	if not cam: return
	
	if not pos_override == OverrideType.UNCHANGED:
		cam.position_smoothing_enabled = pos_override_old
		cam.position_smoothing_speed = pos_speed_old
	
	if not rot_override == OverrideType.UNCHANGED:
		cam.rotation_smoothing_enabled = rot_override_old
		cam.rotation_smoothing_speed = rot_speed_old

func _draw():
	# Draw camera box if enabled
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, _get_debug_color())

func _get_configuration_warnings():
	return []

func _get_debug_color() -> Color:
	return Color.CORNFLOWER_BLUE

#endregion
