extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd"
const CREATURES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_definition.gd")

func _read() -> SDK.ActorResult:
	var result := super._read()
	if not result.ok:
		return result
	var current: Dictionary = result.actor.data
	if str(current.get("schema", "")) != "mork-borg-adversary/v1":
		return _failure("Creature data is unavailable.")
	var data: Dictionary = current.duplicate(true)
	data["inventory"] = inventory(data)
	data["creature_inventory"] = true
	result.actor.data = data
	return result

## A saved profile gains ordinary editable item identities on its first edit.
## The marker prevents removed source attacks from returning on a later edit.
func inventory(data: Dictionary) -> Array:
	var items: Array = []
	for raw in super.inventory(data):
		if typeof(raw) != TYPE_DICTIONARY:
			return []
		var item: Dictionary = raw
		items.append(item)
	if data.get("creature_inventory", false):
		return items
	for raw in CREATURES.new().attack_options(data):
		var attack: Dictionary = raw
		items.append({"inventory_id": "creature:" + str(attack.id), "source_attack_id": str(attack.id), "name": str(attack.name), "kind": "Weapon", "damage": str(attack.dice), "range_feet": attack.range_feet, "quantity": 1, "equipped": attack.get("equipped", true), "broken": attack.get("broken", false), "rules": attack.get("rules", "")})
	var armor: Dictionary = data.get("armor", {})
	if not str(armor.get("reduction", "")).is_empty():
		items.append({"inventory_id": "creature:armor", "name": str(armor.get("name", "Armor")), "kind": "Armor", "reduction": str(armor.reduction), "quantity": 1, "equipped": true})
	return items

func _save(data: Dictionary) -> SDK.ActorResult:
	var armor := {"name": "No armor", "reduction": ""}
	var items: Array = data.inventory
	for raw in items:
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("kind", "")) == "Armor" and item.get("equipped", false) and not item.get("broken", false) and quantity > 0:
			armor = {"name": str(item.name), "reduction": str(item.get("reduction", ""))}
	data["armor"] = armor
	return await _sdk.actors.update(_id, data)

func shield_reduction(data: Dictionary) -> int:
	for raw in inventory(data):
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("kind", "")) == "Shield" and item.get("equipped", false) and not item.get("broken", false) and quantity > 0:
			return 1
	return 0

## Keep the editable armor item and the profile's current protection in sync.
func damage_armor(data: Dictionary) -> void:
	var items := inventory(data)
	var worn: Dictionary = {}
	for raw in items:
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("kind", "")) == "Armor" and item.get("equipped", false) and not item.get("broken", false) and quantity > 0:
			worn = item
	if worn.is_empty():
		return
	var reduction := str(worn.get("reduction", ""))
	var tier: int = worn.get("armor_tier", {"d2": 1, "d4": 2, "d6": 3}.get(reduction, 0))
	if tier < 1:
		return
	worn["penalty_tier"] = worn.get("penalty_tier", tier)
	worn["armor_tier"] = tier - 1
	worn["reduction"] = ["", "d2", "d4"][tier - 1]
	if tier == 1:
		worn["broken"] = true
		worn["ruined"] = true
	data["inventory"] = items
	data["creature_inventory"] = true
	data["armor"] = {"name": str(worn.get("name", "Armor")), "reduction": str(worn.reduction)}
