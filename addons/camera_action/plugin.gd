@tool
extends EditorPlugin

func _enter_tree():
	add_autoload_singleton("CameraActionManager", "res://addons/camera_action/manager.gd")

func _exit_tree():
	remove_autoload_singleton("CameraActionManager")
