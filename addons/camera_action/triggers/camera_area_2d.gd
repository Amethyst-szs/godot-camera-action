@tool
@icon("res://addons/camera_action/icon/CameraArea2D.svg")

extends Area2D
## Trigger a CameraAction by bodies or areas entering and leaving an Area2D
class_name CameraArea2D

@export var filter: CollisionObject2D = null
@export var allow_any: bool = false

var action: CameraAction

#region Virtual Functions

func _ready():
	if not _try_get_action():
		push_error("CameraArea2D doesn't have CameraAction as child!")
		return
	
	area_entered.connect(enter_try_start.bind())
	body_entered.connect(enter_try_start.bind())
	area_exited.connect(exit_try_end.bind())
	body_exited.connect(exit_try_end.bind())

func _get_configuration_warnings() -> PackedStringArray:
	if _try_get_action():
		return []
	
	return ["This node doesn't have a CameraAction child!"]

#endregion

#region Start and Stop Methods

func enter_try_start(node: Node):
	if node == filter or allow_any:
		action.start()

func exit_try_end(node: Node):
	if node == filter or allow_any:
		action.end()

#endregion

#region Util

func _try_get_action() -> bool:
	for child in get_children():
		if child is CameraAction:
			action = child
			return true
		
		if child is Path2D:
			if _try_find_follow_in_path(child): return true
	
	return false

func _try_find_follow_in_path(path: Path2D) -> bool:
	for path_child in path.get_children():
		if path_child is PathFollow2D:
			return try_find_action_in_follow(path_child)
	
	return false

func try_find_action_in_follow(follow: PathFollow2D) -> bool:
	for follow_child in follow.get_children():
		if follow_child is CameraAction:
			action = follow_child
			return true
	
	return false

#endregion
