@tool
extends BaseComponent

@export var max_rotation: float = 45
@export var min_rotation: float = -45
@export var density: float = 1
@export var thickness: float = 0.5
var surface_area: float = 72 # m^2
@export var rotation_channel: SignalConnection.Channel = SignalConnection.Channel.None
var rot: float = 0

var previous_velocity: Vector3 = Vector3.ZERO

func mass() -> float:
	return surface_area * thickness * density

func _ready() -> void:
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
