extends "res://rookframe/sdk/actor_definition.gd"

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE = null) -> void:
	_data_catalogue = data_catalogue


const ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd")

const ROOKFRAME_CONTENT := "fbf21a78-626e-4f35-b2ce-bd196083d9b7"

func default_miniature(definition: String) -> Dictionary:
	return _default_miniature(definition, _data_catalogue)

func _default_miniature(definition: String, data_catalogue: CATALOGUE) -> Dictionary:
	var local_id := data_catalogue.miniature_id(definition)
	return {} if local_id.is_empty() else {"package_id": ROOKFRAME_CONTENT, "local_id": local_id}

func effective_miniature(data: Dictionary) -> Dictionary:
	var preferred: Dictionary = data.get("preferred_miniature", {})
	if not preferred.is_empty():
		return preferred.duplicate(true)
	# A cleared assignment must not resurrect the definition's authored Miniature.
	if data.has("preferred_miniature"):
		return {"package_id": ROOKFRAME_CONTENT, "local_id": "default-miniature"}
	var authored := default_miniature(str(data.get("definition_id", "")))
	return authored if not authored.is_empty() else {"package_id": ROOKFRAME_CONTENT, "local_id": "default-miniature"}

func create_data(_choices: Variant) -> Variant:
	push_error("MÖRK BORG Actor creation requires the Package data capability.")
	return null

func create_data_with_content(raw_choices: Variant, content: RefCounted) -> Variant:
	var data_catalogue := CATALOGUE.new(content)
	if not data_catalogue.can_create_creature():
		return null
	return _create(raw_choices, data_catalogue)

func preview() -> Dictionary:
	if not _data_catalogue.can_create_creature():
		return {}
	return _create({}, _data_catalogue)

func _create(raw_choices: Variant, data_catalogue: CATALOGUE) -> Variant:
	var choices: Dictionary = raw_choices.duplicate(true)
	var definition: Dictionary = data_catalogue.creature_profile(resource_name).duplicate(true)
	var data: Dictionary = {
		"schema": "mork-borg-adversary/v1",
		"definition_id": resource_name,
		"name": definition.get("display_name", "Creature"),
		"hit_points": definition.get("hit_points", 0),
		"maximum_hit_points": definition.get("hit_points", 0),
		"morale": definition.get("morale", {"kind": "none"}),
		"armor": definition.get("armor", {"name": "No armor", "reduction": ""}),
		"attacks": definition.get("attacks", []),
		"inventory": definition.get("loot", []).duplicate(true),
		"creature_stat_block": true,
		"rules": definition.get("rules", ""),
	}
	var metadata := data_catalogue.creature_details(resource_name).duplicate(true)
	for field in ["classification", "rule_groups", "reference", "source"]:
		if metadata.has(field):
			data[field] = metadata[field]
	for field in ["defence_dr", "piercing_defence_dr", "destroy_at_damage"]:
		if definition.has(field):
			data[field] = definition[field]
	if choices.has("creation_id"):
		data["creation_id"] = choices["creation_id"]
	if choices.has("creation_roll_sequence"):
		data["creation_roll_sequence"] = choices["creation_roll_sequence"]
	for key in ["preferred_miniature", "inventory_serial", "summoner_actor", "summon_action", "grant_source", "name", "hit_points", "maximum_hit_points", "morale", "armor", "attacks", "inventory", "classification", "rule_groups", "reference", "source", "portrait"]:
		if choices.has(key):
			data[key] = choices[key]
	if not data.has("preferred_miniature"):
		data["preferred_miniature"] = _default_miniature(resource_name, data_catalogue)
	return data

## Project saved effective capabilities into a Creature Stat Block before any
## loot edit. The saved inventory remains untouched; only the old equipment
## interpretation is retired. The first ordinary accepted Actor update persists
## this value, so removed attacks and old source defaults cannot return.
func stat_block(current: Dictionary) -> Dictionary:
	var data := current.duplicate(true)
	if str(data.get("schema", "")) != "mork-borg-adversary/v1" or data.get("creature_stat_block", false):
		return data
	if typeof(data.get("attacks", [])) != TYPE_ARRAY or typeof(data.get("inventory", [])) != TYPE_ARRAY or typeof(data.get("armor", {})) != TYPE_DICTIONARY:
		return data
	var saved_attacks: Array = data.get("attacks", [])
	for raw in saved_attacks:
		if typeof(raw) != TYPE_DICTIONARY:
			return data
	var saved_items: Array = data.get("inventory", [])
	for raw in saved_items:
		if typeof(raw) != TYPE_DICTIONARY:
			return data
	var attacks := _inventory_attacks(data) if data.get("creature_inventory", false) else _profile_attacks(data)
	var retained: Array = []
	for raw in attacks:
		var attack: Dictionary = raw
		if not attack.get("equipped", true) or attack.get("broken", false) or int(attack.get("quantity", 1)) < 1:
			continue
		for key in ["inventory_id", "equipped", "broken", "quantity", "ammunition"]:
			attack.erase(key)
		retained.append(attack)
	data["attacks"] = retained
	var armor: Dictionary = data.get("armor", {"name": "No armor", "reduction": ""})
	var shield := 0
	var defence_penalty := 0
	for raw in ITEMS.new(null, null, _data_catalogue).inventory(data):
		var item: Dictionary = raw
		if not item.get("equipped", false) or int(item.get("quantity", 0)) < 1:
			continue
		if str(item.get("kind", "")) == "Armor" and int(item.get("penalty_tier", item.get("armor_tier", 0))) >= 2:
			defence_penalty += 2
		if str(item.get("kind", "")) == "Shield" and not item.get("broken", false):
			shield = 1
	if shield > 0:
		armor["shield_reduction"] = shield
	if defence_penalty > 0:
		armor["defence_penalty"] = defence_penalty
	data["armor"] = armor
	data["creature_stat_block"] = true
	data.erase("creature_inventory")
	return data

func attack_options(data: Dictionary) -> Array:
	var normalized := stat_block(data)
	if typeof(normalized.get("attacks", [])) != TYPE_ARRAY:
		return []
	var attacks: Array = normalized.get("attacks", [])
	var definition: Dictionary = _data_catalogue.creature_profile(str(data.get("definition_id", "")))
	return _authored_attack_defaults(attacks, definition.get("attacks", []))

## Adapt explicit capabilities for the existing targeted combat operation.
## These records never come from carried loot and have no ammunition counter.
func combat_attacks(data: Dictionary) -> Array:
	var result: Array = []
	var attacks: Array = attack_options(data)
	for raw_attack in attacks:
		if typeof(raw_attack) != TYPE_DICTIONARY:
			return []
		var attack: Dictionary = raw_attack
		var item: Dictionary = attack.duplicate(true)
		item["inventory_id"] = "creature:" + str(attack.get("id", ""))
		item["damage"] = str(attack.get("dice", ""))
		item.erase("ammunition")
		item["kind"] = "Weapon"
		item["quantity"] = 1
		item["equipped"] = true
		result.append(item)
	return result

func shield_reduction(data: Dictionary) -> int:
	var normalized := stat_block(data)
	var armor: Dictionary = normalized.get("armor", {})
	return int(armor.get("shield_reduction", 0))

## Targeted tabletop criticals change recorded protection, never carried loot.
func damage_protection(current: Dictionary) -> Dictionary:
	var data := stat_block(current)
	var armor: Dictionary = data.get("armor", {})
	var tier: int = {"d2": 1, "d4": 2, "d6": 3}.get(str(armor.get("reduction", "")), 0)
	if tier > 0:
		armor["reduction"] = ["", "d2", "d4"][tier - 1]
		data["armor"] = armor
	return data

func _profile_attacks(data: Dictionary) -> Array:
	var saved: Array = data.get("attacks", [])
	var definition_id := str(data.get("definition_id", ""))
	var definition: Dictionary = _data_catalogue.creature_profile(definition_id)
	var authored: Array = definition.get("attacks", [])
	if saved.is_empty() or authored.is_empty():
		return saved.duplicate(true)
	for raw in saved:
		if typeof(raw) != TYPE_DICTIONARY:
			return saved.duplicate(true)
		var previous: Dictionary = raw
		if previous.has("id"):
			return _authored_attack_defaults(saved, authored)
	var paired := definition_id in ["hawk-as-weapon", "eulotha-wyvern", "lady-porcelain", "monkey", "nodh-zombie", "seth-goblin"]
	if saved.size() != (1 if paired else authored.size()):
		return saved.duplicate(true)
	var result: Array = []
	for index in range(authored.size()):
		var template: Dictionary = authored[index]
		var option: Dictionary = template.duplicate(true)
		var previous: Dictionary = saved[0 if paired else index]
		for field in ["dice", "attack_dr", "defence_dr", "rules", "piercing"]:
			if previous.has(field):
				option[field] = previous[field]
		if not paired and previous.has("name"):
			option["name"] = previous["name"]
		result.append(option)
	return result

func _inventory_attacks(data: Dictionary) -> Array:
	var result: Array = []
	var profiles := _profile_attacks(data)
	var items: Array = data.get("inventory", [])
	for raw in items:
		if typeof(raw) != TYPE_DICTIONARY:
			return []
		var item: Dictionary = raw
		if str(item.get("kind", "")) != "Weapon":
			continue
		var attack: Dictionary = {}
		for raw_profile in profiles:
			var profile: Dictionary = raw_profile
			if str(profile.get("id", "")) == str(item.get("source_attack_id", "")):
				attack = profile.duplicate(true)
		var inventory_id: String = item.get("inventory_id", "")
		var source_attack: String = item.get("source_attack_id", "")
		attack["id"] = inventory_id if source_attack.is_empty() else source_attack
		attack["inventory_id"] = str(item.get("inventory_id", ""))
		attack["name"] = str(item.get("name", "Attack"))
		attack["dice"] = str(item.get("damage", ""))
		attack["range_feet"] = item.get("range_feet", 0)
		attack["equipped"] = item.get("equipped", false)
		attack["broken"] = item.get("broken", false)
		attack["quantity"] = item.get("quantity", 0)
		attack["ammunition"] = item.get("ammunition", "")
		attack["piercing"] = bool(item.get("piercing", attack.get("piercing", false)))
		result.append(attack)
	return result

## Companion stat blocks state their own defence test; enemy blocks state the
## opposing attack test. Reverse the deviation when changing the rolling side.
func defence_test_difficulty(data: Dictionary, piercing: bool = false) -> int:
	var dr := target_attack_difficulty(data, piercing)
	return 24 - dr

func target_attack_difficulty(data: Dictionary, piercing: bool = false) -> int:
	var definition: Dictionary = _data_catalogue.creature_profile(str(data.get("definition_id", "")))
	var dr: int = data.get("defence_dr", definition.get("defence_dr", 12))
	if str(data.get("definition_id", "")) in ["hawk-as-weapon", "ancient-gore-hound"]:
		dr = 24 - dr
	if piercing:
		dr = data.get("piercing_defence_dr", definition.get("piercing_defence_dr", dr))
	return dr

func attack_test_difficulty(attack: Dictionary) -> int:
	var own_dr: int = attack.get("attack_dr", 12)
	var opposing_dr: int = attack.get("defence_dr", 12)
	return own_dr + 12 - opposing_dr

func _authored_attack_defaults(saved: Array, authored: Array) -> Array:
	var result: Array = saved.duplicate(true)
	for raw in result:
		var attack: Dictionary = raw
		for untyped_entry in authored:
			var entry: Dictionary = untyped_entry
			if str(entry.get("id", "")) == str(attack.get("id", "")):
				for field in ["natural", "piercing"]:
					if not attack.has(field):
						attack[field] = bool(entry.get(field, false))
	return result
