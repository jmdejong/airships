@tool
class_name HexsHeightSource
extends HeightSource
var noise: FastNoiseLite = FastNoiseLite.new()
var color_noise: FastNoiseLite = FastNoiseLite.new()
var areas: Dictionary[Vector2i, Area] = {}
@export var hexes_to_shore: int = 12
@export var hex_rad: float = 192
@export var random_seed = 3851644
@export var center_height: int = 10

var hasher: Hasher

func _init() -> void:
	hasher = Hasher.new(random_seed)
	noise.fractal_octaves = 3
	noise.seed = hasher.with(3).randi()
	noise.frequency = 0.02
	noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	var arw: int = hexes_to_shore+2
	for z: int in range(-arw, arw+1):
		for x: int in range(max(-arw, -z-arw), min(arw, arw-z)+1):
			var v: Vector2i = Vector2i(x, z)
			var rh: Hasher = hasher.with(321).with_vec2(v)
			var center_distance = (abs(x) + abs(x+z) + abs(z))/2
			var area: Area = Sea.new()
			if v == Vector2i.ZERO:
				area = StartArea.new()
			elif center_distance < hexes_to_shore:
				area = rh.pick_weighted([
					[Field.new(), 0.4],
					[Village.new(), 0.1],
					[Forest.new(), 0.25],
					[Hill.new(), 0.25]
				])
			elif center_distance == hexes_to_shore:
				if rh.randf() < 0.5:
					area = ShallowSea.new()
				else:
					area = Coast.new()
			area.setup(hasher, v, hex_to_pix(v), hex_rad/2)
			areas[v] = area
	
	color_noise.seed = hasher.with(44).randi()
	color_noise.frequency = 0.05

func buffers_at(area: Rect2, segments: int) -> TileBuffers:
	const texture_size: float = 8
	var buf: TileBuffers = TileBuffers.new(area, segments)
	var size: Vector2i = buf.size
	for y in size.y:
		for x in size.x:
			var ind: int = x + y*size.x
			var tile: Vector2 = Vector2(x, y)
			var pos: Vector2 = buf.tile_to_pos * tile
			var position: Vector3 = pos_at(pos)
			buf.heights[ind] = position.y
			buf.positions[ind] = position
			buf.colors[ind] = color_modifier(pos)
			buf.tex_uvs[ind] = pos / texture_size
	for y in size.y - 1:
		for x in size.x - 1:
			var ind: int = x + y*size.x
			var normal: Vector3 = -(buf.positions[ind+1] - buf.positions[ind]).cross(buf.positions[ind+size.x] - buf.positions[ind]).normalized()
			buf.normals[ind] = normal
		var indr: int = (y+1) * (size.x) - 1
		var normalr: Vector3 = -(pos_at(buf.tile_to_pos * Vector2(size.x, y)) - buf.positions[indr]).cross(buf.positions[indr+size.x] - buf.positions[indr]).normalized()
		buf.normals[indr] = normalr
	for x in size.x - 1:
		var indb: int = x + (size.y - 1)*size.x
		var normalb: Vector3 = -(buf.positions[indb+1] - buf.positions[indb]).cross(pos_at(buf.tile_to_pos * Vector2(x, size.y)) - buf.positions[indb]).normalized()
		buf.normals[indb] = normalb
	var indbr: int = size.x * size.y - 1
	var normalbr: Vector3 = -(pos_at(buf.tile_to_pos * Vector2(size.x, size.y-1)) - buf.positions[indbr]).cross(pos_at(buf.tile_to_pos * Vector2(size.x-1, size.y)) - buf.positions[indbr]).normalized()
	buf.normals[indbr] = normalbr
	return buf

func color_modifier(pos: Vector2) -> Color:
	return (color_noise.get_noise_2dv(pos)+9)/10 * Color.WHITE

func height_at(pos: Vector2) -> float:
	var vf: Vector2 = pix_to_hex(pos)
	var vfloor := vf.floor()
	var vfrac: Vector2 = vf - vfloor
	var w: Vector3 = Vector3(0, 0, 0)
	var va: Vector2i = Vector2i(int(vfloor.x), int(vfloor.y))
	var vb: Vector2i = Vector2i(int(vfloor.x), int(vfloor.y)+1)
	var vc: Vector2i = Vector2i(int(vfloor.x)+1, int(vfloor.y))
	if vfrac.x + vfrac.y <= 1.0:
		w.x = 1-vfrac.x-vfrac.y
		w.y = vfrac.y
		w.z = vfrac.x
	else:
		va += Vector2i.ONE
		w.x = vfrac.x + vfrac.y - 1
		w.y = 1-vfrac.x
		w.z = 1-vfrac.y
	var area_a: Area = get_area(va)
	var area_b: Area = get_area(vb)
	var area_c: Area = get_area(vc)
	return _combine_areas(area_a, area_b, area_c, w, pos)

func _combine_areas(area_a: Area, area_b: Area, area_c: Area, w: Vector3, pos: Vector2) -> float:
	var center_influences: Vector3 = influences(w, 0.8)
	w = influences(w, center_influences.x * area_a.center_size() + center_influences.y * area_b.center_size() + center_influences.z * area_c.center_size())
	var n: float = clamp((1-max(w.x, w.y, w.z))*5, 0, 1)
	return float(area_a.height) * w.x + float(area_b.height) * w.y + float(area_c.height) * w.z  + noise.get_noise_2d(pos.x, pos.y) * n * 5.0


func influences(w: Vector3, center_size: float) -> Vector3:
	w -= Vector3.ONE*center_size/3
	w += Vector3.ONE*min(w.x, w.y, w.z, 0) / 2
	w = w.clampf(0, 1)
	w = w*w
	w /= w.x + w.y + w.z
	return w

func extremes(_region: Rect2) -> Vector2:
	return Vector2(-125, 100)

func structures(region: Rect2) -> Structure.Buffer:
	var strucs: Structure.Buffer = Structure.Buffer.new()
	for hex: Vector2i in hexes_in(region):
		var area: Area = get_area(hex)
		strucs.add_buffer(area.structures(self))
		#for structure: Node3D in area.structures():
			#var pos: Vector2 = Vector2(structure.position.x, structure.position.z)
			##if region.has_point(pos):
			#var s: Node3D = structure.duplicate()
			#s.position.y += height_at(pos)
			#strucs.append(s)
	return strucs

func hexes_in(region: Rect2) -> Array[Vector2i]:
	var hexes: Array[Vector2i] = []
	for hex_z: int in range(floor(pix_to_hex_z(region.position.y)), ceil(pix_to_hex_z(region.end.y))):
		var pix_z: float = hex_to_pix_z(hex_z)
		for hex_x : int in range(floor(pix_to_hex_x(Vector2(region.position.x, pix_z))), ceil(pix_to_hex_x(Vector2(region.end.x, pix_z)))):
			var hex: Vector2i = Vector2i(hex_x, hex_z)
			if region.has_point(hex_to_pix(hex)):
				hexes.append(hex)
	return hexes

func get_area(vid: Vector2i) -> Area:
	if not areas.has(vid):
		areas[vid] = DeepSea.new()
		areas[vid].setup(hasher, vid, hex_to_pix(vid), hex_rad)
	return areas[vid]

const SQRT3: float = sqrt(3)
#const SQRT3_INV: float = 1.0/SQRT3

func pix_to_hex_z(pix_z: float) -> float:
	return 2.0/SQRT3 * pix_z/hex_rad

func pix_to_hex_x(pix: Vector2) -> float:
	var vs: Vector2 = pix/hex_rad
	return vs.x - 1/SQRT3*vs.y

func pix_to_hex(pix: Vector2) -> Vector2:
	var vs: Vector2 = pix/hex_rad
	return Vector2(vs.x - 1/SQRT3*vs.y, 2/SQRT3*vs.y)

func pix_to_hex_i(pix: Vector2i) -> Vector2i:
	return hex_round(pix_to_hex(pix))

func hex_to_pix(hex: Vector2i) -> Vector2:
	return Vector2(hex.x + 0.5 * hex.y, SQRT3/2.0 * hex.y) * hex_rad

func hex_to_pix_z(hex_z: float) -> float:
	return SQRT3/2.0 * hex_z * hex_rad

func hex_round(v: Vector2) -> Vector2i:
	var v3 := Vector3(v.x, v.y, -v.x-v.y)
	var vr := v3.round()
	var vd := (vr - v3).abs()
	if vd.x > vd.y and vd.x > vd.z:
		vr.x = -vr.y - vr.z
	elif vd.y > vd.z:
		vr.y = -vr.x - vr.z
	else:
		vr.z = -vr.x - vr.y
	return Vector2i(int(vr.x), int(vr.y))

@abstract
class Area:
	var height: float
	var rid: Hasher
	var apos: Vector2i
	var global_pos: Vector2
	var area_radius: float
	var origin: Vector3
	var _structures: Structure.Buffer = null
	func setup(hasher: Hasher, apos: Vector2i, global_pos: Vector2, radius: float) -> void:
		rid = hasher.with(5321).with_vec2(apos)
		self.apos = apos
		self.global_pos = global_pos
		self.area_radius = radius
		height = calc_height()
		origin = Vector3(global_pos.x, height, global_pos.y)
	func structures(height_source: HeightSource) -> Structure.Buffer:
		if _structures == null:
			_structures = Structure.Buffer.new()
			fill(height_source)
		return _structures
	@abstract
	func calc_height() -> float
	func fill(_height_source: HeightSource) -> void:
		return
	func center_size() -> float:
		return 0

class StartArea extends Area:
	func calc_height() -> float:
		return 10
	func center_size() -> float:
		return 0.7

class Sea extends Area:
	func calc_height() -> float:
		return rid.randi_range(-30, -10)

class ShallowSea extends Area:
	func calc_height() -> float:
		return rid.randi_range(-8, -4)

class DeepSea extends Area:
	func calc_height() -> float:
		return rid.randi_range(-120, -80)

class Coast extends Area:
	func calc_height() -> float:
		return rid.randi_range(2, 6)

class Field extends Area:
	func calc_height() -> float:
		return rid.randi_range(4, 12) + int(rid.randf() * rid.randf() * 20)

class Forest extends Area:
	func calc_height() -> float:
		return rid.randi_range(6, 12)
	func fill(height_source: HeightSource) -> void:
		@warning_ignore("narrowing_conversion")
		var m: int = area_radius * 0.9
		for i in range(80):
			var r: Hasher = rid.with(i)
			#var tree: Node3D = Structure.tree.scene.instantiate()# if r.with(-83).randf() < 0.5 else Structure.small_tree.scene.instantiate()
			var pos: Vector2 = global_pos + Vector2(r.with(910).randi_range(-m, m), r.with(915).randi_range(-m, m))
			if pos.distance_to(global_pos) > m:
				continue
			#tree.position = Vector3(pos.x, 0, pos.y)
			_structures.add(Structure.tree, height_source.pos_at(pos), 0)
	func center_size() -> float:
		return 0.3

class Hill extends Area:
	func calc_height() -> float:
		return rid.randi_range(20, 80)
	func fill(height_source: HeightSource) -> void:
		@warning_ignore("narrowing_conversion")
		var m: int = area_radius*0.66
		for i in rid.with(-3).randi_range(0, 5):
			var r: Hasher = rid.with(i)
			#var rock: Node3D = Structure.rock.scene.instantiate()
			var pos: Vector2 = global_pos + Vector2(r.with(910).randi_range(-m, m), r.with(915).randi_range(-m, m))
			#rock.position = Vector3(pos.x, 0, pos.y)
			#rock.rotate_y(PI/2 * r.with(5).randi_range(0, 3))
			_structures.add(Structure.rock, height_source.pos_at(pos), PI/2 * r.with(5).randi_range(0, 3))

class Village extends Area:
	func calc_height() -> float:
		return rid.randi_range(6, 12)
	func fill(height_source: HeightSource) -> void:
		var available_positions: Array[Vector2] = [Vector2(0, 0), Vector2(-20, -20), Vector2(20, -20), Vector2(-20, 20), Vector2(20, 20), Vector2(25, 0), Vector2(0, 25), Vector2(-25, 0), Vector2(0, -25)]
		for i: int in rid.with(-4).randi_range(2, 6):
			var r: Hasher = rid.with(i)
			var pos: Vector2 = global_pos + available_positions.pop_at(r.with(3).randi() % available_positions.size()) + Vector2(r.with(9).randi_range(-3, 3) , r.with(5).randi_range(-3, 3))
			_structures.add(Structure.house, height_source.pos_at(pos), PI / 4 * r.with(13).randi_range(0, 7))
	func center_size() -> float:
		return 0.5
