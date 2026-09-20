extends Node3D

var frame_count: int = 0
var max_frames: int = 1020 # 17.0s @ 60fps
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
	print("[Classic Code Intro] Initializing clean authentic sequence...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	
	if AudioManager:
		AudioManager.stop_music(0.0)
	
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

	# 1. FULLSCREEN TERMINAL
	terminal_window = Control.new()
	terminal_window.position = Vector2.ZERO
	terminal_window.size = Vector2(1280, 720)
	black_screen.add_child(terminal_window)

	var term_bg = ColorRect.new()
	term_bg.position = Vector2.ZERO
	term_bg.size = Vector2(1280, 720)
	term_bg.color = Color(0.04, 0.05, 0.07, 1.0)
	terminal_window.add_child(term_bg)

	terminal_rtl = RichTextLabel.new()
	terminal_rtl.bbcode_enabled = true
	terminal_rtl.scroll_active = false
	terminal_rtl.position = Vector2(28, 24)
	terminal_rtl.size = Vector2(1224, 672)
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
	var dt = 1.0 / 60.0
	anim_time += dt
	_update_sequence(anim_time, dt)

	var img = get_viewport().get_texture().get_image()
	if img:
		if img.get_size() != Vector2i(1280, 720):
			img.resize(1280, 720, Image.INTERPOLATE_BILINEAR)
		var path = ProjectSettings.globalize_path(frames_dir + ("frame_%04d.png" % frame_count))
		img.save_png(path)

	frame_count += 1
	if frame_count >= max_frames:
		print("[Classic Code Intro] All 1020 frames captured.")
		get_tree().quit(0)

func _format_scrolled_terminal(lines: Array[String], max_lines: int = 25) -> String:
	if lines.size() <= max_lines:
		return "\n".join(lines)
	var sliced = lines.slice(lines.size() - max_lines)
	return "\n".join(sliced)

func _update_sequence(t: float, dt: float) -> void:
	# =========================================================================
	# BEAT 1: 0.0s to 11.0s -> CODE & TERMINAL RUN (11.0s)
	# =========================================================================
	if t < 11.0:
		black_screen.visible = true
		terminal_window.visible = true
		black_hole_quad.visible = false
		sun_sphere.visible = false
		ship.visible = false

		# Phase 1A: Typing code normally (0.0s to 5.5s)
		if t < 5.5:
			terminal_rtl.position.y = 24.0
			var typing_p = clamp(t / 5.2, 0.0, 1.0)
			var chars_to_show = int(typing_p * total_code_chars)
			var cursor = "[color=#5af78e]█[/color]" if fmod(t, 0.24) < 0.12 else " "
			terminal_rtl.text = prompt_str + code_text_bbcode + cursor
			terminal_rtl.visible_characters = 54 + chars_to_show

		# Phase 1B: Terminal Execution with Errors & Distance Reveal (5.5s to 11.0s)
		else:
			terminal_rtl.visible_characters = -1
			terminal_rtl.position.y = 24.0

			var lines: Array[String] = []
			lines.append(prompt_str.strip_edges())
			for l in code_text_bbcode.split("\n"):
				lines.append(l)

			lines.append("")
			lines.append("[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] godot --headless --script emergency_routine.gd")
			lines.append("[color=#a5e179]>> INITIALIZING EMERGENCY RECOVERY SCRIPT EXECUTION...[/color]")
			lines.append("")

			if t >= 6.4:
				lines.append("[color=#e5c07b][1/3] query_sagittarius_quantum_relay()...[/color]")
				lines.append("[color=#ff5555]>>> [ERR_CONNECTION_TIMEOUT] 0 quantum repeaters in range.[/color]")
				lines.append("[color=#ff5555]    Galactic relay network unreachable. Link lost.[/color]")
				lines.append("")

			if t >= 7.5:
				lines.append("[color=#e5c07b][2/3] query_hyperspace_propulsion_status()...[/color]")
				lines.append("[color=#ff5555]>>> [CRITICAL_MELTDOWN] SCRIPT ERROR: Warp core coils vaporized.[/color]")
				lines.append("[color=#ff5555]    Hyperdrive offline. Relativistic jump unavailable.[/color]")
				lines.append("")

			if t >= 8.6:
				lines.append("[color=#61afef][3/3] compute_distance_to_supermassive_black_hole()...[/color]")
				lines.append("[color=#98c379][OK] TARGET VECTOR SOLVED: GALACTIC CORE SINGULARITY.[/color]")
				lines.append("[color=#e5c07b]CALCULATED DISTANCE (AU):[/color]")

				var num_time = t - 8.6
				var digits_count = int(clamp(num_time / 2.2, 0.0, 1.0) * 850)
				var sub_digits = infinite_digits_pool.substr(0, digits_count)

				var chunk_size = 85
				for i in range(0, sub_digits.length(), chunk_size):
					var chunk = sub_digits.substr(i, chunk_size)
					if i + chunk_size >= sub_digits.length() and sub_digits.length() > 50:
						lines.append("[color=#ffb454]" + chunk + "... AU[/color]")
					else:
						lines.append("[color=#ffb454]" + chunk + "[/color]")

			terminal_rtl.text = _format_scrolled_terminal(lines, 25)

	# =========================================================================
	# BEAT 2: 11.0s to 13.0s -> SUPERMASSIVE BLACK HOLE (EXACTLY 2.0s)
	# =========================================================================
	elif t < 13.0:
		var b2_t = t - 11.0
		black_screen.visible = false
		terminal_window.visible = false

		black_hole_quad.visible = true
		sun_sphere.visible = false
		ship.visible = false

		camera.position = Vector3(0, 0, lerp(12.0, 6.8, b2_t / 2.0))
		camera.look_at(Vector3.ZERO, Vector3.UP)
		black_hole_quad.rotation.z += dt * 0.05

	# =========================================================================
	# BEAT 3: 13.0s to 17.0s -> FAST WINDOW FLIGHT TO SUN & EXTENDED TITLE (4.0s)
	# =========================================================================
	else:
		var b3_t = t - 13.0
		black_hole_quad.visible = false
		ship.visible = true
		sun_sphere.visible = true
		sun_light.visible = true
		cabin_light.visible = true

		sun_sphere.rotation.y += dt * 0.08

		# Fast forward push out through window (13.0s to 14.5s)
		var p = clamp(b3_t / 1.5, 0.0, 1.0)
		var s_p = p * p * (3.0 - 2.0 * p) # Smoothstep easing

		var start_pos = Vector3(0.0, 1.84, -0.6)
		var end_pos = Vector3(0.8, 2.5, -18.0)
		camera.position = start_pos.lerp(end_pos, s_p)

		var start_look = Vector3(0.0, 1.96, -4.0)
		var end_look = sun_sphere.position
		var cur_look = start_look.lerp(end_look, s_p)
		camera.look_at(cur_look, Vector3.UP)

		# Smooth rapid darkening
		fade_overlay.color = Color(0.0, 0.0, 0.0, clamp(b3_t / 1.4, 0.0, 0.90))

		# Title stays on screen for 2.5 full seconds
		if b3_t > 0.6:
			var title_p = clamp((b3_t - 0.6) / 0.8, 0.0, 1.0)
			title_card.modulate.a = title_p
