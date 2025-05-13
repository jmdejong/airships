extends RayCast3D

var preview: Area3D = null
var build_component: Component = null
var component_position: Vector3
var rotation_mode: int = 2:
	set(value):
		rotation_mode = posmod(value, 4)
		rotation_transform = Transform3D(Basis(Vector3.UP, rotation_mode * PI / 2), Vector3.ZERO)
var rotation_transform: Transform3D = Transform3D(Basis(Vector3.UP, rotation_mode * PI / 2), Vector3.ZERO)

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
		preview.transform = rotation_transform
		var p: Vector3 = %BuildCast.get_collision_point() * collider.transform
		var n: Vector3 = (%BuildCast.get_collision_normal() * collider.quaternion).round()
		if n.length_squared() != 1:
			%BuildPreview.global_position = collider.to_global(p)
			preview.valid = false
			return
		var area: AABB = rotation_transform * build_component.area
		var center_offset: Vector3 = n * area.size / 2 
		component_position = (p  + center_offset - area.get_center()).snappedf(Global.block_size)
		%BuildPreview.global_position = collider.to_global(component_position)
		preview.valid = !preview.has_overlapping_bodies()
	else:
		%BuildPreview.rotation = Vector3.ZERO
		%BuildPreview.position = Vector3.ZERO
		if preview and preview.valid:
			preview.valid = false

func try_build() -> void:
	var collider: CollisionObject3D = %BuildCast.get_collider()
	place_preview()
	if preview.valid:
		collider.build_component(component_position, build_component, rotation_transform)

func try_remove() -> void:
	var collider: CollisionObject3D = %BuildCast.get_collider()
	if collider == null:
		return
	var shape: CollisionShape3D = collider.shape_owner_get_owner(collider.shape_find_owner(%BuildCast.get_collider_shape()))
	var component: Node3D = shape.get_meta("component")
	component.get_parent().remove_child(component)
	component.changed.emit()
	component.queue_free()
