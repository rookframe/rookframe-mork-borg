extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/actor_definition.gd"

## Source-backed classless character definition for the first creator slice.
## The UI owns the staged draft and physical Rolls; this resource owns the
## durable Character schema and validates the source-defined choices that can
## cross the SDK boundary.
const CLASS_ID := "classless"
const CLASS_TITLE := "No Class"
const ABILITY_NAMES := ["Agility", "Presence", "Strength", "Toughness"]
const PACK_CHOICES := ["Nothing", "Backpack", "Sack", "Small wagon", "Donkey"]
const STARTING_CREATURES: Dictionary = {}


func create_data(raw_choices: Variant) -> Variant:
	var choices: Dictionary = raw_choices
	var abilities: Dictionary = {}
	var submitted_abilities: Dictionary = choices.get("abilities", {})
	for ability_name in ABILITY_NAMES:
		if submitted_abilities.has(ability_name):
			var score: int = submitted_abilities.get(ability_name, 1)
			if score < 1:
				score = 1
			elif score > 20:
				score = 20
			abilities[ability_name] = {"score": score, "modifier": _modifier(score)}
	var inventory: Array = choices.get("inventory", [])
	var pack: String = choices.get("pack", "Nothing")
	if not PACK_CHOICES.has(pack):
		pack = "Nothing"
	var starting_creatures: Array = []
	var name: String = choices.get("name", "Unnamed Character")
	if name.is_empty():
		name = "Unnamed Character"
	var description: String = choices.get("description", "")
	var hit_points: int = choices.get("hit_points", 1)
	if hit_points < 1:
		hit_points = 1
	var maximum_hit_points: int = choices.get("maximum_hit_points", hit_points)
	if maximum_hit_points < hit_points:
		maximum_hit_points = hit_points
	var silver: int = choices.get("silver", 0)
	if silver < 0:
		silver = 0
	var omens: int = choices.get("omens", 0)
	if omens < 0:
		omens = 0
	var companion_sheets: Array = choices.get("companion_sheets", [])
	return {
		"schema": "mork-borg-character/v1",
		"definition_id": CLASS_ID,
		"class_id": CLASS_ID,
		"class_title": CLASS_TITLE,
		"name": name,
		"description": description,
		"abilities": abilities,
		"hit_points": hit_points,
		"maximum_hit_points": maximum_hit_points,
		"silver": silver,
		"omens": omens,
		"pack": pack,
		"inventory": inventory,
		"origin": choices.get("origin", ""),
		"traits": [],
		"preferred_miniature": choices.get("preferred_miniature", {}),
		"companion_sheets": companion_sheets,
		"starting_creature_ids": starting_creatures,
	}


func _modifier(score: int) -> int:
	if score <= 4:
		return -3
	if score <= 6:
		return -2
	if score <= 8:
		return -1
	if score <= 12:
		return 0
	if score <= 14:
		return 1
	if score <= 16:
		return 2
	return 3
