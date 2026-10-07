@tool
class_name BufferedHeightSource
extends HeightSource

@export var base_source: HeightSource:
	set(b):
		base_source = b
		#update()
@export var area: Rect2
@export var segments: int

var buffer: TileBuffers = null

func buffers_at(buf_area: Rect2, buf_segments: int) -> TileBuffers:
	if buffer == null:
		buffer = base_source.buffers_at(area, segments)
		#prints("buffhs", buffer.size, buffer.area, buffer.segments)
	return buffer.sub_region(buf_area, buf_segments)

func height_at(pos: Vector2) -> float:
	return base_source.height_at(pos)

func extremes(area: Rect2) -> Vector2:
	return base_source.extremes(area)

func structures(area: Rect2) -> Structure.Buffer:
	return base_source.structures(area)
