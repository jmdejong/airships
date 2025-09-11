class_name BoxComponent
extends BaseComponent

@export var density: float = 100

func physics_properties() -> PhysicsProperties:
	return PhysicsProperties.box(
		$CollisionShape3D.position,
		$CollisionShape3D.shape.size,
		density
	)
