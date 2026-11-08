@tool
extends MeshInstance3D

@export var leaf_draw_material: ShaderMaterial
@export var resolution: int = 128
@export var filename: String = "leaves.png"

@export_tool_button("generate") var generate_action: Callable = generate

func generate() -> Texture2D:
	var texture: DrawableTexture2D = DrawableTexture2D.new()
	texture.setup(resolution, resolution, DrawableTexture2D.DRAWABLE_FORMAT_RGBA8)
	texture.blit_rect(Rect2i(0, 0, resolution, resolution), preload("res://icon.svg"), Color.BLACK, 0, leaf_draw_material)
	get_surface_override_material(0).albedo_texture = texture
	var image: Image = texture.get_image()
	var file_path: String = "res://textures/generated/" + filename
	image.save_png(file_path)
	var img_tex: Texture2D = ResourceLoader.load(file_path, "", ResourceLoader.CACHE_MODE_REPLACE)
	#var img_tex := ImageTexture.create_from_image(image)
	print("img", img_tex)
	return img_tex
