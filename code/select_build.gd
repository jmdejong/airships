extends Control

@export var component: Component.ComponentType

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		get_owner().select_build.emit(Component.from_type(component))
