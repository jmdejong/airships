@tool
class_name WoodPanel
extends BaseComponent

@export var density: float = 100
var size_block: Vector3i
@export var size: Vector3 = Vector3.ONE:
	set(val):
		size_block = Vector3(val / Global.block_size)
		size = size_block * Global.block_size
		_update_sizes()

func _update_sizes() -> void:
		volume = size.x * size.y * size.z
		mass_ = density * volume
		var origin: Vector3 = size / 2.0
		$CollisionShape3D.shape = _box_shape(size)
		$CollisionShape3D.position = origin
		var ms: BoxMesh = $MeshInstance3D.mesh.duplicate()
		ms.size = size
		$MeshInstance3D.mesh = ms
		$MeshInstance3D.position = origin
		$CenterOfMass.position = origin
		$Connection.position = origin
		$Connection/CollisionShapeX.shape = _box_shape(size + Vector3(0.1, -0.2, -0.2))
		$Connection/CollisionShapeY.shape = _box_shape(size + Vector3(-0.2, 0.1, -0.2))
		$Connection/CollisionShapeZ.shape = _box_shape(size + Vector3(-0.2, -0.2, 0.1))

func _block_positions() -> Array[Vector3]:
	var p: Array[Vector3] = []
	for x: int in size_block.x:
		for y: int in size_block.y:
			for z: int in size_block.z:
				p.append(Vector3(x, y, z) * Global.block_size)
	return p

func destroy(where: Vector3) -> void:
	if get_parent() == null:
		return
	var local_where: Vector3 = where * transform
	var closest: Vector3
	var closest_score: float = INF
	if size_block != Vector3i.ONE:
		for pos: Vector3 in _block_positions():
			var center: Vector3 = pos + Global.block_center
			if center.distance_squared_to(local_where) < closest_score:
				closest = pos
				closest_score = center.distance_squared_to(local_where)
		var new_components: Array[Component] = []
		for pos in _block_positions():
			if pos == closest:
				continue
			var clone: WoodPanel = duplicate()
			clone.size = Vector3.ONE * Global.block_size
			#clone.get_node().set_meta("component", clone)
			clone.position = transform * pos
			new_components.append(clone)
		get_parent().add_components(new_components)
	get_parent().remove_child(self)
	changed_physics.emit()
	changed_shapes.emit()
	queue_free()

func _box_shape(size: Vector3) -> BoxShape3D:
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = size
	return bs
