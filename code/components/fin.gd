@tool
class_name Fin
extends BaseComponent

@export var density: float = 4
@export var thickness: float = 0.5
@export var surface_area: float = 72 # m^2


var previous_position: Vector3

func mass() -> float:
	return surface_area * thickness * density

func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var velocity: Vector3 = -($CenterOfMass.to_local(previous_position)) / delta
	previous_position = $CenterOfMass.global_position
	var relative_air_velocity: Vector3 = -velocity
	#var air_particle_force: float = relative_air_velocity.z * 2
	#var air_volume: float = absf(relative_air_velocity.z) * surface_area
	#var f: float = air_particle_force * air_volume * Atmosphere.air_density(global_position.y)
	var v: float = -relative_air_velocity.z
	var f: float = 0.5 \
		* Atmosphere.air_density($CenterOfMass.position) \
		* v \
		* relative_air_velocity.length() \
		* surface_area
	var force := Vector3(0, 0, -f)
	#var force: Force = Force.new($CenterOfMass.position, Vector3(0, 0, 1), f)
	%ForceIndicator.global_position = $CenterOfMass.global_position + $CenterOfMass.global_basis * (force / 40)
	%WindIndicator.position = relative_air_velocity * 2
	var ship: Airship = get_ship()
	ship.apply_force($CenterOfMass.global_basis * force, $CenterOfMass.global_position - ship.global_position)
