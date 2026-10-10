shader_type spatial;
render_mode world_vertex_coords, diffuse_lambert, specular_schlick_ggx, cull_disabled;

uniform vec3 base_color: source_color;
uniform sampler2D normal_map: repeat_enable;

varying vec3 vert;

void vertex() {
	// Called for every vertex the material is visible on.
	vert = VERTEX;
}

float height_at(vec2 pos) {
	return sin(pos.x) + sin(pos.y);
}

void fragment() {
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.0);
	ALBEDO = base_color;// * (1.0-fres);
	NORMAL_MAP =
		texture(normal_map, vec2(vert.x, vert.z) / 16.0 + TIME*vec2(0.01, 0.005)).xyz * 0.5 +
		texture(normal_map, vec2(vert.x, vert.z) / 16.0 + TIME*vec2(0.015, -0.0051)).xyz * 0.5;
	//);
	//float height = height_at(vert.xz);
	//NORMAL_MAP = -normalize(cross(
		//vec3(0.1, height_at(vert.xz+vec2(0.1, 0))-height, 0),
		//vec3(0, height_at(vert.xz+vec2(0, 0.1))-height, 0.1)
	//));
	
	ALPHA = 0.9;//mix(1.0, 0.75, fres);
	ROUGHNESS = mix(0.1, 0.4, fres);
	METALLIC = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
