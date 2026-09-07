shader_type spatial;
render_mode cull_back, diffuse_burley, specular_schlick_ggx;

// Color Palette
uniform vec3 ocean_color : source_color = vec3(0.04, 0.22, 0.55);
uniform vec3 shore_color : source_color = vec3(0.12, 0.45, 0.70);
uniform vec3 beach_color : source_color = vec3(0.76, 0.70, 0.50);
uniform vec3 land_color : source_color = vec3(0.20, 0.52, 0.25);
uniform vec3 mountain_color : source_color = vec3(0.45, 0.40, 0.35);
uniform vec3 peak_color : source_color = vec3(0.92, 0.95, 1.0);
uniform vec3 atmosphere_color : source_color = vec3(0.30, 0.70, 1.0);
uniform vec3 cloud_color : source_color = vec3(1.0, 1.0, 1.0);
uniform vec3 emission_color : source_color = vec3(0.0, 0.0, 0.0);

// Generation Parameters
uniform float water_threshold : hint_range(0.0, 1.0) = 0.48;
uniform float mountain_threshold : hint_range(0.0, 1.0) = 0.72;
uniform float peak_threshold : hint_range(0.0, 1.0) = 0.88;
uniform float cloud_density : hint_range(0.0, 1.0) = 0.55;
uniform float cloud_speed : hint_range(0.0, 0.5) = 0.03;
uniform float rotation_speed : hint_range(-0.5, 0.5) = 0.02;
uniform float emission_energy : hint_range(0.0, 10.0) = 0.0;
uniform float fresnel_intensity : hint_range(0.0, 5.0) = 1.6;
uniform float noise_scale : hint_range(0.5, 8.0) = 2.4;

varying vec3 v_normal;
varying vec3 v_pos;

// Hash functions for 3D procedural noise (seamless across sphere)
float hash31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.1, 0.1));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3(vec3 x) {
	vec3 p = floor(x);
	vec3 w = fract(x);
	vec3 u = w * w * (3.0 - 2.0 * w);
	
	float n000 = hash31(p + vec3(0.0, 0.0, 0.0));
	float n100 = hash31(p + vec3(1.0, 0.0, 0.0));
	float n010 = hash31(p + vec3(0.0, 1.0, 0.0));
	float n110 = hash31(p + vec3(1.0, 1.0, 0.0));
	float n001 = hash31(p + vec3(0.0, 0.0, 1.0));
	float n101 = hash31(p + vec3(1.0, 0.0, 1.0));
	float n011 = hash31(p + vec3(0.0, 1.0, 1.0));
	float n111 = hash31(p + vec3(1.0, 1.0, 1.0));
	
	float nx00 = mix(n000, n100, u.x);
	float nx10 = mix(n010, n110, u.x);
	float nx01 = mix(n001, n101, u.x);
	float nx11 = mix(n011, n111, u.x);
	
	float nxy0 = mix(nx00, nx10, u.y);
	float nxy1 = mix(nx01, nx11, u.y);
	
	return mix(nxy0, nxy1, u.z);
}

// Fractal Brownian Motion for rich continents & terrain detail
float fbm(vec3 p, int octaves) {
	float val = 0.0;
	float amp = 0.5;
	float freq = 1.0;
	for(int i = 0; i < octaves; i++) {
		val += amp * noise3(p * freq);
		freq *= 2.05;
		amp *= 0.5;
	}
	return val;
}

void vertex() {
	v_normal = NORMAL;
	v_pos = VERTEX;
}

void fragment() {
	// Rotate coordinate space around Y axis for smooth planetary rotation
	float rot_angle = TIME * rotation_speed;
	mat3 rot_mat = mat3(
		vec3(cos(rot_angle), 0.0, sin(rot_angle)),
		vec3(0.0, 1.0, 0.0),
		vec3(-sin(rot_angle), 0.0, cos(rot_angle))
	);
	vec3 p = rot_mat * normalize(v_pos) * noise_scale;
	
	// Base continental elevation
	float elev = fbm(p, 5);
	
	// Secondary ridges and rivers
	float detail = fbm(p * 2.2 + vec3(4.2, 1.7, 9.1), 3);
	elev = mix(elev, detail, 0.25);
	
	// Biome color grading
	vec3 surface_col;
	float is_water = 0.0;
	float roughness = 0.85;
	float metallic = 0.02;
	
	if (water_threshold > 0.05 && elev < water_threshold) {
		// Ocean / Water depth gradient
		float depth = elev / water_threshold;
		surface_col = mix(ocean_color, shore_color, smoothstep(0.4, 1.0, depth));
		is_water = 1.0;
		roughness = 0.15; // Sleek water specularity
		metallic = 0.08;
	} else if (water_threshold > 0.05 && elev < water_threshold + 0.04) {
		// Coastal beach / shore
		float t = (elev - water_threshold) / 0.04;
		surface_col = mix(beach_color, land_color, t);
		roughness = 0.75;
	} else if (elev < mountain_threshold) {
		// Lowlands / Forests / Plains
		float t = (elev - (water_threshold + 0.04)) / max(0.001, (mountain_threshold - (water_threshold + 0.04)));
		surface_col = mix(land_color, mountain_color, t * 0.7);
		roughness = 0.85;
	} else if (elev < peak_threshold) {
		// Rocky Mountains
		float t = (elev - mountain_threshold) / max(0.001, (peak_threshold - mountain_threshold));
		surface_col = mix(mountain_color, peak_color, t * 0.6);
		roughness = 0.90;
	} else {
		// Glacial snow peaks / high crags
		surface_col = peak_color;
		roughness = 0.65;
	}
	
	// Dynamic animated cloud layer (independent drift)
	vec3 cloud_col_final = vec3(0.0);
	float cloud_alpha = 0.0;
	if (cloud_density > 0.05) {
		float cloud_rot = TIME * (rotation_speed + cloud_speed);
		mat3 c_rot = mat3(
			vec3(cos(cloud_rot), 0.0, sin(cloud_rot)),
			vec3(0.0, 1.0, 0.0),
			vec3(-sin(cloud_rot), 0.0, cos(cloud_rot))
		);
		vec3 cp = c_rot * normalize(v_pos) * (noise_scale * 1.35) + vec3(12.5, 3.2, 7.8);
		float cloud_noise = fbm(cp, 4);
		
		// Cloud shadow cast on terrain
		float cloud_shadow = smoothstep(1.0 - cloud_density * 0.7, 1.0, cloud_noise) * 0.35;
		surface_col *= (1.0 - cloud_shadow);
		
		// Cloud layer blend
		cloud_alpha = smoothstep(1.0 - cloud_density, 1.0, cloud_noise);
		cloud_col_final = cloud_color;
		surface_col = mix(surface_col, cloud_col_final, cloud_alpha);
		roughness = mix(roughness, 0.95, cloud_alpha);
	}
	
	// Pulsating lava / plasma rifts (for Level 4 & 5 planets)
	vec3 emit_col = vec3(0.0);
	if (emission_energy > 0.01) {
		float rift_mask = smoothstep(0.68, 0.85, fbm(p * 3.5 + vec3(2.1, 8.4, 1.3), 3));
		// Also emit strongly in low trenches if lava planet
		if (water_threshold > 0.05 && elev < water_threshold * 0.75) {
			rift_mask = max(rift_mask, 1.0 - (elev / (water_threshold * 0.75)));
		}
		emit_col = emission_color * rift_mask * emission_energy;
		surface_col = mix(surface_col, emission_color, rift_mask * 0.8);
	}
	
	// Atmospheric Rayleigh rim scattering (Fresnel glow)
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.2);
	vec3 atmo = atmosphere_color * fresnel * fresnel_intensity;
	
	ALBEDO = surface_col;
	ROUGHNESS = roughness;
	METALLIC = metallic;
	EMISSION = emit_col + atmo * 0.85;
}
