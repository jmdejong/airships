class_name NoiseHeightSource
extends HeightSource
	
var noise: FastNoiseLite = FastNoiseLite.new()
var h = 200

func _init() -> void:
	noise.frequency = 0.002
	noise.seed = -1263

func height_at(pos: Vector2) -> float:
	return snappedf(noise.get_noise_2dv(pos) * h, 1)

func extremes(_area: Rect2) -> Vector2:
	return Vector2(-h, h)

func structures(_area: Rect2) -> Structure.Buffer:
	return Structure.Buffer.new()
