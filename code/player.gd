extends CharacterBody3D

const MOUSE_SENSITIVITY: float = 0.003
const speed: float = 4
const sprint_speed: float = 40
const jump_speed: float = 10

var gravity_enabled: bool = true

signal viewpoint_changed(pos: Vector3)

func adjust_direction() -> void:
	var down = get_gravity()
	if down.length_squared() == 0:
		down = Vector3(0, -1, 0)
	look_at(global_position + (quaternion * Vector3.RIGHT).cross(down).normalized(), -down.normalized())
	

func _physics_process(delta: float) -> void:
	var input_movement: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
	var s: float = speed
	if Input.is_action_pressed("sprint"):
		s = sprint_speed
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * s)
	if gravity_enabled:
		movement.y = velocity.y - Atmosphere.gravity() * delta
		if Input.is_action_pressed("up"):
			movement.y = s
	else:
		movement.y = s * (float(Input.is_action_pressed("up")) - float(Input.is_action_pressed("down")))
	velocity = movement.rotated(Vector3(0, 1, 0), rotation.y)
	move_and_slide()
	
	viewpoint_changed.emit(position)

func _input(event: InputEvent):
	if Input.is_action_just_pressed("toggle_gravity"):
		gravity_enabled = !gravity_enabled
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if Input.is_action_just_pressed("click"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			try_press()
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		$Head.rotation.x = clamp($Head.rotation.x - event.relative.y * MOUSE_SENSITIVITY, -PI/2, PI/2)
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)


func _process(delta: float) -> void:
	var collider = %Eyecast.get_collider()
	if collider != null and collider.has_method("mouseover_description"):
		%Tooltip.text = collider.mouseover_description()
		%Tooltip.visible = true
	else:
		%Tooltip.visible = false
	
func try_press() -> void:
	var collider = %Eyecast.get_collider()
	if collider != null and collider.has_method("press"):
		collider.press()
