extends RefCounted
## Explicit workflow projection of accepted creature data. Never infer actions from prose.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const SPECIALS := {"lich-necromancer": ["scroll-theft"], "bone-bowyer": ["ambush"]}

func specials(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var accepted := CREATURES.new().stat_block(data)
	var keys: Array = SPECIALS.get(str(accepted.get("definition_id", "")), [])
	var groups: Array = accepted.get("rule_groups", [])
	for raw in groups:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		var group: Dictionary = raw
		var entries: Array = group.get("entries", [])
		for entry in entries:
			if typeof(entry) == TYPE_DICTIONARY:
				var rule: Dictionary = entry
				if str(rule.get("id", "")) in keys:
					result.append(rule.duplicate(true))
	return result
