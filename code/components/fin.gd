@tool
class_name Fin
extends BaseComponent

@export var density: float = 1
@export var thickness: float = 0.5
var surface_area: float = 72 # m^2
#var size_block: Vector2i
#@export var size: Vector2:
	#set(v):
		#size_block = Vector2i(v/Global.block_size)
		#size = size_block * Global.block_size
		#surface_area = size.x * size.y
		#if is_inside_tree():
			#update_sizes()

#func update_sizes() -> void:
		#var origin: Vector3 = Vector3(size.x, thickness, size.y) / 2.0
		#var size3 = Vector3(size.x, thickness, size.y)
		#$CollisionShape3D.shape = _box_shape(size3)
		#$CollisionShape3D.position = origin
		#var ms: BoxMesh = $MeshInstance3D.mesh.duplicate()
		#ms.size = size3
		#$MeshInstance3D.mesh = ms
		#$MeshInstance3D.position = origin
		#$CenterOfMass.position = origin
		#$Connection.position = origin
		#$Connection/CollisionShapeX.shape = _box_shape(size3 + Vector3(0.1, -0.2, -0.2))
		#$Connection/CollisionShapeY.shape = _box_shape(size3 + Vector3(-0.2, 0.1, -0.2))
		#$Connection/CollisionShapeZ.shape = _box_shape(size3 + Vector3(-0.2, -0.2, 0.1))

var previous_position: Vector3

func mass() -> float:
	return surface_area * thickness * density

func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var ship: Airship = get_ship()
	var force := calculate_wing_force()
	#var force := calculate_fin_force()
	%ForceIndicator.global_position = $CenterOfMass.global_position + (force * 10.0 / ship.mass)
	ship.apply_force(force, $CenterOfMass.global_position - ship.global_position)

func calculate_fin_force() -> Vector3:
	var local_air_velocity: Vector3 = global_basis.inverse() * relative_air_velocity()
	var v: float = local_air_velocity.y
	var f: float = 0.5 \
		* Atmosphere.air_density($CenterOfMass.global_position) \
		* v \
		* local_air_velocity.length() \
		* surface_area
	return $CenterOfMass.global_basis * Vector3(0, f, 0)

func calculate_wing_force() -> Vector3:
	var air_velocity: Vector3 = $CenterOfMass.global_basis.inverse() * relative_air_velocity()
	var air_speed_sq: float = air_velocity.length_squared()
	if air_speed_sq < 0.01:
		return Vector3.ZERO
	var air_direction: Vector3 = air_velocity.normalized()
	
	var angle_of_attack: float = asin(clamp(air_direction.y, -1.0, 1.0))
	
	var lift_slope: float = 4.0 # Not very exact
	var stall_angle: float = deg_to_rad(15.0)
	var lift_coefficient: float = angle_of_attack * lift_slope
	if abs(angle_of_attack) > stall_angle:
		# Simple stall: lift drops off after stall angle
		lift_coefficient = sign(angle_of_attack) * lift_slope * stall_angle * 0.5
	
	var dynamic_pressure = 0.5 * Atmosphere.air_density($CenterOfMass.global_position) * air_speed_sq
	
	var lift_mag: float = dynamic_pressure * surface_area * lift_coefficient
	var lift_force: Vector3 = Vector3(0, lift_mag, 0)
	
	# Drag: Parasitic drag + Induced drag (proportional to cl^2)
	var drag_coefficient: float = 0.02 + (lift_coefficient * lift_coefficient * 0.1) 
	var drag_mag: float = dynamic_pressure * surface_area * drag_coefficient
	var drag_force: Vector3 = air_direction * drag_mag

	var local_force: Vector3 = lift_force + drag_force
	return $CenterOfMass.global_basis * local_force

func relative_air_velocity() -> Vector3:
	var ship: Airship = get_ship()
	var velocity: Vector3 = ship.linear_velocity + ship.angular_velocity.cross($CenterOfMass.global_position - ship.global_position)
	return Atmosphere.wind_velocity($CenterOfMass.global_position) - velocity

func _box_shape(size: Vector3) -> BoxShape3D:
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = size
	return bs
