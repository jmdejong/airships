class_name PhysicsProperties
extends RefCounted

var mass: float
var center_of_mass: Vector3
var volume: float
var center_of_volume: Vector3

func _init(mass: float, center_of_mass: Vector3, volume: float, center_of_volume: Vector3) -> void:
	self.mass = mass
	self.center_of_mass = center_of_mass
	self.volume = volume
	self.center_of_volume = center_of_volume

static func box(center: Vector3, size: Vector3, density: float) -> PhysicsProperties:
	var volume = size.x * size.y * size.z
	return PhysicsProperties.new(volume * density, center, volume, center)

static func combine(ps: Array[PhysicsProperties]) -> PhysicsProperties:
	var total: PhysicsProperties = PhysicsProperties.new(0, Vector3.ZERO, 0, Vector3.ZERO)
	for p: PhysicsProperties in ps:
		total.mass += p.mass
		total.center_of_mass += p.center_of_mass * p.mass
		total.volume += p.volume
		total.center_of_volume += p.center_of_volume * p.volume
	
	total.center_of_mass /= total.mass
	if !total.center_of_mass.is_finite():
		total.center_of_mass = Vector3.ZERO
	total.center_of_volume /= total.volume
	if !total.center_of_volume.is_finite():
		total.center_of_volume = Vector3.ZERO
	return total

func transformed(t: Transform3D) -> PhysicsProperties:
	return PhysicsProperties.new(mass, t * center_of_mass, volume, t*center_of_volume)
