class_name Force
extends Object

var pos: Vector3
var direction: Vector3
func _init(pos: Vector3, direction: Vector3) -> void:
	self.pos = pos
	self.direction = direction

func transformed(t: Transform3D) -> Force:
	return Force.new(t * pos, t.basis.get_rotation_quaternion() * direction)
