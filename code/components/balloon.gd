extends Node3D

signal changed

var radius = 10
var volume = 4.0/3 * PI * radius * radius * radius

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return 10

func center_of_mass() -> Vector3:
	return transform * $CenterOfMass.position

func shapes() -> Array[CollisionShape3D]:
	var c: CollisionShape3D = $CollisionShape3D.duplicate()
	c.set_meta("component", self)
	c.transform = transform * c.transform
	return [c]
