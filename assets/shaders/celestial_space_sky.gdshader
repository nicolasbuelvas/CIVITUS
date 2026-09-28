shader_type sky;

// Unified Astrophysical Celestial Sky Shader
// Grounded in Planetary Science & Atmospheric Optics:
// 1. Physically continuous celestial solar vector (no popping, no camera-locked clashes)
// 2. Continuous Rayleigh & Mie atmospheric scattering derived per view ray
// 3. Directional sunset/dawn glow concentrated in setting sun azimuth (Belt of Venus anti-solar)
// 4. Smooth day -> twilight -> night transition with organic daylight star extinction
// 5. KSP Barometric scale height: high altitude reveals pitch-black space & stars
// 6. Pinpoint sub-pixel stars & subtle Milky Way galactic dust band

uniform vec3 space_color : source_color = vec3(0.001, 0.002, 0.004);
uniform vec3 sun_direction = vec3(0.65, 0.40, 0.65);
uniform vec3 sun_color : source_color = vec3(1.0, 0.96, 0.88);
uniform float sun_angular_size : hint_range(0.008, 0.08) = 0.024;

// Atmospheric Rayleigh Parameters
uniform float atmosphere_density : hint_range(0.0, 3.0) = 1.0;
uniform float barometric_factor : hint_range(0.0, 1.0) = 1.0;
uniform float local_sun_altitude : hint_range(-1.0, 1.0) = 0.5;
uniform vec3 sky_zenith_color : source_color = vec3(0.12, 0.22, 0.45);
uniform vec3 sky_horizon_color : source_color = vec3(0.30, 0.70, 1.0);
uniform vec3 sunset_color : source_color = vec3(1.0, 0.38, 0.12);
uniform vec3 player_up = vec3(0.0, 1.0, 0.0);

// Faint, realistic Milky Way galactic band
uniform vec3 galactic_plane_normal = vec3(0.35, 0.82, 0.45);
uniform vec3 nebula_color_1 : source_color = vec3(0.035, 0.018, 0.060); // Faint cosmic violet
uniform vec3 nebula_color_2 : source_color = vec3(0.015, 0.030, 0.045); // Faint cosmic teal
uniform vec3 nebula_dust : source_color = vec3(0.050, 0.025, 0.015);   // Faint dust rifts

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
	vec3 sun_dir_norm = normalize(sun_direction);
	vec3 up_norm = normalize(player_up);
	
	// =========================================================================
	// 1. FAINT, REALISTIC MILKY WAY (SUBTLE RIBBON, ZERO SECOND SUN)
	// =========================================================================
	float gal_lat = abs(dot(dir, normalize(galactic_plane_normal)));
	float gal_band = exp(-gal_lat * gal_lat * 20.0);
	
	float n1 = fbm(dir * 2.2 + vec3(1.5, 3.2, 4.1));
	float n2 = fbm(dir * 3.8 + vec3(5.1, 1.4, 2.7));
	float dust_rift = 1.0 - smoothstep(0.38, 0.62, fbm(dir * 4.5 + vec3(8.0, 2.0, 3.0))) * 0.70;
	
	vec3 neb = (nebula_color_1 * n1 + nebula_color_2 * n2) * gal_band * 0.35 * dust_rift;
	
	// =========================================================================
	// 2. PINPOINT REALISTIC STARFIELD
	// =========================================================================
	vec3 p = dir * 880.0;
	vec3 fp = floor(p);
	float h = hash3(fp);
	float star = 0.0;
	
	float star_thresh = mix(0.993, 0.985, gal_band);
	if (h > star_thresh) {
		vec3 center = fp + vec3(0.5);
		float d = length(p - center);
		star = exp(-d * d * 8.5) * (0.55 + 0.45 * (h - star_thresh) / (1.0 - star_thresh));
		float twinkle = 0.88 + 0.12 * sin(TIME * (2.0 + h * 3.5) + h * 6.28);
		star *= twinkle;
	}
	
	// Ultra-faint background stardust
	vec3 p2 = dir * 1450.0;
	vec3 fp2 = floor(p2);
	float h2 = hash3(fp2);
	float micro_star = 0.0;
	if (h2 > 0.996) {
		vec3 center2 = fp2 + vec3(0.5);
		float d2 = length(p2 - center2);
		micro_star = exp(-d2 * d2 * 12.0) * 0.35;
	}
	
	vec3 st_color = mix(vec3(0.78, 0.88, 1.0), vec3(1.0, 0.92, 0.80), h);
	vec3 star_field = st_color * star + vec3(0.92, 0.94, 1.0) * micro_star;
	vec3 cosmic_sky = space_color + neb + star_field;
	
	// =========================================================================
	// 3. HOST STAR SOLAR DISC (CLEAN, SHARP, SINGLE SUN)
	// =========================================================================
	float cos_sun = dot(dir, sun_dir_norm);
	float sun_radius_cos = cos(sun_angular_size);
	
	float sun_disc = smoothstep(sun_radius_cos, sun_radius_cos + 0.0006, cos_sun);
	float sun_corona = pow(clamp(cos_sun, 0.0, 1.0), 384.0) * 0.40;
	float sun_halo = pow(clamp(cos_sun, 0.0, 1.0), 64.0) * 0.04;
	
	vec3 sun_radiance = sun_color * (sun_disc * 2.2 + sun_corona + sun_halo);
	
	// =========================================================================
	// 4. PHYSICALLY CONTINUOUS RAYLEIGH ATMOSPHERE
	// =========================================================================
	float optical_mass = atmosphere_density * barometric_factor;
	
	if (optical_mass <= 0.02) {
		// Vacuum of space (Airless moon or orbit above Karman line)
		COLOR = cosmic_sky + sun_radiance;
	} else {
		// Sun zenith angle relative to observer's local tangent plane
		float sun_zenith = dot(up_norm, sun_dir_norm);
		float ray_elev = dot(dir, up_norm);
		float ray_elev_clamped = clamp(ray_elev, 0.0, 1.0);
		
		// 4a. Base Rayleigh sky gradient (zenith vs horizon)
		vec3 day_sky = mix(sky_horizon_color, sky_zenith_color, pow(ray_elev_clamped, 0.55));
		
		// 4b. Directional sunset / sunrise glow
		// Projection of sun direction onto observer's horizontal plane
		vec3 sun_horiz_proj = sun_dir_norm - up_norm * sun_zenith;
		float sun_horiz_len = length(sun_horiz_proj);
		vec3 sun_horiz = (sun_horiz_len > 0.001) ? (sun_horiz_proj / sun_horiz_len) : vec3(1.0, 0.0, 0.0);
		
		// Ray alignment with setting sun azimuth
		float azimuth_align = clamp(dot(dir, sun_horiz), 0.0, 1.0);
		
		// Sunset rim glow: concentrated near the horizon in the sun's direction
		float sunset_proximity = smoothstep(0.35, -0.20, sun_zenith);
		float sunset_active = smoothstep(-0.25, 0.12, sun_zenith) * sunset_proximity;
		float sunset_glow_strength = exp(-abs(ray_elev) * 5.0) * pow(azimuth_align, 2.2) * sunset_active;
		
		// Twilight / night transition factor based on sun elevation
		float day_factor = smoothstep(-0.12, 0.15, sun_zenith);
		float deep_night_factor = smoothstep(-0.30, -0.10, sun_zenith); // 0 at deep night, 1 at dawn
		
		// Base atmospheric lighting
		vec3 active_sky = mix(sunset_color, day_sky, day_factor);
		active_sky += sunset_color * (sunset_glow_strength * 1.8);
		
		// Twilight darkening
		vec3 twilight_deep = vec3(0.003, 0.005, 0.012) * optical_mass;
		active_sky = mix(twilight_deep, active_sky, deep_night_factor);
		
		// Forward scattering around the sun disc through atmospheric haze
		float forward_scatter = pow(clamp(cos_sun, 0.0, 1.0), 28.0) * 0.22 * optical_mass * day_factor;
		active_sky += sun_color * forward_scatter;
		
		// Daylight extinction of background stars
		float daylight_extinction = clamp(day_factor * optical_mass * 1.4, 0.0, 1.0);
		vec3 star_visible = cosmic_sky * (1.0 - daylight_extinction);
		
		// Procedural Atmospheric Clouds (Fase 5.1)
		// Organic cloud layer that scrolls with planetary trade winds, catches sunset light, and never clips 3D camera
		if (optical_mass > 0.05 && ray_elev > 0.0) {
			vec3 cloud_proj = dir / max(ray_elev + 0.12, 0.1);
			vec3 wind_offset = vec3(TIME * 0.008, 0.0, TIME * 0.005);
			float c_noise = fbm(cloud_proj * 1.4 + wind_offset);
			float c_density = smoothstep(0.48, 0.74, c_noise) * smoothstep(0.01, 0.28, ray_elev);
			vec3 c_color = mix(vec3(0.96, 0.97, 1.0), sunset_color * 1.3, sunset_glow_strength);
			active_sky = mix(active_sky, c_color, c_density * 0.58 * day_factor);
		}
		
		// Seamless Rayleigh horizon gradient (no harsh artificial dark cutoff band)
		vec3 final_atmosphere = active_sky;
		
		// Blend atmosphere with cosmic deep space
		float atmo_blend = clamp(optical_mass * deep_night_factor, 0.0, 1.0);
		COLOR = mix(cosmic_sky, final_atmosphere, atmo_blend) + star_visible + sun_radiance;
	}
}
