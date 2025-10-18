class_name Seat
extends Node3D


@export var bindings: Array[Binding] = []

func _on_sitbox_pressed_by(player: Player) -> void:
	player.sit(self)

func seat_position() -> Vector3:
	return global_position

func handle_player_input(delta: float) -> void:
	for binding in bindings:
		if Input.is_key_pressed(binding.key):
			var control: SignalControl = get_node(binding.control)
			if control == null:
				continue
			control.change_raw_value(delta * binding.change)

func get_component() -> Component:
	return get_parent()
