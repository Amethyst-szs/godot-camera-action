extends CharacterBody2D

@export var speed = 500
@export var run_speed = 1200

func _process(_delta):
	var move_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_pressed("run"):
		velocity = move_dir * run_speed
	else:
		velocity = move_dir * speed
	
	move_and_slide()
