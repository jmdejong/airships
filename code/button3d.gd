extends Area3D

@export var description: String

signal pressed;

func mouseover_description() -> String:
	return description

func press() -> void:
	pressed.emit()
