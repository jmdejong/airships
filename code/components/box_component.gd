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
	var c: CollisionShape3D = $CollisionShape3D.duplicate()
	c.set_meta("component", self)
	c.transform = transform * c.transform
	return [c]

func block_components() -> Dictionary[Vector3, Node3D]:
	var d: Dictionary[Vector3, Node3D]
	var aabb: AABB = transform * $CollisionShape3D.transform * AABB(-$CollisionShape3D.size / 2.0, $CollisionShape3D.size) / Global.block_size
	for x in range(aabb.position.x, aabb.end.x + 1):
		for y in range(aabb.position.y, aabb.end.y + 1):
			for z in range(aabb.position.z, aabb.end.z + 1):
				d[Vector3(x, y, z)/2.0] = self
	return d
