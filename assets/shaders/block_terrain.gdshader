shader_type spatial;

uniform sampler2D top_texture : source_color, filter_nearest;
uniform sampler2D side_texture : source_color, filter_nearest;
uniform float roughness : hint_range(0.0, 1.0) = 0.8;

void fragment() {
	vec4 top_col = texture(top_texture, UV);
	vec4 side_col = texture(side_texture, UV);
	
	// Normal.y > 0.5 means top face of the block
	float is_top = step(0.5, NORMAL.y);
	vec4 col = mix(side_col, top_col, is_top);
	
	ALBEDO = col.rgb * COLOR.rgb;
	ROUGHNESS = roughness;
}
