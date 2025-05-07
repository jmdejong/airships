extends Node

const BASE_AIR_DENSITY := 1.2

func air_density(height: float) -> float:
	return BASE_AIR_DENSITY / (1.0 + 0.008 * height)

func gravity_vec() -> Vector3:
	var space := get_viewport().find_world_3d().space
	return PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY) \
	 * PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR)

func gravity() -> float:
	var space := get_viewport().find_world_3d().space
	return PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY)
