extends RefCounted
class_name CraftingSystem

signal inventory_changed()
signal storage_changed()
signal body_slots_changed()
signal inventory_full(item_name: String)
signal hyperdrive_repaired(part_name: String)
signal hyperdrive_ready()

const MAX_STACK_RESOURCE: int = 10
const MAX_STACK_TOOL: int = 1

# Total summary inventory (for backward compatibility and fast lookups)
var inventory: Dictionary = {
	"iron": 0,
	"copper": 0,
	"silicon": 0,
	"uranium": 0,
	"wrench": 0,
	"wire": 0,
	"microchip": 0,
	"reactor_cell": 0,
	"hull_plate": 0,
	"nozzle_core": 0,
	"hyperdrive_coil": 0,
	"o2_filter": 0,
	"energy_cell": 0,
	"repair_kit_basic": 0,
	"repair_kit_advanced": 0,
	"o2_canister": 0,
	"suit_sealant": 0,
	"plasma_cutter": 0,
	"alien_meat": 0,
	"alien_chitin": 0,
	"alien_fang": 0,
	"biogel_sample": 0,
	"cooked_ration": 0,
	"chitin_spear": 0,
	"bio_medkit": 0,
	"chitin_plate": 0,
	"plant_fibers": 0,
	"ocean_pearl": 0,
	"pearl": 0,
	"suit_plating": 0,
	"plasma_lens": 0,
	"sealant_paste": 0,
	"bio_fuel": 0,
	"hyperdrive_catalyst": 0,
	"laser_pistol": 0
}

# Astronaut Physical Body Attachment Slots:
# The astronaut can carry items on Hands (2) or Suit Hooks (4 on Back)!
# 6 physical attachment points:
# - hand_left  : Left Hand
# - hand_right : Right Hand
# - back_1     : Upper Left Backpack Mount
# - back_2     : Upper Right Backpack Mount
# - back_3     : Lower Left Backpack Mount
# - back_4     : Lower Right Backpack Mount
var body_slots: Dictionary = {
	"hand_left": {"item": "", "count": 0},
	"hand_right": {"item": "", "count": 0},
	"back_1": {"item": "", "count": 0},
	"back_2": {"item": "", "count": 0}
}

const ALL_BODY_SLOTS: Array = ["hand_right", "hand_left", "back_1", "back_2"]

# Ship Storage Bin (Waste of Space cabin cargo container)
var ship_storage: Dictionary = {
	"iron": 0,
	"copper": 0,
	"silicon": 0,
	"uranium": 0,
	"wrench": 0,
	"wire": 0,
	"microchip": 0,
	"reactor_cell": 0,
	"hull_plate": 0,
	"nozzle_core": 0,
	"hyperdrive_coil": 0,
	"o2_filter": 0,
	"energy_cell": 0,
	"repair_kit_basic": 0,
	"repair_kit_advanced": 0,
	"o2_canister": 0,
	"suit_sealant": 0,
	"plasma_cutter": 0,
	"alien_meat": 0,
	"alien_chitin": 0,
	"alien_fang": 0,
	"biogel_sample": 0,
	"cooked_ration": 0,
	"chitin_spear": 0,
	"bio_medkit": 0,
	"chitin_plate": 0,
	"plant_fibers": 0,
	"ocean_pearl": 0,
	"pearl": 0,
	"suit_plating": 0,
	"plasma_lens": 0,
	"sealant_paste": 0,
	"bio_fuel": 0,
	"hyperdrive_catalyst": 0,
	"laser_pistol": 0
}

# Hyperdrive requirements per level
var hyperdrive_requirements: Dictionary = {}
var installed_parts: Dictionary = {}

func init_level_requirements(difficulty: int) -> void:
	installed_parts.clear()
	match difficulty:
		0, 1:
			hyperdrive_requirements = {
				"wrench": 1,
				"wire": 2,
				"uranium": 10
			}
		2:
			hyperdrive_requirements = {
				"wrench": 1,
				"wire": 4,
				"microchip": 2,
				"uranium": 20
			}
		3:
			hyperdrive_requirements = {
				"wrench": 1,
				"wire": 6,
				"microchip": 4,
				"reactor_cell": 1,
				"uranium": 35
			}
		_: # 4 and 5 (Hardcore)
			hyperdrive_requirements = {
				"wrench": 2,
				"wire": 8,
				"microchip": 6,
				"reactor_cell": 2,
				"uranium": 50
			}
	for k in hyperdrive_requirements.keys():
		installed_parts[k] = 0

func get_max_stack(item: String) -> int:
	match item:
		"laser_pistol", "wrench", "microchip", "reactor_cell", "hull_plate", "nozzle_core", "hyperdrive_coil", "o2_filter", "energy_cell", "repair_kit_basic", "repair_kit_advanced", "o2_canister", "suit_sealant", "plasma_cutter", "chitin_spear", "bio_medkit", "chitin_plate", "suit_plating", "plasma_lens", "hyperdrive_catalyst":
			return MAX_STACK_TOOL
		_:
			return MAX_STACK_RESOURCE

# ===================================================
# ASTRONAUT BODY SLOTS & RESOURCE COLLECTION
# ===================================================
func get_body_slot(slot_name: String) -> Dictionary:
	return body_slots.get(slot_name, {"item": "", "count": 0})

func can_astronaut_carry(res_name: String, amount: int = 1) -> bool:
	var max_s = get_max_stack(res_name)
	var needed = amount
	
	# Check matching existing slots first
	for s_key in ALL_BODY_SLOTS:
		if not body_slots.has(s_key): continue
		var s = body_slots[s_key]
		if s["item"] == res_name and s["count"] < max_s:
			needed -= (max_s - s["count"])
			if needed <= 0:
				return true
				
	# Check empty slots
	for s_key in ALL_BODY_SLOTS:
		if not body_slots.has(s_key): continue
		var s = body_slots[s_key]
		if s["item"] == "" or s["count"] <= 0:
			needed -= max_s
			if needed <= 0:
				return true
				
	return false

func add_resource(res_name: String, amount: int = 1) -> void:
	if not inventory.has(res_name) or amount <= 0:
		return
		
	var remaining = amount
	var max_s = get_max_stack(res_name)
	
	# 1. First add to existing matching body slots
	for s_key in ALL_BODY_SLOTS:
		if not body_slots.has(s_key): continue
		var s = body_slots[s_key]
		if s["item"] == res_name and s["count"] < max_s:
			var space = max_s - s["count"]
			var to_add = mini(remaining, space)
			s["count"] += to_add
			remaining -= to_add
			if remaining <= 0:
				break
				
	# 2. Fill empty body slots next
	if remaining > 0:
		for s_key in ALL_BODY_SLOTS:
			if not body_slots.has(s_key): continue
			var s = body_slots[s_key]
			if s["item"] == "" or s["count"] <= 0:
				var to_add = mini(remaining, max_s)
				s["item"] = res_name
				s["count"] = to_add
				remaining -= to_add
				if remaining <= 0:
					break
					
	# If body slots were full and could not take all:
	if remaining > 0:
		inventory_full.emit(res_name)
		
	# Synchronize summary inventory dict
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	body_slots_changed.emit()

func _recalculate_inventory_from_body() -> void:
	for k in inventory.keys():
		inventory[k] = 0
	for s_key in body_slots.keys():
		var s = body_slots[s_key]
		if s["item"] != "" and s["count"] > 0 and inventory.has(s["item"]):
			inventory[s["item"]] += s["count"]

func reset_inventory() -> void:
	for k in inventory.keys():
		inventory[k] = 0
	for s_key in ALL_BODY_SLOTS:
		if body_slots.has(s_key):
			body_slots[s_key] = {"item": "", "count": 0}
	ship_storage.clear()
	installed_parts.clear()
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()

func sync_body_from_inventory() -> void:
	# Calculate total currently held in body slots
	var body_counts: Dictionary = {}
	for s in body_slots.values():
		if s["item"] != "" and s["count"] > 0:
			body_counts[s["item"]] = body_counts.get(s["item"], 0) + s["count"]
			
	# For any item where inventory has more than body, distribute into empty body slots or ship storage
	for item in inventory.keys():
		var diff = inventory[item] - body_counts.get(item, 0)
		while diff > 0:
			var max_s = get_max_stack(item)
			var placed = false
			# Try existing matching slot
			for s_key in ALL_BODY_SLOTS:
				if not body_slots.has(s_key): continue
				var s = body_slots[s_key]
				if s["item"] == item and s["count"] < max_s:
					var take = mini(diff, max_s - s["count"])
					s["count"] += take
					diff -= take
					placed = true
					break
			if not placed:
				# Try empty slot
				for s_key in ALL_BODY_SLOTS:
					if not body_slots.has(s_key): continue
					var s = body_slots[s_key]
					if s["item"] == "" or s["count"] <= 0:
						var take = mini(diff, max_s)
						s["item"] = item
						s["count"] = take
						diff -= take
						placed = true
						break
			if not placed:
				# Put remainder into ship storage
				ship_storage[item] = ship_storage.get(item, 0) + diff
				diff = 0
				break
	_recalculate_inventory_from_body()
	body_slots_changed.emit()

func set_body_slot(slot_name: String, item: String, count: int) -> void:
	if not body_slots.has(slot_name):
		return
	if count <= 0 or item == "":
		body_slots[slot_name] = {"item": "", "count": 0}
	else:
		body_slots[slot_name] = {"item": item, "count": count}
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	body_slots_changed.emit()

func swap_body_slots(slot_a: String, slot_b: String) -> void:
	if not body_slots.has(slot_a) or not body_slots.has(slot_b):
		return
	var temp = body_slots[slot_a].duplicate()
	body_slots[slot_a] = body_slots[slot_b].duplicate()
	body_slots[slot_b] = temp
	body_slots_changed.emit()

# ===================================================
# DRAG & DROP / STORAGE TRANSFER LOGIC
# ===================================================
func deposit_body_slot_to_storage(slot_name: String) -> bool:
	if not body_slots.has(slot_name):
		return false
	var s = body_slots[slot_name]
	if s["item"] == "" or s["count"] <= 0:
		return false
		
	var item = s["item"]
	var count = s["count"]
	ship_storage[item] = ship_storage.get(item, 0) + count
	body_slots[slot_name] = {"item": "", "count": 0}
	
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
	return true

func drop_body_slot(slot_name: String) -> Dictionary:
	if not body_slots.has(slot_name):
		return {}
	var s = body_slots[slot_name]
	if s["item"] == "" or s["count"] <= 0:
		return {}
	var dropped_data = {"item": s["item"], "count": s["count"]}
	body_slots[slot_name] = {"item": "", "count": 0}
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	body_slots_changed.emit()
	return dropped_data

func drop_storage_item(item_name: String, count: int = 1) -> Dictionary:
	var available = ship_storage.get(item_name, 0)
	if available <= 0:
		return {}
	var dropped_count = mini(available, count)
	ship_storage[item_name] -= dropped_count
	storage_changed.emit()
	return {"item": item_name, "count": dropped_count}

func remove_resource(item: String, count: int = 1) -> bool:
	return consume_item(item, count)

func craft_field_item(recipe_key: String) -> bool:
	var gm = _get_gm()
	match recipe_key:
		"emergency_o2":
			if inventory.get("plant_fibers", 0) >= 2:
				remove_resource("plant_fibers", 2)
				if gm:
					gm.player_stats.oxygen = minf(100.0, gm.player_stats.oxygen + 35.0)
					gm.player_vital_updated.emit("oxygen", gm.player_stats.oxygen, 100.0)
				_play_audio("collect", 1.2, 0.0)
				return true
			elif inventory.get("silicon", 0) >= 1:
				remove_resource("silicon", 1)
				if gm:
					gm.player_stats.oxygen = minf(100.0, gm.player_stats.oxygen + 35.0)
					gm.player_vital_updated.emit("oxygen", gm.player_stats.oxygen, 100.0)
				_play_audio("collect", 1.2, 0.0)
				return true
		"small_biofuel":
			if inventory.get("plant_fibers", 0) >= 2:
				remove_resource("plant_fibers", 2)
				if gm:
					gm.player_stats.fuel = minf(100.0, gm.player_stats.fuel + 30.0)
					gm.player_vital_updated.emit("fuel", gm.player_stats.fuel, 100.0)
				_play_audio("collect", 1.2, 0.0)
				return true
		"suit_patch":
			if inventory.get("plant_fibers", 0) >= 1 and inventory.get("iron", 0) >= 1:
				remove_resource("plant_fibers", 1)
				remove_resource("iron", 1)
				if gm:
					gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 25.0)
					gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
				_play_audio("collect", 1.2, 0.0)
				return true
	return false

func equip_storage_to_body_slot(item: String, target_slot: String = "") -> bool:
	if ship_storage.get(item, 0) <= 0:
		return false
		
	var max_s = get_max_stack(item)
	var chosen_slot = target_slot
	
	# If no specific slot or target slot is occupied by different item:
	if chosen_slot == "" or not body_slots.has(chosen_slot):
		# Find first empty slot
		for k in ALL_BODY_SLOTS:
			if body_slots[k]["item"] == "" or body_slots[k]["count"] <= 0:
				chosen_slot = k
				break
				
	if chosen_slot == "":
		inventory_full.emit(item)
		return false
		
	var s = body_slots[chosen_slot]
	if s["item"] != "" and s["item"] != item and s["count"] > 0:
		# Slot already has another item: swap back to storage
		var old_item = s["item"]
		var old_count = s["count"]
		ship_storage[old_item] = ship_storage.get(old_item, 0) + old_count
		s["item"] = ""
		s["count"] = 0
		
	var available = ship_storage[item]
	var current_in_slot = s["count"] if s["item"] == item else 0
	var space = max_s - current_in_slot
	if space <= 0:
		return false
		
	var to_transfer = mini(available, space)
	ship_storage[item] -= to_transfer
	s["item"] = item
	s["count"] = current_in_slot + to_transfer
	
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
	return true

func deposit_all_to_storage() -> void:
	# Clear body slots
	for s_key in body_slots.keys():
		var s = body_slots[s_key]
		if s["item"] != "" and s["count"] > 0:
			ship_storage[s["item"]] = ship_storage.get(s["item"], 0) + s["count"]
			body_slots[s_key] = {"item": "", "count": 0}
			
	# Also clear any remaining loose inventory
	for k in inventory.keys():
		var count = inventory[k]
		if count > 0:
			ship_storage[k] = ship_storage.get(k, 0) + count
			inventory[k] = 0
			
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()

func withdraw_all_from_storage() -> void:
	# Load from ship storage into astronaut body slots as much as fits
	for item in ship_storage.keys():
		var available = ship_storage[item]
		if available <= 0:
			continue
		for s_key in ALL_BODY_SLOTS:
			if available <= 0:
				break
			if not body_slots.has(s_key): continue
			var s = body_slots[s_key]
			var max_s = get_max_stack(item)
			if s["item"] == "" or s["count"] <= 0:
				var take = mini(available, max_s)
				s["item"] = item
				s["count"] = take
				available -= take
				ship_storage[item] = available
			elif s["item"] == item and s["count"] < max_s:
				var space = max_s - s["count"]
				var take = mini(available, space)
				s["count"] += take
				available -= take
				ship_storage[item] = available
				
	_recalculate_inventory_from_body()
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()

func deposit_item(item: String, amount: int = 1) -> bool:
	if inventory.get(item, 0) < amount or amount <= 0:
		return false
	inventory[item] -= amount
	ship_storage[item] = ship_storage.get(item, 0) + amount
	
	# Deduct from body slots
	var rem = amount
	for s in body_slots.values():
		if s["item"] == item and s["count"] > 0:
			var take = mini(rem, s["count"])
			s["count"] -= take
			rem -= take
			if s["count"] <= 0:
				s["item"] = ""
			if rem <= 0:
				break
				
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
	return true

func withdraw_item(item: String, amount: int = 1) -> bool:
	if ship_storage.get(item, 0) < amount or amount <= 0:
		return false
	ship_storage[item] -= amount
	inventory[item] = inventory.get(item, 0) + amount
	
	# Place in body slots if space allows
	var rem = amount
	for s_key in ALL_BODY_SLOTS:
		if rem <= 0: break
		if not body_slots.has(s_key): continue
		var s = body_slots[s_key]
		var max_s = get_max_stack(item)
		if s["item"] == "" or s["count"] <= 0:
			var take = mini(rem, max_s)
			s["item"] = item
			s["count"] = take
			rem -= take
		elif s["item"] == item and s["count"] < max_s:
			var space = max_s - s["count"]
			var take = mini(rem, space)
			s["count"] += take
			rem -= take
			
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
	return true

# ===================================================
# CRAFTING & HYPERDRIVE LOGIC
# ===================================================
func can_craft(item: String) -> bool:
	sync_body_from_inventory()
	# Check combined resources (from body or ship storage if in cabin)
	var iron = inventory.get("iron", 0) + ship_storage.get("iron", 0)
	var copper = inventory.get("copper", 0) + ship_storage.get("copper", 0)
	var silicon = inventory.get("silicon", 0) + ship_storage.get("silicon", 0)
	var wire = inventory.get("wire", 0) + ship_storage.get("wire", 0)
	var uranium = inventory.get("uranium", 0) + ship_storage.get("uranium", 0)
	
	match item:
		"wrench":
			return iron >= 2
		"wire":
			return copper >= 1
		"microchip":
			return silicon >= 1 and wire >= 1
		"reactor_cell":
			return uranium >= 1 and iron >= 2
		# Ship modular parts
		"hull_plate":
			return iron >= 2
		"nozzle_core":
			return copper >= 2 and iron >= 1
		"hyperdrive_coil":
			return copper >= 2 and silicon >= 1
		"o2_filter":
			return silicon >= 1 and iron >= 1
		"energy_cell":
			return silicon >= 1 and uranium >= 1
		# Field consumables
		"repair_kit_basic":
			return iron >= 2
		"repair_kit_advanced":
			return iron >= 2 and copper >= 2
		"o2_canister":
			return iron >= 1 and silicon >= 1
		"suit_sealant":
			return silicon >= 2
		# Tools
		"plasma_cutter":
			return iron >= 2 and silicon >= 2
		# Creature Resources & Survival Gear
		"cooked_ration":
			return get_item_count("alien_meat") >= 1
		"chitin_spear":
			return get_item_count("alien_chitin") >= 2 and (get_item_count("alien_fang") >= 1 or get_item_count("copper") >= 1)
		"bio_medkit":
			return get_item_count("biogel_sample") >= 1 and get_item_count("alien_chitin") >= 1
		"chitin_plate":
			return get_item_count("alien_chitin") >= 2 and get_item_count("iron") >= 1
		# Drops Utility Expansion Recipes
		"suit_plating":
			return get_item_count("alien_chitin") >= 2
		"plasma_lens":
			return get_item_count("alien_fang") >= 1
		"sealant_paste":
			return get_item_count("plant_fibers") >= 2
		"bio_fuel":
			return get_item_count("plant_fibers") >= 2
		"hyperdrive_catalyst":
			return get_item_count("pearl") >= 1 or get_item_count("ocean_pearl") >= 1
	return false

func _consume_craft_material(mat: String, amount: int) -> void:
	var rem = amount
	# Deduct from body first
	for s in body_slots.values():
		if s["item"] == mat and s["count"] > 0:
			var take = mini(rem, s["count"])
			s["count"] -= take
			rem -= take
			if s["count"] <= 0:
				s["item"] = ""
			if rem <= 0:
				break
	# If still needed, deduct from ship storage
	if rem > 0 and ship_storage.get(mat, 0) >= rem:
		ship_storage[mat] -= rem
		rem = 0
	_recalculate_inventory_from_body()

func _add_crafted_item(item: String, count: int = 1) -> void:
	if can_astronaut_carry(item, count):
		add_resource(item, count)
	else:
		ship_storage[item] = ship_storage.get(item, 0) + count
		inventory[item] = inventory.get(item, 0) + count

func craft(item: String) -> bool:
	if not can_craft(item):
		return false
	match item:
		"wrench":
			_consume_craft_material("iron", 2)
			_add_crafted_item("wrench", 1)
		"wire":
			_consume_craft_material("copper", 1)
			_add_crafted_item("wire", 2)
		"microchip":
			_consume_craft_material("silicon", 1)
			_consume_craft_material("wire", 1)
			_add_crafted_item("microchip", 1)
		"reactor_cell":
			_consume_craft_material("uranium", 1)
			_consume_craft_material("iron", 2)
			_add_crafted_item("reactor_cell", 1)
		"hull_plate":
			_consume_craft_material("iron", 2)
			_add_crafted_item("hull_plate", 1)
		"nozzle_core":
			_consume_craft_material("copper", 2)
			_consume_craft_material("iron", 1)
			_add_crafted_item("nozzle_core", 1)
		"hyperdrive_coil":
			_consume_craft_material("copper", 2)
			_consume_craft_material("silicon", 1)
			_add_crafted_item("hyperdrive_coil", 1)
		"o2_filter":
			_consume_craft_material("silicon", 1)
			_consume_craft_material("iron", 1)
			_add_crafted_item("o2_filter", 1)
		"energy_cell":
			_consume_craft_material("silicon", 1)
			_consume_craft_material("uranium", 1)
			_add_crafted_item("energy_cell", 1)
		"repair_kit_basic":
			_consume_craft_material("iron", 2)
			_add_crafted_item("repair_kit_basic", 1)
		"repair_kit_advanced":
			_consume_craft_material("iron", 2)
			_consume_craft_material("copper", 2)
			_add_crafted_item("repair_kit_advanced", 1)
		"o2_canister":
			_consume_craft_material("iron", 1)
			_consume_craft_material("silicon", 1)
			_add_crafted_item("o2_canister", 1)
		"suit_sealant":
			_consume_craft_material("silicon", 2)
			_add_crafted_item("suit_sealant", 1)
		"plasma_cutter":
			_consume_craft_material("iron", 2)
			_consume_craft_material("silicon", 2)
			_add_crafted_item("plasma_cutter", 1)
		"cooked_ration":
			_consume_craft_material("alien_meat", 1)
			_add_crafted_item("cooked_ration", 1)
		"chitin_spear":
			_consume_craft_material("alien_chitin", 2)
			if get_item_count("alien_fang") >= 1:
				_consume_craft_material("alien_fang", 1)
			else:
				_consume_craft_material("copper", 1)
			_add_crafted_item("chitin_spear", 1)
		"bio_medkit":
			_consume_craft_material("biogel_sample", 1)
			_consume_craft_material("alien_chitin", 1)
			_add_crafted_item("bio_medkit", 1)
		"chitin_plate":
			_consume_craft_material("alien_chitin", 2)
			_consume_craft_material("iron", 1)
			_add_crafted_item("chitin_plate", 1)
		"suit_plating":
			_consume_craft_material("alien_chitin", 2)
			_add_crafted_item("suit_plating", 1)
		"plasma_lens":
			_consume_craft_material("alien_fang", 1)
			_add_crafted_item("plasma_lens", 1)
		"sealant_paste":
			_consume_craft_material("plant_fibers", 2)
			_add_crafted_item("sealant_paste", 1)
		"bio_fuel":
			_consume_craft_material("plant_fibers", 2)
			_add_crafted_item("bio_fuel", 1)
		"hyperdrive_catalyst":
			if get_item_count("pearl") >= 1:
				_consume_craft_material("pearl", 1)
			else:
				_consume_craft_material("ocean_pearl", 1)
			_add_crafted_item("hyperdrive_catalyst", 1)
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
	return true

func _get_gm():
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root and loop.root.has_node("GameManager"):
		return loop.root.get_node("GameManager")
	return null

func _play_audio(sfx: String, pitch: float = 1.0, vol: float = 0.0) -> void:
	var loop = Engine.get_main_loop()
	if loop and "root" in loop and loop.root and loop.root.has_node("AudioManager"):
		loop.root.get_node("AudioManager").play(sfx, pitch, vol)

func use_consumable(item: String) -> bool:
	var total_avail = inventory.get(item, 0) + ship_storage.get(item, 0)
	if total_avail <= 0:
		return false
	_consume_craft_material(item, 1)
	var gm = _get_gm()
	match item:
		"repair_kit_basic":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 35.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
		"repair_kit_advanced":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 80.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
		"o2_canister":
			if gm:
				gm.player_stats.oxygen = minf(100.0, gm.player_stats.oxygen + 50.0)
				gm.player_vital_updated.emit("oxygen", gm.player_stats.oxygen, 100.0)
		"suit_sealant":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 30.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
		"alien_meat":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 20.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
		"cooked_ration":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 50.0)
				gm.player_stats.oxygen = minf(100.0, gm.player_stats.oxygen + 30.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
				gm.player_vital_updated.emit("oxygen", gm.player_stats.oxygen, 100.0)
		"bio_medkit":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 60.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
		"chitin_plate":
			if gm:
				gm.player_stats.hull = minf(100.0, gm.player_stats.hull + 45.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, 100.0)
		"suit_plating":
			if gm:
				var current_max = float(gm.player_stats.get("max_hull", 100.0))
				var new_max = current_max + 20.0
				gm.player_stats["max_hull"] = new_max
				gm.player_stats.hull = minf(new_max, gm.player_stats.hull + 35.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, new_max)
		"plasma_lens":
			if gm:
				gm.player_stats["mining_speed_boost"] = 2.0
		"sealant_paste":
			if gm:
				var max_h = float(gm.player_stats.get("max_hull", 100.0))
				gm.player_stats.hull = minf(max_h, gm.player_stats.hull + 35.0)
				gm.player_vital_updated.emit("hull", gm.player_stats.hull, max_h)
		"bio_fuel":
			if gm:
				gm.player_stats.fuel = minf(100.0, gm.player_stats.fuel + 50.0)
				gm.player_vital_updated.emit("fuel", gm.player_stats.fuel, 100.0)
		"pearl", "ocean_pearl":
			if gm and gm.has_method("add_luna_coins"):
				gm.add_luna_coins(100)
		"hyperdrive_catalyst":
			for part in hyperdrive_requirements.keys():
				if installed_parts.get(part, 0) < hyperdrive_requirements[part]:
					installed_parts[part] = installed_parts.get(part, 0) + 1
					hyperdrive_repaired.emit(part)
					if is_hyperdrive_complete():
						hyperdrive_ready.emit()
					break
		_:
			return false
	_play_audio("craft", 1.0, 1.5)
	return true

func trade_pearl_for_coins(pearl_name: String = "pearl") -> bool:
	var item_to_use = ""
	if get_item_count("pearl") >= 1:
		item_to_use = "pearl"
	elif get_item_count("ocean_pearl") >= 1:
		item_to_use = "ocean_pearl"
	if item_to_use.is_empty():
		return false
	_consume_craft_material(item_to_use, 1)
	var gm = _get_gm()
	if gm and gm.has_method("add_luna_coins"):
		gm.add_luna_coins(100)
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
	return true

func craft_item(item: String) -> bool:
	return craft(item)

func use_item(item: String) -> bool:
	return use_consumable(item)

func get_item_count(item: String) -> int:
	return inventory.get(item, 0) + ship_storage.get(item, 0)

func add_item(item: String, count: int = 1) -> void:
	_add_crafted_item(item, count)

func consume_item(item: String, count: int = 1) -> bool:
	if get_item_count(item) < count:
		return false
	_consume_craft_material(item, count)
	return true

func can_install_part(part: String) -> bool:
	if not hyperdrive_requirements.has(part):
		return false
	var needed = hyperdrive_requirements[part] - installed_parts.get(part, 0)
	var available = inventory.get(part, 0) + ship_storage.get(part, 0)
	return needed > 0 and available > 0

func install_part(part: String) -> bool:
	if not can_install_part(part):
		return false
	_consume_craft_material(part, 1)
	installed_parts[part] = installed_parts.get(part, 0) + 1
	inventory_changed.emit()
	storage_changed.emit()
	hyperdrive_repaired.emit(part)
	if is_hyperdrive_complete():
		hyperdrive_ready.emit()
	return true

func install_all_available_parts() -> int:
	var count = 0
	for part in hyperdrive_requirements.keys():
		while can_install_part(part):
			if install_part(part):
				count += 1
			else:
				break
	return count

func is_hyperdrive_complete() -> bool:
	for part in hyperdrive_requirements.keys():
		if installed_parts.get(part, 0) < hyperdrive_requirements[part]:
			return false
	return true

func get_hyperdrive_progress() -> float:
	var total_needed = 0
	var total_installed = 0
	for k in hyperdrive_requirements.keys():
		total_needed += hyperdrive_requirements[k]
		total_installed += installed_parts.get(k, 0)
	if total_needed == 0:
		return 1.0
	return float(total_installed) / float(total_needed)
