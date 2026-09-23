extends VBoxContainer

const SDK = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/package_sdk_facade.gd")

signal status_changed(message: String, error: bool)
signal busy_changed(value: bool)
signal primary_changed(text: String, disabled: bool)
signal character_created(actor: SDK.Actor)

var sdk: SDK
var _definitions: Array[SDK.ContentEntry] = []
var _character_definition: SDK.ContentEntry
var _character_miniatures: Array[SDK.ContentEntry] = []
var _character_miniature_choices: Array[Dictionary] = []
var _compact := false
var _character_content: VBoxContainer
var _status: Label
var _character_draft: Dictionary = {}
var _character_stage := "create-class"
var _creation_generation := 0
var _creation_active := false
var _busy := false
var _character_tab := "character"
var _character_name_field
var _character_description_field
var _character_fields: Dictionary = {}


func configure(definitions: Array[SDK.ContentEntry], character_definition: SDK.ContentEntry, miniatures: Array[SDK.ContentEntry], compact: bool, facade: SDK, miniature_choices: Array[Dictionary] = []) -> void:
	_definitions = definitions
	_character_definition = character_definition
	_character_miniatures = miniatures
	_character_miniature_choices = miniature_choices
	_compact = compact
	sdk = facade
	_character_content = self


func begin() -> void:
	_begin_character_creation()


func primary() -> void:
	_on_character_primary_action()


func start_over() -> void:
	_start_over_character()


func discard() -> void:
	_discard_character_creation()


func is_active() -> bool:
	return _creation_active


func clear_creation() -> void:
	_discard_character_creation()
	for child in get_children():
		child.queue_free()


func show_creation_route(route: String) -> void:
	_show_creation_route(route)


func _ready() -> void:
	_character_content = self

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


func _show_creation_route(route: String) -> void:
	for child in get_children():
		child.queue_free()
	_character_fields = {}
	var progress := _label(_stage_label(route), "RookframeMeta")
	progress.name = "CreationProgress"
	add_child(progress)
	_character_stage = route
	if route == "create-class":
		_build_class_stage()
	elif route == "create-abilities":
		_build_abilities_stage()
	elif route == "create-origin":
		_build_origin_stage()
	elif route == "create-equipment":
		_build_equipment_stage()
	elif route == "create-identity":
		_build_identity_stage()
	elif route == "create-review":
		_build_review_stage()
	primary_changed.emit("Create character" if route == "create-review" else "Continue", route == "create-abilities" and bool(_character_draft.get("roll_pending", false)))


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
	var pending := bool(_character_draft.get("roll_pending", false))
	var body: VBoxContainer = _section("ABILITIES", "Automatic physical Rolls are requested for the Player. No manual Throw is used.")
	if pending:
		body.add_child(_label("Rolling Agility, Presence, Strength, Toughness, and Hit points…", "RookframeMeta"))
	else:
		body.add_child(_label("The source uses normal ability rolls (3d6). The four modifiers stay visible on the completed sheet.", "RookframeMeta"))
	var abilities: Dictionary = _character_draft.get("abilities", {})
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var value: Dictionary = abilities.get(ability_name, {})
		var score := str(value.get("score", "—"))
		var modifier := str(value.get("modifier", "—"))
		body.add_child(_label("%s     %s     modifier %s" % [ability_name, score, modifier], "RookframeValue"))
	var hp: Variant = _character_draft.get("hit_points", "—")
	body.add_child(_label("Hit points     %s / %s" % [hp, hp], "RookframeValue"))


func _build_origin_stage() -> void:
	var body: VBoxContainer = _section("ORIGIN & TRAITS", "The selected source profile does not declare an origin or traits.")
	body.add_child(_label("No class origin or traits supplied by source", "RookframeValue"))
	body.add_child(_label("Continue to choose the source-defined starting equipment pack.", "RookframeMeta"))


func _build_equipment_stage() -> void:
	var body: VBoxContainer = _section("EQUIPMENT", "Automatic source Rolls settle starting silver, omens, food, pack, weapon, and armor.")
	var pending := bool(_character_draft.get("equipment_roll_pending", false))
	if pending:
		body.add_child(_label("Rolling starting equipment…", "RookframeMeta"))
	var totals: Dictionary = _character_draft.get("equipment_rolls", {})
	for roll_name in ["Silver", "Omens", "Food", "Equipment pack", "Weapon", "Armor"]:
		body.add_child(_label("%s     %s" % [roll_name, str(totals.get(roll_name, "—"))], "RookframeValue"))
	body.add_child(_label("PACK", "RookframeSubtitle"))
	var choices := ["Nothing", "Backpack", "Sack", "Small wagon", "Donkey"]
	var pack := _button("Pack: %s" % str(_character_draft.get("pack", "Nothing")))
	var pack_index := 0
	for index in range(choices.size()):
		if choices[index] == str(_character_draft.get("pack", "Nothing")):
			pack_index = index
	pack.text = "Pack: %s" % choices[pack_index]
	pack.pressed.connect(_cycle_pack.bind(pack, choices))
	body.add_child(pack)
	var inventory: Array = _character_draft.get("inventory", [])
	body.add_child(_label("Starting items: %s" % (_list_text(_inventory_names(inventory)) if not inventory.is_empty() else "none"), "RookframeMeta"))


func _build_identity_stage() -> void:
	var body: VBoxContainer = _section("IDENTITY", "Name and description are private Character data. Preferred Miniature is a published visual reference.")
	_character_name_field = _new_line_field(body, "NAME", "Character name")
	_character_name_field.set("value", str(_character_draft.get("name", "")))
	_character_description_field = _new_text_field(body, "DESCRIPTION", "Describe this Character")
	_character_description_field.set("value", str(_character_draft.get("description", "")))
	var miniature: Button = _button("Choose a published Miniature")
	miniature.name = "PreferredMiniature"
	var selected_index := 0
	var preferred_miniature: Dictionary = _character_draft.get("preferred_miniature", {})
	var preferred_title: String = preferred_miniature.get("title", "")
	for index in range(_character_miniatures.size()):
		var choice: Dictionary = _character_miniature_choices[index] if index < _character_miniature_choices.size() else {}
		if str(choice.get("title", "")) == preferred_title:
			selected_index = index + 1
	if selected_index > 0:
		miniature.text = str(_character_miniature_choices[selected_index - 1].get("title", "Published Miniature"))
	miniature.pressed.connect(_cycle_preferred_miniature.bind(miniature))
	body.add_child(_label("PREFERRED MINIATURE", "RookframeLabel"))
	body.add_child(miniature)
	_character_fields["miniature"] = miniature


func _build_review_stage() -> void:
	var body: VBoxContainer = _section("REVIEW", "Review the complete staged Character before the all-or-nothing durable create.")
	body.add_child(_label("%s · No Class" % str(_character_draft.get("name", "Unnamed Character")), "RookframeHeading"))
	var abilities: Dictionary = _character_draft.get("abilities", {})
	var ability_summary: Array[String] = []
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var ability: Dictionary = abilities.get(ability_name, {})
		ability_summary.append("%s %s (%s)" % [ability_name, str(ability.get("score", "—")), str(ability.get("modifier", "—"))])
	body.add_child(_label(_list_text(ability_summary, " · "), "RookframeMeta"))
	body.add_child(_label("HP %s · Silver %s · Omens %s · Pack %s" % [str(_character_draft.get("hit_points", "—")), str(_character_draft.get("silver", 0)), str(_character_draft.get("omens", 0)), str(_character_draft.get("pack", "Nothing"))], "RookframeValue"))
	body.add_child(_label("Origin & traits: none supplied by source", "RookframeMeta"))
	var starting_creature_ids: Array[String] = _character_draft.get("starting_creature_ids", [])
	body.add_child(_label("Starting Creature grants: %s" % ("none" if starting_creature_ids.is_empty() else _list_text(starting_creature_ids)), "RookframeMeta"))


func _inventory_names(items: Array) -> Array[String]:
	var names: Array[String] = []
	for item in items:
		var item_data: Dictionary = item
		var item_name: String = item_data.get("name", "Item")
		names.append(item_name)
	return names


func _list_text(items: Array[String], separator: String = ", ") -> String:
	if items.is_empty():
		return ""
	if items.size() == 1:
		return items[0]
	if items.size() == 2:
		return "%s%s%s" % [items[0], separator, items[1]]
	if items.size() == 3:
		return "%s%s%s%s%s" % [items[0], separator, items[1], separator, items[2]]
	return "%s%s%s%s%s%s%s" % [items[0], separator, items[1], separator, items[2], separator, items[3]]


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


func _set_status(message: String, error: bool = false) -> void:
	status_changed.emit(message, error)


func _set_busy(value: bool, message: String, error: bool = false) -> void:
	_busy = value
	busy_changed.emit(value)
	_set_status(message, error)


func _begin_character_creation() -> void:
	if _busy or sdk == null or _character_definition == null:
		return
	_discard_character_creation()
	_creation_generation += 1
	_creation_active = true
	_character_stage = "create-class"
	_character_tab = "character"
	_character_draft = {
		"class_id": "classless",
		"class_title": "No Class",
		"abilities": {},
		"equipment_rolls": {},
		"inventory": [],
		"pack": "Nothing",
		"silver": 0,
		"omens": 0,
		"origin": "",
		"traits": [],
		"name": "",
		"description": "",
		"preferred_miniature": {},
		"starting_creature_ids": [],
		"companion_sheets": [],
		"roll_pending": false,
		"equipment_roll_pending": false,
	}
	_show_creation_route("create-class")
	_set_status("Choose the source-backed No Class profile.")


func _start_over_character() -> void:
	_begin_character_creation()


func _discard_character_creation() -> void:
	if not _creation_active:
		return
	_creation_generation += 1
	_creation_active = false
	_character_draft = {}
	_character_stage = "create-class"


func _on_character_primary_action() -> void:
	if not _creation_active or _busy:
		return
	if _character_stage == "create-class":
		_character_stage = "create-abilities"
		_character_draft["roll_pending"] = true
		_show_creation_route(_character_stage)
		_roll_character_abilities(_creation_generation)
	elif _character_stage == "create-abilities":
		if bool(_character_draft.get("roll_pending", false)):
			_set_status("The source Rolls are still pending.")
			return
		_character_stage = "create-origin"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-origin":
		_character_stage = "create-equipment"
		_character_draft["equipment_roll_pending"] = true
		_show_creation_route(_character_stage)
		_roll_character_equipment(_creation_generation)
	elif _character_stage == "create-equipment":
		if bool(_character_draft.get("equipment_roll_pending", false)):
			_set_status("Starting equipment Rolls are still pending.")
			return
		_character_stage = "create-identity"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-identity":
		_sync_identity_fields()
		if str(_character_draft.get("name", "")).strip_edges().is_empty():
			_set_status("Enter a Character name before continuing.", true)
			return
		if _character_draft.get("preferred_miniature", {}).is_empty():
			_set_status("Choose a published Miniature before continuing.", true)
			return
		_character_stage = "create-review"
		_show_creation_route(_character_stage)
	elif _character_stage == "create-review":
		_sync_identity_fields()
		_commit_character()


func _roll_character_abilities(token: int) -> void:
	if not _creation_active or token != _creation_generation:
		return
	var abilities: Dictionary = {}
	for ability_name in ["Agility", "Presence", "Strength", "Toughness"]:
		var result: SDK.DiceRollResult = await _automatic_roll(ability_name, 6, 3, token)
		if token != _creation_generation or not _creation_active:
			return
		if not result.ok:
			_character_draft["roll_pending"] = false
			_show_creation_route("create-abilities")
			_set_status(result.message, true)
			return
		var score := _roll_total(result)
		abilities[ability_name] = {"score": score, "modifier": _modifier(score)}
	_character_draft["abilities"] = abilities
	var hit_points_result: SDK.DiceRollResult = await _automatic_roll("Hit points", 8, 1, token)
	if token != _creation_generation or not _creation_active:
		return
	if not hit_points_result.ok:
		_character_draft["roll_pending"] = false
		_show_creation_route("create-abilities")
		_set_status(hit_points_result.message, true)
		return
	_character_draft["hit_points"] = _roll_total(hit_points_result)
	_character_draft["maximum_hit_points"] = _character_draft["hit_points"]
	_character_draft["roll_pending"] = false
	_show_creation_route("create-abilities")
	_set_status("Automatic Rolls complete. Continue to Origin & Traits.")


func _roll_character_equipment(token: int) -> void:
	if not _creation_active or token != _creation_generation:
		return
	var terms := [["Silver", 6, 2], ["Omens", 2, 1], ["Food", 4, 1], ["Equipment pack", 6, 1], ["Weapon", 6, 1], ["Armor", 2, 1]]
	var totals: Dictionary = {}
	for term in terms:
		var result: SDK.DiceRollResult = await _automatic_roll(term[0], term[1], term[2], token)
		if token != _creation_generation or not _creation_active:
			return
		if not result.ok:
			_character_draft["equipment_roll_pending"] = false
			_show_creation_route("create-equipment")
			_set_status(result.message, true)
			return
		totals[term[0]] = _roll_total(result)
	_character_draft["equipment_rolls"] = totals
	_character_draft["silver"] = int(totals.get("Silver", 0)) * 10
	_character_draft["omens"] = int(totals.get("Omens", 0))
	_character_draft["inventory"] = [
		{"name": "Food", "quantity": int(totals.get("Food", 0))},
		{"name": "Weapon", "roll": int(totals.get("Weapon", 0))},
		{"name": "Armor", "roll": int(totals.get("Armor", 0))},
	]
	_character_draft["equipment_roll_pending"] = false
	_show_creation_route("create-equipment")
	_set_status("Starting equipment is ready. Choose a source-defined pack.")


func _automatic_roll(name: String, faces: int, count: int, token: int) -> SDK.DiceRollResult:
	_set_status("Rolling %s…" % name)
	await get_tree().process_frame
	if token != _creation_generation or not _creation_active:
		return SDK.DiceRollResult.new({"ok": false, "message": "Character creation was discarded."})
	return await sdk.dice.roll(SDK.DiceRequest.new([SDK.DiceTerm.new(name, faces, count)]))


func _roll_total(result: SDK.DiceRollResult) -> int:
	var total := 0
	for term in result.terms:
		for value in term.results:
			total += int(value)
	return total


func _modifier(score: int) -> int:
	if score <= 4:
		return -3
	if score <= 6:
		return -2
	if score <= 8:
		return -1
	if score <= 12:
		return 0
	if score <= 14:
		return 1
	if score <= 16:
		return 2
	return 3


func _sync_identity_fields() -> void:
	_character_draft["name"] = _character_name_field.get("value")
	_character_draft["description"] = _character_description_field.get("value")
	var miniature: Button = _character_fields.get("miniature") as Button
	if miniature != null:
		_set_preferred_miniature(_miniature_button_index(miniature), miniature)


func _cycle_pack(pack: Button, choices: Array) -> void:
	var index := 0
	for choice_index in range(choices.size()):
		if pack.text == "Pack: %s" % choices[choice_index]:
			index = choice_index + 1
	if index >= choices.size():
		index = 0
	pack.text = "Pack: %s" % choices[index]
	_character_draft["pack"] = choices[index]


func _cycle_preferred_miniature(miniature: Button) -> void:
	var index := _miniature_button_index(miniature) + 1
	if index > _character_miniatures.size():
		index = 0
	if index == 0:
		miniature.text = "Choose a published Miniature"
	else:
		miniature.text = str(_character_miniature_choices[index - 1].get("title", "Published Miniature"))
	_set_preferred_miniature(index, miniature)


func _miniature_button_index(miniature: Button) -> int:
	if miniature.text == "Choose a published Miniature":
		return 0
	for index in range(_character_miniatures.size()):
		if index < _character_miniature_choices.size() and miniature.text == str(_character_miniature_choices[index].get("title", "Published Miniature")):
			return index + 1
	return 0


func _set_preferred_miniature(index: int, miniature: Button) -> void:
	if index <= 0 or index - 1 >= _character_miniatures.size():
		_character_draft["preferred_miniature"] = {}
		return
	if index - 1 >= _character_miniature_choices.size():
		_character_draft["preferred_miniature"] = {}
		return
	_character_draft["preferred_miniature"] = _character_miniature_choices[index - 1].duplicate(true)


func _commit_character() -> void:
	if _busy or not _creation_active or sdk == null or _character_definition == null:
		return
	var choices: Dictionary = {
		"class_id": _character_draft.get("class_id", "classless"),
		"class_title": _character_draft.get("class_title", "No Class"),
		"abilities": _character_draft.get("abilities", {}),
		"inventory": _character_draft.get("inventory", []),
		"pack": _character_draft.get("pack", "Nothing"),
		"silver": _character_draft.get("silver", 0),
		"omens": _character_draft.get("omens", 0),
		"name": _character_draft.get("name", ""),
		"description": _character_draft.get("description", ""),
		"hit_points": _character_draft.get("hit_points", 1),
		"maximum_hit_points": _character_draft.get("maximum_hit_points", 1),
		"origin": _character_draft.get("origin", ""),
		"preferred_miniature": _character_draft.get("preferred_miniature", {}),
		"companion_sheets": _character_draft.get("companion_sheets", []),
		"starting_creature_ids": _character_draft.get("starting_creature_ids", []),
	}
	_set_busy(true, "Creating Character and source-defined starting grants…")
	var created_actors: Array[SDK.Actor] = []
	var result: SDK.ActorResult = await sdk.actors.create(_character_definition.reference, choices)
	if not result.ok or result.actor == null:
		_set_busy(false, result.message if not result.ok else "Character was not created.", true)
		return
	created_actors.append(result.actor)
	var durable_data: Dictionary = result.actor.data
	var starting_ids: Array = durable_data.get("starting_creature_ids", [])
	for creature_id in starting_ids:
		var creature_id_text: String = creature_id
		var creature_definition := _find_definition(creature_id_text)
		if creature_definition == null:
			await _rollback_created_actors(created_actors)
			_set_busy(false, "Starting Creature grant %s is unavailable; Character creation was rolled back." % creature_id_text, true)
			return
		var companion_result: SDK.ActorResult = await sdk.actors.create(creature_definition.reference, {})
		if not companion_result.ok or companion_result.actor == null:
			await _rollback_created_actors(created_actors)
			_set_busy(false, companion_result.message if not companion_result.ok else "Starting Creature grant failed; Character creation was rolled back.", true)
			return
		created_actors.append(companion_result.actor)
	_creation_active = false
	_character_draft = {}
	_set_busy(false, "Character created with ordinary Owner access.")
	character_created.emit(result.actor)


func _find_definition(local_id: String) -> SDK.ContentEntry:
	for entry in _definitions:
		if entry.reference.local_id == local_id:
			return entry
	return null


func _rollback_created_actors(created: Array[SDK.Actor]) -> void:
	for index in range(created.size() - 1, -1, -1):
		var cleanup: SDK.OperationResult = await sdk.actors.delete(created[index].id)
		if not cleanup.ok:
			_set_status("Rollback failed for a partial Actor: %s" % cleanup.message, true)
