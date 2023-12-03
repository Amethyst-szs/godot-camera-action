@tool
extends Node2D
class_name CameraAction

#region Variables & Exports

var is_applying: bool = false
var is_applied: bool = false

@export_category("Camera Transition")
## Duration in seconds it takes for the camera to change from current settings to new configuration
@export_range(0.0, 5.0, 0.1, "or_greater") var length: float = 1.0
## Should the camera be eased in, out, or both
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
## Curve for the easing animation to follow
@export var ease_curve: Tween.TransitionType = Tween.TRANS_LINEAR

@export_category("Debugging")
## Show bounding boxes and other helpful information in the editor viewport
@export var show_in_editor: bool = true
## Show editor debug info for the camera while the game is running
@export var show_in_game: bool = false

#endregion

#region Virtual Functions

func apply():
	push_error(_get_configuration_warnings()[0])

func apply_finished():
	is_applying = false
	is_applied = true

func applied_update():
	push_error(_get_configuration_warnings()[0])

func apply_end():
	is_applying = false
	is_applied = false

func _process(_delta):
	if _is_debug_drawing_available() and Engine.is_editor_hint():
		queue_redraw()

func _physics_process(_delta):
	if is_applied: applied_update()

func _get_configuration_warnings():
	return ["CameraAction cannot be used standalone. Use type of CameraAction that inherits this node"]

#endregion

#region Draw Functions

func _draw():
	if not _is_debug_drawing_available(): return
	
	# Draw bounds of camera
	_draw_camera(Vector2.ZERO, 1.0, 0.0, Color.RED)

func _draw_camera(pos_center: Vector2, zoom: float, angle: float, color: Color) -> void:
	# Create radian angle
	var angle_rad: float = deg_to_rad(angle)
	
	# Calculate size of camera and offset using zoom parameter
	var size: Vector2 = _get_default_viewport_size()
	size = (Vector2.ONE / zoom) * size
	
	# Calculate position of top-left corner by combining center and size
	var pos_topleft := Vector2(pos_center + (-size / 2.0))
	
	# Create list of points to draw for camera bounds
	var points: Array[Vector2] = [
		Vector2(pos_center + (pos_topleft - pos_center).rotated(angle_rad)),
		pos_center + (Vector2(pos_topleft.x + size.x, pos_topleft.y) - pos_center).rotated(angle_rad),
		pos_center + (Vector2(pos_topleft.x + size.x, pos_topleft.y + size.y) - pos_center).rotated(angle_rad),
		pos_center + (Vector2(pos_topleft.x, pos_topleft.y + size.y) - pos_center).rotated(angle_rad),
	]
	
	# Draw marker indicating the top of the camera
	var pos_marker_end := points[0].move_toward(points[1], size.x / 2)
	var pos_marker_start := pos_marker_end.move_toward(pos_center, size.y / 10)
	draw_line(pos_marker_start, pos_marker_end, color.darkened(0.2), 3)
	draw_circle(pos_marker_end, 10, color.darkened(0.2))
	
	# Draw camera frame
	_draw_rect_from_points(points, color, 3)
	_draw_converging_lines_from_points(pos_center, points, color.darkened(0.4), 1)

func _draw_rect_from_points(points: Array[Vector2], color: Color, thickness: float):
	draw_line(points[0], points[1], color, thickness)
	draw_line(points[1], points[2], color, thickness)
	draw_line(points[2], points[3], color, thickness)
	draw_line(points[3], points[0], color, thickness)

func _draw_converging_lines_from_points(center: Vector2, points: Array[Vector2], color: Color, thickness: float):
	draw_line(center, points[0], color, thickness)
	draw_line(center, points[1], color, thickness)
	draw_line(center, points[2], color, thickness)
	draw_line(center, points[3], color, thickness)

#endregion

#region General Utility Functions

func _create_cam_tween() -> Tween:
	var tween: Tween = create_tween()
	tween.set_parallel(true).set_ease(ease_type).set_trans(ease_curve)
	
	return tween

func _get_cam() -> Camera2D:
	return get_viewport().get_camera_2d()

func _get_default_viewport_size() -> Vector2:
	var size: Vector2
	size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	return size

func _is_debug_drawing_available() -> bool:
	if not Engine.is_editor_hint() and not show_in_game: return false
	if Engine.is_editor_hint() and not show_in_editor: return false
	return true

#endregion
