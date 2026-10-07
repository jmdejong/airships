extends Node

const face_level: int = 5
const face_segments: int = 2**face_level

@onready var default_mesh: Mesh = _build_mesh(0)
@onready var meshes: Array[Mesh] = _build_all_meshes()

func mesh_for(xlo: bool, ylo: bool, xhi: bool, yhi: bool) -> Mesh:
	return meshes[int(xlo) + 2*int(ylo) + 4*int(xhi) + 8*int(yhi)]

#func _encode_neighbours(xlo: bool, ylo: bool, xhi: bool, yhi: bool) -> int:
	#return int(xlo) + 2*int(ylo) + 4*int(xhi) + 8*int(yhi)

func _build_all_meshes() -> Array[Mesh]:
	var m: Array[Mesh] = []
	for i in 16:
		m.append(_build_mesh(i))
	return m

func _build_mesh(border_code: int) -> Mesh:
	var w: int = face_segments + 1
	var vertices := PackedVector3Array()
	vertices.resize(w*w)
	for x: int in w:
		for y: int in w:
			vertices[x + y*w] = Vector3(float(x)/face_segments - 0.5, 0, float(y)/face_segments - 0.5)
	var indices := PackedInt32Array()
	_add_core_indices(indices)
	_add_border_indices(indices, border_code)
	var mesh := ArrayMesh.new()
	var surface = []
	surface.resize(Mesh.ARRAY_MAX)
	surface[Mesh.ARRAY_VERTEX] = vertices
	surface[Mesh.ARRAY_INDEX] = indices
	mesh.add_surface_from_arrays(
		Mesh.PRIMITIVE_TRIANGLES,
		surface,
		[],
		{}
	)
	return mesh

func _add_core_indices(indices: PackedInt32Array) -> void:
	var w: int = face_segments + 1
	for x: int in range(1, face_segments-1):
		for y: int in range(1, face_segments-1):
			var i: int = x+y*w
			if (x + y) % 2 == 1:
				indices.append_array([i, i+1, i+w, i+w, i+1, i+w+1])
			else:
				indices.append_array([i, i+1, i+w+1, i+w, i, i+w+1])
	var b: int = w*(w-2)
	for i: int in range(2, face_segments, 2):
		var x: int = i
		var y: int = i*w
		indices.append_array([
			x+w-1, x, x+w,
			x, x+w+1, x+w,
			x+b-1, x+b, x+b+w,
			x+b+w, x+b, x+b+1,
			y-w+1, y+1, y,
			y, y+1, y+w+1,
			y-2, y+w-1, y+w-2,
			y+w-2, y+w-1, y+2*w-2 
		])

func _add_border_indices(indices: PackedInt32Array, border_code: int) -> void:
	var w: int = face_segments + 1
	for i: int in range(0, face_segments, 2):
		var left: int = i*w
		if border_code & 1:
			indices.append_array([
				left, left+w+1, left+w,
				left+w+1, left+w*2, left+w
			])
		else:
			indices.append_array([
				left, left+w+1, left+w*2
			])
		var top: int = i
		if border_code & 2:
			indices.append_array([
				top, top+1, top+w+1,
				top+1, top+2, top+w+1
			])
		else:
			indices.append_array([
				top, top+2, top+w+1
			])
		var right: int = i*w+w-1
		if border_code & 4:
			indices.append_array([
				right, right+w, right+w-1,
				right+w, right+w*2, right+w-1
			])
		else:
			indices.append_array([
				right, right+w*2, right+w-1
			])
		var bottom: int = i+w*(w-1)
		if border_code & 8:
			indices.append_array([
				bottom, bottom-w+1, bottom+1,
				bottom-w+1, bottom+2, bottom+1
			])
		else:
			indices.append_array([
				bottom, bottom-w+1, bottom+2
			])
