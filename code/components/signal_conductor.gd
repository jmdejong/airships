class_name SignalConductor
extends Area3D

enum Channel {RED, GREEN, BLUE, YELLOW}
signal changed(value: SignalValue, channel: Channel)
var values: Dictionary[Channel, SignalValue] = {}

func set_value(channel: Channel, v: SignalValue) -> void:
	if v.equals(value(channel)):
		return
	values[channel] = v
	for c: SignalConductor in connected():
		c.set_value(channel, v)
	changed.emit(v, channel)

func value(channel: Channel) -> SignalValue:
	return values.get(channel, SignalValue.EMPTY)

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
	for channel: Channel in Channel.values():
		var v: SignalValue = value(channel).combine(area.value(channel))
		set_value(channel, v)
		area.set_value(channel, v)
