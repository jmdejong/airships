extends BaseComponent

@export var power: float = 0.0:
	set(value):
		power = value
		%StatusPanel.text = "%2.2f kW" % (power / 1000.0)
		if power == 0:
			%Rotor.rps = sign(%Rotor.rps) * 0.02
		else:
			%Rotor.rps = value / 500
		changed.emit()
var step: float = 5000
var max_power: float = 50000
var min_power: float = -50000

func _ready() -> void:
	power = power
	mass_ = 100.0
	volume = 0.25

func forces() -> Array[Force]:
	var direction: Vector3 = ($CenterOfMass.position-%Rotor.position).normalized() * sign(power)
	return [Force.new(%Rotor.position, direction, abs(power)).transformed(transform)]

func _on_less_pressed() -> void:
	power = max(power - step, min_power)

func _on_more_pressed() -> void:
	power = min(power + step, max_power)
