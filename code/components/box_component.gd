extends Node3D

@export var density = 10
@onready var volume = _calculate_volume()

func _calculate_volume() -> float:
	var size: Vector3 = $CollisionShape3D.shape.size * $CollisionShape3D.scale * scale
	return size.x * size.y * size.z

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return density * volume
	
