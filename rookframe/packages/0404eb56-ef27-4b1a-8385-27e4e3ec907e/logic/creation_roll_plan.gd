extends RefCounted

## One ordered list drives both the next-roll action and equipment rows.
## Results insert their follow-up dice immediately after their source row.
func terms(draft: Dictionary, step: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var profile: Dictionary = draft.get("class_profile", {})
	if step == 2:
		var abilities: Dictionary = draft.get("abilities", {})
		for name in ["Agility", "Presence", "Strength", "Toughness"]:
			result.append(_term(name, 6, 3, abilities.has(name)))
		result.append(_term("Hit points", int(profile.get("hp_faces", 8)), 1, draft.has("hit_points_roll") or draft.has("hit_points")))
	elif step == 3:
		if draft.get("class_id", "") == "classless":
			return result
		for term in origin_terms(draft):
			var row := _term(term[0], term[1], 1, draft.has(term[2]))
			row["key"] = term[2]
			result.append(row)
	elif step == 4:
		var values: Dictionary = draft.get("equipment_rolls", {})
		for term in [["Silver", 6, int(profile.get("silver_count", 2))], ["Omens", int(profile.get("omen_faces", 2)), 1], ["Food", 4, 1], ["Equipment pack", 6, 1], ["Equipment first", 12, 1], ["Equipment second", 12, 1]]:
			result.append(_term(term[0], term[1], term[2], values.has(term[0])))
			if term[0] == "Equipment first":
				if int(values.get(term[0], 0)) == 5 and draft.get("class_id") != "fanged-deserter":
					result.append(_term("Unclean scroll", 10, 1, values.has("Unclean scroll")))
				if int(values.get(term[0], 0)) == 11:
					result.append(_term("Red poison doses", 4, 1, values.has("Red poison doses")))
			if term[0] == "Equipment second":
				var second_roll := int(values.get(term[0], 0))
				if second_roll == 1:
					result.append(_term("Life elixir doses", 4, 1, values.has("Life elixir doses")))
				elif second_roll == 2 and draft.get("class_id") != "fanged-deserter":
					result.append(_term("Sacred scroll", 10, 1, values.has("Sacred scroll")))
				elif second_roll == 3:
					result.append(_term("Dog hit points", 6, 1, values.has("Dog hit points")))
				elif second_roll == 4:
					result.append(_term("Monkey count", 4, 1, values.has("Monkey count")))
					for index in range(int(values.get("Monkey count", 0))):
						var name := "Monkey %d hit points" % (index + 1)
						result.append(_term(name, 4, 1, values.has(name)))

		if draft.get("class_id") == "esoteric-hermit":
			result.append(_term("Hermit scroll family", 2, 1, values.has("Hermit scroll family")))
			result.append(_term("Hermit scroll", 10, 1, values.has("Hermit scroll")))
		var has_scroll := (int(values.get("Equipment first", 0)) == 5 and not scroll_disposed(draft, "first")) or (int(values.get("Equipment second", 0)) == 2 and not scroll_disposed(draft, "second"))
		var equipment_known := values.has("Equipment first") and values.has("Equipment second") and scroll_choice(draft).is_empty()
		for arms in [["Weapon", "weapon_faces", 10, 6], ["Armor", "armor_faces", 4, 2]]:
			var faces := int(profile.get(arms[1], arms[2]))
			var fixed: bool = bool(profile.get("fixed_arms", false)) or draft.get("class_id") == "fanged-deserter"
			var available := fixed or faces <= int(arms[3]) or equipment_known or has_scroll
			if has_scroll and not fixed:
				faces = mini(faces, int(arms[3]))
			var row := _term(arms[0], faces, 1, values.has(arms[0]))
			row["available"] = available
			result.append(row)
	return result

func origin_terms(draft: Dictionary) -> Array:
	var profile: Dictionary = draft.get("class_profile", {})
	var result: Array = [["Origin", int(profile.get("origin_faces", 6)), "origin_roll"]]
	var class_id := str(draft.get("class_id", ""))
	if class_id == "wretched-royalty":
		result.append(["First gift", 6, "feature_roll"])
		result.append(["Second gift", 6, "second_feature_roll"])
	elif class_id == "occult-herbmaster":
		result.append(["First decoction", 8, "first_decoction_roll"])
		result.append(["Second decoction", 8, "second_decoction_roll"])
		result.append(["Decoction doses", 4, "decoction_doses"])
	else:
		result.append(["Class feature", 6, "feature_roll"])

	return result

func scroll_disposed(draft: Dictionary, slot: String) -> bool:
	var dispositions: Array = draft.get("scroll_dispositions", [])
	for raw in dispositions:
		var disposition: Dictionary = raw
		if disposition.get("slot") == slot and disposition.get("disposition") != "reroll":
			return true
	return false

func scroll_choice(draft: Dictionary) -> String:
	if draft.get("class_id") != "fanged-deserter":
		return ""
	var totals: Dictionary = draft.get("equipment_rolls", {})
	for slot in [["first", "Equipment first", 5], ["second", "Equipment second", 2]]:
		if int(totals.get(slot[1], 0)) == slot[2] and not scroll_disposed(draft, slot[0]):
			return slot[0]
	return ""

func _term(name: String, faces: int, count: int, complete: bool) -> Dictionary:
	return {"name": name, "faces": faces, "count": count, "complete": complete, "available": true}

