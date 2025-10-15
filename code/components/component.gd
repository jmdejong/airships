class_name Component
extends Node3D

@warning_ignore("unused_signal")
signal changed_physics
@warning_ignore("unused_signal")
signal changed_forces
@warning_ignore("unused_signal")
signal changed_shapes

func physics_properties() -> PhysicsProperties:
	assert(false, "Abstract method")
	return null

func forces() -> Array[Force]:
	return []

func shapes() -> Array[CollisionShape3D]:
	return []

func all_components() -> Array[Component]:
	assert(false, "Abstract method")
	return [self]

func get_ship() -> Airship:
	var parent: Node = get_parent()
	while parent != null and not parent is Airship:
		parent = parent.get_parent()
	return parent
