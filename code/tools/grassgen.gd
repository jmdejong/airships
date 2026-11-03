@tool
extends MeshInstance3D

@export var blades_count: int = 16
@export var blade_top: float = 1
@export var blade_bottom: float = -0.5
@export var blade_width: float = 0.2
@export var blade_spread_rad: float = 1
@export var grass_material: Material
@export var htr: float = 0.5
@export var vtr: float = 0.2
@export_tool_button("generate") var generate_action: Callable = generate
@export var filename: String = "grass.mesh"

func generate() -> void:
	
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	for i in blades_count:
		var pos := Vector2(randf_range(-blade_spread_rad, blade_spread_rad), randf_range(-blade_spread_rad, blade_spread_rad))
		var vs: int = vertices.size()
		var rot: float = randf_range(0, TAU)
		vertices.append_array(PackedVector3Array([
			Vector3(pos.x + blade_width * sin(rot), blade_bottom, pos.y + blade_width * cos(rot)),
			Vector3(pos.x - blade_width * sin(rot), blade_bottom, pos.y - blade_width * cos(rot)),
			Vector3(pos.x, blade_top, pos.y) + Vector3(randf_range(-htr, htr), randf_range(-vtr, vtr), randf_range(-htr, htr))
		]))
		indices.append_array(PackedInt32Array([vs, vs+1, vs+2]))
		normals.append_array(PackedVector3Array([Vector3.UP, Vector3.UP, Vector3.UP]))
		uvs.append_array(PackedVector2Array([Vector2(0, 0), Vector2(1, 0), Vector2(0.5, 1)]))
		var c: Color = Color.WHITE * randf_range(0.8, 1.2)
		colors.append_array(PackedColorArray([c, c, c]))
	var grass_mesh := ArrayMesh.new()
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	surface_array[Mesh.ARRAY_COLOR] = colors
	grass_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	grass_mesh.surface_set_material(0, grass_material)
	mesh = grass_mesh
	ResourceSaver.save(grass_mesh, "res://models/generated/" + filename)
