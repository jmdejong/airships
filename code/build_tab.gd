extends CanvasLayer


signal select_remove
signal select_build(blueprint: ComponentBlueprint)


func _on_remove_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		select_remove.emit()
