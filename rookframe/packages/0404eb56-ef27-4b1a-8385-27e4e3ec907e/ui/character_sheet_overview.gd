extends VBoxContainer

signal edit_requested

var _data: Dictionary = {}


func configure(data: Dictionary, _miniatures: Array) -> void:
	_data = data
	_build()


func _build() -> void:
	var body: VBoxContainer = _section("CHARACTER", "Completed durable sheet · creator Owner and GM inherent Owner")
	var abilities: Dictionary = _data.get("abilities", {})
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability: Dictionary = abilities.get(ability_name, {})
		var score: String = ability.get("score", "—")
		var modifier: String = ability.get("modifier", "—")
		body.add_child(_label("%s     %s     modifier %s" % [ability_name, score, modifier], "RookframeValue"))
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
	body.add_child(edit)
	var access := _section("ACCESS", "The creating Player is Owner. The GM is inherent Owner; other Players receive no automatic grant.")
	access.add_child(_label("Ordinary Actor Access is enforced by the World authority.", "RookframeMeta"))
	var companions: Array = _data.get("companion_sheets", [])
	var companion_body := _section("COMPANIONS", "Descriptive companion data stays on this Character sheet until a source grant creates an individual Actor.")
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
