shader_type spatial;
render_mode unshaded, cull_disabled;

uniform vec4 core_color : source_color = vec4(1.0, 0.95, 0.75, 1.0);
uniform vec4 mid_color : source_color = vec4(1.0, 0.65, 0.15, 1.0);
uniform vec4 rim_color : source_color = vec4(0.9, 0.25, 0.05, 1.0);
uniform float granulation_scale = 12.0;
uniform float pulse_speed = 0.4;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x),
               mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    mat2 rot = mat2(vec2(cos(0.5), sin(0.5)), vec2(-sin(0.5), cos(0.5)));
    for (int i = 0; i < 4; i++) {
        v += a * noise(p);
        p = rot * p * 2.1;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV * granulation_scale;
    float t = TIME * pulse_speed;
    
    // Convective solar plasma circulation
    float n1 = fbm(uv + vec2(t * 0.5, t * 0.2));
    float n2 = fbm(uv * 1.5 - vec2(t * 0.3, -t * 0.4));
    float plasma = n1 * 0.6 + n2 * 0.4;
    
    // Fresnel limb darkening
    float fresnel = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 1.8);
    
    // Color mixing based on plasma heat and limb
    vec3 col = mix(core_color.rgb, mid_color.rgb, smoothstep(0.3, 0.7, plasma));
    col = mix(col, rim_color.rgb, fresnel * 0.85);
    
    // Corona edge glow
    col += rim_color.rgb * pow(fresnel, 3.0) * 2.5;

    ALBEDO = col;
}
