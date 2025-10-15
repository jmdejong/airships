extends Area3D

@export var description: String

signal pressed();
signal pressed_by(player: Player);

func mouseover_description() -> String:
	return description

func press(player: Player) -> void:
	pressed.emit()
	pressed_by.emit(player)
