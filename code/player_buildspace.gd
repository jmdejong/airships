extends Camera3D

var speed = 5

func _physics_process(delta: float) -> void:
	
	if view_movement != Vector2.ZERO:
		$Head.rotation.x = clamp($Head.rotation.x - view_movement.y, -PI/2, PI/2)
		rotate_y(-view_movement.x)
		view_movement = Vector2.ZERO
	
	var input_movement: Vector2 = (Input.get_vector("left", "right", "forwards", "backwards") + %UI.move_joystick.touch_value()).limit_length()
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * speed) \
		.rotated(Vector3(0, 1, 0), rotation.y)
	
	position += movement
