extends Node3D

signal changed

@export var density = 10
@onready var volume = _calculate_volume()

func _calculate_volume() -> float:
	var size: Vector3 = $CollisionShape3D.shape.size * $CollisionShape3D.scale * scale
	return size.x * size.y * size.z

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return density * volume
	
func center_of_mass() -> Vector3:
	return transform * $CenterOfMass.position

func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			var c: CollisionShape3D = child.duplicate()
			c.transform = transform * c.transform
			s.append(c)
	return s
