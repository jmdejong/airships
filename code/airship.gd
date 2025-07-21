class_name Airship
extends RigidBody3D

var displaced_volume: float
var center_of_volume: Vector3
var forces: Array[Force]
var drag_area_coefficient: float
static var CompositeComponent = preload("res://scenes/components/composite.tscn")

func _ready() -> void:
	$Components.changed.connect(calculate_components)
	calculate_components()
	await get_tree().create_timer(0.05).timeout
	check_connections()
	for child in get_children():
		if child is Component and child != $Components:
			child.reparent($Components)
	$Components.ship = self
	prints("mv", mass, displaced_volume)

func calculate_components() -> void:

	self.center_of_volume = $Components.center_of_volume()
	self.center_of_mass = $Components.center_of_mass()
	self.mass = max(0.01, $Components.mass())
	self.displaced_volume = $Components.displaced_volume()
	self.forces = $Components.forces()
	self.drag_area_coefficient = pow(self.displaced_volume, 2.0/3.0) * 2.0
	set_shapes()
	#prints("m:", mass, "v", displaced_volume, "d", self.drag_area_coefficient)
	$CenterOfMassMarker.position = center_of_mass
	$CenterOfVolumeMarker.position = center_of_volume

func set_shapes() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			remove_child(child)
	for source_shape: CollisionShape3D in $Components.shapes():
		var shape = source_shape.duplicate()
		add_child(shape)

func _physics_process(delta: float) -> void:
	var air_density: float = Atmosphere.air_density(to_global(center_of_volume).y)
	var displaced_air_mass := displaced_volume * air_density
	var weight := mass - displaced_air_mass
	apply_force(-displaced_air_mass * Atmosphere.gravity_vec(), to_global(center_of_volume) - global_position)
	for force: Force in forces:
		var global_force: Force = force.transformed(global_transform)
		apply_force(global_force.direction, global_force.pos - global_position)
	# https://en.wikipedia.org/wiki/Drag_(physics)#The_drag_equation
	var drag: float = 0.5 * air_density * linear_velocity.length_squared() * drag_area_coefficient
	apply_central_force(-linear_velocity.normalized() * drag)

func is_build_target() -> bool:
	return true

func is_floor() -> bool:
	return true

func check_connections() -> void:
	var all_components: Array[Component] = $Components.all_components()
	if all_components.is_empty():
		queue_free()
		return
	var start: Component = all_components[0]
	var known: Dictionary[Component, bool] = {}
	for c in all_components:
		known[c] = false
	known[start] = true
	var fringe: Array[Component] = [start]
	while !fringe.is_empty():
		#prints("f", fringe)
		var c: Component = fringe.pop_back()
		#prints(c, c.connected_components())
		for n in c.connected_components():
			if known.has(n) and !known[n]:
				known[n] = true
				fringe.append(n)
	#prints(all_components.size(), known.size())
	var unconnected: Array[Component] = []
	var parents: Dictionary[CompositeComponent, bool]
	for c: Component in all_components:
		if !known[c]:
			unconnected.append(c)
			var parent: CompositeComponent = c.get_parent()
			parent.remove_child(c)
			parents[parent] = true
	for parent: CompositeComponent in parents.keys():
		parent.recalculate()
	if !unconnected.is_empty():
		var new_ship: Airship = preload("res://scenes/airship.tscn").instantiate()
		new_ship.transform = transform
		new_ship.linear_velocity = linear_velocity
		new_ship.angular_velocity = angular_velocity
		var new_components: CompositeComponent = new_ship.get_node("Components")
		for c in unconnected:
			new_components.add_child(c)
		get_parent().add_child(new_ship)

func build_component(pos: Vector3, component: ComponentBlueprint, transform) -> void:
	var comp_node: Component = component.create()
	comp_node.transform = transform
	comp_node.position += pos
	$Components/Custom.add_component(comp_node)

func destroy_component(component: Component, pos: Vector3):
	component.destroy(pos)
	await get_tree().create_timer(0.05).timeout
	check_connections()
