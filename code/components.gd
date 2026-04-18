extends Node


#const components: Array[PackedScene] = [
	#preload("res://scenes/components/ballast.tscn"),
	#preload("res://scenes/components/balloon.tscn"),
	#preload("res://scenes/components/wood_panel.tscn"),
	#preload("res://scenes/components/engine.tscn"),
	#preload("res://scenes/components/signal_control.tscn")
#]

var components: Dictionary[String, PackedScene]

func _ready() -> void:
	register(preload("res://scenes/components/ballast.tscn"))
	register(preload("res://scenes/components/balloon.tscn"))
	register(preload("res://scenes/components/wood_panel.tscn"))
	register(preload("res://scenes/components/engine.tscn"))
	register(preload("res://scenes/components/cable4m.tscn"))
	register(preload("res://scenes/components/wire_straight.tscn"))

func register(scene: PackedScene) -> void:
	var instance: Component = scene.instantiate()
	if components.has(instance.typ):
		push_error("Duplicate type for " + components[instance.typ].to_string() + " and " + scene.to_string())
	components[instance.typ] = scene

func from_json(json: Dictionary[String, Variant]) -> Component:
	var type: String = json.get("_ct")
	var position: Vector3 = __parse_vector3(json.get("_p"))
	var rotation: Vector3 = __parse_vector3(json.get("_r"))
	var name: String = json.get("_n")
	if type == null or is_nan(position.x) or is_nan(rotation.x) or name == null:
		push_error("Failed deserializing component from json " + JSON.stringify(json) + ". Mandatory property missing")
		return null
	var scene: PackedScene = components.get(type)
	if scene == null:
		push_error("Failed deserializing unknown component type " + type)
		return null
	var component: Component = scene.instantiate()
	component.position = position
	component.rotation = rotation
	component.name = name
	component.initialize_from_json(json)
	return component
	

func __parse_vector3(json: Array[float]) -> Vector3:
	if json.size() != 3:
		return Vector3(NAN, NAN, NAN)
	return Vector3(json[0], json[1], json[2])
