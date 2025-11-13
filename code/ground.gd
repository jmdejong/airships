@tool
extends Node3D

@export var height_source: HeightSource = HexsHeightSource.new()

@export var level: int = 9
@export var segments: int = 16
@export var min_vertex_size: float = 1
var size: float = segments * 2**level * min_vertex_size
var area: Rect2 = Rect2(-size/2, -size/2, size, size)
var root_face: GroundFace
@export var tasks_per_tick: int = 1
#@export_tool_button("Regenerate") var regenerate: Callable = update_loaded_areas

func _ready() -> void:
	$StartPreview.visible = false
	var config: GroundFace.Config = GroundFace.Config.new(segments)
	root_face = GroundFace.create(level, area, config, height_source, Vector3i(0, 0, 0), {})
	add_child(root_face)
	root_face.activate()

func _enter_tree() -> void:
	if root_face != null:
		root_face.activate()

func _process(_delta: float) -> void:
	update_loaded_areas()

func update_loaded_areas():
	var camera: Camera3D = get_viewport().get_camera_3d()
	if camera == null or root_face == null:
		return
	var task_counter: Counter = Counter.new(tasks_per_tick)
	var queue: Array[GroundFace] = [root_face]
	var i: int = 0
	while i < queue.size():
		var face: GroundFace = queue[i]
		face.update_camera(camera.global_position, task_counter)
		queue.append_array(face.active_subfaces())
		i += 1
	#prints("queue size ", i)
	
	
