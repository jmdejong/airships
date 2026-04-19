extends BaseComponent

@export var unrolled: bool = false:
	set(val):
		unrolled = val
		$RolledUp.visible = not val
		$Unrolled.visible = val
		$ClimbShape/CollisionShape3D2.disabled = not val
		$Deploy/CollisionShape3D2.disabled = val
		$RollUp/CollisionShape3D2.disabled = not val

func _ready() -> void:
	unrolled = unrolled

func _on_deploy_pressed_by(_player: Player) -> void:
	unrolled = true


func _on_climb_shape_pressed_by(player: Player) -> void:
	player.teleport_to($ClimbPoint.global_position)


func _on_roll_up_pressed_by(_player: Player) -> void:
	unrolled = false
