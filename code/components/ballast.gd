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
	var c: CollisionShape3D = $CollisionShape3D.duplicate()
	c.set_meta("component", self)
	c.transform = transform * c.transform
	return [c]

	
func block_components() -> Dictionary[Vector3, Node3D]:
	var d: Dictionary[Vector3, Node3D]
	var aabb: AABB = transform * $CollisionShape3D.transform * AABB(-$CollisionShape3D.size / 2.0, $CollisionShape3D.size) / Global.block_size
	for x in range(aabb.position.x, aabb.end.x + 1):
		for y in range(aabb.position.y, aabb.end.y + 1):
			for z in range(aabb.position.z, aabb.end.z + 1):
				d[Vector3(x, y, z)/2.0] = self
	return d
