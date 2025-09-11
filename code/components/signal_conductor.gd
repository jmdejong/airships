class_name SignalConductor
extends Area3D

signal changed(value: float)
var value: float = 0.0:
	set(v):
		if value == v:
			return
		value = v
		update_value()

func update_value() -> void:
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
