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
	"reactor_cell": 0
}

# Astronaut Physical Body Attachment Slots:
# The astronaut can ONLY carry items on their Hands or Back!
# 4 physical attachment points:
# - hand_left  : Left Hand
# - hand_right : Right Hand
# - back_1     : Upper Backpack Mount
# - back_2     : Lower Backpack Mount
var body_slots: Dictionary = {
	"hand_left": {"item": "", "count": 0},
	"hand_right": {"item": "", "count": 0},
	"back_1": {"item": "", "count": 0},
	"back_2": {"item": "", "count": 0}
}

# Ship Storage Bin (Waste of Space cabin cargo container)
var ship_storage: Dictionary = {
	"iron": 0,
	"copper": 0,
	"silicon": 0,
	"uranium": 0,
	"wrench": 0,
	"wire": 0,
	"microchip": 0,
	"reactor_cell": 0
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
		"wrench", "microchip", "reactor_cell":
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
	for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
		var s = body_slots[s_key]
		if s["item"] == res_name and s["count"] < max_s:
			needed -= (max_s - s["count"])
			if needed <= 0:
				return true
				
	# Check empty slots
	for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
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
	for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
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
		for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
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

func sync_body_from_inventory() -> void:
	# If inventory contains items not yet mapped to body slots (e.g. from tests or loads)
	# distribute them into body slots.
	var cur_body_total = 0
	for s in body_slots.values():
		cur_body_total += s["count"]
		
	var inv_total = 0
	for v in inventory.values():
		inv_total += v
		
	if inv_total > 0 and cur_body_total == 0:
		for item in inventory.keys():
			var count = inventory[item]
			while count > 0:
				var max_s = get_max_stack(item)
				var assigned = false
				for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
					var s = body_slots[s_key]
					if s["item"] == "" or s["count"] <= 0:
						var to_add = mini(count, max_s)
						s["item"] = item
						s["count"] = to_add
						count -= to_add
						assigned = true
						break
				if not assigned:
					break # All body slots filled
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

func equip_storage_to_body_slot(item: String, target_slot: String = "") -> bool:
	if ship_storage.get(item, 0) <= 0:
		return false
		
	var max_s = get_max_stack(item)
	var chosen_slot = target_slot
	
	# If no specific slot or target slot is occupied by different item:
	if chosen_slot == "" or not body_slots.has(chosen_slot):
		# Find first empty slot
		for k in ["hand_right", "hand_left", "back_1", "back_2"]:
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
		for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
			if available <= 0:
				break
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
	for s_key in ["hand_right", "hand_left", "back_1", "back_2"]:
		if rem <= 0: break
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

func craft(item: String) -> bool:
	if not can_craft(item):
		return false
	match item:
		"wrench":
			_consume_craft_material("iron", 2)
			add_resource("wrench", 1)
		"wire":
			_consume_craft_material("copper", 1)
			add_resource("wire", 2)
		"microchip":
			_consume_craft_material("silicon", 1)
			_consume_craft_material("wire", 1)
			add_resource("microchip", 1)
		"reactor_cell":
			_consume_craft_material("uranium", 1)
			_consume_craft_material("iron", 2)
			add_resource("reactor_cell", 1)
	inventory_changed.emit()
	storage_changed.emit()
	body_slots_changed.emit()
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
