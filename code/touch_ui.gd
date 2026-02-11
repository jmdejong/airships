extends Control

signal enable_touch
signal touch_click

var touch_enabled: bool = false

func _input(event: InputEvent) -> void:
	if !touch_enabled and (event is InputEventScreenDrag or event is InputEventScreenTouch):
		visible = true
		%TouchClick.visible = true
		touch_enabled = true
		enable_touch.emit()

func _on_touch_click_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed:
		touch_click.emit()
