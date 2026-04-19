class_name Seat
extends Node3D


var bindings: Array[Binding] = []

func _on_sitbox_pressed_by(player: Player) -> void:
	player.sit(self)

func seat_position() -> Vector3:
	return global_position

func handle_player_input(delta: float) -> void:
	for binding in bindings:
		if Input.is_key_pressed(binding.key) and binding.action != Binding.Action.None:
			var control: SignalControl = get_node(binding.control)
			if control == null:
				continue
			if binding.action == Binding.Action.Change:
				control.change_raw_value(delta * binding.change)
			elif binding.action == Binding.Action.Set:
				control.set_value(binding.set_to)

func get_component() -> Component:
	return get_parent()
