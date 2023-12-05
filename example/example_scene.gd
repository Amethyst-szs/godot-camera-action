extends Node2D

func _input(_event):
	if Input.is_action_just_pressed("ui_select"):
		$CameraShake.start()
	
	if Input.is_action_just_pressed("ui_accept"):
		$Cameras/Sequence.sequence_start()
