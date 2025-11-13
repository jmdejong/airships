shader_type spatial;
render_mode world_vertex_coords, specular_disabled, diffuse_lambert;

uniform sampler2D ground_texture : source_color, filter_linear_mipmap;
uniform float texture_size;

varying vec3 vert;

void vertex() {
	vert = VERTEX;
}

void fragment() {
	vec2 uv = fract(vert.xz / texture_size);
	ALBEDO = texture(ground_texture, uv).xyz * COLOR.xyz;
}
