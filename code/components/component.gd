@abstract
class_name Component
extends Node3D

@warning_ignore("unused_signal")
signal changed_physics
@warning_ignore("unused_signal")
signal changed_shapes

@export var ctyp: String

var mooring_point: Node3D = null

@abstract
func physics_properties() -> PhysicsProperties

func shapes() -> Array[CShape]:
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
	if ctyp == null || ctyp == "":
		push_error("Failed to serialize component " + name + ": no type known")
		return {}
	var json: Dictionary[String, Variant] = {
		"_ct": ctyp,
		"_n" : name,
		"_p": [position.x, position.y, position.z],
		"_r": [rotation.x, rotation.y, rotation.z]
	}
	json.merge(to_own_json())
	return json

@abstract
func to_own_json() -> Dictionary[String, Variant]

@abstract
func initialize_from_json(json: Dictionary) -> void

class CShape extends RefCounted:
	var transform: Transform3D
	var shape: Shape3D
	var component: Component
	
	func _init(transform_: Transform3D, shape_: Shape3D, component_: Component) -> void:
		transform = transform_
		shape = shape_
		component = component_
	
	func transformed(new_transform: Transform3D) -> CShape:
		return CShape.new(new_transform * transform, shape, component)

#@abstract func connections() -> Array[Vector3]
