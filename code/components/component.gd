class_name Component
extends Node3D

@warning_ignore("unused_signal")
signal changed

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

func conduct_signal() -> bool:
	return false

func accept_signal() -> bool:
	return false
