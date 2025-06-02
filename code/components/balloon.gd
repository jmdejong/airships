extends BaseComponent

var radius = 10

func _ready() -> void:
	volume = 4.0/3 * PI * radius * radius * radius
	mass_ = 10
