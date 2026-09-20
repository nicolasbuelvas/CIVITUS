shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Procedural Scorched Impact Crater Shader
// - Eliminates the harsh black circle
// - Organic radial blast striations & exhaust scorch marks
// - Thermal stress cracks with incandescent embers
// - Soft feathered boundary blending into planetary regolith

uniform vec3 crater_center_color : source_color = vec3(0.08, 0.07, 0.06);
uniform vec3 scorch_edge_color : source_color = vec3(0.24, 0.20, 0.17);
uniform vec3 planet_regolith_color : source_color = vec3(0.45, 0.40, 0.35);
uniform vec3 ember_color : source_color = vec3(1.0, 0.35, 0.05);

uniform float crater_radius : hint_range(4.0, 12.0) = 8.2;
uniform float inner_blast_radius : hint_range(1.0, 5.0) = 3.6;
uniform float heat_glow : hint_range(0.0, 2.0) = 0.85;

float hash21(vec2 p) {
	p = fract(p * vec2(234.34, 435.345));
	p += dot(p, p + 34.23);
	return fract(p.x * p.y);
}

float noise2d(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash21(i);
	float b = hash21(i + vec2(1.0, 0.0));
	float c = hash21(i + vec2(0.0, 1.0));
	float d = hash21(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm2d(vec2 p) {
	float v = 0.0;
	float a = 0.5;
	for (int i = 0; i < 4; i++) {
		v += a * noise2d(p);
		p *= 2.05;
		a *= 0.5;
	}
	return v;
}

void fragment() {
	// UV is centered at (0.5, 0.5)
	vec2 coord = (UV - vec2(0.5)) * 2.0;
	float dist = length(coord); // 0 at center, 1 at perimeter
	
	// Radial blast angle for rocket plume striations
	float angle = atan(coord.y, coord.x);
	float striations = fbm2d(vec2(angle * 4.0, dist * 8.0));
	float detail_noise = fbm2d(coord * 12.0);
	
	// Radial blast shape with feathered edge
	float blast_dist = dist + (detail_noise - 0.5) * 0.18;
	
	// Outer feathering: transparent at the rim so it merges with planet ground
	float alpha_mask = 1.0 - smoothstep(0.72, 0.98, blast_dist);
	if (alpha_mask <= 0.01) {
		discard;
	}
	
	// Color zones
	float inner_t = smoothstep(0.0, 0.45, blast_dist);
	float mid_t = smoothstep(0.35, 0.85, blast_dist);
	
	vec3 col = mix(crater_center_color, scorch_edge_color, inner_t);
	col = mix(col, planet_regolith_color, mid_t);
	
	// Dark blast streaks
	col *= mix(0.75, 1.15, striations);
	
	// Thermal cracks with glowing embers near center
	float crack_val = abs(noise2d(coord * 24.0) - 0.5) * 2.0;
	float crack_mask = smoothstep(0.12, 0.02, crack_val) * (1.0 - inner_t) * heat_glow;
	
	ALBEDO = col;
	ROUGHNESS = mix(0.92, 0.65, crack_mask);
	METALLIC = 0.12;
	SPECULAR = 0.25;
	
	EMISSION = ember_color * crack_mask * 1.8;
	ALPHA = alpha_mask;
}
