@tool
class_name ResizableComponent
extends BaseComponent

@export var fixed_size: Vector3 = Vector3.ONE * Global.block_size
@export var fixed_origin: Vector3 = Vector3.ZERO

var center: Vector3
@export var size: Vector3 = Vector3.ONE:
	set(v):
		v = (v / Global.block_size).ceil() * Global.block_size
		center = v / 2.0
		if fixed_size.x > 0:
			v.x = fixed_size.x
			center.x = fixed_origin.x
		if fixed_size.y > 0:
			v.y = fixed_size.y
			center.y = fixed_origin.y
		if fixed_size.z > 0:
			v.z = fixed_size.z
			center.z = fixed_origin.z
		var is_changed: bool = size != v
		size = v
		if is_inside_tree() and is_changed:
			update_sizes()
@export var connect_x: bool = false
@export var connect_y: bool = false
@export var connect_z: bool = false
@export_tool_button("Construct") var construct_button: Callable = construct

@export var density: float = 100

func _enter_tree() -> void:
	update_sizes()

func update_sizes() -> void:
	var origin: Vector3 = center
	var ms: BoxMesh = $MeshInstance3D.mesh.duplicate()
	ms.size = size
	$MeshInstance3D.mesh = ms
	$MeshInstance3D.position = origin
	$CollisionShape3D.position = origin
	$CollisionShape3D.shape = _box_shape(size)
	$CenterOfMass.position = origin
	$Connection.position = origin
	if connect_x:
		$Connection/CollisionShapeX.shape = _box_shape(size + Vector3(0.01, -0.01, -0.01))
	if connect_y:
		$Connection/CollisionShapeY.shape = _box_shape(size + Vector3(-0.01, 0.01, -0.01))
	if connect_z:
		$Connection/CollisionShapeZ.shape = _box_shape(size + Vector3(-0.01, -0.01, 0.01))

func construct() -> void:
	if not has_node(^"CollisionShape3D"):
		var collision_node: CollisionShape3D = CollisionShape3D.new()
		add_child(collision_node)
		collision_node.name = "CollisionShape3D"
		collision_node.owner = get_tree().edited_scene_root
	if not has_node(^"CenterOfMass"):
		var centerofmass_node: Node3D = Node3D.new()
		add_child(centerofmass_node)
		centerofmass_node.name = "CenterOfMass"
		centerofmass_node.owner = get_tree().edited_scene_root
	if (connect_x or connect_y or connect_z) and not has_node(^"Connection"):
		var connection_node: Area3D = preload("res://scenes/connection.tscn").instantiate()
		add_child(connection_node)
		connection_node.name = "Connection"
		connection_node.owner = get_tree().edited_scene_root
	_fix_connection_shape("CollisionShapeX", connect_x)
	_fix_connection_shape("CollisionShapeY", connect_y)
	_fix_connection_shape("CollisionShapeZ", connect_z)
	update_sizes()

func physics_properties() -> PhysicsProperties:
	return PhysicsProperties.box(
		transform * $CenterOfMass.position,
		size,
		density
	)

func destroy(where: Vector3) -> void:
	if get_parent() == null:
		return
	var size_block: Vector3i = (size / Global.block_size).ceil()
	var local_where: Vector3 = where * global_transform
	var closest: Vector3i = Vector3i(local_where / Global.block_size).clamp(Vector3i.ZERO, size_block - Vector3i.ONE)
	if size_block != Vector3i.ONE:
		var new_components: Array[Component] = []
		for area in subdivide(size, closest * Global.block_size, Global.block_size):
			if area.get_volume() > 0:
				var clone: ResizableComponent = duplicate()
				clone.size = area.size
				clone.position = transform * area.position
				new_components.append(clone)
		get_parent().add_components(new_components)
	get_parent().remove_child(self)
	changed_physics.emit()
	changed_shapes.emit()
	queue_free()

func subdivide(size: Vector3, out: Vector3, step: float) -> Array[AABB]:
	var size_before: Vector3 = out
	var size_before_with: Vector3 = size_before + Vector3(step, step, step)
	var size_after: Vector3 = size - size_before_with
	var divisions: Array[AABB] = []
	if fixed_size.x <= 0:
		divisions.append_array([
			AABB(Vector3.ZERO, Vector3(size_before.x, size.y, size.z)),
			AABB(Vector3(size_before_with.x, 0, 0), Vector3(size_after.x, size.y, size.z)),
		])
	if fixed_size.z <= 0:
		divisions.append_array([
			AABB(Vector3(size_before.x, 0, 0), Vector3(step, size.y, size_before.z)),
			AABB(Vector3(size_before.x, 0, size_before_with.z), Vector3(step, size.y, size_after.z)),
		])
	if fixed_size.y <= 0:
		divisions.append_array([
			AABB(Vector3(size_before.x, 0, size_before.z), Vector3(step, size_before.y, step)),
			AABB(Vector3(size_before.x, size_before_with.y, size_before.z), Vector3(step, size_after.y, step))
		])
	return divisions

func _fix_connection_shape(node_name: StringName, enabled: bool) -> void:
	var node: CollisionShape3D = $Connection.get_node_or_null(NodePath(node_name))
	if enabled:
		if node == null:
			node = CollisionShape3D.new()
			$Connection.add_child(node)
			node.name = node_name
			node.owner = get_tree().edited_scene_root
	if not enabled and node != null:
		node.queue_free()

func _box_shape(size: Vector3) -> BoxShape3D:
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = size
	return bs

func to_own_json() -> Dictionary[String, Variant]:
	return {"size": [size.x, size.y, size.z]}

func initialize_from_json(json: Dictionary) -> void:
	size = Components.parse_vector3(json["size"])
	update_sizes()
