extends Node3D

signal changed

var total_mass: float = 1000
@export var initial_filling: float = 0.2
var filling: float :
	set(value):
		filling = value
		$Water.scale.y = filling
		%StatusPanel.text = "%4.0f kg\n%3d%%" % [filling * total_mass, int(filling * 100)]
		changed.emit()

var step: float = 0.1

func _ready() -> void:
	filling = initial_filling

func mass() -> float:
	return total_mass * filling + 0.1

func displaced_volume() -> float:
	return 1.0

func center_of_mass() -> Vector3:
	return transform * $CenterOfMass.position

func _on_less_pressed() -> void:
	filling = max(filling - step, 0.0)


func _on_more_pressed() -> void:
	filling = min(filling + step, 1.0)

func shapes() -> Array[CollisionShape3D]:
	var s: Array[CollisionShape3D] = []
	for child in get_children():
		if child is CollisionShape3D:
			var c: CollisionShape3D = child.duplicate()
			c.transform = transform * c.transform
			s.append(c)
	return s
