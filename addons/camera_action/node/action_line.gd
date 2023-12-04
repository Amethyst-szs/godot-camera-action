@tool
@icon("res://addons/camera_action/icon/CameraActionLine.svg")

extends CameraActionSimple
## Camera will follow a fixed line segment at any angle
class_name CameraActionLine

#region Variables & Exports

## Direction for the camera to travel in
@export_range(-90, 90, 1, "degrees") var angle: float = 0.0:
	set(value):
		angle = value
		angle_rad = deg_to_rad(angle)
		angle_dir = Vector2.RIGHT.rotated(angle_rad)

## Lowest value the camera can go on this line
@export_range(0, 1, 1, "or_greater", "hide_slider", "suffix:px") var min_distance: float = 1000
## Highest value the camera can go on this line
@export_range(0, 1, 1, "or_greater", "hide_slider", "suffix:px") var max_distance: float = 1000

## Line angle variable converted to radians automatically
var angle_rad: float = 0.0
## Vector direction of line angle calculated automatically
var angle_dir: Vector2 = Vector2.RIGHT

## Target position the camera is set to
var target_cam_pos: Vector2 = Vector2.ZERO

#endregion

func start():
	super()
	var cam: Camera2D = _get_cam()
	if not tween or not cam: return
	
	# Calculate start position and add global_position tween
	_calc_target_cam_pos(cam)
	_add_property_to_tween_reference_list("global_position", "target_cam_pos", self, cam.global_position)
	
	# Enable limits based on boundaries
	var bounds: Rect2 = _calc_boundaries(true)
	
	match (abs(angle)):
		0.0:
			cam.limit_left = bounds.position.x
			cam.limit_right = bounds.size.x
		90.0:
			cam.limit_top = bounds.position.y
			cam.limit_bottom = bounds.size.y
		_:
			cam.limit_left = bounds.position.x
			cam.limit_right = bounds.size.x
			cam.limit_top = bounds.position.y
			cam.limit_bottom = bounds.size.y

func update_transition(delta: float):
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	_calc_target_cam_pos(cam)
	super(delta)

func update():
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	_calc_target_cam_pos(cam)
	cam.global_position = target_cam_pos

# Draw camera bounds and limits
func _draw():
	var col: Color = Color.LIGHT_SKY_BLUE
	
	if _is_camera_drawing_available():
		_draw_camera(Vector2.ZERO, zoom, degrees, col)
	
	if _is_limit_drawing_available():
		var offset := (Vector2.UP * 100).rotated(angle_rad)
		var bounds := _calc_boundaries(false)
			
		draw_line(bounds.position, bounds.size, col, 2)
		draw_line(bounds.position - offset, bounds.position + offset, col, 4)
		draw_line(bounds.size - offset, bounds.size + offset, col, 4)

# Cannot have configuration warnings
func _get_configuration_warnings():
	return []

func _calc_target_cam_pos(cam: Camera2D):
	var bounds := _calc_boundaries(true)
	var point: Vector2 = _get_base_target_pos(cam)
	
	# Convert camera parent node position to closest point on line
	var v := point - bounds.position
	var d := v.dot(angle_dir)
	target_cam_pos = bounds.position + (angle_dir * d)

func _get_base_target_pos(cam: Camera2D):
	# Gets the camera's parent node and its global position
	return cam.get_parent().global_position

func _calc_boundaries(is_add_global_position: bool = true) -> Rect2:
	# Converted min and max distance to boundary rectangle
	var edge_l := (Vector2.RIGHT * -min_distance).rotated(angle_rad)
	var edge_r := (Vector2.RIGHT * max_distance).rotated(angle_rad)
	
	if is_add_global_position:
		return Rect2(edge_l + global_position, edge_r + global_position)
	else:
		return Rect2(edge_l, edge_r)
