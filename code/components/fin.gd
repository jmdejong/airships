@tool
class_name Fin
extends BaseComponent

@export var density: float = 1
@export var thickness: float = 0.5
var surface_area: float = 72 # m^2

var previous_velocity: Vector3 = Vector3.ZERO

func mass() -> float:
	return surface_area * thickness * density

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	$Foil.ship = get_ship()

func _enter_tree() -> void:
	if Engine.is_editor_hint():
		return
	if $Foil != null:
		$Foil.ship = get_ship()

func _box_shape(size: Vector3) -> BoxShape3D:
	var bs: BoxShape3D = BoxShape3D.new()
	bs.size = size
	return bs
