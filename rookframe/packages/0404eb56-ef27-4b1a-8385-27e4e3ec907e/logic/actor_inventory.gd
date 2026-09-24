extends RefCounted

## Ordinary Actor inventory operations, shared by Character and Creature sheets.
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
var _sdk: SDK
var _id: SDK.ActorId

func _init(facade: SDK, actor_id: SDK.ActorId) -> void:
	_sdk = facade
	_id = actor_id

func _read() -> SDK.ActorResult:
	var result := _sdk.actors.read(_id)
	if not result.ok or result.actor == null:
		return _failure("Actor data is unavailable.")
	if result.actor.access_level != "Owner":
		return _failure("Owner access is required to change this Actor.")
	return result

func _failure(message: String) -> SDK.ActorResult:
	return SDK.ActorResult.new({"ok": false, "message": message})

func _save(data: Dictionary) -> SDK.ActorResult:
	return await _sdk.actors.update(_id, data)

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
		for key in ["name", "kind", "rules", "price", "source", "damage", "reduction", "attack_ability", "ammunition", "resource_field"]:
			if defaults.has(key) and not entry.has(key):
				entry[key] = str(defaults.get(key, ""))
		for key in ["quantity", "range_feet", "armor_tier", "uses"]:
			if defaults.has(key) and not entry.has(key):
				var number: int = defaults.get(key, 0)
				entry[key] = number
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
	return await _save(data)

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
		return await _save(data)
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
