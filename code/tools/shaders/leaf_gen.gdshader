shader_type texture_blit;

uniform uint leaf_count = 128u;
uniform float edge_brighness = 0.5;
uniform float edge_width = 0.5;
uniform float brightness_veriation = 0.2;
uniform float leaf_radius = 0.09;
uniform uint seed = 0;


uint hash(uint h) {
	// from https://github.com/jwerle/murmurhash.c/blob/10ba9c25abbcf8952b5f4abecf9bf4fc148e8e65/murmurhash.c#L85-L89
	h ^= (h >> 16u);
	h *= 0x85ebca6bu;
	h ^= (h >> 13u);
	h *= 0xc2b2ae35u;
	h ^= (h >> 16u);
	return h;
}

float hash_to_f(uint h) {
	return float(hash(h))/4294967296.0;
}


void blit() {
	vec2 p = UV.xy;
	uint leaf_index = leaf_count + 1u;
	uint h;
	float leaf_center_distance = 0.0;
	for (uint i=0u; i<leaf_count; ++i) {
		h = i + seed;
		float dist = hash_to_f(h);
		float dir = hash_to_f(h+1000u) * 2.0 * PI;
		vec2 leaf_pos = vec2(sin(dir), cos(dir)) * (dist - 2.0 * leaf_radius) / 2.0 + vec2(0.5, 0.5);
		float rad = leaf_radius * (0.8 + 0.4 * hash_to_f(h+3000u));
		leaf_center_distance = distance(p, leaf_pos) / rad;
		if (leaf_center_distance < 1.0) {
			leaf_index = i;
			break;
		}
	}
	if (leaf_index < leaf_count) {
		float edge_factor = mix(edge_brighness, 1.0, clamp((1.0-leaf_center_distance) / edge_width, 0.0, 1.0));
		float brightness = (1.0 + brightness_veriation * (hash_to_f(h+2000u)* 2.0 - 1.0)) * edge_factor;
		COLOR0 = vec4(brightness, brightness, brightness, 1.0);
	} else {
		COLOR0 = vec4(0, 0, 0, 0);
	}
}
