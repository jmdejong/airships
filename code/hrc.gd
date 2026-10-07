@tool
extends Node
# Hierarchical Region Coordinates

var base_tile_size: float = 1

func _level_size(level: int) -> float:
	return base_tile_size * 2**level

func hrc_area(hrc: Vector3i) -> Rect2:
	var s = _level_size(hrc.z)
	return Rect2(hrc.x * s, hrc.y * s, s, s)

func children(hrc: Vector3i) -> Array[Vector3i]:
	return [
		Vector3i(hrc.x * 2 + 0, hrc.y * 2 + 0, hrc.z - 1),
		Vector3i(hrc.x * 2 + 1, hrc.y * 2 + 0, hrc.z - 1),
		Vector3i(hrc.x * 2 + 0, hrc.y * 2 + 1, hrc.z - 1),
		Vector3i(hrc.x * 2 + 1, hrc.y * 2 + 1, hrc.z - 1)
	]

func parent(hrc: Vector3i) -> Vector3i:
	return Vector3i(floori(hrc.x/2.0), floori(hrc.y/2.0), hrc.z + 1)

func neighbour_in(hrc: Vector3i, direction: Vector2i) -> Vector3i:
	return Vector3i(hrc.x + direction.x, hrc.y + direction.y, hrc.z)

func world_to_hrc_pos(world: Vector2, level: int) -> Vector2:
	return world / _level_size(level)

func world_to_hrc_id(world: Vector2, level: int) -> Vector3i:
	var v: Vector2 = world_to_hrc_pos(world, level)
	return Vector3i(floori(v.x), floori(v.y), level)

func world_to_hrc_uv(world: Vector2, level: int) -> Vector2:
	return world_to_hrc_pos(world, level).posmod(1)

func ancestor_at_level(hrc: Vector3i, level: int) -> Vector3i:
	assert(level >= hrc.z)
	while level > hrc.z:
		hrc = parent(hrc)
	return hrc

func relative_axis_distance(hrc: Vector3i, to: Vector2) -> float:
	var area: Rect2 = hrc_area(hrc)
	var d: Vector2 = (to - area.get_center()).abs() / area.size - Vector2(0.5, 0.5)
	return max(d.x, d.y)

func absolute_axis_distance(hrc: Vector3i, to: Vector2) -> float:
	var area: Rect2 = hrc_area(hrc)
	var d: Vector2 = (to - area.get_center()).abs() - Vector2(0.5, 0.5) * area.size
	return max(d.x, d.y)
