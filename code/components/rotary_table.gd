class_name RotaryTable
extends Component

@export var max_rotation: float = 45
@export var min_rotation: float = -45
@export var step: float = 1
@export var rotation_channel: SignalConnection.Channel = SignalConnection.Channel.GREEN
var density: float = 200
var rot: float = 0

func _ready() -> void:
	for child in get_children():
		if child is Component and child != $RComponents:
			remove_child(child)
			child.transform = $RComponents.transform.inverse() * child.transform
			$RComponents.add_component(child)
	$RComponents.changed.connect(func(): changed.emit())
	var typ: Dictionary[SignalConnection.Channel, SignalType] = {
		rotation_channel: SignalType.new("deg", min_rotation, max_rotation, 5)
	}
	$SignalConnection.own_type = typ
	rotate_to(rot)


func physics_properties() -> PhysicsProperties:
	var own: PhysicsProperties = PhysicsProperties.box($CenterOfMass.position, $CollisionShape3D.shape.size, density)
	return PhysicsProperties.combine([own, $RComponents.physics_properties()]).transformed(transform)

func shapes() -> Array[CollisionShape3D]:
	var shape: CollisionShape3D = $CollisionShape3D.duplicate()
	shape.transform = transform * shape.transform
	shape.set_meta("component", self)
	var collisionshapes: Array[CollisionShape3D] = [shape]
	for inner_shape_original: CollisionShape3D in $RComponents.shapes():
		var inner_shape: CollisionShape3D = inner_shape_original.duplicate()
		inner_shape.transform = transform * inner_shape.transform
		collisionshapes.append(inner_shape)
	return collisionshapes

func forces() -> Array[Force]:
	var f: Array[Force] = []
	for force in $RComponents.forces():
		f.append(force.transformed(transform))
	return f

func destroy(_where: Vector3) -> void:
	var parent: CompositeComponent = get_parent()
	if parent == null:
		return
	parent.remove_child(self)
	changed.emit()
	var components: CompositeComponent = $RComponents
	remove_child(components)
	components.owner = null
	components.transform = transform * components.transform
	parent.add_component(components)
	queue_free()

func all_components() -> Array[Component]:
	# important: self must be before any child components (so when removing this will be removed with its children first)
	var ac: Array[Component] = [self]
	ac.append_array($RComponents.all_components())
	return ac

func connected_components() -> Array[Component]:
	var connected: Array[Component] = []
	connected.assign($Connection.get_overlapping_areas().map(func(area): return area.get_parent()))
	return connected

func rotate_to(r: float) -> void:
	r = clamp(r, min_rotation, max_rotation)
	#if rot == r:
		#return
	rot = r
	$Top.rotation_degrees.y = -rot
	$RComponents.transform = $Top.transform * $Top/Corner.transform
	$RComponents.recalculate()

func rotate_clockwise() -> void:
	rotate_to(rot-5)

func rotate_counterclockwise() -> void:
	rotate_to(rot+5)

func _on_signal_connection_typed_changed(channel: SignalConnection.Channel, value: float) -> void:
	if channel == rotation_channel:
		rotate_to(value)
