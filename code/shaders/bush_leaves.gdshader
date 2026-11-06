shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled;

uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_disable;


void fragment() {
	
	vec4 albedo_tex = texture(texture_albedo, UV);
	if (albedo_tex.a < 0.5) {
		discard;
	}
	if (!FRONT_FACING) {
		NORMAL = -NORMAL;
	}
	ALBEDO = albedo_tex.rgb;
}
