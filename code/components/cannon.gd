extends BaseComponent

var fire_force: float = 3000
var can_fire := true
var vert_angle_lo: float = -25
var vert_angle_hi: float = 35
func mass() -> float:
	return 500


func _on_fire_pressed() -> void:
	if !can_fire:
		return
	can_fire = false
	var projectile: RigidBody3D = preload("res://scenes/cannonball.tscn").instantiate()
	projectile.global_position = %Muzzle.global_position
	projectile.linear_velocity = ship.linear_velocity
	var direction: Vector3 = (%Muzzle.global_position - %Chamber.global_position).normalized()
	var impulse: Vector3 = direction * fire_force
	ship.add_sibling(projectile)
	projectile.apply_central_impulse(impulse)
	#prints("z", ship.to_local($Muzzle.global_position))
	ship.apply_impulse(-impulse, %Muzzle.global_position - ship.global_position)
	%Muzzle.add_child(preload("res://scenes/effects/flash.tscn").instantiate())
	%Muzzle.add_child(preload("res://scenes/effects/smoke.tscn").instantiate())
	await get_tree().create_timer(0.5).timeout
	can_fire = true


func _on_up_pressed() -> void:
	%Barrel.rotation_degrees.z = clamp(%Barrel.rotation_degrees.z + 5, vert_angle_lo, vert_angle_hi)

func _on_down_pressed() -> void:
	%Barrel.rotation_degrees.z = clamp(%Barrel.rotation_degrees.z - 5, vert_angle_lo, vert_angle_hi)
