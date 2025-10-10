class_name SignalConnection
extends Area3D

enum Channel {RED, GREEN, BLUE, YELLOW, None}
signal changed(channel: Channel, value: float)

#signal connections_changed
var values: Dictionary[Channel, float] = {}
var types: Dictionary[Channel, SignalType] = {}:
	set(val):
		var combined: Dictionary[Channel, SignalType] = types.merged(val)
		types = val
		for channel: Channel in combined:
			changed.emit(channel, value(channel))
var own_type: Dictionary[Channel, SignalType] = {}:
	set(val):
		own_type = val
		change_connections()

@export var max_voltage = 10

func set_raw_value(channel: Channel, v: float) -> void:
	if v == raw_value(channel):
		return
	values[channel] = v
	for c: SignalConnection in get_overlapping_areas():
		c.set_raw_value(channel, v)
	changed.emit(channel, value(channel))

func set_value(channel: Channel, v: float) -> void:
	set_raw_value(channel, signal_type(channel).unit_to_base(v))

func change_value(channel: Channel, v: float) -> void:
	set_value(channel, v + value(channel))

func change_base_value(channel: Channel, v: float) -> void:
	change_value(channel, signal_type(channel).base_to_unit(v))

func value(channel: Channel) -> float:
	return signal_type(channel).base_to_unit(raw_value(channel))

func raw_value(channel: Channel) -> float:
	return values.get(channel, 0)

func signal_type(channel: Channel) -> SignalType:
	return own_type.get(channel, types.get(channel, SignalType.new("V", -10, 10, 1)))

func connected() -> Array[SignalConnection]:
	var others: Dictionary[SignalConnection, bool] = {}
	var fringe = [self]
	while !fringe.is_empty():
		var connection: SignalConnection = fringe.pop_back()
		for neighbour: SignalConnection in connection.get_overlapping_areas():
			if !others.has(neighbour):
				others[neighbour] = true
				fringe.append(neighbour)
	return others.keys()

func all_connected() -> Array[SignalConnection]:
	var all: Array[SignalConnection] = [self]
	all.append_array(connected())
	return all

func search_types() -> Dictionary[Channel, SignalType]:
	var typs: Dictionary[Channel, SignalType] = own_type.duplicate()
	for other: SignalConnection in connected():
		for channel: SignalConnection.Channel in other.own_type:
			var other_type: SignalType = other.own_type.get(channel)
			if !typs.has(channel):
				typs[channel] = other_type
			else:
				typs[channel] = typs[channel].combine(other_type)
	return typs

func change_connections():
	if is_node_ready():
		types = search_types()
		for connection: SignalConnection in connected():
			connection.types = types

func _on_area_entered(area: SignalConnection) -> void:
	change_connections()
	for channel: Channel in Channel.values():
		var v: float = raw_value(channel)
		if abs(area.raw_value(channel)) > abs(raw_value(channel)):
			v = area.raw_value(channel)
		set_raw_value(channel, v)
		area.set_raw_value(channel, v)

func _on_area_exited(_area: SignalConnection) -> void:
	change_connections()
