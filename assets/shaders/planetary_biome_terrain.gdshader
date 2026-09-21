shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled;

// Planetary Biome & Columnar Basalt Terrain Shader
// Features:
// 1. Columnar Basalt / Hexagonal Jointing striations inspired by Giant's Causeway
// 2. Micro-relief rock grain & mineral scree on plateau steps
// 3. Slope-aware triplanar texturing: sheer vertical cliffs vs flat horizontal steps
// 4. Shoreline wetness & specular absorption near sea level
// 5. Dynamic biome tuning (Volcanic/Basalt, Arid, Lush, Cryo, Acidic)

uniform float roughness : hint_range(0.0, 1.0) = 0.82;
uniform float metallic : hint_range(0.0, 1.0) = 0.12;
uniform float sea_level_radius = 240.0;
uniform float column_scale = 1.25;
uniform float micro_grain_scale = 32.0;

// High-speed 3D hash
float hash3(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.11, 0.13, 0.17));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// 2D Hexagonal grid / Columnar Jointing distance
// Returns vec3(dist_to_center, dist_to_edge, cell_id)
vec3 hex_column(vec2 p) {
	vec2 q = vec2(p.x * 2.0 * 0.577350269, p.y + p.x * 0.577350269);
	vec2 pi = floor(q);
	vec2 pf = fract(q);
	float v = mod(pi.x + pi.y, 3.0);
	float ca = step(1.0, v);
	float cb = step(2.0, v);
	vec2 ma = step(pf.xy, pf.yx);
	vec2 id = pi + ca - cb * ma;
	
	// Hex cell center in orthogonal coords
	vec2 h_center = vec2(id.x * 0.8660254, id.y - id.x * 0.5);
	vec2 delta = p - h_center;
	
	// Distance to 6 edges of hexagon
	vec2 d = abs(delta);
	float edge_dist = 0.8660254 - max(d.x * 0.8660254 + d.y * 0.5, d.y);
	float center_dist = length(delta);
	
	return vec3(center_dist, edge_dist, id.x * 13.0 + id.y * 37.0);
}

// Micro-striation rock noise
float rock_grain(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float n000 = hash3(i);
	float n100 = hash3(i + vec3(1.0, 0.0, 0.0));
	float n010 = hash3(i + vec3(0.0, 1.0, 0.0));
	float n110 = hash3(i + vec3(1.0, 1.0, 0.0));
	float n001 = hash3(i + vec3(0.0, 0.0, 1.0));
	float n101 = hash3(i + vec3(1.0, 0.0, 1.0));
	float n011 = hash3(i + vec3(0.0, 1.0, 1.0));
	float n111 = hash3(i + vec3(1.0, 1.0, 1.0));
	return mix(
		mix(mix(n000, n100, f.x), mix(n010, n110, f.x), f.y),
		mix(mix(n001, n101, f.x), mix(n011, n111, f.x), f.y),
		f.z
	);
}

varying vec3 v_world_pos;
varying vec3 v_world_norm;
varying float v_radial_dist;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_norm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
	v_radial_dist = length(v_world_pos);
}

void fragment() {
	vec3 up_radial = normalize(v_world_pos);
	vec3 norm = normalize(v_world_norm);
	
	// Slope factor: 1.0 = flat horizontal step / plateau, 0.0 = steep vertical basalt cliff
	float slope = clamp(dot(norm, up_radial), 0.0, 1.0);
	float is_step_top = smoothstep(0.48, 0.72, slope);
	
	// Tangent plane projection for hex columns
	vec3 tangent = normalize(abs(up_radial.y) < 0.9 ? cross(up_radial, vec3(0.0, 1.0, 0.0)) : cross(up_radial, vec3(0.0, 0.0, 1.0)));
	vec3 bitangent = cross(up_radial, tangent);
	vec2 planar_uv = vec2(dot(v_world_pos, tangent), dot(v_world_pos, bitangent)) * column_scale;
	
	// Columnar jointing / Hexagonal prisms
	vec3 hex = hex_column(planar_uv);
	float edge_groove = smoothstep(0.0, 0.09, hex.y); // Dark crevice line between columns
	float step_variant = fract(hex.z * 0.123); // Individual pillar color tint variation
	
	// Directional rock striations on top faces
	vec3 grain_pos = v_world_pos * micro_grain_scale;
	float fine_grain = rock_grain(grain_pos);
	float coarse_strata = rock_grain(grain_pos * 0.25);
	float rock_texture = mix(fine_grain, coarse_strata, 0.45);
	
	// Vertical cooling fissures on cliff faces
	float cliff_fissures = sin(planar_uv.x * 14.0 + fine_grain * 1.5) * 0.5 + 0.5;
	cliff_fissures = smoothstep(0.25, 0.75, cliff_fissures);
	
	// Base albedo from vertex colors (contains geological strata & biome tints)
	vec3 base_col = COLOR.rgb;
	
	// Pillar shading modulation:
	// 1. Column face variation: slight tone shift between adjacent hexagonal columns
	vec3 column_tint = base_col * (0.88 + step_variant * 0.24);
	
	// 2. Top face: rough striated rock with micro-crystals and scree
	vec3 top_face_col = column_tint * (0.82 + rock_texture * 0.36);
	
	// 3. Side cliff: darker vertical basalt jointing with cooling fractures
	vec3 cliff_face_col = column_tint * (0.65 + cliff_fissures * 0.22);
	
	// Blend top step vs cliff wall based on slope
	vec3 shaded_terrain = mix(cliff_face_col, top_face_col, is_step_top);
	
	// Darken joint crevices between hexagonal columns
	shaded_terrain *= (0.50 + 0.50 * edge_groove);
	
	// Shoreline wetness near sea level (adds slight sheen and rich mineral saturation without pitch-black darkening)
	float dist_to_sea = abs(v_radial_dist - sea_level_radius);
	float is_shore_wet = 1.0 - smoothstep(0.0, 1.4, dist_to_sea);
	shaded_terrain = mix(shaded_terrain, shaded_terrain * 0.90, is_shore_wet * 0.40);
	
	// Normal perturbation for rough micro-relief in world space, then transformed to view space for Godot PBR
	float bump = (rock_texture - 0.5) * 0.28 * is_step_top + (cliff_fissures - 0.5) * 0.18 * (1.0 - is_step_top);
	vec3 world_perturbed_norm = normalize(norm + tangent * bump + bitangent * bump);
	NORMAL = normalize((VIEW_MATRIX * vec4(world_perturbed_norm, 0.0)).xyz);
	
	ALBEDO = shaded_terrain;
	ROUGHNESS = mix(roughness, 0.18, is_shore_wet);
	METALLIC = mix(metallic, 0.28, is_shore_wet);
	SPECULAR = mix(0.18, 0.65, is_shore_wet);
}
