extends RefCounted

## Completed-sheet operations. Read current Actor data for every field-local
## change; the public SDK owns authorization, durable publication and replication.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const ABILITIES := ["Agility", "Presence", "Strength", "Toughness"]
var _sdk: SDK
var _id: SDK.ActorId

func _init(facade: SDK, actor_id: SDK.ActorId) -> void:
	_sdk = facade
	_id = actor_id

func correct(field: String, text: String) -> SDK.ActorResult:
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data: Dictionary = current.duplicate(true)
	if field in ABILITIES or field in ["hit_points", "maximum_hit_points", "silver", "omens", "power_uses"]:
		if not text.is_valid_int():
			return _failure("Enter a whole number.")
		var value := int(text)
		if field in ABILITIES:
			if value < -3 or value > 6:
				return _failure("Ability modifiers range from −3 to +6.")
			var abilities: Dictionary = data.get("abilities", {})
			var ability: Dictionary = abilities.get(field, {})
			ability["modifier"] = value
			abilities[field] = ability
			data["abilities"] = abilities
		else:
			if field != "hit_points" and value < (1 if field == "maximum_hit_points" else 0):
				return _failure("Enter a non-negative value (maximum HP must be at least 1).")
			data[field] = value
	elif field in ["name", "description", "origin", "class_title", "pack"]:
		if field == "name" and text.strip_edges().is_empty():
			return _failure("Enter a Character name.")
		data[field] = text.strip_edges()
	elif field == "class_rules":
		var lines: Array[String] = []
		for line in text.split("\n"):
			lines.append(line)
		data[field] = lines
	elif field.begins_with("trait:") or field.begins_with("companion:"):
		var parts := field.split(":")
		var key := "traits" if parts[0] == "trait" else "companion_sheets"
		var source_entries: Array = data.get(key, [])
		var entries: Array = source_entries.duplicate(true)
		if parts.size() != 3 or not parts[1].is_valid_int() or int(parts[1]) < 0 or int(parts[1]) >= entries.size() or not parts[2] in ["name", "rules"]:
			return _failure("This Character field is unavailable. Reopen the sheet.")
		var entry: Dictionary = entries[int(parts[1])]
		entry[parts[2]] = text
		data[key] = entries
	else:
		return _failure("This Character field is not editable.")
	return await _sdk.actors.update(_id, data)

func spend_omen() -> SDK.ActorResult:
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data: Dictionary = current.duplicate(true)
	var omens: int = data.get("omens", 0)
	if omens <= 0:
		return _failure("No Omens remain.")
	data["omens"] = omens - 1
	return await _sdk.actors.update(_id, data)

func _read() -> SDK.ActorResult:
	var result := _sdk.actors.read(_id)
	if not result.ok:
		return result
	if result.actor == null:
		return _failure("Character data is unavailable.")
	var data: Dictionary = result.actor.data
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		return _failure("Character data is unavailable.")
	if result.actor.access_level != "Owner":
		return _failure("Owner access is required to change this Character.")
	return result

func _failure(message: String) -> SDK.ActorResult:
	return SDK.ActorResult.new({"ok": false, "message": message})

const EQUIPMENT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/equipment.gd")

## Old completed Characters gain stable item identities on their next edit.
## The Actor-local serial never reuses removed identities.
func inventory(data: Dictionary) -> Array:
	var source_items: Array = data.get("inventory", [])
	var items: Array = source_items.duplicate(true)
	var serial: int = _serial(data, items)
	for raw in items:
		var entry: Dictionary = raw
		if not entry.has("inventory_id"):
			serial += 1
			entry["inventory_id"] = str(serial)
		var defaults: Dictionary = EQUIPMENT.new().item(str(entry.get("source_item_id", "")))
		for key in ["name", "kind", "quantity", "equipped", "rules", "price", "source", "damage", "range_feet", "armor_tier", "reduction", "uses"]:
			if defaults.has(key) and not entry.has(key):
				entry[key] = defaults[key]
		if not entry.has("quantity"):
			entry["quantity"] = 1
		if not entry.has("equipped"):
			entry["equipped"] = false
	return items

func add_equipment(source_id: String) -> SDK.ActorResult:
	var item: Dictionary = EQUIPMENT.new().item(source_id)
	if item.is_empty():
		return _failure("That equipment is unavailable.")
	return await _add(item)

func add_custom(fields: Dictionary) -> SDK.ActorResult:
	var item: Dictionary = {"custom": true, "name": "", "kind": "Equipment", "quantity": 1, "equipped": false}
	for key in ["name", "kind", "quantity", "uses", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
		if not fields.has(key):
			continue
		var error := _edit_item(item, str(key), str(fields[key]))
		if not error.is_empty():
			return _failure(error)
	if str(item.name).strip_edges().is_empty():
		return _failure("Enter an item name.")
	return await _add(item)

func _add(item: Dictionary) -> SDK.ActorResult:
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data: Dictionary = current.duplicate(true)
	var items := inventory(data)
	var serial := _serial(data, items) + 1
	item["inventory_id"] = str(serial)
	items.append(item)
	data["inventory_serial"] = serial
	data["inventory"] = items
	return await _sdk.actors.update(_id, data)

func change_item(id: String, field: String, text: String) -> SDK.ActorResult:
	return await _change_item(id, field, text, false)

func remove_item(id: String) -> SDK.ActorResult:
	return await _change_item(id, "", "", true)

func _change_item(id: String, field: String, text: String, remove: bool) -> SDK.ActorResult:
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data: Dictionary = current.duplicate(true)
	var items := inventory(data)
	data["inventory_serial"] = _serial(data, items)
	for index in range(items.size()):
		var item: Dictionary = items[index]
		if str(item.get("inventory_id", "")) != id:
			continue
		if remove:
			var retained: Array = []
			for other_index in range(items.size()):
				if other_index != index:
					retained.append(items[other_index])
			items = retained
		else:
			var error := _edit_item(item, field, text)
			if not error.is_empty():
				return _failure(error)
		data["inventory"] = items
		return await _sdk.actors.update(_id, data)
	return _failure("This item has been removed. Return to Inventory.")

func _edit_item(item: Dictionary, field: String, text: String) -> String:
	var custom: bool = item.get("custom", false)
	if field in ["quantity", "uses", "range_feet", "armor_tier"]:
		if field in ["range_feet", "armor_tier"] and not custom:
			return "Only custom item mechanics can be changed."
		if field == "uses" and item.has("dose_pool"):
			return "Edit the portable laboratory’s shared remaining doses."
		if not text.is_valid_int() or int(text) < 0:
			return "Enter a non-negative whole number."
		if field == "armor_tier" and int(text) > 3:
			return "Armor tiers range from 0 to 3."
		item[field] = int(text)
	elif field == "equipped":
		if not str(item.get("kind", "")) in ["Weapon", "Armor", "Shield"]:
			return "This item is carried without an equipment state."
		item[field] = text == "true"
	elif field == "name" or (custom and field in ["rules", "kind", "damage", "reduction"]):
		if field == "name" and text.strip_edges().is_empty():
			return "Enter an item name."
		if field == "kind" and not text in ["Equipment", "Weapon", "Armor", "Shield"]:
			return "Choose Equipment, Weapon, Armor or Shield."
		if field in ["damage", "reduction"] and not text in ["", "d2", "d4", "d6", "d8", "d10", "d12", "2d6", "2d8", "d4+1"]:
			return "Use a supported damage or reduction formula."
		item[field] = text.strip_edges()
		if field == "kind" and text == "Equipment":
			item["equipped"] = false
	else:
		return "This item field is not editable."
	return ""

func _serial(data: Dictionary, items: Array) -> int:
	var serial: int = data.get("inventory_serial", 0)
	for raw in items:
		var item: Dictionary = raw
		var item_id: String = item.get("inventory_id", "0")
		if int(item_id) > serial:
			serial = int(item_id)
	return serial
