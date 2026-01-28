@tool
@abstract
class_name HeightSource
extends Resource

@abstract
func height_at(pos: Vector2) -> float

func buffers_at(area: Rect2, segments: int) -> TileBuffers:
	const texture_size: float = 8
	var buf: TileBuffers = TileBuffers.new(area, segments)
	var size: Vector2i = buf.size
	for y in size.y:
		for x in size.x:
			var ind: int = x + y*size.x
			var tile: Vector2 = Vector2(x, y)
			var pos: Vector2 = buf.tile_to_pos * tile
			var position: Vector3 = pos_at(pos)
			buf.heights[ind] = position.y
			buf.positions[ind] = position
			buf.colors[ind] = color_modifier(pos)
			buf.tex_uvs[ind] = pos / texture_size
	for y in size.y - 1:
		for x in size.x - 1:
			var ind: int = x + y*size.x
			var normal: Vector3 = -(buf.positions[ind+1] - buf.positions[ind]).cross(buf.positions[ind+size.x] - buf.positions[ind]).normalized()
			buf.normals[ind] = normal
		var indr: int = (y+1) * (size.x) - 1
		var normalr: Vector3 = -(pos_at(buf.tile_to_pos * Vector2(size.x, y)) - buf.positions[indr]).cross(buf.positions[indr+size.x] - buf.positions[indr]).normalized()
		buf.normals[indr] = normalr
	for x in size.x - 1:
		var indb: int = x + (size.y - 1)*size.x
		var normalb: Vector3 = -(buf.positions[indb+1] - buf.positions[indb]).cross(pos_at(buf.tile_to_pos * Vector2(x, size.y)) - buf.positions[indb]).normalized()
		buf.normals[indb] = normalb
	var indbr: int = size.x * size.y - 1
	var normalbr: Vector3 = -(pos_at(buf.tile_to_pos * Vector2(size.x, size.y-1)) - buf.positions[indbr]).cross(pos_at(buf.tile_to_pos * Vector2(size.x-1, size.y)) - buf.positions[indbr]).normalized()
	buf.normals[indbr] = normalbr
	return buf

func prepare_area(area: Rect2, segments: int) -> bool:
	return true

func pos_at(pos: Vector2) -> Vector3:
	return Vector3(pos.x, height_at(pos), pos.y)

func color_modifier(_pos: Vector2) -> Color:
	return Color.WHITE

func color_modifier3(pos: Vector3) -> Color:
	return color_modifier(Vector2(pos.x, pos.z))

#func get_area_height(area: Rect2i) -> PackedFloat32Array:
	#var p: PackedFloat32Array = []

@abstract
func extremes(area: Rect2) -> Vector2

@abstract
func structures(area: Rect2) -> Structure.Buffer
