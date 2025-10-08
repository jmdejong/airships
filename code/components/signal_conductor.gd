class_name SignalConductor
extends Area3D

signal changed(value: float, type: SignalType)
var has_changed = false
var value: float = 0.0:
	set(v):
		if value == v:
			return
		has_changed = true
		value = v
		update()
var signal_type: SignalType = null:
	set(t):
		if signal_type == t:
			return
		has_changed = true
		signal_type = t
		update()

func update() -> void:
	for c: SignalConductor in connected():
		c.value = value
		c.signal_type = signal_type
	changed.emit(value, signal_type)

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
	if area.has_changed:
		value = area.value
		signal_type = area.signal_type
	else:
		area.value = value
		area.signal_type = signal_type
