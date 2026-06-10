shader_type canvas_item;
render_mode unshaded, blend_mix;

const int MAX_LIGHTS = 16;

uniform vec4 darkness_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int light_count = 0;
uniform vec2 light_positions[MAX_LIGHTS];
uniform float light_radii[MAX_LIGHTS];
uniform float light_strengths[MAX_LIGHTS];
uniform float inner_radius_ratio = 0.15;

void fragment() {
	float visibility = 0.0;

	for (int i = 0; i < MAX_LIGHTS; i++) {
		if (i >= light_count) {
			break;
		}

		float radius = max(light_radii[i], 0.001);
		float inner_radius = radius * clamp(inner_radius_ratio, 0.0, 0.95);
		float dist = distance(FRAGCOORD.xy, light_positions[i]);
		float light_amount = 1.0 - smoothstep(inner_radius, radius, dist);
		visibility = max(visibility, light_amount * light_strengths[i]);
	}

	float darkness_alpha = darkness_color.a * (1.0 - clamp(visibility, 0.0, 1.0));
	COLOR = vec4(darkness_color.rgb, darkness_alpha);
}
