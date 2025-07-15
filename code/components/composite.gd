class_name CompositeComponent
extends Component

signal changed

@export var keep_empty: bool

var _mass: float
var _displaced_volume: float
var _center_of_mass: Vector3
var _center_of_volume: Vector3
var _shapes: Array[CollisionShape3D]
var _forces: Array[Force]
var component_cells: Dictionary[Vector2, Node3D]
var ship: Airship:
	set(s):
		for child in get_children():
			child.ship = s
		ship = s
var should_recalculate := false

func _ready() -> void:
	for child in get_children():
		child.ship = ship
		child.changed.connect(recalculate)
	_recalculate()

func recalculate() -> void:
	if get_tree() == null:
		return
	_recalculate()
	#should_recalculate = true
	#await get_tree().create_timer(0.1).timeout
	#if should_recalculate:
		#should_recalculate = false
		#_recalculate()

func _recalculate() -> void:
	_mass = 0
	_displaced_volume = 0
	_center_of_mass = Vector3(0, 0, 0)
	_center_of_volume = Vector3(0, 0, 0)
	_shapes = []
	_forces = []
	if !keep_empty and get_child_count() == 0 and get_parent != null:
		get_parent().remove_child(self)
		changed.emit()
		queue_free()
	for component in get_children():
		var m: float = component.mass()
		var v: float = component.displaced_volume()
		_mass += m
		_displaced_volume += v
		var com: Vector3 = transform * component.center_of_mass()
		_center_of_mass += com * m
		var cov: Vector3
		if component.has_method("center_of_volume"):
			cov = transform * component.center_of_volume()
		else:
			cov = com
		_center_of_volume += cov * v
		if component.has_method("forces"):
			for force: Force in component.forces():
				_forces.append(force.transformed(transform))
		for source_shape: CollisionShape3D in component.shapes():
			var shape = source_shape.duplicate()
			shape.transform = transform * shape.transform
			_shapes.append(shape)
	if (_mass == 0.0):
		_center_of_mass = Vector3(0, 0, 0)
	else:
		_center_of_mass /= _mass
	if (_displaced_volume == 0.0):
		_center_of_volume = Vector3(0, 0, 0)
	else:
		_center_of_volume /= _displaced_volume
	changed.emit()

func displaced_volume() -> float:
	return _displaced_volume

func mass() -> float:
	return _mass

func center_of_mass() -> Vector3:
	return _center_of_mass

func center_of_volume() -> Vector3:
	return _center_of_volume

func shapes() -> Array[CollisionShape3D]:
	return _shapes

func forces() -> Array[Force]:
	return _forces

func add_component(component: Component) -> void:
	add_child(component)
	component.ship = ship
	component.changed.connect(recalculate)
	recalculate()

func add_components(components: Array[Component]) -> void:
	for component: Component in components:
		add_child(component)
		component.ship = ship
		component.changed.connect(recalculate)
	recalculate()

func all_components() -> Array[Component]:
	var ac: Array[Component] = []
	for c: Component in get_children():
		ac.append_array(c.all_components())
	return ac

func connected_components() -> Array[Component]:
	return []
