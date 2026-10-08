@tool
class_name StructureTile
extends Node3D

var tile_id: Vector3i

static func create(tile_id: Vector3i, height_source: HeightSource, terrain: Terrain) -> StructureTile:
	var structure_tile: StructureTile = preload("res://scenes/terrain/structure_tile.tscn").instantiate()
	structure_tile.tile_id = tile_id
	var area = Hrc.hrc_area(tile_id)
	var structure_buffer = height_source.structures(area)
	for node in structure_buffer.nodes():
		node.position.y = terrain.height_at(Vector2(node.position.x, node.position.z))
		structure_tile.add_child(node)
	return structure_tile
