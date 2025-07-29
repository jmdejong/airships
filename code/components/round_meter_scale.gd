extends Control

var center: Vector2 = size / 2
@export var markings: int = 100
@export var bow: float = 300
@export var mark_step: float = 1
@export var format_str: String = "%2.0f"
var lo: float = - bow / 2
var scale_: float = bow / markings

func _draw() -> void:
	for v: int in (markings + 1):
		var angle: float = deg_to_rad(v * scale_ + lo)
		draw_radial_line(angle, 96 if v%10==0 else 102 if v%5 == 0 else 108, 118)
	var default_font = ThemeDB.fallback_font
	var default_font_size = 16
	for v: int in range(0, markings + 1, 10):
		var value: float = v * mark_step
		var angle: float = deg_to_rad(v * scale_ + lo)
		draw_set_transform(center, angle + PI, Vector2.ONE)
		var p: Vector2 = Vector2(-92, 8)#center + Vector2.RIGHT.rotated(angle) * 10
		draw_string(default_font, p, format_str % [value], HORIZONTAL_ALIGNMENT_CENTER, -1, default_font_size, Color.BLACK)

func value_to_angle(value: float) -> float:
	return deg_to_rad(value / mark_step * scale_ + lo)

func draw_radial_line(angle: float, start: float, end: float) -> void:
	var dir: Vector2 = Vector2.RIGHT.rotated(angle)
	draw_line(center + dir * start, center + dir * end, Color.BLACK, 1.0)
