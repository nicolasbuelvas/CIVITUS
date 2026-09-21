shader_type spatial;
render_mode blend_add, depth_draw_never, cull_back, unshaded;

// Physical atmospheric scattering & limb rim glow for spherical worlds
// Transparent on planet disc, luminous Rayleigh halo on silhouette horizon
uniform vec4 atmosphere_color : source_color = vec4(0.30, 0.70, 1.0, 0.85);
uniform vec3 sun_direction = vec3(0.5, 0.7, 0.5);
uniform float rim_power : hint_range(0.5, 8.0) = 3.2;
uniform float sun_intensity_power : hint_range(0.5, 6.0) = 1.6;
uniform float density : hint_range(0.0, 3.0) = 1.0;

void fragment() {
	// View-aligned limb Fresnel (zero in center, peak at horizon silhouette)
	float n_dot_v = clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = pow(1.0 - n_dot_v, rim_power);
	
	// Rayleigh forward-scattering on host-star illuminated hemisphere (world space normal)
	vec3 sun_dir_norm = normalize(sun_direction);
	vec3 world_normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	float sun_factor = clamp(dot(world_normal, sun_dir_norm), 0.0, 1.0);
	float sun_scattering = pow(sun_factor, sun_intensity_power) * 1.5 + 0.12;
	
	// Sunset golden-crimson reddening along the terminator edge
	float terminator_band = smoothstep(0.0, 0.16, sun_factor) * (1.0 - smoothstep(0.16, 0.38, sun_factor));
	vec3 lit_color = mix(atmosphere_color.rgb, vec3(1.0, 0.45, 0.15), terminator_band * 0.75);
	
	ALBEDO = lit_color;
	ALPHA = clamp(rim * sun_scattering * atmosphere_color.a * density, 0.0, 0.95);
}
