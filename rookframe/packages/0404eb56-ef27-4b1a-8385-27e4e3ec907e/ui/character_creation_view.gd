extends BoxContainer

const CHECK = preload("res://rookframe/ui/icons/check.svg")
const ROLL_ROW = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/character_creation_roll.gd")

signal class_selected(class_id: String)
signal scroll_selected(slot: String, disposition: String)

var _scroll_slot := ""
const CLASS_NODES: Dictionary = {"NoClass": "classless", "FangedDeserter": "fanged-deserter", "GutterbornScum": "gutterborn-scum", "EsotericHermit": "esoteric-hermit"}

func _ready() -> void:
	for node in ["NoClass", "FangedDeserter", "GutterbornScum", "EsotericHermit"]:
		get_node("Main/Content/Class/" + node).pressed.connect(_select_class.bind(CLASS_NODES[node]))
	for choice in ["Reroll", "Eat", "Paper"]:
		get_node("Main/Content/Equipment/ScrollChoice/" + choice).pressed.connect(_select_scroll.bind({"Reroll": "reroll", "Eat": "eat", "Paper": "toilet-paper"}[choice]))

func _select_class(class_id: String) -> void:
	class_selected.emit(class_id)

func _select_scroll(disposition: String) -> void:
	scroll_selected.emit(_scroll_slot, disposition)

const ABILITIES := ["Agility", "Presence", "Strength", "Toughness", "Hit points"]
const EQUIPMENT := ["Silver", "Omens", "Food", "Equipment pack", "Equipment first", "Equipment second", "Weapon", "Armor"]
const EQUIPMENT_FORMULAS := ["2d6 × 10", "1d2", "1d4 days", "1d6", "1d12", "1d12", "1d10", "1d4"]

func present_creation(route: String, draft: Dictionary, compact: bool) -> void:
	var profile: Dictionary = draft.get("class_profile", {})
	var class_title: String = draft.get("class_title", "No Class")
	_scroll_slot = str(draft.get("scroll_choice_slot", ""))
	get_node(^"Main/Content/Class").columns = 2
	for node in ["NoClass", "FangedDeserter", "GutterbornScum", "EsotericHermit"]:
		var choice := get_node("Main/Content/Class/" + node) as Button
		choice.button_pressed = CLASS_NODES[node] == draft.get("class_id", "classless")
		choice.icon = CHECK if choice.button_pressed else null
	get_node(^"Main/Content/Equipment/ScrollChoice").visible = not _scroll_slot.is_empty()
	var equipment_pending: bool = draft.get("equipment_roll_pending", false)
	var roll_ready: bool = draft.get("roll_ready", false)
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
	get_node(^"Aside/Context/Content/Title").text = "PREFERRED MINIATURE" if selected == "Identity" else ("EQUIPMENT PACK" if selected == "Equipment" else class_title.to_upper())
	var hp_faces: int = profile.get("hp_faces", 8)
	var silver_count: int = profile.get("silver_count", 2)
	var omen_faces: int = profile.get("omen_faces", 2)
	var description := _rules_text(draft)
	var facts := "Hit points\nToughness + 1d%d\n\nSilver\n%dd6 × 10\n\nOmens\n1d%d" % [hp_faces, silver_count, omen_faces]
	var hint := "Your character is created after the final review."
	if selected == "Abilities":
		description = "Rolls resolve in order. Dice are rolled automatically on your behalf."
		facts = "Hit points\n1d%d + Toughness (minimum 1)" % hp_faces
		hint = "Rolling %s…" % str(draft.get("active_roll", "abilities")) if ability_pending and not roll_ready else "Continue with the next ability when ready."
		_present_abilities(draft, compact)
	elif selected == "Origin":
		description = str(draft.get("origin", ""))
		facts = _traits_text(draft)
		_present_origin(draft, compact)
	elif selected == "Equipment":
		description = "Choose from the packs available for your roll."
		facts = _inventory_text(draft.get("inventory", []))
		hint = "Rolling %s…" % str(draft.get("active_roll", "equipment")) if equipment_pending and not roll_ready else "Continue with the next roll when ready."
		get_node(^"Aside/Context/Content/Pack").text = "Pack: %s" % str(draft.get("pack", "Nothing"))
		_present_equipment(draft, compact)
	elif selected == "Identity":
		description = "Preferred appearance for this Actor’s Rooks."
		facts = ""
		hint = "You can edit the completed sheet after creation."
		get_node(^"Main/Content/Identity/Name").value = str(draft.get("name", ""))
		get_node(^"Main/Content/Identity/Description").value = str(draft.get("description", ""))
	elif selected == "Review":
		description = _traits_text(draft)
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
		get_node(^"Main/Content/Review/Description").text = class_title + "\n" + str(draft.get("origin", "")) + "\n" + str(draft.get("description", ""))
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
		row.present_roll(title, _ability_formula(title, draft), result, "complete" if complete else (("current" if ready else "pending") if current else "locked"), index + 1, compact)


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
		row.present_roll(title, _equipment_formula(title, draft, EQUIPMENT_FORMULAS[index]), result, "complete" if complete else (("current" if ready else "pending") if current else "locked"), index + 1, compact)

	var extra: ROLL_ROW = get_node(^"Main/Content/Equipment/ExtraRoll")
	var active: String = draft.get("active_roll", "")
	var pending: bool = draft.get("equipment_roll_pending", false)
	extra.visible = not EQUIPMENT.has(active) and not active.is_empty() and pending
	if extra.visible:
		extra.present_roll(active, str(draft.get("active_roll_formula", "")), "Ready" if ready else "Rolling…", "current" if ready else "pending", 7, compact)


func _ability_formula(title: String, draft: Dictionary) -> String:
	var profile: Dictionary = draft.get("class_profile", {})
	if title == "Hit points":
		var hp_faces: int = profile.get("hp_faces", 8)
		return "1d%d + Toughness" % hp_faces
	var offsets: Dictionary = profile.get("ability_offsets", {})
	var offset: int = offsets.get(title, 0)
	return "3d6" + ("%+d" % offset if offset != 0 else "")


func _equipment_formula(title: String, draft: Dictionary, fallback: String) -> String:
	var profile: Dictionary = draft.get("class_profile", {})
	if title == "Silver":
		var silver_count: int = profile.get("silver_count", 2)
		return "%dd6 × 10" % silver_count
	if title == "Omens":
		var omen_faces: int = profile.get("omen_faces", 2)
		return "1d%d" % omen_faces
	if title == "Weapon" or title == "Armor":
		var faces: int = profile.get("weapon_faces" if title == "Weapon" else "armor_faces", 10 if title == "Weapon" else 4)
		var totals: Dictionary = draft.get("equipment_rolls", {})
		if totals.has("Unclean scroll") or totals.has("Sacred scroll"):
			var limit := 6 if title == "Weapon" else 2
			if faces > limit:
				faces = limit
		return "1d%d" % faces
	return fallback


func _present_origin(draft: Dictionary, compact: bool) -> void:
	var classless := str(draft.get("class_id", "classless")) == "classless"
	get_node(^"Main/Content/Origin/Explanation").text = "No class origin or traits." if classless else str(draft.get("origin", "Your origin and class feature are determined by two Rolls."))
	get_node(^"Main/Content/Origin/Continue").text = "Continue to starting equipment." if classless else _traits_text(draft)
	for entry in [["OriginRoll", "Origin", "origin_roll"], ["FeatureRoll", "Class feature", "feature_roll"]]:
		var row: ROLL_ROW = get_node("Main/Content/Origin/" + entry[0])
		row.visible = not classless
		var complete := draft.has(entry[2])
		var current: bool = str(draft.get("active_roll", "")) == entry[1]
		var ready: bool = draft.get("roll_ready", false)
		row.present_roll(entry[1], "1d6", str(draft[entry[2]]) if complete else ("Rolling…" if current and not ready else "—"), "complete" if complete else ("current" if current and ready else "pending" if current else "locked"), 1 if entry[0] == "OriginRoll" else 2, compact)


func _rules_text(draft: Dictionary) -> String:
	var rules: Array = draft.get("class_rules", [])
	var result := ""
	for rule in rules:
		result += ("\n" if not result.is_empty() else "") + str(rule)
	return result if not result.is_empty() else "Normal ability rolls and starting equipment."


func _traits_text(draft: Dictionary) -> String:
	var result := ""
	var traits: Array = draft.get("traits", [])
	for raw_trait in traits:
		var trait_data: Dictionary = raw_trait
		result += str(trait_data.get("name", "")) + "\n" + str(trait_data.get("rules", ""))
	return result


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
