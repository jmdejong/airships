extends Node3D

signal changed

var power: float:
	set(value):
		power = value
		$StatusPanel.text = "%2.0f N" % power
		$Rotor.rps = power / 500 + 0.02
		changed.emit()
var step: float = 200
var max_power: float = 2000

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
	power = max(power - step, 0)


func _on_more_pressed() -> void:
	power = min(power + step, max_power)


func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			s.append(child)
	return s
