extends VBoxContainer

signal sheet_save_requested(private_name: String, description: String, hit_points: int, silver: int, omens: int)
signal cancel_requested

var _name_field
var _description_field
var _hit_points_field
var _silver_field
var _omens_field


func configure(data: Dictionary, _miniatures: Array) -> void:
	var body: VBoxContainer = _section("EDIT CHARACTER", "Changes update the completed Actor and persist through the World authority.")
	_name_field = _new_line_field(body, "NAME", "Character name")
	var character_name: String = data.get("name", "")
	_name_field.set("value", character_name)
	_description_field = _new_text_field(body, "DESCRIPTION", "Description")
	var character_description: String = data.get("description", "")
	_description_field.set("value", character_description)
	_hit_points_field = _new_line_field(body, "HIT POINTS", "Hit points")
	var hit_points: int = data.get("hit_points", 1)
	_hit_points_field.set("value", str(hit_points))
	_silver_field = _new_line_field(body, "SILVER", "Silver")
	var silver: int = data.get("silver", 0)
	_silver_field.set("value", str(silver))
	_omens_field = _new_line_field(body, "OMENS", "Omens")
	var omens: int = data.get("omens", 0)
	_omens_field.set("value", str(omens))
	var save := _button("Save changes", true)
	save.pressed.connect(_emit_sheet_save_requested)
	body.add_child(save)
	var cancel := _button("Cancel")
	cancel.pressed.connect(_emit_cancel_requested)
	body.add_child(cancel)


func _emit_sheet_save_requested() -> void:
	var private_name: String = _name_field.get("value")
	var description: String = _description_field.get("value")
	var hit_points: int = int(_hit_points_field.get("value"))
	var silver: int = int(_silver_field.get("value"))
	var omens: int = int(_omens_field.get("value"))
	sheet_save_requested.emit(private_name.strip_edges(), description.strip_edges(), hit_points, silver, omens)


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


func _new_line_field(parent: VBoxContainer, label_text: String, placeholder: String):
	var field = preload("res://rookframe/ui/components/forms/text_field.tscn").instantiate()
	field.set("label_text", label_text)
	field.set("placeholder", placeholder)
	parent.add_child(field)
	return field


func _new_text_field(parent: VBoxContainer, label_text: String, placeholder: String):
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
