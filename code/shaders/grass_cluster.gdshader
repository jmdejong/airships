shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;

uniform vec3 top_color: source_color;
uniform vec3 base_color: source_color;
uniform float cull_min_distance = 32.0;
uniform float cull_max_distance = 64.0;

void vertex() {
	float dist = distance(NODE_POSITION_WORLD, CAMERA_POSITION_WORLD);
	float hash = fract(sin(dot(NODE_POSITION_WORLD.xz, vec2(12.9898, 78.233))) * 43758.5453);
	float keep_probability = (dist-cull_max_distance) / (cull_min_distance - cull_max_distance);
	float lh = (keep_probability*abs(keep_probability) - hash) * 8.0;
	if (lh < 0.0) {
		VERTEX = vec3(0.0);
	} else if (lh < 1.0) {
		VERTEX.y += lh-1.0;
	} 
}

void fragment() {
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = mix(base_color, top_color, UV.y) * COLOR.g;
}
