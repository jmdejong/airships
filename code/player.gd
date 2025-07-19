extends RigidBody3D

const MOUSE_SENSITIVITY: float = 0.003
const speed: float = 5
const sprint_multiplier: float = 10
const ultra_sprint_multiplier: float = 100
const jump_speed: float = 4
const walk_force: float = 1000

var move_fly: bool = false
var mouse_motion: Vector2 = Vector2.ZERO
var used_platform: RigidBody3D = null
var platform_movement: Vector3 = Vector3.ZERO
var last_since_floor: float = 0
var was_on_ground := false
const last_since_floor_max: float = 5

enum MouseMode {Unfocused, Play, Select, Build, Remove}


var mouse_mode: MouseMode = MouseMode.Unfocused:
	set(value):
		mouse_mode = value
		if value == MouseMode.Unfocused or value == MouseMode.Select:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		$BuildTab.visible = mouse_mode == MouseMode.Select
		%BuildPreview.visible = mouse_mode == MouseMode.Build
		if value == MouseMode.Remove:
			%CrosshairTexture.texture = preload("res://textures/ui/break.png")
		else:
			%CrosshairTexture.texture = preload("res://textures/ui/crosshair.png")

var build_mode: bool = false:
	set(value):
		build_mode = value
		$BuildTab.visible = build_mode
		

signal viewpoint_changed(pos: Vector3)

func adjust_direction() -> void:
	var down = get_gravity()
	if down.length_squared() == 0:
		down = Vector3(0, -1, 0)
	look_at(global_position + (quaternion * Vector3.RIGHT).cross(down).normalized(), -down.normalized())
	
func _physics_process(delta: float) -> void:
	last_since_floor += delta
	if last_since_floor >= last_since_floor_max:
		used_platform = null
func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if mouse_motion != Vector2.ZERO:
		$Head.rotation.x = clamp($Head.rotation.x - mouse_motion.y * MOUSE_SENSITIVITY, -PI/2, PI/2)
		rotate_y(-mouse_motion.x * MOUSE_SENSITIVITY)
		mouse_motion = Vector2.ZERO
	
	var is_on_ground: bool = false#%GroundCheck.get_collision_count() > 0
	var contact_point = null
	for i in state.get_contact_count():
		if state.get_contact_local_normal(i).y > 0.7:# and state.get_contact_local_position(i).y < 0.2:
			is_on_ground = true
			var o: Node3D = state.get_contact_collider_object(i)
			contact_point = state.get_contact_collider_position(i)
			if o is RigidBody3D:
				used_platform = o
				platform_movement = o.linear_velocity
				last_since_floor = 0
				break
			else:
				used_platform = null
	var floor_movement: Vector3 = Vector3.ZERO
	if used_platform != null:
		floor_movement = platform_movement * (last_since_floor_max - last_since_floor) / last_since_floor_max
	var input_movement: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * speed) \
		.rotated(Vector3(0, 1, 0), rotation.y)
		
	var desired_velocity: Vector3 = floor_movement + movement
	var deltav: Vector3 = desired_velocity - linear_velocity
	if move_fly:
		desired_velocity.y = Input.get_axis("down", "up") * speed
		if Input.is_action_pressed("sprint"):
			desired_velocity *= sprint_multiplier
		if Input.is_action_pressed("ultrasprint"):
			desired_velocity *= ultra_sprint_multiplier
		linear_velocity = desired_velocity
	else:
		deltav.y = 0
		if is_on_ground:
			var force: Vector3 = deltav * mass * 10
			apply_force(force, contact_point - global_position)
			if used_platform != null:
				used_platform.apply_force(-force, contact_point - used_platform.global_position)
			if Input.is_action_pressed("up") and was_on_ground:
				var jump_strength: Vector3 = Vector3(0, 200, 0)
				apply_impulse(jump_strength, contact_point - global_position)
				if used_platform != null:
					used_platform.apply_impulse(-jump_strength, contact_point - used_platform.global_position)
			was_on_ground = true
		else:
			was_on_ground = false
			apply_central_force(deltav * mass * 0.5)
	
	%Info.text = "speed: %1.1f m/s\n%1.1f\n%1.1f" % [
		Vector2(linear_velocity.x, linear_velocity.z).length(),
		Vector2(desired_velocity.x, desired_velocity.z).length(),
		Vector2(deltav.x, deltav.z).length()
	]
	
	try_interact()
	if mouse_mode == MouseMode.Build:
		%BuildCast.place_preview()
	
	viewpoint_changed.emit(position)

func _unhandled_input(event: InputEvent):
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion += event.relative
	
	if Input.is_action_just_pressed("toggle_gravity"):
		move_fly = !move_fly
		gravity_scale = float(!move_fly)
	
	if Input.is_action_just_pressed("toggle_build"):
		if mouse_mode == MouseMode.Select:
			mouse_mode = MouseMode.Play
		else:
			mouse_mode = MouseMode.Select
	
	if mouse_mode == MouseMode.Build:
		if Input.is_action_just_released("rotate_left"):
			%BuildCast.rotation_mode += 1
			prints("rotate left", %BuildCast.rotation_mode)
		if Input.is_action_just_released("rotate_right"):
			%BuildCast.rotation_mode -= 1
			prints("rotate_right", %BuildCast.rotation_mode)
	
	# Capturing/Freeing the cursor
	if Input.is_action_just_pressed("escape"):
		mouse_mode = MouseMode.Unfocused
	if Input.is_action_just_pressed("click"):
		if mouse_mode == MouseMode.Play:
			try_press()
		elif mouse_mode == MouseMode.Build:
			%BuildCast.try_build()
		elif mouse_mode == MouseMode.Remove:
			%BuildCast.try_remove()
		else:
			mouse_mode = MouseMode.Play
	if Input.is_action_just_pressed("cancel_click"):
		mouse_mode = MouseMode.Play


func try_interact() -> void:
	var collider = %EyeCast.get_collider()
	if collider != null and collider.has_method("mouseover_description") and mouse_mode == MouseMode.Play:
		%Tooltip.text = collider.mouseover_description()
		%Tooltip.visible = true
	else:
		%Tooltip.visible = false

	
func try_press() -> void:
	var collider = %EyeCast.get_collider()
	if collider != null and collider.has_method("press"):
		collider.press()

func _on_build_tab_select_build(component: ComponentBlueprint) -> void:
	mouse_mode = MouseMode.Build
	%BuildCast.select_build(component)


func _on_build_tab_select_remove() -> void:
	mouse_mode = MouseMode.Remove
