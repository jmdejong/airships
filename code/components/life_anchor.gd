class_name LifeAnchor
extends BoxComponent


func _on_attach_box_pressed_by(player: Player) -> void:
	player.attach_lifeline(self)

func anchor_point() -> Vector3:
	return $AnchorPoint.global_position
