@tool
extends Control

@export var draw_radius: float = 100
@export var touch_marker_draw_radius = 40
@export var move_radius: float = 100
@export var limit: float = 150
@export_tool_button("draw") var redraw_action: Callable = queue_redraw

var touch_index: int = -99
var touch_position: Vector2


func _input(event: InputEvent) -> void:
	var last_touch_position: Vector2 = touch_position
	if event is InputEventScreenTouch and not event.pressed:
		touch_position = Vector2.ZERO
		touch_index = -99
	elif event is InputEventScreenTouch:
		var tp: Vector2 = event.position - global_position
		if tp.length() <= limit:
			touch_index = event.index
			touch_position = tp
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var tp: Vector2 = event.position - global_position
		if event.index == touch_index:
			touch_position = tp
			get_viewport().set_input_as_handled()
	if last_touch_position != touch_position:
		queue_redraw()


func _draw() -> void:
	draw_circle(Vector2.ZERO, draw_radius, Color(0.8, 0.8, 0.8, 0.4))
	if touch_position != Vector2.ZERO:
		draw_circle(touch_position.limit_length(draw_radius), touch_marker_draw_radius, Color(1, 1, 1, 0.7))

func touch_value() -> Vector2:
	return touch_position / move_radius
