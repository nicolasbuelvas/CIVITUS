extends CharacterBody3D
class_name AlienCreature

signal creature_damaged(current_hp: float, max_hp: float)
signal creature_died(loot_dict: Dictionary)
signal creature_fed(reward_item: String)

@export var max_health: float = 65.0
@export var is_aggressive: bool = false
@export var speed: float = 3.6

var current_health: float = 65.0
var is_dead: bool = false
var planet_radius: float = 160.0
var target_player: CharacterBody3D = null

var loot_item_defeat: String = "alien_chitin"
var loot_item_friendly: String = "biogel_sample"
var creature_color: Color = Color(0.35, 0.75, 0.45)

# Mesh node references for articulated procedural animations
@onready var body_mesh: MeshInstance3D = get_node_or_null("Visuals/Thorax")
@onready var head_mesh: MeshInstance3D = get_node_or_null("Visuals/Head")
@onready var eye_l: MeshInstance3D = get_node_or_null("Visuals/Head/EyeL")
@onready var eye_r: MeshInstance3D = get_node_or_null("Visuals/Head/EyeR")
@onready var mandible_l: MeshInstance3D = get_node_or_null("Visuals/Head/MandibleL")
@onready var mandible_r: MeshInstance3D = get_node_or_null("Visuals/Head/MandibleR")

@onready var leg_fl: Node3D = get_node_or_null("Visuals/LegFL")
@onready var leg_fr: Node3D = get_node_or_null("Visuals/LegFR")
@onready var leg_rl: Node3D = get_node_or_null("Visuals/LegRL")
@onready var leg_rr: Node3D = get_node_or_null("Visuals/LegRR")
@onready var col_shape: CollisionShape3D = get_node_or_null("CollisionShape3D")

var walk_cycle: float = 0.0
var wander_timer: float = 0.0
var wander_tangent: Vector3 = Vector3.FORWARD
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("creatures")
	add_to_group("interactable")
	current_health = max_health

func setup_creature(planet_params: Dictionary, aggressive: bool = false) -> void:
	is_aggressive = aggressive
	var p_type = planet_params.get("type", "Habitable")
	var lvl = planet_params.get("level", 1)
	
	if p_type.contains("Volcan") or p_type.contains("Lava"):
		creature_color = Color(0.95, 0.35, 0.12)
		loot_item_defeat = "magma_carapace"
		loot_item_friendly = "pyro_crystal"
		max_health = 80.0 + lvl * 15.0
		speed = 4.2
	elif p_type.contains("Toxic") or p_type.contains("Acido"):
		creature_color = Color(0.45, 0.85, 0.20)
		loot_item_defeat = "toxic_gland"
		loot_item_friendly = "corrosive_filter"
		max_health = 65.0 + lvl * 10.0
		speed = 3.8
	elif p_type.contains("Cryo") or p_type.contains("Hielo"):
		creature_color = Color(0.30, 0.75, 0.95)
		loot_item_defeat = "cryo_scale"
		loot_item_friendly = "permafrost_sample"
		max_health = 60.0 + lvl * 10.0
		speed = 3.4
	else:
		creature_color = Color(0.32, 0.76, 0.42) if not aggressive else Color(0.88, 0.28, 0.22)
		loot_item_defeat = "alien_chitin"
		loot_item_friendly = "biogel_sample"
		max_health = 50.0 + lvl * 8.0
		speed = 3.6
		
	current_health = max_health
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = creature_color
	mat.roughness = 0.55
	mat.metallic = 0.35
	if is_aggressive:
		mat.emission_enabled = true
		mat.emission = creature_color * 0.35
	if body_mesh:
		body_mesh.material_override = mat

func _physics_process(delta: float) -> void:
	if is_dead:
		return
		
	var pos = global_position
	var up_dir = pos.normalized()
	if pos.length() < 0.01:
		up_dir = Vector3.UP
		
	# 1. Radial Planetary Gravity
	var gravity_accel = -up_dir * 12.0
	velocity += gravity_accel * delta
	
	# 2. AI Behavior & Sensing
	if not is_instance_valid(target_player):
		var pl = get_tree().get_first_node_in_group("player")
		if pl is CharacterBody3D:
			target_player = pl
			
	var desired_tangent = Vector3.ZERO
	if is_instance_valid(target_player):
		var p_pos = target_player.global_position
		var to_player = p_pos - pos
		var dist_to_player = to_player.length()
		var tangent_to_player = (to_player - up_dir * to_player.dot(up_dir)).normalized()
		
		if is_aggressive:
			# Stalk player if within detection radius
			if dist_to_player < 16.0:
				desired_tangent = tangent_to_player
				if dist_to_player < 2.2:
					_perform_attack(delta)
			else:
				desired_tangent = _get_wander_tangent(up_dir, delta)
		else:
			# Peaceful: Flee if player sprints close (< 5.0m)
			if dist_to_player < 5.0:
				desired_tangent = -tangent_to_player
			else:
				desired_tangent = _get_wander_tangent(up_dir, delta)
	else:
		desired_tangent = _get_wander_tangent(up_dir, delta)
		
	# 3. Horizontal Movement & Tangent Orientation
	var is_moving = desired_tangent.length_squared() > 0.01
	if is_moving:
		var target_vel = desired_tangent * speed
		var v_vertical = up_dir * velocity.dot(up_dir)
		velocity = v_vertical + target_vel
		
		var forward = desired_tangent.normalized()
		var right = up_dir.cross(forward).normalized()
		global_transform.basis = Basis(right, up_dir, -forward).orthonormalized()
		
		# 4. Articulated Quadruped Leg Stepping Animation
		walk_cycle += delta * speed * 3.5
		var step_l = sin(walk_cycle) * 0.45
		var step_r = -step_l
		if leg_fl: leg_fl.rotation.x = step_l
		if leg_rr: leg_rr.rotation.x = step_l
		if leg_fr: leg_fr.rotation.x = step_r
		if leg_rl: leg_rl.rotation.x = step_r
		
		if body_mesh:
			body_mesh.position.y = 0.45 + absf(sin(walk_cycle)) * 0.06
		if mandible_l: mandible_l.rotation.y = sin(walk_cycle * 1.5) * 0.25
		if mandible_r: mandible_r.rotation.y = -sin(walk_cycle * 1.5) * 0.25
	else:
		var v_vertical = up_dir * velocity.dot(up_dir)
		velocity = v_vertical
		walk_cycle += delta * 1.2
		if body_mesh:
			body_mesh.position.y = 0.45 + sin(walk_cycle) * 0.02
		if leg_fl: leg_fl.rotation.x = lerp_angle(leg_fl.rotation.x, 0.0, delta * 8.0)
		if leg_fr: leg_fr.rotation.x = lerp_angle(leg_fr.rotation.x, 0.0, delta * 8.0)
		if leg_rl: leg_rl.rotation.x = lerp_angle(leg_rl.rotation.x, 0.0, delta * 8.0)
		if leg_rr: leg_rr.rotation.x = lerp_angle(leg_rr.rotation.x, 0.0, delta * 8.0)
		
	up_direction = up_dir
	move_and_slide()

func _get_wander_tangent(up_dir: Vector3, delta: float) -> Vector3:
	wander_timer -= delta
	if wander_timer <= 0.0:
		wander_timer = randf_range(3.5, 8.0)
		var rand_vec = Vector3(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
		wander_tangent = (rand_vec - up_dir * rand_vec.dot(up_dir)).normalized()
	return wander_tangent

func _perform_attack(delta: float) -> void:
	attack_cooldown -= delta
	if attack_cooldown <= 0.0:
		attack_cooldown = 1.3
		AudioManager.play("thruster", 1.4, -4.0)
		
		var tw = create_tween()
		tw.tween_property(self, "position", position + -global_transform.basis.z * 0.6, 0.18)
		tw.tween_property(self, "position", position, 0.25)
		
		GameManager.player_stats.hull = maxf(0.0, GameManager.player_stats.hull - 15.0)
		GameManager.player_vital_updated.emit("hull", GameManager.player_stats.hull, 100.0)

func take_damage(dmg: float) -> Dictionary:
	if is_dead:
		return {}
		
	current_health = maxf(0.0, current_health - dmg)
	creature_damaged.emit(current_health, max_health)
	AudioManager.play("mine", 1.3, 0.0)
	
	if body_mesh and body_mesh.material_override is StandardMaterial3D:
		var m = body_mesh.material_override as StandardMaterial3D
		m.albedo_color = Color.WHITE
		get_tree().create_timer(0.08).timeout.connect(func(): if is_instance_valid(m): m.albedo_color = creature_color)
	
	if current_health <= 0.0:
		return _die()
	return {}

func feed_creature(_food_item: String = "fiber") -> String:
	if is_dead or is_aggressive:
		return ""
	AudioManager.play("collect", 1.2, 0.0)
	creature_fed.emit(loot_item_friendly)
	GameManager.crafting.add_resource("uranium", 1)
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector3(1.15, 1.15, 1.15), 0.2)
	tw.tween_property(self, "scale", Vector3.ONE, 0.2)
	return loot_item_friendly

func _die() -> Dictionary:
	is_dead = true
	velocity = Vector3.ZERO
	if col_shape:
		col_shape.set_deferred("disabled", true)
		
	var tw = create_tween().set_parallel(true)
	tw.tween_property(self, "scale", Vector3(1.2, 0.3, 1.2), 0.35).set_trans(Tween.TRANS_BOUNCE)
	if leg_fl: tw.tween_property(leg_fl, "rotation:z", 1.2, 0.3)
	if leg_fr: tw.tween_property(leg_fr, "rotation:z", -1.2, 0.3)
	if leg_rl: tw.tween_property(leg_rl, "rotation:z", 1.2, 0.3)
	if leg_rr: tw.tween_property(leg_rr, "rotation:z", -1.2, 0.3)
	
	var loot = {
		"item": loot_item_defeat,
		"amount": 2
	}
	creature_died.emit(loot)
	AudioManager.play("collect", 0.9, 2.0)
	
	GameManager.crafting.add_resource("iron", 2)
	GameManager.crafting.add_resource("copper", 1)
	
	tw.chain().tween_interval(4.0)
	tw.chain().tween_callback(queue_free)
	return loot
