// NOTE: Shader automatically converted from Godot Engine 4.7.2.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_disable;
uniform sampler2D albedo_gradient : source_color, filter_linear_mipmap, repeat_enable;
uniform float canopy_height_variation = 1.0;


varying vec3 albedo_position_tint;


float hash_position(vec3 p) {
    return fract(sin(dot(p, vec3(12.9898, 78.233, 37.719))) * 43758.5453);
}


void vertex() {
	albedo_position_tint = texture(albedo_gradient, vec2(hash_position(MODEL_MATRIX[3].xyz), 0)).rgb;
	VERTEX.y += canopy_height_variation * (hash_position(MODEL_MATRIX[3].xyz + vec3(12307.1, 3301.7, 11346.3)) * 2.0 - 1.0);
}

void fragment() {
	
	vec4 albedo_tex = texture(texture_albedo, UV);
	if (albedo_tex.a < 0.5) {
		discard;
	}
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = albedo_position_tint.rgb * albedo_tex.rgb;
}
