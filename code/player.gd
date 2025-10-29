class_name Player
extends RigidBody3D

const MOUSE_SENSITIVITY: float = 0.003
const speed: float = 5
const sprint_multiplier: float = 10
const ultra_sprint_multiplier: float = 100
const jump_speed: float = 4
const walk_force: float = 1000

var mouse_motion: Vector2 = Vector2.ZERO
var used_platform: RigidBody3D = null
var platform_movement: Vector3 = Vector3.ZERO
var last_since_floor: float = 0
var was_on_ground := false
const last_since_floor_max: float = 5
var specific_info: String = ""

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

enum Posture {Standing, Sitting, FlyDebug}
var posture: Posture = Posture.Standing:
	set(v):
		if posture == v:
			return
		posture = v
		if posture == Posture.Standing:
			gravity_scale = 1
			was_on_ground = false
		if posture == Posture.FlyDebug:
			gravity_scale = 0
var seat: Seat = null


func _ready() -> void:
	build_separation_rays()

func build_separation_rays() -> void:
	var shape: SeparationRayShape3D = SeparationRayShape3D.new()
	shape.slide_on_slope = true
	shape.length = 0.55
	var offset: Vector3 = Vector3($StandShape.shape.radius + 0.1, 0.55, 0)
	var nrays: int = 48
	for i in nrays:
		var col: CollisionShape3D = CollisionShape3D.new()
		col.shape = shape
		col.position = offset.rotated(Vector3.UP, 2 * PI * float(i) / float(nrays))
		col.rotate_x(PI/2.0)
		add_child(col)


func adjust_direction() -> void:
	var down = get_gravity()
	if down.length_squared() == 0:
		down = Vector3(0, -1, 0)
	look_at(global_position + (quaternion * Vector3.RIGHT).cross(down).normalized(), -down.normalized())
	
func _physics_process(delta: float) -> void:
	last_since_floor += delta
	if last_since_floor >= last_since_floor_max:
		used_platform = null
	if posture == Posture.Sitting:
		seat.handle_player_input(delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if mouse_motion != Vector2.ZERO:
		$Head.rotation.x = clamp($Head.rotation.x - mouse_motion.y * MOUSE_SENSITIVITY, -PI/2, PI/2)
		rotate_y(-mouse_motion.x * MOUSE_SENSITIVITY)
		mouse_motion = Vector2.ZERO
	
	var input_movement: Vector2 = Input.get_vector("left", "right", "forwards", "backwards")
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * speed) \
		.rotated(Vector3(0, 1, 0), rotation.y)
	
	if posture == Posture.FlyDebug:
		movement.y = Input.get_axis("down", "up") * speed
		if Input.is_action_pressed("sprint"):
			movement *= sprint_multiplier
		if Input.is_action_pressed("ultrasprint"):
			movement *= ultra_sprint_multiplier
		linear_velocity = movement
		specific_info = ""
	elif posture == Posture.Standing:
		move_around(state, movement)
	elif posture == Posture.Sitting:
		global_position = seat.seat_position()
		linear_velocity = seat.get_component().get_ship().linear_velocity
		specific_info = ""
	
	%Info.text = "fps: %3.1f\nspeed: %1.1f m/s\n(%3.1f, %3.1f, %3.1f)\n%3.1fK %3.1fkPa %1.2fkg/m^3\nground: %s\n%s" % [
		Engine.get_frames_per_second(),
		Vector2(linear_velocity.x, linear_velocity.z).length(),
		position.x,
		position.y,
		position.z,
		Atmosphere.temperature(position.y),
		Atmosphere.pressure(position.y) / 1000,
		Atmosphere.air_density(position.y),
		was_on_ground,
		specific_info
	]

func _process(_delta: float) -> void:
	try_interact()
	if mouse_mode == MouseMode.Build:
		%BuildCast.place_preview()

func move_around(state: PhysicsDirectBodyState3D, movement: Vector3) -> void:
	var is_on_ground: bool = false#%GroundCheck.get_collision_count() > 0
	var contact_point = null
	for i in state.get_contact_count():
		var ground_angle: float = state.get_contact_local_normal(i).normalized().angle_to(Vector3.UP) / PI * 180.0
		if ground_angle < 45:
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
		
	var desired_velocity: Vector3 = floor_movement + movement
	var deltav: Vector3 = desired_velocity - linear_velocity
	deltav.y = 0
	if is_on_ground:
		physics_material_override.friction = 1.0
		var force: Vector3 = deltav * mass * 10
		apply_force(force, contact_point - global_position)
		if used_platform != null:
			used_platform.apply_force(-force, contact_point - used_platform.global_position)
		var platform_velocity = Vector3.ZERO
		if used_platform != null:
			platform_velocity = used_platform.linear_velocity
		if Input.is_action_pressed("up") and was_on_ground and linear_velocity.y - platform_velocity.y < 1.0:
			var jump_strength: Vector3 = Vector3(0, 350, 0)
			apply_impulse(jump_strength, contact_point - global_position)
			if used_platform != null:
				used_platform.apply_impulse(-jump_strength, contact_point - used_platform.global_position)
		was_on_ground = true
	else:
		physics_material_override.friction = 0.0
		was_on_ground = false
		apply_central_force(deltav * mass * 0.5)
	specific_info = "%3.2f" % [deltav.length()]

func _unhandled_input(event: InputEvent):
	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		mouse_motion += event.relative
	
	if posture == Posture.Sitting && Input.is_action_just_pressed("stand_up"):
			stand_up.call_deferred()
	if Input.is_action_just_pressed("toggle_gravity"):
		if posture == Posture.Standing:
			posture = Posture.FlyDebug
		elif posture == Posture.FlyDebug:
			posture = Posture.Standing
	
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
		mouse_mode = mouse_mode
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
	
	if Input.is_action_just_pressed("switch_render"):
		var vp := get_viewport()
		vp.debug_draw = (vp.debug_draw + 1) % 6 as Viewport.DebugDraw


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
		collider.press(self)

func _on_build_tab_select_build(component: ComponentBlueprint) -> void:
	mouse_mode = MouseMode.Build
	%BuildCast.select_build(component)

func _on_build_tab_select_remove() -> void:
	mouse_mode = MouseMode.Remove

func sit(seat: Seat) -> void:
	posture = Posture.Sitting
	self.seat = seat
	global_position = seat.seat_position()
	$StandShape.disabled = true
	$SitShape.disabled = false
	for child: CollisionShape3D in get_children().filter(func(c: Node): return c is CollisionShape3D):
		if child.shape is SeparationRayShape3D:
			child.disabled = true
	$Head.position.y = 0.7

func stand_up() -> void:
	posture = Posture.Standing
	seat = null
	$StandShape.disabled = false
	$SitShape.disabled = true
	for child: CollisionShape3D in get_children().filter(func(c: Node): return c is CollisionShape3D):
		if child.shape is SeparationRayShape3D:
			child.disabled = false
	$Head.position.y = 1.5
	was_on_ground = false
