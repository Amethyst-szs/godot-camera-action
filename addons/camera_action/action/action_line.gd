@tool
@icon("res://addons/camera_action/icon/CameraActionLine.svg")

extends CameraActionSimple
## Camera will follow a fixed line segment at any angle
class_name CameraActionLine

#region Enums

enum EaseComponenets {
	X,
	Y,
	BOTH
}

#endregion

#region Variables & Exports

## Direction for the camera to travel in
@export_range(-180, 180, 0.5, "degrees") var angle: float = 0.0:
	set(value):
		angle = value
		angle_rad = deg_to_rad(angle)
		angle_dir = Vector2.RIGHT.rotated(angle_rad)
		_update_camera_bounds()

## Should the position of the camera be kept within a bounding box?
@export var apply_limits: bool = false:
	set(value):
		apply_limits = value
		_update_camera_bounds()

## How far backwards can the camera travel
@export_range(1, 1, 1, "or_greater", "hide_slider", "suffix:px") var limit_backward: float = 1000:
	set(value):
		limit_backward = value
		_update_camera_bounds()

## How far forwards can the camera travel
@export_range(1, 1, 1, "or_greater", "hide_slider", "suffix:px") var limit_forward: float = 1000:
	set(value):
		limit_forward = value
		_update_camera_bounds()

const limit_top: float = 100000
const limit_bottom: float = 100000

## Should the X, Y, or both vector components be eased during camera start
@export var ease_components := EaseComponenets.BOTH

## Line angle variable converted to radians automatically
var angle_rad: float = 0.0
## Vector direction of line angle calculated automatically
var angle_dir: Vector2 = Vector2.RIGHT

## Target position the camera is set to
var target_cam_pos: Vector2 = Vector2.ZERO
## Dictionary containing info about the camera boundary.
## Automatically updates when limits or angle changes, as well as on camera start
var camera_bounds: Dictionary = {}

#endregion

#region Main Functions

func _enter_tree():
	_update_camera_bounds()

func start():
	super()
	
	var cam: Camera2D = CameraActionManager.get_camera()
	if not tween or not cam: return
	
	_update_camera_bounds(cam)
	_calc_target_cam_pos(cam)
	
	# If coming from a previous action of CameraActionLine, set ease components to both
	var previous_action: CameraAction = CameraActionManager.previous_action
	if is_instance_valid(previous_action) and previous_action is CameraActionLine:
		_add_property_to_tween_reference_list("global_position", "target_cam_pos", self, cam.global_position)
	else:
		# Add different property to tween list depending on ease components
		match(ease_components):
			EaseComponenets.BOTH:
				_add_property_to_tween_reference_list("global_position", "target_cam_pos", self, cam.global_position)
			EaseComponenets.X:
				_add_property_to_tween_reference_list("global_position", "target_cam_pos", self, cam.global_position, "x")
			EaseComponenets.Y:
				_add_property_to_tween_reference_list("global_position", "target_cam_pos", self, cam.global_position, "y")

func update_transition(delta: float, cam: Camera2D):
	_calc_target_cam_pos(cam)
	super(delta, cam)

func update(delta: float, cam: Camera2D):
	_calc_target_cam_pos(cam)
	cam.global_position = target_cam_pos
	
	super(delta, cam)

# Draw camera bounds and limits
func _draw():
	if camera_bounds.is_empty(): return
	var col: Color = _get_debug_color()
	
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, col)
	
	if _is_limit_drawing_available():
		draw_line(camera_bounds["start"], camera_bounds["end"], col.lightened(0.4), 6)
		if apply_limits:
			_draw_rect_from_points(_bounds_to_array(), col.lightened(0.2), 5)

# Cannot have configuration warnings
func _get_configuration_warnings():
	return []

func _get_debug_color() -> Color:
	return Color.MEDIUM_PURPLE

#endregion

#region Targetting Utilities

func _calc_target_cam_pos(cam: Camera2D):
	var point: Vector2 = _get_base_target_pos(cam)
	var global_start: Vector2 = global_position + camera_bounds["start"]
	target_cam_pos = _calc_point_on_line(point, global_start, angle_dir)

func _calc_point_on_line(point: Vector2, line_start: Vector2, line_dir: Vector2) -> Vector2:
	var v: Vector2 = point - line_start
	var d := v.dot(angle_dir)
	return line_start + (angle_dir * d)

func _get_base_target_pos(cam: Camera2D):
	# Gets the camera's parent node and its global position
	return cam.get_parent().global_position

#endregion

#region Limit Bounding Utilities

func _update_camera_bounds(cam: Camera2D = null) -> void:
	# Converted min and max distance to boundary rectangle
	camera_bounds  = {
		"tl": ((Vector2.LEFT * limit_backward) + (Vector2.UP * limit_top)).rotated(angle_rad),
		"tr": ((Vector2.RIGHT * limit_forward) + (Vector2.UP * limit_top)).rotated(angle_rad),
		"bl": ((Vector2.LEFT * limit_backward) + (Vector2.DOWN * limit_bottom)).rotated(angle_rad),
		"br": ((Vector2.RIGHT * limit_forward) + (Vector2.DOWN * limit_bottom)).rotated(angle_rad),
		"start": angle_dir * -1000000,
		"end": angle_dir * 1000000,
	}
	
	if cam and apply_limits:
		cam.limit_left = global_position.x + _get_closest_point_in_direction(Vector2.LEFT).x
		cam.limit_top = global_position.y + _get_closest_point_in_direction(Vector2.UP).y
		cam.limit_right = global_position.x + _get_closest_point_in_direction(Vector2.RIGHT).x
		cam.limit_bottom = global_position.y + _get_closest_point_in_direction(Vector2.DOWN).y

func _get_closest_point_in_direction(dir: Vector2) -> Vector2:
	if camera_bounds.is_empty(): return Vector2.ZERO
	
	dir *= 100000
	var closest: float = 10000000.0
	var value: Vector2
	
	for idx in range(4):
		var dist: float = dir.distance_to(camera_bounds.values()[idx])
		if dist < closest:
			closest = dist
			value = camera_bounds.values()[idx]
	
	return value

func _bounds_to_array() -> Array[Vector2]:
	if camera_bounds.is_empty(): return []
	return [camera_bounds["tl"], camera_bounds["tr"], camera_bounds["br"], camera_bounds["bl"]]

#endregion
