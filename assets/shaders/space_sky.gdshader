shader_type sky;

uniform vec3 space_color : source_color = vec3(0.018, 0.024, 0.042);
uniform vec3 nebula_color_1 : source_color = vec3(0.08, 0.03, 0.16); // Deep cosmic indigo
uniform vec3 nebula_color_2 : source_color = vec3(0.02, 0.08, 0.14); // Dark interstellar teal
uniform vec3 nebula_accent : source_color = vec3(0.12, 0.05, 0.10);  // Soft magenta dust
uniform float nebula_intensity : hint_range(0.0, 3.0) = 1.25;
uniform float star_brightness : hint_range(0.0, 3.0) = 0.55; // Toned down, elegant
uniform float dynamic_speed : hint_range(0.0, 0.2) = 0.015;

float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.13, 0.17));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise(vec3 x) {
	vec3 p = floor(x);
	vec3 w = fract(x);
	vec3 u = w * w * (3.0 - 2.0 * w);
	return mix(mix(mix(hash3(p + vec3(0.0, 0.0, 0.0)), hash3(p + vec3(1.0, 0.0, 0.0)), u.x),
	               mix(hash3(p + vec3(0.0, 1.0, 0.0)), hash3(p + vec3(1.0, 1.0, 0.0)), u.x), u.y),
	           mix(mix(hash3(p + vec3(0.0, 0.0, 1.0)), hash3(p + vec3(1.0, 0.0, 1.0)), u.x),
	               mix(hash3(p + vec3(0.0, 1.0, 1.0)), hash3(p + vec3(1.0, 1.0, 1.0)), u.x), u.y), u.z);
}

float fbm(vec3 p) {
	return noise(p) * 0.5 + noise(p * 2.02) * 0.25 + noise(p * 4.05) * 0.125;
}

void sky() {
	vec3 dir = normalize(EYEDIR);
	
	// Dynamic drifting time coordinates for slow interstellar cloud motion
	float t = TIME * dynamic_speed;
	vec3 drift1 = vec3(t * 0.5, t * 0.2, t * 0.3);
	vec3 drift2 = vec3(-t * 0.3, t * 0.4, -t * 0.2);
	
	// Volumetric deep space nebula layers
	float n1 = fbm(dir * 1.8 + drift1 + vec3(2.1, 4.3, 1.7));
	float n2 = fbm(dir * 2.6 + drift2 + vec3(6.5, 1.8, 3.9));
	float n3 = fbm(dir * 3.5 + vec3(8.2, 5.1, 2.4));
	
	vec3 neb1 = nebula_color_1 * smoothstep(0.35, 0.78, n1);
	vec3 neb2 = nebula_color_2 * smoothstep(0.40, 0.82, n2);
	vec3 neb3 = nebula_accent * smoothstep(0.45, 0.85, n3) * 0.6;
	vec3 total_nebula = (neb1 + neb2 + neb3) * nebula_intensity;
	
	// Soft, realistic stars (Gaussian circular falloff, toned-down brightness, subtle twinkle)
	vec3 p = dir * 140.0;
	vec3 fp = floor(p);
	float h = hash3(fp);
	float star = 0.0;
	
	if (h > 0.984) {
		vec3 center = fp + vec3(0.5);
		float d = length(p - center);
		// Smooth Gaussian spot instead of harsh square block
		float radius = 0.35 + (h - 0.984) * 12.0;
		star = exp(-d * d * (18.0 / radius));
		
		// Subtle organic twinkle
		float twinkle = 0.75 + 0.25 * sin(TIME * (1.5 + h * 4.0) + h * 6.28);
		star *= twinkle;
	}
	
	// Sparse faint background stars
	vec3 p2 = dir * 240.0;
	vec3 fp2 = floor(p2);
	float h2 = hash3(fp2);
	float star2 = 0.0;
	if (h2 > 0.994) {
		vec3 center2 = fp2 + vec3(0.5);
		float d2 = length(p2 - center2);
		star2 = exp(-d2 * d2 * 32.0) * 0.4;
	}
	
	// Gentle temperature tint (warm amber vs pale blue)
	vec3 star_color = mix(vec3(0.75, 0.85, 1.0), vec3(1.0, 0.88, 0.75), h);
	vec3 star_field = (star_color * star + vec3(0.8, 0.85, 0.95) * star2) * star_brightness;
	
	// Opaque deep space composite
	COLOR = space_color + total_nebula + star_field;
}
