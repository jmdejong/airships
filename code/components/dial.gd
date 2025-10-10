extends BoxComponent

@export var scale_degree: float = 2
@export var step_size: float = 1
@export var signal_channel: SignalConnection.Channel = SignalConnection.Channel.RED

func _ready() -> void:
	update()

func update() -> void:
	if !is_node_ready():
		return
	var value: float = $SignalConnection.value(signal_channel)
	var typ: SignalType = $SignalConnection.signal_type(signal_channel)
	$Screw.rotation_degrees.y = -value * scale_degree
	%StatusText.text = "%3.2f %s" % [value, typ.unit]

func _on_signal_connection_changed(_channel: SignalConnection.Channel, _value: float) -> void:
	update()

func _on_less_pressed() -> void:
	$SignalConnection.change_base_value(signal_channel, -step_size)

func _on_more_pressed() -> void:
	$SignalConnection.change_base_value(signal_channel, step_size)
