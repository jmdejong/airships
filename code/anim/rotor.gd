extends Node3D

var rpm: float = 60
@onready var rot_speed: float = 60 / rpm * PI * 2.0

func _process(delta: float) -> void:
	$Propellor.rotate_x(delta * rot_speed)
