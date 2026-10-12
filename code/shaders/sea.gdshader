shader_type spatial;
render_mode world_vertex_coords, diffuse_lambert, specular_schlick_ggx;

//#include "fastnoiselite.gdshaderinc"
#include "ashima_simplex3.gdshaderinc"

uniform vec3 base_color: source_color;
uniform sampler2D normal_map: repeat_enable;
uniform sampler2D depth_texture: hint_depth_texture;
uniform int wave_noise_seed = 536;

varying vec3 vert;
varying float camera_distance;

float detail_for(vec2 pos) {
	return clamp(1.0-max(length(dFdx(pos)), length(dFdy(pos))), 0.0, 1.0);
}

float noise_octave(vec3 pos) {
	return snoise(pos) * detail_for(pos.xy);
}

float height_at(vec2 pos) {
	return 0.2 * (
		noise_octave(vec3(pos*0.12, TIME/4.0))/2.0
		+ noise_octave(vec3(pos*0.3, TIME/4.0))/4.0
		+ noise_octave(vec3(pos*0.8, TIME/4.0))/8.0
		+ noise_octave(vec3(pos*1.8, TIME/3.0))/16.0
		+ noise_octave(vec3(pos*4.0, TIME/2.0))/32.0
	);
	
	//fnl_state noise = fnlCreateState(wave_noise_seed);
	//noise.octaves = 3;//int(ceil(detail * 5.0));
	//noise.frequency = 0.4;
	//return 0.1 * fnlGetNoise3D(noise, pos.x, pos.y, TIME/2.0);
	
	//return 1.0 * sin(pos.x/2.0) * sin(pos.y/2.0);
}

void vertex() {
	vert = VERTEX;
	camera_distance = distance(VERTEX, CAMERA_POSITION_WORLD);
	//VERTEX.y = height_at(VERTEX.xz);
}


void fragment() {
	float fres = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	//NORMAL_MAP =
		//texture(normal_map, vec2(vert.x, vert.z) / 16.0 + TIME*vec2(0.01, 0.005)).xyz * 0.5 +
		//texture(normal_map, vec2(vert.x, vert.z) / 16.0 + TIME*vec2(0.015, -0.0051)).xyz * 0.5;
	//);
	float dxy = 0.01;
	float f = 0.1;
	//float detail = clamp(1.0-max(length(dFdx(vert.xz*f)), length(dFdy(vert.xz*f))), 0.0, 1.0);
	float height = height_at(vert.xz);
	vec3 normal = -normalize(vec3(
		(height_at(vert.xz+vec2(dxy, 0))-height) / dxy,
		(height_at(vert.xz+vec2(0, dxy))-height) / dxy,
		1.0
	));
	//NORMAL = (VIEW_MATRIX * vec4(-normal, 1.0)).xyz;
	NORMAL_MAP = normal * 0.5 + 0.5;
	
	float depth = texture(depth_texture, SCREEN_UV).x;
	#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
	#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	#endif
	vec4 world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vec3 world_position = world.xyz / world.w;
	float water_depth = -world_position.y;
	
	ALBEDO = base_color;// * (1.0-fres);
	ALPHA = 1.0-0.4/(water_depth*water_depth*fres*2.0 + 1.0);//mix(1.0, 0.75, fres);
	ROUGHNESS = 0.2;//mix(0.1, 0.4, fres);
	METALLIC = 0.0;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
