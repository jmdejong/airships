class_name Structure
extends RefCounted

var scene: PackedScene

func _init(scene: PackedScene) -> void:
	self.scene = scene

static var tree: Structure = Structure.new(preload("res://scenes/structures/tree.tscn"))
static var small_tree: Structure = Structure.new(preload("res://scenes/structures/small_tree.tscn"))
static var rock: Structure = Structure.new(preload("res://scenes/structures/rock.tscn"))
static var house: Structure = Structure.new(preload("res://scenes/structures/house.tscn"))
