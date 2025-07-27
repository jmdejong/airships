class_name CompositeComponent
extends Component

signal changed

@export var keep_empty: bool

var _physics_properties: PhysicsProperties
var _shapes: Array[CollisionShape3D]
var _forces: Array[Force]
var component_cells: Dictionary[Vector2, Node3D]
var ship: Airship:
	set(s):
		for child in get_children():
			if child is Component:
				child.ship = s
		ship = s
var should_recalculate := false

func _ready() -> void:
	for child in get_children():
		if child is Component:
			child.ship = ship
			child.changed.connect(recalculate)
	_recalculate()

func physics_properties() -> PhysicsProperties:
	return _physics_properties

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
	var all_properties: Array[PhysicsProperties] = []
	_shapes = []
	_forces = []
	if !keep_empty and get_child_count() == 0 and get_parent != null:
		changed.emit()
		queue_free()
	for child in get_children():
		if not (child is Component):
			continue
		var component: Component = child
		all_properties.append(component.physics_properties())
		for force: Force in component.forces():
			_forces.append(force.transformed(transform))
		for source_shape: CollisionShape3D in component.shapes():
			var shape = source_shape.duplicate()
			shape.transform = transform * shape.transform
			_shapes.append(shape)
	_physics_properties = PhysicsProperties.combine(all_properties).transformed(transform)
	changed.emit()

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
	for c in get_children():
		if c is Component:
			ac.append_array(c.all_components())
	return ac

func connected_components() -> Array[Component]:
	return []
