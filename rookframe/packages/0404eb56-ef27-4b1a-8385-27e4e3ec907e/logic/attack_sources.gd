extends RefCounted
## Native intrinsic bindings shared by favorite projection and combat authority.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const BROKEN = preload(ROOT + "logic/broken_incident.gd")

func intrinsic(data: Dictionary, id: String, options: Dictionary = {}) -> Dictionary:
	if str(data.get("schema", "")) != "mork-borg-character/v1":
		return {}
	var weapon := {"inventory_id": id, "kind": "Weapon", "quantity": 1, "equipped": true, "natural": true, "attack_ability": "Strength", "attack_dr": 12, "range_feet": 5}
	if id == "intrinsic:unarmed":
		weapon["source_item_id"] = "unarmed"
		weapon["name"] = "Unarmed"
		weapon["damage"] = "d2"
		weapon["rules"] = "Strength DR12 · d2 damage."
	elif id == "intrinsic:improvised":
		weapon["source_item_id"] = "improvised"
		weapon["name"] = "Improvised weapon"
		weapon["damage"] = "d4"
		weapon["rules"] = "Choose an object and melee or ranged use with the table."
		if str(options.get("improvised_mode", "melee")) == "ranged":
			weapon["attack_ability"] = "Presence"
			weapon["range_feet"] = 30
		if not str(options.get("object", "")).strip_edges().is_empty():
			weapon["name"] = str(options.object).strip_edges()
	elif id == "class:bite":
		if str(data.get("class_id", "")) != "fanged-deserter":
			return {}
		weapon["source_item_id"] = "bite"
		weapon["name"] = "Bite"
		weapon["damage"] = "d6"
		weapon["attack_dr"] = 10
		weapon["rules"] = "Strength DR10 · d6. Enemy free attack on 1–2 on d6."
	else:
		return {}

	return weapon

func entries(data: Dictionary) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ["class:bite", "intrinsic:unarmed", "intrinsic:improvised"]:
		var weapon := intrinsic(data, id)
		if weapon.is_empty():
			continue
		var identity: String = "intrinsic:bite" if id == "class:bite" else str(id)
		result.append({"key": identity + ":attack", "category": "Attacks", "name": str(weapon.name), "action": "attack", "item": id, "source": str(weapon.source_item_id), "damage": str(weapon.damage), "detail": str(weapon.rules), "present": true, "available": BROKEN.new().can_act(data)})
	return result

func jab_weapons(inventory: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for raw in inventory:
		var item: Dictionary = raw
		if usable(item) and int(item.get("range_feet", 0)) == 5 and not item.get("two_handed", false) and str(item.get("source_item_id", "")) != "zweihander" and not item.get("natural", false):
			result.append(item)
	return result

func usable(item: Dictionary, creature: bool = false) -> bool:
	if str(item.get("kind", "")) != "Weapon" or damage_dice(str(item.get("damage", ""))).is_empty() or int(item.get("range_feet", 0)) <= 0:
		return false
	if int(item.get("quantity", 0)) < 1 or not item.get("equipped", false) or item.get("broken", false):
		return false
	if str(item.get("source_item_id", "")) == "eurekia":
		return item.get("drawn", false) or int(item.get("uses", 0)) > 0
	return creature or item.has("attack_ability") or int(item.get("range_feet", 0)) in [5, 10]


func damage_dice(formula: String) -> Dictionary:
	var terms := formula.to_lower().split("+")
	if terms.size() > 2 or terms.size() == 2 and not terms[1].is_valid_int():
		return {}
	var parts := terms[0].split("d")
	if parts.size() != 2 or not parts[1].is_valid_int() or not parts[0].is_empty() and not parts[0].is_valid_int():
		return {}
	var count := 1 if parts[0].is_empty() else int(parts[0])
	var faces := int(parts[1])
	if count < 1 or count > 15 or not faces in [2, 4, 6, 8, 10, 12, 20]:
		return {}
	return {"faces": faces, "count": count}
