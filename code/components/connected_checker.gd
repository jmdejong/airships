extends Area3D

func _ready() -> void:
	update(null)

func update(left: Component):
	var is_conn: bool = false
	var component: Component = get_parent().get_parent()
	for other: Area3D in get_overlapping_areas():
		if other.get_parent() != component && other.get_parent() != left:
			is_conn = true
			break
	get_parent().visible = is_conn
	get_parent().disabled = !is_conn
	component.changed_shapes.emit()

func _on_area_entered(_area: Area3D) -> void:
	update(null)

func _on_area_exited(area: Area3D) -> void:
	update(area.get_parent())
