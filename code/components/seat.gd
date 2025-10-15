class_name Seat
extends Node3D

func _on_sitbox_pressed_by(player: Player) -> void:
	player.sit(self)

func seat_position() -> Vector3:
	return global_position
