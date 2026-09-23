extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")
signal appearance_save_requested(index: int)
signal cancel_requested

var _miniature_count := 0
var _appearance_option: Button


func configure(data: Dictionary, miniature_count: int) -> void:
	_miniature_count = miniature_count
	var body: VBoxContainer = _section("APPEARANCE", "Choose a preferred published Miniature for this Character.")
	var option: Button = _button("Choose a published Miniature")
	_appearance_option = option
	var preferred_miniature: Dictionary = data.get("preferred_miniature", {})
	var preferred_title: String = preferred_miniature.get("title", "")
	option.pressed.connect(_cycle_appearance_miniature)
	body.add_child(option)
	var save := _button("Save appearance", true)
	save.pressed.connect(_emit_appearance_save_requested)
	body.add_child(save)
	var cancel := _button("Cancel")
	cancel.pressed.connect(_emit_cancel_requested)
	body.add_child(cancel)


func _cycle_appearance_miniature() -> void:
	var index := _miniature_button_index(_appearance_option) + 1
	if index > _miniature_count:
		index = 0
	if index == 0:
		_appearance_option.text = "Choose a published Miniature"
	else:
		_appearance_option.text = "Published Miniature %d" % index


func _miniature_button_index(option: Button) -> int:
	if option.text == "Choose a published Miniature":
		return 0
	for index in range(_miniature_count):
		if option.text == "Published Miniature %d" % (index + 1):
			return index + 1
	return 0


func _emit_appearance_save_requested() -> void:
	appearance_save_requested.emit(_miniature_button_index(_appearance_option))


func _emit_cancel_requested() -> void:
	cancel_requested.emit()


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
