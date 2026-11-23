extends "res://rookframe/sdk/actor_definition.gd"

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE = null) -> void:
	_data_catalogue = data_catalogue


## Source-backed Character definitions for the seven creation branches.
## The UI owns the staged draft and physical Rolls; this resource owns the
## durable Character schema and validates the source-defined choices that can
## cross the SDK boundary.
const CLASSES = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creation_classes.gd")
@export var class_id := "classless"
const ABILITY_NAMES := ["Agility", "Presence", "Strength", "Toughness"]


func create_data(_choices: Variant) -> Variant:
	push_error("MÖRK BORG Actor creation requires the Package data capability.")
	return null

func create_data_with_content(raw_choices: Variant, content: RefCounted) -> Variant:
	var data_catalogue := CATALOGUE.new(content)
	if not data_catalogue.can_create_character():
		return null
	return _create(raw_choices, data_catalogue)

func _create(raw_choices: Variant, data_catalogue: CATALOGUE) -> Variant:
	var choices: Dictionary = raw_choices.duplicate(true)
	var classes := CLASSES.new(data_catalogue)
	var profile: Dictionary = classes.profile(class_id)
	var feature_roll: int = choices.get("feature_roll", 0)
	var origin_roll: int = choices.get("origin_roll", 0)
	var feature: Dictionary = classes.feature(class_id, feature_roll)
	var traits: Array = [] if feature.is_empty() else [feature]
	var second_feature_roll: int = choices.get("second_feature_roll", 0)
	if class_id == "wretched-royalty":
		traits.append(classes.feature(class_id, second_feature_roll))
	var decoction_rolls: Array = choices.get("decoction_rolls", [])
	if class_id == "occult-herbmaster":
		for roll in decoction_rolls:
			var decoction_roll: int = roll
			traits.append(classes.decoction(decoction_roll))
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
	if not data_catalogue.creation_choices("PACK_CHOICES").has(pack):
		pack = "Nothing"
	var starting_creatures: Array = data_catalogue.creation_choices("STARTING_CREATURES").duplicate()
	var requested_creatures: Array = choices.get("starting_creature_ids", [])
	for creature_id in requested_creatures:
		var creature_id_text: String = creature_id
		if data_catalogue.creation_choices("SOURCE_CREATURE_CHOICES").has(creature_id_text):
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
		"origin": classes.origin(class_id, origin_roll),
		"origin_roll": origin_roll,
		"feature_roll": feature_roll,
		"second_feature_roll": second_feature_roll,
		"decoction_rolls": decoction_rolls,
		"traits": traits,
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
	if kind not in ["Weapon", "Armor"]:
		return ""
	var results := _data_catalogue.creation_choices("WEAPON_RESULTS" if kind == "Weapon" else "ARMOR_RESULTS")
	return results[mini(result_index, results.size() - 1)]


func pack_choices_for_roll(roll: int) -> Array[String]:
	var result: Array[String] = []
	if roll in [5, 6]:
		var packs := _data_catalogue.creation_choices("PACK_CHOICES")
		for pack in (packs.slice(0, 4) if roll == 5 else packs):
			result.append(str(pack))
	return result


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
