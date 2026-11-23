extends RefCounted

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE) -> void:
	_data_catalogue = data_catalogue


## Bare Bones pp. 21–26 and 46–57. These are individual retained actions,
## not an effects engine. Distances use the approved application convention.
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
	var manual: Variant = _data_catalogue.action_record("MANUAL", key)
	if manual != null:
		var original: Dictionary = manual
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
	var decoction: Variant = _data_catalogue.action_record("DECOCTIONS", key)
	if decoction != null:
		var original: Dictionary = decoction
		var result := {"range_feet": 5, "consume": true, "manual": true, "text": original.get("text", "")}
		if original.has("die"):
			result["die"] = original.get("die")
		return result
	var test: Variant = _data_catalogue.action_record("TESTS", key)
	if typeof(test) == TYPE_DICTIONARY:
		var test_record: Dictionary = test
		return test_record.duplicate(true)
	if key in ["medicine-box", "life-elixir", "elixir-vitalis"]:
		return {"healing": true, "range_feet": 5, "consume": true}
	if key == "wizard-teeth":
		return {"range_feet": 0}
	return {}

const SDK = preload("res://rookframe/sdk/package_sdk_facade.gd")
const ITEMS = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/actor_inventory.gd")

func owned(data: Dictionary, id: String) -> Dictionary:
	if id.begins_with("feature:") or id.begins_with("owned-feature:"):
		var traits: Array = data.get("traits", [])
		for raw in traits:
			var trait_data: Dictionary = raw
			var feature_id: String = trait_data.get("id", "")
			if feature_matches(trait_data, id):
				var name: String = trait_data.get("name", feature_id)
				var rules: String = trait_data.get("rules", "")
				var feature := {"source_item_id": feature_id, "inventory_id": id, "name": name, "rules": rules}
				if trait_data.has("uses"):
					var uses: int = trait_data.uses
					feature["uses"] = uses
				return feature
		return {}
	for raw in ITEMS.new(null, SDK.ActorId.new(""), _data_catalogue).inventory(data):
		var item: Dictionary = raw
		var quantity: int = item.get("quantity", 0)
		if str(item.get("inventory_id", "")) == id and quantity > 0 and not item.get("broken", false):
			return item
	return {}


func feature_matches(feature: Dictionary, owned_id: String) -> bool:
	if owned_id.begins_with("owned-feature:"):
		var identity := str(feature.get("favorite_entry_id", ""))
		return not identity.is_empty() and "owned-feature:" + identity == owned_id
	return "feature:" + str(feature.get("id", "")) == owned_id
