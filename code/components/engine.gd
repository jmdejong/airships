extends Node3D

var power: float:
	set(value):
		power = value
		$StatusPanel.text = "%2.0f N" % power
		$Rotor.rps = power / 500 + 0.05
var step: float = 200
var max_power: float = 2000

func _ready() -> void:
	power = 1000

func mass() -> float:
	return 100.0

func displaced_volume() -> float:
	return 0.25

func force() -> Vector3:
	return (global_position - $Rotor.global_position).normalized() * power


func _on_less_pressed() -> void:
	power = max(power - step, 0)


func _on_more_pressed() -> void:
	power = min(power + step, max_power)
