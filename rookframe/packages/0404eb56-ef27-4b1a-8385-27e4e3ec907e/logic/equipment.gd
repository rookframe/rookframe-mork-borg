extends RefCounted

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE) -> void:
	_data_catalogue = data_catalogue


## Core equipment facts from Bare Bones pp. 21–26; Bevy catalogue is reuse evidence.
## Ranges are the approved application convention, not printed weapon ranges.
# Catalogue rows: id, name, kind, rules, price, source, damage, range, armor tier, reduction, uses, attack ability, ammunition.
# Named live dictionaries are constructed at the boundary; each call returns fresh data.
func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in _data_catalogue.equipment_rows():
		result.append(_entry(row))
	for family in CATALOGUE.SCROLL_FAMILIES:
		var entries := _data_catalogue.scrolls(family)
		for raw in entries:
			var entry: Dictionary = raw
			result.append(entry.duplicate(true))
	return result

func item(id: String) -> Dictionary:
	if id.is_empty():
		return {}
	for class_id in ["fanged-deserter", "gutterborn-scum", "esoteric-hermit", "wretched-royalty", "heretical-priest", "occult-herbmaster"]:
		var profile: Dictionary = _data_catalogue.class_profiles().get(class_id, {})
		var features: Array = profile.get("features", [])
		for raw in features:
			var feature: Dictionary = raw
			var original: Dictionary = feature.get("item", {})
			if str(original.get("source_item_id", "")) == id:
				var special := original.duplicate(true)
				special["rules"] = str(feature.rules)
				if str(special.get("kind", "")) == "Weapon":
					special["range_feet"] = {"old-sigurds-sling": 30, "shoe-of-deaths-horse": 30, "sacred-shepherds-crook": 10}.get(id, 5)
					special["attack_ability"] = "Presence" if id in ["old-sigurds-sling", "shoe-of-deaths-horse"] else "Strength"
				if id in ["book-of-boiling-blood", "stones-taken-from-thel-emas-lost-temple", "blasphemous-nechrubel-bible"]:
					special["uses"] = 1
				if id == "stolen-mitre":
					special["defence_dr"] = 10
				return special
	for raw_row in _data_catalogue.equipment_rows():
		var row: Array = raw_row
		if str(row[0]) == id:
			return _entry(row)
	for family in CATALOGUE.SCROLL_FAMILIES:
		var entries := _data_catalogue.scrolls(family)
		for raw in entries:
			var entry: Dictionary = raw
			if str(entry.source_item_id) == id:
				return entry.duplicate(true)
	return {}

func _entry(row: Array) -> Dictionary:
	var entry: Dictionary = {"source_item_id": str(row[0]), "name": str(row[1]), "kind": str(row[2]), "rules": str(row[3]), "price": str(row[4]), "source": str(row[5]), "quantity": 1, "equipped": false}
	if str(entry.source_item_id) in ["waterskin", "lard"]:
		entry["uses"] = 4 if str(entry.source_item_id) == "waterskin" else 5
	var damage: String = row[6]
	var weapon_range: int = row[7]
	var tier: int = row[8]
	var reduction: String = row[9]
	var uses: int = row[10]
	if str(entry.kind) == "Weapon":
		entry["piercing"] = str(entry.source_item_id) in ["shortsword", "knife", "spear", "bow", "shortbow", "crossbow"]
	if not damage.is_empty():
		entry["damage"] = damage
	if weapon_range >= 0:
		entry["range_feet"] = weapon_range
	if tier >= 0:
		entry["armor_tier"] = tier
	if not reduction.is_empty():
		entry["reduction"] = reduction
	if not str(row[11]).is_empty():
		entry["attack_ability"] = str(row[11])
	if not str(row[12]).is_empty():
		entry["ammunition"] = str(row[12])
	if not str(row[12]).is_empty() and str(row[2]) == "Equipment":
		entry["resource_field"] = "uses" if uses >= 0 else "quantity"
	if uses >= 0:
		entry["uses"] = uses
	return entry
