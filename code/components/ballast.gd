extends Node3D

var total_mass: float = 1000
var filling: float :
	set(value):
		filling = value
		$Water.scale.y = filling
		%StatusPanel.text = "%4.1f kg\n%3d%%" % [mass(), int(filling * 100)]

var step: float = 0.1

func _ready() -> void:
	filling = 0.5

func mass() -> float:
	return total_mass * filling + 0.1

func displaced_volume() -> float:
	return 1.0


func _on_less_pressed() -> void:
	filling = max(filling - step, 0.0)
	prints("Dropping ballast", mass())


func _on_more_pressed() -> void:
	filling = min(filling + step, 1.0)
	prints("Filling ballast", mass())
