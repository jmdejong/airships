class_name TileBuffers
extends RefCounted
var area: Rect2
var heights := PackedFloat32Array()
var positions := PackedVector3Array()
var normals := PackedVector3Array()
var colors := PackedColorArray()
var tex_uvs := PackedVector2Array()
var segments: int
var size: Vector2i
var tile_to_pos: Transform2D
var pos_to_tile: Transform2D
func _init(area: Rect2, segments: int) -> void:
	self.area = area
	self.segments = segments
	tile_to_pos = Transform2D(0, area.size/segments, 0, area.position)
	pos_to_tile = tile_to_pos.affine_inverse()
	size = Vector2i(segments + 1, segments + 1)
	var buffer_size: int = size.x * size.y
	heights.resize(buffer_size)
	positions.resize(buffer_size)
	normals.resize(buffer_size)
	colors.resize(buffer_size)
	tex_uvs.resize(buffer_size)

func height_at(pos: Vector2i) -> float:
	return heights[pos.x + pos.y * size.x]

func pos_at(tile_pos: Vector2i) -> Vector3:
	return positions[tile_pos.x + tile_pos.y * size.x]

func color_modifier_at(pos: Vector2i) -> Color:
	return colors[pos.x + pos.y * size.x]

func normal_at(pos: Vector2i) -> Vector3:
	return normals[pos.x + pos.y * size.x]

func uv_at(pos: Vector2i) -> Vector2:
	return tex_uvs[pos.x + pos.y * size.x]
