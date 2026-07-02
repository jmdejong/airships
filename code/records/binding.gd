class_name Binding
extends Resource

enum Action {None, Set, Change}

@export var key: Key
@export var control: String
@export var action: Action = Action.None
@export var change: float
@export var set_to: float

func to_json() -> Dictionary[String, Variant]:
	var json: Dictionary[String, Variant] = {"key": key, "control": control, "action": action}
	if action == Action.Change:
		json.change = change
	elif action == Action.Set:
		json.set_to = set_to
	return json

static func from_json(json: Dictionary) -> Binding:
	var binding := Binding.new()
	binding.key = json.key
	binding.control = json.control
	binding.action = json.action
	binding.change = json.get("change", 0.0)
	binding.set_to = json.get("set_to", 0.0)
	return binding
