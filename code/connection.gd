extends Area3D


#func _ready() -> void:
	#connection_points()


func connection_points() -> Array[Vector3]:
	var points: Dictionary[Vector3, bool] = {}
	for child: Node in get_children():
		if not (child is CollisionShape3D):
			continue
		var cs: CollisionShape3D = child
		if cs.shape is SphereShape3D:
			points[as_connection_point(cs.position)] = true
		elif cs.shape is BoxShape3D:
			var a: AABB = AABB(position - cs.shape.size/2, cs.shape.size)
			var ba: AABB = AABB(a.position / Global.block_size, a.size / Global.block_size)
			for x: float in range(ceil(ba.position.x - 0.5), floor(ba.end.x + 0.5)):
				for y: float in range(ceil(ba.position.y - 0.5), floor(ba.end.y + 0.5)):
					points[Vector3(x + 0.5, y + 0.5, ceil(ba.position.z)) * Global.block_size] = true
					points[Vector3(x + 0.5, y + 0.5, floor(ba.end.z)) * Global.block_size] = true
				for z: float in range(ceil(ba.position.z - 0.5), floor(ba.end.z + 0.5)):
					points[Vector3(x + 0.5, ceil(ba.position.y), z + 0.5) * Global.block_size] = true
					points[Vector3(x + 0.5, floor(ba.end.y), z + 0.5) * Global.block_size] = true
			for z: float in range(ceil(ba.position.z - 0.5), floor(ba.end.z + 0.5)):
				for y: float in range(ceil(ba.position.y - 0.5), floor(ba.end.y + 0.5)):
					points[Vector3(ceil(ba.position.x), y + 0.5, z + 0.5) * Global.block_size] = true
					points[Vector3(floor(ba.end.x), y + 0.5, z + 0.5) * Global.block_size] = true
		else:
			push_error("Unsupported connection shape ", cs.shape)

	var pa: Array[Vector3] = []
	pa.append_array(points.keys())
	return pa

func as_connection_point(point: Vector3) -> Vector3:
	return (transform * point).snappedf(Global.block_size/2)
