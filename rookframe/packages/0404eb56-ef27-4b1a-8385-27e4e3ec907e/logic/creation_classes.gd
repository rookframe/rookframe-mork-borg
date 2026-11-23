extends RefCounted

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE) -> void:
	_data_catalogue = data_catalogue


## Bare Bones pp. 46–57. Creation facts only; ongoing effects and Omen
## benefits remain table-managed. Returned snapshots never mutate this source.

func decoction(roll: int) -> Dictionary:
	var options := _data_catalogue.class_decoctions()
	return options[roll - 1].duplicate(true) if roll > 0 and roll <= options.size() else {}

func profile(class_id: String) -> Dictionary:
	return _data_catalogue.class_profiles().get(class_id, {}).duplicate(true)

func feature(class_id: String, roll: int) -> Dictionary:
	var features: Array = _data_catalogue.class_profiles().get(class_id, {}).get("features", [])
	return features[roll - 1].duplicate(true) if roll > 0 and roll <= features.size() else {}

func origin(class_id: String, roll: int) -> String:
	var origins: Array = _data_catalogue.class_profiles().get(class_id, {}).get("origins", [])
	return str(origins[roll - 1]) if roll > 0 and roll <= origins.size() else ""
