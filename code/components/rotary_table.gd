class_name RotaryTable
extends Component

@export var max_rotation: float = 45
@export var min_rotation: float = -45
@export var step: float = 5
var density: float = 200
var rot: float = 0
var ship: Airship:
	set(s):
		$RComponents.ship = s
		ship = s

func _ready() -> void:
	for child in get_children():
		if child is Component and child != $RComponents:
			remove_child(child)
			child.transform = $RComponents.transform.inverse() * child.transform
			$RComponents.add_component(child)
	$RComponents.ship = ship
	$RComponents.changed.connect(func(): changed.emit())


func physics_properties() -> PhysicsProperties:
	var own: PhysicsProperties = PhysicsProperties.box($CenterOfMass.position, $CollisionShape3D.shape.size, density)
	return PhysicsProperties.combine([own, $RComponents.physics_properties()])

func shapes() -> Array[CollisionShape3D]:
	var shape: CollisionShape3D = $CollisionShape3D.duplicate()
	shape.transform = transform * shape.transform
	shape.set_meta("component", self)
	var collisionshapes: Array[CollisionShape3D] = [shape]
	for inner_shape: CollisionShape3D in $RComponents.shapes():
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

func do_rotate(delta: float) -> void:
	rot = clamp(rot + delta, min_rotation, max_rotation)
	$Top.rotation_degrees.y = rot
	$RComponents.transform = $Top.transform * $Top/Corner.transform
	prints("rotating to", rot)
	$RComponents.recalculate()

func rotate_clockwise() -> void:
	do_rotate(-5)

func rotate_counterclockwise() -> void:
	do_rotate(5)

func accept_signal() -> bool:
	return true
