extends Node3D

# Celestial Atmosphere, Host Star & Day/Night Cycle Controller (KSP + Minecraft 20-Min Cycle)
# Grounded in astrophysics:
# 1. Moving Solar Celestial Orbit: 20-minute diurnal cycle (1200s Minecraft length) with 24° axial inclination
# 2. Synchronized Astronaut & Spaceship Shadows: Ground remains stable in physics space while shadows sweep realistically
# 3. Single Solar Disc: DirectionalLight3D sky_mode = LIGHT_ONLY ensures exactly one sun drawn in the sky shader
# 4. KSP Barometric Altitude: Atmospheric density drops exponentially with altitude P(h) = P0 * e^(-h/H)
# 5. Clean Deep Space: Pinpoint stars & subtle Milky Way band without second suns or screen burnout

@onready var world_env: WorldEnvironment = $WorldEnvironment
@onready var sun_light: DirectionalLight3D = $SunLight
@onready var planet: Node3D = $SphericalPlanet

# Host Star & Orbital Parameters
var star_data: Dictionary = {}
var star_color: Color = Color.WHITE
var star_luminosity: float = 1.0
var star_temperature: float = 5778.0
var orbit_au: float = 1.0
var base_light_energy: float = 1.25

# Atmospheric Envelope
var has_atmosphere: bool = true
var atmosphere_density: float = 1.0
var atmosphere_color: Color = Color(0.30, 0.70, 1.0)
var sky_color: Color = Color(0.12, 0.22, 0.45)
var sunset_color: Color = Color(1.0, 0.38, 0.12)

# Planetary Day/Night Cycle (Minecraft 20-Minute Period: 1200.0s)
var day_length: float = 1200.0
var time_of_day: float = 0.25 # Starts in bright morning
var current_sun_dir: Vector3 = Vector3.UP

# Player-centric local celestial state
var player_node: Node3D = null
var local_sun_altitude: float = 0.5
var barometric_factor: float = 1.0
var player_altitude_m: float = 0.0

# Sky Shader Material
var celestial_sky_mat: ShaderMaterial = null

func _ready() -> void:
	_init_celestial_atmosphere()

func _init_celestial_atmosphere() -> void:
	var planet_params = GameManager.current_planet
	var sys = GameManager.current_solar_system
	
	# 1. Retrieve Host Star Data
	if planet_params.has("star") and not planet_params["star"].is_empty():
		star_data = planet_params["star"]
	elif sys.has("star") and not sys["star"].is_empty():
		star_data = sys["star"]
	else:
		star_data = {
			"name": "Sol-Prime",
			"spectral_class": "G",
			"temperature": 5778.0,
			"luminosity": 1.0,
			"color": Color(1.0, 0.96, 0.88)
		}
		
	star_color = star_data.get("color", Color(1.0, 0.96, 0.88))
	star_luminosity = maxf(0.05, star_data.get("luminosity", 1.0))
	star_temperature = star_data.get("temperature", 5778.0)
	orbit_au = maxf(0.20, planet_params.get("orbit_au", 1.0))
	
	# 2. Astrophysics: Physical Irradiance Flux F = L / d^2
	var flux = star_luminosity / (orbit_au * orbit_au)
	base_light_energy = clampf(1.30 + 0.65 * log(maxf(0.05, flux) + 1.0), 1.10, 2.90)
	
	# Initial solar vector: Fixed celestial astronomical position in deep space
	current_sun_dir = Vector3(0.85, 0.35, 0.40).normalized()
	
	if sun_light:
		# Single sun: DirectionalLight3D only lights 3D geometry; shader draws the celestial sun disc
		sun_light.sky_mode = DirectionalLight3D.SKY_MODE_LIGHT_ONLY
		sun_light.light_color = star_color
		sun_light.light_energy = base_light_energy
		sun_light.shadow_enabled = true
		sun_light.look_at_from_position(current_sun_dir * 450.0, Vector3.ZERO, Vector3.UP)
		
	# 3. Atmospheric Properties
	has_atmosphere = planet_params.get("has_atmosphere", true)
	atmosphere_density = planet_params.get("atmosphere", 1.0) if has_atmosphere else 0.0
	atmosphere_color = planet_params.get("atmosphere_color", Color(0.30, 0.70, 1.0))
	sky_color = planet_params.get("sky_color", Color(0.12, 0.22, 0.45))
	sunset_color = star_color.lerp(Color(1.0, 0.38, 0.12), 0.70)
	
	# 4. Setup Procedural Celestial Sky & Depth Fog
	_setup_celestial_sky_and_fog()

func _setup_celestial_sky_and_fog() -> void:
	if not world_env or not world_env.environment:
		return
		
	var env = world_env.environment
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	
	# Load Astrophysical Celestial Sky Shader
	var sky_shader = load("res://assets/shaders/celestial_space_sky.gdshader")
	celestial_sky_mat = ShaderMaterial.new()
	celestial_sky_mat.shader = sky_shader
	
	var sky_res = Sky.new()
	sky_res.sky_material = celestial_sky_mat
	sky_res.process_mode = Sky.PROCESS_MODE_QUALITY
	env.background_mode = Environment.BG_SKY
	env.sky = sky_res
	
	# Apparent angular size of host star
	var apparent_sun_angular_size = clampf((0.024 * sqrt(star_luminosity)) / sqrt(orbit_au), 0.010, 0.048)
	
	celestial_sky_mat.set_shader_parameter("sun_direction", current_sun_dir)
	celestial_sky_mat.set_shader_parameter("sun_color", Vector3(star_color.r, star_color.g, star_color.b))
	celestial_sky_mat.set_shader_parameter("sun_angular_size", apparent_sun_angular_size)
	celestial_sky_mat.set_shader_parameter("sky_zenith_color", Vector3(sky_color.r, sky_color.g, sky_color.b))
	celestial_sky_mat.set_shader_parameter("sky_horizon_color", Vector3(atmosphere_color.r, atmosphere_color.g, atmosphere_color.b))
	celestial_sky_mat.set_shader_parameter("sunset_color", Vector3(sunset_color.r, sunset_color.g, sunset_color.b))
	celestial_sky_mat.set_shader_parameter("atmosphere_density", atmosphere_density)
	celestial_sky_mat.set_shader_parameter("barometric_factor", 1.0)
	celestial_sky_mat.set_shader_parameter("local_sun_altitude", 0.5)
	celestial_sky_mat.set_shader_parameter("player_up", Vector3.UP)
	
	# Zero fog occlusion on sky: Sky shader renders all atmospheric Rayleigh gradients cleanly
	env.fog_enabled = false
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	if not has_atmosphere:
		env.ambient_light_color = Color(0.08, 0.08, 0.11)
	else:
		var amb_tint = atmosphere_color.lerp(star_color, 0.28).lightened(0.12)
		env.ambient_light_color = amb_tint * clampf(atmosphere_density * 0.40, 0.20, 0.55)

func _process(delta: float) -> void:
	# 1. Advance diurnal planetary rotation around polar axis (Minecraft day/night cycle: 1200.0s)
	time_of_day = fmod(time_of_day + (delta / day_length), 1.0)
	if is_instance_valid(planet):
		planet.rotate_y((TAU / day_length) * delta)
	
	# 2. Evaluate Observer Position on Rotating Spherical Planet (Spatial Day/Night & KSP Barometric Altitude)
	_evaluate_player_spatial_celestial_state()
	
	# 3. Synchronize Directional Sunlight Vector & Shadow Orientation
	if sun_light:
		sun_light.look_at_from_position(current_sun_dir * 450.0, Vector3.ZERO, Vector3.UP)
		_update_lighting_and_sky()

func _evaluate_player_spatial_celestial_state() -> void:
	# Find player or spectator camera in tree if not cached
	if not is_instance_valid(player_node):
		player_node = get_node_or_null("Character3D")
		if not player_node and planet and "player_instance" in planet:
			player_node = planet.player_instance
		if not player_node:
			player_node = get_node_or_null("SpectatorCamera3D")
			
	var player_dir = Vector3.UP # Default to North pole landing pad
	player_altitude_m = 0.0
	barometric_factor = 1.0
	
	if is_instance_valid(player_node):
		var p_pos = player_node.global_position
		var p_len = p_pos.length()
		if p_len > 0.01:
			player_dir = p_pos / p_len
			# KSP Barometric scale height formula: P(h) = P0 * exp(-h / H)
			player_altitude_m = maxf(0.0, p_len - 160.0)
			barometric_factor = clampf(exp(-player_altitude_m / 22.0), 0.0, 1.0)
			
	# Real spatial dot product: Observer local solar altitude = Normal . SunDirection
	# Positive = Day side, Negative = Dark side (Night), Near zero = Sunset/Dawn terminator!
	local_sun_altitude = player_dir.dot(current_sun_dir)
	
	if celestial_sky_mat:
		celestial_sky_mat.set_shader_parameter("player_up", player_dir)

func _update_lighting_and_sky() -> void:
	if not has_atmosphere:
		if local_sun_altitude > 0.0:
			sun_light.light_color = star_color
			sun_light.light_energy = base_light_energy
		else:
			sun_light.light_energy = 0.0
			
		if celestial_sky_mat:
			celestial_sky_mat.set_shader_parameter("sun_direction", current_sun_dir)
			celestial_sky_mat.set_shader_parameter("atmosphere_density", 0.0)
			celestial_sky_mat.set_shader_parameter("barometric_factor", 0.0)
			celestial_sky_mat.set_shader_parameter("local_sun_altitude", local_sun_altitude)
		return
		
	var env = world_env.environment if world_env else null
	var effective_density = atmosphere_density * barometric_factor
	
	# Update Sky Shader
	if celestial_sky_mat:
		celestial_sky_mat.set_shader_parameter("sun_direction", current_sun_dir)
		celestial_sky_mat.set_shader_parameter("atmosphere_density", atmosphere_density)
		celestial_sky_mat.set_shader_parameter("barometric_factor", barometric_factor)
		celestial_sky_mat.set_shader_parameter("local_sun_altitude", local_sun_altitude)
		
	# Dynamic Sunlight & Ambient Lighting based on local day/night state
	# Direct sunlight orbits the celestial dome; near the horizon atmospheric reddening applies smoothly
	var sunset_t = smoothstep(-0.15, 0.15, local_sun_altitude)
	var twilight_color = star_color.lerp(sunset_color, 0.85)
	sun_light.light_color = twilight_color.lerp(star_color, sunset_t)
	sun_light.light_energy = base_light_energy * clampf(sunset_t + 0.15, 0.05, 1.0)
	
	if env:
		# Check if camera or observer is currently submerged inside planetary fluid
		var active_cam = get_viewport().get_camera_3d() if is_inside_tree() else null
		var cam_pos = active_cam.global_position if is_instance_valid(active_cam) else (player_node.global_position if is_instance_valid(player_node) else Vector3.ZERO)
		var sea_r = planet.get_ocean_surface_radius() if (is_instance_valid(planet) and planet.has_method("get_ocean_surface_radius")) else (float(planet.radius) if (is_instance_valid(planet) and "radius" in planet) else 160.0)
		var p_params = GameManager.current_planet if is_instance_valid(GameManager) else {}
		var has_fluid = str(p_params.get("water_status", "Seco / Desolado")) != "Seco / Desolado" and str(p_params.get("water_status", "")) != ""
		var is_cam_underwater = has_fluid and (cam_pos.length() < sea_r)

		if is_cam_underwater:
			# Deep Fluid Volumetric Immersion: transforms underwater into authentic liquid realm
			env.fog_enabled = true
			env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
			var water_stat = str(p_params.get("water_status", ""))
			var chem = str(p_params.get("ocean_chemical", ""))
			var is_molten = p_params.get("is_molten", false) or water_stat == "Lava Fundida" or chem == "magma"
			var is_acid = water_stat == "Vapor Tóxico" or chem == "sulfuric_acid"
			var is_cryo = water_stat == "Hielo Criogénico" or chem == "methane"
			
			if is_molten:
				env.fog_light_color = Color(1.0, 0.25, 0.05)
				env.fog_density = 0.085
				env.ambient_light_color = Color(1.0, 0.35, 0.08)
			elif is_acid:
				env.fog_light_color = Color(0.38, 0.65, 0.12)
				env.fog_density = 0.065
				env.ambient_light_color = Color(0.32, 0.58, 0.15)
			elif is_cryo:
				env.fog_light_color = Color(0.12, 0.48, 0.82)
				env.fog_density = 0.052
				env.ambient_light_color = Color(0.15, 0.45, 0.75)
			else:
				var ocean_c: Color = p_params.get("ocean_color", Color(0.12, 0.48, 0.88))
				env.fog_light_color = ocean_c.lerp(Color(0.04, 0.22, 0.58), 0.40)
				env.fog_density = 0.045
				env.ambient_light_color = ocean_c.lightened(0.15)
		else:
			env.fog_enabled = false
			if local_sun_altitude > 0.10:
				var day_amb = atmosphere_color.lerp(star_color, 0.25).lightened(0.10) * clampf(effective_density * 0.40, 0.20, 0.55)
				env.ambient_light_color = day_amb
			elif local_sun_altitude >= -0.20:
				var tw_t = smoothstep(-0.20, 0.10, local_sun_altitude)
				var twilight_amb = twilight_color.darkened(0.4) * clampf(effective_density * 0.35, 0.15, 0.4)
				var night_amb = Color(0.035, 0.040, 0.065)
				env.ambient_light_color = night_amb.lerp(twilight_amb, tw_t)
			else:
				env.ambient_light_color = Color(0.035, 0.040, 0.065)

# Public helper for tactical visor / HUD solar telemetry
func get_solar_time_display() -> String:
	var solar_offset = (local_sun_altitude + 1.0) * 0.5
	var local_hour = solar_offset * 24.0
	var hours = int(local_hour)
	var minutes = int(fmod(local_hour * 60.0, 60.0))
	return "%02d:%02d SOL" % [hours, minutes]

func get_sun_altitude() -> float:
	return local_sun_altitude

func get_barometric_altitude_m() -> float:
	return player_altitude_m
