class_name Hasher
extends RefCounted

static func _hashi(i: int) -> int:
	var rng = RandomNumberGenerator.new()
	rng.seed = i
	return rng.randi()

var _seed: int

func _init(seed_: int) -> void:
	_seed = seed_

func rng() -> RandomNumberGenerator:
	var rng = RandomNumberGenerator.new()
	rng.seed = _seed
	return rng

func with(id: int) -> Hasher:
	return Hasher.new(_hashi(_seed ^ _hashi(id)))

func with_vec2(v: Vector2) -> Hasher:
	return with(PackedVector2Array([v]).to_byte_array().to_int64_array()[0])


func randf() -> float:
	return rng().randf()

func randi() -> int:
	return rng().randi()

func randi_range(from: int, to: int) -> int:
	return rng().randi_range(from, to)

func randf_range(from: float, to: float) -> float:
	return rng().randf_range(from, to)


func pick_weighted(options: Array[Array]):
	var total: float = 0
	for option: Array in options:
		var weight: float = option[1]
		total += weight
	var r: float = self.randf() * total
	for option: Array in options:
		r -= option[1]
		if r < 0:
			return option[0]
	assert(false)
