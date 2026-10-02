extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"

const CLASSES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd")
const BROKEN = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/broken_incident.gd")
const ABILITIES := ["Agility", "Presence", "Strength", "Toughness"]

func correct(field: String, text: String) -> SDK.ActorResult:
	var fields: Dictionary = {}
	fields[field] = text
	return await correct_many(fields)

## Apply only edited Character fields to the latest shared Actor snapshot.
## Inventory and Appearance are independent accepted operations.
func correct_many(fields: Dictionary, entry_ids: Dictionary = {}) -> SDK.ActorResult:
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data := current.duplicate(true)
	for key in fields.keys():
		var field := str(key)
		if typeof(key) != TYPE_STRING or typeof(fields.get(field)) != TYPE_STRING:
			return _failure("Character corrections must be text fields.")
		if field.begins_with("trait:") or field.begins_with("companion:"):
			var parts := field.split(":")
			var collection := "traits" if parts[0] == "trait" else "companion_sheets"
			var entries: Array = current.get(collection, [])
			if parts.size() != 3 or not parts[1].is_valid_int():
				return _failure("This Character entry is unavailable.")
			var slot := int(parts[1])
			if slot < 0 or slot >= entries.size():
				return _failure("This Character entry is unavailable.")
			var entry: Dictionary = entries[slot]
			var identity := str(entry.get("id", "")) + "|" + str(entry.get("source_item_id", ""))
			var prefix := parts[0] + ":" + parts[1]
			if entry_ids.has(prefix) and str(entry_ids.get(prefix)) != identity:
				return _failure("This Character entry was replaced. Review its current fields.")
		var error := _correct(data, field, str(fields.get(field)))
		if not error.is_empty():
			return _failure(error)
	data = BROKEN.new().sync(current, data)
	return await _sdk.actors.update(_id, data)

func _correct(data: Dictionary, field: String, text: String) -> String:
	if field in ABILITIES or field in ["hit_points", "maximum_hit_points", "silver", "omens", "power_uses", "improvements"]:
		if not text.is_valid_int():
			return ("Enter a whole number.")
		var value := int(text)
		if field in ABILITIES:
			if value < -3 or value > 6:
				return ("Ability modifiers range from −3 to +6.")
			var abilities: Dictionary = data.get("abilities", {})
			var ability: Dictionary = abilities.get(field, {})
			ability["modifier"] = value
			abilities[field] = ability
			data["abilities"] = abilities
		else:
			if field != "hit_points" and value < (1 if field == "maximum_hit_points" else 0):
				return ("Enter a non-negative value (maximum HP must be at least 1).")
			data[field] = value
	elif field in ["name", "description", "origin", "class_title", "pack"]:
		if field == "name" and text.strip_edges().is_empty():
			return ("Enter a Character name.")
		data[field] = text.strip_edges()
	elif field == "class_rules":
		var lines: Array[String] = []
		for line in text.split("\n"):
			lines.append(line)
		data[field] = lines
	elif field.begins_with("scum_specialty:"):
		if str(data.get("class_id", "")) != "gutterborn-scum" or not field in ["scum_specialty:0", "scum_specialty:1"] or not text.is_valid_int():
			return ("Choose a Gutterborn specialty number from 1 to 6.")
		var slot := 0 if field == "scum_specialty:0" else 1
		var face := int(text)
		if face < (1 if slot == 0 else 0) or face > 6:
			return ("Use 1–6 for a specialty, or 0 to leave the second slot empty.")
		var traits: Array = data.get("traits", [])
		if traits.size() < slot or traits.size() > 2:
			return ("Correct the first specialty before the second.")
		if face == 0:
			if traits.size() == 2:
				traits = [traits[0]]
		else:
			var feature := CLASSES.new().feature("gutterborn-scum", face)
			feature.erase("item")
			if slot < traits.size():
				var existing: Dictionary = traits[slot]
				if str(existing.get("id", "")) != str(feature.id):
					traits = [feature] if traits.size() == 1 else ([feature, traits[1]] if slot == 0 else [traits[0], feature])
			else:
				traits = [feature] if traits.is_empty() else [traits[0], feature]
		data["traits"] = traits
	elif field.begins_with("trait:") or field.begins_with("companion:"):
		var parts := field.split(":")
		var key := "traits" if parts[0] == "trait" else "companion_sheets"
		var source_entries: Array = data.get(key, [])
		var entries: Array = source_entries.duplicate(true)
		if parts.size() != 3 or not parts[1].is_valid_int() or int(parts[1]) < 0 or int(parts[1]) >= entries.size() or not parts[2] in ["name", "rules", "uses"]:
			return ("This Character field is unavailable. Reopen the sheet.")
		var entry: Dictionary = entries[int(parts[1])]
		if parts[2] == "uses" and (not text.is_valid_int() or int(text) < 0):
			return ("Enter a non-negative whole number of remaining uses.")
		entry[parts[2]] = int(text) if parts[2] == "uses" else text
		data[key] = entries
	else:
		return ("This Character field is not editable.")
	return ""

func spend_omen() -> SDK.ActorResult:
	return await adjust_omens(-1)

func adjust_omens(delta: int) -> SDK.ActorResult:
	if delta != -1 and delta != 1:
		return _failure("Choose an Omen increase or decrease.")
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data: Dictionary = current.duplicate(true)
	var omens: int = data.get("omens", 0)
	if delta < 0 and omens <= 0:
		return _failure("No Omens remain.")
	data["omens"] = omens + delta
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

## Appearance commits independently of the Character-field draft.
func set_portrait(image: PackedByteArray) -> SDK.ActorResult:
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data := current.duplicate(true)
	if image.is_empty():
		data.erase("portrait")
	else:
		data["portrait"] = image
	return await _sdk.actors.update(_id, data)
