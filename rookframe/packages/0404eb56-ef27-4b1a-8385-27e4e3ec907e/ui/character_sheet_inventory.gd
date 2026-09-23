extends VBoxContainer

signal add_item_requested

var _data: Dictionary = {}
@onready var _section := get_node(^"InventorySection") as Control


func configure(data: Dictionary, _miniatures: Array) -> void:
	_data = data
	_build()


func _build() -> void:
	var body: Container = _section.call("get_body_slot")
	var actions: Container = _section.call("get_action_slot")
	var inventory: Array = _data.get("inventory", [])
	if inventory.is_empty():
		body.add_child(_label("No items recorded.", "RookframeMeta"))
	else:
		for item in inventory:
			var item_data: Dictionary = item
			var item_name: String = item_data.get("name", "Item")
			body.add_child(_label(item_name, "RookframeBody"))
	var add_item := _button("Add item")
	add_item.pressed.connect(_emit_add_item_requested)
	actions.add_child(add_item)


func _emit_add_item_requested() -> void:
	add_item_requested.emit()


func _label(text: String, variation: String = "RookframeBody") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = 2
	label.set("theme_override_font_sizes/font_size", 16)
	return label


func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 44)
	button.focus_mode = 2
	button.theme_type_variation = "RookframePrimaryButton" if primary else "RookframeSecondaryButton"
	return button
