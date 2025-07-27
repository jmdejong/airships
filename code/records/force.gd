class_name Force
extends Object

var pos: Vector3
var direction: Vector3
var power: float

func _init(pos: Vector3, direction: Vector3, power: float) -> void:
	self.pos = pos
	self.direction = direction
	self.power = power

func transformed(t: Transform3D) -> Force:
	return Force.new(t * pos, t.basis.get_rotation_quaternion() * direction, power)
