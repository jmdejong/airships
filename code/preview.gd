extends Area3D

var valid_overlay: Material = preload("res://materials/build/valid_preview.tres")
var invalid_overlay: Material = preload("res://materials/build/invalid_preview.tres")

var valid: bool = true:
	set(value):
		valid = value
		if value:
			get_tree().set_group("visual", "material_overlay", valid_overlay)
		else:
			get_tree().set_group("visual", "material_overlay", invalid_overlay)

func _ready() -> void:
	get_tree().set_group("visual", "transparency", 0.5)
