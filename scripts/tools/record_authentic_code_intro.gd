extends Node3D

var frame_count: int = 0
var max_frames: int = 1440 # 24.0s @ 60fps
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
var terminal_rtl: RichTextLabel
var fade_overlay: ColorRect
var title_card: Control
var main_title_lbl: Label
var subtitle_lbl: Label

# Authentic Linux Shell Script - NO COMMENTS
var prompt_str: String = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] cat << 'EOF' > emergency_recovery.sh\n"

var bash_script_plain = """#!/usr/bin/env bash

set -e

export SHIP_STATUS="CRITICAL_WARP_CORE_MELTDOWN"
export DRIFT_SECTOR="UNMAPPED_OUTER_VOID"
export EMERGENCY_OXYGEN_RESERVE=100

declare -a SURVIVAL_DIRECTIVES=(
    "SCAN_LOCAL_ORBIT_FOR_HABITABLE_ATMOSPHERE"
    "INITIATE_TOUCHDOWN_ON_TERRESTRIAL_PLANET"
    "EXTRACT_SURFACE_IRON_COPPER_SILICON_URANIUM"
    "FABRICATE_CIRCUITS_AND_REACTOR_CELLS"
    "REBUILD_HYPERDRIVE_PROPULSION_CORE"
    "SOLVE_RETURN_VECTOR_TO_SUPERMASSIVE_BLACK_HOLE"
)

verify_hull_and_containment
ping_sagittarius_quantum_relay
diagnose_warp_coils
calculate_trajectory_home
EOF"""

var bash_script_bbcode = """[color=#ff7085]#!/usr/bin/env bash[/color]

[color=#ff7085]set[/color] -e

[color=#ff7085]export[/color] SHIP_STATUS=[color=#a5e179]"CRITICAL_WARP_CORE_MELTDOWN"[/color]
[color=#ff7085]export[/color] DRIFT_SECTOR=[color=#a5e179]"UNMAPPED_OUTER_VOID"[/color]
[color=#ff7085]export[/color] EMERGENCY_OXYGEN_RESERVE=[color=#67d5ff]100[/color]

[color=#ff7085]declare[/color] -a SURVIVAL_DIRECTIVES=(
    [color=#a5e179]"SCAN_LOCAL_ORBIT_FOR_HABITABLE_ATMOSPHERE"[/color]
    [color=#a5e179]"INITIATE_TOUCHDOWN_ON_TERRESTRIAL_PLANET"[/color]
    [color=#a5e179]"EXTRACT_SURFACE_IRON_COPPER_SILICON_URANIUM"[/color]
    [color=#a5e179]"FABRICATE_CIRCUITS_AND_REACTOR_CELLS"[/color]
    [color=#a5e179]"REBUILD_HYPERDRIVE_PROPULSION_CORE"[/color]
    [color=#a5e179]"SOLVE_RETURN_VECTOR_TO_SUPERMASSIVE_BLACK_HOLE"[/color]
)

[color=#f5c66b]verify_hull_and_containment[/color]
[color=#f5c66b]ping_sagittarius_quantum_relay[/color]
[color=#f5c66b]diagnose_warp_coils[/color]
[color=#f5c66b]calculate_trajectory_home[/color]
[color=#57c7ff]EOF[/color]"""

var total_bash_chars: int = 0
var infinite_digits_pool: String = ""

func _ready() -> void:
	print("[Linux TTY Intro] Initializing 24.0s @ 60 FPS sequence...")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(frames_dir))
	
	total_bash_chars = bash_script_plain.length()
	
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
	# 1. FULLSCREEN LINUX TTY CONSOLE (Entire 1280x720 screen)
	black_screen = ColorRect.new()
	black_screen.set_anchors_preset(Control.PRESET_FULL_RECT)
	black_screen.color = Color(0.05, 0.06, 0.08, 1.0)
	add_child(black_screen)

	# Fullscreen Text Area - NO SCROLLBAR, NO SIDEBAR
	terminal_rtl = RichTextLabel.new()
	terminal_rtl.bbcode_enabled = true
	terminal_rtl.scroll_active = false
	terminal_rtl.position = Vector2(36, 32)
	terminal_rtl.size = Vector2(1208, 656)
	terminal_rtl.add_theme_font_size_override("normal_font_size", 17)
	black_screen.add_child(terminal_rtl)

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
	# Fixed step of 1/60s per frame for 60 FPS silky smooth motion
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
		print("[Linux TTY Intro] All 1440 frames captured.")
		get_tree().quit(0)

func _update_sequence(t: float, dt: float) -> void:
	# =========================================================================
	# BEAT 1: 0.0s to 16.0s -> CODE & TERMINAL (LONGEST BEAT - 16s)
	# =========================================================================
	if t < 16.0:
		black_screen.visible = true
		terminal_rtl.visible = true
		black_hole_quad.visible = false
		sun_sphere.visible = false
		ship.visible = false

		# Phase 1A: Typing bash script calmly (0.0s to 8.5s)
		if t < 8.5:
			var typing_p = clamp(t / 8.0, 0.0, 1.0)
			var chars_to_show = int(typing_p * total_bash_chars)
			var cursor = "[color=#5af78e]█[/color]" if fmod(t, 0.24) < 0.12 else " "
			terminal_rtl.text = prompt_str + bash_script_bbcode + cursor
			terminal_rtl.visible_characters = 54 + chars_to_show

		# Phase 1B: Part 1 Run & Error (8.5s to 10.8s)
		elif t < 10.8:
			terminal_rtl.visible_characters = -1
			if t > 10.6:
				terminal_rtl.text = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] clear"
			else:
				var out = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] bash emergency_recovery.sh --check-relay\n\n"
				out += "[color=#67d5ff]>> [1/3] VERIFYING QUANTUM RELAY HANDSHAKE (relay.unmilkyway.core)...[/color]\n"
				if t >= 9.3:
					out += "[color=#ff5555]>>> [ERR_CONNECTION_TIMEOUT] 0 repeaters in range. Link negotiation failed.[/color]\n"
					out += "[color=#ff5555]    Galactic core communication grid unreachable. Signal lost.[/color]\n\n"
					out += "[color=#ff7085][FAILED] EXIT CODE 1[/color]"
				terminal_rtl.text = out

		# Phase 1C: Part 2 Run & Error (10.8s to 13.0s)
		elif t < 13.0:
			terminal_rtl.visible_characters = -1
			if t > 12.8:
				terminal_rtl.text = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] clear"
			else:
				var out = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] bash emergency_recovery.sh --check-warp\n\n"
				out += "[color=#67d5ff]>> [2/3] DIAGNOSING WARP CORE MAGNETIC CONTAINMENT & COILS...[/color]\n"
				if t >= 11.6:
					out += "[color=#ff5555]>>> [CRITICAL_MELTDOWN] SCRIPT ERROR: Hyperdrive coils vaporized.[/color]\n"
					out += "[color=#ff5555]    Magnetic containment compromised. Relativistic propulsion offline.[/color]\n\n"
					out += "[color=#ff7085][FAILED] EXIT CODE 2[/color]"
				terminal_rtl.text = out

		# Phase 1D: Part 3 Solve Distance & Infinite Stream (13.0s to 16.0s)
		else:
			terminal_rtl.visible_characters = -1
			var out = "[color=#5af78e]astronaut@civitus-cockpit[/color]:[color=#57c7ff]~/systems[/color][color=#f1f1f0]$[/color] bash emergency_recovery.sh --solve-distance\n\n"
			out += "[color=#67d5ff]>> [3/3] SOLVING RELATIVISTIC VECTOR TO SUPERMASSIVE BLACK HOLE...[/color]\n"
			out += "[color=#98c379][OK] VECTOR SOLVED: GALACTIC CORE SINGULARITY (THE UNMILKY WAY).[/color]\n\n"
			out += "[color=#e5c07b]CALCULATED DISTANCE TO HOME: [/color]"

			var num_time = t - 13.3
			var digits_count = int(clamp(num_time / 2.3, 0.0, 1.0) * 850)
			var sub_digits = infinite_digits_pool.substr(0, digits_count)

			out += "[color=#ffb454]" + sub_digits + "... AU[/color]\n\n"
			if num_time > 1.2:
				out += "[color=#ff7085]>>> SYSTEM WARNING: INFINITE DISTANCE DETECTED // TRAVEL TIME: UNMEASURABLE[/color]"

			terminal_rtl.text = out

	# =========================================================================
	# BEAT 2: 16.0s to 19.5s -> SUPERMASSIVE BLACK HOLE (SHORTENED TO 3.5s)
	# =========================================================================
	elif t < 19.5:
		var b2_t = t - 16.0
		black_screen.visible = false
		terminal_rtl.visible = false

		black_hole_quad.visible = true
		sun_sphere.visible = false
		ship.visible = false

		camera.position = Vector3(0, 0, lerp(12.5, 6.8, b2_t / 3.5))
		camera.look_at(Vector3.ZERO, Vector3.UP)
		black_hole_quad.rotation.z += dt * 0.04

	# =========================================================================
	# BEAT 3: 19.5s to 24.0s -> CABIN & ULTRA SMOOTH 60 FPS FORWARD GLIDE (4.5s)
	# =========================================================================
	else:
		var b3_t = t - 19.5
		black_hole_quad.visible = false
		ship.visible = true
		sun_sphere.visible = true
		sun_light.visible = true
		cabin_light.visible = true

		sun_sphere.rotation.y += dt * 0.08

		# Ultra smooth forward camera glide through the window cutout
		var p = clamp(b3_t / 4.4, 0.0, 1.0)
		var s_p = p * p * (3.0 - 2.0 * p) # Smoothstep easing

		# Gentle displacement from cockpit center (Z=-0.6) smoothly floating forward
		var start_pos = Vector3(0.0, 1.84, -0.6)
		var end_pos = Vector3(0.8, 2.5, -14.0)
		camera.position = start_pos.lerp(end_pos, s_p)

		var start_look = Vector3(0.0, 1.96, -4.0)
		var end_look = sun_sphere.position
		var cur_look = start_look.lerp(end_look, s_p)
		camera.look_at(cur_look, Vector3.UP)

		# Smooth progressive background darkening
		fade_overlay.color = Color(0.0, 0.0, 0.0, clamp((b3_t - 1.5) / 1.8, 0.0, 0.90))

		# Smooth title fade-in
		if b3_t > 1.8:
			var title_p = clamp((b3_t - 1.8) / 1.6, 0.0, 1.0)
			title_card.modulate.a = title_p
