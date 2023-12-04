@icon("res://addons/camera_action/icon/CameraShake.svg")

extends Node2D
class_name CameraShake

#region Enums

enum EaseType {
	NONE,
	EASE_IN,
	EASE_OUT,
	EASE_IN_OUT
}

#endregion

#region Variables & Exports

var is_active: bool = false
var active_time: float = 0.0
var time_animation: float = 0.0

@export_group("Lifetime")
## Should the camera shake continue indefinitely until manually stopped
@export var infinite_duration: bool = false
## Duration in seconds that the camera will spend shaking
@export_range(0.0, 5.0, 0.1, "or_greater") var duration: float = 0.5

@export_group("Animation")
## Speed of shaking animation (multiple of time in sine wave)
@export_range(0.1, 20.0, 0.1, "or_greater") var speed: float = 5.0
## Should the camera be eased in, out, or both
@export var easing: EaseType = EaseType.EASE_OUT
## How long should the ease in last in seconds
@export_range(0.0, 1.0, 0.05, "or_greater") var ease_in_length: float = 0.2
## How long should the ease out last in seconds
@export_range(0.0, 1.0, 0.05, "or_greater") var ease_out_length: float = 0.2

@export_group("Randomness")
## Complexity of shaking, low numbers make simple movements and high numbers are more eratic
@export_range(1, 5) var complexity: int = 2
## Every time this shake is played, should the seed to randomized?
@export var variations: bool = true
## Manually changes randomness of the wave pattern the shake follows
@export var seed: int = 0

@export_group("Size")
## Radius for the camera to shake in the X direction
@export_range(0.0, 50.0, 0.5, "or_greater", "suffix:px") var horizontal_size: float = 10.0
## Radius for the camera to shake in the Y direction
@export_range(0.0, 50.0, 0.5, "or_greater", "suffix:px") var vertical_size: float = 10.0
## Degrees for the camera to rotate around during shake
@export_range(0.0, 45.0, 0.01, "or_greater", "degrees", "radians_as_degrees") var rotation_size: float = 0.0872
## Distance for the camera to zoom exponentially
@export_range(0.0, 0.5, 0.01, "or_greater", "suffix:exp") var zoom_size: float = 0.1

@export_group("Components")
## Should the camera's position be shaken?
## Note that this shakes the offset, not the raw position, so it can go over limits
@export var edit_position: bool = true
## Should the camera be rotated by the shake?
@export var edit_rotation: bool = false
## Should the camera be zoomed in and out by the shake?
@export var edit_zoom: bool = false

#endregion

#region Implementation

func start() -> void:
	if CameraActionManager.config_shake_strength < 0.01: return
	
	if not CameraActionManager.active_action:
		push_warning("Cannot start CameraShake without any CameraAction active!")
		return
	
	is_active = true
	active_time = 0.0
	time_animation = 0.0
	
	if variations:
		seed = randi_range(-1000000, 1000000)
	
	if not CameraActionManager.update_camera_shake.is_connected(_update):
		CameraActionManager.update_camera_shake.connect(_update.bind())

func _update(delta: float) -> void:
	var cam: Camera2D = CameraActionManager.get_camera()
	if not is_active or not cam: return
	
	# Add the delta of this process to the current time
	active_time += delta
	
	# Create speed factor to scale the shaking speed based on easing
	var speed_factor: float = speed
	# Create decay factor to smooth components
	var decay_factor: float = 1.0
	
	# If in the ease in time range, calculate speed factor
	if active_time < ease_in_length and _is_ease_in():
		decay_factor = lerpf(0.0, 1.0, active_time / ease_in_length)
	# If in the ease out time range, calculate decay factor and speed factor
	else: if active_time > duration - ease_out_length and _is_ease_out():
		decay_factor = lerpf(1.0, 0.0, 1.0 - ((duration - active_time) / ease_out_length))
	
	decay_factor = maxf(0.0, decay_factor)
	speed_factor = decay_factor * speed
	
	# Animation time is the same as regular time but scaled by easing rate
	time_animation += delta * speed_factor
	
	# Get shake strength modifier
	var modifier: float = CameraActionManager.config_shake_strength
	
	# Modify components
	if edit_position:
		var position_offset: Vector2 = Vector2(
			_calc_complex_wave(time_animation + rand_from_seed(seed + 2)[0]) * horizontal_size,
			_calc_complex_wave(time_animation + rand_from_seed(seed + 4)[0]) * vertical_size
		)
		
		cam.offset += position_offset * decay_factor * modifier
	
	if edit_rotation:
		var base := _calc_complex_wave(time_animation + rand_from_seed(seed + 4)[0]) * rotation_size
		cam.rotation += base * decay_factor * modifier
	
	if edit_zoom:
		var base := _calc_complex_wave(time_animation + rand_from_seed(seed + 6)[0]) * zoom_size
		cam.zoom += Vector2(base, base) * decay_factor * modifier
	
	# Check if the animation has finished
	if active_time >= duration and not infinite_duration:
		end()

func end() -> void:
	is_active = false
	active_time = 0.0
	time_animation = 0.0
	
	if CameraActionManager.update_camera_shake.is_connected(_update):
		CameraActionManager.update_camera_shake.disconnect(_update.bind())

#endregion

#region Utility Functions

func _calc_complex_wave(time: float) -> float:
	var rand: int = rand_from_seed(seed)[0] % 100000
	var wave_components: Array[float]
	var wave: float = 0.0
	
	for idx in range(complexity):
		wave_components.push_back(sin((time + rand) * ((rand_from_seed(rand + idx)[0] % 3) + 1)))
	
	for item in wave_components:
		wave += item
	
	return wave / wave_components.size()

func _is_ease_in() -> bool:
	return easing == EaseType.EASE_IN or easing == EaseType.EASE_IN_OUT

func _is_ease_out() -> bool:
	return (easing == EaseType.EASE_OUT or easing == EaseType.EASE_IN_OUT) and not infinite_duration

#endregion
