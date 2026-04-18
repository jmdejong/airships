extends Area3D

signal pressed_by(player: Player);

@export var delegate: Node


func mouseover_description(player: Player) -> String:
	return delegate.mouseover_description(self, player)

func press(player: Player) -> void:
	pressed_by.emit(player)
