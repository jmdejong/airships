@tool
class_name HexsHeightSource
extends HeightSource
var noise: FastNoiseLite = FastNoiseLite.new()
var color_noise: FastNoiseLite = FastNoiseLite.new()
var areas: Dictionary[Vector2i, Area] = {}
@export var hexes_to_shore: int = 12
@export var hex_diameter: float = 192
@export var random_seed = 3851644
@export var center_height: int = 10
var height_source_material: ShaderMaterial = _default_height_source_material()
@export var height_gradient: GradientTexture1D
@export var height_gradient2: GradientTexture1D
var height_scale: float = 128
var height_min: float = -32
var hasher: Hasher
var absolute_minimum: float = -1024
var height_min_step: float = 0.125
var height_channel_resolution = (height_min_step * 256.0)
var red_scale: float = 255.0/height_channel_resolution
var green_scale: float = 255.0*256.0/height_channel_resolution
var blue_scale: float = 0

@export var base_terrain_material: ShaderMaterial

static func _default_height_source_material() -> ShaderMaterial:
	var mat: ShaderMaterial = ShaderMaterial.new()
	mat.shader = preload("res://code/shaders/hexs_height.gdshader")
	return mat

func _init() -> void:
	hasher = Hasher.new(random_seed)
	noise.fractal_octaves = 4
	noise.seed = hasher.with(3).randi()
	noise.frequency = 0.02
	#noise.noise_type = FastNoiseLite.NoiseType.TYPE_SIMPLEX_SMOOTH
	var arw: int = hexes_to_shore+2
	for z: int in range(-arw, arw+1):
		for x: int in range(max(-arw, -z-arw), min(arw, arw-z)+1):
			var v: Vector2i = Vector2i(x, z)
			var rh: Hasher = hasher.with(321).with_vec2(v)
			var center_distance = (abs(x) + abs(x+z) + abs(z))/2
			var area: Area = Sea.new()
			if v == Vector2i.ZERO:
				area = StartArea.new()
			elif v == Vector2i(1, -1):
				area = Hangar.new()
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
			area.setup(hasher, v, hex_to_pix(v), hex_diameter/2)
			areas[v] = area
	
	color_noise.seed = hasher.with(44).randi()
	color_noise.frequency = 0.05
	_handle_hexes()

func _handle_hexes() -> void:
	var hexes_x: int = 48
	var lowest_hex: Vector2i = Vector2i(-hexes_x/2, -hexes_x/2)
	height_source_material.set_shader_parameter("hexes_x", hexes_x)
	height_source_material.set_shader_parameter("lowest_hex", lowest_hex)
	var hexes_vecs: PackedVector4Array = PackedVector4Array()
	hexes_vecs.resize(hexes_x * hexes_x)
	for y in hexes_x:
		for x in hexes_x:
			var ind: int = y * hexes_x + x
			var area_id = Vector2i(x, y) + lowest_hex
			var area: Area = get_area(area_id)
			hexes_vecs[ind] = Vector4(area.height, area.center_size(), area.bumpiness(), 0)
	height_source_material.set_shader_parameter("hexes", hexes_vecs)
	height_source_material.set_shader_parameter("hex_diameter", hex_diameter)


func buffers_at(area: Rect2, segments: int) -> TileBuffers:
	var step: Vector2 = area.size / segments
	var height_img: Image = height_image_at(area, segments + 1).height
	height_img.convert(Image.Format.FORMAT_RH)
	#var height_data: PackedFloat16Array = height_img.get_data().
	#var normal_img: Image = normal_texture.get_image()
	#normal_img.convert(Image.Format.FORMAT_RGB8)
	const texture_size: float = 8
	var buf: TileBuffers = TileBuffers.new(area, segments)
	var size: Vector2i = buf.size
	for y in size.y:
		for x in size.x:
			var ind: int = x + y*size.x
			var tile: Vector2 = Vector2(x, y)
			var pos: Vector2 = buf.tile_to_pos * tile
			var height: float = height_img.get_pixel(x, y).r * height_scale + height_min
			var position: Vector3 = Vector3(pos.x, height, pos.y)
			buf.heights[ind] = position.y
			buf.positions[ind] = position
			buf.colors[ind] = color_modifier(pos)
			buf.tex_uvs[ind] = pos / texture_size
			buf.normals[ind] = -Vector3(step.x, height_img.get_pixel(x+1, y).r * height_scale + height_min - height, 0) \
				.cross(Vector3(0, height_img.get_pixel(x, y+1).r * height_scale + height_min - height, step.y)) \
				.normalized()
	return buf

func height_image_at(area: Rect2, segments: int) -> ImageBuffers:
	var step: Vector2 = area.size / segments
	var area3 = AABB(Vector3(area.position.x, height_min, area.position.y),Vector3(area.size.x, height_scale, area.size.y))
	var resolution: int = segments + 1
	var height_texture: DrawableTexture2D = DrawableTexture2D.new()
	height_texture.setup(resolution, resolution, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8)
	var normal_texture: DrawableTexture2D = DrawableTexture2D.new()
	normal_texture.setup(resolution, resolution, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8)
	var color_texture: DrawableTexture2D = DrawableTexture2D.new()
	color_texture.setup(resolution, resolution, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8)
	var detail_texture: DrawableTexture2D = DrawableTexture2D.new()
	detail_texture.setup(resolution, resolution, DrawableTexture2D.DrawableFormat.DRAWABLE_FORMAT_RGBA8)
	height_source_material.set_shader_parameter("area_pos", area3.position)
	height_source_material.set_shader_parameter("area_size", area3.size)
	height_source_material.set_shader_parameter("area_segments", segments)
	height_source_material.set_shader_parameter("step_size", step)
	height_source_material.set_shader_parameter("height_gradient", ImageTexture.create_from_image(height_gradient.get_image()))
	height_source_material.set_shader_parameter("height_gradient2", ImageTexture.create_from_image(height_gradient2.get_image()))
	height_source_material.set_shader_parameter("absolute_minimum", absolute_minimum)
	height_source_material.set_shader_parameter("height_resolution", height_channel_resolution)
	height_source_material.set_shader_parameter("noise_between_seed", noise.seed)
	height_texture.blit_rect_multi(
		Rect2i(Vector2i.ZERO, Vector2i.ONE * resolution),
		[preload("res://icon.svg")],
		[normal_texture, color_texture, detail_texture],
		Color.BLACK,
		0,
		height_source_material
	)
	var image_buffers: ImageBuffers = ImageBuffers.new()
	image_buffers.height = height_texture.get_image()
	image_buffers.normal = normal_texture.get_image()
	image_buffers.color = color_texture.get_image()
	image_buffers.detail = detail_texture.get_image()
	#image_buffers.detail.save_png("user://detail_"+str(area)+".png")
	image_buffers.area = area3
	image_buffers.segments = segments
	image_buffers.absolute_minimum = absolute_minimum
	image_buffers.red_scale = red_scale
	image_buffers.green_scale = green_scale
	image_buffers.blue_scale = blue_scale
	image_buffers.base_material = base_terrain_material
	return image_buffers

func base_material() -> ShaderMaterial:
	return base_terrain_material.duplicate()

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
	var bumps: float = (area_a.bumpiness() * w.x + area_b.bumpiness() * w.y + area_c.bumpiness() * w.z) * noise.get_noise_2d(pos.x, pos.y) * n * 5.0
	return float(area_a.height) * w.x + float(area_b.height) * w.y + float(area_c.height) * w.z + bumps


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
	for hex: Vector2i in hexes_in(region.grow(hex_diameter)):
		var area: Area = get_area(hex)
		strucs.add_buffer(area.structures().filter_region(region))
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
		areas[vid].setup(hasher, vid, hex_to_pix(vid), hex_diameter)
	return areas[vid]

const SQRT3: float = sqrt(3)
#const SQRT3_INV: float = 1.0/SQRT3

func pix_to_hex_z(pix_z: float) -> float:
	return 2.0/SQRT3 * pix_z/hex_diameter

func pix_to_hex_x(pix: Vector2) -> float:
	var vs: Vector2 = pix/hex_diameter
	return vs.x - 1/SQRT3*vs.y

func pix_to_hex(pix: Vector2) -> Vector2:
	var vs: Vector2 = pix/hex_diameter
	return Vector2(vs.x - 1/SQRT3*vs.y, 2/SQRT3*vs.y)

func pix_to_hex_i(pix: Vector2i) -> Vector2i:
	return hex_round(pix_to_hex(pix))

func hex_to_pix(hex: Vector2i) -> Vector2:
	return Vector2(hex.x + 0.5 * hex.y, SQRT3/2.0 * hex.y) * hex_diameter

func hex_to_pix_z(hex_z: float) -> float:
	return SQRT3/2.0 * hex_z * hex_diameter

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
	func structures() -> Structure.Buffer:
		if _structures == null:
			_structures = Structure.Buffer.new()
			fill()
		return _structures
	@abstract
	func calc_height() -> float
	func fill() -> void:
		return
	func center_size() -> float:
		return 0
	func bumpiness() -> float:
		return 1

	func area_cells(cell_diameter: float, displacement: float=0, fill_chance: float=1, extend: float=0) -> PackedVector2Array:
		var cells := PackedVector2Array()
		var cell_radius: float = cell_diameter / SQRT3
		var n: int = floori((area_radius + extend) / cell_radius * 2.0 / 3.0)
		for q: int in range(-n, n+1):
			for r: int in range(max(-n, -q-n),  min(n, -q+n)+1):
				#results.append(axial_add(center, Hex(q, r)))
				var p := Vector2(q * 3.0/2.0, SQRT3/2.0 * q + SQRT3 * r) * cell_radius
				var rl: Hasher = rid.with(q * n * 3 + r)
				if rl.randf() > fill_chance:
					continue
				#if absf(p.x) <= rad and absf(p.x) + SQRT3 * absf(p.y) <= 2.0 * rad:
				var offset_dir: float = rl.with(64309).randf() * TAU
				var offset_radius: float = sqrt(rl.with(48291).randf()) * displacement*cell_diameter/2.0
				var offset := offset_radius * Vector2(sin(offset_dir), cos(offset_dir))
				cells.append(offset + p + global_pos)
		return cells

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
	func fill() -> void:
		for pos: Vector2 in area_cells(9, 1, 0.25, -16):
			_structures.add(Structure.bush, pos, 0)

class Forest extends Area:
	func calc_height() -> float:
		return rid.randi_range(6, 12)
	func fill() -> void:
		@warning_ignore("narrowing_conversion")
		var m: int = area_radius * 0.9
		for i in range(rid.with(349).randi_range(30, 100)):
			var r: Hasher = rid.with(i)
			#var tree: Node3D = Structure.tree.scene.instantiate()# if r.with(-83).randf() < 0.5 else Structure.small_tree.scene.instantiate()
			var pos: Vector2 = global_pos + Vector2(r.with(910).randi_range(-m, m), r.with(915).randi_range(-m, m))
			if pos.distance_to(global_pos) > m:
				continue
			#tree.position = Vector3(pos.x, 0, pos.y)
			_structures.add(Structure.tree, pos, 0)
		for i in range(rid.with(383).randi_range(10, 40)):
			var r: Hasher = rid.with(i).with(3578)
			#var tree: Node3D = Structure.tree.scene.instantiate()# if r.with(-83).randf() < 0.5 else Structure.small_tree.scene.instantiate()
			var pos: Vector2 = global_pos + Vector2(r.with(910).randi_range(-m, m), r.with(915).randi_range(-m, m))
			if pos.distance_to(global_pos) > m:
				continue
			#tree.position = Vector3(pos.x, 0, pos.y)
			_structures.add(Structure.small_tree, pos, 0)
		for i in range(rid.with(387).randi_range(10, 40)):
			var r: Hasher = rid.with(i).with(4892)
			var pos: Vector2 = global_pos + Vector2(r.with(910).randi_range(-m, m), r.with(915).randi_range(-m, m))
			if pos.distance_to(global_pos) > m:
				continue
			_structures.add(Structure.bush, pos, 0)
	func center_size() -> float:
		return 0.2
	func bumpiness() -> float:
		return 0.5

class Hill extends Area:
	func calc_height() -> float:
		return rid.randi_range(20, 80)
	func fill() -> void:
		@warning_ignore("narrowing_conversion")
		var m: int = area_radius*0.66
		for i in rid.with(-3).randi_range(0, 5):
			var r: Hasher = rid.with(i)
			#var rock: Node3D = Structure.rock.scene.instantiate()
			var pos: Vector2 = global_pos + Vector2(r.with(910).randi_range(-m, m), r.with(915).randi_range(-m, m))
			#rock.position = Vector3(pos.x, 0, pos.y)
			#rock.rotate_y(PI/2 * r.with(5).randi_range(0, 3))
			_structures.add(Structure.rock, pos, PI/2 * r.with(5).randi_range(0, 3))
	func bumpiness() -> float:
		return 2.0

class Village extends Area:
	func calc_height() -> float:
		return rid.randi_range(6, 12)
	func fill() -> void:
		var available_positions: Array[Vector2] = [Vector2(0, 0), Vector2(-20, -20), Vector2(20, -20), Vector2(-20, 20), Vector2(20, 20), Vector2(25, 0), Vector2(0, 25), Vector2(-25, 0), Vector2(0, -25)]
		for i: int in rid.with(-4).randi_range(2, 6):
			var r: Hasher = rid.with(i)
			var pos: Vector2 = global_pos + available_positions.pop_at(r.with(3).randi() % available_positions.size()) + Vector2(r.with(9).randi_range(-3, 3) , r.with(5).randi_range(-3, 3))
			_structures.add(Structure.house, pos, PI / 4 * r.with(13).randi_range(0, 7))
	func center_size() -> float:
		return 0.5

class Hangar extends Area:
	func calc_height() -> float:
		return rid.randi_range(6, 12)
	func fill() -> void:
		_structures.add(Structure.hangar, global_pos + Vector2(0, -0), PI/2)
		_structures.add(Structure.mooring_mast, global_pos + Vector2(-40, 50),0)
		_structures.add(Structure.mooring_mast, global_pos + Vector2(40, -50),0)
	func center_size() -> float:
		return 0.6
	func bumpiness() -> float:
		return 0

#func fill_random(area: Area, structures: Dictionary[Structure, float], grid_step_size: float, extend: float=0, fill_chance: float=1, displacement: float=1) -> Structure.Buffer:
	##var rad: float = hex_diameter / 2.0 + extend
	##var srad: int = floor(rad / grid_step_size)
	##for sx: int in range(srad, srad + 1):
		##var rx: float = sx * grid_step_size
		##var sh: int = floor(rx
		##for sy: int in range(
	#return Structure.Buffer.new()

#func area_cells(area: Area, cell_diameter: float, extend: float=0) -> PackedVector2Array:
	#var rad: float = area.area_radius / 2.0 + extend
	#var cells := PackedVector2Array()
	#var limit := int(ceil(2.0 * rad / cell_diameter)) + 1
#
	#for q in range(-limit, limit + 1):
		#for r in range(-limit, limit + 1):
			#var p := Vector2(
				#1.5 * cell_diameter * q,
				#sqrt(3.0) * cell_diameter * (r + 0.5 * q)
			#)
			#if absf(p.x) <= rad and absf(p.x) + sqrt(3.0) * absf(p.y) <= 2.0 * rad:
				#cells.append(p)
	#return cells
