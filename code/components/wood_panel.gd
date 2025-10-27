@tool
class_name WoodPanel
extends BaseComponent

@export var density: float = 400
var size_block: Vector3i
@export var size: Vector3 = Vector3.ONE:
	set(val):
		size_block = Vector3(val / Global.block_size)
		size = size_block * Global.block_size
		_update_sizes()


func physics_properties() -> PhysicsProperties:
	return PhysicsProperties.box(transform * (size / 2), size, density)

func _update_sizes() -> void:
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

func destroy(where: Vector3) -> void:
	if get_parent() == null:
		return
	var local_where: Vector3 = where * transform
	var closest: Vector3i = Vector3i(local_where / Global.block_size).clamp(Vector3i.ZERO, size_block - Vector3i.ONE)
	if size_block != Vector3i.ONE:
		var new_components: Array[Component] = []
		for area in subdivide(size, closest * Global.block_size, Global.block_size):
			if area.get_volume() > 0:
				var clone: WoodPanel = duplicate()
				clone.size = area.size
				clone.position = transform * area.position
				new_components.append(clone)
		get_parent().add_components(new_components)
	get_parent().remove_child(self)
	changed_physics.emit()
	changed_shapes.emit()
	queue_free()

func subdivide(size: Vector3, out: Vector3, step: float) -> Array[AABB]:
	var size_before: Vector3 = out
	var size_before_with: Vector3 = size_before + Vector3(step, step, step)
	var size_after: Vector3 = size - size_before_with
	return [
		AABB(Vector3.ZERO, Vector3(size_before.x, size.y, size.z)),
		AABB(Vector3(size_before_with.x, 0, 0), Vector3(size_after.x, size.y, size.z)),
		AABB(Vector3(size_before.x, 0, 0), Vector3(step, size.y, size_before.z)),
		AABB(Vector3(size_before.x, 0, size_before_with.z), Vector3(step, size.y, size_after.z)),
		AABB(Vector3(size_before.x, 0, size_before.z), Vector3(step, size_before.y, step)),
		AABB(Vector3(size_before.x, size_before_with.y, size_before.z), Vector3(step, size_after.y, step))
	]

func _box_shape(size: Vector3) -> BoxShape3D:
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = size
	return bs
