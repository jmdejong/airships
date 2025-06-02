@tool
class_name WoodPanel
extends BaseComponent

@export var density: float = 100
@export var size: Vector3 = Vector3.ONE:
	set(val):
		size_block = Vector3(val / Global.block_size)
		size = size_block * Global.block_size
		volume = size.x * size.y * size.z
		mass_ = density * volume
		var origin: Vector3 = size / 2.0 - Vector3(0.25, 0.25, 0.25)
		var cs: BoxShape3D = $CollisionShape3D.shape.duplicate()
		cs.size = size
		$CollisionShape3D.shape = cs
		$CollisionShape3D.position = origin
		var ms: BoxMesh = $MeshInstance3D.mesh.duplicate()
		ms.size = size
		$MeshInstance3D.mesh = ms
		$MeshInstance3D.position = origin
		$CenterOfMass.position = origin
var size_block: Vector3i

func _block_positions() -> Array[Vector3]:
	var p: Array[Vector3] = []
	for x: int in size_block.x:
		for y: int in size_block.y:
			for z: int in size_block.z:
				p.append(Vector3(x, y, z) * Global.block_size)
	return p

func destroy(where: Vector3) -> void:
	var local_where: Vector3 = where * transform
	var closest: Vector3
	var closest_score: float = INF
	if size_block != Vector3i.ONE:
		for pos in _block_positions():
			if pos.distance_squared_to(local_where) < closest_score:
				closest = pos
				closest_score = pos.distance_squared_to(local_where)
		for pos in _block_positions():
			if pos == closest:
				continue
			var clone: WoodPanel = duplicate()
			clone.size = Vector3.ONE * Global.block_size
			#clone.get_node().set_meta("component", clone)
			clone.position = transform * pos
			get_parent().add_component(clone)
	get_parent().remove_child(self)
	changed.emit()
	queue_free()
