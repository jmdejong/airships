class_name RotaryTable
extends CompositeComponent

@export var max_rotation: float = 45
@export var min_rotation: float = -45
@export var step: float = 5
var rot: float = 0


func _ready() -> void:
	for child in get_children():
		if child is Component and child != $Components and child != $Base:
			remove_child(child)
			child.transform = $Components.transform.inverse() * child.transform
			$Components.add_component(child)
	$Components.ship = ship
	$Components.changed.connect(recalculate)
	_recalculate()

func do_rotate(delta: float) -> void:
	rot = clamp(rot + delta, min_rotation, max_rotation)
	$Top.rotation_degrees.y = rot
	$Components.transform = $Top.transform * $Top/Corner.transform
	prints("rotating to", rot)
	$Components.recalculate()

func rotate_clockwise() -> void:
	do_rotate(-5)

func rotate_counterclockwise() -> void:
	do_rotate(5)
