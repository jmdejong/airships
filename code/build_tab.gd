extends CanvasLayer


signal select_build(component: Component)
signal select_remove


func _on_remove_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == 1:
		select_remove.emit()
