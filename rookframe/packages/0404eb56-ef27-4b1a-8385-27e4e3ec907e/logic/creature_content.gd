extends RefCounted

const CATALOGUE = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/logic/catalogue.gd")
var _data_catalogue: CATALOGUE

func _init(data_catalogue: CATALOGUE) -> void:
	_data_catalogue = data_catalogue

func details(definition: String) -> Dictionary:
	return _data_catalogue.creature_details(definition).duplicate(true)
