extends RigidBody3D

const BASE_AIR_DENSITY := 1.2
#var velocity := Vector3(0,0,0)
var wait_time := 0.0
var displaced_volume: float
var center_of_volume: Vector3

func _ready() -> void:
	for component in $Components.get_children():
		for c in component.get_children():
			if c is CollisionShape3D:
				component.remove_child(c)
				c.transform = component.transform * c.transform
				add_child(c)
	calculate_components()

func calculate_components() -> void:
	var mass: float = 0
	var displaced_volume: float = 0
	var center_of_mass: Vector3 = Vector3(0, 0, 0)
	var center_of_volume: Vector3 = Vector3(0, 0, 0)
	for component in $Components.get_children():
		var m: float = component.mass()
		var v: float = component.displaced_volume()
		assert(m > 0)
		assert(v > 0)
		mass += m
		displaced_volume += v
		var center: Vector3 = (component.transform * component.get_node("CenterOfMass").position)
		center_of_mass += center * m
		center_of_volume += center * v
	center_of_mass /= mass
	center_of_volume /= displaced_volume
	self.center_of_volume = center_of_volume
	self.center_of_mass = center_of_mass
	self.mass = mass
	self.displaced_volume = displaced_volume
	$CenterOfMassMarker.position = center_of_mass
	$CenterOfVolumeMarker.position = center_of_volume

func _physics_process(delta: float) -> void:
	calculate_components()
	var displaced_air_mass := displaced_volume * air_density(to_global(center_of_volume).y)
	var weight := mass - displaced_air_mass
	apply_force(-displaced_air_mass * gravity_vec(), to_global(center_of_volume) - global_position)
	if wait_time < 0:
		prints(displaced_volume, mass, displaced_air_mass, weight)
		wait_time = 5.0
	else:
		wait_time -= delta
	for component in $Components.get_children():
		if component.has_method("force"):
			apply_force(component.force(), component.get_node("CenterOfMass").global_position - global_position)


func gravity_vec() -> Vector3:
	var space := get_viewport().find_world_3d().space
	return PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY) \
	 * PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR)

# todo: good place fo this function
func air_density(height: float) -> float:
	return BASE_AIR_DENSITY / (1 + 0.05 * height)
