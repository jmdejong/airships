class_name CompositeComponent
extends Component

@export var keep_empty: bool

var _physics_properties: PhysicsProperties
var _shapes: Array[CollisionShape3D]
var _forces: Array[Force]
var _physics_changed := true
var _forces_changed := true
var _shapes_changed := true

func _ready() -> void:
	for child in get_children():
		if child is Component:
			_connect_child_signals(child)
	recalculate_all()

func _physics_process(_delta: float) -> void:
	set_physics_process(false)
	if _physics_changed:
		_physics_changed = false
		_recalculate_physics()
	if _forces_changed:
		_forces_changed = false
		_recalculate_forces()
	if _shapes_changed:
		_shapes_changed = false
		_recalculate_shapes()

func physics_properties() -> PhysicsProperties:
	if _physics_properties == null:
		_recalculate_physics()
	return _physics_properties

func _recalculate_physics() -> void:
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

func _recalculate_forces() -> void:
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

func _recalculate_shapes() -> void:
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

func recalculate_physics() -> void:
	_physics_changed = true
	set_physics_process(true)
func recalculate_forces() -> void:
	_forces_changed = true
	set_physics_process(true)
func recalculate_shapes() -> void:
	_shapes_changed = true
	set_physics_process(true)

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
	_connect_child_signals(component)
	recalculate_all()

func add_components(components: Array[Component]) -> void:
	for component: Component in components:
		add_child(component)
		_connect_child_signals(component)
	recalculate_all()

func all_components() -> Array[Component]:
	var ac: Array[Component] = []
	for c in get_children():
		if c is Component:
			ac.append_array(c.all_components())
	return ac

func connected_components() -> Array[Component]:
	return []

func _connect_child_signals(component: Component) -> void:
	component.changed_physics.connect(recalculate_physics)
	component.changed_forces.connect(recalculate_forces)
	component.changed_shapes.connect(recalculate_shapes)
