class_name ImageBuffers
extends Resource

var height: Image
var normal: Image
var area: AABB
var segments: int

func height_at_pixel(pix: Vector2i) -> float:
	return height.get_pixelv(pix).r * area.size.y + area.position.y

func height_sub_image(sub_area: Rect2i) -> Image:
	var area2: Rect2i = Rect2i(int(area.position.x), int(area.position.z), segments, segments)
	assert(area2.encloses(sub_area))
	var taken_area: Rect2i = Rect2i(sub_area.position - area2.position, sub_area.size + Vector2i.ONE)
	return height.get_region(taken_area)
	
#
#func convert_height() -> void:
	#var w: int = written_height.get_width()
	#var h: int = written_height.get_height()
	#var s: int = w * h
	#var written_data: PackedByteArray = written_height.get_data()
	#var converted_data: PackedByteArray = PackedByteArray()
	#converted_data.resize(2 * s)
	#for i in s:
		#converted_data[i*2] = written_data[i*8]
		#converted_data[i*2+1] = written_data[i*8+1]
	#converted_height = Image.create_from_data(w, h, false, Image.Format.FORMAT_RH, converted_data)
	
