@tool
class_name WireStraight
extends BaseComponent

var density = 200
var radius = 0.05

@export var length: float = 0.25:
	set(value):
		length = snappedf(value, Global.block_size)
		volume = PI * radius * radius * length
		mass_ = density * volume
		var center := Vector3(Global.block_size / 2.0, length / 2.0, Global.block_size / 2.0)
		$CollisionShape3D.position = center
		var shape: BoxShape3D = $CollisionShape3D.shape.duplicate_deep()
		shape.size.y = length;
		$CollisionShape3D.shape = shape
		$MeshInstance3D.position = center
		var mesh: CylinderMesh = $MeshInstance3D.mesh.duplicate_deep()
		mesh.height = length
		$MeshInstance3D.mesh = mesh
		$CenterOfMass.position = center
		var connect_shape := BoxShape3D.new()
		connect_shape.size = Vector3(0.1, length + 0.1, 0.1)
		$SignalConnection.position = center
		$SignalConnection/CollisionShape3D.shape = connect_shape.duplicate_deep()
		$Connection.position = center
		$Connection/CollisionShape3D.shape = connect_shape.duplicate_deep()


func to_own_json() -> Dictionary[String, Variant]:
	return {"length": length}

func initialize_from_json(json: Dictionary) -> void:
	length = json.length
