extends RigidBody3D

var displaced_volume: float
var center_of_volume: Vector3
var forces: Array[Force]

func _ready() -> void:
	$Components.changed.connect(calculate_components)
	calculate_components()

func calculate_components() -> void:

	self.center_of_volume = $Components.center_of_volume()
	self.center_of_mass = $Components.center_of_mass()
	self.mass = $Components.mass()
	self.displaced_volume = $Components.displaced_volume()
	self.forces = $Components.forces()
	set_shapes()
	prints("m:", mass, "v", displaced_volume, "f", forces)
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
		apply_force(force.direction, force.pos)
