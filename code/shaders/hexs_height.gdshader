shader_type texture_blit;

#include "fastnoiselite.gdshaderinc"

uniform vec3 area_pos;
uniform vec3 area_size;
uniform int area_segments;
uniform vec2 step_size;
uniform vec4[2304] hexes;
uniform int hexes_x;
uniform ivec2 lowest_hex;
uniform float hex_diameter;
uniform sampler2D height_gradient : repeat_disable;
uniform sampler2D height_gradient2 : repeat_disable;
uniform float absolute_minimum;
uniform float height_resolution;
uniform int noise_between_seed;

const float SQRT3 = 1.7320508075688772;


vec2 world_to_hex(vec2 world) {
	vec2 vs = world / hex_diameter;
	return vec2(vs.x - 1.0/SQRT3*vs.y, 2.0/SQRT3*vs.y);
}

vec4 get_hex(ivec2 hex_id) {
	ivec2 ind2 = hex_id - lowest_hex;
	if (ind2.x < 0 || ind2.y < 0 || ind2.x >= hexes_x ||ind2.y >= hexes_x) {
		return vec4(-250.0, 0.0, 0.0, 0.0);
	} else {
		return hexes[ind2.y * hexes_x + ind2.x];
	}
}

vec3 influences(vec3 w, float center_size) {
	w -= vec3(center_size/3.0);
	w += vec3(min(min(w.x, w.y), min(w.z, 0.0)))/2.0;
	w = clamp(w, 0.0, 1.0);
	w = w * w;
	w /= w.x + w.y + w.z;
	return w;
}

float hex_center_size(vec4 hex) {
	return hex.y;
}

float hex_height(vec4 hex) {
	return hex.x;
}

struct RelevantHexes {
	vec4 hex_a;
	vec4 hex_b;
	vec4 hex_c;
	vec3 weights;
};

RelevantHexes relevant_hexes(vec2 pos) {
	vec2 vf = world_to_hex(pos);
	vec2 vfloor = floor(vf);
	vec2 vfrac = vf - vfloor;
	ivec2 va = ivec2(vfloor);
	ivec2 vb = ivec2(vfloor) + ivec2(0, 1);
	ivec2 vc = ivec2(vfloor) + ivec2(1, 0);
	vec3 w;
	if (vfrac.x + vfrac.y <= 1.0) {
		w = vec3(1.0-vfrac.x-vfrac.y, vfrac.y, vfrac.x);
	} else {
		va += ivec2(1);
		w = vec3(vfrac.x+vfrac.y-1.0, 1.0-vfrac.x, 1.0-vfrac.y);
	}
	vec4 hex_a = get_hex(va);
	vec4 hex_b = get_hex(vb);
	vec4 hex_c = get_hex(vc);
	vec3 center_influences = influences(w, 0.8);
	w = influences(w, center_influences.x * hex_center_size(hex_a) + center_influences.y * hex_center_size(hex_b) + center_influences.z * hex_center_size(hex_c));
	return RelevantHexes(hex_a, hex_b, hex_c, w);
}

float height(vec2 pos, vec4 hex_avg, vec3 w) {
	//vec3 w = h.weights;
	float n = clamp((1.0-max(w.x, max(w.y, w.z))) * 5.0, 0.0, 1.0);
	fnl_state noise_between = fnlCreateState(noise_between_seed);
	noise_between.octaves = 4;
	noise_between.frequency = 0.02;
	//noise.noise_type = FNL_NOISE_OPENSIMPLEX2S;
	float bumps = hex_avg.z * fnlGetNoise2D(noise_between, pos.x, pos.y) * n * 5.0;
	return hex_height(hex_avg) + bumps;
}

vec3 encode_height(float height) {
	int h = int(floor((height - absolute_minimum) * height_resolution));
	return vec3(
		float(h%256) / 255.0,
		float((h/256)%256) / 255.0,
		0
		//float((h/256/256)%256) / 255.0
	);
}

vec3 terrain_color(vec2 pos, float height) {
	vec3 t1 = texture(height_gradient, vec2(height/200.0+0.5, 0)).xyz;
	vec3 t2 = texture(height_gradient2, vec2(height/200.0+0.5, 0)).xyz;
	fnl_state noise_color_patch = fnlCreateState(noise_between_seed^9403);
	noise_color_patch.octaves = 4;
	noise_color_patch.frequency = 0.05;
	float h = clamp(fnlGetNoise2D(noise_color_patch, pos.x, pos.y)/2.0 + 0.5, 0.0, 1.0);
	return mix(t1, t2, h) * (1.0 + 0.0625*fnlGetNoise2D(noise_color_patch, 19324.0-pos.x, 38748.0-pos.y));
}

float grass_density(vec2 pos, float height, vec3 normal) {
	fnl_state noise = fnlCreateState(noise_between_seed^9403);
	noise.octaves = 2;
	noise.frequency = 0.02;
	float noise_effect = pow(fnlGetNoise2D(noise, pos.x, pos.y), 2.0);
	float height_effect = min((height-1.0)/3.0, pow((32.0-height)/8.0, 3.0));
	return clamp(height_effect * noise_effect * normal.y, 0.0, 1.0);
}

float height_at(vec2 pos) {
	RelevantHexes h = relevant_hexes(pos);
	vec4 hex_avg = h.hex_a * h.weights.x + h.hex_b * h.weights.y + h.hex_c * h.weights.z;
	return height(pos, hex_avg, h.weights);
}

void blit() {
	vec2 pos = (FRAGCOORD.xy - vec2(0.5)) * step_size + area_pos.xz;
	RelevantHexes h = relevant_hexes(pos);
	vec4 hex_avg = h.hex_a * h.weights.x + h.hex_b * h.weights.y + h.hex_c * h.weights.z;
	float height = height(pos, hex_avg, h.weights);
	vec3 pos3 = vec3(pos.x, height, pos.y);
	COLOR0 = vec4(encode_height(height), 1);
	
	vec3 normal = -normalize(cross(
		vec3(0.1, height_at(pos+vec2(0.1, 0))-height, 0),
		vec3(0, height_at(pos+vec2(0, 0.1))-height, 0.1)
	));
	COLOR1 = vec4(normal/2.0+vec3(0.5), 1);
	COLOR2 = vec4(terrain_color(pos, height), 1);
	COLOR3 = vec4(grass_density(pos, height, normal), 0, 0, 1);
	//COLOR2 = vec4(0, height/100.0+0.5, 0, 1);
}
