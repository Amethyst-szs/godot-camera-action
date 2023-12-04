extends CharacterBody2D

@export var speed = 500

func _process(_delta):
	var move_dir: Vector2 = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = move_dir * speed
	move_and_slide()
