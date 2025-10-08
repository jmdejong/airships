class_name SignalValue
extends Object


var value: float
var unit: String
var min_: float
var max_: float

func _init(value: float, unit: String, min_: float, max_: float) -> void:
	self.value = clamp(value, min_, max_)
	self.unit = unit
	self.min_ = min_
	self.max_ = max_

static func unlimited(value: float, unit: String) -> SignalValue:
	return SignalValue.new(value, unit, float("inf"), float("-inf"))

static func empty() -> SignalValue:
	return unlimited(0.0, "")

static var EMPTY: SignalValue = SignalValue.empty()

func with_value(val: float):
	return SignalValue.new(val, unit, min_, max_)

func changed_by(dif: float):
	return with_value(value + dif)

func equals(other: SignalValue) -> bool:
	if other == null:
		return false
	return value == other.value && unit == other.unit && min_ == other.min_ && max_ == other.max_

func has_range() -> bool:
	return max_ > min_

func min_allowed() -> float:
	if has_range():
		return min_
	else:
		return float("-inf")

func max_allowed() -> float:
	if has_range():
		return max_
	else:
		return float("inf")

func combine(other: SignalValue) -> SignalValue:
	if other == null:
		return self
	var new_value: float = value
	if abs(other.value) > abs(value):
		new_value = other.value
	var new_unit: String = ""
	if unit == other.unit:
		new_unit = unit
	elif unit == "":
		new_unit = other.unit
	elif other.unit == "":
		new_unit = unit
	else:
		new_unit = "??"
	var new_min: float = min(min_, other.min_)
	var new_max: float = max(max_, other.max_)
	return SignalValue.new(new_value, new_unit, new_min, new_max)
