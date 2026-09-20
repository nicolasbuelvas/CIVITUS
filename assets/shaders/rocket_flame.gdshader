shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

// Supersonic Aerospace Rocket Exhaust Plume Shader
// Features:
// 1. Incandescent inner plasma core (white-hot to cyan)
// 2. Outer hydrocarbon combustion sheath (fiery orange/gold)
// 3. Periodic Supersonic Shock Diamonds (Mach Discs)
// 4. Downward supersonic turbulence and gaseous plume expansion
// 5. Soft edge feathering and axial depth decay

uniform vec4 core_color : source_color = vec4(1.0, 0.98, 0.92, 1.0);
uniform vec4 flame_color : source_color = vec4(1.0, 0.52, 0.08, 0.90);
uniform vec4 rim_color : source_color = vec4(0.2, 0.6, 1.0, 0.50);
uniform float shock_diamond_freq : hint_range(5.0, 40.0) = 18.0;
uniform float flame_speed : hint_range(5.0, 50.0) = 28.0;
uniform float expansion_power : hint_range(0.5, 3.0) = 1.3;

void vertex() {
	// Downward supersonic gas expansion wobble
	float t = TIME * flame_speed;
	float wobble = sin(VERTEX.y * 12.0 - t) * 0.04 * (1.0 - UV.y);
	VERTEX.xz += normalize(VERTEX.xz + vec2(0.001)) * wobble;
}

void fragment() {
	float t = TIME * flame_speed;
	float y_axis = clamp(UV.y, 0.0, 1.0); // 0 at nozzle, 1 at tail
	
	// Radial distance from plume center axis
	float radial = length(UV - vec2(0.5, UV.y)) * 2.0;
	float core_mask = clamp(1.0 - radial * 2.2, 0.0, 1.0);
	core_mask = pow(core_mask, 1.8);
	
	// Supersonic Shock Diamonds (Mach discs) along the central gas stream
	float mach_wave = cos(y_axis * shock_diamond_freq - t * 0.2) * 0.5 + 0.5;
	mach_wave = pow(mach_wave, 4.0) * (1.0 - y_axis * 0.75);
	float diamond_core = mach_wave * clamp(1.0 - radial * 3.5, 0.0, 1.0);
	
	// High-speed shear noise along the plume boundary
	float stream_noise = sin(UV.x * 24.0 + y_axis * 36.0 - t) * 0.15;
	
	// Color gradient: Incandescent White Core -> Golden Orange Flame -> Violet/Cyan Ion Sheath
	vec3 col = mix(flame_color.rgb, core_color.rgb, core_mask);
	col += rim_color.rgb * pow(radial, 2.5) * 0.6;
	col += core_color.rgb * diamond_core * 2.5; // Blazing hot shock diamonds
	
	// Tail decay and edge fade
	float alpha_decay = pow(1.0 - y_axis, expansion_power);
	float edge_fade = clamp(1.0 - radial, 0.0, 1.0);
	float final_alpha = (alpha_decay * edge_fade + diamond_core * 0.5) * (0.85 + stream_noise);
	
	ALBEDO = col * 2.2;
	ALPHA = clamp(final_alpha, 0.0, 1.0);
}
