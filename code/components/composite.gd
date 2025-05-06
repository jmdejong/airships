extends Node3D

signal changed

var _mass: float
var _displaced_volume: float
var _center_of_mass: Vector3
var _center_of_volume: Vector3
var _shapes: Array[CollisionShape3D]
var _forces: Array[Force]
var component_cells: Dictionary[Vector2, Node3D]

func _ready() -> void:
	for child in get_children():
		child.changed.connect(_recalculate)
	_recalculate()

func _recalculate() -> void:
	_mass = 0
	_displaced_volume = 0
	_center_of_mass = Vector3(0, 0, 0)
	_center_of_volume = Vector3(0, 0, 0)
	_shapes = []
	_forces = []
	#component_cells += 
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

func add_component(component: Node3D) -> void:
	add_child(component)
	component.changed.connect(_recalculate)
	_recalculate()
