extends Node3D

var frame_count: int = 0
var max_frames: int = 555 # 18.5s @ 30fps
var frames_dir: String = "res://temp_frames/authentic_intro/"
var anim_time: float = 0.0

# 3D Scene references
var ship: Node3D
var camera: Camera3D
var black_hole_quad: MeshInstance3D
var sun_sphere: MeshInstance3D
var sun_light: OmniLight3D
var cabin_light: OmniLight3D
var starfield_node: Node3D

# UI references
var black_screen: ColorRect
var terminal_window: Control
var terminal_rtl: RichTextLabel
var fade_overlay: ColorRect
var title_card: Control
var main_title_lbl: Label
var subtitle_lbl: Label

# Realistic Linux Prompt
var prompt_str: String = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] cat << 'EOF' > emergency_routine.gd\n"

# English GDScript code - NO COMMENTS
var code_text_plain = """extends CockpitTelemetryOS

var galactic_incident: String = "SAGITTARIUS_NEXUS_WARP_CORE_MELTDOWN"
var current_drift_location: String = "UNKNOWN_DEEP_VOID_OUTSKIRTS"
var life_support_state: String = "ISOLATED_EMERGENCY_RESERVE"

var required_survival_directives: Array[String] = [
    "SCAN_LOCAL_SYSTEM_FOR_SURVIVABLE_ATMOSPHERE",
    "INITIATE_TOUCHDOWN_AND_LAND_EXPLORATION_MODULE",
    "MINE_SURFACE_IRON_COPPER_SILICON_URANIUM",
    "FABRICATE_WRENCH_CIRCUITRY_REACTOR_CELLS",
    "RECONSTRUCT_WARP_CORE_AND_RESTORE_THRUST",
    "CALCULATE_RELATIVISTIC_VECTOR_TO_SUPERMASSIVE_BLACK_HOLE"
]

func _ready() -> void:
    assess_hull_structural_integrity()
    query_sagittarius_quantum_relay()
    query_hyperspace_propulsion_status()
    compute_distance_to_supermassive_black_hole()
EOF"""

var code_text_bbcode = """[color=#ff7085]extends[/color] [color=#67d5ff]CockpitTelemetryOS[/color]

[color=#ff7085]var[/color] galactic_incident: [color=#67d5ff]String[/color] = [color=#a5e179]"SAGITTARIUS_NEXUS_WARP_CORE_MELTDOWN"[/color]
[color=#ff7085]var[/color] current_drift_location: [color=#67d5ff]String[/color] = [color=#a5e179]"UNKNOWN_DEEP_VOID_OUTSKIRTS"[/color]
[color=#ff7085]var[/color] life_support_state: [color=#67d5ff]String[/color] = [color=#a5e179]"ISOLATED_EMERGENCY_RESERVE"[/color]

[color=#ff7085]var[/color] required_survival_directives: [color=#67d5ff]Array[/color][[color=#67d5ff]String[/color]] = [
    [color=#a5e179]"SCAN_LOCAL_SYSTEM_FOR_SURVIVABLE_ATMOSPHERE"[/color],
    [color=#a5e179]"INITIATE_TOUCHDOWN_AND_LAND_EXPLORATION_MODULE"[/color],
    [color=#a5e179]"MINE_SURFACE_IRON_COPPER_SILICON_URANIUM"[/color],
    [color=#a5e179]"FABRICATE_WRENCH_CIRCUITRY_REACTOR_CELLS"[/color],
    [color=#a5e179]"RECONSTRUCT_WARP_CORE_AND_RESTORE_THRUST"[/color],
    [color=#a5e179]"CALCULATE_RELATIVISTIC_VECTOR_TO_SUPERMASSIVE_BLACK_HOLE"[/color]
]

[color=#ff7085]func[/color] [color=#f5c66b]_ready[/color]() -> [color=#67d5ff]void[/color]:
    [color=#f5c66b]assess_hull_structural_integrity[/color]()
    [color=#f5c66b]query_sagittarius_quantum_relay[/color]()
    [color=#f5c66b]query_hyperspace_propulsion_status[/color]()
    [color=#f5c66b]compute_distance_to_supermassive_black_hole[/color]()
[color=#57c7ff]EOF[/color]"""

var total_code_chars: int = 0
var infinite_digits_pool: String = ""

func _ready() -> void:
	print("[Realistic Linux Intro] Initializing Linux console intro...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	
	total_code_chars = code_text_plain.length()
	
	var digits = ""
	for i in range(1200):
		digits += str(randi() % 10)
	infinite_digits_pool = digits
	
	_setup_3d_environment()
	_setup_ui()

func _setup_3d_environment() -> void:
	var env_node = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.001, 0.001, 0.003, 1.0)
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.15
	env.glow_enabled = true
	env.glow_intensity = 1.4
	env.glow_bloom = 0.4
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	env_node.environment = env
	add_child(env_node)

	camera = Camera3D.new()
	add_child(camera)
	camera.current = true
	camera.fov = 68.0

	var ship_scene = load("res://scenes/entities/spaceship_3d.tscn")
	if ship_scene:
		ship = ship_scene.instantiate()
		add_child(ship)
		ship.position = Vector3.ZERO
		var ramp = ship.get_node_or_null("HullStructure/BoardingRamp")
		if ramp:
			ramp.visible = false

	starfield_node = Node3D.new()
	add_child(starfield_node)
	for i in range(180):
		var star = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		var sz = randf_range(0.2, 0.5)
		s_mesh.radius = sz
		s_mesh.height = sz * 2.0
		var s_mat = StandardMaterial3D.new()
		s_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		s_mat.albedo_color = Color(0.85, 0.92, 1.0, 0.75)
		star.mesh = s_mesh
		star.material_override = s_mat
		star.position = Vector3(randf_range(-90, 90), randf_range(-40, 50), randf_range(-140, -50))
		starfield_node.add_child(star)

	# Interstellar Black Hole Quad
	black_hole_quad = MeshInstance3D.new()
	var q_mesh = QuadMesh.new()
	q_mesh.size = Vector2(26.0, 26.0)
	var bh_shader = load("res://assets/shaders/interstellar_black_hole.gdshader")
	var bh_mat = ShaderMaterial.new()
	bh_mat.shader = bh_shader
	black_hole_quad.mesh = q_mesh
	black_hole_quad.material_override = bh_mat
	black_hole_quad.position = Vector3(0.0, 0.0, -16.0)
	add_child(black_hole_quad)
	black_hole_quad.visible = false

	# Stellar Sun
	sun_sphere = MeshInstance3D.new()
	var sun_mesh = SphereMesh.new()
	sun_mesh.radius = 9.5
	sun_mesh.height = 19.0
	var sun_shader = load("res://assets/shaders/stellar_sun.gdshader")
	var sun_mat = ShaderMaterial.new()
	sun_mat.shader = sun_shader
	sun_sphere.mesh = sun_mesh
	sun_sphere.material_override = sun_mat
	sun_sphere.position = Vector3(2.5, 3.2, -45.0)
	add_child(sun_sphere)
	sun_sphere.visible = false

	sun_light = OmniLight3D.new()
	sun_light.position = sun_sphere.position
	sun_light.light_color = Color(1.0, 0.85, 0.45)
	sun_light.light_energy = 5.5
	sun_light.omni_range = 100.0
	add_child(sun_light)
	sun_light.visible = false

	cabin_light = OmniLight3D.new()
	cabin_light.position = Vector3(0, 1.35, -2.2)
	cabin_light.light_color = Color(0.2, 0.8, 1.0)
	cabin_light.light_energy = 1.0
	cabin_light.omni_range = 5.0
	add_child(cabin_light)
	cabin_light.visible = false

func _setup_ui() -> void:
	black_screen = ColorRect.new()
	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_screen.color = Color(0.0, 0.0, 0.0, 1.0)
	add_child(black_screen)

	# 1. REALISTIC LINUX CONSOLE WINDOW
	terminal_window = Control.new()
	terminal_window.position = Vector2(60, 45)
	terminal_window.size = Vector2(1160, 630)
	black_screen.add_child(terminal_window)

	var term_bg = Panel.new()
	term_bg.position = Vector2.ZERO
	term_bg.size = terminal_window.size
	var term_sb = StyleBoxFlat.new()
	term_sb.bg_color = Color(0.06, 0.07, 0.09, 0.98)
	term_sb.border_width_left = 1
	term_sb.border_width_top = 32
	term_sb.border_width_right = 1
	term_sb.border_width_bottom = 1
	term_sb.border_color = Color(0.2, 0.23, 0.28, 1.0)
	term_sb.corner_radius_top_left = 8
	term_sb.corner_radius_top_right = 8
	term_sb.corner_radius_bottom_left = 8
	term_sb.corner_radius_bottom_right = 8
	term_bg.add_theme_stylebox_override("panel", term_sb)
	terminal_window.add_child(term_bg)

	var dots_lbl = Label.new()
	dots_lbl.text = "  ●  ●  ●"
	dots_lbl.position = Vector2(12, 6)
	dots_lbl.size = Vector2(100, 20)
	dots_lbl.add_theme_font_size_override("font_size", 14)
	dots_lbl.add_theme_color_override("font_color", Color(0.85, 0.38, 0.38))
	terminal_window.add_child(dots_lbl)

	var title_lbl = Label.new()
	title_lbl.text = "astronaut@civitus-cockpit: ~/systems (bash)"
	title_lbl.position = Vector2(0, 6)
	title_lbl.size = Vector2(1160, 20)
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_lbl.add_theme_font_size_override("font_size", 13)
	title_lbl.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))
	terminal_window.add_child(title_lbl)

	terminal_rtl = RichTextLabel.new()
	terminal_rtl.bbcode_enabled = true
	terminal_rtl.position = Vector2(24, 46)
	terminal_rtl.size = Vector2(1112, 565)
	terminal_rtl.add_theme_font_size_override("normal_font_size", 16)
	terminal_window.add_child(terminal_rtl)

	# 2. Fade overlay
	fade_overlay = ColorRect.new()
	fade_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade_overlay.color = Color(0, 0, 0, 0.0)
	add_child(fade_overlay)

	# 3. Outro Title Card
	title_card = Control.new()
	title_card.set_anchors_preset(Control.PRESET_FULL_RECT)
	title_card.modulate.a = 0.0
	add_child(title_card)

	main_title_lbl = Label.new()
	main_title_lbl.text = "C I V I T U S"
	main_title_lbl.position = Vector2(0, 230)
	main_title_lbl.size = Vector2(1280, 110)
	main_title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	main_title_lbl.add_theme_font_size_override("font_size", 96)
	main_title_lbl.add_theme_color_override("font_color", Color(1.0, 0.98, 0.94))
	title_card.add_child(main_title_lbl)

	subtitle_lbl = Label.new()
	subtitle_lbl.text = "T H E   U N M I L K Y   W A Y   H O M E"
	subtitle_lbl.position = Vector2(0, 370)
	subtitle_lbl.size = Vector2(1280, 40)
	subtitle_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_lbl.add_theme_font_size_override("font_size", 22)
	subtitle_lbl.add_theme_color_override("font_color", Color(1.0, 0.78, 0.28))
	title_card.add_child(subtitle_lbl)

func _process(_delta: float) -> void:
	var dt = 1.0 / 30.0
	anim_time += dt
	_update_sequence(anim_time, dt)

	var img = get_viewport().get_texture().get_image()
	if img:
		var path = ProjectSettings.globalize_path(frames_dir + ("frame_%04d.png" % frame_count))
		img.save_png(path)

	frame_count += 1
	if frame_count >= max_frames:
		print("[Realistic Linux Intro] All 555 frames captured.")
		get_tree().quit(0)

func _update_sequence(t: float, dt: float) -> void:
	# BEAT 1: 0.0s to 5.8s -> Typing code inside the Linux console
	if t < 5.8:
		black_screen.visible = true
		terminal_window.visible = true
		black_hole_quad.visible = false
		sun_sphere.visible = false
		ship.visible = false

		var typing_p = clamp(t / 5.5, 0.0, 1.0)
		var chars_to_show = int(typing_p * total_code_chars)
		var cursor = "[color=#5af78e]█[/color]" if fmod(t, 0.24) < 0.12 else " "
		
		terminal_rtl.text = prompt_str + code_text_bbcode + cursor
		terminal_rtl.visible_characters = 54 + chars_to_show

	# BEAT 2: 5.8s to 10.5s -> Linux console runs command & displays errors & infinite stream
	elif t < 10.5:
		black_screen.visible = true
		terminal_window.visible = true
		terminal_rtl.visible_characters = -1
		black_hole_quad.visible = false
		sun_sphere.visible = false
		ship.visible = false

		var term_text = prompt_str + code_text_bbcode + "\n\n"
		term_text += "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] godot --headless --script emergency_routine.gd\n"
		term_text += "[color=#a5e179]>> INITIALIZING EMERGENCY RECOVERY SCRIPT EXECUTION...[/color]\n\n"

		if t >= 6.8:
			term_text += "[color=#e5c07b][1/3] query_sagittarius_quantum_relay()...[/color]\n"
			term_text += "[color=#ff5555]>>> [ERR_CONNECTION_TIMEOUT] 0 quantum repeaters in range.[/color]\n"
			term_text += "[color=#ff5555]    Galactic relay network unreachable. Link lost.[/color]\n\n"

		if t >= 7.6:
			term_text += "[color=#e5c07b][2/3] query_hyperspace_propulsion_status()...[/color]\n"
			term_text += "[color=#ff5555]>>> [CRITICAL_MELTDOWN] SCRIPT ERROR: Warp core coils vaporized.[/color]\n"
			term_text += "[color=#ff5555]    Hyperdrive offline. Relativistic jump unavailable.[/color]\n\n"

		if t >= 8.4:
			term_text += "[color=#61afef][3/3] compute_distance_to_supermassive_black_hole()...[/color]\n"
			term_text += "[color=#98c379][OK] TARGET VECTOR SOLVED: GALACTIC CORE SINGULARITY.[/color]\n"
			term_text += "[color=#e5c07b]CALCULATED DISTANCE: [/color]"

			var num_time = t - 8.4
			var digits_count = int(clamp(num_time / 2.0, 0.0, 1.0) * 850)
			var sub_digits = infinite_digits_pool.substr(0, digits_count)
			
			term_text += "[color=#ffb454]" + sub_digits + "... AU[/color]\n\n"
			if num_time > 1.2:
				term_text += "[color=#ff7085]>>> SYSTEM WARNING: INFINITE DISTANCE DETECTED // TRAVEL TIME: UNMEASURABLE[/color]"

		terminal_rtl.text = term_text

	# BEAT 3: 10.5s to 13.0s -> SWITCH TO OTHER VIEW: SUPERMASSIVE BLACK HOLE
	elif t < 13.0:
		var b3_t = t - 10.5
		black_screen.visible = false
		terminal_window.visible = false

		black_hole_quad.visible = true
		sun_sphere.visible = false
		ship.visible = false

		camera.position = Vector3(0, 0, lerp(13.0, 7.0, b3_t / 2.5))
		camera.look_at(Vector3.ZERO, Vector3.UP)
		black_hole_quad.rotation.z += dt * 0.04

	# BEAT 4: 13.0s to 15.5s -> INSIDE CABIN LOOKING AT SUN
	elif t < 15.5:
		var b4_t = t - 13.0
		black_hole_quad.visible = false
		ship.visible = true
		sun_sphere.visible = true
		sun_light.visible = true
		cabin_light.visible = true

		camera.fov = 68.0
		camera.position = Vector3(0.0, 1.83 + sin(b4_t * 1.6) * 0.012, -0.6)
		camera.look_at(Vector3(0.0, 1.96, -4.0), Vector3.UP)
		sun_sphere.rotation.y += dt * 0.08

	# BEAT 5: 15.5s to 18.5s -> CAMERA MOVES TO SUN AND TITLE: THE UNMILKY WAY HOME
	else:
		var b5_t = t - 15.5
		var p5 = b5_t / 3.0

		black_hole_quad.visible = false
		sun_sphere.visible = true
		sun_light.visible = true

		camera.position = Vector3(0.0, lerp(1.85, 3.2, p5), lerp(-0.6, -26.0, p5))
		camera.look_at(sun_sphere.position, Vector3.UP)

		fade_overlay.color = Color(0.0, 0.0, 0.0, clamp((b5_t - 0.5) / 1.5, 0.0, 0.90))

		if b5_t > 0.6:
			var title_p = clamp((b5_t - 0.6) / 1.4, 0.0, 1.0)
			title_card.modulate.a = title_p
