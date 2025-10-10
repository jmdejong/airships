class_name SignalType
extends Resource


@export var unit: String
@export var min_: float
@export var max_: float
@export var scale: float = 1

func _init(unit: String, min_: float, max_: float, scale: float) -> void:
	self.unit = unit
	self.min_ = min_
	self.max_ = max_
	self.scale = scale

func equals(other: SignalType) -> bool:
	if other == null:
		return false
	return unit == other.unit && min_ == other.min_ && max_ == other.max_

func unit_to_base(v: float):
	return clamp(v, min_, max_) / scale

func base_to_unit(v: float):
	return v * scale

func has_range() -> bool:
	return max_ > min_
	
func clamp(val: float) -> float:
	if has_range():
		return clamp(val, min_, max_)
	else:
		return val

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

func combine(other: SignalType) -> SignalType:
	if other == null:
		return self
	var new_unit: String = ""
	var new_scale: float = 1
	if unit == other.unit && scale == other.scale:
		new_unit = unit
		new_scale = scale
	else:
		new_unit = "??"
		new_scale = 1
	var new_min: float = min(min_ / scale, other.min_ / other.scale) * new_scale
	var new_max: float = max(max_ / scale, other.max_ / other.scale) * new_scale
	return SignalType.new(new_unit, new_min, new_max, new_scale)
