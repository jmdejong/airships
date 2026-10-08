@tool
class_name Region
extends Node3D

var area: Rect2
var region_id: Vector3i
var segments: int
var image_buffers: ImageBuffers
var root_face: TerrainFace
var ground_material: ShaderMaterial

static func create(region_id: Vector3i, segments: int, height_source: HeightSource) -> Region:
	var region = preload("res://scenes/terrain/region.tscn").instantiate()
	region.region_id = region_id
	region.segments = segments
	region.initialize(height_source)
	return region

func initialize(height_source: HeightSource) -> void:
	area = Hrc.hrc_area(region_id)

	position = Vector3(area.get_center().x, 0, area.get_center().y)
	image_buffers = height_source.height_image_at(area, segments)
	ground_material = image_buffers.terrain_material()

func draw_terrain() -> void:
	var mesh_shape: PlaneMesh = $MeshInstance3D.mesh
	$MeshInstance3D.scale = Vector3(area.size.x, 1, area.size.y)
	mesh_shape.subdivide_width = segments - 1
	mesh_shape.subdivide_depth = segments - 1
	$MeshInstance3D.material_override = mesh_material()
	$MeshInstance3D.custom_aabb = AABB(
		Vector3(area.position.x - global_position.x, -1024, area.position.y - global_position.z),
		Vector3(area.size.x, 4096, area.size.y)
	)

func mesh_material() -> ShaderMaterial:
	return ground_material

func build_collider() -> void:
	var r: int = segments + 1
	var map_data: PackedFloat32Array = PackedFloat32Array()
	map_data.resize(r*r)
	var img_data: PackedByteArray = image_buffers.height.get_data()
	for i: int in map_data.size():
		map_data[i] = img_data.decode_half(i*8)
	$StaticBody3D/CollisionShape3D.shape.map_data = map_data

func relative_axis_distance(to: Vector2) -> float:
	var d: Vector2 = (to - area.get_center()).abs() / area.size - Vector2(0.5, 0.5)
	return max(d.x, d.y)

func height_at(pos: Vector2) -> float:
	return image_buffers.height_at(pos)
