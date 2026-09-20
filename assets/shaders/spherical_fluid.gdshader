shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// Spherical Fluid Shader for Planetary Oceans, Lakes, Magma & Cryo Seas
// Mobile-optimized (single-pass, zero heavy raymarching, 60 FPS target)
// Fully camera-invariant: texture and wave coordinates are anchored in World Space

uniform vec4 fluid_color : source_color = vec4(0.06, 0.35, 0.75, 0.78);
uniform vec4 deep_color : source_color = vec4(0.02, 0.15, 0.45, 0.95);
uniform float wave_speed : hint_range(0.0, 0.2) = 0.04;
uniform float wave_amplitude : hint_range(0.0, 1.0) = 0.15;
uniform float roughness : hint_range(0.0, 1.0) = 0.08;
uniform float metallic : hint_range(0.0, 1.0) = 0.18;

// Thermal / Chemical emission (for molten lava or glowing bioluminescent oceans)
uniform bool is_emissive = false;
uniform vec3 emission_color : source_color = vec3(1.0, 0.35, 0.05);
uniform float emission_energy : hint_range(0.0, 5.0) = 2.4;

// Interactive Character & Entity Ripple Wake
uniform vec3 character_pos = vec3(0.0);
uniform float character_motion : hint_range(0.0, 2.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

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

float calc_wave_height(vec3 np, float t) {
	float w1 = sin(np.x * 28.0 + np.y * 22.0 + t * 4.0) * 0.45;
	float w2 = cos(np.z * 32.0 + np.x * 18.0 - t * 3.5) * 0.35;
	float w3 = sin(np.y * 42.0 - np.z * 26.0 + t * 5.2) * 0.20;
	return w1 + w2 + w3;
}

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	
	// Gentle radial wave displacement on liquid sphere
	vec3 norm = normalize(VERTEX);
	float t = TIME * wave_speed;
	float w = calc_wave_height(norm, t) * 0.05;
	
	// Dynamic wake displacement around character (ONLY if character_pos is valid & submerged!)
	float char_disp = 0.0;
	if (length(character_pos) > 1.0) {
		float d_char = distance(v_world_pos, character_pos);
		if (d_char < 5.0) {
			float ripple = sin(d_char * 8.0 - TIME * 7.0) * smoothstep(5.0, 0.2, d_char);
			char_disp = ripple * (0.03 + character_motion * 0.08);
		}
	}
	
	VERTEX += norm * (w * wave_amplitude + char_disp);
}

void fragment() {
	float t = TIME * wave_speed;
	vec3 w_norm = normalize(v_world_normal);
	
	// Celestial sky reflection tint (matches planetary atmosphere, avoids washed-out white shadow)
	vec3 sky_reflect_col = vec3(0.20, 0.52, 0.88);
	if (is_emissive) {
		sky_reflect_col = vec3(0.85, 0.30, 0.08);
	}
	
	// Camera-invariant tangent frame derived from world normal
	vec3 w_t = normalize(abs(w_norm.y) < 0.9 ? cross(w_norm, vec3(0.0, 1.0, 0.0)) : cross(w_norm, vec3(0.0, 0.0, 1.0)));
	vec3 w_b = cross(w_norm, w_t);
	
	// Calculate wave gradient in world space for realistic normal perturbation
	float eps = 0.04;
	float h0 = calc_wave_height(w_norm, t);
	float ht = calc_wave_height(normalize(w_norm + w_t * eps), t);
	float hb = calc_wave_height(normalize(w_norm + w_b * eps), t);
	
	float dhdt = (ht - h0) / eps;
	float dhdb = (hb - h0) / eps;
	
	// Dual-frequency rippling normal perturbation in WORLD SPACE (camera invariant!)
	float n1 = wave_noise(w_norm * 32.0 + vec3(t, t * 0.6, -t * 0.4));
	float n2 = wave_noise(w_norm * 64.0 - vec3(t * 0.5, -t * 0.8, t * 0.3));
	float wave_factor = (n1 * 0.65 + n2 * 0.35);
	
	// Interactive wake ripple (smooth physical swell, zero unnatural white target rings)
	float char_wake_perturb = 0.0;
	float char_wake_foam = 0.0;
	if (length(character_pos) > 1.0) {
		float d_char = distance(v_world_pos, character_pos);
		if (d_char < 5.0) {
			float wake_falloff = smoothstep(5.0, 0.2, d_char);
			char_wake_perturb = sin(d_char * 8.0 - TIME * 7.0) * wake_falloff * (0.15 + character_motion * 0.35);
			// Soft churn foam only when moving quickly
			if (character_motion > 0.4) {
				char_wake_foam = smoothstep(2.5, 0.2, d_char) * (character_motion * 0.35);
			}
		}
	}
	
	// Smooth normal perturbation: physical fluid slope without harsh cellular shadow artifacts
	float wave_micro = (n1 - 0.5) * 0.22 + (n2 - 0.5) * 0.12;
	vec3 perturbed_world_norm = normalize(w_norm - (w_t * (dhdt * 0.8 + wave_micro + char_wake_perturb * 0.4) + w_b * (dhdb * 0.8 + wave_micro)) * (wave_amplitude * 0.38));
	
	if (!FRONT_FACING) {
		// Viewed from underwater looking UP at the liquid surface ceiling:
		vec3 under_norm = -perturbed_world_norm;
		NORMAL = normalize((VIEW_MATRIX * vec4(under_norm, 0.0)).xyz);
		float up_view = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		// Shimmering water ceiling reflecting refracted skylight and sun
		vec3 ceil_col = mix(fluid_color.rgb, sky_reflect_col * 1.35, pow(up_view, 1.8));
		float under_caustic = wave_noise(w_norm * 60.0 - vec3(t * 1.2, t * 0.8, -t * 0.9));
		ceil_col += vec3(pow(under_caustic, 2.0) * 0.25);
		ALBEDO = ceil_col;
		ROUGHNESS = 0.10;
		METALLIC = 0.15;
		SPECULAR = 0.85;
		ALPHA = clamp(fluid_color.a * 0.88, 0.70, 0.96);
		if (is_emissive) {
			EMISSION = emission_color * (emission_energy * 0.5);
		} else {
			EMISSION = fluid_color.rgb * 0.20;
		}
	} else {
		// Transform to VIEW space for Godot PBR lighting & specular highlights
		NORMAL = normalize((VIEW_MATRIX * vec4(perturbed_world_norm, 0.0)).xyz);
		
		// Subsurface optical caustics network (anchored in world space)
		float caustic1 = wave_noise(w_norm * 75.0 + vec3(t * 1.5, -t * 1.1, t * 0.7));
		float caustic2 = wave_noise(w_norm * 75.0 - vec3(t * 0.8, t * 1.3, -t * 1.0));
		float caustics = pow(caustic1 * caustic2, 2.0) * 1.6;
		
		// Delicate seafoam on wave crests and active character churn (soft and natural)
		float foam_mask = smoothstep(0.82, 0.95, wave_factor) * 0.30 + char_wake_foam;
		vec3 foam_color = vec3(0.92, 0.97, 1.0);
		if (is_emissive) {
			foam_color = vec3(1.0, 0.84, 0.35); // Incandescent golden foam on magma crests
		}
		
		// View Fresnel effect: deep look reveals crystal water, grazing rim reflects sky tint
		float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
		float fresnel = pow(1.0 - n_dot_v, 4.5);
		
		// Deep rich color gradient (solid, clear and vibrant from orbit/spectator mode)
		vec3 water_body = mix(deep_color.rgb, fluid_color.rgb, clamp(n_dot_v * 0.70 + 0.30, 0.0, 1.0));
		water_body += vec3(caustics * 0.035 * (1.0 - fresnel));
		water_body = mix(water_body, sky_reflect_col, fresnel * 0.40);
		water_body = mix(water_body, foam_color, clamp(foam_mask, 0.0, 0.45));
		
		ALBEDO = water_body;
		ROUGHNESS = roughness + wave_factor * 0.05 + foam_mask * 0.20;
		METALLIC = metallic;
		SPECULAR = 0.52;
		
		if (is_emissive) {
			// Glowing magma veins between cooling dark basalt crust
			float crust = smoothstep(0.38, 0.68, wave_factor);
			vec3 lava_glow = mix(emission_color * emission_energy, emission_color * (emission_energy * 0.25), crust);
			lava_glow += emission_color * (foam_mask * 2.5); // Incandescent foam
			EMISSION = lava_glow;
			ALPHA = 1.0;
		} else {
			// Subsurface optical luminescence: ensures ocean waters never resemble shadows from high orbit
			EMISSION = fluid_color.rgb * 0.14;
			ALPHA = clamp(fluid_color.a + fresnel * 0.12, 0.90, 0.98);
		}
	}
}