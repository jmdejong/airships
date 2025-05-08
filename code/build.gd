extends RayCast3D

var preview: Area3D = null
var build_component: Component = null

func select_build(component: Component) -> void:
	for child in %BuildPreview.get_children():
		child.queue_free()
	build_component = component
	if component == null:
		preview = null
	else:
		preview = component.preview.instantiate()
		%BuildPreview.add_child(preview)

func place_preview() -> void:
	var collider = %BuildCast.get_collider()
	if collider != null and collider.has_method("is_build_target"):
		%BuildPreview.global_rotation = collider.global_rotation
		var cpos: Vector3 = collider.to_local(%BuildCast.get_collision_point() + %BuildCast.get_collision_normal() * 0.24).snappedf(0.5)
		%BuildPreview.global_position = collider.to_global(cpos)
		preview.valid = !preview.has_overlapping_bodies()
	else:
		%BuildPreview.rotation = Vector3.ZERO
		%BuildPreview.position = Vector3.ZERO
		if preview and preview.valid:
			preview.valid = false

func try_build() -> void:
	var collider = %BuildCast.get_collider()
	if collider != null and collider.has_method("is_build_target"):
		%BuildPreview.global_rotation = collider.global_rotation
		var cpos: Vector3 = collider.to_local(%BuildCast.get_collision_point() + %BuildCast.get_collision_normal() * 0.24).snappedf(0.5)
		%BuildPreview.global_position = collider.to_global(cpos)
		preview.valid = !preview.has_overlapping_bodies()
		if preview.valid:
			collider.build_component(cpos, build_component)

func try_remove() -> void:
	var collider: CollisionObject3D = %BuildCast.get_collider()
	if collider == null:
		return
	var shape: CollisionShape3D = collider.shape_owner_get_owner(collider.shape_find_owner(%BuildCast.get_collider_shape()))
	var component: Node3D = shape.get_meta("component")
	component.get_parent().remove_child(component)
	component.changed.emit()
	component.queue_free()
