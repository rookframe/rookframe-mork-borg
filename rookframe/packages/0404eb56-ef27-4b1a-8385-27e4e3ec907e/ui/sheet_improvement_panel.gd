extends VBoxContainer

func configure(data: Dictionary, action: Dictionary, phone: bool, prepared: bool, ending: bool) -> void:
	var results: Dictionary = action.get("results", {})
	var hp_roll: Dictionary = results.get("more_hp", {})
	var phase := str(action.get("phase", ""))
	var state := str(action.get("state", ""))
	var hp := phase in ["more_hp", "hp_increase"] or (action.is_empty() and prepared)
	var debris := phase in ["debris", "silver", "scroll"]
	var abilities := phase == "abilities"
	get_node("Heading/Inset/Title").text = "END THIS IMPROVEMENT?" if ending else "IMPROVEMENT COMPLETE" if state == "resolved" else "WHEN THE GM GRANTS AN IMPROVEMENT" if action.is_empty() and not prepared else "MORE HP" if hp else "DEBRIS" if debris else "ABILITY CHANGES" if abilities else "CLASS" if state != "resolved" else "IMPROVEMENT COMPLETE"
	get_node("Body/Content/Explanation").text = "Accepted results stay on the sheet." if ending else "Resolve three steps, in order: More HP, Debris, and Ability changes. Apply your class's additional steps where required." if action.is_empty() and not prepared else "Roll 6d10 against %d maximum HP." % int(hp_roll.get("maximum", data.get("maximum_hit_points", 1))) if hp else "Roll d6 to see what you find in the debris." if debris else "Roll a separate d6 against every ability modifier." if abilities else str(action.get("message", ""))
	get_node("Body/Content/Rules").text = "Maximum HP: %d. Current HP: %d. Silver: %d. Resolve unfinished steps with the table. Ending cannot be resumed or rerolled here." % [int(data.get("maximum_hit_points", 1)), int(data.get("hit_points", 0)), int(data.get("silver", 0))] if ending else "6d10 against maximum HP; a qualifying result adds d6. Find nothing, Silver, or a scroll. Roll against every modifier; some may decrease." if action.is_empty() and not prepared else "Equal or greater: increase maximum HP by d6. Current HP stays unchanged." if hp else "1–3: Nothing · 4: 3d10 Silver · 5: Unclean scroll · 6: Sacred scroll" if debris else "At −3…+1, 1 lowers and 2–6 raises. At +2 or higher, equal/greater raises and lower reduces. Modifiers stay within −3…+6." if abilities else "Accepted results remain on the sheet."
	get_node("Body/Content/Result").visible = not ending and ((hp and results.has("more_hp")) or (debris and results.has("debris")) or results.has("class") and phase in ["class", "specialty_roll"])
	var faces := ""
	var value := ""
	var copy := ""
	if hp and results.has("more_hp"):
		var roll: Dictionary = results.more_hp
		faces = "6d10 · " + _faces(roll.faces)
		value = "%d %s %d" % [int(roll.total), "≥" if roll.qualifies else "<", int(roll.maximum)]
		copy = "The roll qualifies. Roll d6 for the increase." if roll.qualifies else "Maximum HP stays unchanged."
		if results.has("hp_increase"):
			var increase: Dictionary = results.hp_increase
			copy = "d6: %d · Maximum HP: %d → %d. Current HP: %d." % [int(increase.roll), int(increase.before), int(increase.after), int(increase.current)]
	elif debris and results.has("debris"):
		var roll: Dictionary = results.debris
		faces = "Debris d6 · " + str(roll.roll)
		value = str(roll.outcome)
		if results.has("silver"):
			var silver: Dictionary = results.silver
			copy = "3d10 · %s = %d Silver. %d → %d." % [_faces(silver.faces), int(silver.total), int(silver.before), int(silver.after)]
		elif results.has("scroll"):
			copy = str(results.scroll) + " added to Inventory and Powers."
		else:
			copy = "Choose the scroll agreed with the table." if state == "scroll" else "Accepted debris result."
	elif results.has("class"):
		copy = str(results["class"])
	get_node("Body/Content/Result/Inset/Content/Faces").text = faces
	get_node("Body/Content/Result/Inset/Content/Value").text = value
	get_node("Body/Content/Result/Inset/Content/Copy").text = copy
	get_node("Body/Content/Abilities").visible = abilities and not ending
	var rows = {"Strength": "Body/Content/Abilities/Strength", "Agility": "Body/Content/Abilities/Agility", "Presence": "Body/Content/Abilities/Presence", "Toughness": "Body/Content/Abilities/Toughness"}
	var current_abilities: Dictionary = data.get("abilities", {})
	for ability in ["Strength", "Agility", "Presence", "Toughness"]:
		var row_path: String = rows.get(str(ability), "Body/Content/Abilities/Strength")
		var current: Dictionary = current_abilities.get(ability, {})
		(get_node(row_path + "/Roll") as Label).text = "d6"
		(get_node(row_path + "/Change") as Label).text = "%+d" % int(current.get("modifier", 0))
	var changes: Array = results.get("abilities", [])
	for raw in changes:
		var change: Dictionary = raw
		var row_path: String = rows.get(str(change.ability), "Body/Content/Abilities/Strength")
		(get_node(row_path + "/Roll") as Label).text = "d6 · " + str(change.roll)
		(get_node(row_path + "/Change") as Label).text = "%+d → %+d" % [int(change.before), int(change.after)]
	var tablet := get_viewport_rect().size.x <= 1150 and not phone
	add_theme_constant_override("separation", 0)
	get_node("Body/Content").add_theme_constant_override("separation", 8 if phone else 14 if tablet else 20)
	for edge in ["left", "right", "top", "bottom"]:
		get_node("Body").add_theme_constant_override("margin_" + edge, 10 if phone else 16 if tablet else 24)
		get_node("Heading/Inset").add_theme_constant_override("margin_" + edge, (10 if phone else 20) if edge in ["left", "right"] else 6 if phone else 12)

	get_node("Body/Content/Steps").visible = action.is_empty() and not prepared and not ending
	get_node("Body/Content/Steps").vertical = not phone
	get_node("Body/Content/Rules").visible = not get_node("Body/Content/Steps").visible and not debris
	for path in ["Body/Content/Steps/Step1", "Body/Content/Steps/Step2", "Body/Content/Steps/Step3"]:
		(get_node(path + "/Number") as Control).add_theme_font_size_override("font_size", 19 if phone else 26)
		(get_node(path + "/Copy/Title") as Control).add_theme_font_size_override("font_size", 13 if phone else 18)
		(get_node(path + "/Copy/Text") as Control).add_theme_font_size_override("font_size", 12 if phone else 16)
	get_node("Body/Content/DebrisKey").visible = debris and not ending
	get_node("Body/Content/DebrisKey").columns = 4 if phone else 2
	for path in ["Body/Content/DebrisKey/Nothing", "Body/Content/DebrisKey/Silver", "Body/Content/DebrisKey/Unclean", "Body/Content/DebrisKey/Sacred"]:
		get_node(path).vertical = phone
		get_node(path).add_theme_constant_override("separation", 4 if phone else 12)
		(get_node(path + "/Face") as Control).add_theme_font_size_override("font_size", 12 if phone else 16)
		(get_node(path + "/Result") as Control).add_theme_font_size_override("font_size", 12 if phone else 16)
	for path in ["Body/Content/Abilities/Strength", "Body/Content/Abilities/Agility", "Body/Content/Abilities/Presence", "Body/Content/Abilities/Toughness"]:
		var row_path: String = path
		var row = get_node(path)
		row.columns = 4 if phone else 3
		row.custom_minimum_size = Vector2(row.custom_minimum_size.x, 50 if phone else 65)
		(get_node(row_path + "/Spacer") as Control).visible = not phone
		(get_node(row_path + "/EndSpacer") as Control).visible = not phone
		(get_node(row_path + "/Icon") as Control).custom_minimum_size = Vector2(22, 22) if phone else Vector2(26, 26)
		(get_node(row_path + "/Name") as Control).add_theme_font_size_override("font_size", 13 if phone else 18)
		(get_node(row_path + "/Roll") as Control).add_theme_font_size_override("font_size", 12 if phone else 16)
		(get_node(row_path + "/Change") as Control).add_theme_font_size_override("font_size", 23 if phone else 30)
	get_node("Heading/Inset/Title").add_theme_font_size_override("font_size", 13 if phone else 16)
	get_node("Body/Content/Explanation").add_theme_font_size_override("font_size", 15 if phone else 20)
	get_node("Body/Content/Rules").add_theme_font_size_override("font_size", 12 if phone else 16)
	get_node("Body/Content/Result/Inset/Content/Value").add_theme_font_size_override("font_size", 30 if phone else 42)
	get_node("Body/Content/Result/Inset/Content/Copy").add_theme_font_size_override("font_size", 12 if phone else 16)
	for edge in ["left", "right", "top", "bottom"]:
		get_node("Body/Content/Result/Inset").add_theme_constant_override("margin_" + edge, (14 if phone else 24) if edge in ["left", "right"] else 10 if phone else 18)

func _faces(values: Array) -> String:
	var result := ""
	for value in values:
		result += (" + " if not result.is_empty() else "") + str(value)
	return result
