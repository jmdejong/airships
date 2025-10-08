class_name SignalConductor
extends Area3D

signal changed(value: SignalValue)
var value: SignalValue = SignalValue.empty():
	set(v):
		if v.equals(value):
			return
		value = v
		update()

func update() -> void:
	for c: SignalConductor in connected():
		c.value = value
	changed.emit(value)

func connected() -> Array[SignalConductor]:
	var others: Dictionary[SignalConductor, bool] = {}
	var fringe = [self]
	while !fringe.is_empty():
		var conductor: SignalConductor = fringe.pop_back()
		for neighbour: SignalConductor in conductor.get_overlapping_areas():
			if !others.has(neighbour):
				others[neighbour] = true
				fringe.append(neighbour)
	return others.keys()

func _on_area_entered(area: SignalConductor) -> void:
	if area.value == null:
		area.value = value
	elif value == null:
		value = area.value
	else:
		value = value.combine(area.value)
		area.value = value
