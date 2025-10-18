extends Area3D

func _ready() -> void:
	update(null)

func update(left: Component):
	var is_conn: bool = false
	var component: Component = get_parent().get_parent()
	var ship: Airship = component.get_ship()
	for other: Area3D in get_overlapping_areas():
		var other_comp: Component = other.get_parent()
		if other_comp != component && other_comp != left && other_comp.get_ship() == ship:
			is_conn = true
			break
	get_parent().visible = is_conn
	get_parent().disabled = !is_conn
	component.changed_shapes.emit()

func _on_area_entered(_area: Area3D) -> void:
	update(null)

func _on_area_exited(area: Area3D) -> void:
	update(area.get_parent())
