extends BoxComponent

@export var bindings: Array[Binding] = []

func _ready():
	$Seat.bindings = bindings
