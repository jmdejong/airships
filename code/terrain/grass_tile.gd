@tool
class_name GrassTile
extends TerrainTile

var axis_instance_count: int = 32

static func create(tile_id_: Vector3i, height_source: Region) -> GrassTile:
	var grass_tile: GrassTile = preload("res://scenes/terrain/grass_tile.tscn").instantiate()
	grass_tile.tile_id = tile_id_
	var pos: Vector2 = grass_tile.area.get_center()
	grass_tile.position = Vector3(pos.x, 0, pos.y)
	grass_tile.initialize(height_source)
	return grass_tile

func initialize(region: Region) -> void:
	var multimesh: MultiMesh = $MultiMeshInstance3D.multimesh
	multimesh.instance_count = axis_instance_count * axis_instance_count
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(tile_id.x + 32409 * tile_id.y + 43859 * tile_id.z)
	var lo: float = 1_000_000
	var hi: float = -1_000_000
	var transforms: Array[Transform3D]
	var colors := PackedColorArray()
	for x in axis_instance_count:
		for y in axis_instance_count:
			var pb := Vector2(x + rng.randf_range(0.2, 0.8), y+rng.randf_range(0.2, 0.8)) / axis_instance_count * area.size + area.position
			if region.grass_density_at(pb) < rng.randf():
				continue
			var pos = Vector3(pb.x, region.height_at(pb) - rng.randf_range(0.0, 0.2), pb.y)
			if pos.y > hi:
				hi = pos.y
			if pos.y < lo:
				lo = pos.y
			var tf := Transform3D(Basis(Vector3.UP, rng.randf()*TAU), pos-position)
			transforms.append(tf)
			colors.append(region.color_at(pb))
	multimesh.instance_count = len(transforms)
	for i in len(transforms):
		multimesh.set_instance_transform(i, transforms[i])
		multimesh.set_instance_color(i, colors[i])
	$MultiMeshInstance3D.custom_aabb = AABB(
		Vector3(area.position.x, lo, area.position.y) - position,
		Vector3(area.size.x, hi-lo+1, area.size.y)
	).grow(0.5)
	
