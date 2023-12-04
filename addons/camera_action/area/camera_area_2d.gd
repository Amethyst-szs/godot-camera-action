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
	for child in get_children():
		if child is CameraAction:
			action = child
			break
	
	if not action:
		push_error("CameraArea2D doesn't have CameraAction as child!")
		return
	
	area_entered.connect(enter_try_start.bind())
	body_entered.connect(enter_try_start.bind())
	area_exited.connect(exit_try_end.bind())
	body_exited.connect(exit_try_end.bind())

func _get_configuration_warnings() -> PackedStringArray:
	for child in get_children():
		if child is CameraAction:
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
