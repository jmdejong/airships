extends BaseComponent

@export var power_channel: SignalConnection.Channel = SignalConnection.Channel.RED
@export var power: float = 0.0:
	set(value):
		value = clamp(value, min_power, max_power)
		if power != value:
			power = value
			update_power()
var step: float = 5000
var max_power: float = 50000
var min_power: float = -50000
var signal_scale = 1000

func _ready() -> void:
	mass_ = 100.0
	volume = 0.25
	var typ: Dictionary[SignalConnection.Channel, SignalType] = {
		power_channel: SignalType.new("kW", min_power / signal_scale, max_power / signal_scale, 5)
	}
	$SignalConnection.own_type = typ
	update_power()

func update_power() -> void:
		if power == 0:
			%Rotor.rps = sign(%Rotor.rps) * 0.02
		else:
			%Rotor.rps = power / 1000
		#$SignalConnection.set_value(
			#power_channel, 
			#power / signal_scale
		#)
		changed.emit()

func forces() -> Array[Force]:
	var direction: Vector3 = ($CenterOfMass.position-%Rotor.position).normalized() * sign(power)
	return [Force.new(%Rotor.position, direction, abs(power)).transformed(transform)]

func _on_signal_connection_changed(channel: SignalConnection.Channel, value: float) -> void:
	if channel == power_channel:
		power = value * signal_scale
