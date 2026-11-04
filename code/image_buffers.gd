class_name ImageBuffers
extends Resource

var height: Image
var normal: Image
var color: Image
var detail: Image
var area: AABB
var segments: int
var absolute_minimum: float
var red_scale: float
var green_scale: float
var blue_scale: float
var base_material: ShaderMaterial

func height_sub_image(sub_area: Rect2i) -> Image:
	var area2: Rect2i = Rect2i(int(area.position.x), int(area.position.z), segments, segments)
	assert(area2.encloses(sub_area))
	var taken_area: Rect2i = Rect2i(sub_area.position - area2.position, sub_area.size + Vector2i.ONE)
	return height.get_region(taken_area)
