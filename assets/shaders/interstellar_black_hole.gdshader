shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform float black_hole_radius = 2.2;
uniform float disk_inner_radius = 2.6;
uniform float disk_outer_radius = 11.5;
uniform vec4 color_core : source_color = vec4(1.0, 0.96, 0.85, 1.0);
uniform vec4 color_mid : source_color = vec4(1.0, 0.68, 0.18, 1.0);
uniform vec4 color_rim : source_color = vec4(0.85, 0.32, 0.08, 1.0);
uniform float rotation_speed = 0.8;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
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
    vec2 uv = (UV - vec2(0.5)) * 2.0;
    float r = length(uv) * 14.0;
    float phi = atan(uv.y, uv.x);

    // 1. Central Event Horizon (Schwarzschild black hole shadow)
    if (r < black_hole_radius * 1.1) {
        ALBEDO = vec3(0.0);
        ALPHA = 1.0;
    } else {
        // 2. Einstein Photon Sphere (ultrabright ring at shadow edge)
        float photon_ring = exp(-pow(r - black_hole_radius * 1.18, 2.0) / 0.04) * 4.0;

        // 3. Interstellar Geometry: Horizontal Accretion Disk
        float r_eq = length(vec2(uv.x * 3.8, uv.y * 18.0));
        float mask_eq = smoothstep(disk_inner_radius, disk_inner_radius + 1.2, r_eq) *
                        smoothstep(disk_outer_radius, disk_outer_radius - 3.0, r_eq);

        // 4. Upper Gravitational Lensing Halo (Rear disk bent over top)
        float r_top = length(vec2(uv.x * 4.4, (uv.y - 0.28) * 8.2));
        float mask_top = smoothstep(disk_inner_radius * 0.95, disk_inner_radius + 1.0, r_top) *
                         smoothstep(disk_outer_radius * 0.72, disk_outer_radius * 0.72 - 2.5, r_top);

        // 5. Lower Gravitational Lensing Halo (Rear disk bent under bottom)
        float r_bot = length(vec2(uv.x * 4.4, (uv.y + 0.28) * 8.2));
        float mask_bot = smoothstep(disk_inner_radius * 0.95, disk_inner_radius + 1.0, r_bot) *
                         smoothstep(disk_outer_radius * 0.68, disk_outer_radius * 0.68 - 2.2, r_bot) * 0.7;

        float total_mask = max(mask_eq, max(mask_top, mask_bot));

        // Plasma turbulence with rotation
        float flow = phi + TIME * rotation_speed;
        float plasma = fbm(vec2(r * 0.65 - TIME * 0.3, flow * 2.8));
        total_mask *= (0.65 + 0.5 * plasma);

        // Relativistic Doppler Beaming (approaching side is brighter/bluer)
        float doppler = clamp(1.0 - uv.x * 0.55, 0.45, 1.85);
        total_mask *= doppler;

        // Radial Temperature Gradient
        float temp_t = clamp((r - disk_inner_radius) / (disk_outer_radius - disk_inner_radius), 0.0, 1.0);
        vec3 disk_col = mix(color_core.rgb, color_mid.rgb, smoothstep(0.0, 0.4, temp_t));
        disk_col = mix(disk_col, color_rim.rgb, smoothstep(0.4, 1.0, temp_t));

        vec3 final_color = disk_col * total_mask * 2.4 + color_core.rgb * photon_ring;
        float alpha_val = clamp(total_mask + photon_ring, 0.0, 1.0);

        // Smooth outer edge fadeout
        alpha_val *= smoothstep(13.0, 9.5, r);

        ALBEDO = final_color;
        ALPHA = alpha_val;
    }
}
