@abstract
class_name Component
extends Node3D

@warning_ignore("unused_signal")
signal changed_physics
@warning_ignore("unused_signal")
signal changed_forces
@warning_ignore("unused_signal")
signal changed_shapes

@export var typ: String

var mooring_point: Node3D = null

@abstract
func physics_properties() -> PhysicsProperties

func forces() -> Array[Force]:
	return []

func shapes() -> Array[CollisionShape3D]:
	return []

@abstract
func all_components() -> Array[Component]

func get_ship() -> Airship:
	var parent: Node = get_parent()
	while parent != null and not parent is Airship:
		parent = parent.get_parent()
	return parent

func preview() -> Node3D:
	return 

func to_json() -> Dictionary[String, Variant]:
	if typ == null || typ == "":
		push_error("Failed to serialize component " + name + ": no type known")
		return {}
	var json: Dictionary[String, Variant] = {
		"_ct": typ,
		"_n" : name,
		"_p": [position.x, position.y, position.z],
		"_r": [rotation.x, rotation.y, rotation.z]
	}
	json.merge(to_own_json())
	return json

@abstract
func to_own_json() -> Dictionary[String, Variant]

@abstract
func initialize_from_json(json: Dictionary[String, Variant]) -> void
