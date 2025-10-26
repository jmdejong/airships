@abstract
class_name HeightSource
extends Resource

@abstract
func height_at(pos: Vector2) -> float

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
