class_name ImageBuffers
extends Resource

var height: Image
var normal: Image
var color: Image
var area: AABB
var segments: int

func height_at_pixel(pix: Vector2i) -> float:
	return height.get_pixelv(pix).r * area.size.y + area.position.y

func height_sub_image(sub_area: Rect2i) -> Image:
	var area2: Rect2i = Rect2i(int(area.position.x), int(area.position.z), segments, segments)
	assert(area2.encloses(sub_area))
	var taken_area: Rect2i = Rect2i(sub_area.position - area2.position, sub_area.size + Vector2i.ONE)
	return height.get_region(taken_area)
	
