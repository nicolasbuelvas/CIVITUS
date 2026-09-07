extends Node3D
class_name SolarSystemOrbits3D

@onready var orbits_mesh_instance: MeshInstance3D = $OrbitsMesh
@onready var hz_mesh_instance: MeshInstance3D = $HabitableZoneMesh
@onready var planets_container: Node3D = $PlanetsContainer
@onready var star_mesh_instance: MeshInstance3D = $StarCenterMesh

const AU_SCALE: float = 12.0 # 1 AU = 12 meters in 3D solar system view

var system_data: Dictionary = {}
var selected_index: int = 0
var orbit_angles: Array[float] = []

func _ready() -> void:
	# Initialize containers if not created via scene
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
		add_child(star_mesh_instance)

func _process(delta: float) -> void:
	# Animate planets slowly revolving along their orbits (Keplerian: closer = faster)
	if system_data.is_empty():
		return
	var planets = system_data.get("planets", [])
	for i in range(planets.size()):
		if i < orbit_angles.size():
			var r = max(0.2, planets[i].get("orbit_au", 1.0))
			var speed = 0.35 / sqrt(r) # Kepler's 3rd law approximation
			orbit_angles[i] += speed * delta
			var p_node = planets_container.get_node_or_null("PlanetMarker_%d" % i)
			if p_node:
				var dist = r * AU_SCALE
				p_node.position = Vector3(cos(orbit_angles[i]) * dist, 0.0, sin(orbit_angles[i]) * dist)

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

func _build_star_visuals(star_data: Dictionary) -> void:
	var s_col: Color = star_data.get("color", Color(1.0, 0.88, 0.35))
	var s_lum: float = star_data.get("luminosity", 1.0)
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = s_col
	
	var r = clamp(2.0 * sqrt(s_lum), 1.8, 4.5)
	var s_mesh = SphereMesh.new()
	s_mesh.radius = r
	s_mesh.height = r * 2.0
	star_mesh_instance.mesh = s_mesh
	star_mesh_instance.material_override = mat

func _build_habitable_zone(star_data: Dictionary) -> void:
	var hz_in = star_data.get("hz_inner_au", 0.85) * AU_SCALE
	var hz_out = star_data.get("hz_outer_au", 1.65) * AU_SCALE
	
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var segments = 64
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
			col = Color(0.35, 1.0, 0.70, 0.85)
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
	# Clear old markers
	for child in planets_container.get_children():
		child.queue_free()
		
	orbit_angles.clear()
	for i in range(planets.size()):
		var p = planets[i]
		var r = p.get("orbit_au", 1.0) * AU_SCALE
		var start_angle = float(i) * (TAU / max(1.0, float(planets.size()))) + 0.5
		orbit_angles.append(start_angle)
		
		var marker = MeshInstance3D.new()
		marker.name = "PlanetMarker_%d" % i
		var m_mesh = SphereMesh.new()
		var p_size = 0.55 if i == sel_idx else 0.40
		m_mesh.radius = p_size
		m_mesh.height = p_size * 2.0
		marker.mesh = m_mesh
		
		var m_mat = StandardMaterial3D.new()
		m_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m_mat.albedo_color = p.get("surface_color", Color(0.4, 0.8, 1.0))
		marker.material_override = m_mat
		
		marker.position = Vector3(cos(start_angle) * r, 0.0, sin(start_angle) * r)
		planets_container.add_child(marker)
