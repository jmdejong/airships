class_name ImageBuffers
extends Resource

var height: Image
var normal: Image
var color: Image
var area: AABB
var segments: int
var absolute_minimum: float
var red_scale: float
var green_scale: float
var blue_scale: float
var base_material: ShaderMaterial

func height_at_pixel(pix: Vector2i) -> float:
	return height.get_pixelv(pix).r * area.size.y + area.position.y

func height_sub_image(sub_area: Rect2i) -> Image:
	var area2: Rect2i = Rect2i(int(area.position.x), int(area.position.z), segments, segments)
	assert(area2.encloses(sub_area))
	var taken_area: Rect2i = Rect2i(sub_area.position - area2.position, sub_area.size + Vector2i.ONE)
	return height.get_region(taken_area)
	
func terrain_material() -> ShaderMaterial:
	var height_tex: ImageTexture = ImageTexture.create_from_image(height)
	var normal_tex: ImageTexture = ImageTexture.create_from_image(normal)
	var color_tex: ImageTexture = ImageTexture.create_from_image(color)
	var ground_material: ShaderMaterial = base_material.duplicate()
	ground_material.set_shader_parameter("height_tex", height_tex)
	ground_material.set_shader_parameter("normal_tex", normal_tex)
	ground_material.set_shader_parameter("color_tex", color_tex)
	ground_material.set_shader_parameter("position", area.position)
	ground_material.set_shader_parameter("size", area.size)
	ground_material.set_shader_parameter("subtiles", segments)
	ground_material.set_shader_parameter("absolute_minimum", absolute_minimum)
	ground_material.set_shader_parameter("red_scale", red_scale)
	ground_material.set_shader_parameter("green_scale", green_scale)
	ground_material.set_shader_parameter("blue_scale", blue_scale)
	return ground_material
