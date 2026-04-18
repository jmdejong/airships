extends Node



var components: Dictionary[String, PackedScene]

func _ready() -> void:
	register(preload("res://scenes/components/ballast.tscn"))
	register(preload("res://scenes/components/balloon.tscn"))
	register(preload("res://scenes/components/barometer.tscn"))
	register(preload("res://scenes/components/engine.tscn"))
	register(preload("res://scenes/components/cable4m.tscn"))
	register(preload("res://scenes/components/cannon.tscn"))
	register(preload("res://scenes/components/chair.tscn"))
	register(preload("res://scenes/components/dial.tscn"))
	register(preload("res://scenes/components/life_anchor.tscn"))
	register(preload("res://scenes/components/mooring_line.tscn"))
	register(preload("res://scenes/components/rotary_table.tscn"))
	register(preload("res://scenes/components/slider.tscn"))
	register(preload("res://scenes/components/smalloon.tscn"))
	register(preload("res://scenes/components/status_panel.tscn"))
	register(preload("res://scenes/components/wire_connect.tscn"))
	register(preload("res://scenes/components/wire_straight.tscn"))
	register(preload("res://scenes/components/wood_panel.tscn"))
	
	register(preload("res://scenes/components/composite.tscn"))

func register(scene: PackedScene) -> void:
	var instance: Component = scene.instantiate()
	if instance.ctyp == null or instance.ctyp == "":
		push_error("component " + scene.to_string() + " does not have a ctyp")
		return
	if components.has(instance.ctyp):
		push_error("Duplicate type for " + components[instance.ctyp].to_string() + " and " + scene.to_string())
	components[instance.ctyp] = scene

func from_json(json: Dictionary) -> Component:
	var ctyp: String = json.get("_ct")
	var position: Vector3 = parse_vector3(json.get("_p"))
	var rotation: Vector3 = parse_vector3(json.get("_r"))
	var component_name: String = json.get("_n")
	if ctyp == null or is_nan(position.x) or is_nan(rotation.x) or name == null:
		push_error("Failed deserializing component from json " + JSON.stringify(json) + ". Mandatory property missing")
		return null
	var scene: PackedScene = components.get(ctyp)
	if scene == null:
		push_error("Failed deserializing unknown component type " + ctyp)
		return null
	var component: Component = scene.instantiate()
	component.position = position
	component.rotation = rotation
	component.name = component_name
	component.initialize_from_json(json)
	return component
	

func parse_vector3(json: Array) -> Vector3:
	if json.size() != 3:
		push_error("Invalid vector3: " + JSON.stringify(json))
		return Vector3(NAN, NAN, NAN)
	return Vector3(json[0], json[1], json[2])
