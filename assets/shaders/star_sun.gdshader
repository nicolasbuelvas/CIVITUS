shader_type spatial;
render_mode cull_back, unshaded;

// Star Visual Colors
uniform vec3 star_color : source_color = vec3(1.0, 0.85, 0.35);
uniform vec3 core_color : source_color = vec3(1.0, 0.98, 0.92);
uniform vec3 corona_color : source_color = vec3(1.0, 0.40, 0.12);

// Solar Physics & Animation Parameters
uniform float flare_speed : hint_range(0.01, 0.5) = 0.08;
uniform float turbulent_scale : hint_range(1.0, 12.0) = 4.5;
uniform float corona_intensity : hint_range(0.5, 4.0) = 2.2;
uniform float pulse_rate : hint_range(0.1, 2.0) = 0.4;

varying vec3 v_normal;
varying vec3 v_pos;

// 3D procedural noise for solar granules and magnetic convection cells
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

float fbm_star(vec3 p) {
	float v = 0.0;
	float a = 0.5;
	vec3 shift = vec3(100.0);
	for (int i = 0; i < 4; i++) {
		v += a * noise3(p);
		p = p * 2.05 + shift;
		a *= 0.5;
	}
	return v;
}

void vertex() {
	v_normal = normalize(NORMAL);
	v_pos = VERTEX;
}

void fragment() {
	// Animated convection cells crawling across the solar sphere
	float t = TIME * flare_speed;
	vec3 sample_pos1 = v_pos * turbulent_scale + vec3(t * 0.7, t * 0.5, t * 0.3);
	vec3 sample_pos2 = v_pos * (turbulent_scale * 1.8) - vec3(t * 0.4, t * 0.8, t * 0.6);
	
	float n1 = fbm_star(sample_pos1);
	float n2 = fbm_star(sample_pos2);
	float granule_noise = mix(n1, n2, 0.45);
	
	// Fresnel corona glow
	vec3 view_dir = normalize(-VERTEX);
	float NdotV = clamp(dot(v_normal, view_dir), 0.0, 1.0);
	float fresnel = pow(1.0 - NdotV, 2.5);
	
	// Subtle dynamic pulse
	float pulse = 1.0 + 0.06 * sin(TIME * pulse_rate * 6.28318);
	
	// Chromosphere & photosphere color grading
	vec3 surface_col = mix(star_color, core_color, pow(granule_noise, 2.2));
	vec3 rim_glow = mix(corona_color, star_color, NdotV) * fresnel * corona_intensity;
	
	vec3 final_color = (surface_col * pulse) + rim_glow;
	
	ALBEDO = final_color;
	EMISSION = final_color * 1.25;
}
