extends Area3D


var valid: bool = true:
	set(value):
		valid = value
		if value:
			$MeshInstance3D.material_override.albedo_color = Color(0.5, 0.5, 1.0, 0.5)
		else:
			$MeshInstance3D.material_override.albedo_color = Color(1.0, 0.5, 0.5, 0.5)
