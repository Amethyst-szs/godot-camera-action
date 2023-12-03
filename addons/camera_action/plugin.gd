@tool
extends EditorPlugin

func _enter_tree():
	add_custom_type("CameraAction", "Node2D", CameraAction, preload("res://icon.svg"))
	add_custom_type("CameraActionFixed", "CameraAction", CameraActionFixed, preload("res://icon.svg"))

func _exit_tree():
	remove_custom_type("CameraAction")
	remove_custom_type("CameraActionFixed")
