extends RefCounted
## Named accepted Creature capabilities, independent of loot and targets.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const OWN = preload(ROOT + "logic/creature_own_tests.gd")

func choice(data: Dictionary, part: String, entry: String) -> Dictionary:
	if part in ["damage", "attack"]:
		if typeof(data.get("attacks", [])) != TYPE_ARRAY:
			return {}
		var attacks: Array = data.get("attacks", [])
		for raw in attacks:
			if typeof(raw) != TYPE_DICTIONARY:
				continue
			var attack: Dictionary = raw
			if str(attack.get("id", "")) == entry:
				var identity := str(attack.get("correction_entry_id", "")) + "|" + entry
				var damage := _choice("Damage", str(attack.get("name", "Attack")), attack.get("dice"), "damage", entry, identity)
				if not damage.is_empty():
					damage["correction_id"] = str(attack.get("correction_entry_id", ""))
				if part == "damage":
					return damage
				var own := OWN.new().attack(data, attack)
				if own.is_empty():
					return {}
				var chosen := _choice("Attack", str(attack.get("name", "Attack")), "d20", part, entry, identity)
				chosen["difficulty"] = own.difficulty
				chosen["damage"] = damage
				chosen["correction_id"] = str(attack.get("correction_entry_id", ""))
				return chosen
	elif part == "defence":
		var own := OWN.new().defence(data)
		if not own.is_empty() and str(own.entry) == entry:
			var chosen := _choice("Defence", str(own.name), "d20", part, entry, str(own.correction_id) + "|" + entry)
			chosen["difficulty"] = own.difficulty
			return chosen
	elif part == "armor":
		if typeof(data.get("armor", {})) != TYPE_DICTIONARY:
			return {}
		var armor: Dictionary = data.get("armor", {})
		if str(armor.get("reduction", "")) in ["d2", "d4", "d6"]:
			return _choice("Protection", str(armor.get("name", "Armor")), armor.get("reduction"), part, "", "armor")
	elif part == "morale":
		if typeof(data.get("morale", {})) != TYPE_DICTIONARY:
			return {}
		var morale: Dictionary = data.get("morale", {})
		if str(morale.get("kind", "")) == "fixed" and typeof(morale.get("value")) == TYPE_INT:
			var chosen := _choice("Morale", "Morale", "2d6", part, "", "morale")
			chosen["morale"] = int(morale.value)
			return chosen
	elif part.begins_with("printed:"):
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
				if typeof(raw) != TYPE_DICTIONARY:
					continue
				var rule: Dictionary = raw
				if str(rule.get("id", "")) != entry or typeof(rule.get("rolls", [])) != TYPE_ARRAY:
					continue
				var rolls: Array = rule.get("rolls", [])
				for raw_roll in rolls:
					if typeof(raw_roll) != TYPE_DICTIONARY:
						continue
					var roll: Dictionary = raw_roll
					if str(roll.get("id", "")) == part.trim_prefix("printed:"):
						return _choice(str(roll.get("name", "Printed dice")), str(rule.get("name", "Creature rule")), roll.get("dice"), part, entry, str(rule.get("correction_entry_id", "")) + "|" + entry + "|" + str(roll.get("id", "")))
	return {}

func _choice(label: String, name: String, formula: Variant, part: String, entry: String, identity: String) -> Dictionary:
	if typeof(formula) != TYPE_STRING:
		return {}
	var accepted := plan(str(formula))
	if accepted.is_empty():
		return {}
	var normalized := ("" if int(accepted.count) == 1 else str(accepted.count)) + "d" + str(accepted.faces) + ("" if int(accepted.modifier) == 0 else "+" + str(accepted.modifier))
	return {"label": label, "name": name, "formula": str(formula).strip_edges().to_lower(), "normalized": normalized, "part": part, "entry": entry, "identity": identity, "plan": accepted}

## One explicit supported pool plus an integer modifier; never interpret prose.
func plan(formula: String) -> Dictionary:
	var terms := formula.strip_edges().to_lower().split("+")
	if terms.size() > 2:
		return {}
	var parts := terms[0].split("d")
	if parts.size() != 2:
		return {}
	var health := HEALTH.new()
	var count := health.integer("1" if parts[0].is_empty() else str(parts[0]))
	var faces := health.integer(str(parts[1]))
	var modifier := health.integer(str(terms[1])) if terms.size() == 2 else {"ok": true, "value": 0}
	if not count.ok or not faces.ok or not modifier.ok:
		return {}
	var number := int(count.value)
	var sides := int(faces.value)
	var addition := int(modifier.value)
	if number < 1 or number > 15 or not sides in [2, 4, 6, 8, 10, 12, 20]:
		return {}
	if addition > HEALTH.MAX_VALUE - sides * number:
		return {}
	return {"faces": sides, "physical_faces": 4 if sides == 2 else sides, "count": number, "modifier": addition}

func total(plan: Dictionary, faces: Array[int]) -> int:
	var result := 0
	for face in faces:
		result += int((face + 1) / 2) if int(plan.faces) == 2 else face
	return result + int(plan.modifier)

func outcome(choice: Dictionary, face: int) -> String:
	if face == 1:
		return "Fumble"
	if face == 20:
		return "Critical"
	return "Base succeeds" if face >= int(choice.difficulty) else "Base fails"

func text(choice: Dictionary, value: int, sequence: int, critical: bool = false) -> String:
	var label := str(choice.label)
	var formula := str(choice.normalized)
	var result := "%s: %s = %d. Raw Roll #%d." % [label, formula, value, sequence]
	if choice.part in ["attack", "defence"]:
		return "%s: d20 %d, DR%d — %s. Raw Roll #%d. Apply table modifiers and resolve consequences manually." % [label, value, int(choice.difficulty), outcome(choice, value), sequence]
	if critical:
		result += " Matching Attack critical: damage doubled."
	var plan: Dictionary = choice.plan
	if int(plan.faces) == 2:
		result += " Physical d4 faces map 1–2 to 1 and 3–4 to 2 before the modifier."
	if choice.part == "morale":
		result += " Morale %d: %s. Resolve the response at the table." % [int(choice.morale), "holds" if value <= int(choice.morale) else "fails"]
	else:
		result += " Resolve protection and consequences at the table." if choice.part == "damage" else " Resolve consequences at the table."
	return result
