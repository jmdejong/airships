extends MeshInstance3D

func _ready() -> void:
	var sun: DirectionalLight3D = get_tree().get_first_node_in_group("sun")
	var material: ShaderMaterial = material_override
	material.set_shader_parameter("sun", sun.basis.z.normalized())
