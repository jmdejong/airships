extends Label3D

var previous_position: Vector3

func _physics_process(delta: float) -> void:
	var velocity = (global_position - previous_position) / delta
	previous_position = global_position
	text = "Altitude: %4.1f m\nAir: %2.2f kg/m^3\nHor speed: %2.2f m/s\nVert speed: %+2.2f m/s\nAng speed: %+3.1f deg/s" % [
		global_position.y,
		Atmosphere.air_density(global_position.y),
		Vector2(velocity.x, velocity.z).length(),
		velocity.y,
		get_parent().get_parent().get_parent().get_ship().angular_velocity.y / PI * 180.0
	]
