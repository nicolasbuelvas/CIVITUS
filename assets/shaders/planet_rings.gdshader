shader_type spatial;
render_mode cull_disabled, blend_mix, depth_draw_opaque;

uniform vec3 ring_color : source_color = vec3(0.85, 0.75, 0.65);
uniform vec3 shadow_color : source_color = vec3(0.05, 0.05, 0.1);
uniform float inner_radius = 0.55;
uniform float outer_radius = 0.95;
uniform float ring_density = 1.0;

void fragment() {
	vec2 center = UV - vec2(0.5);
	float dist = length(center) * 2.0;
	
	if (dist < inner_radius || dist > outer_radius) {
		discard;
	}
	
	// Ring bands using trigonometric harmonic rings
	float band = sin(dist * 65.0) * 0.5 + 0.5;
	band *= sin(dist * 180.0) * 0.3 + 0.7;
	band = pow(band, 1.4);
	
	// Fade edges
	float edge_fade = smoothstep(inner_radius, inner_radius + 0.04, dist) * 
	                  (1.0 - smoothstep(outer_radius - 0.04, outer_radius, dist));
	
	ALBEDO = ring_color * (0.6 + 0.4 * band);
	ALPHA = clamp(band * edge_fade * ring_density * 0.85, 0.0, 1.0);
	ROUGHNESS = 0.9;
}
