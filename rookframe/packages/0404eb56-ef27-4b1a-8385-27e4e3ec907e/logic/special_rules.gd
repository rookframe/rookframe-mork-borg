extends RefCounted

## Bare Bones pp. 21–26 and 46–57. These are individual retained actions,
## not an effects engine. Distances use the approved application convention.
const TESTS := {
	"master-of-fate": {"ability": "Presence", "dr": 8, "success": "You know the right way. The table describes it.", "failure": "The right way remains unknown.", "range_feet": 0},
	"filthy-fingersmith": {"ability": "Agility", "dr": 8, "success": "Success with pockets and locks; resolve the fictional change at the table.", "failure": "Failed to pick pockets or locks.", "range_feet": 0},
	"list-of-sins": {"ability": "Presence", "dr": 10, "success": "Strange light surrounds evil creatures. Defend with +2 against beings discovered this way; apply the benefit manually.", "failure": "No creatures are revealed.", "range_feet": 30},
	"horn-of-the-schleswig-lords": {"ability": "Presence", "dr": 12, "success": "The chosen creature's next non-combat test is an automatic success. Apply the benefit manually.", "failure": "The horn grants no automatic success.", "range_feet": 30, "uses": 1},
	"stones-taken-from-thel-emas-lost-temple": {"ability": "Presence", "dr": 10, "success": "The stones tell the truth about danger in the adjacent room. The table supplies the answer.", "failure": "The stones may lie. Cannot test again until sunset; the table restores eligibility manually.", "range_feet": 0, "uses": 1},
}

const DECOCTIONS := {
	"ezumiels-vapor": {"die": 4, "text": "DR14 test or severe hallucinations for %d hours. The source does not select a PC ability; the table chooses and resolves that test. Handle hallucinations manually."},
	"southern-frog-stew": {"die": 4, "text": "Vomit for %d hours. DR14 test or do nothing else. The source does not select a PC ability; the table chooses and resolves that test. Handle vomiting manually."},
	"fernors-philtre": {"die": 4, "text": "Cures infection and gives +2 on Presence tests for %d hours. Dab into the eye; handle these benefits manually."},
	"spider-owl-soup": {"text": "See in darkness and climb walls for 30 minutes. Handle these benefits manually."},
	"hyphos-enervating-snuff": {"text": "Two attacks per round, defence DR14 for one fight. Snort the snuff; sneezing and these benefits are handled manually."},
}

const MANUAL := {
	"speaker-of-truths": {"uses": 2, "range_feet": 30, "text": "The chosen creature's next test DR is lowered by 4. Apply this benefit manually."},
	"harp": {"die": 4, "text": "Music gives +%d on the reaction roll. Apply the benefit manually."},
	"blasphemous-nechrubel-bible": {"uses": 1, "die": 6, "text": ""},
	"dodging-death": {"die": 4, "count": 2, "text": ""},
	"excretal-stealth": {"text": "When hidden in muck, debris and filth, noticing you requires Presence DR16. Resolve observers' tests manually."},
	"escaping-fate": {"text": "Each Omen use has a 50% chance not to spend it. Resolve the chance and Omen benefit manually, using ordinary dice and sheet corrections. No Omen benefit is automated."},
	"crumpled-monster-mask": {"text": "While worn, lesser creatures such as goblins, gnoums and children check Morale every round. Resolve these ongoing checks manually."},
}

func definition(key: String) -> Dictionary:
	if key == "blade-of-your-ancestors":
		return {"blade": true, "range_feet": 5}
	if key in ["bomb", "bear-trap", "caltrops"]:
		return {"damage": true, "range_feet": 30 if key == "bomb" else 5, "die": 10 if key == "bomb" else 8 if key == "bear-trap" else 4, "quantity_use": key == "bomb"}
	if key in ["dried-food", "torch", "lantern-oil", "waterskin", "lard"]:
		return {"supply": true, "range_feet": 0, "quantity_use": key in ["dried-food", "torch", "lantern-oil"], "consume": key in ["waterskin", "lard"]}
	if key == "abominable-gob-lobber":
		return {"gob": true, "range_feet": 30, "uses": 0}
	if key == "stolen-mitre":
		return {"ability_choice": true, "ability": "", "dr": 8, "range_feet": 0, "success": "Success: nearly invisible outside battle, with the mitre over your ears. Resolve the fictional change at the table.", "failure": "Stealth failed."}
	if key == "wrong-jesus-crucifix":
		return {"morale": true, "range_feet": 30}
	if key in ["ezumiels-vapor", "southern-frog-stew"]:
		return {"resistance": true, "ability_choice": true, "consume": true, "range_feet": 5, "dr": 14, "die": 4, "text": "Severe hallucinations for %d hours; handle hallucinations manually." if key == "ezumiels-vapor" else "Vomit for %d hours and can do nothing else; handle vomiting manually."}
	if key == "initiate-of-the-invisible-college":
		return {"college": true, "uses": 1, "range_feet": 0}
	if key == "portable-laboratory":
		return {"brew": true, "range_feet": 0}
	if key == "book-of-boiling-blood":
		return {"book": true, "uses": 1, "range_feet": 30, "dr": 12, "text": ""}
	if MANUAL.has(key):
		var original: Dictionary = MANUAL.get(key, {})
		var result := {"range_feet": original.get("range_feet", 0), "manual": true, "text": original.get("text", "")}
		if original.has("die"):
			result["die"] = original.get("die")
			result["count"] = original.get("count", 1)
		if original.has("uses"):
			result["uses"] = original.get("uses")
		return result
	if key in ["poison-red", "red-poison-decoction", "poison-black", "black-poison-decoction"]:
		var black := key in ["poison-black", "black-poison-decoction"]
		return {"poison": true, "consume": true, "range_feet": 5, "dr": 14 if black else 12, "die": 6 if black else 10, "text": "Blind for one hour; handle blindness manually." if black else ""}
	if DECOCTIONS.has(key):
		var original: Dictionary = DECOCTIONS.get(key, {})
		var result := {"range_feet": 5, "consume": true, "manual": true, "text": original.get("text", "")}
		if original.has("die"):
			result["die"] = original.get("die")
		return result
	if TESTS.has(key):
		var original: Dictionary = TESTS.get(key, {})
		return original.duplicate(true)
	if key in ["medicine-box", "life-elixir", "elixir-vitalis"]:
		return {"healing": true, "range_feet": 5, "consume": true}
	if key == "wizard-teeth":
		return {"range_feet": 0}
	return {}

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
const ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/character_actions.gd")

func owned(data: Dictionary, id: String) -> Dictionary:
	if id.begins_with("feature:"):
		var traits: Array = data.get("traits", [])
		for raw in traits:
			var trait_data: Dictionary = raw
			if "feature:" + str(trait_data.get("id", "")) == id:
				var feature := {"source_item_id": str(trait_data.id), "inventory_id": id, "name": str(trait_data.get("name", trait_data.id)), "rules": str(trait_data.get("rules", ""))}
				if trait_data.has("uses"):
					var uses: int = trait_data.uses
					feature["uses"] = uses
				return feature
		return {}
	for raw in ITEMS.new(null, SDK.ActorId.new("")).inventory(data):
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("inventory_id", "")) == id and quantity > 0 and not item.get("broken", false):
			return item
	return {}

