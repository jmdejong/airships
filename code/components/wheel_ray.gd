extends RayCast3D

var ship: Airship
@export var rest_distance: float = 0.38
@export var damping: float = 1000
@export var spring_strength: float = 30000
@export var grip: float = 1
@export var roll_friction: float = 0.01

func _physics_process(_delta: float) -> void:
	if ship == null:
		return
	var relative_velocity: Vector3 = ship.linear_velocity + ship.angular_velocity.cross(global_position - ship.global_position)
	var local_velocity: Vector3 = global_basis.inverse() * relative_velocity
	var force: Vector3 = Vector3(
		-local_velocity.x * grip * ship.mass,
		0,
		-local_velocity.z * roll_friction * ship.mass
	) + calculate_suspension_force(local_velocity)
	ship.apply_force(global_basis * force, global_position - ship.global_position)

func calculate_suspension_force(local_velocity: Vector3) -> Vector3:
	if not is_colliding():
		return Vector3.ZERO
	var collision_point: Vector3 = get_collision_point()
	var collision_distance: float = collision_point.distance_to(global_position)
	var suspend_offset: float = rest_distance - collision_distance
	var speed_on_string: float = -local_velocity.y
	var spring_force: float = suspend_offset * spring_strength + speed_on_string * damping
	return max(0, spring_force) * get_collision_normal()
