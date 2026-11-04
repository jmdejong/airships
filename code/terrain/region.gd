@tool
class_name Region
extends Resource

var area: Rect2
var region_id: Vector3i
var level_range: int
var segments: int
var segment_level: int
var image_buffers: ImageBuffers
var root_face: TerrainFace
var ground_material: ShaderMaterial

func _init(region_id_: Vector3i, level_range_: int, height_source: HeightSource) -> void:
	region_id = region_id_
	level_range = level_range_
	segments = 2**level_range
	segment_level = region_id.z - level_range
	area = Hrc.hrc_area(region_id)
	image_buffers = height_source.height_image_at(area, segments)
	_make_ground_material(height_source)

func _make_ground_material(height_source: HeightSource) -> void:
	var height_tex: ImageTexture = ImageTexture.create_from_image(image_buffers.height)
	var normal_tex: ImageTexture = ImageTexture.create_from_image(image_buffers.normal)
	var color_tex: ImageTexture = ImageTexture.create_from_image(image_buffers.color)
	ground_material = height_source.base_material()
	ground_material.set_shader_parameter("height_tex", height_tex)
	ground_material.set_shader_parameter("normal_tex", normal_tex)
	ground_material.set_shader_parameter("color_tex", color_tex)
	ground_material.set_shader_parameter("position", area.position)
	ground_material.set_shader_parameter("size", area.size)
	ground_material.set_shader_parameter("subtiles", segments)
	ground_material.set_shader_parameter("absolute_minimum", image_buffers.absolute_minimum)
	ground_material.set_shader_parameter("red_scale", image_buffers.red_scale)
	ground_material.set_shader_parameter("green_scale", image_buffers.green_scale)
	ground_material.set_shader_parameter("blue_scale", image_buffers.blue_scale)

func mesh_material() -> ShaderMaterial:
	return ground_material

func relative_axis_distance(to: Vector2) -> float:
	var d: Vector2 = (to - area.get_center()).abs() / area.size - Vector2(0.5, 0.5)
	return max(d.x, d.y)

func height_at(pos: Vector2) -> float:
	var c: Color = image_buffers.height.get_pixelv(_pos_to_pixel(pos))
	return image_buffers.absolute_minimum + c.r * image_buffers.red_scale + c.g * image_buffers.green_scale


func _height_sub_image(tile_id: Vector3i) -> Image:
	var segment_region_position: Vector3i = Hrc.child_at_level(region_id, segment_level)
	var segment_tile_position: Vector3i = Hrc.child_at_level(tile_id, segment_level)
	var pixel_pos: Vector3i = segment_tile_position - segment_region_position
	var region_size: int = 2**(level_range - region_id.z + tile_id.z)
	var region: Rect2i = Rect2i(Vector2(pixel_pos.x, pixel_pos.y), Vector2.ONE * (region_size + 1))
	return image_buffers.height.get_region(region)

func height_buffer_at(tile_id: Vector3i) -> PackedFloat32Array:
	assert(Hrc.ancestor_at_level(tile_id, region_id.z) == region_id)
	var img_data: PackedByteArray = _height_sub_image(tile_id).get_data()
	var map_data: PackedFloat32Array = PackedFloat32Array()
	map_data.resize(img_data.size() / 4)
	var absolute_minimum: float = image_buffers.absolute_minimum
	var red_scale: float = image_buffers.red_scale
	var green_scale: float = image_buffers.green_scale
	var _blue_scale: float = image_buffers.blue_scale
	# Heavy loop. Make sure to optimize
	for i: int in map_data.size():
		map_data[i] = absolute_minimum \
			+ img_data.get(i*4)/255.0 * red_scale \
			+ img_data.get(i*4+1)/255.0 * green_scale
	return map_data

func grass_density_at(pos: Vector2) -> float:
	return image_buffers.detail.get_pixelv(_pos_to_pixel(pos))[0]

func color_at(pos: Vector2) -> Color:
	var c: Color = image_buffers.color.get_pixelv(_pos_to_pixel(pos))
	if Global.is_srgb:
		return c.srgb_to_linear()
	else:
		return c 

func _pos_to_pixel(pos: Vector2) -> Vector2i:
	assert(area.has_point(pos))
	return Vector2i(
		round((pos.x - area.position.x) / area.size.x * segments),
		round((pos.y - area.position.y) / area.size.y * segments)
	)
