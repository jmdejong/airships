class_name TerrainCollider
extends StaticBody3D

var area: Rect2
var region_id: Vector3i

static func create(region_id: Vector3i, image_buffers: ImageBuffers) -> TerrainCollider:
	var collider: TerrainCollider = preload("res://scenes/terrain/terrain_collider.tscn").instantiate()
	collider.region_id = region_id
	collider.area = Hrc.hrc_area(region_id)
	collider.initialize(image_buffers)
	return collider

func initialize(image_buffers: ImageBuffers) -> void:
	position = Vector3(area.get_center().x, 0, area.get_center().y)
	var r: int = 2**region_id.z + 1
	var img_data: PackedByteArray = _get_img_data(image_buffers)
	var map_data: PackedFloat32Array = _create_collider_data(img_data, image_buffers.area.position.y, image_buffers.area.size.y)
	_apply_collider_data(map_data, r)

func _get_img_data(image_buffers: ImageBuffers) -> PackedByteArray:
	return image_buffers.height_sub_image(area).get_data()
func _create_collider_data(img_data: PackedByteArray, height_min: float, height_scale: float) -> PackedFloat32Array:
	var map_data: PackedFloat32Array = PackedFloat32Array()
	map_data.resize(img_data.size() / 8)
	# Heavy loop. Make sure to optimize
	for i: int in map_data.size():
		map_data[i] = img_data.decode_half(i*8) * height_scale + height_min
	return map_data
func _apply_collider_data(map_data: PackedFloat32Array, r: int) -> void:
	$CollisionShape3D.shape.map_width = r
	$CollisionShape3D.shape.map_depth = r
	$CollisionShape3D.shape.map_data = map_data


func relative_axis_distance(to: Vector2) -> float:
	var d: Vector2 = (to - area.get_center()).abs() / area.size - Vector2(0.5, 0.5)
	return max(d.x, d.y)
