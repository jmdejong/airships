@tool
class_name GroundFace
extends Node3D

var area: Rect2
var config: Config
var height_source: HeightSource
var aabb: AABB
var level: int
var all_positions: Dictionary[Vector3i, GroundFace]
var face_id: Vector3i = Vector3i(0, 0, 0)
var detail_border: Dictionary[Vector2i, bool] = {}
var borders: Dictionary[Vector2i, MeshInstance3D] = {}
var detail_border_meshes: Dictionary[Vector2i, Mesh] = {}
var no_detail_border_meshes: Dictionary[Vector2i, Mesh] = {}
var _active = true
var step_size: float
var tile_buffers: TileBuffers
static var scene: PackedScene = preload("res://scenes/ground_face.tscn")
var self_node: Node3D
var subfaces: Node3D
var self_active: bool = true:
	set(val):
		self_active = val
		$Self.visible = self_active
		%CollisionShape3D.disabled = !self_active
		#if self_active:
			#if !self_node.is_inside_tree():
				#add_child(self_node)
		#else:
			#if self_node.is_inside_tree():
				#remove_child(self_node)
var subfaces_active: bool = false:
	set(val):
		subfaces_active = val
		$Subfaces.visible = subfaces_active
		if subfaces_active:
			if subfaces.get_child_count() == 0:
				subdivide()
			for subface: GroundFace in subfaces.get_children():
				subface.activate()
			#if !subfaces.is_inside_tree():
				#add_child(subfaces)
		else:
			for subface: GroundFace in subfaces.get_children():
				subface.deactivate()
				subface.prune()
			#if subfaces.is_inside_tree():
				#remove_child(subfaces)
		

static func create(level: int, area: Rect2, config: Config, height_source: HeightSource, face_id: Vector3i, all_positions: Dictionary[Vector3i, GroundFace]) -> GroundFace:
	var face: GroundFace = scene.instantiate()
	face.level = level
	face.config = config
	face.height_source = height_source
	face.area = area
	face.face_id = face_id
	face.all_positions = all_positions
	face.name = "GroundFace_%d_%d__%d" % [face_id.x, face_id.y, face_id.z]
	all_positions[face_id] = face
	return face

func _ready() -> void:
	assert(area.size.x == area.size.y)
	step_size = area.size.x / config.segments
	var extremes: Vector2 = height_source.extremes(area)
	aabb = AABB(Vector3(area.position.x, extremes.x, area.position.y), Vector3(area.size.x, extremes.y - extremes.x, area.size.y))
	self_node = $Self
	subfaces = $Subfaces
	initialize_nodes()

func initialize_nodes() -> void:
	#remove_child(subfaces)
	tile_buffers = height_source.buffers_at(area, config.segments)
	%Mesh.mesh = build_mesh()
	borders = {
		Vector2i(1, 0): $"Self/Border_X+",
		Vector2i(0, 1): $"Self/Border_Y+",
		Vector2i(-1, 0): $"Self/Border_X-",
		Vector2i(0, -1): $"Self/Border_Y-"
	}
	for border: Vector2i in borders:
		detail_border_meshes[border] = build_border(border, true)
		no_detail_border_meshes[border] = build_border(border, false)
	%Water.position = Vector3(area.get_center().x, -0.35, area.get_center().y)
	%Water.scale = Vector3(area.size.x, 1, area.size.y)
	initialize_collisions()
	initialize_structures()

func initialize_collisions() -> void:
	%CollisionShape3D.position = Vector3(area.get_center().x, 0, area.get_center().y)
	%CollisionShape3D.scale = Vector3.ONE * step_size
	var shape: HeightMapShape3D = HeightMapShape3D.new()
	shape.map_width = config.segments + 1
	shape.map_depth = config.segments + 1
	var height_buffer: PackedFloat32Array = PackedFloat32Array()
	height_buffer.resize(tile_buffers.heights.size())
	for i in tile_buffers.heights.size():
		height_buffer[i] = tile_buffers.heights[i] / step_size
	shape.map_data = height_buffer
	%CollisionShape3D.shape = shape

func initialize_structures() -> void:
	#if level == config.structure_mesh_level:
		#prints("assigneing multimeshes")
		#for multimesh: MultiMesh in height_source.structures(area).multimeshes():
			#prints("multimesh", multimesh)
			#var m: MultiMeshInstance3D = MultiMeshInstance3D.new()
			#m.multimesh = multimesh
			#%Structures.add_child(m)
	if level == config.structure_node_level:
		for structure: Node3D in height_source.structures(area).nodes():
			%Structures.add_child(structure)

func _exit_tree() -> void:
	_active = false
	for direction in borders.keys():
		var neighbour := neighbour_in(direction)
		if neighbour != null:
			neighbour.update_border(-direction)

func active_subfaces() -> Array[GroundFace]:
	var faces: Array[GroundFace] = []
	if not self_active:
		faces.assign($Subfaces.get_children())
	return faces

func neighbour_in(direction: Vector2i) -> GroundFace:
	var other_id: Vector3i = Vector3i(face_id.x + direction.x, face_id.y + direction.y, face_id.z)
	return all_positions.get(other_id)

func update_all_borders() -> void:
	for direction: Vector2i in borders.keys():
		update_border(direction)
		var neighbour := neighbour_in(direction)
		if neighbour != null:
			neighbour.update_border(-direction)

func update_border(direction: Vector2i):
	var neighbour: GroundFace = neighbour_in(direction)
	var neighbour_detailed: bool = neighbour != null and neighbour.is_active()
	var self_detailed: bool = detail_border.get(direction, false)
	if neighbour_detailed != self_detailed or borders[direction].mesh == null:
		if neighbour_detailed:
			borders[direction].mesh = detail_border_meshes[direction]
		else:
			borders[direction].mesh = no_detail_border_meshes[direction]
		detail_border[direction] = neighbour_detailed

func update_camera(pos: Vector3, tasks_per_tick: Counter) -> void:
	var nearest_to_cam: Vector3 = pos.clamp(aabb.position, aabb.end)
	var distance: float = pos.distance_to(nearest_to_cam)
	var my_size: float = area.size.length()
	if self_active and distance < my_size and level > 0 and tasks_per_tick.value > 0 and height_source.prepare_area(area, config.segments * 2):
		tasks_per_tick.value -= 1
		self_active = false
		subfaces_active = true
			
	if not self_active and distance > my_size:
		self_active = true
		subfaces_active = false

func subdivide() -> void:
	for d in [Vector2(0, 0), Vector2(0, 1), Vector2(1, 0), Vector2(1, 1)]:
		var subface: GroundFace = create(
			level-1,
			Rect2(area.position + d * area.size / 2, area.size/2),
			config,
			height_source,
			Vector3i(face_id.x * 2 + d.x, face_id.y * 2 + d.y, face_id.z + 1),
			all_positions
		)
		subfaces.add_child(subface)

func prune() -> void:
	for child: GroundFace in subfaces.get_children():
		child.queue_free()

func activate() -> void:
	_active = true
	all_positions[face_id] = self
	update_all_borders()

func deactivate() -> void:
	_active = false
	all_positions.erase(face_id)
	prune()
	update_all_borders()

func is_active() -> bool:
	return _active


func build_mesh() -> Mesh:
	var builder = MeshBuilder.new(tile_buffers, config)
	builder.vertices = tile_buffers.positions
	builder.colors = tile_buffers.colors
	var w: int = config.segments + 1
	for x: int in range(1, config.segments-1):
		for y: int in range(1, config.segments-1):
			var i: int = x+y*w
			if (x + y) % 2 == 1:
				builder.indices.append_array([i, i+1, i+w, i+w, i+1, i+w+1])
			else:
				builder.indices.append_array([i, i+1, i+w+1, i+w, i, i+w+1])
			#var corners: PackedVector2Array = [Vector2(x, y), Vector2(x, y+1), Vector2(x+1, y), Vector2(x+1, y+1)]
			#if (x + y) % 2 == 1:
				#builder.add_tri(corners[0], corners[2], corners[1])
				#builder.add_tri(corners[1], corners[2], corners[3])
			#else:
				#builder.add_tri(corners[0], corners[2], corners[3])
				#builder.add_tri(corners[1], corners[0], corners[3])
	var b: int = w*(w-2)
	for i: int in range(2, config.segments, 2):
		var x: int = i
		var y: int = i*w
		builder.indices.append_array([
			x+w-1, x, x+w,
			x, x+w+1, x+w,
			x+b-1, x+b, x+b+w,
			x+b+w, x+b, x+b+1,
			y-w+1, y+1, y,
			y, y+1, y+w+1,
			y-2, y+w-1, y+w-2,
			y+w-2, y+w-1, y+2*w-2 
		])
	var mesh := ArrayMesh.new()
	builder.apply(mesh)
	return mesh


const dir_to_from: Dictionary[Vector2i, Vector2i] = {
	Vector2i(1, 0): Vector2i(1, 0),
	Vector2i(0, 1): Vector2i(1, 1),
	Vector2i(-1, 0): Vector2i(0, 1),
	Vector2i(0, -1): Vector2i(0, 0)
}

func build_border(direction: Vector2i, detailed: bool) -> Mesh:
	var builder = MeshBuilder.new(tile_buffers, config)
	var from: Vector2i = dir_to_from[direction] * config.segments
	var step: Vector2i = Vector2i(-direction.y, direction.x)
	var inner: Vector2i = -direction
	for i: int in range(1,config.segments, 2):
		var base: Vector2i = from + i * step
		if not detailed:
			builder.add_tri(base + inner, base - step, base + step)
		else:
			builder.add_tri(base, base + step, base + inner)
			builder.add_tri(base - step, base, base + inner)
	var mesh := ArrayMesh.new()
	builder.apply(mesh)
	return mesh


class MeshBuilder:
	var tile_buffers: TileBuffers
	var config: Config
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var tex_uvs := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	
	func _init(tile_buffers: TileBuffers, config: Config) -> void:
		self.tile_buffers = tile_buffers
		self.config = config
		
	func add_tri(t0: Vector2i, t1: Vector2i, t2: Vector2i) -> void:
		var c0: Vector3 = tile_buffers.pos_at(t0)
		var c1: Vector3 = tile_buffers.pos_at(t1)
		var c2: Vector3 = tile_buffers.pos_at(t2)
		var ind: int = vertices.size()
		vertices.append_array([c0, c1, c2])
		colors.append_array([tile_buffers.color_modifier_at(t0), tile_buffers.color_modifier_at(t1), tile_buffers.color_modifier_at(t2)])
		indices.append_array(PackedInt32Array([ind+0, ind+1, ind+2]))
	
	
	func apply(mesh: ArrayMesh) -> void:
		var surface = []
		surface.resize(Mesh.ARRAY_MAX)
		surface[Mesh.ARRAY_VERTEX] = vertices
		surface[Mesh.ARRAY_COLOR] = colors
		surface[Mesh.ARRAY_INDEX] = indices
		mesh.add_surface_from_arrays(
			Mesh.PRIMITIVE_TRIANGLES,
			surface,
			[],
			{}
		)

class Config extends RefCounted:
	var segments: int
	var structure_node_level: int = 4
	var structure_mesh_level: int = 5
	func _init(segments: int) -> void:
		self.segments = segments
