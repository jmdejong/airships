@tool
class_name Cable
extends BaseComponent

var density: float = 1000
var width: float = 0.05

@export var length: float = 1:
	set(value):
		length = snappedf(value, Global.block_size)
		volume = length * width * width
		mass_ = density * volume
		var center := Vector3(Global.block_size / 2.0, length / 2.0, Global.block_size / 2.0)
		$CollisionShape3D.position = center
		var shape: BoxShape3D = $CollisionShape3D.shape.duplicate_deep()
		shape.size.y = length;
		$CollisionShape3D.shape = shape
		$MeshInstance3D.position = center
		var mesh: BoxMesh = $MeshInstance3D.mesh.duplicate_deep()
		mesh.size.y = length
		$MeshInstance3D.mesh = mesh
		$CenterOfMass.position = center
		var connect_shape := BoxShape3D.new()
		connect_shape.size = Vector3(0.1, length + 0.1, 0.1)
		$Connection.position = center
		$Connection/CollisionShape3D.shape = connect_shape.duplicate_deep()


func to_own_json() -> Dictionary[String, Variant]:
	return {"length": length}

func initialize_from_json(json: Dictionary) -> void:
	length = json.length
