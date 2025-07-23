class_name ComponentBlueprint
extends Object

var factory: Callable
var preview: PackedScene
var area: AABB

func _init(factory: Callable, preview: PackedScene, area: AABB):
	self.factory = factory
	self.preview = preview
	self.area = area

func create() -> Component:
	return factory.call()

enum ComponentType { Woodblock, EngineHor }

static var WoodBlock: ComponentBlueprint = ComponentBlueprint.new(
	(func() -> Component: var node: Component = preload("res://scenes/components/wood_panel.tscn").instantiate();node.size = Vector3.ONE * Global.block_size;return node),
	preload("res://scenes/previews/woodblock.tscn"),
	AABB(-Global.block_center, Vector3.ONE*Global.block_size),
)
static var EngineHor: ComponentBlueprint = ComponentBlueprint.new(
	func(): return preload("res://scenes/components/engine.tscn").instantiate(),
	preload("res://scenes/previews/engine.tscn"),
	AABB(-Vector3.ONE*Global.block_size, Vector3(1.5, 1.0, 1.0))
)

static var components: Dictionary[ComponentType, ComponentBlueprint] = {
	ComponentType.Woodblock: WoodBlock,
	ComponentType.EngineHor: EngineHor
}

static func from_type(typ: ComponentType) -> ComponentBlueprint:
	return components[typ]


func snap_point(collision_point: Vector3, collision_vector: Vector3) -> Vector3:
	return Vector3(
		collision_point.x if collision_vector.x >= 0 else collision_point.x - 0.5,
		collision_point.y if collision_vector.y >= 0 else collision_point.y - 0.5,
		collision_point.z if collision_vector.z >= 0 else collision_point.z - 0.5
	)
