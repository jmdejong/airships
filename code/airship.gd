extends Node3D

const BASE_AIR_DENSITY := 1.2
var velocity := Vector3(0,0,0)
var wait_time := 0.0

func _physics_process(delta: float) -> void:
	var mass: float = 0
	var displaced_volume: float = 0
	for component in $Components.get_children():
		mass += component.mass()
		displaced_volume += component.displaced_volume()
	var displaced_air_mass := displaced_volume * air_density()
	var weight := mass - displaced_air_mass
	if wait_time < 0:
		prints(displaced_volume, mass, displaced_air_mass, weight)
		wait_time = 5.0
	else:
		wait_time -= delta
	velocity.y = -weight / mass
	position += velocity * delta

func air_density() -> float:
	return BASE_AIR_DENSITY / (1 + 0.1 * position.y)
