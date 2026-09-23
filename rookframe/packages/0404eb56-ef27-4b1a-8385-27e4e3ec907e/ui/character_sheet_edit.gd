extends VBoxContainer

signal sheet_save_requested(private_name: String, description: String, hit_points: int, maximum_hit_points: int, silver: int, omens: int, abilities: Dictionary, inventory: Array)
signal cancel_requested

@onready var _section := get_node(^"EditSection") as Control
var _name_field
var _description_field
var _hit_points_field
var _maximum_hit_points_field
var _silver_field
var _omens_field
var _agility_field
var _presence_field
var _strength_field
var _toughness_field
var _inventory: Array = []
var _inventory_fields: Array = []


func configure(data: Dictionary, _miniatures: Array) -> void:
	_inventory = data.get("inventory", [])
	_inventory_fields = []
	var body: Container = _section.call("get_body_slot")
	var actions: Container = _section.call("get_action_slot")
	_name_field = _new_line_field(body, "NAME", "Character name")
	var character_name: String = data.get("name", "")
	_name_field.set("value", character_name)
	_description_field = _new_text_field(body, "DESCRIPTION", "Description")
	var character_description: String = data.get("description", "")
	_description_field.set("value", character_description)
	_hit_points_field = _new_line_field(body, "HIT POINTS", "Hit points")
	var hit_points: int = data.get("hit_points", 1)
	_hit_points_field.set("value", str(hit_points))
	_maximum_hit_points_field = _new_line_field(body, "MAXIMUM HIT POINTS", "Maximum hit points")
	var maximum_hit_points: int = data.get("maximum_hit_points", hit_points)
	_maximum_hit_points_field.set("value", str(maximum_hit_points))
	_silver_field = _new_line_field(body, "SILVER", "Silver")
	var silver: int = data.get("silver", 0)
	_silver_field.set("value", str(silver))
	_omens_field = _new_line_field(body, "OMENS", "Omens")
	var omens: int = data.get("omens", 0)
	_omens_field.set("value", str(omens))
	var abilities: Dictionary = data.get("abilities", {})
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability_data: Dictionary = abilities.get(ability_name, {})
		var ability_field = _new_line_field(body, ability_name.to_upper(), "Score")
		ability_field.set("value", str(ability_data.get("score", 1)))
		if ability_name == "Agility":
			_agility_field = ability_field
		elif ability_name == "Presence":
			_presence_field = ability_field
		elif ability_name == "Strength":
			_strength_field = ability_field
		else:
			_toughness_field = ability_field
	for inventory_index in range(_inventory.size()):
		var item_data: Dictionary = _inventory[inventory_index]
		var item_name: String = str(item_data.get("name", "Item"))
		for quantity_key in ["quantity", "uses"]:
			if not item_data.has(quantity_key):
				continue
			var inventory_field = _new_line_field(body, "%s %s" % [item_name.to_upper(), str(quantity_key).to_upper()], quantity_key)
			inventory_field.set("value", str(item_data.get(quantity_key, 0)))
			_inventory_fields.append({"index": inventory_index, "key": quantity_key, "field": inventory_field})
	var save := _button("Save changes", true)
	save.pressed.connect(_emit_sheet_save_requested)
	actions.add_child(save)
	var cancel := _button("Cancel")
	cancel.pressed.connect(_emit_cancel_requested)
	actions.add_child(cancel)


func _emit_sheet_save_requested() -> void:
	var private_name: String = _name_field.get("value")
	var description: String = _description_field.get("value")
	var hit_points: int = int(_hit_points_field.get("value"))
	var maximum_hit_points: int = int(_maximum_hit_points_field.get("value"))
	var silver: int = int(_silver_field.get("value"))
	var omens: int = int(_omens_field.get("value"))
	var abilities: Dictionary = {}
	abilities["Agility"] = {"score": int(_agility_field.get("value"))}
	abilities["Presence"] = {"score": int(_presence_field.get("value"))}
	abilities["Strength"] = {"score": int(_strength_field.get("value"))}
	abilities["Toughness"] = {"score": int(_toughness_field.get("value"))}
	var inventory := _inventory.duplicate(true)
	var normalized_inventory: Array = []
	for raw_item in inventory:
		var item_data: Dictionary = raw_item
		var item_index := normalized_inventory.size()
		for entry in _inventory_fields:
			if int(entry.get("index", -1)) != item_index:
				continue
			var quantity_key: String = str(entry.get("key", ""))
			var quantity := int(entry.get("field").get("value"))
			if quantity < 0:
				quantity = 0
			item_data[quantity_key] = quantity
		normalized_inventory.append(item_data)
	inventory = normalized_inventory
	sheet_save_requested.emit(private_name.strip_edges(), description.strip_edges(), hit_points, maximum_hit_points, silver, omens, abilities, inventory)


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


func _new_line_field(parent: Container, label_text: String, placeholder: String):
	var field = preload("res://rookframe/ui/components/forms/text_field.tscn").instantiate()
	field.set("label_text", label_text)
	field.set("placeholder", placeholder)
	parent.add_child(field)
	return field


func _new_text_field(parent: Container, label_text: String, placeholder: String):
	var field = preload("res://rookframe/ui/components/forms/text_area.tscn").instantiate()
	field.set("label_text", label_text)
	field.set("placeholder", placeholder)
	parent.add_child(field)
	return field


func _label(text: String, variation: String = "RookframeBody") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	return label


func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = 2
	button.theme_type_variation = "RookframePrimaryButton" if primary else "RookframeSecondaryButton"
	return button
