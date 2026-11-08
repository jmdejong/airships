@tool
extends MeshInstance3D

@export var leaf_material: ShaderMaterial
@export var leaf_draw_material: ShaderMaterial
@export var resolution: int = 128
@export var leaves_filename: String = "bush_leaves.png"
@export var mesh_filename: String = "bush2.mesh"
@export var blades_count: int = 8
@export var blade_width: float = 0.6
@export var blade_top: float = 2
@export var htr: float = 2
@export var btr: float = 0.5;
@export var vtr: float = 1
@export var blade_bottom: float = -0.2

@export_tool_button("generate") var generate_action: Callable = generate

func generate() -> void:
	var texture: Texture2D = generate_tex()
	leaf_material.set_shader_parameter("texture_albedo", texture)
	#material_override = leaf_material
	generate_mesh()
	

func generate_tex() -> Texture2D:
	var texture: DrawableTexture2D = DrawableTexture2D.new()
	texture.setup(resolution, resolution, DrawableTexture2D.DRAWABLE_FORMAT_RGBA8)
	texture.blit_rect(Rect2i(0, 0, resolution, resolution), preload("res://icon.svg"), Color.BLACK, 0, leaf_draw_material)
	var image: Image = texture.get_image()
	var file_path: String = "res://textures/generated/" + leaves_filename
	image.save_png(file_path)
	var img_tex: Texture2D = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	return img_tex

func generate_mesh() -> void:
	var vertices := PackedVector3Array()
	var indices := PackedInt32Array()
	var uvs := PackedVector2Array()
	var normals := PackedVector3Array()
	var bs := Basis.from_euler(Vector3(deg_to_rad(23), deg_to_rad(37), deg_to_rad(19)))
	var size := 0.7

	var planes := [
		[bs.x, bs.y],
		[bs.y, bs.z],
		[bs.z, bs.x],
	]

	for plane in planes:
		var a: Vector3 = plane[0] * size
		var b: Vector3 = plane[1] * size
		var normal := a.cross(b).normalized()
		prints("norm", normal)

		var vs: int = vertices.size()
		var verts: Array[Vector3] = [-a - b, a - b, a + b, -a + b]
		vertices.append_array(PackedVector3Array(verts))
		normals.append_array(PackedVector3Array(verts.map(func(v): return v.normalized())))
		indices.append_array(PackedInt32Array([vs, vs+1, vs+2, vs, vs+2, vs+3]))
		uvs.append_array(PackedVector2Array([Vector2(0, 1), Vector2(1, 1), Vector2(1, 0), Vector2(0, 0)]))
	
	var bush_mesh := ArrayMesh.new()
	var surface_array: Array = []
	surface_array.resize(Mesh.ARRAY_MAX)
	surface_array[Mesh.ARRAY_VERTEX] = vertices
	surface_array[Mesh.ARRAY_NORMAL] = normals
	surface_array[Mesh.ARRAY_TEX_UV] = uvs
	surface_array[Mesh.ARRAY_INDEX] = indices
	
	bush_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, surface_array)
	bush_mesh.surface_set_material(0, leaf_material)
	mesh = bush_mesh
	var file_path: String = "res://models/generated/" + mesh_filename
	ResourceSaver.save(bush_mesh, file_path)
	self.mesh = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE)
