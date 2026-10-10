shader_type texture_blit;

#include "fastnoiselite.gdshaderinc"

uniform vec3 area_pos;
uniform vec3 area_size;
uniform int area_segments;
uniform vec2 step_size;
uniform vec4[2304] hexes;
uniform int hexes_x;
uniform ivec2 lowest_hex;
uniform float hex_rad;
uniform sampler2D height_gradient : repeat_disable;
uniform float absolute_minimum;
uniform float height_resolution;

const float SQRT3 = 1.7320508075688772;


vec2 world_to_hex(vec2 world) {
	vec2 vs = world / hex_rad;
	return vec2(vs.x - 1.0/SQRT3*vs.y, 2.0/SQRT3*vs.y);
}

vec4 get_hex(ivec2 hex_id) {
	ivec2 ind2 = hex_id - lowest_hex;
	if (ind2.x < 0 || ind2.y < 0 || ind2.x >= hexes_x ||ind2.y >= hexes_x) {
		return vec4(-150.0, 0.0, 0.0, 0.0);
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

float height_at(vec2 pos) {
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
	float n = clamp((1.0-max(w.x, max(w.y, w.z))) * 5.0, 0.0, 1.0);
	fnl_state noise = fnlCreateState(5346);
	noise.octaves = 4;
	noise.frequency = 0.02;
	//noise.noise_type = FNL_NOISE_OPENSIMPLEX2S;
	return hex_height(hex_a) * w.x + hex_height(hex_b) * w.y + hex_height(hex_c) * w.z + fnlGetNoise2D(noise, pos.x, pos.y) * n * 5.0;
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

void blit() {
	vec2 pos = (FRAGCOORD.xy - vec2(0.5)) * step_size + area_pos.xz;
	float height = height_at(pos);
	COLOR0 = vec4(encode_height(height), 1);
	vec3 normal = -normalize(cross(
		vec3(0.1, height_at(pos+vec2(0.1, 0))-height, 0),
		vec3(0, height_at(pos+vec2(0, 0.1))-height, 0.1)
	));
	COLOR1 = vec4(normal/2.0+vec3(0.5), 1);
	COLOR2 = vec4(texture(height_gradient, vec2(height/100.0+0.5, 0)).xyz, 1);
	//COLOR2 = vec4(0, height/100.0+0.5, 0, 1);
}
