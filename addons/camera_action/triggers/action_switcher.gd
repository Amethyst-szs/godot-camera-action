@tool
@icon("res://addons/camera_action/icon/CameraActionSwitcher.svg")

extends Node2D
## Switch between a different camera actions in scene by index or node name
class_name CameraActionSwitch

## List of actions that you can toggle between using this switcher.
## You'll be able to access anything in this list by index and name (non-case sensitive)
@export var action_list: Array[CameraAction]:
	set(value):
		action_list = value
		_update_action_name_list()

## Is the current list of action names matching the main action list?
var is_action_name_list_valid: bool = false
## List of action node's NodePath name
var action_name_list: Array[String]

## The currently active action in this switcher.
## Only one in the switch can be active at a time.
## This follow standard priorty rules, so if the camera you're enabling with the switch
## has lower priority than the highest priority camera in the queue, your switch camera
## will end up in the queue behind it
var active_action: CameraAction = null

func _ready():
	_update_action_name_list()

## Start a camera action by index in the action list
func start_by_index(index: int) -> void:
	if not _is_valid_index(index): return
	var node: CameraAction = action_list[index]
	
	if node == active_action: return
	
	if active_action:
		active_action.end()
	
	active_action = node
	node.start()

## Start a camera action by the name of the node (not case-sensitive)
func start_by_node_name(name: String) -> void:
	if not _is_valid_name(name): return
	var node_idx: int = action_name_list.find(name.to_lower())
	var node: CameraAction = action_list[node_idx]
	
	if node == active_action: return
	
	if active_action:
		active_action.end()
	
	active_action = node
	node.start()

## End the currently active camera in the switcher
func end_active() -> void:
	if not active_action: return
	
	active_action.end()
	active_action = null

## Check if the index supplied has a valid action node
func _is_valid_index(index: int) -> bool:
	if index >= action_list.size() or index < 0:
		push_warning("Cannot start action in CameraActionSwitcher with out-of-bounds index!
		Requested index: %s - Max index: %s" % [str(index), str(action_list.size())])
		return false
	
	var node: CameraAction = action_list[index]
	
	if not is_instance_valid(node) or not node.is_inside_tree():
		push_warning("Cannot start action in CameraActionSwitcher with invalid action instance
		(Maybe the scene and this node hasn't finished initalizing?)
		Requested index: %s" % [str(index)])
		return false
	
	return true

## Check if the node name supplied matches with a valid action node in the list
func _is_valid_name(name: String) -> bool:
	if not is_action_name_list_valid:
		push_warning("Cannot start action by name in CameraActionSwitcher with bad action list!
		(Maybe the nodes or scene hasn't finished initalizing?)
		Requested name: %s" % [name.to_lower()])
		return false
	
	var node_idx: int = action_name_list.find(name.to_lower())
	if node_idx == -1:
		push_warning("Cannot start action in CameraActionSwitcher with unknown node name!
		Requested name: %s" % [name.to_lower()])
		return false
	
	var node: CameraAction = action_list[node_idx]
		
	if not is_instance_valid(node) or not node.is_inside_tree():
		push_warning("Cannot start action in CameraActionSwitcher with invalid action instance
		(Maybe the nodes or scene hasn't finished initalizing?)
		Requested name: %s" % [str(name.to_lower())])
		return false
	
	return true

## Updates the action name list to match with the action list
func _update_action_name_list():
	action_name_list.clear()
	for item in action_list:
		if not item.is_inside_tree():
			print(item)
			is_action_name_list_valid = false
			return
		
		var name: String = item.get_path().get_name(item.get_path().get_name_count() - 1)
		action_name_list.push_back(name.to_lower())
	
	is_action_name_list_valid = true
