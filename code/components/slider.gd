extends BoxComponent

@export var signal_channel: SignalConnection.Channel = SignalConnection.Channel.RED

func _ready() -> void:
	%SignalControl.channel = signal_channel

func _on_signal_control_changed(value: float, signal_type: SignalType) -> void:
	if !is_node_ready():
		return
	%ColorRect.set_(value, max(signal_type.min_allowed(), -1000), min(signal_type.max_allowed(), 1000))
	%StatusText.text = "%3.2f %s" % [value, signal_type.unit]
