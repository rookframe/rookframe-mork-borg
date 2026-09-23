extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/actor_definition.gd"

## Source-backed Character definitions for the first four creation branches.
## The UI owns the staged draft and physical Rolls; this resource owns the
## durable Character schema and validates the source-defined choices that can
## cross the SDK boundary.
const CLASSES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd")
@export var class_id := "classless"
const ABILITY_NAMES := ["Agility", "Presence", "Strength", "Toughness"]
const PACK_CHOICES: Array[String] = ["Nothing", "Backpack", "Sack", "Small wagon", "Donkey"]
const WEAPON_RESULTS := ["Femur", "Staff", "Shortsword", "Knife", "Warhammer", "Sword", "Bow", "Flail", "Crossbow", "Zweihander"]
const ARMOR_RESULTS := ["No armor", "Light armor", "Medium armor", "Heavy armor"]
## Fixed grants are empty for the classless profile. Conditional starting
## Creature grants are admitted only from SOURCE_CREATURE_CHOICES after the
## source equipment table selects a combat profile.
const STARTING_CREATURES: Array[String] = []
const SOURCE_CREATURE_CHOICES := ["dog-small-but-vicious", "monkey", "ancient-gore-hound", "hawk-as-weapon"]


func create_data(raw_choices: Variant) -> Variant:
	var choices: Dictionary = raw_choices
	var profile: Dictionary = CLASSES.new().profile(class_id)
	var feature_roll: int = choices.get("feature_roll", 0)
	var origin_roll: int = choices.get("origin_roll", 0)
	var feature: Dictionary = CLASSES.new().feature(class_id, feature_roll)
	var abilities: Dictionary = {}
	var submitted_abilities: Dictionary = choices.get("abilities", {})
	for ability_name in ABILITY_NAMES:
		if submitted_abilities.has(ability_name):
			var score_data: Dictionary = submitted_abilities.get(ability_name, {})
			var score: int = score_data.get("score", 1)
			if score < 1:
				score = 1
			elif score > 20:
				score = 20
			abilities[ability_name] = {"score": score, "modifier": _modifier(score)}
	var inventory: Array = choices.get("inventory", [])
	var pack: String = choices.get("pack", "Nothing")
	if not PACK_CHOICES.has(pack):
		pack = "Nothing"
	var starting_creatures: Array = STARTING_CREATURES.duplicate()
	var requested_creatures: Array = choices.get("starting_creature_ids", [])
	for creature_id in requested_creatures:
		var creature_id_text: String = creature_id
		if SOURCE_CREATURE_CHOICES.has(creature_id_text):
			starting_creatures.append(creature_id_text)
	var name: String = choices.get("name", "Unnamed Character")
	if name.is_empty():
		name = "Unnamed Character"
	var description: String = choices.get("description", "")
	var hit_points: int = choices.get("hit_points", 1)
	if hit_points < 1:
		hit_points = 1
	var maximum_hit_points: int = choices.get("maximum_hit_points", hit_points)
	if not choices.has("maximum_hit_points") and submitted_abilities.has("Toughness"):
		var toughness_data: Dictionary = submitted_abilities.get("Toughness", {})
		var toughness_score: int = toughness_data.get("score", 1)
		hit_points += _modifier(toughness_score)
		if hit_points < 1:
			hit_points = 1
		maximum_hit_points = hit_points
	if maximum_hit_points < hit_points:
		maximum_hit_points = hit_points
	var silver: int = choices.get("silver", 0)
	if silver < 0:
		silver = 0
	var omens: int = choices.get("omens", 0)
	if omens < 0:
		omens = 0
	var companion_sheets: Array = choices.get("companion_sheets", [])
	var starting_creature_grants: Array = choices.get("starting_creature_grants", [])
	return {
		"creation_id": choices.get("creation_id", ""),
		"creation_roll_sequence": choices.get("creation_roll_sequence", 0),
		"schema": "mork-borg-character/v1",
		"definition_id": class_id,
		"class_id": class_id,
		"class_title": profile.get("title", "No Class"),
		"name": name,
		"description": description,
		"abilities": abilities,
		"hit_points": hit_points,
		"maximum_hit_points": maximum_hit_points,
		"silver": silver,
		"omens": omens,
		"pack": pack,
		"inventory": inventory,
		"origin": CLASSES.new().origin(class_id, origin_roll),
		"origin_roll": origin_roll,
		"feature_roll": feature_roll,
		"traits": [] if feature.is_empty() else [feature],
		"class_rules": profile.get("rules", []),
		"scroll_dispositions": choices.get("scroll_dispositions", []).duplicate(true),
		"preferred_miniature": choices.get("preferred_miniature", {}),
		"companion_sheets": companion_sheets,
		"starting_creature_ids": starting_creatures,
		"starting_creature_grants": starting_creature_grants,
	}


func resolve_equipment_name(kind: String, roll: int) -> String:
	var result_index := roll - 1
	if result_index < 0:
		result_index = 0
	if kind == "Weapon":
		if result_index >= WEAPON_RESULTS.size():
			result_index = WEAPON_RESULTS.size() - 1
		return WEAPON_RESULTS[result_index]
	if kind == "Armor":
		if result_index >= ARMOR_RESULTS.size():
			result_index = ARMOR_RESULTS.size() - 1
		return ARMOR_RESULTS[result_index]
	return ""


func pack_choices_for_roll(roll: int) -> Array[String]:
	if roll == 5:
		return ["Nothing", "Backpack", "Sack", "Small wagon"]
	if roll == 6:
		return PACK_CHOICES.duplicate()
	return []


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
