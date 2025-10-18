@tool
extends Node

var block_size: float = 0.25
var block_center: Vector3 = Vector3.ONE * block_size / 2.0


func relative_transform(descendant: Node3D, ancestor: Node3D) -> Transform3D:
	return (ancestor.global_transform.inverse() * descendant.global_transform)
