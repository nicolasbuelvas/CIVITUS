extends Node3D
class_name SolarSystemOrbits3D

signal planet_clicked(index: int)

const StarShader = preload("res://assets/shaders/star_sun.gdshader")
const PlanetShader = preload("res://assets/shaders/planet_sphere.gdshader")
const RingsShader = preload("res://assets/shaders/planet_rings.gdshader")

var orbits_mesh_instance: MeshInstance3D = null
var hz_mesh_instance: MeshInstance3D = null
var planets_container: Node3D = null
var star_mesh_instance: MeshInstance3D = null

const AU_SCALE: float = 12.0 # 1 AU = 12 meters in 3D solar system view

var system_data: Dictionary = {}
var selected_index: int = 0
var orbit_angles: Array[float] = []
var planet_markers: Array[Node3D] = []

func _ready() -> void:
	if not orbits_mesh_instance:
		orbits_mesh_instance = MeshInstance3D.new()
		add_child(orbits_mesh_instance)
	if not hz_mesh_instance:
		hz_mesh_instance = MeshInstance3D.new()
		add_child(hz_mesh_instance)
	if not planets_container:
		planets_container = Node3D.new()
		add_child(planets_container)
	if not star_mesh_instance:
		star_mesh_instance = MeshInstance3D.new()
		var s_mesh = SphereMesh.new()
		s_mesh.radius = 2.8
		s_mesh.height = 5.6
		star_mesh_instance.mesh = s_mesh
		star_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(star_mesh_instance)

func _process(delta: float) -> void:
	# Continuous, uninterrupted Keplerian orbital revolution
	if system_data.is_empty():
		return
	var planets = system_data.get("planets", [])
	for i in range(planets.size()):
		if i < orbit_angles.size() and i < planet_markers.size():
			var r = max(0.2, planets[i].get("orbit_au", 1.0))
			var speed = 0.28 / sqrt(r)
			orbit_angles[i] += speed * delta
			var p_node = planet_markers[i]
			if is_instance_valid(p_node):
				var dist = r * AU_SCALE
				p_node.position = Vector3(cos(orbit_angles[i]) * dist, 0.0, sin(orbit_angles[i]) * dist)
				var sphere_node = p_node.get_node_or_null("PlanetSphere")
				if sphere_node:
					sphere_node.rotation.y += delta * 0.25

	if is_instance_valid(star_mesh_instance):
		var disk = star_mesh_instance.get_node_or_null("AccretionDisk")
		if is_instance_valid(disk):
			disk.rotation.y += delta * 1.6

func setup_system(sys: Dictionary, sel_idx: int = 0) -> void:
	system_data = sys
	selected_index = sel_idx
	
	_build_star_visuals(sys.get("star", {}))
	_build_habitable_zone(sys.get("star", {}))
	_build_orbit_lines(sys.get("planets", []), sel_idx)
	_build_planet_markers(sys.get("planets", []), sel_idx)

func set_selected_planet(sel_idx: int) -> void:
	selected_index = sel_idx
	if not system_data.is_empty():
		_build_orbit_lines(system_data.get("planets", []), sel_idx)
		_update_selection_halo(sel_idx)

func _update_selection_halo(sel_idx: int) -> void:
	for i in range(planet_markers.size()):
		var marker = planet_markers[i]
		if is_instance_valid(marker):
			var halo = marker.get_node_or_null("SelectionRing")
			if halo:
				halo.visible = (i == sel_idx)

func _build_star_visuals(star_data: Dictionary) -> void:
	# Clear previous black hole accretion accessories if any
	for child in star_mesh_instance.get_children():
		child.queue_free()

	if star_data.get("is_black_hole", false):
		# 1. Gargantua Black Hole Event Horizon (Completely black, unshaded)
		var eh_radius = float(star_data.get("event_horizon_radius", 2.2))
		var s_mesh = SphereMesh.new()
		s_mesh.radius = eh_radius
		s_mesh.height = eh_radius * 2.0
		s_mesh.radial_segments = 48
		s_mesh.rings = 24
		star_mesh_instance.mesh = s_mesh
		
		var bh_mat = StandardMaterial3D.new()
		bh_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		bh_mat.albedo_color = Color(0.005, 0.005, 0.01, 1.0)
		star_mesh_instance.material_override = bh_mat
		star_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		
		# 2. Photon Sphere (Luminous gravitational lensing shell)
		var ps_mesh_inst = MeshInstance3D.new()
		ps_mesh_inst.name = "PhotonSphere"
		var ps_radius = float(star_data.get("photon_sphere_radius", 3.0))
		var ps_mesh = SphereMesh.new()
		ps_mesh.radius = ps_radius
		ps_mesh.height = ps_radius * 2.0
		ps_mesh_inst.mesh = ps_mesh
		var ps_mat = StandardMaterial3D.new()
		ps_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		ps_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		ps_mat.albedo_color = Color(1.0, 0.92, 0.70, 0.45)
		ps_mesh_inst.material_override = ps_mat
		star_mesh_instance.add_child(ps_mesh_inst)
		
		# 3. Relativistic Glowing Accretion Disk
		var disk_mesh_inst = MeshInstance3D.new()
		disk_mesh_inst.name = "AccretionDisk"
		var disk_mesh = TorusMesh.new()
		disk_mesh.inner_radius = float(star_data.get("accretion_inner_radius", 3.5))
		disk_mesh.outer_radius = float(star_data.get("accretion_outer_radius", 11.5))
		disk_mesh.rings = 64
		disk_mesh.ring_segments = 32
		disk_mesh_inst.mesh = disk_mesh
		var disk_mat = StandardMaterial3D.new()
		disk_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		disk_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		disk_mat.albedo_color = Color(1.0, 0.68, 0.18, 0.92)
		disk_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		disk_mesh_inst.material_override = disk_mat
		star_mesh_instance.add_child(disk_mesh_inst)
		return

	var s_col: Color = star_data.get("color", Color(1.0, 0.88, 0.35))
	var s_lum: float = star_data.get("luminosity", 1.0)
	
	var mat = ShaderMaterial.new()
	mat.shader = StarShader
	mat.set_shader_parameter("star_color", s_col)
	mat.set_shader_parameter("core_color", Color(1.0, 0.98, 0.94))
	mat.set_shader_parameter("corona_color", s_col.lerp(Color(1.0, 0.35, 0.1), 0.55))
	mat.set_shader_parameter("flare_speed", 0.08)
	mat.set_shader_parameter("turbulent_scale", 4.0)
	mat.set_shader_parameter("corona_intensity", 2.2)
	mat.set_shader_parameter("pulse_rate", 0.4)
	
	var r = clamp(2.4 * sqrt(s_lum), 2.2, 5.2)
	var s_mesh = SphereMesh.new()
	s_mesh.radius = r
	s_mesh.height = r * 2.0
	s_mesh.radial_segments = 48
	s_mesh.rings = 24
	star_mesh_instance.mesh = s_mesh
	star_mesh_instance.material_override = mat
	star_mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

func _build_habitable_zone(star_data: Dictionary) -> void:
	var hz_in = star_data.get("hz_inner_au", 0.85) * AU_SCALE
	var hz_out = star_data.get("hz_outer_au", 1.65) * AU_SCALE
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var segments = 72
	var hz_color = Color(0.2, 0.9, 0.45, 0.09)
	st.set_color(hz_color)
	
	for i in range(segments + 1):
		var a = (float(i) / float(segments)) * TAU
		var ca = cos(a)
		var sa = sin(a)
		st.add_vertex(Vector3(ca * hz_in, -0.05, sa * hz_in))
		st.add_vertex(Vector3(ca * hz_out, -0.05, sa * hz_out))
		
	var mesh = st.commit()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = hz_color
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	hz_mesh_instance.mesh = mesh
	hz_mesh_instance.material_override = mat

func _build_orbit_lines(planets: Array, sel_idx: int) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_LINES)
	
	var segments = 72
	for p_i in range(planets.size()):
		var p = planets[p_i]
		var r = p.get("orbit_au", 1.0) * AU_SCALE
		var is_sel = (p_i == sel_idx)
		
		var col: Color
		if is_sel:
			col = Color(0.35, 1.0, 0.70, 0.90)
		else:
			col = Color(0.30, 0.65, 0.95, 0.28)
			
		st.set_color(col)
		for j in range(segments):
			var a1 = (float(j) / float(segments)) * TAU
			var a2 = (float(j + 1) / float(segments)) * TAU
			st.add_vertex(Vector3(cos(a1) * r, 0.0, sin(a1) * r))
			st.add_vertex(Vector3(cos(a2) * r, 0.0, sin(a2) * r))
			
	var mesh = st.commit()
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	orbits_mesh_instance.mesh = mesh
	orbits_mesh_instance.material_override = mat

func _build_planet_markers(planets: Array, sel_idx: int) -> void:
	for child in planets_container.get_children():
		planets_container.remove_child(child)
		child.queue_free()
	planet_markers.clear()
		
	var preserve_angles = (orbit_angles.size() == planets.size())
	if not preserve_angles:
		orbit_angles.clear()
		
	for i in range(planets.size()):
		var p = planets[i]
		var r = p.get("orbit_au", 1.0) * AU_SCALE
		var cur_angle = 0.0
		if preserve_angles:
			cur_angle = orbit_angles[i]
		else:
			cur_angle = p.get("orbit_angle", float(i) * (TAU / max(1.0, float(planets.size()))) + 0.5)
			orbit_angles.append(cur_angle)
		
		var marker_root = Node3D.new()
		marker_root.name = "PlanetMarker_%d" % i
		
		var is_sel = (i == sel_idx)
		# Scaled up for crystal-clear mobile visibility
		var p_size = 1.25 if not is_sel else 1.55
		
		# 1. Procedural 3D Miniature Planet Sphere
		var sphere_inst = MeshInstance3D.new()
		sphere_inst.name = "PlanetSphere"
		var s_mesh = SphereMesh.new()
		s_mesh.radius = p_size
		s_mesh.height = p_size * 2.0
		s_mesh.radial_segments = 32
		s_mesh.rings = 16
		sphere_inst.mesh = s_mesh
		
		var p_mat = ShaderMaterial.new()
		p_mat.shader = PlanetShader
		p_mat.set_shader_parameter("ocean_color", p.get("ocean_color", Color(0.04, 0.22, 0.55)))
		p_mat.set_shader_parameter("shore_color", p.get("shore_color", Color(0.12, 0.45, 0.70)))
		p_mat.set_shader_parameter("beach_color", p.get("beach_color", Color(0.76, 0.70, 0.50)))
		p_mat.set_shader_parameter("land_color", p.get("land_color", Color(0.20, 0.52, 0.25)))
		p_mat.set_shader_parameter("mountain_color", p.get("mountain_color", Color(0.45, 0.40, 0.35)))
		p_mat.set_shader_parameter("peak_color", p.get("peak_color", Color(0.92, 0.95, 1.0)))
		p_mat.set_shader_parameter("atmosphere_color", p.get("atmosphere_color", Color(0.30, 0.70, 1.0)))
		p_mat.set_shader_parameter("water_threshold", p.get("water_threshold", 0.48))
		p_mat.set_shader_parameter("cloud_density", p.get("cloud_density", 0.50))
		p_mat.set_shader_parameter("cloud_speed", 0.04)
		p_mat.set_shader_parameter("emission_energy", p.get("emission_energy", 0.0))
		p_mat.set_shader_parameter("emission_color", p.get("emission_color", Color.BLACK))
		sphere_inst.material_override = p_mat
		marker_root.add_child(sphere_inst)
		
		# 2. Miniature Planetary Rings (if present)
		if p.get("has_rings", false):
			var ring_inst = MeshInstance3D.new()
			var q_mesh = QuadMesh.new()
			var r_span = p_size * 4.4
			q_mesh.size = Vector2(r_span, r_span)
			q_mesh.orientation = PlaneMesh.FACE_Y
			ring_inst.mesh = q_mesh
			
			var ring_mat = ShaderMaterial.new()
			ring_mat.shader = RingsShader
			ring_mat.set_shader_parameter("ring_color", p.get("ring_color", Color(0.85, 0.85, 0.95)))
			ring_inst.material_override = ring_mat
			marker_root.add_child(ring_inst)
			
		# 3. Selected Target Beacon Halo (Persistent toggle)
		var sel_ring = MeshInstance3D.new()
		sel_ring.name = "SelectionRing"
		var t_mesh = TorusMesh.new()
		t_mesh.inner_radius = p_size * 1.35
		t_mesh.outer_radius = p_size * 1.65
		t_mesh.rings = 32
		t_mesh.ring_segments = 16
		sel_ring.mesh = t_mesh
		
		var r_mat = StandardMaterial3D.new()
		r_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		r_mat.albedo_color = Color(0.35, 1.0, 0.75, 0.95)
		sel_ring.material_override = r_mat
		sel_ring.visible = is_sel
		marker_root.add_child(sel_ring)
		
		# 4. Large Mobile Touch & Click Hitbox (Area3D)
		var area = Area3D.new()
		area.name = "TouchArea"
		var col = CollisionShape3D.new()
		var shape = SphereShape3D.new()
		shape.radius = 4.5 # Extra generous touch area for mobile taps
		col.shape = shape
		area.add_child(col)
		area.input_event.connect(_on_area_input_event.bind(i))
		marker_root.add_child(area)
		
		marker_root.position = Vector3(cos(cur_angle) * r, 0.0, sin(cur_angle) * r)
		planets_container.add_child(marker_root)
		planet_markers.append(marker_root)

func _on_area_input_event(_camera: Camera3D, event: InputEvent, _position: Vector3, _normal: Vector3, _shape_idx: int, planet_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		planet_clicked.emit(planet_idx)
	elif event is InputEventScreenTouch and event.pressed:
		planet_clicked.emit(planet_idx)

func get_planet_position(idx: int) -> Vector3:
	if idx >= 0 and idx < planet_markers.size():
		var p_node = planet_markers[idx]
		if is_instance_valid(p_node):
			return p_node.global_position
	return Vector3.ZERO
