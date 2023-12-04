extends Node

#region User - Configuration Variables & Methods

## Always show the currently active camera box while in game.
## Very useful in debugging to visualize how your camera is behaving
var config_show_active_cam: bool = false:
	set(value):
		config_show_active_cam = value
		if active_action:
			active_action.set_debug_settings_visiblity_all(true)
	get:
		return config_show_active_cam

## By default CameraActions will affect the active Camera2D in the main viewport
## Set this value to another Camera2D to override this behavior
var config_override_cam: Camera2D = null

#endregion

#region Backend - Utilities

func get_camera():
	if config_override_cam:
		return config_override_cam
	
	return get_viewport().get_camera_2d()

#endregion

#region Backend - Priority System

## Determines the priority of a CameraAction, any action that is started during another action
## with higher priority will be queued until the higher priority actions are finished
enum PriorityType {
	NONE,
	LOWEST,
	LOWER,
	LOW,
	NORMAL,
	HIGH,
	HIGHER,
	HIGHEST,
}

## Array of queued CameraActions. When the active action is ended, the most recent and
## highest priority action in this queue will replace it (assuming the queue isn't empty)
var action_queue: Array[CameraAction] = []

## The current priority of the active_action, used to compare against when an action is started
var active_priority := PriorityType.NONE

## Current CameraAction node that is controlling the camera
var active_action: CameraAction = null

## Called whenever a CameraAction has its "start" method called
## Attempts to either replace the current active action or add the new action to the queue
func try_start(action: CameraAction) -> bool:
	# If this new action has a priority of NONE, skip it
	if action.priority == PriorityType.NONE:
		return false
	
	# Check this new action's priority and add to queue if lower
	if action.priority < active_priority:
		if not action_queue.has(action):
			action.is_in_queue = true
			action_queue.push_back(action)
		
		return false
	
	# If there is an active action already, move it into the queue and disable it
	if active_action:
		if config_show_active_cam: active_action.set_debug_settings_visiblity_all(false)
		active_action.pause()
		action_queue.push_back(active_action)
		active_action.is_in_queue = true
	
	# Replace active priority and active action
	active_priority = action.priority
	active_action = action
	action.is_in_queue = false
	
	# Setup parts of this action based on the user config
	if config_show_active_cam: action.set_debug_settings_visiblity_all(true)
	
	return true

## Called whenever a CameraAction is ended, either by the user or cause it is leaving the tree
## Removes itself from the action queue and updates the active action is needed
func end(action: CameraAction) -> void:
	# Remove this action from the queue if it is present
	if action_queue.has(action):
		action_queue.erase(action)
		action.is_in_queue = false
	
	# If ending the active action, search for a new active action
	if active_action == action:
		active_action = null
		
		# Setup the ending action node based on config
		if config_show_active_cam: action.set_debug_settings_visiblity_all(false)
		
		# Look for a new active action to start
		_try_start_new_action_with_queue()
	
	# If there is no active action, ensure the active priority is reset to NONE
	if not active_action:
		active_priority = PriorityType.NONE

## Called by the end method in this class to find the next CameraAction to use in the queue
## If it doesn't find a new action to use in the queue, camera will continue with no action applied
func _try_start_new_action_with_queue() -> bool:
	# Create variables to track our target action and priority
	var new_action: CameraAction
	var highest_priority: PriorityType = PriorityType.NONE
	
	# Iterate through the queue and find the newest action with the highest priority
	for item in action_queue:
		if item.priority >= highest_priority:
			new_action = item
			highest_priority = item.priority
	
	# Assuming an item was found, start that action and erase it from the queue
	if not new_action == null:
		active_priority = new_action.priority
		action_queue.erase(new_action)
		new_action.start()
		return true
	
	return false

#endregion
