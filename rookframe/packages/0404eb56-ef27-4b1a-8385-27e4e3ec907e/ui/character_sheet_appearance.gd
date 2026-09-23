extends VBoxContainer

signal appearance_save_requested(index: int)

var _miniature_count := 0
var _appearance_choice_index := 0
var _appearance_option: Button
var _miniature_choices: Array[Dictionary] = []
@onready var _section := get_node(^"AppearanceSection") as Control


func configure(data: Dictionary, miniature_count: int, miniature_choices: Array[Dictionary]) -> void:
	_miniature_count = miniature_count
	_miniature_choices = miniature_choices
	var body: Container = _section.call("get_body_slot")
	var option: Button = _button("Choose a published Miniature")
	_appearance_option = option
	var preferred_miniature: Dictionary = data.get("preferred_miniature", {})
	var preferred_index: int = preferred_miniature.get("choice_index", 0)
	if preferred_index <= 0:
		var preferred_local_id: String = preferred_miniature.get("local_id", "")
		for index in range(_miniature_choices.size()):
			if str(_miniature_choices[index].get("local_id", "")) == preferred_local_id:
				preferred_index = index + 1
	_appearance_choice_index = preferred_index
	if preferred_index > 0:
		option.text = "Published Miniature %d" % preferred_index
	option.pressed.connect(_cycle_appearance_miniature)
	body.add_child(option)


func _cycle_appearance_miniature() -> void:
	var index := _appearance_choice_index + 1
	if index > _miniature_count:
		index = 0
	if index == 0:
		_appearance_option.text = "Choose a published Miniature"
	else:
		_appearance_option.text = "Published Miniature %d" % index
	_appearance_choice_index = index
	if index > 0:
		appearance_save_requested.emit(index)


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
