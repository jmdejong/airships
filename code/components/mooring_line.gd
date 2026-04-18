extends BaseComponent


func mouseover_description(target: Node, _player: Player) -> String:
	if target != $Interaction:
		return ""
	if get_ship().moored_to != null:
		return "depart"
	if $LandingPlaceDetect.has_overlapping_areas():
		return "moor"
	return ""


func _on_interaction_pressed_by(_player: Player) -> void:
	if get_ship().moored_to != null:
		get_ship().moored_to = null
	else:
		var landing_areas: Array[Area3D] = $LandingPlaceDetect.get_overlapping_areas()
		var moor_connectors = landing_areas.filter(func(area): return area is MoorConnector)
		if moor_connectors.is_empty():
			return
		var moor_connector: MoorConnector = moor_connectors[0]
		get_ship().moor_to(moor_connector)
