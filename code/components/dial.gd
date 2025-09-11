extends BoxComponent

@export var scale_degree: float = 30


func _on_signal_connection_changed(value: float) -> void:
	$Screw.rotation_degrees.y = -value * scale_degree


func _on_less_pressed() -> void:
	$SignalConnection.value -= 0.5


func _on_more_pressed() -> void:
	$SignalConnection.value += 0.5
