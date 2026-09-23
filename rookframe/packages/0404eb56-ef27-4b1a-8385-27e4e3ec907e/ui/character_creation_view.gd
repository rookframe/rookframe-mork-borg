extends BoxContainer

const ROLL_ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creation_roll.gd")

const ABILITIES := ["Agility", "Presence", "Strength", "Toughness", "Hit points"]
const EQUIPMENT := ["Silver", "Omens", "Food", "Equipment pack", "Equipment first", "Equipment second", "Weapon", "Armor"]
const EQUIPMENT_FORMULAS := ["2d6 × 10", "1d2", "1d4 days", "1d6", "1d12", "1d12", "1d10", "1d4"]

func present_creation(route: String, draft: Dictionary, compact: bool) -> void:
	var equipment_pending: bool = draft.get("equipment_roll_pending", false)
	var ability_pending: bool = draft.get("roll_pending", false)
	vertical = compact
	get_node(^"Main").theme_type_variation = "RookframePackageInk" if compact else "RookframeSection"
	add_theme_constant_override("separation", 12 if compact else 20)
	var stages := ["Class", "Abilities", "Origin", "Equipment", "Identity", "Review"]
	var selected: String = {"create-class": "Class", "create-abilities": "Abilities", "create-rolling": "Abilities", "create-origin": "Origin", "create-equipment": "Equipment", "create-identity": "Identity", "create-review": "Review"}.get(route, "Class")
	for stage in stages:
		get_node("Main/Content/" + stage).visible = stage == selected
	get_node(^"Main/Content/Title").text = "ROLL ABILITIES" if selected == "Abilities" else ("STARTING EQUIPMENT" if selected == "Equipment" else selected.to_upper())
	get_node(^"Main/Content/Title").visible = not (compact and selected in ["Abilities", "Class"])
	get_node(^"Aside").visible = not (compact and selected == "Abilities")
	get_node(^"Aside/Context/Content/Pack").visible = selected == "Equipment" and not equipment_pending
	get_node(^"Aside/Context/Content/PreferredMiniature").visible = selected == "Identity"
	get_node(^"Aside/Context/Content/Title").text = "PREFERRED MINIATURE" if selected == "Identity" else ("EQUIPMENT PACK" if selected == "Equipment" else "NO CLASS")
	var description := "Starting attributes and equipment follow the classless tables."
	var facts := "Hit points\nToughness + 1d8\n\nSilver\n2d6 × 10\n\nOmens\n1d2"
	var hint := "Your character is created after the final review."
	if selected == "Abilities":
		description = "Rolls resolve in order. Dice are rolled automatically on your behalf."
		facts = "Normal ability rolls\n3d6 for each ability\n\nHit points\n1d8 + Toughness (minimum 1)"
		hint = "Rolling %s…" % str(draft.get("active_roll", "abilities")) if ability_pending else "Continue when all ability rolls are complete."
		_present_abilities(draft, compact)
	elif selected == "Origin":
		description = "No class origin or traits."
		facts = "Your identity and description come next."
	elif selected == "Equipment":
		description = "Choose from the packs available for your roll."
		facts = _inventory_text(draft.get("inventory", []))
		hint = "Rolling %s…" % str(draft.get("active_roll", "equipment")) if equipment_pending else "Starting equipment is ready."
		get_node(^"Aside/Context/Content/Pack").text = "Pack: %s" % str(draft.get("pack", "Nothing"))
		_present_equipment(draft, compact)
	elif selected == "Identity":
		description = "Preferred appearance for this Actor’s Rooks."
		facts = ""
		hint = "You can edit the completed sheet after creation."
		get_node(^"Main/Content/Identity/Name").value = str(draft.get("name", ""))
		get_node(^"Main/Content/Identity/Description").value = str(draft.get("description", ""))
	elif selected == "Review":
		description = "No class origin or traits."
		var creatures: Array = draft.get("starting_creature_ids", [])
		facts = "Starting creatures: %d" % creatures.size()
		hint = "You can edit the sheet after creating the character."
		get_node(^"Main/Content/Review/Name").text = str(draft.get("name", "Unnamed Character"))
		get_node(^"Main/Content/Review/Resources").text = "HP %s     Omens %s     Silver %s" % [str(draft.get("hit_points", 0)), str(draft.get("omens", 0)), str(draft.get("silver", 0))]
		var values: Array[String] = []
		var abilities: Dictionary = draft.get("abilities", {})
		for ability in ["Agility", "Presence", "Strength", "Toughness"]:
			var value: Dictionary = abilities.get(ability, {})
			var modifier: int = value.get("modifier", 0)
			values.append("%s  %s → %s" % [ability, str(value.get("score", "—")), _modifier(modifier)])
		get_node(^"Main/Content/Review/Abilities").text = _lines(values)
		get_node(^"Main/Content/Review/Description").text = str(draft.get("description", ""))
		get_node(^"Main/Content/Review/Inventory").text = _inventory_text(draft.get("inventory", []))
	get_node(^"Aside/Context/Content/Description").text = description
	get_node(^"Aside/Context/Content/Facts").text = facts
	get_node(^"Aside/Hint").text = hint


func _present_abilities(draft: Dictionary, compact: bool) -> void:
	var ready: bool = draft.get("roll_ready", false)
	var values: Dictionary = draft.get("abilities", {})
	var rows := [get_node(^"Main/Content/Abilities/Agility"), get_node(^"Main/Content/Abilities/Presence"), get_node(^"Main/Content/Abilities/Strength"), get_node(^"Main/Content/Abilities/Toughness"), get_node(^"Main/Content/Abilities/HitPoints")]
	for index in range(5):
		var title: String = ABILITIES[index]
		var complete: bool = values.has(title) if index < 4 else draft.has("hit_points")
		var current := title == str(draft.get("active_roll", ""))
		var result := "—"
		if complete:
			if index < 4:
				var ability: Dictionary = values[title]
				var modifier: int = ability.get("modifier", 0)
				result = "%s → %s" % [str(ability.get("score", 0)), _modifier(modifier)]
			else:
				result = str(draft.get("hit_points", 0))
		elif current and not ready:
			result = "Rolling…"
		var row: ROLL_ROW = rows[index]
		row.present_roll(title, "3d6" if index < 4 else "1d8 + Toughness", result, "complete" if complete else (("current" if ready else "pending") if current else "locked"), index + 1, compact)


func _present_equipment(draft: Dictionary, compact: bool) -> void:
	var ready: bool = draft.get("roll_ready", false)
	var values: Dictionary = draft.get("equipment_rolls", {})
	var rows := [get_node(^"Main/Content/Equipment/Silver"), get_node(^"Main/Content/Equipment/Omens"), get_node(^"Main/Content/Equipment/Food"), get_node(^"Main/Content/Equipment/Pack"), get_node(^"Main/Content/Equipment/First"), get_node(^"Main/Content/Equipment/Second"), get_node(^"Main/Content/Equipment/Weapon"), get_node(^"Main/Content/Equipment/Armor")]
	for index in range(EQUIPMENT.size()):
		var title: String = EQUIPMENT[index]
		var complete: bool = values.has(title)
		var current := title == str(draft.get("active_roll", ""))
		var result: String = str(values[title]) if complete else ("Rolling…" if current and not ready else "—")
		if complete and title == "Silver":
			var silver_roll: int = values[title]
			result = str(silver_roll * 10)
		var row: ROLL_ROW = rows[index]
		row.present_roll(title, EQUIPMENT_FORMULAS[index], result, "complete" if complete else (("current" if ready else "pending") if current else "locked"), index + 1, compact)


func _inventory_text(items: Array) -> String:
	var names: Array[String] = []
	for item in items:
		var item_data: Dictionary = item
		names.append(str(item_data.get("name", "Item")))
	return _lines(names)


func _modifier(value: int) -> String:
	return "%+d" % value


func _lines(values: Array[String]) -> String:
	var text := ""
	for value in values:
		var line: String = value
		text += ("\n" if not text.is_empty() else "") + line
	return text
