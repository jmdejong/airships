class_name Airship
extends RigidBody3D

signal teleport(from: Vector3, to: Vector3)

var displaced_volume: float
var center_of_volume: Vector3
var forces: Array[Force]
const drag_coefficient: float = 0.5
var drag_area_coefficient: float
var ndetached: int = 0
var mooring_joint: Joint3D = null
var moored_to: MoorConnector = null:
	set(val):
		if mooring_joint != null:
			mooring_joint.queue_free()
		moored_to = val

func _ready() -> void:
	$Components.changed_physics.connect(calculate_components_physics)
	$Components.changed_forces.connect(calculate_components_forces)
	$Components.changed_shapes.connect(calculate_components_shapes)
	calculate_components_physics()
	calculate_components_forces()
	calculate_components_shapes()
	await get_tree().create_timer(0.05).timeout
	check_connections()
	for child in get_children():
		if child is Component and child != $Components:
			child.reparent($Components)

func calculate_components_physics() -> void:
	var physics_properties: PhysicsProperties = $Components.physics_properties()
	self.center_of_volume = physics_properties.center_of_volume
	self.center_of_mass = physics_properties.center_of_mass
	self.mass = max(0.01, physics_properties.mass)
	self.displaced_volume = physics_properties.volume
	self.drag_area_coefficient = pow(displaced_volume, 2.0/3.0) * drag_coefficient
	$CenterOfMassMarker.position = center_of_mass
	$CenterOfVolumeMarker.position = center_of_volume

func calculate_components_forces() -> void:
	self.forces = $Components.forces()

func calculate_components_shapes() -> void:
	self.set_shapes()

func set_shapes() -> void:
	for child in get_children():
		if child is CollisionShape3D:
			remove_child(child)
	for source_shape: CollisionShape3D in $Components.shapes():
		var shape = source_shape.duplicate()
		add_child(shape)

func _physics_process(_delta: float) -> void:
	if moored_to != null and mooring_joint == null:
		move_moor()
	var air_density: float = Atmosphere.air_density(to_global(center_of_volume).y)
	var displaced_air_mass := displaced_volume * air_density
	apply_force(-displaced_air_mass * Atmosphere.gravity_vec(), to_global(center_of_volume) - global_position)
	for local_force: Force in forces:
		if local_force.power == 0:
			continue
		var force: Force = local_force.transformed(global_transform)
		var thrust = pow(force.power * force.power * 2 * 10 * Atmosphere.air_density(force.pos.y), 0.3333333333333)
		apply_force(force.direction * thrust, force.pos - global_position)
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
		if !known[c] and c.is_inside_tree():
			unconnected.append(c)
			var parent: CompositeComponent = c.get_parent()
			var gtf: Transform3D = c.global_transform
			parent.remove_child(c)
			c.transform = gtf
			parents[parent] = true
	for parent: CompositeComponent in parents.keys():
		parent.recalculate_all()
	if !unconnected.is_empty():
		var new_ship: Airship = preload("res://scenes/airship.tscn").instantiate()
		ndetached += 1
		new_ship.name = name + "_D" + str(ndetached)
		new_ship.transform = transform
		new_ship.linear_velocity = linear_velocity
		new_ship.angular_velocity = angular_velocity
		var new_components: CompositeComponent = new_ship.get_node("Components")
		for c in unconnected:
			c.transform = new_ship.transform.inverse() * c.transform
			new_components.add_child(c)
		get_parent().add_child(new_ship)
		new_components.recalculate_all()

func build_component(pos: Vector3, component: ComponentBlueprint, build_transform: Transform3D) -> void:
	var comp_node: Component = component.create()
	comp_node.transform = build_transform
	comp_node.position += pos
	if !has_node("Components/Custom"):
		var custom_components: CompositeComponent = preload("res://scenes/components/composite.tscn").instantiate()
		custom_components.name = "Custom"
		$Components.add_component(custom_components)
	$Components/Custom.add_component(comp_node)

func destroy_component(component: Component, pos: Vector3):
	component.destroy(pos)
	await get_tree().create_timer(0.05).timeout
	check_connections()

func impact(shape: CollisionShape3D, impactor: RigidBody3D) -> void:
	if !is_instance_valid(shape) || !is_instance_valid(shape.get_meta("component")):
		return
	var component: Component = shape.get_meta("component")
	destroy_component(component, impactor.global_position)

func moor_to(connector: MoorConnector) -> void:
	if $Components.mooring_point == null:
		return
	else:
		moored_to = connector

func move_moor():
	var new_position: Vector3 = moored_to.global_position - ($Components.mooring_point.global_position - global_position)
	teleport.emit(global_position, new_position)
	global_position = new_position
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	mooring_joint = PinJoint3D.new()
	mooring_joint.position = moored_to.global_position
	mooring_joint.node_a = get_path()
	mooring_joint.node_b = moored_to.body.get_path()
	add_sibling(mooring_joint)


func to_json() -> Dictionary[String, Variant]:
	return {
		"type": "ship",
		"name": name,
		"components": $Components.to_json(),
		"pos": [position.x, position.y, position.z],
		"r": [rotation.x, rotation.y, rotation.z]
	}

static func from_json(json: Dictionary) -> Airship:
	var ship: Airship = preload("res://scenes/airship.tscn").instantiate()
	ship.name = json.name
	ship.get_node("Components").initialize_from_json(json.components)
	return ship
