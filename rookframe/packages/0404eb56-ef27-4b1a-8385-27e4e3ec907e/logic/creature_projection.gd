extends RefCounted
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")
## Text fields and entry identities for one Creature stat-block correction.
## Numeric slots keep every entry field at exactly three colon-separated parts.

func fields(data: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for field in ["name", "classification", "hit_points", "maximum_hit_points"]:
		values[field] = str(data.get(field, ""))
	var armor: Dictionary = data.get("armor", {})
	for field in ["name", "reduction", "shield_reduction", "defence_penalty"]:
		if field in ["name", "reduction"] or armor.has(field):
			values["armor:" + field] = str(armor.get(field, ""))
	var morale: Dictionary = data.get("morale", {})
	if str(morale.get("kind", "")) == "fixed":
		values["morale"] = str(morale.get("value", ""))
	var attacks: Array = data.get("attacks", [])
	for index in range(attacks.size()):
		var attack: Dictionary = attacks[index]
		for field in ["name", "dice", "range_feet", "rules", "attack_dr", "defence_dr"]:
			if field in ["name", "dice", "rules"] or attack.has(field):
				values["attack:%d:%s" % [index, field]] = str(attack.get(field, ""))
	var entries := rules(data)
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		for field in ["name", "text"]:
			values["rule:%d:%s" % [index, field]] = str(entry.get(field, ""))
	var rolls := printed(data)
	for index in range(rolls.size()):
		var roll: Dictionary = rolls[index]
		values["printed:%d:dice" % index] = str(roll.get("dice", ""))
	if entries.is_empty() or not rules_mirror(data):
		values["rules"] = str(data.get("rules", ""))
	return values

func identities(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var attacks: Array = data.get("attacks", [])
	for index in range(attacks.size()):
		var attack: Dictionary = attacks[index]
		result["attack:%d" % index] = str(attack.get("correction_entry_id", "")) + "|" + str(attack.get("id", ""))
	var entries := rules(data)
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		result["rule:%d" % index] = str(entry.get("correction_entry_id", "")) + "|" + str(entry.get("id", ""))
	var rolls := printed(data)
	for index in range(rolls.size()):
		var roll: Dictionary = rolls[index]
		result["printed:%d" % index] = str(roll.get("correction_entry_id", "")) + "|" + str(roll.get("id", ""))
	return result

func rules(data: Dictionary) -> Array:
	var result: Array = []
	var groups: Array = data.get("rule_groups", [])
	for raw in groups:
		var group: Dictionary = raw
		var entries: Array = group.get("entries", [])
		for entry in entries:
			result.append(entry)
	return result

func printed(data: Dictionary) -> Array:
	var result: Array = []
	for raw in rules(data):
		var entry: Dictionary = raw
		var rolls: Array = entry.get("rolls", [])
		for roll in rolls:
			result.append(roll)
	return result

func printed_routes(data: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	var entries := rules(data)
	var slot := 0
	for index in range(entries.size()):
		var entry: Dictionary = entries[index]
		var rolls: Array = entry.get("rolls", [])
		for roll in rolls:
			result["printed:%d:dice" % slot] = "rule:%d" % index
			slot += 1
	return result

## Structured rules are canonical. Recognize the old authored prose mirror,
## while preserving additional accepted prose that differs from that mirror.
func rules_text(data: Dictionary) -> String:
	var text := ""
	for raw in rules(data):
		var entry: Dictionary = raw
		text += ("\n\n" if not text.is_empty() else "") + str(entry.get("name", "")) + "\n" + str(entry.get("text", ""))
	return text

func rules_mirror(data: Dictionary) -> bool:
	var text := str(data.get("rules", ""))
	var definition: Dictionary = CREATURES.CORE_DEFINITIONS.get(str(data.get("definition_id", "")), {})
	return text.is_empty() or text == rules_text(data) or text == str(definition.get("rules", ""))

func title(field: String) -> String:
	return str({"name": "Name", "classification": "Classification", "hit_points": "Current HP", "maximum_hit_points": "Maximum HP", "morale": "Morale", "armor:name": "Armor name", "armor:reduction": "Armor formula", "armor:shield_reduction": "Shield reduction", "armor:defence_penalty": "Defence penalty", "dice": "Damage formula", "attack_dr": "Own Attack DR", "defence_dr": "Printed defence DR", "range_feet": "Range (feet)", "rules": "Creature rules", "text": "Creature rules"}.get(field, field.replace("_", " ").capitalize()))
