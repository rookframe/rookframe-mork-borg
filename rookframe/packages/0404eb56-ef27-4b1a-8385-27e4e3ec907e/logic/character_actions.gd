extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"

const ABILITIES := ["Agility", "Presence", "Strength", "Toughness"]

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
		if parts.size() != 3 or not parts[1].is_valid_int() or int(parts[1]) < 0 or int(parts[1]) >= entries.size() or not parts[2] in ["name", "rules", "uses"]:
			return _failure("This Character field is unavailable. Reopen the sheet.")
		var entry: Dictionary = entries[int(parts[1])]
		if parts[2] == "uses" and (not text.is_valid_int() or int(text) < 0):
			return _failure("Enter a non-negative whole number of remaining uses.")
		entry[parts[2]] = int(text) if parts[2] == "uses" else text
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
