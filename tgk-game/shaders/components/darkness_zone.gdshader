shader_type canvas_item;
render_mode unshaded, blend_mix;

const int MAX_LIGHTS = 16;
const int MAX_ZONE_POINTS = 64;

uniform vec4 darkness_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int light_count = 0;
uniform vec2 light_positions[MAX_LIGHTS];
uniform float light_radii[MAX_LIGHTS];
uniform float light_strengths[MAX_LIGHTS];
uniform float inner_radius_ratio = 0.15;
uniform int zone_point_count = 0;
uniform vec2 zone_points[MAX_ZONE_POINTS];
uniform float fade_distance = 8.0;

varying vec2 local_position;

void vertex() {
	local_position = VERTEX;
}

float distance_to_segment(vec2 p, vec2 a, vec2 b) {
	vec2 segment = b - a;
	float segment_length_sq = max(dot(segment, segment), 0.0001);
	float t = clamp(dot(p - a, segment) / segment_length_sq, 0.0, 1.0);
	return distance(p, a + segment * t);
}

float distance_to_zone_edge(vec2 p) {
	if (zone_point_count < 2) {
		return fade_distance;
	}

	float min_distance = 1000000.0;

	for (int i = 0; i < MAX_ZONE_POINTS; i++) {
		if (i >= zone_point_count) {
			break;
		}

		int next_index = i + 1;
		if (next_index >= zone_point_count) {
			next_index = 0;
		}

		min_distance = min(min_distance, distance_to_segment(p, zone_points[i], zone_points[next_index]));
	}

	return min_distance;
}

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

	float edge_alpha = 1.0;
	if (fade_distance > 0.0) {
		edge_alpha = smoothstep(0.0, fade_distance, distance_to_zone_edge(local_position));
	}

	float darkness_alpha = darkness_color.a * edge_alpha * (1.0 - clamp(visibility, 0.0, 1.0));
	COLOR = vec4(darkness_color.rgb, darkness_alpha);
}
