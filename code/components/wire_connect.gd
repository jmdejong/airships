extends BaseComponent



var connected_shapes: Array[SignalShapeConnection] = []
var connected_directions: Array[String] = []
var connected_direction_map: Dictionary[String, bool] = {}
var _v: int = 0
var _v_last: int = -1

func _ready() -> void:
	update_connected_directions()

func update_connected_directions() -> void:
	if _v == _v_last:
		return
	_v_last = _v
	connected_direction_map = {}
	for ssc: SignalShapeConnection in connected_shapes:
		var shape: CollisionShape3D = ssc.local_shape
		var dir = shape.name.trim_prefix("Connection_")
		assert(dir.length() == 2)
		connected_direction_map[dir] = true
	connected_directions = []
	connected_directions.append_array(connected_direction_map.keys())
	for child: Node in get_children():
		if child is CollisionShape3D:
			var dir = child.name.trim_prefix("Collision_")
			assert(dir.length() == 2)
			child.visible = connected_direction_map.get(dir, false)
	changed.emit()

func shapes() -> Array[CollisionShape3D]:
	var collisionshapes: Array[CollisionShape3D] = []
	for child: Node in get_children():
		if child is CollisionShape3D:
			var dir: String = child.name.trim_prefix("Collision_")
			assert(dir.length() == 2)
			if !connected_direction_map.get(dir, false):
				continue
			var c: CollisionShape3D = child.duplicate()
			c.set_meta("component", self)
			c.transform = transform * c.transform
			collisionshapes.append(c)
	return collisionshapes


class SignalShapeConnection:
	var rid: RID
	var area_shape_index: int
	var local_area: Area3D
	var local_shape: CollisionShape3D
	
	func _init(rid: RID, area_shape_index: int, local_area: Area3D, local_shape_index: int) -> void:
		self.rid = rid
		self.area_shape_index = area_shape_index
		self.local_area = local_area
		self.local_shape = local_area.shape_owner_get_owner(local_area.shape_find_owner(local_shape_index))
	
	func equals(other: SignalShapeConnection) -> bool:
		return rid == other.rid && area_shape_index == other.area_shape_index && local_area == other.local_area && local_shape == other.local_shape

func _on_signal_connection_area_shape_entered(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if area.get_parent().get_ship() != get_ship():
		return
	connected_shapes.append(SignalShapeConnection.new(area_rid, area_shape_index, $SignalConnection, local_shape_index))
	_v += 1
	update_connected_directions.call_deferred()

func _on_signal_connection_area_shape_exited(area_rid: RID, _area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	var s: SignalShapeConnection = SignalShapeConnection.new(area_rid, area_shape_index, $SignalConnection, local_shape_index)
	var index: int = connected_shapes.find_custom(func(ssc: SignalShapeConnection) -> bool: return s.equals(ssc))
	if index >= 0:
		connected_shapes.remove_at(index)
		_v += 1
		update_connected_directions.call_deferred()


func _on_connection_area_shape_entered(area_rid: RID, area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	if area.get_parent().get_ship() != get_ship():
		return
	connected_shapes.append(SignalShapeConnection.new(area_rid, area_shape_index, $SignalConnection, local_shape_index))
	_v += 1
	update_connected_directions.call_deferred()


func _on_connection_area_shape_exited(area_rid: RID, _area: Area3D, area_shape_index: int, local_shape_index: int) -> void:
	var s: SignalShapeConnection = SignalShapeConnection.new(area_rid, area_shape_index, $SignalConnection, local_shape_index)
	var index: int = connected_shapes.find_custom(func(ssc: SignalShapeConnection) -> bool: return s.equals(ssc))
	if index >= 0:
		connected_shapes.remove_at(index)
		_v += 1
		update_connected_directions.call_deferred()
