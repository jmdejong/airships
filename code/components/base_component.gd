class_name BaseComponent
extends Component

signal changed

var mass_: float
var volume: float
var ship: Airship

func displaced_volume() -> float:
	return volume

func mass() -> float:
	return mass_
	
func center_of_mass() -> Vector3:
	return transform * $CenterOfMass.position

func shapes() -> Array[CollisionShape3D]:
	var collisionshapes: Array[CollisionShape3D] = []
	for child: Node in get_children():
		if child is CollisionShape3D:
			var c: CollisionShape3D = child.duplicate()
			c.set_meta("component", self)
			c.transform = transform * c.transform
			collisionshapes.append(c)
	return collisionshapes

func destroy(_where: Vector3) -> void:
	if get_parent() == null:
		return
	get_parent().remove_child(self)
	changed.emit()
	queue_free()

func all_components() -> Array[Component]:
	return [self]

func connected_components() -> Array[Component]:
	var connected: Array[Component] = []
	connected.assign($Connection.get_overlapping_areas().map(func(area): return area.get_parent()))
	return connected
