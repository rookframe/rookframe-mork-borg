extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/actor_definition.gd"

## Immutable MÖRK BORG core definitions. A live Actor receives a deep copy and
## can then edit its private encounter sheet without changing this catalogue.
const CORE_DEFINITIONS: Dictionary = {
	"hawk-as-weapon": {"loot": [], "display_name": "Hawk as weapon", "hit_points": 8, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"id": "claws", "natural": true, "name": "Claws", "dice": "d4", "range_feet": 5, "attack_dr": 10}, {"id": "bite", "natural": true, "name": "Bite", "dice": "d4", "range_feet": 5, "attack_dr": 10}], "defence_dr": 10, "rules": "Loyal only to its Hermit, who understands its cries. Keeps watch, scouts and attacks."},
	"ancient-gore-hound": {"loot": [], "display_name": "Ancient gore-hound", "hit_points": 10, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Bite", "dice": "d6", "attack_dr": 10, "id": "bite", "natural": true, "range_feet": 5}], "defence_dr": 12, "rules": "Sniffs out treasure in debris. Frenzied around goblins and berserkers."},
	"dog-small-but-vicious": {"loot": [], "display_name": "Small but vicious dog", "hit_points": 8, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Bite", "dice": "d4", "id": "bite", "natural": true, "range_feet": 5}]},
	"aland-wickhead": {"loot": [], "display_name": "Aland, Wickhead knife-wielder", "hit_points": 10, "morale": {"kind": "fixed", "value": 7}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Knife with dried blood", "dice": "d4", "id": "knife-with-dried-blood", "range_feet": 5}]},
	"arbint-troll": {"loot": [], "defence_dr": 10, "display_name": "Arbint, Troll", "hit_points": 32, "morale": {"kind": "special"}, "armor": {"name": "Thick hide", "reduction": "d2"}, "attacks": [{"name": "Fist", "dice": "2d6", "id": "fist", "natural": true, "range_feet": 5}]},
	"belze-skeleton": {"loot": [], "rules": "Moves silently and attacks by surprise. Can repeat voices it has heard. Piercing attacks against it are DR14. Any strike dealing 5 or more damage destroys it completely.", "piercing_defence_dr": 14, "destroy_at_damage": 5, "display_name": "Belze, blood-drenched skeleton", "hit_points": 7, "morale": {"kind": "fixed", "value": 8}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Shortsword", "dice": "d4", "id": "shortsword", "range_feet": 5}, {"name": "Knife", "dice": "d4", "id": "knife", "range_feet": 5}, {"name": "Bony knuckles", "dice": "d2", "id": "bony-knuckles", "natural": true, "range_feet": 5}]},
	"bone-bowyer": {"loot": [], "display_name": "The Bone Bowyer", "hit_points": 25, "morale": {"kind": "none"}, "armor": {"name": "Tanned flesh", "reduction": "d4"}, "attacks": [{"id": "whispering-death", "name": "The Whispering Death", "dice": "d6", "range_feet": 30, "defence_dr": 14, "rules": "May attack twice each round."}], "rules": "Test DR12 to detect the Bowyer or it gets two free shots. The bow deals d6 damage. A miss sends the arrow toward another random creature nearby; repeat until it hits. It cannot target or harm the Bone Bowyer. The Bowyer may craft a bow for a wicked character who completes a task: abduct a child; cruelly murder kin; desecrate a shrine or church; sow discord; spread disease; or burn a heretic."},
	"bent-scum": {"loot": [], "display_name": "Bent, Scum", "hit_points": 7, "morale": {"kind": "fixed", "value": 8}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Poisoned knife", "dice": "d4", "id": "poisoned-knife", "range_feet": 5}]},
	"eulotha-wyvern": {"loot": [], "display_name": "Eulotha, Wyvern", "hit_points": 25, "morale": {"kind": "fixed", "value": 10}, "armor": {"name": "Thick hide", "reduction": "d4"}, "attacks": [{"id": "bite", "natural": true, "name": "Bite", "dice": "d6", "range_feet": 5, "rules": "60% chance of biting; otherwise use Sting."}, {"id": "sting", "natural": true, "name": "Sting", "dice": "d6", "range_feet": 5, "rules": "Toughness DR14 avoids one painful hour of paralysis; duration is table managed."}]},
	"lady-porcelain": {"loot": [], "display_name": "Lady Porcelain, undead doll", "hit_points": 11, "morale": {"kind": "none"}, "armor": {"name": "Porcelain", "reduction": "d2"}, "attacks": [{"id": "claws", "natural": true, "name": "Claws", "dice": "d4", "range_feet": 5}, {"id": "piercing-bite", "natural": true, "name": "Piercing bite", "dice": "d4", "range_feet": 5}]},
	"lich-necromancer": {"loot": [], "rules": "Touch paralyzes. Test Presence DR14 each round to break free. No one can use Powers nearby. Each round it can steal a nearby scroll’s contents and use the Power against its owner.", "display_name": "Lich, Undead (weak) necromancer", "hit_points": 15, "morale": {"kind": "none"}, "armor": {"name": "Barrier (necro)", "reduction": "d4"}, "attacks": [{"name": "Strike", "dice": "d6", "id": "strike", "natural": true, "range_feet": 5}]},
	"monkey": {"loot": [], "display_name": "Monkey", "hit_points": 6, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"id": "punch", "natural": true, "name": "Punch", "dice": "d4", "range_feet": 5}, {"id": "bite", "natural": true, "name": "Bite", "dice": "d4", "range_feet": 5}]},
	"nodh-zombie": {"loot": [], "display_name": "Nodh, zombie", "hit_points": 7, "morale": {"kind": "none"}, "armor": {"name": "Leather scraps", "reduction": "d2"}, "attacks": [{"id": "claw", "natural": true, "name": "Claw", "dice": "d2", "range_feet": 5}, {"id": "bite", "natural": true, "name": "Bite", "dice": "d2", "range_feet": 5, "rules": "On a bite, Toughness DR8 or death within two days followed by rising as a zombie. Delayed consequences are table managed."}]},
	"seth-goblin": {"loot": [], "rules": "An attack carries the goblin curse whether it hits or misses. Find and kill that goblin within d6 days; if it still lives, the victim permanently becomes a goblin.", "defence_dr": 14, "display_name": "Seth, Goblin", "hit_points": 6, "morale": {"kind": "fixed", "value": 7}, "armor": {"name": "Ropy skin", "reduction": "d2"}, "attacks": [{"id": "knife", "name": "Knife", "dice": "d4", "range_feet": 5, "defence_dr": 14}, {"id": "shortbow", "name": "Shortbow", "dice": "d4", "range_feet": 30, "defence_dr": 14}]},
	"thinx-grotesque": {"loot": [], "rules": "Moves slowly and is easy to hit: attacks against it are DR10. Its eye-beam is used on 1–2 on a d6 each round and always hits.", "defence_dr": 10, "display_name": "Thinx, Grotesque", "hit_points": 18, "morale": {"kind": "none"}, "armor": {"name": "Clay / stone", "reduction": "d6"}, "attacks": [{"name": "Claws", "dice": "d6", "id": "claws", "natural": true, "range_feet": 5}, {"name": "Eye-beam", "dice": "d8", "id": "eye-beam", "natural": true, "range_feet": 30, "always_hits": true, "rules": "Used on 1–2 on a d6 each round. Always hits."}]},
	"wrat-wraith": {"loot": [], "defence_dr": 14, "display_name": "Wrat, Wraith", "hit_points": 15, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Touch", "dice": "d4", "id": "touch", "natural": true, "range_feet": 5}]},
	"zukuma-berserker": {"loot": [], "defence_dr": 10, "display_name": "Zukuma, berserker", "hit_points": 13, "morale": {"kind": "fixed", "value": 9}, "armor": {"name": "Hardened skin", "reduction": "d2"}, "attacks": [{"name": "Long flail", "dice": "d8", "id": "long-flail", "range_feet": 10}, {"name": "Heavy mace", "dice": "d6", "id": "heavy-mace", "range_feet": 5}, {"name": "Chained sword", "dice": "d6", "id": "chained-sword", "range_feet": 10}, {"name": "Huge warhammer", "dice": "d10", "id": "huge-warhammer", "range_feet": 5}]},
}


const ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd")
const CREATURE_CONTENT = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/creature_content.gd")

const ROOKFRAME_CONTENT := "fbf21a78-626e-4f35-b2ce-bd196083d9b7"
const AUTHORED_MINIATURES := {"bent-scum": "bandit", "seth-goblin": "goblin", "zukuma-berserker": "barbarian"}

func default_miniature(definition: String) -> Dictionary:
	var local_id := str(AUTHORED_MINIATURES.get(definition, ""))
	return {} if local_id.is_empty() else {"package_id": ROOKFRAME_CONTENT, "local_id": local_id}

func effective_miniature(data: Dictionary) -> Dictionary:
	var preferred: Dictionary = data.get("preferred_miniature", {})
	if not preferred.is_empty():
		return preferred.duplicate(true)
	var authored := default_miniature(str(data.get("definition_id", "")))
	return authored if not authored.is_empty() else {"package_id": ROOKFRAME_CONTENT, "local_id": "default-miniature"}

func create_data(raw_choices: Variant) -> Variant:
	var choices: Dictionary = raw_choices
	var definition: Dictionary = CORE_DEFINITIONS.get(resource_name, {}).duplicate(true)
	var data: Dictionary = {
		"schema": "mork-borg-adversary/v1",
		"definition_id": resource_name,
		"name": definition.get("display_name", "Creature"),
		"hit_points": definition.get("hit_points", 0),
		"maximum_hit_points": definition.get("hit_points", 0),
		"morale": definition.get("morale", {"kind": "none"}),
		"armor": definition.get("armor", {"name": "No armor", "reduction": ""}),
		"attacks": definition.get("attacks", []),
		"inventory": definition.get("loot", []).duplicate(true),
		"creature_stat_block": true,
		"rules": definition.get("rules", ""),
	}
	var metadata := CREATURE_CONTENT.new().details(resource_name)
	for field in ["classification", "rule_groups", "reference", "source"]:
		if metadata.has(field):
			data[field] = metadata[field]
	for field in ["defence_dr", "piercing_defence_dr", "destroy_at_damage"]:
		if definition.has(field):
			data[field] = definition[field]
	if choices.has("creation_id"):
		data["creation_id"] = choices["creation_id"]
	if choices.has("creation_roll_sequence"):
		data["creation_roll_sequence"] = choices["creation_roll_sequence"]
	for key in ["preferred_miniature", "inventory_serial", "summoner_actor", "summon_action", "grant_source", "name", "hit_points", "maximum_hit_points", "morale", "armor", "attacks", "inventory", "classification", "rule_groups", "reference", "source", "portrait"]:
		if choices.has(key):
			data[key] = choices[key]
	if not data.has("preferred_miniature"):
		data["preferred_miniature"] = default_miniature(resource_name)
	return data

## Project saved effective capabilities into a Creature Stat Block before any
## loot edit. The saved inventory remains untouched; only the old equipment
## interpretation is retired. The first ordinary accepted Actor update persists
## this value, so removed attacks and old source defaults cannot return.
func stat_block(current: Dictionary) -> Dictionary:
	var data := current.duplicate(true)
	if str(data.get("schema", "")) != "mork-borg-adversary/v1" or data.get("creature_stat_block", false):
		return data
	if typeof(data.get("attacks", [])) != TYPE_ARRAY or typeof(data.get("inventory", [])) != TYPE_ARRAY or typeof(data.get("armor", {})) != TYPE_DICTIONARY:
		return data
	for raw in data.get("attacks", []) + data.get("inventory", []):
		if typeof(raw) != TYPE_DICTIONARY:
			return data
	var attacks := _inventory_attacks(data) if data.get("creature_inventory", false) else _profile_attacks(data)
	var retained: Array = []
	for raw in attacks:
		var attack: Dictionary = raw
		if not attack.get("equipped", true) or attack.get("broken", false) or int(attack.get("quantity", 1)) < 1:
			continue
		for key in ["inventory_id", "equipped", "broken", "quantity", "ammunition"]:
			attack.erase(key)
		retained.append(attack)
	data["attacks"] = retained
	var armor: Dictionary = data.get("armor", {"name": "No armor", "reduction": ""})
	var shield := 0
	var defence_penalty := 0
	for raw in ITEMS.new(null, null).inventory(data):
		var item: Dictionary = raw
		if not item.get("equipped", false) or int(item.get("quantity", 0)) < 1:
			continue
		if str(item.get("kind", "")) == "Armor" and int(item.get("penalty_tier", item.get("armor_tier", 0))) >= 2:
			defence_penalty += 2
		if str(item.get("kind", "")) == "Shield" and not item.get("broken", false):
			shield = 1
	if shield > 0:
		armor["shield_reduction"] = shield
	if defence_penalty > 0:
		armor["defence_penalty"] = defence_penalty
	data["armor"] = armor
	data["creature_stat_block"] = true
	data.erase("creature_inventory")
	return data

func attack_options(data: Dictionary) -> Array:
	var normalized := stat_block(data)
	if typeof(normalized.get("attacks", [])) != TYPE_ARRAY:
		return []
	var attacks: Array = normalized.get("attacks", [])
	return attacks.duplicate(true)

## Adapt explicit capabilities for the existing targeted combat operation.
## These records never come from carried loot and have no ammunition counter.
func combat_attacks(data: Dictionary) -> Array:
	var result: Array = []
	for attack in attack_options(data):
		if typeof(attack) != TYPE_DICTIONARY:
			return []
		var item: Dictionary = attack.duplicate(true)
		item["inventory_id"] = "creature:" + str(attack.get("id", ""))
		item["damage"] = str(attack.get("dice", ""))
		item.erase("ammunition")
		item["kind"] = "Weapon"
		item["quantity"] = 1
		item["equipped"] = true
		result.append(item)
	return result

func shield_reduction(data: Dictionary) -> int:
	var normalized := stat_block(data)
	var armor: Dictionary = normalized.get("armor", {})
	return int(armor.get("shield_reduction", 0))

## Targeted tabletop criticals change recorded protection, never carried loot.
func damage_protection(current: Dictionary) -> Dictionary:
	var data := stat_block(current)
	var armor: Dictionary = data.get("armor", {})
	var tier: int = {"d2": 1, "d4": 2, "d6": 3}.get(str(armor.get("reduction", "")), 0)
	if tier > 0:
		armor["reduction"] = ["", "d2", "d4"][tier - 1]
		data["armor"] = armor
	return data

func _profile_attacks(data: Dictionary) -> Array:
	var saved: Array = data.get("attacks", [])
	var definition_id := str(data.get("definition_id", ""))
	var definition: Dictionary = CORE_DEFINITIONS.get(definition_id, {})
	var authored: Array = definition.get("attacks", [])
	if saved.is_empty() or authored.is_empty():
		return saved.duplicate(true)
	for raw in saved:
		if typeof(raw) != TYPE_DICTIONARY:
			return saved.duplicate(true)
		var previous: Dictionary = raw
		if previous.has("id"):
			return _authored_attack_defaults(saved, authored)
	var paired := definition_id in ["hawk-as-weapon", "eulotha-wyvern", "lady-porcelain", "monkey", "nodh-zombie", "seth-goblin"]
	if saved.size() != (1 if paired else authored.size()):
		return saved.duplicate(true)
	var result: Array = []
	for index in range(authored.size()):
		var option: Dictionary = authored[index].duplicate(true)
		var previous: Dictionary = saved[0 if paired else index]
		for field in ["dice", "attack_dr", "defence_dr", "rules"]:
			if previous.has(field):
				option[field] = previous[field]
		if not paired and previous.has("name"):
			option["name"] = previous["name"]
		result.append(option)
	return result

func _inventory_attacks(data: Dictionary) -> Array:
	var result: Array = []
	var profiles := _profile_attacks(data)
	var items: Array = data.get("inventory", [])
	for raw in items:
		if typeof(raw) != TYPE_DICTIONARY:
			return []
		var item: Dictionary = raw
		if str(item.get("kind", "")) != "Weapon":
			continue
		var attack: Dictionary = {}
		for raw_profile in profiles:
			var profile: Dictionary = raw_profile
			if str(profile.get("id", "")) == str(item.get("source_attack_id", "")):
				attack = profile.duplicate(true)
		var inventory_id: String = item.get("inventory_id", "")
		var source_attack: String = item.get("source_attack_id", "")
		attack["id"] = inventory_id if source_attack.is_empty() else source_attack
		attack["inventory_id"] = str(item.get("inventory_id", ""))
		attack["name"] = str(item.get("name", "Attack"))
		attack["dice"] = str(item.get("damage", ""))
		attack["range_feet"] = item.get("range_feet", 0)
		attack["equipped"] = item.get("equipped", false)
		attack["broken"] = item.get("broken", false)
		attack["quantity"] = item.get("quantity", 0)
		attack["ammunition"] = item.get("ammunition", "")
		result.append(attack)
	return result

## Companion stat blocks state their own defence test; enemy blocks state the
## opposing attack test. Reverse the deviation when changing the rolling side.
func defence_test_difficulty(data: Dictionary, piercing: bool = false) -> int:
	var dr := target_attack_difficulty(data, piercing)
	return 24 - dr

func target_attack_difficulty(data: Dictionary, piercing: bool = false) -> int:
	var definition: Dictionary = CORE_DEFINITIONS.get(str(data.get("definition_id", "")), {})
	var dr: int = data.get("defence_dr", definition.get("defence_dr", 12))
	if str(data.get("definition_id", "")) in ["hawk-as-weapon", "ancient-gore-hound"]:
		dr = 24 - dr
	if piercing:
		dr = data.get("piercing_defence_dr", definition.get("piercing_defence_dr", dr))
	return dr

func attack_test_difficulty(attack: Dictionary) -> int:
	var own_dr: int = attack.get("attack_dr", 12)
	var opposing_dr: int = attack.get("defence_dr", 12)
	return own_dr + 12 - opposing_dr

func _authored_attack_defaults(saved: Array, authored: Array) -> Array:
	var result: Array = saved.duplicate(true)
	for raw in result:
		var attack: Dictionary = raw
		for entry in authored:
			if str(entry.get("id", "")) == str(attack.get("id", "")) and not attack.has("natural"):
				var natural: bool = entry.get("natural", false)
				attack["natural"] = natural
	return result
