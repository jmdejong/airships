extends Control

@export var component: ComponentBlueprint.ComponentType

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		get_owner().select_build.emit(ComponentBlueprint.from_type(component))
