extends Control


func _process(_delta):
	var pressure: float = Atmosphere.pressure(%CenterOfMass.global_position.y)
	rotation = %Scale.value_to_angle(pressure/1000)
	
