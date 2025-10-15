class_name CompositeComponent
extends Component

@export var keep_empty: bool

var _physics_properties: PhysicsProperties
var _shapes: Array[CollisionShape3D]
var _forces: Array[Force]
var should_recalculate := false

func _ready() -> void:
	for child in get_children():
		if child is Component:
			child.changed_physics.connect(recalculate_physics)
			child.changed_forces.connect(recalculate_forces)
			child.changed_shapes.connect(recalculate_shapes)
	recalculate_all()

func physics_properties() -> PhysicsProperties:
	return _physics_properties

func recalculate_physics() -> void:
	if !is_inside_tree():
		return
	var all_properties: Array[PhysicsProperties] = []
	if !keep_empty and get_child_count() == 0 and get_parent != null:
		queue_free()
	for child in get_children():
		if not (child is Component):
			continue
		var component: Component = child
		all_properties.append(component.physics_properties())
	_physics_properties = PhysicsProperties.combine(all_properties).transformed(transform)
	changed_physics.emit()


func recalculate_forces() -> void:
	if !is_inside_tree():
		return
	_forces = []
	if !keep_empty and get_child_count() == 0 and get_parent != null:
		queue_free()
	for child in get_children():
		if not (child is Component):
			continue
		var component: Component = child
		for force: Force in component.forces():
			_forces.append(force.transformed(transform))
	changed_forces.emit()


func recalculate_shapes() -> void:
	if !is_inside_tree():
		return
	_shapes = []
	if !keep_empty and get_child_count() == 0 and get_parent != null:
		queue_free()
	for child in get_children():
		if not (child is Component):
			continue
		var component: Component = child
		for source_shape: CollisionShape3D in component.shapes():
			var shape = source_shape.duplicate()
			shape.transform = transform * shape.transform
			_shapes.append(shape)
	changed_shapes.emit()

func recalculate_all() -> void:
	recalculate_physics()
	recalculate_forces()
	recalculate_shapes()

func shapes() -> Array[CollisionShape3D]:
	return _shapes

func forces() -> Array[Force]:
	return _forces

func add_component(component: Component) -> void:
	add_child(component)
	component.changed_physics.connect(recalculate_physics)
	component.changed_forces.connect(recalculate_forces)
	component.changed_shapes.connect(recalculate_shapes)
	recalculate_all()

func add_components(components: Array[Component]) -> void:
	for component: Component in components:
		add_child(component)
		component.changed_physics.connect(recalculate_physics)
		component.changed_forces.connect(recalculate_forces)
		component.changed_shapes.connect(recalculate_shapes)
	recalculate_all()

func all_components() -> Array[Component]:
	var ac: Array[Component] = []
	for c in get_children():
		if c is Component:
			ac.append_array(c.all_components())
	return ac

func connected_components() -> Array[Component]:
	return []
