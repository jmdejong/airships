@tool
class_name Balloon
extends BaseComponent

@export var radius: float = 10:
	set(val):
		radius = val
		if has_node("CollisionShape3D"):
			$CollisionShape3D.shape.radius = val
		if has_node("MeshInstance3D"):
			$MeshInstance3D.mesh.radius = val
@export var length: float = 30:
	set(val):
		length = val
		if has_node("CollisionShape3D"):
			$CollisionShape3D.shape.height = val
		if has_node("MeshInstance3D"):
			$MeshInstance3D.mesh.height = val
@export var filling_density: float = 0.1
@export var envelope_mass: float = 0.1

func _ready() -> void:
	var tube: float = length - radius * 2
	volume = 4.0/3 * PI * radius * radius * radius + tube * PI * radius * radius
	var surface = 4 * PI * radius * radius + 2 * PI * radius * tube
	mass_ = filling_density * volume + surface * envelope_mass
