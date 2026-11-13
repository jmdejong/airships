@tool
class_name Balloon
extends BaseComponent

@export var radius: float = 10:
	set(val):
		radius = val
		if has_node("CollisionShape3D"):
			$CollisionShape3D.shape.radius = val
		if has_node("MeshInstance3D"):
			$MeshInstance3D.mesh.radius = val
@export var length: float = 30:
	set(val):
		length = val
		if has_node("CollisionShape3D"):
			$CollisionShape3D.shape.height = val
		if has_node("MeshInstance3D"):
			$MeshInstance3D.mesh.height = val
@export var filling_density: float = 0.1
@export var envelope_density: float = 0.5 # kg / m^2
@export var structure_mass: float = 10

@export var mooring_connect_point: Node3D:
	set(point):
		mooring_point = point
	get():
		return mooring_point
var previous_position: Vector3

func _ready() -> void:
	var tube: float = length - radius * 2
	volume = 4.0/3 * PI * radius * radius * radius + tube * PI * radius * radius
	var surface = 4 * PI * radius * radius + 2 * PI * radius * tube
	mass_ = filling_density * volume + surface * envelope_density
	if mooring_point == null:
		push_error("No mooring point for ", self)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	apply_drag()

func apply_drag() -> void:
	var ship: RigidBody3D = get_ship()
	var center_of_mass_node: Node3D = $CenterOfMass
	if not ship or not center_of_mass_node: return
	
	#var tf: Transform3D = center_of_mass_node.global_transform
	var sections: Array[Node3D] = [$ForeCenter, $AftCenter]
	
	var frontal_area_per_section: float = (PI * radius * radius) / float(len(sections))
	var side_area_per_section: float = (2.0 * radius * length) / float(len(sections))
	
	for section: Node3D in sections:
		# Calculate world-space offset from ship center to this point
		var tf: Transform3D = section.global_transform
		
		# Relative velocity in world space
		var velocity: Vector3 = ship.linear_velocity + ship.angular_velocity.cross(section.global_position - ship.global_position)
		var world_air_velocity = Atmosphere.wind_velocity(section.global_position) - velocity
		
		# Transform relative velocity to CenterOfMass local space
		var local_air_velocity: Vector3 = tf.basis.inverse() * world_air_velocity
		var air_speed_sq: float = local_air_velocity.length_squared()
		if air_speed_sq < 0.01:
			continue
		var local_air_direction: Vector3 = local_air_velocity.normalized()
		
		# Alignment is the Z component since local forward is (0, 0, -1)
		var alignment: float = abs(local_air_direction.z)
		
		var area: float = lerp(side_area_per_section, frontal_area_per_section, alignment)
		var drag_coeff: float = lerp(0.8, 0.05, alignment)
		
		# Drag force in local space (opposite to local velocity)
		var dynamic_pressure: float = 0.5 * Atmosphere.air_density(section.global_position) * air_speed_sq
		var drag_force_local: Vector3 = local_air_direction * (dynamic_pressure * drag_coeff * area)
		
		# Keel effect in local space
		var side_dir_local: Vector3 = Vector3(0, 0, -1).cross(local_air_direction).cross(local_air_direction).normalized()
		var keel_force_local: Vector3 = side_dir_local * (dynamic_pressure * side_area_per_section * 0.1 * (1.0 - alignment))
		
		# Transform combined local force back to world space and apply
		var total_force_world: Vector3 = tf.basis * (drag_force_local + keel_force_local)
		ship.apply_force(total_force_world, section.global_position - ship.global_position)

	# 2. Roll Axis Damping (Skin Friction)
	var tube_forward_world: Vector3 = $CenterOfMass.global_basis.x
	var roll_velocity: float = ship.angular_velocity.dot(tube_forward_world)
	var roll_torque: Vector3 = -tube_forward_world * roll_velocity * 0.1 * ship.linear_velocity.length()
	ship.apply_torque(roll_torque)
