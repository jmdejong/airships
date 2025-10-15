extends BoxComponent

@export var scale_degree: float = 2
@export var signal_channel: SignalConnection.Channel = SignalConnection.Channel.None

func _ready() -> void:
	%SignalControl.channel = signal_channel

func _on_signal_control_changed(value: float, signal_type: SignalType) -> void:
	$Screw.rotation_degrees.y = -value * scale_degree
	%StatusText.text = "%3.2f %s" % [value, signal_type.unit]
