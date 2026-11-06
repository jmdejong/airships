@tool
extends MeshInstance3D

@export var stem_height = 10
@export var stem_radius = 0.5
@export var stem_width: Curve
@export var stem_material: BaseMaterial3D
@export var leaf_material: Material
@export var leaf_quad_width: float = 4
@export var leaf_quad_count: int = 256
@export var leaf_rad: float = 5
@export var filename: String = "tree.mesh"
#var leaf_quad_height: float = leaf_quad_width
@export_tool_button("generate") var generate_action: Callable = generate_leafy_tree



func generate_leafy_tree() -> void:
	%Leafgen.generate()
	
	var tree_mesh: ArrayMesh = ArrayMesh.new()
	
	var stem_surface: Array = create_surface_array()
	
	make_tube(PackedVector4Array([
		Vector4(0, -1, 0, stem_radius * 2),
		Vector4(0, stem_height * 0.1, 0, stem_radius * 1.2),
		Vector4(0, stem_height * 0.9, 0, stem_radius * 0.6),
		Vector4(0, stem_height * 1.1, 0, 0)
	]), 7, stem_surface)
	tree_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, stem_surface)
	tree_mesh.surface_set_material(tree_mesh.get_surface_count()-1, stem_material)
	
	
	var leaf_surface: Array = create_surface_array()
	make_leaf_cluster_around(Vector3(0, stem_height, 0), leaf_rad, leaf_quad_count, leaf_surface)
	tree_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, leaf_surface)
	tree_mesh.surface_set_material(tree_mesh.get_surface_count()-1, leaf_material)
	self.mesh = tree_mesh
	ResourceSaver.save(tree_mesh, "res://models/generated/" + filename)

func create_surface_array() -> Array:
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = PackedVector3Array()
	surface_array[Mesh.ARRAY_NORMAL] = PackedVector3Array()
	surface_array[Mesh.ARRAY_TEX_UV] = PackedVector2Array()
	surface_array[Mesh.ARRAY_INDEX] = PackedInt32Array()
	return surface_array

const golden_angle := PI * (3.0 - sqrt(5.0))

func make_leaf_cluster_around(center: Vector3, leaf_radius: float, leaf_count: int, surface_array: Array) -> void:
	for i in leaf_count:
		var cos_theta: float= 2.0 * (i+randf()) / float(leaf_count) - 1.0
		var phi: float = i * golden_angle
		var sin_theta := sqrt(1.0 - cos_theta * cos_theta)
		var dir := Vector3(sin_theta * cos(phi), sin_theta * sin(phi), cos_theta)
		var radius: float = pow(randf(), 0.2)
		var pos: Vector3 = center + dir * radius * leaf_radius
		make_leaf_quad(pos, center, surface_array)


func make_leaf_quad(pos: Vector3, center: Vector3, surface_array: Array) -> void:
	var vertices: PackedVector3Array = surface_array[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = surface_array[Mesh.ARRAY_INDEX]
	var uvs: PackedVector2Array = surface_array[Mesh.ARRAY_TEX_UV]
	var normals: PackedVector3Array = surface_array[Mesh.ARRAY_NORMAL]
	
	var axis := Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized()
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
		#vs, vs+2, vs+1,
		#vs, vs+3, vs+2
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
			var next: Vector4 = nodes[h+1]
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
				if r > 0:
					indices.append(n)
					indices.append(n+1)
					indices.append(n-verts_per_ring)
				indices.append(n-verts_per_ring)
				indices.append(n+1)
				indices.append(n+1-verts_per_ring)
		
