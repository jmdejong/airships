extends Node3D

signal changed

var radius = 10
var volume = 4.0/3 * PI * radius * radius * radius

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return 10

func center_of_mass() -> Vector3:
	return $CenterOfMass.position

func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			s.append(child)
	return s
