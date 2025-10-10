extends BaseComponent

var fire_force: float = 3000
var can_fire := true
var vert_angle_lo: float = -25
var vert_angle_hi: float = 35
@export var angle_channel = SignalConnection.Channel.RED
var angle: float = 0

func _ready() -> void:
	var typ: Dictionary[SignalConnection.Channel, SignalType] = {
		angle_channel: SignalType.new("deg", vert_angle_lo, vert_angle_hi, 5)
	}
	$SignalConnection.own_type = typ
	set_angle(angle)

func mass() -> float:
	return 500

func shapes() -> Array[CollisionShape3D]:
	var collisionshapes: Array[CollisionShape3D] = []
	for child: CollisionShape3D in [$Barrel/BarrelShape, $MountShape]:
		#if child is CollisionShape3D:
			var c: CollisionShape3D = child.duplicate()
			c.set_meta("component", self)
			c.transform = (get_parent().global_transform.inverse() * child.global_transform)
			collisionshapes.append(c)
	return collisionshapes

func _on_fire_pressed() -> void:
	if !can_fire:
		return
	can_fire = false
	#prints("ship", ship)
	var projectile: RigidBody3D = preload("res://scenes/cannonball.tscn").instantiate()
	projectile.global_position = %Muzzle.global_position
	var ship: Airship = get_ship()
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

func set_angle(a: float) -> void:
	angle = clamp(a, vert_angle_lo, vert_angle_hi)
	%Barrel.rotation_degrees.z = angle
	changed.emit()

func _on_up_pressed() -> void:
	set_angle(angle + 5)

func _on_down_pressed() -> void:
	set_angle(angle - 5)

func _on_signal_connection_changed(channel: SignalConnection.Channel, value: float) -> void:
	if channel == angle_channel:
		set_angle(value)
