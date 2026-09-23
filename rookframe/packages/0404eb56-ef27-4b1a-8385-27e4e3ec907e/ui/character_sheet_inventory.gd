extends VBoxContainer

signal add_item_requested

var _data: Dictionary = {}


func configure(data: Dictionary, _miniatures: Array) -> void:
	_data = data
	_build()


func _build() -> void:
	var body: VBoxContainer = _section("INVENTORY", "Durable Character inventory · no global footer actions")
	var inventory: Array = _data.get("inventory", [])
	if inventory.is_empty():
		body.add_child(_label("No items recorded.", "RookframeMeta"))
	else:
		for item in inventory:
			var item_data: Dictionary = item
			var item_name: String = item_data.get("name", "Item")
			body.add_child(_label(item_name, "RookframeValue"))
	var add_item := _button("Add item")
	add_item.pressed.connect(_emit_add_item_requested)
	body.add_child(add_item)


func _emit_add_item_requested() -> void:
	add_item_requested.emit()


func _label(text: String, variation: String = "RookframeBody") -> Label:
	var label := Label.new()
	label.text = text
	label.theme_type_variation = variation
	label.autowrap_mode = 2
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
