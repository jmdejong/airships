class_name Airship
extends RigidBody3D

var displaced_volume: float
var center_of_volume: Vector3
var forces: Array[Force]
static var CompositeComponent = preload("res://scenes/components/composite.tscn")

func _ready() -> void:
	$Components.changed.connect(calculate_components)
	calculate_components()
	await get_tree().create_timer(0.05).timeout
	check_connections()
	for child in get_children():
		if child is Component and child != $Components:
			child.reparent($Comonents)
	

func calculate_components() -> void:

	self.center_of_volume = $Components.center_of_volume()
	self.center_of_mass = $Components.center_of_mass()
	self.mass = max(0.01, $Components.mass())
	self.displaced_volume = $Components.displaced_volume()
	self.forces = $Components.forces()
	set_shapes()
	#prints("m:", mass, "v", displaced_volume, "f", forces)
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
	var displaced_air_mass := displaced_volume * Atmosphere.air_density(to_global(center_of_volume).y)
	var weight := mass - displaced_air_mass
	apply_force(-displaced_air_mass * Atmosphere.gravity_vec(), to_global(center_of_volume) - global_position)
	for force: Force in forces:
		var global_force: Force = force.transformed(global_transform)
		apply_force(global_force.direction, global_force.pos - global_position)

func is_build_target() -> bool:
	return true

func is_floor() -> bool:
	return true

func check_connections() -> void:
	var all_components: Array[Component] = $Components.all_components()
	if all_components.is_empty():
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
	var holders: Dictionary[CompositeComponent, bool]
	for c: Component in all_components:
		if !known[c]:
			unconnected.append(c)
			c.remove()
	if !unconnected.is_empty():
		var new_ship: Airship = preload("res://scenes/airship.tscn").instantiate()
		new_ship.transform = transform
		get_parent().add_child(new_ship)
		var new_components: CompositeComponent = new_ship.get_node("Components")
		for c in unconnected:
			new_components.add_component(c)

func build_component(pos: Vector3, component: ComponentBlueprint, transform) -> void:
	var comp_node: Node3D = component.scene.instantiate()
	comp_node.transform = transform
	comp_node.position += pos
	$Components/Custom.add_component(comp_node)

func destroy_component(component: Component, pos: Vector3):
	component.destroy(pos)
	await get_tree().create_timer(0.05).timeout
	check_connections()
