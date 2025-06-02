class_name BaseComponent
extends Node3D

signal changed

var mass_: float
var volume: float

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return mass_
	
func center_of_mass() -> Vector3:
	return transform * $CenterOfMass.position

func shapes() -> Array[CollisionShape3D]:
	var c: CollisionShape3D = $CollisionShape3D.duplicate()
	c.set_meta("component", self)
	c.transform = transform * c.transform
	return [c]
