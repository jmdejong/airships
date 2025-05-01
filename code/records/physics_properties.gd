class_name PhysicsProperties
extends Object


var mass: float
var displaced_volume: float
var center_of_mass: Vector3
var center_of_volume: Vector3

func _init(mass: float, displaced_volume: float, center_of_mass: Vector3, center_of_volume: Vector3, forces: Array[Force] = []) -> void:
	self.mass = mass
	self.displaced_volume = displaced_volume
	self.center_of_mass = center_of_mass
	self.center_of_volume = center_of_volume

static func uniform(volume: float, density: float, center: Vector3) -> PhysicsProperties:
	return PhysicsProperties.new(volume * density, volume, center, center)

func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			s.append(child)
	return s
