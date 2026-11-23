extends RefCounted

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE) -> void:
	_data_catalogue = data_catalogue


## Bare Bones Powers tables, pp. 32–33; effects remain table managed.
func item(family: String, roll: int) -> Dictionary:
	var entries: Array = _data_catalogue.scrolls(family)
	if roll < 1 or roll > entries.size():
		return {}
	var source: Dictionary = entries[roll - 1]
	var result: Dictionary = source.duplicate(true)
	result["roll"] = roll
	return result
