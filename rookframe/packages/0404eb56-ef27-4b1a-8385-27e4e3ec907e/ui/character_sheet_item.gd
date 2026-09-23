extends VBoxContainer

signal item_save_requested(item_name: String)
signal cancel_requested

var _item_field


func configure(_data: Dictionary, _miniatures: Array) -> void:
	var body: VBoxContainer = _section("ADD ITEM", "Add durable inventory data to this Character Actor.")
	_item_field = _new_line_field(body, "NEW ITEM", "Item name")
	var save := _button("Save item", true)
	save.pressed.connect(_emit_item_save_requested)
	body.add_child(save)
	var cancel := _button("Cancel")
	cancel.pressed.connect(_emit_cancel_requested)
	body.add_child(cancel)


func _emit_item_save_requested() -> void:
	var item_name: String = _item_field.get("value")
	item_save_requested.emit(item_name.strip_edges())


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


func _new_line_field(parent: VBoxContainer, label_text: String, placeholder: String):
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


func _section(title: String, subtitle: String = "") -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.theme_type_variation = "RookframeInsetSurface"
	panel.size_flags_horizontal = 3
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 6)
	body.add_child(_label(title.to_upper(), "RookframeSubtitle"))
	if not subtitle.is_empty():
		body.add_child(_label(subtitle, "RookframeMeta"))
	panel.add_child(body)
	add_child(panel)
	return body
