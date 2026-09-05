extends RefCounted
class_name CraftingSystem

signal inventory_changed()
signal hyperdrive_repaired(part_name: String)
signal hyperdrive_ready()

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

# Hyperdrive requirements per level
# Level 1: Wrench + 2 Wires + 10 Uranium
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

func add_resource(res_name: String, amount: int = 1) -> void:
	if inventory.has(res_name):
		inventory[res_name] += amount
		inventory_changed.emit()

func can_craft(item: String) -> bool:
	match item:
		"wrench":
			return inventory["iron"] >= 2
		"wire":
			return inventory["copper"] >= 1
		"microchip":
			return inventory["silicon"] >= 1 and inventory["wire"] >= 1
		"reactor_cell":
			return inventory["uranium"] >= 1 and inventory["iron"] >= 2
	return false

func craft(item: String) -> bool:
	if not can_craft(item):
		return false
	match item:
		"wrench":
			inventory["iron"] -= 2
			inventory["wrench"] += 1
		"wire":
			inventory["copper"] -= 1
			inventory["wire"] += 2
		"microchip":
			inventory["silicon"] -= 1
			inventory["wire"] -= 1
			inventory["microchip"] += 1
		"reactor_cell":
			inventory["uranium"] -= 1
			inventory["iron"] -= 2
			inventory["reactor_cell"] += 1
	inventory_changed.emit()
	return true

func can_install_part(part: String) -> bool:
	if not hyperdrive_requirements.has(part):
		return false
	var needed = hyperdrive_requirements[part] - installed_parts[part]
	return needed > 0 and inventory.get(part, 0) > 0

func install_part(part: String) -> bool:
	if not can_install_part(part):
		return false
	inventory[part] -= 1
	installed_parts[part] += 1
	inventory_changed.emit()
	hyperdrive_repaired.emit(part)
	if is_hyperdrive_complete():
		hyperdrive_ready.emit()
	return true

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
