class_name Binding
extends Resource

@export var key: Key
@export var control: String
@export var change: float

func to_json() -> Dictionary[String, Variant]:
	return {"key": key, "control": control, "change": change}

static func from_json(json: Dictionary) -> Binding:
	var binding := Binding.new()
	binding.key = json.key
	binding.control = json.control
	binding.change = json.change
	return binding
