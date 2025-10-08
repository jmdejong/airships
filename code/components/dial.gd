extends BoxComponent

@export var scale_degree: float = 2
@export var step_size: float = 5

var value: SignalValue = SignalValue.empty():
	set(val):
		if value.equals(val):
			return
		value = val
		update()

func _ready() -> void:
	value = $SignalConnection.value
	update()

func update() -> void:
	if !is_inside_tree():
		return
	$SignalConnection.value = value
	$Screw.rotation_degrees.y = -value.value * scale_degree
	%StatusText.text = "%3.2f %s" % [value.value, value.unit]

func _on_signal_connection_changed(value: SignalValue) -> void:
	self.value = value

func _on_less_pressed() -> void:
	value = value.changed_by(-step_size)

func _on_more_pressed() -> void:
	value = value.changed_by(step_size)
