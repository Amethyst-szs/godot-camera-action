@tool
extends CameraAction
class_name CameraActionFixed

@export_category("Camera Properties")

@export var zoom: float = 1
@export_range(-360, 360, 0.1, "or_greater", "or_less", "degrees") var degrees: float = 0

func apply():
	var tween: Tween = _create_cam_tween()
	var cam: Camera2D = _get_cam()
	if not cam:
		push_warning("%s could not apply to camera, couldn't find the active camera!" % [name])
	
	tween.tween_property(cam, "global_position", global_position, length)
	tween.tween_property(cam, "zoom", Vector2(zoom, zoom), length)
	tween.tween_property(cam, "rotation_degrees", degrees, length)
	
	tween.tween_property(cam, "offset", Vector2.ZERO, length)
	
	is_applying = true
	tween.finished.connect(apply_finished)

func applied_update():
	var cam: Camera2D = _get_cam()
	if not cam: return
	
	cam.global_position = global_position

func _ready():
	if not Engine.is_editor_hint():
		apply()

func _draw():
	if not _is_debug_drawing_available(): return
	_draw_camera(Vector2.ZERO, zoom, degrees, Color.MEDIUM_AQUAMARINE)

func _get_configuration_warnings():
	return []
