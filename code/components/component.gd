class_name Component
extends Node3D

func physics_properties() -> PhysicsProperties:
	assert(false, "Abstract method")
	return null

func forces() -> Array[Force]:
	return []

func shapes() -> Array[CollisionShape3D]:
	return []
