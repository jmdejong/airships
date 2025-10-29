extends RigidBody3D


func _on_body_shape_entered(_body_rid: RID, body: Node, body_shape_index: int, _local_shape_index: int) -> void:
	if body is Airship:
		var collision_shape: CollisionShape3D = body.shape_owner_get_owner(body.shape_find_owner(body_shape_index))
		var ship: Airship = body
		ship.impact(collision_shape, self)
