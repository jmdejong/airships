extends Node3D

signal changed

var previous_position: Vector3

func _physics_process(delta: float) -> void:
	var velocity = (global_position - previous_position) / delta
	previous_position = global_position
	%Dashboard.text = "Altitude: %4.1f m\nAir: %2.2f kg/m^3\nHor speed: %2.2f m/s\nVert speed: %2.2f m/s" % [
		global_position.y,
		 Atmosphere.air_density($%Dashboard.global_position.y),
		Vector2(velocity.x, velocity.z).length(),
		velocity.y
	]

func displaced_volume() -> float:
	return 0.01

func mass() -> float:
	return 20
	

func center_of_mass() -> Vector3:
	return $CenterOfMass.position

func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			s.append(child)
	return s
