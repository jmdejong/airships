@tool
class_name StructureTile
extends TerrainTile


static func create(tile_id_: Vector3i, region: Region, height_source: HeightSource) -> StructureTile:
	var structure_tile: StructureTile = preload("res://scenes/terrain/structure_tile.tscn").instantiate()
	structure_tile.tile_id = tile_id_
	var structure_buffer: Structure.Buffer = height_source.structures(structure_tile.area)
	for node: Node3D in structure_buffer.nodes():
		node.position.y = region.height_at(Vector2(node.position.x, node.position.z))
		structure_tile.add_child(node)
	return structure_tile
