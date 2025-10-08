class_name SignalType
extends Object

@export var unit: String
@export var min_allowed: float
@export var max_allowed: float

func _init(unit: String, min_: float, max_: float) -> void:
	self.unit = unit
	self.min_allowed = min_
	self.max_allowed = max_

func combine(other: SignalType) -> SignalType:
	var u: String = unit
	if other.unit != unit:
		u = "???"
	return SignalType.new(u, min(min_allowed, other.min_allowed), max(max_allowed, other.max_allowed))
