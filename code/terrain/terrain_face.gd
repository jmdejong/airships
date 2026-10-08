@tool
class_name TerrainFace
extends Node3D

var area: Rect2
var aabb: AABB
var level: int
var face_id: Vector3i:
	set(f):
		face_id = f
		level = f.z
		area = Hrc.hrc_area(f)
		aabb = AABB(Vector3(area.position.x, -256, area.position.y), Vector3(area.size.x, 1024, area.size.y))
var has_neighbour: Dictionary[Vector2i, bool] = {}
#var level_range: int = 5
#var subtiles: int = 2**level_range
#var detail_border: Dictionary[Vector2i, bool] = {}
#var borders: Dictionary[Vector2i, MeshInstance3D] = {}
#var detail_border_meshes: Dictionary[Vector2i, Mesh] = {}
#var no_detail_border_meshes: Dictionary[Vector2i, Mesh] = {}
var material: Material
#var _active = true
var step_size: float
static var scene: PackedScene = preload("res://scenes/terrain/terrain_face.tscn")

static func create(face_id: Vector3i, material: Material) -> TerrainFace:
	var face: TerrainFace = scene.instantiate()
	#face.level = level
	face.face_id = face_id
	var center: Vector2 = face.area.get_center()
	face.position = Vector3(center.x, 0, center.y)
	face.material = material
	#face.area = area
	#face.all_positions = all_positions
	face.name = "TerrainFace_%d_%d__%d" % [face_id.x, face_id.y, face_id.z]
	face.initialize()
	#all_positions[face_id] = face
	return face

func initialize() -> void:
	assert(area.size.x == area.size.y)
	step_size = area.size.x / FaceMeshes.face_segments
	%Mesh.mesh = FaceMeshes.default_mesh
	%Mesh.scale = Vector3(area.size.x, 1, area.size.y)
	%Water.scale = Vector3(area.size.x, 1, area.size.y)
	%Mesh.custom_aabb = AABB(Vector3(-0.5, -1024, -0.5), Vector3(1, 2048, 1))
	%Mesh.material_override = material

func set_neighbour(direction: Vector2i, exists: bool) -> void:
	has_neighbour[direction] = exists
	_update_mesh()

func _update_mesh() -> void:
	%Mesh.mesh = FaceMeshes.mesh_for(
		has_neighbour.get(Vector2i(-1, 0), false),
		has_neighbour.get(Vector2i(0, -1), false),
		has_neighbour.get(Vector2i(1, 0), false),
		has_neighbour.get(Vector2i(0, 1), false)
	)
