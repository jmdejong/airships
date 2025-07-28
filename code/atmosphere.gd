extends Node

# formula: https://en.wikipedia.org/wiki/Density_of_air#Variation_with_altitude
const BASE_AIR_DENSITY := 1.2
const STANDARD_ATMOSPHERIC_PRESSURE: float = 101325
const STANDARD_TEMPERATURE: float = 288.15
const TEMPERATURE_LAPSE_RATE: float = 0.0065
const IDEAL_GAS_CONSTANT: float = 8.31446
const AIR_MOLAR_MASS: float = 0.0289652
const HEIGHT_MULTIPLIER: float = 10
const TROPOPAUSE_PRESSURE_DROP = 6300
var tropopause_cutoff: float = 11000 / HEIGHT_MULTIPLIER
var tropopause_temperature: float = _troposphere_temperature(tropopause_cutoff)
var tropopause_cutoff_pressure: float = _troposphere_pressure(tropopause_cutoff)


func _troposphere_temperature(height: float) -> float:
	var h := height * HEIGHT_MULTIPLIER
	return STANDARD_TEMPERATURE - TEMPERATURE_LAPSE_RATE * h

func _troposphere_pressure(height: float) -> float:
	var h := height * HEIGHT_MULTIPLIER
	return STANDARD_ATMOSPHERIC_PRESSURE * \
		pow(
			1.0 - TEMPERATURE_LAPSE_RATE * h / STANDARD_TEMPERATURE,
			gravity() * AIR_MOLAR_MASS / (IDEAL_GAS_CONSTANT * TEMPERATURE_LAPSE_RATE)
		)

func _tropopause_pressure(height: float) -> float:
	return tropopause_cutoff_pressure * exp(-(height-tropopause_cutoff) * HEIGHT_MULTIPLIER / TROPOPAUSE_PRESSURE_DROP)

func temperature(height: float) -> float:
	if height >= tropopause_cutoff:
		return tropopause_temperature
	else:
		return _troposphere_temperature(height)

func pressure(height: float) -> float:
	if height >= tropopause_cutoff:
		return _tropopause_pressure(height)
	else:
		return _troposphere_pressure(height)

func air_density(height: float) -> float:
	var density := pressure(height) * AIR_MOLAR_MASS / (IDEAL_GAS_CONSTANT * temperature(height))
	return density

func gravity_vec() -> Vector3:
	return gravity() * Vector3.DOWN
	
func gravity() -> float:
	return 9.81
