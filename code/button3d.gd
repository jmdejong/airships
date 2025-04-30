extends Area3D

@export var description: String

signal pressed;

func _input_event(camera: Camera3D, event: InputEvent, event_position: Vector3, normal: Vector3, shape_idx: int) -> void:
	return
	print(event)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		pressed.emit()

func mouseover_description() -> String:
	return description

func press() -> void:
	pressed.emit()
