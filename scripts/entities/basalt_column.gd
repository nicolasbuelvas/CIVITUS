class_name BasaltColumnFormation
extends Node3D

# Hexagonal Basalt Column Stepped Terrace (Giant's Causeway style)
# Generates clusters of 7 to 12 hexagonal pillars with stepped heights

@export var pillar_count: int = 9
@export var base_radius: float = 1.10
@export var step_height_variance: float = 1.80

func setup_formation(rock_color: Color = Color(0.42, 0.32, 0.28)) -> void:
	# Clear old children if any
	for child in get_children():
		child.queue_free()
		
	var body = StaticBody3D.new()
	body.name = "ColumnCollider"
	add_child(body)
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = rock_color
	mat.roughness = 0.82
	mat.metallic_specular = 0.18
	
	# Hexagonal offsets in local X-Z plane
	var hex_offsets = [
		Vector2(0.0, 0.0),
		Vector2(1.73, 0.0),
		Vector2(-1.73, 0.0),
		Vector2(0.866, 1.5),
		Vector2(-0.866, 1.5),
		Vector2(0.866, -1.5),
		Vector2(-0.866, -1.5),
		Vector2(1.73 * 1.5, 0.75),
		Vector2(-1.73 * 1.5, 0.75),
		Vector2(0.0, 3.0),
		Vector2(0.0, -3.0),
	]
	
	var count = mini(pillar_count, hex_offsets.size())
	for i in range(count):
		var offset = hex_offsets[i] * base_radius * 0.95
		var height = 2.4 + (sin(float(i) * 1.7) * 0.5 + 0.5) * step_height_variance
		
		# Hexagonal prism mesh (Cylinder with 6 sides)
		var cyl_mesh = CylinderMesh.new()
		cyl_mesh.top_radius = base_radius
		cyl_mesh.bottom_radius = base_radius
		cyl_mesh.height = height
		cyl_mesh.radial_segments = 6
		
		var mesh_inst = MeshInstance3D.new()
		mesh_inst.mesh = cyl_mesh
		mesh_inst.material_override = mat
		mesh_inst.position = Vector3(offset.x, height * 0.5, offset.y)
		body.add_child(mesh_inst)
		
		# Solid physical collision
		var col = CollisionShape3D.new()
		var col_shape = CylinderShape3D.new()
		col_shape.radius = base_radius
		col_shape.height = height
		col.shape = col_shape
		col.position = Vector3(offset.x, height * 0.5, offset.y)
		body.add_child(col)
