extends Node

# Render real in-engine planet rotation for Devpost GIF
var max_frames: int = 75 # 3.0 seconds at 25 fps
var frame_count: int = 0
var menu_node: Node = null

func _ready() -> void:
	var menu_scene = load("res://scenes/screens/main_menu.tscn")
	menu_node = menu_scene.instantiate()
	add_child(menu_node)
	
	var menu_layer = menu_node.get_node_or_null("MenuLayer")
	if menu_layer:
		menu_layer.visible = false
		
	var rings = menu_node.get_node_or_null("SubViewportContainer/SubViewport/World3D/PlanetPivot/RingsMesh")
	if rings:
		rings.visible = false # Clean Earth-like planet without rings
		
	# Apply Habitable / Temperate Life Planet parameters
	var planet_mesh = menu_node.get_node_or_null("SubViewportContainer/SubViewport/World3D/PlanetPivot/PlanetMesh")
	if planet_mesh:
		var mat = planet_mesh.get_surface_override_material(0) as ShaderMaterial
		if not mat:
			mat = planet_mesh.material_override as ShaderMaterial
		if mat:
			mat.set_shader_parameter("ocean_color", Color(0.08, 0.42, 0.82))
			mat.set_shader_parameter("shore_color", Color(0.14, 0.62, 0.84))
			mat.set_shader_parameter("beach_color", Color(0.85, 0.78, 0.55))
			mat.set_shader_parameter("land_color", Color(0.22, 0.65, 0.30))
			mat.set_shader_parameter("mountain_color", Color(0.48, 0.42, 0.36))
			mat.set_shader_parameter("peak_color", Color(0.95, 0.98, 1.0))
			mat.set_shader_parameter("atmosphere_color", Color(0.28, 0.72, 1.0))
			mat.set_shader_parameter("cloud_color", Color(1.0, 1.0, 1.0))
			mat.set_shader_parameter("emission_color", Color(0, 0, 0))
			mat.set_shader_parameter("emission_energy", 0.0)
			mat.set_shader_parameter("water_threshold", 0.46)
			mat.set_shader_parameter("mountain_threshold", 0.72)
			mat.set_shader_parameter("peak_threshold", 0.88)
			mat.set_shader_parameter("cloud_density", 0.48)
			mat.set_shader_parameter("cloud_speed", 0.025)
			mat.set_shader_parameter("noise_scale", 2.4)
			mat.set_shader_parameter("seed_offset", 42.0)
			
	var sun = menu_node.get_node_or_null("SubViewportContainer/SubViewport/World3D/SunLight")
	if sun:
		sun.light_energy = 2.0
		sun.light_color = Color(1.0, 0.98, 0.94)

func _process(delta: float) -> void:
	frame_count += 1
	var planet_pivot = menu_node.get_node_or_null("SubViewportContainer/SubViewport/World3D/PlanetPivot")
	if planet_pivot:
		planet_pivot.position = Vector3(0.0, 0.0, 0.0)
		
	var cam = menu_node.get_node_or_null("SubViewportContainer/SubViewport/World3D/Camera3D")
	if cam:
		cam.position = Vector3(0.0, 0.0, 14.8)
		
	var planet_mesh = menu_node.get_node_or_null("SubViewportContainer/SubViewport/World3D/PlanetPivot/PlanetMesh")
	if planet_mesh:
		planet_mesh.rotation.y += (TAU / float(max_frames))
	
	if frame_count >= max_frames:
		print("[Render] Completed ", frame_count, " frames successfully.")
		get_tree().quit(0)
