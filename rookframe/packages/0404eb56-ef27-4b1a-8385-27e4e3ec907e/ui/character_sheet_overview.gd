extends VBoxContainer

signal edit_requested

var _data: Dictionary = {}
@onready var _character_section := get_node(^"CharacterSection") as Control
@onready var _access_section := get_node(^"AccessSection") as Control
@onready var _companions_section := get_node(^"CompanionsSection") as Control
@onready var _modifier_actions := get_node(^"CharacterSection/Content/BodySlot/ModifierActions") as VBoxContainer


func configure(data: Dictionary, _miniatures: Array) -> void:
	_data = data
	_build()


func _build() -> void:
	var body: Container = _character_section.call("get_body_slot")
	var actions: Container = _character_section.call("get_action_slot")
	var abilities: Dictionary = _data.get("abilities", {})
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability: Dictionary = abilities.get(ability_name, {})
		var score := str(ability.get("score", "—"))
		var modifier := str(ability.get("modifier", "—"))
		body.add_child(_label("%s     %s     modifier %s" % [ability_name, score, modifier], "RookframeValue"))
		var modifier_button := _modifier_button(ability_name)
		modifier_button.text = "%s %s" % [ability_name, _signed_modifier(str(ability.get("modifier", "—")))]
		modifier_button.tooltip_text = "Roll %s %s from the completed Character sheet." % [ability_name, _signed_modifier(str(ability.get("modifier", "—")))]
	var hit_points: int = _data.get("hit_points", 0)
	var maximum_hit_points: int = _data.get("maximum_hit_points", 0)
	var silver: int = _data.get("silver", 0)
	var omens: int = _data.get("omens", 0)
	body.add_child(_label("HP %s / %s     Silver %s     Omens %s" % [hit_points, maximum_hit_points, silver, omens], "RookframeValue"))
	var origin: String = _data.get("origin", "")
	body.add_child(_label("Origin & traits: %s" % (origin if not origin.is_empty() else "none supplied by source"), "RookframeMeta"))
	var description: String = _data.get("description", "")
	if not description.is_empty():
		body.add_child(_label(description, "RookframeBody"))
	var edit := _button("Edit sheet")
	edit.pressed.connect(_emit_edit_requested)
	actions.add_child(edit)
	var access_body: Container = _access_section.call("get_body_slot")
	access_body.add_child(_label("Ordinary Actor Access is enforced by the World authority.", "RookframeMeta"))
	var companions: Array = _data.get("companion_sheets", [])
	var companion_body: Container = _companions_section.call("get_body_slot")
	companion_body.add_child(_label("None" if companions.is_empty() else "Descriptive companion data recorded", "RookframeMeta"))


func _emit_edit_requested() -> void:
	edit_requested.emit()


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


func _signed_modifier(modifier: String) -> String:
	if modifier == "—":
		return modifier
	if modifier.begins_with("-") or modifier.begins_with("+"):
		return modifier
	return "+" + modifier


func _modifier_button(ability_name: String) -> Button:
	if ability_name == "Agility":
		return _modifier_actions.get_node(^"RowOne/Agility") as Button
	if ability_name == "Presence":
		return _modifier_actions.get_node(^"RowOne/Presence") as Button
	if ability_name == "Strength":
		return _modifier_actions.get_node(^"RowTwo/Strength") as Button
	return _modifier_actions.get_node(^"RowTwo/Toughness") as Button
