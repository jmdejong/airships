extends BaseComponent

var max_filling: float = 1000
@export var initial_filling: float = 200
var filling: float :
	set(value):
		filling = value
		%Water.scale.y = filling/max_filling
		%Water.visible = filling > 0.0
		%StatusPanel.text = "%4.0f kg\n%3d%%" % [filling, int(filling/max_filling * 100)]
		changed.emit()

var step: float = 100

func _ready() -> void:
	filling = initial_filling

func mass() -> float:
	return filling + 1

func displaced_volume() -> float:
	return filling / max_filling * 0.9 + 0.1

func _on_less_pressed() -> void:
	filling = max(filling - step, 0.0)

func _on_more_pressed() -> void:
	filling = min(filling + step, max_filling)
