extends BaseComponent

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
#var signal_value = SignalValue.new(power / signal_scale, "kW", min_power / signal_scale, max_power / signal_scale)

func _ready() -> void:
	mass_ = 100.0
	volume = 0.25
	update_power()

func update_power() -> void:
		%StatusPanel.text = "%2.2f kW" % (power / 1000.0)
		if power == 0:
			%Rotor.rps = sign(%Rotor.rps) * 0.02
		else:
			%Rotor.rps = power / 500
		$SignalConnection.value = SignalValue.new(power / signal_scale, "kW", min_power / signal_scale, max_power / signal_scale)
		changed.emit()

func forces() -> Array[Force]:
	var direction: Vector3 = ($CenterOfMass.position-%Rotor.position).normalized() * sign(power)
	return [Force.new(%Rotor.position, direction, abs(power)).transformed(transform)]

func _on_less_pressed() -> void:
	power = power - step

func _on_more_pressed() -> void:
	power = power + step

func _on_signal_connection_changed(value: SignalValue) -> void:
	power = value.value * signal_scale
