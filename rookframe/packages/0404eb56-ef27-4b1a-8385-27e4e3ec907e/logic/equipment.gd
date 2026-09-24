extends RefCounted
const SCROLLS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/starting_scrolls.gd")

## Core equipment facts from Bare Bones pp. 21–26; Bevy catalogue is reuse evidence.
## Ranges are the approved application convention, not printed weapon ranges.
# Catalogue rows: id, name, kind, rules, price, source, damage, range, armor tier, reduction, uses, attack ability, ammunition.
# Named live dictionaries are constructed at the boundary; each call returns fresh data.
const ROWS: Array = [
	["femur", "Femur", "Weapon", "", "worthless", "Bare Bones · Weapons", "d4", 5, -1, "", -1, "Strength", ""],
	["arrow", "Arrow", "Equipment", "One arrow", "", "Bare Bones · Weapons", "", -1, -1, "", -1, "", "arrow"],
	["backpack", "Backpack", "Equipment", "Holds 7 normal-sized items", "6s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["battle-axe", "Battle axe", "Weapon", "", "35s", "Bare Bones · Weapons", "d8", 5, -1, "", -1, "Strength", ""],
	["bear-trap", "Bear trap", "Equipment", "Presence dr14 to spot", "20s", "Bare Bones · Equipment", "d8", -1, -1, "", -1, "", ""],
	["blanket", "Blanket", "Equipment", "", "4s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["bolt", "Bolt", "Equipment", "One bolt", "", "Bare Bones · Weapons", "", -1, -1, "", -1, "", "bolt"],
	["bomb", "Bomb", "Equipment", "Sealed bottle", "", "Bare Bones · Starting equipment", "d10", -1, -1, "", -1, "", ""],
	["bow", "Bow", "Weapon", "with Presence +10 arrows", "25s", "Bare Bones · Weapons", "d6", 30, -1, "", -1, "Presence", "arrow"],
	["caltrops", "Caltrops", "Equipment", "Infection on 1 in 6", "7s", "Bare Bones · Equipment", "d4", -1, -1, "", -1, "", ""],
	["chalk", "Chalk", "Equipment", "", "1s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["chewing-tobacco", "Chewing tobacco", "Equipment", "", "1s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["club", "Club", "Weapon", "", "10s", "Bare Bones · Weapons", "d6", 5, -1, "", -1, "Strength", ""],
	["crossbow", "Crossbow", "Weapon", "with Presence + 10 bolts", "40s", "Bare Bones · Weapons", "d8", 30, -1, "", -1, "Presence", "bolt"],
	["crowbar", "Crowbar", "Equipment", "", "8s", "Bare Bones · Equipment", "d4", -1, -1, "", -1, "", ""],
	["crucifix-silver", "Crucifix, silver", "Equipment", "", "60s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["crucifix-wood", "Crucifix, wood", "Equipment", "", "8s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["dog-small-but-vicious", "Small but vicious dog", "Equipment", "d6+2 hp, bite d4, only obeys you", "", "Bare Bones · Starting equipment", "d4", -1, -1, "", -1, "", ""],
	["dog-trained", "Dog (trained)", "Equipment", "", "25s", "Bare Bones · Beasts", "", -1, -1, "", -1, "", ""],
	["dog-wild", "Dog (wild)", "Equipment", "", "10s", "Bare Bones · Beasts", "", -1, -1, "", -1, "", ""],
	["donkey", "Donkey", "Equipment", "not bad", "", "Bare Bones · Starting equipment", "", -1, -1, "", -1, "", ""],
	["dried-food", "Dried food", "Equipment", "1 day\nCharacters begin with d4 days worth of food", "1s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["exquisite-perfume", "Exquisite perfume", "Equipment", "", "25s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["firesteel", "Firesteel", "Equipment", "", "4s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["flail", "Flail", "Weapon", "", "35s", "Bare Bones · Weapons", "d8", 5, -1, "", -1, "Strength", ""],
	["grappling-hook", "Grappling hook", "Equipment", "", "12s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["hammer", "Hammer", "Equipment", "", "8s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["handaxe", "Handaxe", "Weapon", "", "15s", "Bare Bones · Weapons", "d6", 5, -1, "", -1, "Strength", ""],
	["heavy-armor", "Heavy armor", "Armor", "splint, plate etc\n−d6 damage, tier 3", "200s", "Bare Bones · Armor", "", -1, 3, "d6", -1, "", ""],
	["heavy-chain", "Heavy chain", "Equipment", "15 feet", "10s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["horse", "Horse", "Equipment", "", "80s", "Bare Bones · Beasts", "", -1, -1, "", -1, "", ""],
	["iron-nails", "Iron nails", "Equipment", "10 nails", "10s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["knife", "Knife", "Weapon", "", "10s", "Bare Bones · Weapons", "d4", 5, -1, "", -1, "Strength", ""],
	["ladder", "Ladder", "Equipment", "", "7s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["lantern-oil", "Lantern oil", "Equipment", "Presence + 6 hours", "5s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["lantern-with-oil", "Lantern with oil", "Equipment", "Presence + 6 hours", "", "Bare Bones · Starting equipment", "", -1, -1, "", -1, "", ""],
	["lard", "Lard", "Equipment", "May function as 5 meals", "5s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["large-iron-hook", "Large iron hook", "Equipment", "", "9s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["life-elixir", "Life elixir", "Equipment", "d4 doses\nHeals d6 hp and removes infection", "", "Bare Bones · Starting equipment", "", -1, -1, "", -1, "", ""],
	["light-armor", "Light armor", "Armor", "fur, padded cloth, leather etc\n−d2 damage, tier 1", "20s", "Bare Bones · Armor", "", -1, 1, "d2", -1, "", ""],
	["lockpicks", "Lockpicks", "Equipment", "", "5s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["mace", "Mace", "Weapon", "", "25s", "Bare Bones · Weapons", "d6", 5, -1, "", -1, "Strength", ""],
	["magnesium-strip", "Magnesium strip", "Equipment", "", "4s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["manacles", "Manacles", "Equipment", "", "10s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["mattress", "Mattress", "Equipment", "", "3s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["meat-cleaver", "Meat cleaver", "Equipment", "", "15s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["medicine-box", "Medicine box", "Equipment", "Stops bleeding/infection and heals d6 hp\nPresence + 4 uses", "15s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["medium-armor", "Medium armor", "Armor", "scale, mail etc\n−d4 damage, tier 2", "100s", "Bare Bones · Armor", "", -1, 2, "d4", -1, "", ""],
	["metal-file", "Metal file", "Equipment", "", "10s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["mirror", "Mirror", "Equipment", "", "15s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["monkeys", "Monkeys", "Equipment", "d4 monkeys that ignore but love you (d4+2 hp, punch/bite d4)", "", "Bare Bones · Starting equipment", "d4", -1, -1, "", -1, "", ""],
	["mule", "Mule", "Equipment", "", "10s", "Bare Bones · Beasts", "", -1, -1, "", -1, "", ""],
	["muzzle", "Muzzle", "Equipment", "", "6s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["noose", "Noose", "Equipment", "", "5s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["oil-lamp", "Oil lamp", "Equipment", "", "10s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["poison-black", "Poison (black)", "Equipment", "Toughness dr14 or d6 damage + blind for one hour\n3 doses", "20s", "Bare Bones · Equipment", "d6", -1, -1, "", 3, "", ""],
	["poison-red", "Poison (red)", "Equipment", "Toughness dr12 or d10 damage\n3 doses\nStarting equipment supplies a bottle with d4 doses", "20s", "Bare Bones · Equipment", "d10", -1, -1, "", 3, "", ""],
	["preserved-corpse", "Preserved corpse", "Equipment", "", "66 + d6s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["rat-tame", "Rat (tame)", "Equipment", "", "8s", "Bare Bones · Beasts", "", -1, -1, "", -1, "", ""],
	["rope", "Rope", "Equipment", "30 feet", "4s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["sack", "Sack", "Equipment", "Holds 10 normal sized items", "3s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["salt", "Salt", "Equipment", "", "4s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["scissors", "Scissors", "Equipment", "", "9s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["scroll", "Scroll", "Equipment", "", "worth roughly 50s to the right buyer", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["sharp-needle", "Sharp Needle", "Equipment", "", "3s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["shield", "Shield", "Shield", "−1 damage\n-1 hp damage or have the shield break to ignore one attack", "20s", "Bare Bones · Armor", "", -1, -1, "", -1, "", ""],
	["shortbow", "Shortbow", "Weapon", "", "13s", "Bare Bones · Weapons", "d4", 30, -1, "", -1, "Presence", "arrow"],
	["shortsword", "Shortsword", "Weapon", "", "20s", "Bare Bones · Weapons", "d4", 5, -1, "", -1, "Strength", ""],
	["sling", "Sling", "Weapon", "", "8s", "Bare Bones · Weapons", "d4", 30, -1, "", -1, "Presence", ""],
	["small-wagon", "Small wagon", "Equipment", "", "25s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["staff", "Staff", "Weapon", "", "5s", "Bare Bones · Weapons", "d4", 10, -1, "", -1, "Strength", ""],
	["sword", "Sword", "Weapon", "", "30s", "Bare Bones · Weapons", "d6", 5, -1, "", -1, "Strength", ""],
	["ten-bolts", "10 bolts", "Equipment", "10 bolts", "10s", "Bare Bones · Weapons", "", -1, -1, "",10, "", "bolt"],
	["tent", "Tent", "Equipment", "", "12s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["toolbox", "Toolbox", "Equipment", "10 nails, hammer, small saw, tongs; starting equipment: 10 nails, tongs, hammer, small saw and drill", "20s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["torch", "Torch", "Equipment", "", "2s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["twenty-arrows", "20 arrows", "Equipment", "20 arrows", "10s", "Bare Bones · Weapons", "", -1, -1, "",20, "", "arrow"],
	["warhammer", "Warhammer", "Weapon", "", "30s", "Bare Bones · Weapons", "d6", 5, -1, "", -1, "Strength", ""],
	["waterskin", "Waterskin", "Equipment", "4 days of water\nCharacters begin with a waterskin", "4s", "Bare Bones · Equipment", "", -1, -1, "", -1, "", ""],
	["whip", "Whip", "Weapon", "", "5s", "Bare Bones · Weapons", "d2", 10, -1, "", -1, "Strength", ""],
	["zweihander", "Zweihänder", "Weapon", "", "60s", "Bare Bones · Weapons", "d10", 5, -1, "", -1, "Strength", ""],
]


func entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in ROWS:
		result.append(_entry(row))
	var tables: Dictionary = SCROLLS.TABLES
	for family in ["unclean", "sacred"]:
		var entries: Array = tables.get(family, [])
		for raw in entries:
			var entry: Dictionary = raw
			result.append(entry.duplicate(true))
	return result

func item(id: String) -> Dictionary:
	for row in ROWS:
		if str(row[0]) == id:
			return _entry(row)
	var tables: Dictionary = SCROLLS.TABLES
	for family in ["unclean", "sacred"]:
		var entries: Array = tables.get(family, [])
		for raw in entries:
			var entry: Dictionary = raw
			if str(entry.source_item_id) == id:
				return entry.duplicate(true)
	return {}

func _entry(row: Array) -> Dictionary:
	var entry: Dictionary = {"source_item_id": str(row[0]), "name": str(row[1]), "kind": str(row[2]), "rules": str(row[3]), "price": str(row[4]), "source": str(row[5]), "quantity": 1, "equipped": false}
	var damage: String = row[6]
	var weapon_range: int = row[7]
	var tier: int = row[8]
	var reduction: String = row[9]
	var uses: int = row[10]
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
