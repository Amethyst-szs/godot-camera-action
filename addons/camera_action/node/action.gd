@tool
@icon("res://addons/camera_action/icon/CameraAction.svg")

extends Node2D
## A base class for all CameraAction nodes, cannot be used standalone
class_name CameraAction

#region Variables & Exports

# State variables

## Is this action currently in the CameraActionManager queue?
## If so, it will be enabled as soon as it is has the highest priority of all queue items
var is_in_queue: bool = false

## Is this action currently playing the transition animation?
var is_starting: bool = false

## Is this action completed with the transition animation and in regular update mode?
var is_running: bool = false

## Debug button to start action
var test_start: bool = false:
	set(value):
		start()
	get:
		return false

## Debug button to end action
var test_end: bool = false:
	set(value):
		end()
	get:
		return false

# State signals
signal update_shake(delta: float)

# Tweening

## Reference to the transition tween. Is null if animation isn't currently playing.
var tween: Tween = null
## Timer used to keep track of how long the tween has been animating
var tween_timer: float = 0.0
## References to all properties tweened by this action
var tween_reference_list: Array[Dictionary] = []

# Exports

## Enable a higher priority level than other CameraActions to override them
@export var priority := CameraActionManager.PriorityType.NORMAL
## Should this camera action be activated instantly on scene load?
@export var autostart: bool = false

@export_group("Transition")
## Duration in seconds it takes for the camera to change from current settings to new configuration
@export_range(0.0, 5.0, 0.1, "or_greater") var length: float = 1.0
## Should the camera be eased in, out, or both
@export var ease_type: Tween.EaseType = Tween.EASE_IN_OUT
## Curve for the easing animation to follow
@export var ease_curve: Tween.TransitionType = Tween.TRANS_LINEAR

@export_group("Debugging")
## Show camera visualization in the editor viewport
@export var show_camera: bool = true
## Show limit boundary box in editor viewport (if this CameraAction type supports limits)
@export var show_limits: bool = true
## Show editor debug info for the camera while the game is running
@export var show_in_game: bool = false

# Constants
const zero_vec: Vector2 = Vector2.ZERO

#endregion

#region Virtual Functions

## Automatically run start if flag is set in inspector
func _ready():
	if not Engine.is_editor_hint() and autostart:
		start()

## Start function, updates and animates camera
func start():
	# Check if this action's priority is higher than the current action
	if not CameraActionManager.try_start(self):
		return
	
	# Reset limits on camera, if this new action has limits it will set them up itself
	_reset_limits()
	
	# Create tween and set start flag
	_create_cam_tween()
	is_starting = true

## Once the transition animation is complete, this function is called, updating status.
func start_finished():
	is_starting = false
	is_running = true
	
	tween.kill()
	tween = null
	_destroy_tween_reference_list()

## Called every frame during _physics_process if the is_staring flag is set.
## This means it will only be called during the tween transition
func update_transition(delta: float, cam: Camera2D):
	_update_tween_reference_list()
	
	if self == CameraActionManager.active_action:
		update_shake.emit(delta)
	
	if tween_timer >= length:
		tween_timer = 0
		start_finished()

## Called every frame during _physics_process if the is_running flag is set.
## This means it will only be called after the transition animation completes
func update(delta: float, cam: Camera2D):
	if self == CameraActionManager.active_action:
		update_shake.emit(delta)

## Called when the CameraActionManager is given a new CameraAction with a higher priority than this one.
## This action will be placed in the queue and wait for itself to be highest priority again
func pause():
	is_starting = false
	is_running = false
	tween_timer = 0.0
	
	if tween:
		tween.kill()
		tween = null
	
	_destroy_tween_reference_list()

## Called to end this CameraAction. Has no effect if "start" wasn't already called.
func end():
	pause()
	CameraActionManager.end(self)

## Queues a redraw of the editor debug info if the editor hint exists
func _process(_delta):
	if Engine.is_editor_hint():
		queue_redraw()

## Call the update function if running
func _physics_process(delta):
	if not Engine.is_editor_hint():
		var cam: Camera2D = CameraActionManager.get_camera()
		if not cam: return
		
		if is_starting: update_transition(delta, cam)
		if is_running: update(delta, cam)

## Display a warning if the user adds a basic CameraAction to their scene, not an inherited type
func _get_configuration_warnings():
	return ["CameraAction cannot be used standalone. Use type that inherits this node"]

## End self in the manager when exiting the tree to prevent null shenanigans
func _exit_tree():
	_destroy_tween_reference_list()
	
	if not Engine.is_editor_hint():
		CameraActionManager.end(self)

#endregion

#region Draw Functions

## Overridden by inherited types, used to draw shapes to the editor interface
func _draw():
	if not _is_camera_drawing_available(): return
	
	# Draw bounds of camera
	_draw_camera(Vector2.ZERO, 1.0, 0.0, _get_debug_color())

## Draw the camera bounding box
func _draw_camera(pos_center: Vector2, zoom: float, angle: float, color: Color) -> void:
	# Create radian angle
	var angle_rad: float = deg_to_rad(angle - global_rotation_degrees)
	
	# Calculate size of camera and offset using zoom parameter
	var size: Vector2 = _get_default_viewport_size()
	size = (Vector2.ONE / zoom) * size
	
	# Calculate position of top-left corner by combining center and size
	var pos_tl := Vector2(pos_center + (-size / 2.0))
	
	# Create list of points to draw for camera bounds
	var points: Array[Vector2] = [
		Vector2(pos_center + (pos_tl - pos_center).rotated(angle_rad)),
		pos_center + (Vector2(pos_tl.x + size.x, pos_tl.y) - pos_center).rotated(angle_rad),
		pos_center + (Vector2(pos_tl.x + size.x, pos_tl.y + size.y) - pos_center).rotated(angle_rad),
		pos_center + (Vector2(pos_tl.x, pos_tl.y + size.y) - pos_center).rotated(angle_rad),
	]
	
	# Draw marker indicating the top of the camera
	var pos_marker_end := points[0].move_toward(points[1], size.x / 2)
	var pos_marker_start := pos_marker_end.move_toward(pos_center, size.y / 10)
	draw_line(pos_marker_start, pos_marker_end, color.darkened(0.2), 3)
	draw_circle(pos_marker_end, 10, color.darkened(0.2))
	
	# Draw camera frame
	_draw_rect_from_points(points, color, 3)
	_draw_converging_from_points(pos_center, points, color.lightened(0.1), 1)

## Draw a rectangangle out of a list of points
func _draw_rect_from_points(points: Array[Vector2], color: Color, thickness: float):
	draw_line(points[0], points[1], color, thickness)
	draw_line(points[1], points[2], color, thickness)
	draw_line(points[2], points[3], color, thickness)
	draw_line(points[3], points[0], color, thickness)

## Draw lines converging on one point from four other points
func _draw_converging_from_points(center: Vector2, points: Array[Vector2], color: Color, thickness: float):
	draw_line(center, points[0], color, thickness)
	draw_line(center, points[1], color, thickness)
	draw_line(center, points[2], color, thickness)
	draw_line(center, points[3], color, thickness)

#endregion

#region Tweening System

## Creates the camera tween and sets up settings
func _create_cam_tween() -> void:
	tween = create_tween()
	tween.set_parallel(true).set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	tween.tween_property(self, "tween_timer", length, length)
	tween.set_ease(ease_type).set_trans(ease_curve)

## Adds a property to the list that gets tweened during the action transition
func _add_property_to_tween_reference_list(cam_var_name: String, target_var_name: String, target_object: Object, initial_value, component: String = "") -> void:
	# Ensure this same property wasn't already added earlier
	_remove_tween_reference(cam_var_name)
	
	# Create dictionary of information about this property
	var new_item: Dictionary = {
		"cam_var": cam_var_name,
		"target": target_var_name,
		"target_obj": target_object,
		"initial": initial_value
	}
	
	if not component.is_empty():
		new_item["component"] = component
	
	# Add to list
	tween_reference_list.push_back(new_item)

## Called during update_transition to animate all tweens
## Uses the tween reference list to animate using interpolate_value
func _update_tween_reference_list() -> void:
	var cam: Camera2D = CameraActionManager.get_camera()
	if not tween or not cam: return
	
	# Iterate through the whole tween reference list
	for idx in range(tween_reference_list.size()):
		var dict: Dictionary = tween_reference_list[idx]
		
		# Get target and interpolated value
		var target = dict["target_obj"].get(dict["target"])
		var value
		
		if dict.has("component"):
			var component: String = dict["component"]
			var value_comp = tween.interpolate_value(dict["initial"][component], target[component] - dict["initial"][component], tween_timer, length, ease_curve, ease_type)
			
			value = cam.get(dict["cam_var"])
			value[component] = value_comp
		else:
			value = tween.interpolate_value(dict["initial"], target - dict["initial"], tween_timer, length, ease_curve, ease_type)
		
		# Update cam var with value
		cam.set(dict["cam_var"], value)

## Remove a tween property from the list
## Mainly used in inherited classes to remove a reference added by their parent
func _remove_tween_reference(cam_var_name: String, componenent: String = "") -> void:
	for item in tween_reference_list:
		if not componenent.is_empty():
			if item["cam_var"] == cam_var_name and item["component"] == componenent:
				tween_reference_list.erase(item)
		else:
			if item["cam_var"] == cam_var_name:
				tween_reference_list.erase(item)

## Destroy the list of tween properties, leave. no. survivors.
func _destroy_tween_reference_list() -> void:
	tween_reference_list.clear()

#endregion

#region General Utility Functions

## Toggles the state of show_camera, show_limits, and show_in_game all at once
func set_debug_settings_visiblity_all(is_visible: bool) -> void:
	visible = is_visible
	show_camera = is_visible
	show_limits = is_visible
	show_in_game = is_visible
	queue_redraw()

func _reset_limits() -> void:
	var cam: Camera2D = CameraActionManager.get_camera()
	if not cam: return
	
	cam.limit_left = -10000000
	cam.limit_top = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000

## Gets a vector of the viewport's size from the ProjectSettings
func _get_default_viewport_size() -> Vector2:
	var size: Vector2
	size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	size.y = ProjectSettings.get_setting("display/window/size/viewport_height")
	return size

func _get_viewport_size() -> Vector2:
	if Engine.is_editor_hint():
		return _get_default_viewport_size()
	
	return get_viewport().size

func _get_debug_color() -> Color:
	return Color.RED

## Checks if the current configuration allows drawing the camera bounding box
func _is_camera_drawing_available() -> bool:
	if not Engine.is_editor_hint():
		if not show_in_game or not show_camera: return false
	
	if Engine.is_editor_hint() and not show_camera: return false
	return true

## Checks if the current configuration allows drawing the limits bounding box
func _is_limit_drawing_available() -> bool:
	if not Engine.is_editor_hint():
		if not show_in_game or not show_limits: return false
	
	if Engine.is_editor_hint() and not show_limits: return false
	return true

#endregion
