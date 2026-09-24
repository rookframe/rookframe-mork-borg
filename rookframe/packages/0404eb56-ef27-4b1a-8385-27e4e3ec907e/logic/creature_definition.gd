extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/actor_definition.gd"

## Immutable MÖRK BORG core definitions. A live Actor receives a deep copy and
## can then edit its private encounter sheet without changing this catalogue.
const CORE_DEFINITIONS: Dictionary = {
	"hawk-as-weapon": {"display_name": "Hawk as weapon", "hit_points": 8, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"id": "claws", "natural": true, "name": "Claws", "dice": "d4", "range_feet": 5, "attack_dr": 10}, {"id": "bite", "natural": true, "name": "Bite", "dice": "d4", "range_feet": 5, "attack_dr": 10}], "defence_dr": 10, "rules": "Loyal only to its Hermit, who understands its cries. Keeps watch, scouts and attacks."},
	"ancient-gore-hound": {"display_name": "Ancient gore-hound", "hit_points": 10, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Bite", "dice": "d6", "attack_dr": 10, "id": "bite", "natural": true, "range_feet": 5}], "defence_dr": 12, "rules": "Sniffs out treasure in debris. Frenzied around goblins and berserkers."},
	"dog-small-but-vicious": {"display_name": "Small but vicious dog", "hit_points": 8, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Bite", "dice": "d4", "id": "bite", "natural": true, "range_feet": 5}]},
	"aland-wickhead": {"display_name": "Aland, Wickhead knife-wielder", "hit_points": 10, "morale": {"kind": "fixed", "value": 7}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Knife with dried blood", "dice": "d4", "id": "knife-with-dried-blood", "range_feet": 5}]},
	"arbint-troll": {"defence_dr": 10, "display_name": "Arbint, Troll", "hit_points": 32, "morale": {"kind": "special"}, "armor": {"name": "Thick hide", "reduction": "d2"}, "attacks": [{"name": "Fist", "dice": "2d6", "id": "fist", "natural": true, "range_feet": 5}]},
	"belze-skeleton": {"rules": "Moves silently and attacks by surprise. Can repeat voices it has heard. Piercing attacks against it are DR14. Any strike dealing 5 or more damage destroys it completely.", "piercing_defence_dr": 14, "destroy_at_damage": 5, "display_name": "Belze, blood-drenched skeleton", "hit_points": 7, "morale": {"kind": "fixed", "value": 8}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Shortsword", "dice": "d4", "id": "shortsword", "range_feet": 5}, {"name": "Knife", "dice": "d4", "id": "knife", "range_feet": 5}, {"name": "Bony knuckles", "dice": "d2", "id": "bony-knuckles", "natural": true, "range_feet": 5}]},
	"bent-scum": {"display_name": "Bent, Scum", "hit_points": 7, "morale": {"kind": "fixed", "value": 8}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Poisoned knife", "dice": "d4", "id": "poisoned-knife", "range_feet": 5}]},
	"eulotha-wyvern": {"display_name": "Eulotha, Wyvern", "hit_points": 25, "morale": {"kind": "fixed", "value": 10}, "armor": {"name": "Thick hide", "reduction": "d4"}, "attacks": [{"id": "bite", "natural": true, "name": "Bite", "dice": "d6", "range_feet": 5, "rules": "60% chance of biting; otherwise use Sting."}, {"id": "sting", "natural": true, "name": "Sting", "dice": "d6", "range_feet": 5, "rules": "Toughness DR14 avoids one painful hour of paralysis; duration is table managed."}]},
	"lady-porcelain": {"display_name": "Lady Porcelain, undead doll", "hit_points": 11, "morale": {"kind": "none"}, "armor": {"name": "Porcelain", "reduction": "d2"}, "attacks": [{"id": "claws", "natural": true, "name": "Claws", "dice": "d4", "range_feet": 5}, {"id": "piercing-bite", "natural": true, "name": "Piercing bite", "dice": "d4", "range_feet": 5}]},
	"lich-necromancer": {"display_name": "Lich, Undead (weak) necromancer", "hit_points": 15, "morale": {"kind": "none"}, "armor": {"name": "Barrier (necro)", "reduction": "d4"}, "attacks": [{"name": "Strike", "dice": "d6", "id": "strike", "natural": true, "range_feet": 5}]},
	"monkey": {"display_name": "Monkey", "hit_points": 6, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"id": "punch", "natural": true, "name": "Punch", "dice": "d4", "range_feet": 5}, {"id": "bite", "natural": true, "name": "Bite", "dice": "d4", "range_feet": 5}]},
	"nodh-zombie": {"display_name": "Nodh, zombie", "hit_points": 7, "morale": {"kind": "none"}, "armor": {"name": "Leather scraps", "reduction": "d2"}, "attacks": [{"id": "claw", "natural": true, "name": "Claw", "dice": "d2", "range_feet": 5}, {"id": "bite", "natural": true, "name": "Bite", "dice": "d2", "range_feet": 5, "rules": "On a bite, Toughness DR8 or death within two days followed by rising as a zombie. Delayed consequences are table managed."}]},
	"seth-goblin": {"defence_dr": 14, "display_name": "Seth, Goblin", "hit_points": 6, "morale": {"kind": "fixed", "value": 7}, "armor": {"name": "Ropy skin", "reduction": "d2"}, "attacks": [{"id": "knife", "name": "Knife", "dice": "d4", "range_feet": 5, "defence_dr": 14}, {"id": "shortbow", "name": "Shortbow", "dice": "d4", "range_feet": 30, "defence_dr": 14}]},
	"thinx-grotesque": {"defence_dr": 10, "display_name": "Thinx, Grotesque", "hit_points": 18, "morale": {"kind": "none"}, "armor": {"name": "Clay / stone", "reduction": "d6"}, "attacks": [{"name": "Claws", "dice": "d6", "id": "claws", "natural": true, "range_feet": 5}, {"name": "Eye-beam", "dice": "d8", "id": "eye-beam", "natural": true, "range_feet": 30, "always_hits": true, "rules": "Used on 1–2 on a d6 each round. Always hits."}]},
	"wrat-wraith": {"defence_dr": 14, "display_name": "Wrat, Wraith", "hit_points": 15, "morale": {"kind": "none"}, "armor": {"name": "No armor", "reduction": ""}, "attacks": [{"name": "Touch", "dice": "d4", "id": "touch", "natural": true, "range_feet": 5}]},
	"zukuma-berserker": {"defence_dr": 10, "display_name": "Zukuma, berserker", "hit_points": 13, "morale": {"kind": "fixed", "value": 9}, "armor": {"name": "Hardened skin", "reduction": "d2"}, "attacks": [{"name": "Long flail", "dice": "d8", "id": "long-flail", "range_feet": 10}, {"name": "Heavy mace", "dice": "d6", "id": "heavy-mace", "range_feet": 5}, {"name": "Chained sword", "dice": "d6", "id": "chained-sword", "range_feet": 10}, {"name": "Huge warhammer", "dice": "d10", "id": "huge-warhammer", "range_feet": 5}]},
}


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
		"inventory": [],
		"rules": definition.get("rules", ""),
	}
	for field in ["defence_dr", "piercing_defence_dr", "destroy_at_damage"]:
		if definition.has(field):
			data[field] = definition[field]
	if choices.has("creation_id"):
		data["creation_id"] = choices["creation_id"]
	if choices.has("creation_roll_sequence"):
		data["creation_roll_sequence"] = choices["creation_roll_sequence"]
	for key in ["creature_inventory", "inventory_serial", "summoner_actor", "summon_action", "grant_source", "name", "hit_points", "maximum_hit_points", "morale", "armor", "attacks", "inventory"]:
		if choices.has(key):
			data[key] = choices[key]
	return data

## Older saved core Actors used one entry for paired attacks. Resolve those
## source entries into authored alternatives without mutating the live sheet.
func attack_options(data: Dictionary) -> Array:
	if data.get("creature_inventory", false):
		return _inventory_attacks(data)
	return _profile_attacks(data)

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
