shader_type spatial;
render_mode unshaded, depth_draw_never, world_vertex_coords;

uniform sampler2D bg_gradient : source_color;
uniform vec3 sun_color : source_color;
uniform vec3 sun;
const float sun_size = 0.999962; // cos(0.0087 rad) (angular diameter of of the sun as seen from earth)
const float sun_angle_max = 0.877;
const float inv_sun_curve = 50.0;

varying vec3 cam_dir;

void vertex() {
	cam_dir = VERTEX - CAMERA_POSITION_WORLD;
}

void fragment() {
	//ALBEDO = cam_dir.y > 0.0 ? vec3(1, 1, 1) : vec3(0, 0, 1);
	float h = normalize(cam_dir).y;
	//ALBEDO = texture(bg_gradient, vec2(h*0.49+0.5, 0)).rgb;
	//DEPTH = 0.0;
	float sd = dot(normalize(cam_dir), sun);
	//float sun_effect = (sd - 0.9
	//ALBEDO = mix(
		//texture(bg_gradient, vec2(h*0.49+0.5, 0)).rgb,
		//sun_color,
		//smoothstep(0.995, 0.999, sd)
	//);
	vec3 sky = texture(bg_gradient, vec2(h*0.49+0.5, 0)).rgb;
	float sun_angle = dot(sun, normalize(cam_dir));
	if (sun_angle > sun_size) {
		sky = sun_color;
	} else if (sun_angle > sun_angle_max) {
		float c2 = (sun_size - sun_angle) / (sun_size - sun_angle_max);
		sky = mix(sky, sun_color, clamp(pow(1.0 - c2, inv_sun_curve), 0.0, 1.0));
	}
	ALBEDO = sky;
	//ALPHA = 0.99;
	// Called for every pixel the material is visible on.
}
