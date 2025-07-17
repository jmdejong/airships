extends BaseComponent

var fire_force: float = 3000

func mass() -> float:
	return 500


func _on_fire_pressed() -> void:
	var projectile: RigidBody3D = preload("res://scenes/cannonball.tscn").instantiate()
	projectile.global_position = %Muzzle.global_position
	projectile.linear_velocity = ship.linear_velocity
	var direction: Vector3 = (%Muzzle.global_position - %Chamber.global_position).normalized()
	var impulse: Vector3 = direction * fire_force
	ship.add_sibling(projectile)
	projectile.apply_central_impulse(impulse)
	#prints("z", ship.to_local($Muzzle.global_position))
	ship.apply_impulse(-impulse, $Muzzle.global_position - ship.global_position)
