shader_type spatial;
render_mode world_vertex_coords, specular_disabled, diffuse_lambert;

uniform sampler2D height_tex;
uniform sampler2D normal_tex;
uniform sampler2D color_tex : source_color;
uniform vec3 position;
uniform vec3 size;
uniform int subtiles;
uniform sampler2D ground_texture : source_color, filter_linear_mipmap;
uniform float texture_size = 2;

varying vec3 world_position;
varying vec2 uv;
uniform float absolute_minimum;
uniform float red_scale;
uniform float green_scale;
uniform float blue_scale;

float decode_height(vec3 encoded) {
	//return encoded.g * green_scale;
	return absolute_minimum + encoded.r * red_scale + encoded.g * green_scale + encoded.b * blue_scale;
}

void vertex() {
	vec2 tile_size = size.xz / float(subtiles);
	uv = (VERTEX.xz - position.xz + tile_size / 2.0) / (size.xz + tile_size);
	VERTEX.y = decode_height(texture(height_tex, uv).rgb);// * size.y + position.y;
	NORMAL = texture(normal_tex, uv).xyz * 2.0 - vec3(1.0);
	world_position = VERTEX;
	COLOR = texture(color_tex, uv);
}

void fragment() {
	vec2 tex_uv = world_position.xz / texture_size;
	ALBEDO = texture(ground_texture, tex_uv).xyz * COLOR.xyz;
	//float seam_distance = min(min(uv.x, uv.y), min(1.0-uv.x, 1.0-uv.y));
	//float seam_marking = seam_distance > 0.002 ? 0.0 : 0.5;
	//ALBEDO = vec3(seam_marking, world_position.y / 100.0, 0);
}