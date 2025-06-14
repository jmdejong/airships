extends Node

# formula: https://en.wikipedia.org/wiki/Density_of_air#Variation_with_altitude
const BASE_AIR_DENSITY := 1.2
const STANDARD_ATMOSPHERIC_PRESSURE: float = 101325
const STANDARD_TEMPERATURE: float = 288.15
const TEMPERATURE_LAPSE_RATE: float = 0.0065
const IDEAL_GAS_CONSTANT: float = 8.31446
const AIR_MOLAR_MASS: float = 0.0289652
const HEIGHT_MULTIPLIER: float = 10
var tropopause_cutoff: float = 11000 / HEIGHT_MULTIPLIER


#func _reaerints("a"+str(h), Atmosphere.air_density(h), Atmosphere.air_density(h) / Atmosphere.air_density(0), Atmosphere.temperature(h), Atmosphere.pressure(h))


func temperature(height: float) -> float:
	height = min(height, tropopause_cutoff)
	var h := height * HEIGHT_MULTIPLIER
	return STANDARD_TEMPERATURE - TEMPERATURE_LAPSE_RATE * h

func pressure(height: float) -> float:
	# Might need some corrections in the tropopause
	var h := height * HEIGHT_MULTIPLIER
	return STANDARD_ATMOSPHERIC_PRESSURE * \
		pow(
			1.0 - TEMPERATURE_LAPSE_RATE * h / STANDARD_TEMPERATURE,
			gravity() * AIR_MOLAR_MASS / (IDEAL_GAS_CONSTANT * TEMPERATURE_LAPSE_RATE)
		)

func air_density(height: float) -> float:
	var density := pressure(height) * AIR_MOLAR_MASS / (IDEAL_GAS_CONSTANT * temperature(height))
	return density

func gravity_vec() -> Vector3:
	var space := get_viewport().find_world_3d().space
	return PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY) \
	 * PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY_VECTOR)

func gravity() -> float:
	var space := get_viewport().find_world_3d().space
	return PhysicsServer3D.area_get_param(space, PhysicsServer3D.AREA_PARAM_GRAVITY)
