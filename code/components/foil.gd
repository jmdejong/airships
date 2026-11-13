extends Node3D

var ship: Airship
@export var surface_area: float

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or ship == null or surface_area <= 0:
		return
	var force := calculate_wing_force()
	#var force := calculate_fin_force()
	$ForceIndicator.global_position = global_position + (force * 10.0 / ship.mass)
	
	ship.apply_force(force, global_position - ship.global_position)

func calculate_fin_force() -> Vector3:
	var local_air_velocity: Vector3 = global_basis.inverse() * relative_air_velocity()
	var v: float = local_air_velocity.y
	var f: float = 0.5 \
		* Atmosphere.air_density(global_position) \
		* v \
		* local_air_velocity.length() \
		* surface_area
	return global_basis * Vector3(0, f, 0)

func calculate_wing_force() -> Vector3:
	var air_velocity: Vector3 = global_basis.inverse() * relative_air_velocity()
	var air_speed_sq: float = air_velocity.length_squared()
	if air_speed_sq < 0.01:
		return Vector3.ZERO
	var air_direction: Vector3 = air_velocity.normalized()
	
	var angle_of_attack: float = asin(clamp(air_direction.y, -1.0, 1.0))
	
	var lift_slope: float = 4.0 # Not very exact
	var stall_angle: float = deg_to_rad(15.0)
	var stall_effect: float = clampf(rad_to_deg(abs(angle_of_attack) - stall_angle) / 2.0, 0.0, 1.0)
	var lift_coefficient: float = lift_slope * lerpf(angle_of_attack, sign(angle_of_attack) * stall_angle * 0.5, stall_effect)
	
	var dynamic_pressure = 0.5 * Atmosphere.air_density(global_position) * air_speed_sq
	
	var lift_mag: float = dynamic_pressure * surface_area * lift_coefficient
	var lift_force: Vector3 = Vector3(0, lift_mag, 0)
	
	# Drag: Parasitic drag + Induced drag (proportional to cl^2)
	var drag_coefficient: float = 0.02 + (lift_coefficient * lift_coefficient * 0.1) 
	var drag_mag: float = dynamic_pressure * surface_area * drag_coefficient
	var drag_force: Vector3 = air_direction * drag_mag

	var local_force: Vector3 = lift_force + drag_force
	return global_basis * local_force

func relative_air_velocity() -> Vector3:
	var velocity: Vector3 = ship.linear_velocity + ship.angular_velocity.cross(global_position - ship.global_position)
	return Atmosphere.wind_velocity(global_position) - velocity
