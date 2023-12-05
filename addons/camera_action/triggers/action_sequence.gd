@tool
@icon("res://icon.svg")

extends CameraActionSwitch
## Advance through different camera actions in a specific order
class_name CameraActionSequence

#region Variables & Exports

enum LoopType {
	## End the current action and become inactive until started again
	END,
	## Go back to the first action in the list and continue
	REPEAT,
	## Go through the list backwards, bouncing back and fourth through the list
	PING_PONG
}

## When reaching the end of the action list, how should this behave?
@export var loop_mode: LoopType = LoopType.END

## Should this sequence automatically be started once node is ready?
@export var autostart: bool = false

## Automatically progress from one item in sequence to the next at this rate
## Leave at zero to disable feature
@export_range(0.0, 10.0, 0.1, "or_greater", "suffix:secs") var auto_timer: float = 0.0
var time: float = 0.0

## Current position in sequence (-1 means inactive, no cameras in sequence are enabled)
var index: int = -1

## Direction for sequence to be moving (used by ping-pong mode to reverse direction)
var direction: int = 1

#endregion

#region User Functions

## Start the sequence from the first index
func sequence_start():
	if action_list.is_empty():
		push_error("Cannot start CameraActionSequence with no actions in list")
		return
	
	index = 0
	start_by_index(index)

## Step through the sequence by some value (default: 1 index)
func sequence_step(step: int = 1):
	if action_list.is_empty():
		push_error("Cannot step in CameraActionSequence with no actions in list")
		return
	
	index = clampi(index + (step * direction), -1, action_list.size())
	
	if (index == action_list.size() and direction > 0) or (index == -1 and direction < 0):
		match(loop_mode):
			LoopType.END:
				sequence_end()
				return
			LoopType.REPEAT:
				index = 0
			LoopType.PING_PONG:
				direction *= -1
				index += direction * 2
	
	start_by_index(index)

## Set the sequence to a specific index
func sequence_set(new_index: int):
	if action_list.is_empty():
		push_error("Cannot set index of CameraActionSequence with no actions in list")
		return
	
	index = clampi(new_index, 0, action_list.size() - 1)
	start_by_index(index)

## End the sequence and reset index and direction
func sequence_end():
	index = -1
	direction = 1
	end_active()

## End the sequence but store the current index and direction for later use in resume
func sequence_pause():
	end_active()

## Start the sequence without updating index, meant to be combined with pause
func sequence_resume():
	if action_list.is_empty():
		push_error("Cannot resume CameraActionSequence with no actions in list")
		return
	
	index = clampi(index, 0, action_list.size() - 1)
	start_by_index(index)

#endregion

#region Timer Functionality

func _ready():
	if Engine.is_editor_hint(): return
	
	if autostart: sequence_start()

func _process(delta: float):
	if Engine.is_editor_hint(): return
	if index == -1 or auto_timer == 0.0: return
	
	time += delta
	if time >= auto_timer:
		time = 0.0
		sequence_step()

#endregion
