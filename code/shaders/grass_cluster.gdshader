shader_type spatial;
render_mode depth_draw_opaque, cull_disabled, diffuse_lambert, specular_disabled, world_vertex_coords;

uniform vec3 top_color: source_color;
uniform vec3 base_color: source_color;
uniform float cull_min_distance = 32.0;
uniform float cull_max_distance = 64.0;

float easeOut(float x, float t) {
	return 1.0 - pow(1.0 - x, t);
}

//vec3 thicken(vec3 vert) {
	//vec3 viewDir = normalize(CAMERA_POSITION_WORLD - VERTEX);
	//vec3 viewDirXZ = normalize(vec3(viewDir.x, 0.0, viewDir.z));
	//vec3 grassFaceNormalXZ = normalize(vec3(NORMAL.x, 0.0, NORMAL.z));
	//float viewDotNormal = clamp(dot(NORMAL, viewDirXZ), 0.0, 1.0);
	//float viewSpaceThickenFactor = easeOut(1.0 - viewDotNormal, 4.0) * smoothstep(0.0, 0.2, viewDotNormal);
	//vec4 mvPosition = VIEW_MATRIX * vec4(VERTEX, 1.0);
	//mvPosition.x -= viewSpaceThickenFactor * (UV.x - 0.5) * 0.5;
	//return (INV_VIEW_MATRIX * mvPosition).xyz;
//}

void vertex() {
	float dist = distance(NODE_POSITION_WORLD, CAMERA_POSITION_WORLD);
	float hash = fract(sin(dot(NODE_POSITION_WORLD.xz, vec2(12.9898, 78.233))) * 43758.5453);
	float keep_probability = (dist-cull_max_distance) / (cull_min_distance - cull_max_distance);
	float lh = (keep_probability*abs(keep_probability) - hash) * 4.0;
	if (lh < 0.0) {
		VERTEX = vec3(0.0);
	} else if (lh < 1.0) {
		VERTEX.y += lh-1.0;
	} else {
		//VERTEX = thicken(VERTEX);
		//vec3 view_position = (VIEW_MATRIX * vec4(VERTEX, 1)).xyz;
		//view_position.x += UV.x - 0.5;
		//VERTEX = (INV_VIEW_MATRIX * vec4(view_position, 1)).xyz;
	}
}

void fragment() {
	//if (!FRONT_FACING) {
		//NORMAL = -NORMAL;
	//}
	NORMAL = normalize(mix(NORMAL, (VIEW_MATRIX * vec4(0, 1, 0, 0)).xyz, clamp(UV.y*2.0, 0.7, 0.9)));
	//NORMAL = (VIEW_MATRIX * vec4(0, 1, 0, 0)).xyz;
	ALBEDO = mix(base_color, top_color, UV.y) * COLOR.g;
}
