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

func preview() -> Preview:
	var node: Preview = preload("res://scenes/preview.tscn").instantiate()
	var meshes: Array[MeshInstance3D] = []
	var collisions: Array[CollisionShape3D] = []
	calculate_child_shapes(self, Transform3D.IDENTITY, meshes, collisions)
	for mesh: MeshInstance3D in meshes:
		mesh.add_to_group("visual")
		node.add_child(mesh)
	for shape: CollisionShape3D in collisions:
		node.add_child(shape)
	if has_node("Connection"):
		for connection_shape: CollisionShape3D in $Connection.get_children():
			var shape: CollisionShape3D = connection_shape.duplicate()
			shape.transform = $Connection.transform * shape.transform
			node.get_node("Connection").add_child(shape)
	return node

func calculate_child_shapes(node: Node3D, tf: Transform3D, meshes: Array[MeshInstance3D], collisions: Array[CollisionShape3D]):
	if !node.visible or node is CollisionObject3D and node != self:
		return
	if node is MeshInstance3D:
		var mesh: MeshInstance3D = MeshInstance3D.new()
		mesh.transform = tf
		mesh.mesh = node.mesh.duplicate()
		meshes.append(mesh)
	if node is CollisionShape3D:
		var shape: CollisionShape3D = CollisionShape3D.new()
		shape.transform = tf
		shape.scale *= 0.99
		shape.shape = node.shape.duplicate()
		collisions.append(shape)
	for child in node.get_children():
		if child is Node3D:
			calculate_child_shapes(child, tf * child.transform, meshes, collisions)
