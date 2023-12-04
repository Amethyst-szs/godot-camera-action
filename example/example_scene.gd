extends Node2D

func _input(_event):
	if Input.is_action_just_pressed("ui_select"):
		$CameraShake.start()
