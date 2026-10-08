@tool
extends Node3D

var super_region_level: int = 12
var region_level: int = 9
const region_level_range: int = 9
const region_step_count: int = 2**region_level_range
var min_face_level: int = 5
var collider_level: int = 8
var structure_level: int = 8
var face_uses_region_level: int = super_region_level - region_level + min_face_level
var load_update_camera_snap: Vector2 = Vector2(16, 16)
var previous_snapped_player_pos: Vector2 = Vector2(NAN, NAN)
var regions_to_load: Array[Vector3i]
var loaded_regions: Dictionary[Vector3i, Region] = {}
var loaded_colliders: Dictionary[Vector3i, TerrainCollider] = {}
var faces: Dictionary[Vector3i, TerrainFace] = {}
var structure_tiles: Dictionary[Vector3i, StructureTile] = {}
var map_changed: bool = true
@export var height_source: HeightSource

func _ready() -> void:
	for t: Vector2i in [Vector2i(0, 0), Vector2i(0, -1), Vector2i(-1, 0), Vector2i(-1, -1)]:
		load_region_at(Vector3i(t.x, t.y, super_region_level))
		load_region_at(Vector3i(t.x, t.y, region_level))
		if not Engine.is_editor_hint():
			build_collider_at(Vector3i(t.x, t.y, collider_level))

func _physics_process(_delta: float) -> void:
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null:
		return
	var player_pos: Vector2 = Vector2(camera.global_position.x, camera.global_position.z)
	var snapped_player_pos: Vector2 = player_pos.snapped(load_update_camera_snap)
	if snapped_player_pos != previous_snapped_player_pos:
		previous_snapped_player_pos = snapped_player_pos
		map_changed = true
		prune_regions(player_pos)
		identify_load_regions(player_pos)
		prune_colliders(player_pos)
		prune_structures(player_pos)
	load_regions()
	if not Engine.is_editor_hint():
		build_one_collider(player_pos)
	build_structures(player_pos)
	if map_changed:
		update_faces(player_pos)
		map_changed = false

func region_for(hrc: Vector3i) -> Region:
	var region_hrc: Vector3i
	if hrc.z < face_uses_region_level:
		region_hrc = Hrc.ancestor_at_level(hrc, region_level)
	else:
		region_hrc = Hrc.ancestor_at_level(hrc, super_region_level)
	var region: Region = loaded_regions.get(region_hrc)
	return region

func load_region_at(region_id: Vector3i) -> void:
	var region: Region = Region.create(region_id, region_step_count, height_source)
	loaded_regions[region_id] = region
	if region_id.z == super_region_level or faces.has(region_id):
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
	for level: int in [region_level, super_region_level]:
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
			region.queue_free()


func update_faces(player_pos) -> void:
	#var faces_by_level: Array[TerrainFace] = []
	for face: TerrainFace in $Faces.get_children():
		if Hrc.relative_axis_distance(face.face_id, player_pos) < 1.0 and face.face_id.z > min_face_level:
			var subfaces: Array = Hrc.children(face.face_id)
			if subfaces.any(func(sub_id: Vector3i): return region_for(sub_id) == null):
				continue
			for sub_id: Vector3i in subfaces:
				add_face(sub_id)
			$Faces.remove_child(face)
	for face: TerrainFace in faces.values():
		if not face.is_inside_tree() and Hrc.relative_axis_distance(face.face_id, player_pos) > 2.0:
			$Faces.add_child(face)
			for sub_id: Vector3i in Hrc.children(face.face_id):
				deactivate_face(sub_id)
		if face.level == super_region_level and not loaded_regions.has(face.face_id):
			deactivate_face(face.face_id)

func add_face(face_id: Vector3i) -> void:
	if not faces.has(face_id):
		faces[face_id] = TerrainFace.create(face_id, region_for(face_id).mesh_material())
	if not faces[face_id].is_inside_tree():
		$Faces.add_child(faces[face_id])
	for direction: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var neighbour_id: Vector3i = Hrc.neighbour_in(face_id, direction)
		if faces.has(neighbour_id):
			faces[face_id].set_neighbour(direction, true)
			faces[neighbour_id].set_neighbour(-direction, true)

func deactivate_face(face_id: Vector3i) -> void:
	if !faces.has(face_id):
		return
	var face: TerrainFace = faces[face_id]
	for sub_id: Vector3i in Hrc.children(face_id):
		deactivate_face(sub_id)
	faces.erase(face_id)
	for direction: Vector2i in [Vector2i(0, 1), Vector2i(1, 0), Vector2i(0, -1), Vector2i(-1, 0)]:
		var neighbour_id: Vector3i = Hrc.neighbour_in(face_id, direction)
		if faces.has(neighbour_id):
			faces[neighbour_id].set_neighbour(-direction, false)
			
	face.queue_free()

func build_one_collider(player_pos: Vector2) -> void:
	var collider_load_distance: int = 2
	for x: int in range(-collider_load_distance, collider_load_distance + 1):
		for y: int in range(-collider_load_distance, collider_load_distance + 1):
			var collider_id: Vector3i = Hrc.world_to_hrc_id(player_pos, collider_level) + Vector3i(x, y, 0)
			if build_collider_at(collider_id):
				return

func build_collider_at(collider_id: Vector3i) -> bool:
	var region: Region = loaded_regions.get(Hrc.ancestor_at_level(collider_id, region_level))
	if region != null and not loaded_colliders.has(collider_id):
		var collider: TerrainCollider = TerrainCollider.create(collider_id, region.image_buffers)
		loaded_colliders[collider_id] = collider
		_add_collider(collider)
		return true
	return false

func _add_collider(collider: TerrainCollider) -> void:
	$Colliders.add_child(collider)

func prune_colliders(player_pos: Vector2) -> void:
	for collider: TerrainCollider in $Colliders.get_children():
		# todo: don't pune colliders with active rigidbodies on them
		if collider.relative_axis_distance(player_pos) > 4.8 and collider.relative_axis_distance(Vector2(0, 0)) > 6:
			loaded_colliders.erase(collider.region_id)
			collider.queue_free()
		else:
			loaded_colliders[collider.region_id] = collider

func build_structures(player_pos: Vector2) -> void:
	var structure_load_distance: int = 2
	for x: int in range(-structure_load_distance, structure_load_distance + 1):
		for y: int in range(-structure_load_distance, structure_load_distance + 1):
			var tile_id: Vector3i = Hrc.world_to_hrc_id(player_pos, structure_level) + Vector3i(x, y, 0)
			if not structure_tiles.has(tile_id):
				var structure_tile: StructureTile = StructureTile.create(tile_id, height_source)
				structure_tiles[tile_id] = structure_tile
				$Structures.add_child(structure_tile)
				return

func prune_structures(player_pos: Vector2) -> void:
	for structure: StructureTile in $Structures.get_children():
		if Hrc.relative_axis_distance(structure.tile_id, player_pos) > 2.8:
			structure_tiles.erase(structure.tile_id)
			structure.queue_free()
