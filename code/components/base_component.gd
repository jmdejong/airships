class_name BaseComponent
extends Component


@export var mass_: float
@export var volume: float

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return mass_
	
func center_of_mass() -> Vector3:
	return transform * $CenterOfMass.position

func center_of_volume() -> Vector3:
	return center_of_mass()

func physics_properties() -> PhysicsProperties:
	return PhysicsProperties.new(mass(), center_of_mass(), displaced_volume(), center_of_volume())

func shapes() -> Array[CollisionShape3D]:
	var collisionshapes: Array[CollisionShape3D] = []
	for child: Node in get_children():
		if child is CollisionShape3D && !child.disabled:
			var c: CollisionShape3D = child.duplicate()
			for inner_child: Node in c.get_children():
				c.remove_child(inner_child)
			c.set_meta("component", self)
			c.transform = transform * c.transform
			collisionshapes.append(c)
	return collisionshapes

func destroy(_where: Vector3) -> void:
	if get_parent() == null:
		return
	get_parent().remove_child(self)
	changed_physics.emit()
	changed_forces.emit()
	changed_shapes.emit()
	queue_free()

func all_components() -> Array[Component]:
	return [self]

func connected_components() -> Array[Component]:
	var connected: Array[Component] = []
	connected.assign($Connection.get_overlapping_areas().map(func(area): return area.get_parent()))
	return connected
