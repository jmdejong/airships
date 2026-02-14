class_name Player
extends RigidBody3D

const speed: float = 5
const sprint_multiplier: float = 10
const ultra_sprint_multiplier: float = 100
const jump_speed: float = 4
const walk_force: float = 1000

var view_movement: Vector2 = Vector2.ZERO
var used_platform: RigidBody3D = null
var platform_movement: Vector3 = Vector3.ZERO
var last_since_floor: float = 0
var was_on_ground := false
const last_since_floor_max: float = 5
var specific_info: String = ""
@onready var lifeline: Lifeline = $Lifeline

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
		if posture == Posture.Sitting:
			$StandShape.disabled = true
			$SitShape.disabled = false
			for child: CollisionShape3D in get_children().filter(func(c: Node): return c is CollisionShape3D):
				if child.shape is SeparationRayShape3D:
					child.disabled = true
			$Head.position.y = 0.7
			$Lifeline.position.y = 0.1
		else:
			$StandShape.disabled = false
			$SitShape.disabled = true
			for child: CollisionShape3D in get_children().filter(func(c: Node): return c is CollisionShape3D):
				if child.shape is SeparationRayShape3D:
					child.disabled = false
			$Head.position.y = 1.5
			$Lifeline.position.y = 0.8

var seat: Seat = null
var separation_rays: Array[CollisionShape3D] = []

func _ready() -> void:
	build_separation_rays()

func build_separation_rays() -> void:
	var shape: SeparationRayShape3D = SeparationRayShape3D.new()
	shape.slide_on_slope = true
	shape.length = 0.55
	var offset: Vector3 = Vector3($StandShape.shape.radius + 0.03, shape.length-0.03, 0)
	var nrays: int = 48
	for i in nrays:
		var col: CollisionShape3D = CollisionShape3D.new()
		separation_rays.append(col)
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
		global_position = seat.seat_position()
		linear_velocity = seat.get_component().get_ship().linear_velocity
		seat.handle_player_input(delta)

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	specific_info = ""
	if view_movement != Vector2.ZERO:
		$Head.rotation.x = clamp($Head.rotation.x - view_movement.y, -PI/2, PI/2)
		rotate_y(-view_movement.x)
		view_movement = Vector2.ZERO
	
	var input_movement: Vector2 = (Input.get_vector("left", "right", "forwards", "backwards") + %UI.move_joystick.touch_value()).limit_length()
	var movement: Vector3 = (Vector3(input_movement.x, 0, input_movement.y) * speed) \
		.rotated(Vector3(0, 1, 0), rotation.y)
	
	if posture == Posture.FlyDebug:
		movement.y = Input.get_axis("down", "up") * speed
		if Input.is_action_pressed("sprint"):
			movement *= sprint_multiplier
		if Input.is_action_pressed("ultrasprint"):
			movement *= ultra_sprint_multiplier
		linear_velocity = movement
	elif posture == Posture.Standing:
		move_around(state, movement)
	elif posture == Posture.Sitting:
		pass
	
	%UI.set_info_text("fps: %3.1f\nspeed: %1.1f m/s\n(%3.1f, %3.1f, %3.1f)\n%3.1fK %3.1fkPa %1.2fkg/m^3\nground: %s\n%s" % [
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
	])


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
	lifeline.apply(self)
	
	for ray in separation_rays:
		ray.disabled = !(is_on_ground || was_on_ground)


func _unhandled_input(_event: InputEvent):
	if posture == Posture.Sitting && Input.is_action_just_pressed("stand_up"):
			stand_up.call_deferred()
	if Input.is_action_just_pressed("toggle_gravity"):
		if posture == Posture.Standing:
			posture = Posture.FlyDebug
		elif posture == Posture.FlyDebug:
			posture = Posture.Standing


func _process(_delta: float) -> void:
	var collider = %EyeCast.get_collider()
	%UI.show_tooltip(collider)

func try_press() -> void:
	var collider = %EyeCast.get_collider()
	if collider != null and collider.has_method("press"):
		collider.press(self)

func sit(seat: Seat) -> void:
	posture = Posture.Sitting
	self.seat = seat
	global_position = seat.seat_position()

func stand_up() -> void:
	posture = Posture.Standing
	seat = null

func attach_lifeline(anchor: LifeAnchor) -> void:
	lifeline.attach(anchor)

func _on_ui_move_view(delta: Vector2) -> void:
	view_movement += delta
