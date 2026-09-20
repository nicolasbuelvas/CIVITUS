shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_back, unshaded;

// Procedural dynamic cloud layer for spherical worlds
// Mobile-optimized (TBDR friendly, low fragment cost, zero raymarching)

uniform vec4 cloud_color : source_color = vec4(1.0, 1.0, 1.0, 0.85);
uniform vec3 sun_direction = vec3(0.5, 0.7, 0.5);
uniform float cloud_density : hint_range(0.0, 1.0) = 0.50;
uniform float cloud_speed : hint_range(0.0, 0.1) = 0.015;
uniform float rim_softness : hint_range(0.5, 4.0) = 1.8;

// Lightweight 3D hash noise
float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.1, 0.2, 0.3));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

float noise3d(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	vec3 u = f * f * (3.0 - 2.0 * f);
	
	return mix(mix(mix(hash3(i + vec3(0,0,0)), hash3(i + vec3(1,0,0)), u.x),
	               mix(hash3(i + vec3(0,1,0)), hash3(i + vec3(1,1,0)), u.x), u.y),
	           mix(mix(hash3(i + vec3(0,0,1)), hash3(i + vec3(1,0,1)), u.x),
	               mix(hash3(i + vec3(0,1,1)), hash3(i + vec3(1,1,1)), u.x), u.y), u.z);
}

void fragment() {
	// Sphere coordinate projection from vertex normal
	vec3 norm = normalize(NORMAL);
	
	// Dual-drift atmospheric wind currents (east-west jet streams)
	float t = TIME * cloud_speed;
	vec3 wind1 = vec3(sin(t * 0.7) * 0.1, 0.0, t);
	vec3 wind2 = vec3(-t * 0.8, sin(t * 0.5) * 0.08, t * 0.3);
	
	float n1 = noise3d(norm * 6.5 + wind1);
	float n2 = noise3d(norm * 14.0 + wind2);
	float cloud_shape = n1 * 0.65 + n2 * 0.35;
	
	// Thresholding according to cloud density
	float threshold = 1.0 - cloud_density * 0.85;
	float alpha_raw = smoothstep(threshold, threshold + 0.22, cloud_shape);
	
	// Solar illumination based on normal facing host star
	float sun_factor = clamp(dot(norm, normalize(sun_direction)), 0.0, 1.0);
	float day_t = smoothstep(0.0, 0.25, sun_factor);
	
	// Day clouds are brilliant white/tinted; night clouds are dark starlit silhouettes
	vec3 lit_color = cloud_color.rgb * (day_t * 0.85 + 0.15);
	
	// Sunset golden rim at the terminator (sun_factor near 0.05..0.20)
	float sunset_band = smoothstep(0.0, 0.14, sun_factor) * (1.0 - smoothstep(0.14, 0.35, sun_factor));
	lit_color = mix(lit_color, vec3(1.0, 0.55, 0.25), sunset_band * 0.65);
	
	// Soft Fresnel edge fade so clouds don't produce harsh clipping against space
	float view_rim = pow(clamp(dot(NORMAL, VIEW), 0.0, 1.0), rim_softness);
	
	ALBEDO = lit_color;
	ALPHA = alpha_raw * cloud_color.a * view_rim;
}
