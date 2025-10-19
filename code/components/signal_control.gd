class_name SignalControl
extends Node

@export var default_step: float = 1
@export var channel: SignalConnection.Channel = SignalConnection.Channel.None:
	set(val):
		if val != channel:
			update_network()
			channel = val
var signal_type: SignalType = SignalType.VOLT

signal changed(value: float, signal_type: SignalType)

func _ready() -> void:
	assert(get_parent() is SignalConnection)
	_conn().changed.connect(update_value)
	_conn().network_changed.connect(update_network)
	update_network()

func _conn() -> SignalConnection:
	return get_parent()

func value() -> float:
	return signal_type.base_to_unit(_conn().raw_value(channel))

func set_value(val: float):
	_conn().set_raw_value(channel, signal_type.unit_to_base(val))

func update_network() -> void:
	signal_type = _conn().search_type(channel)
	changed.emit(value(), signal_type)

func update_value(channel: SignalConnection.Channel, value: float) -> void:
	if channel == self.channel:
		changed.emit(value(), signal_type)

func change_raw_value(by: float) -> void:
	set_value(value() + signal_type.base_to_unit(by))

func incr_step() -> void:
	change_raw_value(default_step)
func decr_step() -> void:
	change_raw_value(-default_step)

func reset_value() -> void:
	_conn().set_raw_value(channel, 0)
