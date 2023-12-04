@tool
@icon("res://example/player/player.png")

extends CameraAction
class_name CameraActionSimple

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

#endregion

#region Virtual Functions

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	_add_property_to_tween_reference_list("zoom", "zoom_vector", self, cam.zoom)
	_add_property_to_tween_reference_list("rotation_degrees", "degrees", self, cam.rotation_degrees)
	_add_property_to_tween_reference_list("offset", "offset", self, cam.offset)

func _draw():
	# Draw camera box if enabled
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, Color.CORNFLOWER_BLUE)

func _get_configuration_warnings():
	return []

#endregion
