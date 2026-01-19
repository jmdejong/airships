class_name Lifeline
extends Node3D

@export var length: float = 10
var anchor: LifeAnchor = null
var previous_stretch: float = 0

func attach(anchor: LifeAnchor) -> void:
	self.anchor = anchor

func detach() -> void:
	self.anchor = null

func reel_in(player: Player) -> void:
	if anchor == null:
		return
	player.position = anchor.anchor_point()

func apply_force(player: Player) -> void:
	if anchor == null:
		previous_stretch = 0
		return
	var distance: float = global_position.distance_to(anchor.anchor_point())
	var stretch = max(distance - length, 0)
	if stretch <= 0:
		previous_stretch = 0
		return
	var force: Vector3 = global_position.direction_to(anchor.anchor_point()) * pow(stretch, 3) * 2
	if stretch > previous_stretch:
		force *= 2
	previous_stretch = stretch
	player.apply_central_force(force)
	anchor.get_ship().apply_force(-force, anchor.anchor_point() - anchor.get_ship().global_position)

func _process(_delta: float) -> void:
	if anchor == null:
		$Rope.visible = false
		return
	$Rope.visible = true
	var anchor_point: Vector3 = anchor.anchor_point()
	$Rope.look_at_from_position((global_position + anchor_point) / 2.0, anchor_point)
	$Rope.scale.z = global_position.distance_to(anchor_point)
