extends BoxComponent

@export var step_size: float = 5
@export var signal_channel: SignalConnection.Channel = SignalConnection.Channel.RED

func _ready() -> void:
	update()

func update() -> void:
	if !is_node_ready():
		return
	var value: float = $SignalConnection.value(signal_channel)
	var signal_type: SignalType = $SignalConnection.signal_type(signal_channel)
	%ColorRect.set_(value, max(signal_type.min_allowed(), -1000), min(signal_type.max_allowed(), 1000))
	%StatusText.text = "%3.2f %s" % [value, signal_type.unit]


func _on_signal_connection_changed(_channel: SignalConnection.Channel, _value: float) -> void:
	update()

func _on_less_pressed() -> void:
	$SignalConnection.change_value(signal_channel, -step_size)

func _on_more_pressed() -> void:
	$SignalConnection.change_value(signal_channel, step_size)
