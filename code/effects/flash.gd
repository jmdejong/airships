extends Node3D


func _ready() -> void:
	$AnimationPlayer.play("flash")
	pass
	#var tween: Tween = create_tween()
	#tween.tween_property($Mesh, "scale", Vector3(3, 3, 3), 2)
	#var tween2 = tween.parallel()
	#tween2.tween_property($Light, "light_energy", 10, 1)
	#tween2.tween_property($Light, "light_energy", 0, 1)
	#await tween.finished
	#queue_free()


func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	queue_free()
