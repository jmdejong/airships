extends BaseComponent

@export var power: float = 0.0:
	set(value):
		power = value
		%StatusPanel.text = "%2.2f kN" % (power / 1000.0)
		if power == 0:
			%Rotor.rps = sign(%Rotor.rps) * 0.02
		else:
			%Rotor.rps = value / 500
		changed.emit()
var step: float = 500
var max_power: float = 5000
var min_power: float = -2000

func _ready() -> void:
	power = power
	mass_ = 100.0
	volume = 0.25

func forces() -> Array[Force]:
	return [Force.new(%Rotor.position, ($CenterOfMass.position-%Rotor.position).normalized() * power).transformed(transform)]

func _on_less_pressed() -> void:
	power = max(power - step, min_power)

func _on_more_pressed() -> void:
	power = min(power + step, max_power)
