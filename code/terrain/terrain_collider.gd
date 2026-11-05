@tool
class_name TerrainCollider
extends TerrainTile


static func create(tile_id_: Vector3i, region: Region) -> TerrainCollider:
	var collider: TerrainCollider = preload("res://scenes/terrain/terrain_collider.tscn").instantiate()
	collider.tile_id = tile_id_
	collider.initialize(region)
	return collider

func initialize(region: Region) -> void:
	position = Vector3(area.get_center().x, 0, area.get_center().y)
	var r: int = 2**tile_id.z + 1
	var map_data = region.height_buffer_at(tile_id)
	_apply_collider_data(map_data, r)
	var loaded_shape: BoxShape3D = BoxShape3D.new()
	loaded_shape.size  = Vector3(area.size.x, 16384, area.size.y)
	$LoadedArea/CollisionShape3D.shape = loaded_shape

func _apply_collider_data(map_data: PackedFloat32Array, r: int) -> void:
	$CollisionShape3D.shape.map_width = r
	$CollisionShape3D.shape.map_depth = r
	$CollisionShape3D.shape.map_data = map_data
