extends BoxComponent

@export var bindings: Array[Binding] = []

func _ready():
	$Seat.bindings = bindings

func to_own_json() -> Dictionary[String, Variant]:
	return {"bindings": bindings.map(func(binding): return binding.to_json())}

func initialize_from_json(json: Dictionary) -> void:
	bindings = []
	for json_binding in json.bindings:
		bindings.append(Binding.from_json(json_binding))
