shader_type spatial;

uniform vec3 ocean_color : source_color = vec3(0.05, 0.35, 0.65);
uniform vec3 land_color : source_color = vec3(0.25, 0.65, 0.3);
uniform vec3 atmosphere_color : source_color = vec3(0.3, 0.7, 1.0);
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.05;

void fragment() {
	// Spherical UV coords
	vec2 p = UV * vec2(2.0, 1.0) + vec2(TIME * rotation_speed, 0.0);
	
	// Continent noise approximation using trigonometric waves
	float n = sin(p.x * 6.28) * cos(p.y * 3.14 * 2.0);
	n += sin(p.x * 12.56 + 1.5) * cos(p.y * 6.28) * 0.5;
	
	// Ocean vs Land
	float land_mask = step(0.1, n);
	vec3 base_col = mix(ocean_color, land_color, land_mask);
	
	// Atmospheric rim glow
	float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	vec3 final_color = mix(base_col, atmosphere_color, fresnel * 0.75);
	
	ALBEDO = final_color;
	ROUGHNESS = mix(0.2, 0.8, land_mask);
	METALLIC = 0.05;
	EMISSION = atmosphere_color * fresnel * 0.4;
}
