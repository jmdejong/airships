extends BaseComponent

@export var density: float = 100

func _ready() -> void:
	volume = _calculate_volume()
	mass_ = density * volume

func _calculate_volume() -> float:
	var size: Vector3 = $CollisionShape3D.shape.size * $CollisionShape3D.scale * scale
	return size.x * size.y * size.z
