extends RefCounted
## Shared sheet/HUD projection. Membership is independent of source availability.
## Saved records retain display context when an exact owned source disappears.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const ITEMS = preload(ROOT + "logic/actor_inventory.gd")
const CREATURE_ITEMS = preload(ROOT + "logic/creature_actions.gd")
const POWERS = preload(ROOT + "logic/powers.gd")
const RULES = preload(ROOT + "logic/special_rules.gd")
const ATTACKS = preload(ROOT + "logic/attack_sources.gd")
const BROKEN = preload(ROOT + "logic/broken_incident.gd")
const PASSIVE := ["excretal-stealth", "escaping-fate", "crumpled-monster-mask", "dodging-death"]
const REACTIVE_ITEMS := ["bear-trap", "caltrops", "blade-of-your-ancestors"]

func needs_identity(data: Dictionary) -> bool:
	var items: Array = data.get("inventory", [])
	for raw in items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")).is_empty():
			return true
	var traits: Array = data.get("traits", [])
	for raw in traits:
		var feature: Dictionary = raw
		if str(feature.get("favorite_entry_id", "")).is_empty():
			return true
	return false

func needs_companion_identity(data: Dictionary) -> bool:
	return not data.get("creature_inventory", false) or needs_identity(data)

func item_entry(item: Dictionary) -> Dictionary:
	var source := str(item.get("source_item_id", ""))
	var action := ""
	var category := ""
	if str(item.get("kind", "")) == "Weapon" and not str(item.get("damage", "")).is_empty():
		action = "attack"
		category = "Attacks"
	elif not POWERS.new().definition(source).is_empty():
		action = "cast"
		category = "Powers"
	elif not RULES.new().definition(source).is_empty() and not source in PASSIVE and not source in REACTIVE_ITEMS:
		action = "use"
		category = "Items"
	if action.is_empty() or str(item.get("inventory_id", "")).is_empty():
		return {}
	return {"key": "item:%s:%s" % [str(item.inventory_id), action], "category": category, "name": str(item.get("name", "Item")), "action": action, "item": str(item.inventory_id), "source": source, "damage": str(item.get("damage", "")), "detail": "%s · %s ft" % [str(item.get("attack_ability", "Strength")), int(item.get("range_feet", 0))] if action == "attack" else ""}

func entries(data: Dictionary, actor_id: String, companions: Array[SDK.Actor] = []) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var inventory := ITEMS.new(null, SDK.ActorId.new(actor_id)).inventory(data)
	for raw in inventory:
		var item: Dictionary = raw
		var entry := item_entry(item)
		if entry.is_empty():
			continue
		entry["present"] = true
		entry["available"] = _available(data, item, str(entry.action), inventory)
		result.append(entry)
	var traits: Array = data.get("traits", [])
	for raw in traits:
		var feature: Dictionary = raw
		var source := str(feature.get("id", ""))
		var identity := str(feature.get("favorite_entry_id", ""))
		var gift: Dictionary = feature.get("item", {})
		if identity.is_empty() or str(gift.get("source_item_id", "")) == source or source in PASSIVE or RULES.new().definition(source).is_empty() and source != "cowards-jab":
			continue
		var available := int(feature.get("uses", 1)) > 0
		if source == "abominable-gob-lobber":
			available = true
		elif source == "cowards-jab":
			available = not ATTACKS.new().jab_weapons(inventory).is_empty()
		result.append({"key": "feature:" + identity + ":use", "category": "Attacks" if source == "cowards-jab" else "Features", "name": str(feature.get("name", "Feature")), "action": "use", "source": source, "entry": identity, "present": true, "available": BROKEN.new().can_act(data) and available})
	for companion in companions:
		var other: Dictionary = companion.data
		if companion.access_level != "Owner" or str(other.get("schema", "")) != "mork-borg-adversary/v1" or not is_companion(data, actor_id, other):
			continue
		var attacks := CREATURE_ITEMS.new(null, companion.id).inventory(other)
		for raw in attacks:
			var attack: Dictionary = raw
			if str(attack.get("kind", "")) != "Weapon" or str(attack.get("damage", "")).is_empty():
				continue
			result.append({"key": companion_key(companion.id.value, str(attack.inventory_id)), "category": "Companions", "name": str(other.get("name", "Companion")) + " · " + str(attack.get("name", "Attack")), "action": "attack", "actor": companion.id.value, "item": str(attack.inventory_id), "present": true, "available": _available(other, attack, "attack", attacks)})
	for intrinsic in ATTACKS.new().entries(data):
		result.append(intrinsic)
	var saved: Array = data.get("favorites", [])
	for entry in result:
		entry["starred"] = false
		for raw in saved:
			var favorite: Dictionary = raw
			if str(favorite.get("key", "")) == str(entry.key):
				entry["starred"] = true
	for raw in saved:
		var favorite: Dictionary = raw
		var present := false
		for entry in result:
			if str(entry.key) == str(favorite.get("key", "")):
				present = true
		if not present:
			var missing := favorite.duplicate(true)
			missing["starred"] = true
			missing["present"] = false
			missing["available"] = false
			result.append(missing)
	return result

func companion_key(actor: String, item: String) -> String:
	# Item IDs can contain ':' (e.g. the Creature's authored profile attacks).
	return "companion:" + actor + ":" + item + ":attack"

func is_companion(data: Dictionary, actor_id: String, other: Dictionary) -> bool:
	return not str(data.get("creation_id", "")).is_empty() and str(other.get("creation_id", "")) == str(data.creation_id) or str(other.get("summoner_actor", "")) == actor_id

func find(data: Dictionary, actor_id: String, companions: Array[SDK.Actor], key: String) -> Dictionary:
	for entry in entries(data, actor_id, companions):
		if str(entry.key) == key and entry.present:
			return entry
	return {}

func record(entry: Dictionary) -> Dictionary:
	var saved := entry.duplicate(true)
	for key in ["starred", "available", "present"]:
		saved.erase(key)
	return saved

func _available(data: Dictionary, item: Dictionary, action: String, inventory: Array) -> bool:
	if not BROKEN.new().can_act(data) or int(item.get("quantity", 0)) < 1 or item.get("broken", false):
		return false
	if action == "attack":
		return ATTACKS.new().usable(item, str(data.get("schema", "")) == "mork-borg-adversary/v1") and (str(item.get("ammunition", "")).is_empty() or not preload(ROOT + "logic/ammunition.gd").new().available(inventory, str(item.ammunition)).is_empty())
	if action == "cast":
		if int(data.get("power_uses", 0)) < 1 or not POWERS.new().casting_restriction(data, inventory).is_empty():
			return false
	var source := str(item.get("source_item_id", ""))
	if source == "stolen-mitre" and not item.get("equipped", false):
		return false
	if source == "portable-laboratory":
		# Brewing replaces the shared pool, including an exhausted batch.
		return str(data.get("class_id", "")) == "occult-herbmaster"
	if item.has("dose_pool"):
		for raw in inventory:
			var pool: Dictionary = raw
			if str(pool.get("source_item_id", "")) == str(item.dose_pool) and int(pool.get("quantity", 0)) > 0 and not pool.get("broken", false):
				return int(pool.get("uses", 0)) > 0
		return false
	if str(item.get("source_item_id", "")) == "eurekia" and item.get("drawn", false):
		return true
	return int(item.get("uses", 1)) > 0
