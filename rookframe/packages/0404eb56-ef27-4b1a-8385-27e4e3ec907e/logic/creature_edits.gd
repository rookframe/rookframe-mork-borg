extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
const PROJECTION = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_projection.gd")
const DICE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/attack_sources.gd")
const HEALTH = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_health.gd")
var _context: SDK.SystemActionContext

func _init(actor_id: SDK.ActorId, context: SDK.SystemActionContext) -> void:
	super(null, actor_id)
	_context = context

func _read() -> SDK.ActorResult:
	var result := _context.read_actor(_id)
	if not result.ok or result.actor == null:
		return _failure("Creature data is unavailable.")
	var current: Dictionary = result.actor.data
	if str(current.get("schema", "")) != "mork-borg-adversary/v1":
		return _failure("Creature data is unavailable.")
	if result.actor.access_level != "Owner":
		return _failure("Owner access is required to change this Creature.")
	return result

func _save(data: Dictionary) -> SDK.ActorResult:
	var saved := _context.commit([SDK.ActorChange.new(_id, data)])
	return _context.read_actor(_id) if saved.ok else _failure(saved.message)

## Freeze old effective capabilities and assign stable correction identities once.
func prepare() -> SDK.ActorResult:
	var result := _read()
	if not result.ok:
		return result
	var current: Dictionary = result.actor.data
	var data := CREATURES.new().stat_block(current)
	if not _valid_entries(data):
		return _failure("Creature capabilities are malformed.")
	var attacks: Array = data.get("attacks", [])
	var entries: Array = []
	for attack in attacks:
		entries.append(attack)
	for entry in PROJECTION.new().rules(data):
		entries.append(entry)
	for roll in PROJECTION.new().printed(data):
		entries.append(roll)
	var seen: Array[String] = []
	for raw in entries:
		var entry: Dictionary = raw
		var identity := str(entry.get("correction_entry_id", ""))
		if identity.is_empty() or identity in seen:
			identity = _context.new_request_id()
			entry["correction_entry_id"] = identity
		seen.append(identity)
	return result if data == current else await _save(data)

func correct_many(fields: Dictionary, entry_ids: Dictionary) -> SDK.ActorResult:
	invalid_field = ""
	var source := _read()
	if not source.ok:
		return source
	var current: Dictionary = source.actor.data
	var data := CREATURES.new().stat_block(current)
	if not _valid_entries(data):
		return _failure("Creature capabilities are malformed.")
	var projection := PROJECTION.new()
	var available := projection.fields(data)
	var identities := projection.identities(data)
	var rules_changed := false
	var rules_mirror := projection.rules_mirror(data)
	for key in fields.keys():
		var field := str(key)
		if typeof(key) != TYPE_STRING or typeof(fields.get(field)) != TYPE_STRING:
			return _failure("Creature corrections must be text fields.")
		var parts := field.split(":")
		if parts.size() == 3 and parts[0] in ["attack", "rule", "printed"]:
			var entry := parts[0] + ":" + parts[1]
			# A removed/replaced entry never receives another entry's correction.
			if not identities.has(entry) or not entry_ids.has(entry) or str(entry_ids.get(entry)) != str(identities.get(entry)):
				continue
		if not available.has(field):
			return _field_failure(field, "This Creature field is unavailable. Reopen the sheet.")
		var error := _correct(data, field, str(fields.get(field)))
		if not error.is_empty():
			return _field_failure(field, error)
		if field.begins_with("rule:") and parts[2] in ["name", "text"]:
			rules_changed = true
	if rules_changed and rules_mirror and not fields.has("rules"):
		data["rules"] = projection.rules_text(data)
	return await _save(data)

func _correct(data: Dictionary, field: String, text: String) -> String:
	if field in ["hit_points", "maximum_hit_points", "morale", "armor:shield_reduction", "armor:defence_penalty"]:
		var integer := HEALTH.new().integer(text)
		if not integer.ok:
			return str(integer.message)
		var value := int(integer.value)
		if field == "maximum_hit_points" and value < 1:
			return "Maximum HP must be at least 1."
		if field == "morale":
			var morale: Dictionary = data.get("morale", {})
			morale["value"] = value
		elif field.begins_with("armor:"):
			if value < 0:
				return "Enter a non-negative whole number."
			var armor: Dictionary = data.get("armor", {})
			armor[field.trim_prefix("armor:")] = value
		else:
			data[field] = value
	elif field in ["name", "classification", "rules"]:
		if field == "name" and text.strip_edges().is_empty():
			return "Enter a Creature name."
		data[field] = text.strip_edges() if field != "rules" else text
	elif field in ["armor:name", "armor:reduction"]:
		var armor: Dictionary = data.get("armor", {})
		if field == "armor:reduction":
			text = text.strip_edges().to_lower()
			if text.begins_with("1d"):
				text = text.trim_prefix("1")
			if not text in ["", "d2", "d4", "d6"]:
				return "Use d2, d4 or d6, or leave protection empty."
		armor[field.trim_prefix("armor:")] = text
	else:
		var parts := field.split(":")
		var entries: Array = data.get("attacks", []) if parts[0] == "attack" else PROJECTION.new().printed(data) if parts[0] == "printed" else PROJECTION.new().rules(data)
		var entry: Dictionary = entries[int(parts[1])]
		var member := str(parts[2])
		if member == "dice":
			text = text.strip_edges().to_lower()
			if DICE.new().damage_dice(text).is_empty():
				return "Use one supported dice group, optionally + a whole number."
			entry[member] = text
		elif member in ["range_feet", "attack_dr", "defence_dr"]:
			var integer := HEALTH.new().integer(text)
			if not integer.ok:
				return str(integer.message)
			if int(integer.value) < 0:
				return "Enter a non-negative whole number."
			entry[member] = int(integer.value)
		else:
			if member == "name" and text.strip_edges().is_empty():
				return "Enter an entry name."
			entry[member] = text
	return ""

func _valid_entries(data: Dictionary) -> bool:
	if typeof(data.get("armor", {})) != TYPE_DICTIONARY or typeof(data.get("morale", {})) != TYPE_DICTIONARY or typeof(data.get("attacks", [])) != TYPE_ARRAY or typeof(data.get("rule_groups", [])) != TYPE_ARRAY:
		return false
	var attacks: Array = data.get("attacks", [])
	for raw in attacks:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
	var groups: Array = data.get("rule_groups", [])
	for raw in groups:
		if typeof(raw) != TYPE_DICTIONARY:
			return false
		var group: Dictionary = raw
		if typeof(group.get("entries", [])) != TYPE_ARRAY:
			return false
		var entries: Array = group.get("entries", [])
		for raw_entry in entries:
			if typeof(raw_entry) != TYPE_DICTIONARY:
				return false
			var entry: Dictionary = raw_entry
			if typeof(entry.get("rolls", [])) != TYPE_ARRAY:
				return false
			var rolls: Array = entry.get("rolls", [])
			for roll in rolls:
				if typeof(roll) != TYPE_DICTIONARY:
					return false
	return true
