class_name Structure
extends RefCounted

var scene: PackedScene
var mesh: Mesh

func _init(scene: PackedScene, mesh: Mesh) -> void:
	self.scene = scene
	self.mesh = mesh

static var tree: Structure = Structure.new(preload("res://scenes/structures/tree.tscn"), preload("res://models/tree.obj"))
static var small_tree: Structure = Structure.new(preload("res://scenes/structures/small_tree.tscn"), null)
static var rock: Structure = Structure.new(preload("res://scenes/structures/rock.tscn"), null)
static var house: Structure = Structure.new(preload("res://scenes/structures/house.tscn"), null)



class Buffer extends RefCounted:
	var structures: Array[Instance] = []
	
	func add(struct: Structure, pos: Vector3, rot: float):
		var si: Instance = Instance.new()
		si.typ = struct
		si.pos = pos
		si.rot = rot
		structures.append(si)
	
	func nodes() -> Array[Node3D]:
		var n: Array[Node3D] = []
		for si: Instance in structures:
			var node: Node3D = si.typ.scene.instantiate()
			node.position = si.pos
			node.rotate_y(si.rot)
			n.append(node)
		return n
	
	func multimeshes() -> Array[MultiMesh]:
		var m: Dictionary[Structure, Array] = {}
		for si: Instance in structures:
			if si.typ == null:
				continue
			if !m.has(si.typ):
				m[si.typ] = []
			m[si.typ].append(si)
		var mm: Array[MultiMesh] = []
		for typ: Structure in m:
			var instances: Array[Instance] = []
			instances.assign(m[typ])
			var multimesh: MultiMesh = MultiMesh.new()
			multimesh.transform_format = MultiMesh.TRANSFORM_3D
			multimesh.mesh = typ.mesh
			multimesh.instance_count = instances.size()
			for i in instances.size():
				var instance: Instance = instances[i]
				var transform: Transform3D = Transform3D().rotated(Vector3.UP, instance.rot).translated(instance.pos)
				multimesh.set_instance_transform(i, transform)
			mm.append(multimesh)
		return mm
	
	func add_buffer(other: Buffer) -> void:
		structures.append_array(other.structures)

class Instance extends RefCounted:
	var typ: Structure
	var pos: Vector3
	var rot: float
