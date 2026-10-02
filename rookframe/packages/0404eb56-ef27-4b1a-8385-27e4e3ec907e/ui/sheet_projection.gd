extends RefCounted

## Presentation values, without changing the System's gameplay data.
const ABILITIES := ["Strength", "Agility", "Presence", "Toughness"]
const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const POWERS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/powers.gd")
const HEART = preload("res://rookframe/ui/icons/character/heart.svg")
const MAGIC = preload("res://rookframe/ui/icons/character/palms.svg")
const DICE = preload("res://rookframe/ui/icons/character/dice.svg")
const HERBS = preload("res://rookframe/ui/icons/character/herbs.svg")
const BAG = preload("res://rookframe/ui/icons/character/bag.svg")
const BOOK = preload("res://rookframe/ui/icons/character/book.svg")
const SILVER = preload("res://rookframe/ui/icons/character/silver.svg")
const CLASSES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd")
const BROKEN = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/broken_incident.gd")

func fields(data: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for field in ["name", "description", "origin", "class_title", "pack", "hit_points", "maximum_hit_points", "omens", "power_uses", "silver", "improvements"]:
		values[str(field)] = str(data.get(str(field), {"hit_points": 0, "maximum_hit_points": 1, "omens": 0, "power_uses": 0, "silver": 0, "improvements": 0}.get(str(field), "")))
	values["class_rules"] = text(data.get("class_rules", []))
	var abilities: Dictionary = data.get("abilities", {})
	for field in ABILITIES:
		var ability: Dictionary = abilities.get(str(field), {})
		values[str(field)] = str(ability.get("modifier", 0))
	for family in ["trait", "companion"]:
		var entries: Array = data.get("traits" if family == "trait" else "companion_sheets", [])
		for index in range(entries.size()):
			var entry: Dictionary = entries[index]
			for field in ["name", "rules", "uses"]:
				if field == "uses" and not entry.has("uses"):
					continue
				values["%s:%d:%s" % [family, index, field]] = str(entry.get(str(field), ""))
	if str(data.get("class_id", "")) == "gutterborn-scum":
		var traits: Array = data.get("traits", [])
		for index in range(2):
			var trait_entry: Dictionary = traits[index] if index < traits.size() else {}
			var selected := 0
			for face in range(1, 7):
				var feature := CLASSES.new().feature("gutterborn-scum", face)
				if str(feature.id) == str(trait_entry.get("id", "")):
					selected = face
			values["scum_specialty:%d" % index] = str(selected)
	return values

func identities(data: Dictionary) -> Dictionary:
	var values: Dictionary = {}
	for family in ["trait", "companion"]:
		var entries: Array = data.get("traits" if family == "trait" else "companion_sheets", [])
		for index in range(entries.size()):
			var entry: Dictionary = entries[index]
			values["%s:%d" % [family, index]] = str(entry.get("id", "")) + "|" + str(entry.get("source_item_id", ""))
	return values

func text(value: Variant) -> String:
	if typeof(value) == TYPE_ARRAY:
		var text := ""
		var values: Array = value
		for line in values:
			text += ("\n" if not text.is_empty() else "") + str(line)
		return text
	return str(value)

func row(id: String, title: String, subtitle: String = "", value: String = "", icon: Texture2D = null) -> Dictionary:
	if icon == null:
		icon = HERBS if id == "class" or id.begins_with("trait:") else BOOK if id.begins_with("injury:") else BAG
	return {"id": id, "title": title, "subtitle": subtitle, "value": value, "icon": icon}

func condition(data: Dictionary) -> Dictionary:
	var hp := int(data.get("hit_points", 0))
	var incident: Dictionary = data.get("broken_incident", {})
	var outcome := int(incident.get("outcome", 0))
	var elapsed := int(incident.get("elapsed", 0))
	var duration := int(incident.get("duration", 0))
	if hp < 0 or incident.get("dead", false):
		return {"title": "DEAD", "copy": "Negative HP means death." if hp < 0 else ("Untreated hemorrhage reached its deadline." if outcome == 3 else "Broken d4: 4 · Dead.")}
	if BROKEN.new().can_complete_followup(data):
		return {"title": "Broken", "copy": "Broken d4: %d is retained. Complete its follow-up dice; the initial outcome is not rerolled." % outcome}
	if outcome == 3 and not incident.get("treated", false):
		return {"title": "Hemorrhage", "copy": "Treatment stops the hemorrhage. Every test is harder while it continues."}
	if outcome in [1, 2] and not incident.get("recovered", false):
		return {"title": "Unconscious" if outcome == 1 else "Unable to act", "copy": "You cannot act until you awaken." if outcome == 1 else str(incident.get("injury", "Injured")) + ". You cannot act until recovery is due."}
	if hp == 0 and outcome == 3 and incident.get("treated", false):
		return {"title": "TREATED", "copy": "Bleeding stopped. 0 HP. Record HP when healing is resolved; treatment does not restore HP."}
	if hp == 0 and outcome == 0:
		return {"title": "Broken", "copy": "Roll once to find out what happens to you."}
	return {}

func collections(data: Dictionary, items: Array, chapter: int, actor_id: String, facade: SDK, filter: int = 0, owner: bool = true) -> Dictionary:
	var primary: Array[Dictionary] = []
	var resources: Array[Dictionary] = []
	var companions: Array[Dictionary] = []
	var heading := "FEATURES & TRAITS"
	if chapter == 0:
		primary.append(row("class", str(data.get("class_title", "Class")), "Class feature"))
		var traits: Array = data.get("traits", [])
		for index in range(traits.size()):
			var trait_entry: Dictionary = traits[index]
			primary.append(row("trait:%d" % index, str(trait_entry.get("name", "Feature")), str(trait_entry.get("rules", "")), str(trait_entry.get("uses", ""))))
		var injuries: Array = data.get("broken_injuries", [])
		for index in range(injuries.size()):
			var injury: Dictionary = injuries[index]
			primary.append(row("injury:%d" % index, str(injury.get("name", "Injury")), "Retained injury"))
		for key in ["hit_points", "omens", "power_uses", "silver"]:
			var title: String = {"hit_points": "Hit points", "omens": "Omens", "power_uses": "Power uses", "silver": "Silver"}.get(str(key), "Resource")
			resources.append(row("resource:" + str(key), title, "remaining", str(data.get(str(key), 0)), HEART if key == "hit_points" else MAGIC if key == "power_uses" else SILVER if key == "silver" else DICE))
		var descriptions: Array = data.get("companion_sheets", [])
		for index in range(descriptions.size()):
			var companion: Dictionary = descriptions[index]
			companions.append(row("companion:%d" % index, str(companion.get("name", "Companion")), "Companion"))
		var actors := facade.actors.list()
		if actors.ok:
			for actor in actors.items:
				var other: Dictionary = actor.data
				var starting := not str(data.get("creation_id", "")).is_empty() and str(other.get("creation_id", "")) == str(data.get("creation_id", ""))
				if str(other.get("schema", "")) == "mork-borg-adversary/v1" and (starting or str(other.get("summoner_actor", "")) == actor_id):
					companions.append(row("actor:" + actor.id.value, str(other.get("name", "Creature")), "Separate Actor", "%d HP" % int(other.get("hit_points", 0))))
	elif chapter == 1:
		heading = "POWERS"
		for raw in items:
			var item: Dictionary = raw
			var power := POWERS.new().definition(str(item.get("source_item_id", "")))
			if not power.is_empty():
				primary.append(row("item:" + str(item.inventory_id), str(item.get("name", "Power")), str(power.get("rules", "")), "Spent" if int(item.get("quantity", 0)) < 1 else str(item.get("family", "Scroll"))))
		resources.append(row("resource:power_uses", "Power uses", "Morning · d4 + Presence", str(data.get("power_uses", 0)), MAGIC))
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("kind", "")) == "Decoction" or str(item.get("source_item_id", "")) == "portable-laboratory":
				resources.append(row("item:" + str(item.inventory_id), str(item.get("name", "Decoction")), "Shared laboratory doses" if item.has("dose_pool") else "Portable laboratory", str(remaining_uses(data, item))))
	elif chapter == 2:
		heading = "INVENTORY"
		if owner:
			primary.append(row("catalogue", "Add equipment", "Browse the equipment catalogue"))
			primary.append(row("custom", "Add custom item", "Current supported item fields"))
		for raw in items:
			var item: Dictionary = raw
			var arms := str(item.get("kind", "")) in ["Weapon", "Armor", "Shield"]
			if filter == 1 and not arms or filter == 2 and arms or filter == 3 and not item.get("equipped", false):
				continue
			primary.append(row("item:" + str(item.inventory_id), str(item.get("name", "Item")), "Broken" if item.get("broken", false) else "Ready" if item.get("equipped", false) else str(item.get("kind", "Equipment")), "×%d" % int(item.get("quantity", 0))))
		resources.append(row("resource:silver", "Silver", "coins", str(data.get("silver", 0))))
		resources.append(row("profile", "Pack & description", str(data.get("pack", ""))))
	elif chapter == 3:
		heading = "STORY"
		primary.append(row("journal:story", "The road ahead", "Local placeholder · Story", "", BOOK))
		resources.append(row("journal:notes", "Personal notes", "Local placeholder · Notes", "", BOOK))
	return {"primary": primary, "resources": resources, "companions": companions, "heading": heading}

func remaining_uses(data: Dictionary, item: Dictionary) -> int:
	if not item.has("dose_pool"):
		return int(item.get("uses", 0))
	var inventory: Array = data.get("inventory", [])
	for raw in inventory:
		var resource: Dictionary = raw
		if str(resource.get("source_item_id", "")) == str(item.get("dose_pool", "")):
			return int(resource.get("uses", 0))
	return 0
