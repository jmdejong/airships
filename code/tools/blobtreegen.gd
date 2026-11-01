@tool
extends CSGCombiner3D

@export var stem_material: BaseMaterial3D
@export var leaf_blob_material: BaseMaterial3D
@export var leaf_cluster_material: Material

@export var stem_height: float = 10
@export var leaf_radius: float = 2
#@export var min_leaf_radius: float = 0.7
@export var branch_angle_max: float = PI*0.4
@export var stem_segments = 8
@export var stem_radius = 0.5
@export var branches_per_segment = 3
@export var leaf_spread_by_height: Curve
@export var smooth_leaf_faces: bool = true
@export var leaf_y_scale: float = 1.0
@export var num_leaf_blobs: float = 32
#@export var core_leaves: 

@export_tool_button("generate") var generate_action: Callable = generate
#@export var 
#@export var branch_min_length 

func clear() -> void:
	for child: Node in get_children():
		child.queue_free()

func generate() -> void:
	clear()
	generate_leafy_tree()


func generate_leafy_tree() -> void:
	leaf_cluster_material.albedo_texture = %Leafgen.generate()
	var stem: CSGCylinder3D = CSGCylinder3D.new()
	stem.height = stem_height + 1
	stem.radius = stem_radius
	stem.material = stem_material
	stem.position = Vector3(0, (stem_height + 1) / 2.0, 0)
	add_child(stem)
	for y in range(ceil(stem_height*0.5), ceil(stem_height*1.5)):
		make_leaf_cluster(Vector3(0, y, 0))
		

func make_leaf_cluster(pos: Vector3) -> void:
	var p := MeshInstance3D.new()
	p.position = pos
	var m: QuadMesh = QuadMesh.new()
	m.size = Vector2(2, 2)
	p.mesh = m
	p.rotate_x(-PI/2.0)
	p.material_override = leaf_cluster_material
	add_child(p)


func generate_blob_tree() -> void:
	#var last: Vector3 = Vector3(0, 0, 0)
	#for i in stem_segments:
	var stem: CSGCylinder3D = CSGCylinder3D.new()
	stem.height = stem_height + 1
	stem.radius = stem_radius
	stem.material = stem_material
	stem.position = Vector3(0, (stem_height + 1) / 2.0, 0)
	add_child(stem)
	for y in range(ceil(stem_height * 0.5), floor(stem_height*1.5)):
		add_child(make_leaf_blob(Vector3(0, y, 0), leaf_spread_by_height.sample(y)*0.8))
	for i in num_leaf_blobs:
		var y = randf_range(5, 15)
		var lr: float = min(leaf_spread_by_height.sample(y), leaf_radius * randf_range(0.75, 1.5))
		var dir: float = 2 * PI * randf()
		var dist: float = leaf_spread_by_height.sample(y) - lr
		var pos: Vector3 = Vector3(sin(dir) * dist, y, cos(dir) * dist)
		add_child(make_leaf_blob(pos, lr))

func make_leaf_blob(pos: Vector3, radius: float) -> CSGShape3D:
	var leaf_blob: CSGSphere3D = CSGSphere3D.new()
	leaf_blob.radius = radius
	leaf_blob.position = pos
	leaf_blob.material = leaf_blob_material
	leaf_blob.smooth_faces = smooth_leaf_faces
	leaf_blob.rings = randi_range(4, 6)
	leaf_blob.radial_segments = randi_range(6, 12)
	leaf_blob.scale.y = leaf_y_scale
	#leaf_blob.rotation = Vector3(randf() * 2 * PI, randf() * 2 * PI, randf() * 2 * PI)
	return leaf_blob
