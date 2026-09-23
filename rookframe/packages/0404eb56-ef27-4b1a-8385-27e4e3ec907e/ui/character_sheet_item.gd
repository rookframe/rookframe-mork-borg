extends VBoxContainer

signal item_save_requested(item_name: String)
signal cancel_requested

var _item_field
@onready var _section := get_node(^"ItemSection") as Control


func configure(_data: Dictionary, _miniatures: Array) -> void:
	var body: Container = _section.call("get_body_slot")
	var actions: Container = _section.call("get_action_slot")
	_item_field = _new_line_field(body, "NEW ITEM", "Item name")
	var save := _button("Save item", true)
	save.pressed.connect(_emit_item_save_requested)
	actions.add_child(save)
	var cancel := _button("Cancel")
	cancel.pressed.connect(_emit_cancel_requested)
	actions.add_child(cancel)


func _emit_item_save_requested() -> void:
	var item_name: String = _item_field.get("value")
	item_save_requested.emit(item_name.strip_edges())


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


func _new_line_field(parent: Container, label_text: String, placeholder: String):
	var field = preload("res://rookframe/ui/components/forms/text_field.tscn").instantiate()
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
