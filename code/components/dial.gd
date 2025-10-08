extends BoxComponent

@export var scale_degree: float = 3
@export var step_size: float = 5

var value: float:
	set(val):
		if signal_type != null:
			val = clamp(val, signal_type.min_allowed, signal_type.max_allowed)
		if val == value:
			return
		value = val
		update()
var signal_type: SignalType = null:
	set(t):
		if t == signal_type:
			return
		signal_type = t
		update()

func _ready() -> void:
	value = $SignalConnection.value
	signal_type = $SignalConnection.signal_type
	update()

func update() -> void:
	$SignalConnection.value = value
	$Screw.rotation_degrees.y = -value * scale_degree
	var unit = ""
	if signal_type != null:
		unit = signal_type.unit
	%StatusText.text = "%3.2f %s" % [value, unit]

func _on_signal_connection_changed(value: float, type: SignalType) -> void:
	self.value = value
	self.signal_type = type

func _on_less_pressed() -> void:
	value -= step_size

func _on_more_pressed() -> void:
	value += step_size
