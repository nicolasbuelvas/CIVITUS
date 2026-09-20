shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back;

// Spherical Fluid Shader for Planetary Oceans, Lakes, Magma & Cryo Seas
// Mobile-optimized (single-pass, zero heavy raymarching, 60 FPS target)

uniform vec4 fluid_color : source_color = vec4(0.06, 0.35, 0.75, 0.78);
uniform vec4 deep_color : source_color = vec4(0.02, 0.15, 0.45, 0.95);
uniform float wave_speed : hint_range(0.0, 0.2) = 0.04;
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.15;
uniform float roughness : hint_range(0.0, 1.0) = 0.10;
uniform float metallic : hint_range(0.0, 1.0) = 0.20;

// Thermal / Chemical emission (for molten lava or glowing bioluminescent oceans)
uniform bool is_emissive = false;
uniform vec3 emission_color : source_color = vec3(1.0, 0.35, 0.05);
uniform float emission_energy : hint_range(0.0, 5.0) = 2.4;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.13, 0.17));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float wave_noise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hash3(i + vec3(0,0,0)), hash3(i + vec3(1,0,0)), u.x),
	               mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), u.x),
	               mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), u.x), u.y), u.z);
}

void vertex() {
	// Gentle radial wave displacement on liquid sphere
	vec3 norm = normalize(VERTEX);
	float t = TIME * wave_speed;
	float w1 = sin(norm.x * 24.0 + norm.y * 18.0 + t * 4.0) * 0.04;
	float w2 = cos(norm.z * 28.0 + norm.x * 16.0 - t * 3.5) * 0.03;
	VERTEX += norm * (w1 + w2) * wave_amplitude;
}

void fragment() {
	vec3 norm = normalize(NORMAL);
	float t = TIME * wave_speed;
	
	// Dual-frequency rippling normal perturbation
	float n1 = wave_noise(norm * 45.0 + vec3(t, t * 0.6, -t * 0.4));
	float n2 = wave_noise(norm * 90.0 - vec3(t * 0.5, -t * 0.8, t * 0.3));
	float wave_factor = (n1 * 0.65 + n2 * 0.35);
	
	// View Fresnel effect: deep look is transparent, shallow grazing angle is reflective
	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float fresnel = pow(1.0 - n_dot_v, 3.5);
	
	// Sparkling water glints on sunlight reflection
	float glint = pow(max(0.0, dot(reflect(-VIEW, NORMAL), normalize(vec3(0.65, 0.40, 0.65)))), 36.0);
	float sparkle = wave_noise(norm * 180.0 + vec3(t * 2.0)) * glint * 1.8;
	
	vec3 final_albedo = mix(deep_color.rgb, fluid_color.rgb, n_dot_v);
	final_albedo = mix(final_albedo, vec3(0.92, 0.96, 1.0), fresnel * 0.35 + sparkle);
	
	ALBEDO = final_albedo;
	ROUGHNESS = roughness + wave_factor * 0.06 - sparkle * 0.05;
	METALLIC = metallic;
	SPECULAR = 0.55 + sparkle * 0.35;
	
	if (is_emissive) {
		// Pulsating magma fissures and glowing lava crust
		float crust = smoothstep(0.40, 0.70, wave_factor);
		vec3 lava_glow = mix(emission_color * emission_energy, emission_color * (emission_energy * 0.3), crust);
		EMISSION = lava_glow;
		ALPHA = 1.0;
	} else {
		ALPHA = clamp(fluid_color.a + fresnel * 0.25, 0.60, 0.95);
	}
}
