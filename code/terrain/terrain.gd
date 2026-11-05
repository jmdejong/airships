@tool
class_name Terrain
extends Node3D


var settings_for_perf: Dictionary[Config.Perf, Settings] = {
	Config.Perf.FAST: Settings.new(8, 10, 256),
	Config.Perf.PRETTY: Settings.new(9, 12, 512),
}
var settings: Settings = settings_for_perf[Config.performance]
var load_update_camera_snap: Vector2 = Vector2(16, 16)
var previous_snapped_player_pos: Vector2 = Vector2(NAN, NAN)
var regions_to_load: Array[Vector3i]
var loaded_regions: Dictionary[Vector3i, Region] = {}
var loaded_colliders: Dictionary[Vector3i, TerrainCollider] = {}
var faces: Dictionary[Vector3i, TerrainFace] = {}
var structure_tiles: Dictionary[Vector3i, StructureTile] = {}
var grass_tiles: Dictionary[Vector3i, GrassTile] = {}
var map_changed: bool = true
@export var height_source: HeightSource

func _physics_process(_delta: float) -> void:
	if height_source == null:
		return
	var camera: Camera3D = get_viewport().get_camera_3d()
	var player_pos: Vector2 = Vector2.ZERO
	if camera == null:
		if not Engine.is_editor_hint():
			return
	else:
		player_pos = Vector2(camera.global_position.x, camera.global_position.z)
	var snapped_player_pos: Vector2 = player_pos.snapped(load_update_camera_snap)
	if snapped_player_pos != previous_snapped_player_pos:
		previous_snapped_player_pos = snapped_player_pos
		map_changed = true
		prune_regions(player_pos)
		identify_load_regions(player_pos)
		prune_tile_layer(player_pos, loaded_colliders, settings.collider_min_distance * 2)
		prune_tile_layer(player_pos, structure_tiles, settings.structure_min_distance * 2)
		prune_tile_layer(player_pos, grass_tiles, settings.grass_min_distance * 2)
	load_regions()
	if not Engine.is_editor_hint():
		build_one_collider(player_pos)
	build_structures(player_pos)
	build_grass(player_pos)
	#build_tile_layer(GrassTile.create, grass_tiles, settings.grass_level, settings.grass_min_distance, $Grass, player_pos)
	if map_changed:
		update_faces(player_pos)
		map_changed = false

func _exit_tree() -> void:
	for face: TerrainFace in faces.values():
		if is_instance_valid(face) and not face.is_inside_tree():
			face.free()

func region_for_face(hrc: Vector3i) -> Region:
	var region_hrc: Vector3i
	if hrc.z < settings.face_uses_region_level:
		region_hrc = Hrc.ancestor_at_level(hrc, settings.region_level)
	else:
		region_hrc = Hrc.ancestor_at_level(hrc, settings.super_region_level)
	var region: Region = loaded_regions.get(region_hrc)
	return region

func load_region_at(region_id: Vector3i) -> void:
	var region: Region = Region.new(region_id, settings.region_level_range, height_source)
	loaded_regions[region_id] = region
	if region_id.z == settings.super_region_level or faces.has(region_id):
		add_face(region_id)
	map_changed = true

func load_regions() -> void:
	var loads_left: int = 2
	while loads_left > 0 and not regions_to_load.is_empty():
		var region_id: Vector3i = regions_to_load.pop_back()
		if loaded_regions.has(region_id):
			continue
		load_region_at(region_id)
		loads_left -= 1

func identify_load_regions(player_pos: Vector2) -> void:
	var region_load_distance: int = 2
	for level: int in [settings.region_level, settings.super_region_level]:
		var region_camera_pos: Vector3i = Hrc.world_to_hrc_id(player_pos, level)
		for x: int in range(-region_load_distance, region_load_distance+1):
			for y: int in range(-region_load_distance, region_load_distance+1):
				var region_id: Vector3i = region_camera_pos + Vector3i(x, y, 0)
				if not loaded_regions.has(region_id):
					regions_to_load.push_back(region_id)

func prune_regions(player_pos: Vector2) -> void:
	for region_id: Vector3i in loaded_regions:
		var region: Region = loaded_regions[region_id]
		if region.relative_axis_distance(player_pos) > 2.8:
			loaded_regions.erase(region_id)

func update_faces(player_pos) -> void:
	for face: TerrainFace in $Faces.get_children():
		if Hrc.relative_axis_distance(face.face_id, player_pos) < 2.0 and face.face_id.z > settings.min_face_level:
			var subfaces: Array = Hrc.children(face.face_id)
			if subfaces.any(func(sub_id: Vector3i): return region_for_face(sub_id) == null):
				continue
			for sub_id: Vector3i in subfaces:
				add_face(sub_id)
			$Faces.remove_child(face)
	for face: TerrainFace in faces.values():
		if not face.is_inside_tree() and Hrc.relative_axis_distance(face.face_id, player_pos) > 3.0:
			$Faces.add_child(face)
			for sub_id: Vector3i in Hrc.children(face.face_id):
				remove_face(sub_id)
		if face.level == settings.super_region_level and not loaded_regions.has(face.face_id):
			remove_face(face.face_id)

func add_face(face_id: Vector3i) -> void:
	if not faces.has(face_id):
		faces[face_id] = TerrainFace.create(face_id, region_for_face(face_id).mesh_material())
	if not faces[face_id].is_inside_tree():
		$Faces.add_child(faces[face_id])
	for direction: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var neighbour_id: Vector3i = Hrc.neighbour_in(face_id, direction)
		if faces.has(neighbour_id):
			faces[face_id].set_neighbour(direction, true)
			faces[neighbour_id].set_neighbour(-direction, true)

func remove_face(face_id: Vector3i) -> void:
	if !faces.has(face_id):
		return
	var face: TerrainFace = faces[face_id]
	for sub_id: Vector3i in Hrc.children(face_id):
		remove_face(sub_id)
	faces.erase(face_id)
	face.queue_free()
	for direction: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var neighbour_id: Vector3i = Hrc.neighbour_in(face_id, direction)
		if faces.has(neighbour_id):
			faces[neighbour_id].set_neighbour(-direction, false)
			
	face.queue_free()

func build_one_collider(player_pos: Vector2) -> void:
	for collider_id: Vector3i in Hrc.iterate_near(player_pos, settings.collider_min_distance, settings.collider_level):
		var region: Region = loaded_regions.get(Hrc.ancestor_at_level(collider_id, settings.region_level))
		if region != null and not loaded_colliders.has(collider_id):
			var collider: TerrainCollider = TerrainCollider.create(collider_id, region)
			loaded_colliders[collider_id] = collider
			$Colliders.add_child(collider)
			return

func build_structures(player_pos: Vector2) -> void:
	for tile_id: Vector3i in Hrc.iterate_near(player_pos, settings.structure_min_distance, settings.structure_level):
		if not structure_tiles.has(tile_id):
			var structure_tile: StructureTile = StructureTile.create(tile_id, height_source)
			$Structures.add_child(structure_tile)
			structure_tiles[tile_id] = structure_tile
			return

func build_grass(player_pos: Vector2) -> void:
	for tile_id: Vector3i in Hrc.iterate_near(player_pos, settings.grass_min_distance, settings.grass_level):
		if not grass_tiles.has(tile_id):
			var region: Region = loaded_regions.get(Hrc.ancestor_at_level(tile_id, settings.region_level))
			if region == null:
				continue
			var grass_tile: GrassTile = GrassTile.create(tile_id, region)
			grass_tiles[tile_id] = grass_tile
			$Grass.add_child(grass_tile)
			return

func build_tile_layer(factory: Callable, collection: Dictionary, level: int, min_distance: float, parent: Node3D, player_pos) -> void:
	for tile_id: Vector3i in Hrc.iterate_near(player_pos, min_distance, level):
		if not collection.has(tile_id):
			var region: Region = loaded_regions.get(Hrc.ancestor_at_level(tile_id, settings.region_level))
			if region == null:
				continue
			var tile: TerrainTile = factory.call(tile_id, region)
			collection[tile_id] = tile
			parent.add_child(tile)
			return

func prune_tile_layer(player_pos: Vector2, tiles: Dictionary, prune_distance: float) -> void:
	for tile: TerrainTile in tiles.values():
		if Hrc.absolute_axis_distance(tile.tile_id, player_pos) >= prune_distance:
			tiles.erase(tile.tile_id)
			tile.queue_free()

func height_at(pos: Vector2) -> float:
	var region_id: Vector3i = Hrc.world_to_hrc_id(pos, settings.region_level)
	if not loaded_regions.has(region_id):
		region_id = Hrc.world_to_hrc_id(pos, settings.super_region_level)
		if not loaded_regions.has(region_id):
			return 404
	return loaded_regions[region_id].height_at(pos)


class Settings:
	var region_level: int = 9
	var super_region_level: int = 12
	var region_level_range: int = region_level
	#var region_step_count: int = 2**region_level_range
	var min_face_level: int = 5
	var collider_level: int = 7
	var structure_level: int = 7
	var face_uses_region_level: int = super_region_level - region_level + min_face_level
	var collider_min_distance: float = 512
	var structure_min_distance: float = 512
	var grass_level: int = 5
	var grass_min_distance: float = 64

	
	func _init(region_level: int, super_region_level: int, physics_min_distance: float) -> void:
		self.region_level = region_level
		self.super_region_level = super_region_level
		self.collider_min_distance = physics_min_distance
		self.structure_min_distance = physics_min_distance
