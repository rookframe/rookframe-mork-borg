extends RefCounted
## Rule/origin capabilities, never inferred from access, targets or Character stats.
func supported(data: Dictionary) -> bool:
	var profile := str(data.get("definition_id", ""))
	if profile in ["hawk-as-weapon", "ancient-gore-hound"]:
		return true
	if profile in ["dog-small-but-vicious", "monkey"]:
		return _origin(data, "creation_id")
	var source := str(data.get("grant_source", ""))
	if profile in ["belze-skeleton", "nodh-zombie"] and source == "Foul Psychopomp" or profile == "zukuma-berserker" and source == "Book of boiling blood":
		return _origin(data, "summoner_actor") and _origin(data, "summon_action")
	return false

func _origin(data: Dictionary, field: String) -> bool:
	return typeof(data.get(field)) == TYPE_STRING and not str(data.get(field, "")).strip_edges().is_empty()

func attack(data: Dictionary, entry: Dictionary) -> Dictionary:
	if not supported(data) or typeof(entry.get("attack_dr", 12)) != TYPE_INT:
		return {}
	return {"difficulty": int(entry.get("attack_dr", 12))}

func defence(data: Dictionary) -> Dictionary:
	if not supported(data) or typeof(data.get("defence_dr", 12)) != TYPE_INT:
		return {}
	var dr := int(data.get("defence_dr", 12))
	if not str(data.get("definition_id", "")) in ["hawk-as-weapon", "ancient-gore-hound"]:
		# Granted/summoned enemy profiles record the opposing attack difficulty.
		if dr < -9223372036854775783:
			return {}
		dr = 24 - dr
	var entry := _defence_entry(data)
	return {"difficulty": dr, "entry": str(entry.get("id", "own-defence")), "name": str(entry.get("name", "Defence")), "correction_id": str(entry.get("correction_entry_id", ""))}

func _defence_entry(data: Dictionary) -> Dictionary:
	if typeof(data.get("rule_groups", [])) != TYPE_ARRAY:
		return {}
	var groups: Array = data.get("rule_groups", [])
	for raw_group in groups:
		if typeof(raw_group) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = raw_group
		if typeof(group.get("entries", [])) != TYPE_ARRAY:
			continue
		var entries: Array = group.get("entries", [])
		for raw in entries:
			if typeof(raw) == TYPE_DICTIONARY:
				var entry: Dictionary = raw
				if str(entry.get("own_test", "")) == "defence":
					return entry
	return {}

func presentation(data: Dictionary) -> Dictionary:
	var attacks: Dictionary = {}
	if typeof(data.get("attacks", [])) == TYPE_ARRAY:
		var entries: Array = data.get("attacks", [])
		for raw in entries:
			if typeof(raw) == TYPE_DICTIONARY:
				var entry: Dictionary = raw
				var own := attack(data, entry)
				if not own.is_empty():
					attacks[str(entry.get("id", ""))] = own.difficulty
	return {"attacks": attacks, "defence": defence(data)}

func attack_identity(data: Dictionary, id: String) -> Dictionary:
	if id.is_empty() or typeof(data.get("attacks", [])) != TYPE_ARRAY:
		return {}
	var entries: Array = data.get("attacks", [])
	for raw in entries:
		if typeof(raw) == TYPE_DICTIONARY:
			var entry: Dictionary = raw
			if str(entry.get("id", "")) == id:
				return {"entry": id, "correction_id": str(entry.get("correction_entry_id", ""))}
	return {}
