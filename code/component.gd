class_name Component
extends Object

var scene: PackedScene
var preview: PackedScene

func _init(scene: PackedScene, preview: PackedScene):
	self.scene = scene
	self.preview = preview

enum ComponentType { Woodblock }

static var WoodBlock: Component = Component.new(
	preload("res://scenes/components/woodblock.tscn"),
	preload("res://scenes/previews/woodblock.tscn")
)

static var components: Dictionary[ComponentType, Component] = {
	ComponentType.Woodblock: WoodBlock
}

static func from_type(typ: ComponentType):
	return components[typ]

func snap_point(collision_point: Vector3, collision_vector: Vector3) -> Vector3:
	return Vector3(
		collision_point.x if collision_vector.x >= 0 else collision_point.x - 0.5,
		collision_point.y if collision_vector.y >= 0 else collision_point.y - 0.5,
		collision_point.z if collision_vector.z >= 0 else collision_point.z - 0.5
	)
