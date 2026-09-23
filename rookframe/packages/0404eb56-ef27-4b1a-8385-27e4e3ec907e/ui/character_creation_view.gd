extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

signal pack_selected(pack: String)
signal miniature_selected(index: int)

var _data: Dictionary = {}
var _stage := "create-class"
var _miniatures: Array[SDK.ContentEntry] = []
var _name_field
var _description_field
var _miniature_option: Button


func render(data: Dictionary, stage: String, miniatures: Array[SDK.ContentEntry]) -> void:
	_data = data
	_stage = stage
	_miniatures = miniatures
	for child in get_children():
		child.queue_free()
	var progress := _label(_stage_label(stage), "RookframeMeta")
	progress.name = "CreationProgress"
	add_child(progress)
	if stage == "create-class":
		_build_class_stage()
	elif stage == "create-abilities":
		_build_abilities_stage()
	elif stage == "create-origin":
		_build_origin_stage()
	elif stage == "create-equipment":
		_build_equipment_stage()
	elif stage == "create-identity":
		_build_identity_stage()
	elif stage == "create-review":
		_build_review_stage()


func identity_values() -> Dictionary:
	if _name_field == null or _description_field == null:
		return {"name": "", "description": "", "preferred_miniature": {}}
	var index := _miniature_button_index(_miniature_option)
	var preferred: Dictionary = {}
	if index > 0 and index - 1 < _miniatures.size():
		var entry: SDK.ContentEntry = _miniatures[index - 1]
		preferred = {"package_id": entry.reference.package_id, "local_id": entry.reference.local_id, "title": entry.title}
	return {"name": _name_field.get("value"), "description": _description_field.get("value"), "preferred_miniature": preferred}


func _stage_label(stage: String) -> String:
	if stage == "create-abilities":
		return "● CLASS  ·  ● ABILITIES  ·  ○ ORIGIN & TRAITS  ·  ○ EQUIPMENT  ·  ○ IDENTITY  ·  ○ REVIEW"
	if stage == "create-origin":
		return "● CLASS  ·  ● ABILITIES  ·  ● ORIGIN & TRAITS  ·  ○ EQUIPMENT  ·  ○ IDENTITY  ·  ○ REVIEW"
	if stage == "create-equipment":
		return "● CLASS  ·  ● ABILITIES  ·  ● ORIGIN & TRAITS  ·  ● EQUIPMENT  ·  ○ IDENTITY  ·  ○ REVIEW"
	if stage == "create-identity":
		return "● CLASS  ·  ● ABILITIES  ·  ● ORIGIN & TRAITS  ·  ● EQUIPMENT  ·  ● IDENTITY  ·  ○ REVIEW"
	if stage == "create-review":
		return "● CLASS  ·  ● ABILITIES  ·  ● ORIGIN & TRAITS  ·  ● EQUIPMENT  ·  ● IDENTITY  ·  ● REVIEW"
	return "● CLASS  ·  ○ ABILITIES  ·  ○ ORIGIN & TRAITS  ·  ○ EQUIPMENT  ·  ○ IDENTITY  ·  ○ REVIEW"


func _build_class_stage() -> void:
	var body: VBoxContainer = _section("CLASS", "Choose a class supplied by the installed MÖRK BORG source.")
	var selected := _button("No Class\nNormal ability rolls · 1d8 hit points · 2d6 silver · 1d2 omens", true)
	selected.alignment = 0
	selected.disabled = true
	body.add_child(selected)
	body.add_child(_label("No class origin or traits are supplied by this source profile. The later stages remain explicit so the completed sheet keeps its source-backed shape.", "RookframeMeta"))
	var facts := HBoxContainer.new()
	facts.add_theme_constant_override("separation", 6)
	for fact in ["3d6 abilities", "1d8 HP", "2d6 silver", "1d2 omens"]:
		var fact_panel := PanelContainer.new()
		fact_panel.theme_type_variation = "RookframeInsetSurface"
		fact_panel.size_flags_horizontal = 3
		fact_panel.add_child(_label(fact, "RookframeLabel"))
		facts.add_child(fact_panel)
	body.add_child(facts)


func _build_abilities_stage() -> void:
	var pending: bool = _data.get("roll_pending", false)
	var body: VBoxContainer = _section("ABILITIES", "Automatic physical Rolls are requested for the Player. No manual Throw is used.")
	if pending:
		body.add_child(_label("Rolling Agility, Presence, Strength, Toughness, and Hit points…", "RookframeMeta"))
	else:
		body.add_child(_label("The source uses normal ability rolls (3d6). The four modifiers stay visible on the completed sheet.", "RookframeMeta"))
	var abilities: Dictionary = _data.get("abilities", {})
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var value: Dictionary = abilities.get(ability_name, {})
		var score: String = value.get("score", "—")
		var modifier: String = value.get("modifier", "—")
		body.add_child(_label("%s     %s     modifier %s" % [ability_name, score, modifier], "RookframeValue"))
	var hp: String = str(_data.get("hit_points", "—"))
	body.add_child(_label("Hit points     %s / %s" % [hp, hp], "RookframeValue"))


func _build_origin_stage() -> void:
	var body: VBoxContainer = _section("ORIGIN & TRAITS", "The selected source profile does not declare an origin or traits.")
	body.add_child(_label("No class origin or traits supplied by source", "RookframeValue"))
	body.add_child(_label("Continue to choose the source-defined starting equipment pack.", "RookframeMeta"))


func _build_equipment_stage() -> void:
	var body: VBoxContainer = _section("EQUIPMENT", "Automatic source Rolls settle starting silver, omens, food, pack, weapon, and armor.")
	var pending: bool = _data.get("equipment_roll_pending", false)
	if pending:
		body.add_child(_label("Rolling starting equipment…", "RookframeMeta"))
	var totals: Dictionary = _data.get("equipment_rolls", {})
	for roll_name in ["Silver", "Omens", "Food", "Equipment pack", "Weapon", "Armor"]:
		body.add_child(_label("%s     %s" % [roll_name, str(totals.get(roll_name, "—"))], "RookframeValue"))
	body.add_child(_label("PACK", "RookframeSubtitle"))
	var choices := ["Nothing", "Backpack", "Sack", "Small wagon", "Donkey"]
	var pack_name: String = _data.get("pack", "Nothing")
	var pack: Button = _button("Pack: %s" % pack_name)
	var pack_index := 0
	for choice_index in range(choices.size()):
		if choices[choice_index] == pack_name:
			pack_index = choice_index
			break
	pack.text = "Pack: %s" % choices[pack_index if pack_index >= 0 else 0]
	pack.pressed.connect(_cycle_pack.bind(pack, choices))
	body.add_child(pack)
	var inventory: Array = _data.get("inventory", [])
	body.add_child(_label("Starting items: %s" % (_list_text(_inventory_names(inventory)) if not inventory.is_empty() else "none"), "RookframeMeta"))


func _build_identity_stage() -> void:
	var body: VBoxContainer = _section("IDENTITY", "Name and description are private Character data. Preferred Miniature is a published visual reference.")
	_name_field = _new_line_field(body, "NAME", "Character name")
	_name_field.set("value", str(_data.get("name", "")))
	_description_field = _new_text_field(body, "DESCRIPTION", "Describe this Character")
	_description_field.set("value", str(_data.get("description", "")))
	var miniature := _button("Choose a published Miniature")
	_miniature_option = miniature
	var preferred_miniature: Dictionary = _data.get("preferred_miniature", {})
	var preferred_title: String = preferred_miniature.get("title", "")
	for index in range(_miniatures.size()):
		var entry: SDK.ContentEntry = _miniatures[index]
		if entry.title == preferred_title:
			miniature.text = entry.title
	miniature.pressed.connect(_cycle_preferred_miniature.bind(miniature))
	body.add_child(_label("PREFERRED MINIATURE", "RookframeLabel"))
	body.add_child(miniature)


func _build_review_stage() -> void:
	var body: VBoxContainer = _section("REVIEW", "Review the complete staged Character before the all-or-nothing durable create.")
	body.add_child(_label("%s · No Class" % str(_data.get("name", "Unnamed Character")), "RookframeHeading"))
	var abilities: Dictionary = _data.get("abilities", {})
	var ability_summary: Array[String] = []
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability: Dictionary = abilities.get(ability_name, {})
		ability_summary.append("%s %s (%s)" % [ability_name, str(ability.get("score", "—")), str(ability.get("modifier", "—"))])
	body.add_child(_label(_list_text(ability_summary, " · "), "RookframeMeta"))
	body.add_child(_label("HP %s · Silver %s · Omens %s · Pack %s" % [str(_data.get("hit_points", "—")), str(_data.get("silver", 0)), str(_data.get("omens", 0)), str(_data.get("pack", "Nothing"))], "RookframeValue"))
	body.add_child(_label("Origin & traits: none supplied by source", "RookframeMeta"))
	var starting_creature_ids: Array = _data.get("starting_creature_ids", [])
	body.add_child(_label("Starting Creature grants: %s" % ("none" if starting_creature_ids.is_empty() else _list_text(starting_creature_ids)), "RookframeMeta"))


func _cycle_pack(pack: Button, choices: Array) -> void:
	var current := pack.text.trim_prefix("Pack: ")
	var index := 0
	for choice_index in range(choices.size()):
		if choices[choice_index] == current:
			index = choice_index + 1
			break
	if index >= choices.size():
		index = 0
	pack.text = "Pack: %s" % choices[index]
	pack_selected.emit(choices[index])


func _cycle_preferred_miniature(miniature: Button) -> void:
	var index := _miniature_button_index(miniature) + 1
	if index > _miniatures.size():
		index = 0
	if index == 0:
		miniature.text = "Choose a published Miniature"
	else:
		miniature.text = _miniatures[index - 1].title
	miniature_selected.emit(index)


func _miniature_button_index(miniature: Button) -> int:
	if miniature == null or miniature.text == "Choose a published Miniature":
		return 0
	for index in range(_miniatures.size()):
		var entry: SDK.ContentEntry = _miniatures[index]
		if miniature.text == entry.title:
			return index + 1
	return 0


func _inventory_names(items: Array) -> Array[String]:
	var names: Array[String] = []
	for item in items:
		var item_data: Dictionary = item
		var item_name: String = item_data.get("name", "Item")
		names.append(item_name)
	return names


func _list_text(items: Array, separator: String = ", ") -> String:
	if items.is_empty():
		return ""
	var first: String = str(items[0])
	if items.size() == 1:
		return first
	var second: String = str(items[1])
	if items.size() == 2:
		return "%s%s%s" % [first, separator, second]
	var third: String = str(items[2])
	if items.size() == 3:
		return "%s%s%s%s%s" % [first, separator, second, separator, third]
	var fourth: String = str(items[3])
	return "%s%s%s%s%s%s%s" % [first, separator, second, separator, third, separator, fourth]


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
