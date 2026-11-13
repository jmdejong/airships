@tool
extends BaseComponent

@export var max_rotation: float = 45
@export var min_rotation: float = -45
@export var density: float = 1
@export var thickness: float = 0.5:
	set(v):
		thickness = v
		update_sizes()
@export var fin_length: float = 6:
	set(v):
		fin_length = v
		update_sizes()
@export var rudder_length: float = 6:
	set(v):
		rudder_length = v
		update_sizes()
@export var width: float = 6:
	set(v):
		width = v
		update_sizes()
@export var rotation_channel: SignalConnection.Channel = SignalConnection.Channel.None
var rot: float = 0

var previous_velocity: Vector3 = Vector3.ZERO

func update_sizes() -> void:
	$MeshInstance3D.mesh = $MeshInstance3D.mesh.duplicate()
	$MeshInstance3D.mesh.size = Vector3(fin_length, thickness, width)
	var fin_center := Vector3(-fin_length / 2.0, 0, 0)
	$MeshInstance3D.position = fin_center
	$Foil.position = fin_center
	
	var total_length: float = fin_length + rudder_length
	var total_center := Vector3(-total_length / 2.0, 0, 0)
	$CenterOfMass.position = total_center
	
	$CollisionShape3D.position = total_center
	$CollisionShape3D.shape = _box_shape(Vector3(total_length, thickness, width))
	
	$Connection/CollisionShape3D.shape = _box_shape(Vector3(0.2, 0.4, width - 0.2))
	$SignalConnection/CollisionShape3D.shape = _box_shape(Vector3(0.2, 0.4, width - 0.2))
	
	$Rudder.position = Vector3(-fin_length, 0, 0)
	$Rudder/Foil.position = Vector3(-rudder_length/2.0, 0, 0)
	$Rudder/MeshInstance3D.position = Vector3(-rudder_length/2.0, 0, 0)
	$Rudder/MeshInstance3D.mesh = $Rudder/MeshInstance3D.mesh.duplicate()
	$Rudder/MeshInstance3D.mesh.size = Vector3(rudder_length, thickness, width)


func mass() -> float:
	return width * (fin_length + rudder_length) * thickness * density

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	$Foil.ship = get_ship()
	$Rudder/Foil.ship = get_ship()
	var typ: Dictionary[SignalConnection.Channel, SignalType] = {
		rotation_channel: SignalType.new("deg", min_rotation, max_rotation, 5)
	}
	$SignalConnection.own_type = typ
	rotate_to(rot)

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	if $Foil != null:
		$Foil.ship = get_ship()
	if $Rudder/Foil != null:
		$Rudder/Foil.ship = get_ship()


func rotate_to(r: float) -> void:
	r = clamp(r, min_rotation, max_rotation)
	#if rot == r:
		#return
	rot = r
	$Rudder.rotation_degrees.z = -rot

func _box_shape(size: Vector3) -> BoxShape3D:
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = size
	return bs


func _on_signal_connection_typed_changed(channel: SignalConnection.Channel, value: float) -> void:
	if channel == rotation_channel:
		rotate_to(value)
