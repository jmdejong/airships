@tool
class_name TerrainTile
extends Node3D

var area: Rect2
var tile_id: Vector3i:
	set(t):
		tile_id = t
		area = Hrc.hrc_area(t)
