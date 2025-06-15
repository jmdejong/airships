extends Node3D

var rps: float = 1
#@onready var rot_speed: float = 1 / rps * PI * 2.0

func _process(delta: float) -> void:
	rotate_x(delta * rps * PI * 2.0)
