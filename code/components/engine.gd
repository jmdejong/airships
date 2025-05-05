extends Node3D

signal changed

var power: float:
	set(value):
		power = value
		$StatusPanel.text = "%2.2f kN" % (power / 1000.0)
		if power == 0:
			$Rotor.rps = sign($Rotor.rps) * 0.02
		else:
			$Rotor.rps = value / 500
		changed.emit()
var step: float = 250
var max_power: float = 5000
var min_power: float = -2000

func _ready() -> void:
	power = 1000

func mass() -> float:
	return 100.0

func displaced_volume() -> float:
	return 0.25

func forces() -> Array[Force]:
	return [Force.new($Rotor.position, -$Rotor.position.normalized() * power)]

func center_of_mass() -> Vector3:
	return $CenterOfMass.position

func _on_less_pressed() -> void:
	power = max(power - step, min_power)


func _on_more_pressed() -> void:
	power = min(power + step, max_power)


func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			s.append(child)
	return s
