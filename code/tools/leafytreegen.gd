@tool
extends MeshInstance3D

@export var stem_height = 10
@export var stem_radius = 0.5
@export var leaf_radius = 4
@export var stem_material: BaseMaterial3D
@export var leaf_material: BaseMaterial3D
@export var leaf_quad_width: float = 4
#var leaf_quad_height: float = leaf_quad_width
@export_tool_button("generate") var generate_action: Callable = generate_leafy_tree


func clear() -> void:
	for child: Node in get_children():
		child.queue_free()

func generate_leafy_tree() -> void:
	clear()
	leaf_material.albedo_texture = %Leafgen.generate()
	var base := CSGCombiner3D.new()
	var stem := CSGCylinder3D.new()
	stem.height = stem_height + 1
	stem.radius = stem_radius
	stem.material = stem_material
	stem.position = Vector3(0, (stem_height + 1) / 2.0, 0)
	base.add_child(stem)
	await get_tree().process_frame
	await get_tree().process_frame
	var mesh: ArrayMesh = base.bake_static_mesh()
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	surface_array[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	surface_array[Mesh.ARRAY_INDEX] = PackedInt32Array()
	
	var max_leaf_clusters: int = 64
	for i in max_leaf_clusters:
		var fi: float = float(i) / float(max_leaf_clusters)
		var y: float = stem_height * (0.5 + fi)
		var dist: float = -4*fi*(fi-1) * leaf_radius
		var dir = randf() * TAU
		make_leaf_cluster(Vector3(sin(dir) * dist, y, cos(dir)*dist), Vector3(0, stem_height, 0), surface_array)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	mesh.surface_set_material(mesh.get_surface_count()-1, leaf_material)
	self.mesh = mesh

func make_leaf_cluster(pos: Vector3, center: Vector3, surface_array: Array) -> void:
	var vertices: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = surface_array[Mesh.ARRAY_TEX_UV]
	var normals: PackedVector3Array = surface_array[Mesh.ARRAY_NORMAL]
	
	var normal: Vector3 = center.direction_to(pos)
	var basis := Basis.from_euler(Vector3(randf(), randf(), randf()) * TAU)
	for axis: Vector3 in [basis.x.normalized(), basis.y.normalized(), basis.z.normalized()]:
		var reference := Vector3.UP
		if abs(axis.dot(reference)) > 0.99:
			reference = Vector3.RIGHT

		var leaf_quad_height := leaf_quad_width
		var right := reference.cross(axis).normalized() * leaf_quad_width * 0.5
		var up := axis.cross(right).normalized() * leaf_quad_height * 0.5

		var vs := vertices.size()
		var verts := PackedVector3Array([
			pos - right - up,
			pos + right - up,
			pos + right + up,
			pos - right + up,
		])

		vertices.append_array(verts)
		for v: Vector3 in verts:
			normals.append(center.direction_to(v))
		uvs.append_array(PackedVector2Array([
				Vector2(0, 1),
				Vector2(1, 1),
				Vector2(1, 0),
				Vector2(0, 0)
		]))
		indices.append_array(PackedInt32Array([
			vs, vs+1, vs+2,
			vs, vs+2, vs+3,
			vs, vs+2, vs+1,
			vs, vs+3, vs+2
		]))
	
func make_tube(nodes: PackedVector4Array, radial_segments: int, surface_array: Array) -> void:
	var vertices: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = surface_array[Mesh.ARRAY_TEX_UV]
	var normals: PackedVector3Array = surface_array[Mesh.ARRAY_NORMAL]
	var verts_per_ring := radial_segments + 1
	var ort := Vector3.ZERO
	for h in len(nodes):
		var node: Vector4 = nodes[h]
		var pos := Vector3(node.x, node.y, node.z)
		var r: float = node.w
		var vs: int = len(vertices)
		var axis := Vector3(0, 0, 0)
		if h > 0:
			var prev: Vector4 = nodes[h-1]
			axis += (pos - Vector3(prev.x, prev.y, prev.z)).normalized()
		if h+1 < len(nodes):
			var next: Vector4 = nodes[h-1]
			axis += (Vector3(next.x, next.y, next.z) - pos).normalized()
		axis = axis.normalized()
		
		if ort == Vector3.ZERO:
			var basevert := Vector3(0, 1, 0)
			if abs(axis.y) > 0.95:
				basevert = Vector3(1, 0, 0)
			ort = basevert.cross(axis).normalized()
		else:
			ort = -ort.cross(axis).cross(axis).normalized()
		
		for i in range(verts_per_ring):
			var angle: float = i * 2 * PI / radial_segments
			var dvert: Vector3 = ort.rotated(axis, angle)
			vertices.append(dvert * r + pos)
			normals.append(dvert.normalized())
			uvs.append(Vector2(float(i) / radial_segments, float(h) / (len(nodes) - 1)))
		if h != 0:
			for i in range(radial_segments):
				var n: int = vs + i
				indices.append(n)
				indices.append(n+1)
				indices.append(n-verts_per_ring)
				indices.append(n-verts_per_ring)
				indices.append(n+1)
				indices.append(n+1-verts_per_ring)
		
