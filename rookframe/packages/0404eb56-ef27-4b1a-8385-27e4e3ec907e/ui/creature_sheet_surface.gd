extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/creature_sheet_chrome.gd"
## Shared authored Full-viewport composition. Domain adapters own mutations/rolls.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const PROJECTION = preload(ROOT + "logic/creature_projection.gd")
const CONTENT = preload(ROOT + "logic/creature_content.gd")
const CARD = preload(ROOT + "ui/creature_rule_card.tscn")
const CARD_SCRIPT = preload(ROOT + "ui/creature_rule_card.gd")
const LOOT_ENTRY = preload(ROOT + "ui/creature_loot_entry.tscn")
const LOOT_ENTRY_SCRIPT = preload(ROOT + "ui/creature_loot_entry.gd")
const SECTION_HEADING = preload(ROOT + "ui/creature_section_heading.tscn")
const ART = preload(ROOT + "ui/creature_sheet_art.gd")
const APPEARANCE = preload(ROOT + "ui/creature_sheet_appearance.gd")
const OWN = preload(ROOT + "logic/creature_own_tests.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const CORRECTION_FORM = preload(ROOT + "ui/creature_correction_form.tscn")
const CORRECTION_FORM_SCRIPT = preload(ROOT + "ui/creature_correction_form.gd")
const CORRECTION_DETAILS = preload(ROOT + "ui/creature_correction_details.gd")
@export var correction_frame: StyleBoxFlat = StyleBoxFlat.new()
@export var footer_action_frame: StyleBoxFlat = StyleBoxFlat.new()
@export var canvas_frame: StyleBoxFlat
@export var identity_frame: StyleBoxFlat
@export var section_frame: StyleBoxFlat
@export var desktop_source_icon_alignment: HorizontalAlignment
@export var touch_source_icon_alignment: HorizontalAlignment
signal correction_changed(field: String, text: String)
signal chapter_changed(chapter: int)
signal entry_requested(id: String)
signal inventory_add_requested
signal reader_closed
signal close_requested
signal create_requested
signal correction_entry_requested(route: String)
signal save_requested
signal cancel_requested
signal edit_requested
signal miniature_requested
signal miniature_clear_requested
signal portrait_requested
signal portrait_reset_requested
signal publication_requested(url: String)
signal roll_requested(part: String, id: String)
signal health_requested
const WORK := "Inset/Layout/Body/Workspace/Chapter/Content/"
const IDENTITY := "Inset/Layout/Body/Identity/Column/"
const IDENTITY_PANEL := "Inset/Layout/Body/Identity"
const SECTION_BUTTON = preload(ROOT + "ui/creature_section_button.tscn")
var _data: Dictionary = {}
var _library := true
var _can_edit := false
var _chapter := 0
var _section := 0
var _reader := false
var _focus_card = null
var _focus_source := false
var _return_entry := ""
var _appearance_texture: Texture2D
var _texture: Texture2D
var _groups: Array[Dictionary] = []
var _layout_pending := false
var _pages: Dictionary = {}
var _encounter_keys: Dictionary = {}
var _reference_route := ""
var _reference_pending := false
var _reference_pages: Dictionary = {}
var _reference_values: Dictionary = {}
var _focus_identity := false
var _identity_overflow := false
var _pager_font_size := 0
var _draft: Dictionary = {}
var _editing := false
var _return_correction := ""
var _return_focus_frames := 0
var _roll_reader := false
var _return_roll := ""
var _correction_reader := false
var _correction_busy := false
var _inline_key: Array = []
var _correction_focus := ""
@onready var _correction_details: CORRECTION_DETAILS = get_node(WORK + "CorrectionSlot/Details")
var _correction_parent: Control

func _ready() -> void:
	_correction_parent = get_node(WORK + "CorrectionSlot")
	_correction_details.back_requested.connect(back)
	_correction_details.save_requested.connect(_save_corrections)
	_correction_details.cancel_requested.connect(_cancel_corrections)
	_correction_details.changed.connect(_correction_typed)
	get_node("CorrectionDialog").close_requested_by_user.connect(back)
	get_node("CorrectionDialog").escape_requested.connect(_cancel_corrections)
	for path in ["IdentityEditors", "HealthEditors/Inset/Fields", "ArmorEditors/Fields"]:
		var form: CORRECTION_FORM_SCRIPT = get_node(IDENTITY + path)
		form.changed.connect(_correction_typed)
	for path in ["Encounter/PrimarySlot/Primary", "Encounter/SecondarySlot/Secondary", "Inventory", "Reader/Pages"]:
		var pager: HBoxContainer = get_node(WORK + path + "/Pager")
		# Preserve the public component and its connected controls; only their
		# authored visual order changes to range, previous, next.
		for action in ["Previous", "Next"]:
			var button: Button = pager.get_node(action)
			pager.remove_child(button)
			pager.add_child(button)
	for index in range(3):
		get_node(NAV + ["Encounter", "Inventory", "Appearance"][index]).pressed.connect(show_chapter.bind(index))
	get_node(SOURCE).pressed.connect(show_source)
	get_node(WORK + "InventoryHeading/Row/Add").pressed.connect(_inventory_add)
	get_node(WORK + "Reader/Back").pressed.connect(back)
	get_node(WORK + "Reader/Publication").pressed.connect(_publication)
	get_node("Inset/Layout/Footer/Close").pressed.connect(_close)
	get_node("Inset/Layout/Footer/Create").pressed.connect(_create)
	get_node("Inset/Layout/Body/Workspace/Tabs/Edit").pressed.connect(_edit)
	get_node("Inset/Layout/Footer/Save").pressed.connect(_save_corrections)
	get_node("Inset/Layout/Footer/Core").pressed.connect(_core_corrections)
	get_node("Inset/Layout/Footer/Cancel").pressed.connect(_cancel_corrections)
	get_node(IDENTITY + "Health").pressed.connect(_health)
	get_node(IDENTITY + "Vitals/Armor").pressed.connect(_roll_armor)
	get_node(IDENTITY + "Vitals/Morale").pressed.connect(_roll_morale)
	get_node(IDENTITY + "MiniatureSummary").pressed.connect(show_chapter.bind(2))
	get_node(IDENTITY + "IdentityDetails").pressed.connect(show_identity)
	var appearance: APPEARANCE = get_node(WORK + "Appearance")
	appearance.miniature_requested.connect(_miniature)
	appearance.miniature_clear_requested.connect(_miniature_clear)
	appearance.portrait_requested.connect(_portrait)
	appearance.portrait_reset_requested.connect(_portrait_reset)
	resized.connect(_queue_layout)
	_queue_layout()

func configure(data: Dictionary, locale: I18N, library: bool = true, can_edit: bool = false, texture: Texture2D = null) -> void:
	_data = data.duplicate(true)
	_locale = locale
	_library = library
	_can_edit = can_edit
	_texture = texture if texture != null else default_portrait(str(data.get("definition_id", "")))
	_appearance_texture = texture if texture != null else ART.new().portrait(str(CONTENT.new().details(str(data.get("definition_id", ""))).get("portrait", "")), false)
	_queue_layout()

func default_portrait(definition: String) -> Texture2D:
	var id := str(CONTENT.new().details(definition).get("portrait", ""))
	return ART.new().portrait(id)

func _queue_layout() -> void:
	if _layout_pending or not is_node_ready():
		return
	_layout_pending = true

func _layout() -> void:
	_layout_pending = false
	_capture_encounter_pages()
	_phone = size.x <= 900
	_tablet = not _phone and size.x <= 1300
	_layout_frame()
	var name := str(_data.get("name", "Creature"))
	var metadata := CONTENT.new().details(str(_data.get("definition_id", "")))
	if _library and name.contains(","):
		name = name.split(",")[0]
	get_node(IDENTITY + "Name").text = _locale.text(str(_draft.get("name", name)) if _editing else name)
	get_node(IDENTITY + "Name").add_theme_font_size_override("font_size", 23 if _phone else 29 if _tablet else 40)
	var classification: String = _data.get("classification", metadata.get("classification", ""))
	if _editing:
		classification = str(_draft.get("classification", ""))
	get_node(IDENTITY + "Classification").text = _locale.text(classification)
	get_node(IDENTITY + "Classification").add_theme_font_size_override("font_size", 14 if _phone else 16 if _tablet else 20)
	_label_style(get_node(IDENTITY + "Name"), "Name")
	_label_style(get_node(IDENTITY + "Classification"), "Classification")
	get_node(IDENTITY + "Portrait").texture = _texture
	_layout_identity(metadata)
	_layout_chapters()
	get_node("Inset/Layout/Footer/Create").visible = _library
	get_node("Inset/Layout/Footer/Create").disabled = not _can_edit
	get_node("Inset/Layout/Footer/Create").text = _locale.text("Create Actor")
	get_node("Inset/Layout/Body/Workspace/Tabs/Edit").visible = not _library and _can_edit and not _editing
	get_node("Inset/Layout/Body/Workspace/Tabs/Edit").text = _locale.text("Edit sheet")
	get_node("Inset/Layout/Body/Workspace/Tabs/Edit").disabled = not bool(_data.get("corrections_available", false))
	for action in ["Save", "Cancel", "Core"]:
		get_node("Inset/Layout/Footer/" + action).visible = _editing
		get_node("Inset/Layout/Footer/" + action).disabled = not _can_edit
	get_node("Inset/Layout/Footer/Save").text = _locale.text("Save sheet")
	get_node("Inset/Layout/Footer/Cancel").text = _locale.text("Cancel")
	get_node("Inset/Layout/Footer/Core").text = _locale.text("Core values")
	get_node(WORK + "InventoryHeading/Row/Add").text = _locale.text("Add Item")
	get_node(WORK + "InventoryHeading/Row/Add").disabled = not _can_edit
	get_node("Inset/Layout/Footer/Close").text = _locale.text("Close")
	get_node(WORK + "Reader/Back").text = _locale.text("Back to creature")
	get_node(WORK + "Reader/Publication").text = _locale.text("Open publication")
	for action in ["Create", "Save", "Cancel", "Core"]:
		_chrome.icon_action(get_node("Inset/Layout/Footer/" + action), {"Create":"person-add", "Save":"check", "Cancel":"close", "Core":"edit"}[action], action in ["Create", "Save"])
	_chrome.icon_action(get_node(NAV + "Edit"), "edit")
	_chrome.icon_action(get_node(WORK + "InventoryHeading/Row/Add"), "add")
	_chrome.icon_action(get_node(WORK + "Reader/Back"), "back")
	get_node("Inset/Layout/Footer/Close").visible = false

	(get_node(WORK + "Appearance") as APPEARANCE).configure(_locale, _appearance_texture, _library, _can_edit, _phone, _tablet, get_node(IDENTITY + "Name").text)
	for button in ["ChangePortrait", "ClearPortrait"]:
		get_node(WORK + "Appearance/Columns/PortraitPanel/Inset/Content/PortraitButtons/" + button).disabled = not _data.get("portrait_editable", _can_edit)
	_build_groups(metadata)
	_configure_inline_core()
	_render_encounter()
	_render_inventory()
	correction_pending(_correction_busy)
	_update_visibility()
	_reference_pending = true

func _build_groups(metadata: Dictionary) -> void:
	var groups: Array[Dictionary] = []
	var attacks: Array = _data.get("attacks", [])
	var attack_entries: Array = []
	var own := OWN.new().presentation(_data)
	var own_attacks: Dictionary = own.attacks
	var own_defence: Dictionary = own.defence
	var defence_present := false
	for index in range(attacks.size()):
		var raw = attacks[index]
		var attack: Dictionary = raw
		var rules := _locale.text(str(attack.get("rules", "")))
		if str(_data.get("definition_id", "")) == "bone-bowyer" and attack.has("defence_dr"):
			rules += ("\n" if not rules.is_empty() else "") + _locale.text("Player defence DR%d.") % int(attack.defence_dr)
		attack_entries.append({"id": str(attack.get("id", "")), "name": str(attack.get("name", "Attack")), "text": rules, "dice": str(attack.get("dice", "")), "attack_dr": own_attacks.get(str(attack.get("id", ""))), "attack": true, "correction_route": "attack:%d" % index, "correction_identity": str(attack.get("correction_entry_id", "")) + "|" + str(attack.get("id", ""))})
	if not _editing and str(_data.get("definition_id", "")) == "seth-goblin" and own_attacks.is_empty() and _default_seth_attacks(attacks):
		var combined: Dictionary = attack_entries[0]
		combined["name"] = "Knife / shortbow"
		combined["text"] = _locale.text("Damage") + " d4."
		attack_entries = [combined]
	if attack_entries.is_empty():
		attack_entries.append({"id": "no-attacks", "name": "Attacks", "text": "No attacks recorded."})
	groups.append({"title": "Attacks", "lane": "primary", "entries": attack_entries})
	var armor: Dictionary = _data.get("armor", {})
	if armor.has("shield_reduction") or armor.has("defence_penalty"):
		var protection := _locale.text(str(armor.get("name", "Protection"))) + "\n" + _locale.text("Damage reduction") + ": " + ("—" if str(armor.get("reduction", "")).is_empty() else "−" + str(armor.reduction))
		if armor.has("shield_reduction"):
			protection += "\n" + _locale.text("Shield reduction") + ": −" + str(armor.shield_reduction)
		if armor.has("defence_penalty"):
			protection += "\n" + _locale.text("Defence penalty +%d") % int(armor.defence_penalty)
		groups.append({"title": "Protection", "lane": "secondary", "entries": [{"id": "protection", "name": "Protection", "text": protection}]})
	var authored: Array = _data.get("rule_groups", metadata.get("rule_groups", []) if _library else [])
	var rule_index := 0
	for raw in authored:
		var group: Dictionary = raw
		var copy: Dictionary = group.duplicate(true)
		var entries: Array = copy.get("entries", [])
		for raw_entry in entries:
			var entry: Dictionary = raw_entry
			entry["correction_route"] = "rule:%d" % rule_index
			entry["correction_identity"] = str(entry.get("correction_entry_id", "")) + "|" + str(entry.get("id", ""))
			rule_index += 1
			if str(entry.get("own_test", "")) == "defence" and not own_defence.is_empty():
				defence_present = true
				entry["own_dr"] = own_defence.difficulty
				# Refresh only these exact known authored defaults; custom prose stays intact.
				if str(entry.get("text", "")) in ["Unmodified d20 against DR10.", "Unmodified d20 against DR12."]:
					entry["text"] = _locale.text("Unmodified d20 against DR%d.") % int(own_defence.difficulty)
		groups.append(copy)
	if not own_defence.is_empty() and not defence_present:
		groups.append({"title": "Own tests", "lane": "primary", "entries": [{"id": own_defence.entry, "name": "Defence", "own_test": "defence", "own_dr": own_defence.difficulty, "text": _locale.text("Unmodified d20 against DR%d.") % int(own_defence.difficulty)}]})
	# Live corrections remain the sole accepted free rules text. Preserve unknown/custom rules.
	if authored.is_empty() and (not str(_data.get("rules", "")).is_empty() or _editing):
		groups.append({"title": "Special rules", "lane": "secondary", "entries": [{"id": "rules", "name": "Special rules", "text": str(_data.rules), "correction_route": "rules"}]})
	if not authored.is_empty() and not PROJECTION.new().rules_mirror(_data):
		groups.append({"title": "Additional rules", "lane": "secondary", "entries": [{"id": "rules", "name": "Additional rules", "text": str(_data.get("rules", "")), "correction_route": "rules"}]})
	var reference: Array = _data.get("reference", metadata.get("reference", []))
	if not reference.is_empty():
		groups.append({"title": "Reference", "lane": "secondary", "entries": reference})
	# Presentation aliases retain saved identities and distinct correction routes.
	var definition := str(_data.get("definition_id", ""))
	if definition == "lich-necromancer":
		var attack_group: Dictionary = groups[0]
		attack_group["title"] = "Attacks & powers"
		if not _editing and attack_entries.size() == 1:
			var strike: Dictionary = attack_entries[0]
			if strike.id == "strike" and strike.name == "Strike" and str(strike.text).is_empty():
				for group in groups:
					var entries: Array = group.entries
					var retained: Array = []
					for raw in entries:
						var entry: Dictionary = raw
						if entry.get("id", "") == "paralysis" and entry.get("name", "") == "Paralyzing touch" and entry.get("text", "") == "Touch paralyzes. Test Presence DR14 each round to break free.":
							strike.text = _locale.text(str(entry.text))
						else:
							retained.append(entry)
					group["entries"] = retained
	elif definition == "bone-bowyer":
		for group in groups:
			if group.title != "Reference":
				continue
			var entries: Array = group.entries
			var retained: Array = []
			for raw in entries:
				var entry: Dictionary = raw
				if entry.get("id", "") == "bow-reference":
					if entry.get("name", "") == "The Bowyer’s bow":
						entry.name = "Damage & retargeting"
					attack_entries.append(entry)
				else:
					if entry.get("id", "") == "commission" and entry.get("name", "") == "Unsavory services":
						entry.name = "Commission"
					retained.append(entry)
			group["entries"] = retained
	# Adjacent authored groups with the same semantic heading share one section.
	var merged: Array[Dictionary] = []
	for group in groups:
		var found := false
		for prior in merged:
			if prior.title == group.title and prior.get("lane", "primary") == group.get("lane", "primary"):
				var previous: Array = prior.entries
				var target: Array = previous.duplicate(true)
				var additions: Array = group.entries
				for entry in additions:
					target.append(entry)
				prior["entries"] = target
				found = true
				break
		if not found:
			merged.append(group)
	_groups = merged
	groups = merged
	_section = mini(_section, maxi(0, groups.size() - 1))
	var selector := get_node(WORK + "Section")
	_clear(selector)
	for index in range(_groups.size()):
		var button: Button = SECTION_BUTTON.instantiate()
		button.name = "Section" + str(index)
		selector.add_child(button)
		button.text = _locale.text(str(_groups[index].title))
		button.custom_minimum_size = Vector2(44, 44)
		button.add_theme_font_size_override("font_size", 16)
		button.add_theme_color_override("font_color", Color(0.905882,0.905882,0.866667,1))
		_style_chapter(button, true)
		button.toggle_mode = true
		button.set_pressed_no_signal(index == _section)
		button.pressed.connect(_section_selected.bind(index))

func _clear(content: Node) -> void:
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()

func _append(host: Node, entry: Dictionary, actions: Array = []) -> void:
	var card: CARD_SCRIPT = CARD.instantiate()
	host.add_child(card)
	card.configure(entry, _locale, _phone, _tablet, str(_data.get("definition_id", "")) == "bone-bowyer")
	card.configure_actions(actions, _locale, _phone)
	card.requested.connect(_requested.bind(card))

func _append_reference(host: Node, entry: Dictionary, compact_boss: bool = false) -> void:
	var card: CARD_SCRIPT = CARD.instantiate()
	host.add_child(card)
	card.configure(entry, _locale, _phone, _tablet, compact_boss)

func _append_heading(host: Node, title: String) -> void:
	var heading: PanelContainer = SECTION_HEADING.instantiate()
	host.add_child(heading)
	_configure_heading(heading, title)

func _configure_heading(heading: PanelContainer, title: String, padded_group: bool = false) -> void:
	heading.custom_minimum_size = Vector2(0,44)
	var frame: StyleBoxFlat = section_frame.duplicate()
	var row: HBoxContainer = heading.get_node("Row/Heading/Content" if padded_group else "Row")
	if padded_group:
		frame.border_width_bottom = 0
		frame.content_margin_top = 0
		frame.content_margin_bottom = 0
		var padding: MarginContainer = heading.get_node("Row/Heading")
		padding.add_theme_constant_override("margin_top", 6)
		padding.add_theme_constant_override("margin_bottom", 7)
		(heading.get_node("Row/Add") as Button).custom_minimum_size = Vector2(44,44)
	heading.add_theme_stylebox_override("panel", frame)
	row.add_theme_constant_override("separation", 12)
	var label: Label = row.get_node("Title")
	label.text = _locale.text(title)
	label.add_theme_font_size_override("font_size", 20 if _phone or _tablet else 24)
	var icon: TextureRect = row.get_node("Icon")
	var extent := 22 if _phone else 23 if _tablet else 26
	icon.custom_minimum_size = Vector2(extent, extent)
	icon.visible = true
	icon.texture = ART.new().heading_icon(title, str(_data.get("definition_id", "")))
	_label_style(label, "Section")

func _capture_encounter_pages() -> void:
	for lane in ["Primary", "Secondary"]:
		if not _encounter_keys.has(lane):
			continue
		if _phone and lane == "Secondary":
			continue
		var keys: Dictionary = _encounter_keys
		var page_key := str(keys.get(lane, ""))
		_pages[page_key] = get_node(WORK + "Encounter/" + lane + "Slot/" + lane).capture_state()

func _render_encounter() -> void:
	var inline_key: Array = []
	if _editing and not _phone and not _tablet:
		inline_key = [_draft.keys()]
		for group in _groups:
			inline_key.append(str(group.title))
			var entries: Array = group.entries
			for raw in entries:
				var entry: Dictionary = raw
				inline_key.append([entry.correction_route, entry.get("correction_identity", "rules")] if entry.has("correction_route") else entry)
		if inline_key == _inline_key:
			_sync_inline_fields()
			return
	_inline_key = inline_key.duplicate(true)
	for lane in ["Primary", "Secondary"]:
		var pages = get_node(WORK + "Encounter/" + lane + "Slot/" + lane)
		var page_key: String = "phone:" + str(_groups[_section].title) + ":" + str(_groups[_section].get("lane", "primary")) if _phone and not _groups.is_empty() else lane
		var state: Dictionary = _pages.get(page_key, {})
		_encounter_keys[lane] = page_key
		_clear(pages.get_node("Area/FocusInset/Content"))
		for index in range(_groups.size()):
			var group := _groups[index]
			if _phone and index != _section or not _phone and str(group.get("lane", "primary")) != lane.to_lower():
				continue
			if not _phone:
				if pages.get_node("Area/FocusInset/Content").get_child_count() > 0:
					var gap := Control.new()
					gap.custom_minimum_size = Vector2(gap.custom_minimum_size.x, 16 if _tablet else 24)
					pages.get_node("Area/FocusInset/Content").add_child(gap)
				_append_heading(pages.get_node("Area/FocusInset/Content"), str(group.title))
			var entries: Array = group.entries
			for raw in entries:
				var entry: Dictionary = raw
				if _editing and not _phone and not _tablet and entry.has("correction_route"):
					var frame := PanelContainer.new()
					frame.add_theme_stylebox_override("panel", correction_frame)
					pages.get_node("Area/FocusInset/Content").add_child(frame)
					var form: CORRECTION_FORM_SCRIPT = CORRECTION_FORM.instantiate()
					frame.add_child(form)
					form.configure(correction_keys(str(entry.correction_route)), _draft, _locale, false, str(entry.get("correction_identity", "rules")))
					form.changed.connect(_correction_typed)
					continue
				var actions: Array = []
				if _editing and entry.has("correction_route"):
					actions.append({"name": "Correct", "part": "correct:" + str(entry.correction_route), "disabled": not _can_edit})
				if entry.get("attack", false):
					if not _library and entry.get("attack_dr") != null:
						actions.append({"name": "Attack", "part": "attack", "dice": "d20 / DR" + str(entry.attack_dr), "disabled": _rolls_disabled()})
					actions.append({"name": "Damage", "part": "damage", "dice": str(entry.dice), "disabled": _rolls_disabled(), "reference": _library})
				if entry.has("own_test") and entry.has("own_dr"):
					actions.append({"name": "Defence", "part": str(entry.own_test), "dice": "d20 / DR" + str(entry.own_dr), "disabled": _rolls_disabled(), "reference": _library})
				var rolls: Array = entry.get("rolls", [])
				for raw_roll in rolls:
					var roll: Dictionary = raw_roll
					actions.append({"name": str(roll.name), "part": "printed:" + str(roll.id), "dice": str(roll.dice), "disabled": _rolls_disabled(), "reference": _library})
				if _editing and entry.has("correction_route"):
					entry = entry.duplicate(true)
					entry["id"] = str(entry.get("correction_identity", "rules"))
				_append(pages.get_node("Area/FocusInset/Content"), entry, actions)
				if _phone:
					var gap := Control.new()
					gap.name = "EntryPageGap" + str(pages.get_node("Area/FocusInset/Content").get_child_count())
					pages.get_node("Area/FocusInset/Content").add_child(gap)
		pages.restore_state(state)
	get_node(WORK + "Encounter/SecondarySlot").visible = not _phone

func _rolls_disabled() -> bool:
	return not _can_edit or not bool(_data.get("rolls_available", false)) or not HEALTH.new().can_roll(_data) or _data.get("editing", false) or _data.get("roll_pending", false)

func _render_inventory() -> void:
	var pages = get_node(WORK + "Inventory")
	var state: Dictionary = pages.capture_state()
	var content = pages.get_node("Area/Content")
	_clear(content)
	var items: Array = _data.get("inventory", [])
	if items.is_empty():
		_append_reference(content, {"name": "", "text": "No starting loot is authored for this creature." if _library else "No carried loot."}, str(_data.get("definition_id", "")) == "bone-bowyer")
	for raw in items:
		var item: Dictionary = raw
		var row = LOOT_ENTRY.instantiate()
		content.add_child(row)
		row.configure(item, _locale, _phone, _tablet)
		row.requested.connect(_requested.bind(row))
	if not pages.resized.is_connected(_inventory_page_size_changed):
		pages.resized.connect(_inventory_page_size_changed)
	_inventory_page_size_changed()
	pages.restore_state(state)

func _inventory_page_size_changed() -> void:
	var pages: Control = get_node(WORK + "Inventory")
	var pager: Control = get_node(WORK + "Inventory/Pager")
	var height := pages.size.y - pager.get_combined_minimum_size().y
	for child in get_node(WORK + "Inventory/Area/Content").get_children():
		var entry := child as LOOT_ENTRY_SCRIPT
		if entry != null:
			entry.set_page_height(height)

func _requested(part: String, id: String, opener: Control) -> void:
	if part.begins_with("correct:"):
		_return_correction = opener.entry_id
		_focus_card = opener
		correction_entry_requested.emit(part.trim_prefix("correct:"))
	elif part == "details":
		entry_requested.emit(id)
		if not _library:
			return
		var items: Array = _data.get("inventory", [])
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("inventory_id", "")) == id:
				show_entry(item, opener)
	else:
		_focus_card = opener
		roll_requested.emit(part, id)

func show_entry(entry: Dictionary, opener: Control = null) -> void:
	_capture_reference_page()
	_reference_route = ""
	_focus_identity = false
	_roll_reader = false
	_return_entry = str(entry.get("inventory_id", ""))
	_focus_card = opener
	_focus_source = false
	_reader = true
	var content = get_node(WORK + "Reader/Pages/Area/Content")
	_clear(content)
	_append_reference(content, {"name": str(entry.get("name", "Item")), "text": str(entry.get("rules", ""))})
	for key in ["kind", "quantity", "damage", "range_feet", "armor_tier", "reduction", "defence_penalty", "uses", "weight", "price", "source"]:
		if entry.has(key):
			_append_reference(content, {"name": key.replace("_", " ").capitalize(), "text": str(entry[key])})
	(get_node(WORK + "Reader/Publication") as Control).visible = false
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func _source() -> Dictionary:
	var metadata: Dictionary = CONTENT.new().details(str(_data.get("definition_id", "")))
	var source: Dictionary = _data.get("source", metadata.get("source", {}))
	return source

func show_source() -> void:
	_capture_reference_page()
	_reference_route = "source"
	_focus_identity = false
	_roll_reader = false
	_return_entry = ""
	_focus_card = null
	_focus_source = true
	_reader = true
	var content = get_node(WORK + "Reader/Pages/Area/Content")
	_clear(content)
	var source: Dictionary = _source()
	_append_reference(content, {"name": "Published source", "text": _locale.text("Published source is unavailable.") if source.is_empty() else str(source.get("title", "")) + "\n" + str(source.get("page", "")) + "\n" + str(source.get("author", ""))})
	_append_reference(content, {"name": "Attribution", "text": "MÖRK BORG is © Ockult Örtmästare Games & Stockholm Kartell. Mechanical facts are restated; study artwork is not official book art."})
	(get_node(WORK + "Reader/Publication") as Control).visible = not str(source.get("url", "")).is_empty()
	var page: Dictionary = _reference_pages.get("source", {})
	get_node(WORK + "Reader/Pages").restore_state(page)
	_reference_values = _source().duplicate(true)
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func back() -> void:
	_correction_reader = false
	_capture_reference_page()
	_reference_route = ""
	_reader = false
	_update_visibility()
	_return_focus_frames = 2
	reader_closed.emit()

func _restore_return_focus() -> void:
	if _focus_identity:
		_focus_identity = false
		var opener: Control = get_node(IDENTITY + "IdentityDetails")
		if opener.is_visible_in_tree():
			opener.grab_focus()
		else:
			get_node(NAV + ["Encounter", "Inventory", "Appearance"][_chapter]).grab_focus()
	elif _roll_reader:
		_roll_reader = false
		if _return_roll == "armor" or _return_roll == "morale":
			var opener: Button = get_node(IDENTITY + "Vitals/" + ("Armor" if _return_roll == "armor" else "Morale"))
			if opener.is_visible_in_tree() and not opener.disabled:
				opener.grab_focus()
			else:
				get_node(NAV + "Encounter").grab_focus()
		elif not focus_roll(_return_entry):
			get_node(NAV + "Encounter").grab_focus()
	elif _focus_source:
		get_node(SOURCE).grab_focus()
	elif _return_correction == "core" and get_node("Inset/Layout/Footer/Core").is_visible_in_tree():
		get_node("Inset/Layout/Footer/Core").grab_focus()
	elif is_instance_valid(_focus_card) and _focus_card.restore_focus():
		pass
	elif not _return_correction.is_empty() and focus_correction(_return_correction):
		pass
	elif not _return_entry.is_empty() and focus_entry(_return_entry):
		pass
	else:
		get_node(NAV + ["Encounter", "Inventory", "Appearance"][_chapter]).grab_focus()

func show_chapter(chapter: int) -> void:
	_correction_reader = false
	_capture_reference_page()
	_reference_route = ""
	_focus_identity = false
	_chapter = clampi(chapter, 0, 2)
	_reader = false
	_roll_reader = false
	_update_visibility()
	chapter_changed.emit(_chapter)

func _update_visibility() -> void:
	_set_chapter_frame(_phone and _correction_reader)
	_update_correction_host()
	var obscured := _reader and not (_correction_reader and not _phone)
	(get_node(IDENTITY_PANEL) as Control).visible = not (_phone and _correction_reader) and (_editing or _roll_reader and _reader or not (_phone and (_chapter == 2 or _reader)))
	get_node("Inset/Layout/Body/Workspace/Tabs").visible = not obscured
	get_node(WORK + "ChapterGap").visible = false
	get_node(WORK + "Section").visible = _phone and _chapter == 0 and not obscured
	get_node(WORK + "SectionRule").visible = _phone and _chapter == 0 and not obscured
	get_node(WORK + "InventoryHeading").visible = _chapter == 1 and not obscured
	get_node(WORK + "InventoryHeading/Row/Add").visible = _chapter == 1 and not obscured and not _library and _can_edit
	get_node(WORK + "Encounter").visible = _chapter == 0 and not obscured
	get_node(WORK + "Inventory").visible = _chapter == 1 and not obscured
	get_node(WORK + "Appearance").visible = _chapter == 2 and not obscured
	get_node(WORK + "Reader").visible = _reader and not _correction_reader
	for index in range(3):
		var button: Button = get_node(NAV + ["Encounter", "Inventory", "Appearance"][index])
		button.set_pressed_no_signal(index == _chapter)
		var label: Label = button.get_node("Center/Row/Title")
		label.theme_type_variation = "SilkCreatureTab" + ("Selected" if index == _chapter else "") + ("Phone" if _phone else "Tablet" if _tablet else "Desktop")
		label.add_theme_color_override("font_color", Color(0.082353,0.090196,0.098039,1) if index == _chapter else Color(0.682353,0.729412,0.745098,1))
		(button.get_node("Center/Row/Icon") as TextureRect).self_modulate = Color(0.082353,0.090196,0.098039,1) if index == _chapter else Color(0.815686,0.745098,0.556863,1)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel") and (_reader or _editing):
		if _editing:
			cancel_requested.emit()
		else:
			back()
		accept_event()

func status(message: String) -> void:
	get_node("Inset/Layout/Footer/Status").text = _locale.text(message)

func miniature(title: String, package: String, assigned: bool) -> void:
	get_node(IDENTITY + "MiniatureSummary/Row/Preview").visible = assigned
	get_node(IDENTITY + "MiniatureSummary/Row/Icon").visible = not assigned
	(get_node(WORK + "Appearance") as APPEARANCE).miniature(_locale, title, package, assigned)
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Value").text = title if assigned else _locale.text("Not assigned")
	get_node(IDENTITY + "MiniatureSummary").tooltip_text = title + (" · " + package if not package.is_empty() else "")

func miniature_summary_preview_target() -> Control:
	return get_node(IDENTITY + "MiniatureSummary/Row/Preview")

func miniature_preview_target() -> Control:
	return get_node(WORK + "Appearance/Columns/MiniaturePanel/Inset/Content/MiniaturePreview")

func _publication() -> void:
	var source: Dictionary = _source()
	publication_requested.emit(str(source.get("url", "")))
func _close() -> void:
	close_requested.emit()
func _create() -> void:
	create_requested.emit()
func _edit() -> void:
	edit_requested.emit()
func _health() -> void:
	health_requested.emit()
func _roll_armor() -> void:
	roll_requested.emit("armor", "")
func _roll_morale() -> void:
	roll_requested.emit("morale", "")
func _section_selected(index: int) -> void:
	_capture_encounter_pages()
	_section = index
	var child_index := 0
	for child in get_node(WORK + "Section").get_children():
		var button: Button = child
		button.set_pressed_no_signal(child_index == index)
		child_index += 1
	_render_encounter()
func _miniature() -> void:
	miniature_requested.emit()
func _miniature_clear() -> void:
	miniature_clear_requested.emit()
func _portrait() -> void:
	portrait_requested.emit()
func _portrait_reset() -> void:
	portrait_reset_requested.emit()

func _inventory_add() -> void:
	inventory_add_requested.emit()

## Local route state only; never Actor or World gameplay data.
func capture_navigation() -> Dictionary:
	_capture_encounter_pages()
	_capture_reference_page()
	var pages: Dictionary = {}
	for key in ["Encounter/PrimarySlot/Primary", "Encounter/SecondarySlot/Secondary", "Inventory", "Reader/Pages"]:
		pages[key] = get_node(WORK + key).capture_state()
	return {"chapter": _chapter, "section": _section, "pages": pages, "encounter_pages": _pages.duplicate(true), "reference_pages": _reference_pages.duplicate(true)}

func restore_navigation(state: Dictionary) -> void:
	var encounter_pages: Dictionary = state.get("encounter_pages", {})
	_pages = encounter_pages.duplicate(true)
	_encounter_keys = {}
	var reference_pages: Dictionary = state.get("reference_pages", {})
	_reference_pages = reference_pages.duplicate(true)
	_reference_route = ""
	_focus_identity = false
	_return_entry = ""
	_return_correction = ""
	_return_focus_frames = 0
	_chapter = clampi(int(state.get("chapter", 0)), 0, 2)
	_section = maxi(0, int(state.get("section", 0)))
	_reader = false
	var pages: Dictionary = state.get("pages", {})
	for key in ["Encounter/PrimarySlot/Primary", "Encounter/SecondarySlot/Secondary", "Inventory", "Reader/Pages"]:
		var value: Dictionary = pages.get(key, {})
		get_node(WORK + key).restore_state(value)
	_queue_layout()

func open_reader(title: String, return_entry: String = "", correction_route: String = "", focus_back: bool = true) -> void:
	_correction_reader = false
	_capture_reference_page()
	_reference_route = ""
	_focus_identity = false
	_roll_reader = false
	_focus_card = null
	_focus_source = false
	_return_entry = return_entry
	_return_correction = correction_route
	_reader = true
	_clear(reader_content())
	_append_reference(reader_content(), {"name": title, "text": ""})
	(get_node(WORK + "Reader/Publication") as Control).visible = false
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	if focus_back:
		get_node(WORK + "Reader/Back").grab_focus()

func focus_health() -> void:
	var opener: Button = get_node(IDENTITY + "Health")
	if opener.is_visible_in_tree() and not opener.disabled:
		opener.grab_focus()
	else:
		get_node("Inset/Layout/Footer/Close").grab_focus()

func open_roll_reader(title: String, part: String, entry: String) -> Dictionary:
	var continuing := _reader and _roll_reader and _return_roll == part and _return_entry == entry
	var page: Dictionary = reader_state() if continuing else {}
	open_reader(title, entry, "", not continuing)
	_roll_reader = true
	_return_roll = part
	_update_visibility()
	return page

func focus_roll(id: String) -> bool:
	for lane in ["Primary", "Secondary"]:
		for child in get_node(WORK + "Encounter/" + lane + "Slot/" + lane + "/Area/FocusInset/Content").get_children():
			var card := child as CARD_SCRIPT
			if card != null and card.entry_id == id and card.restore_focus(_return_roll):
				return true
	return false

func reader_content() -> Control:
	return get_node(WORK + "Reader/Pages/Area/Content") as Control

func reader_state() -> Dictionary:
	if _correction_reader:
		return _correction_details.paging()
	return get_node(WORK + "Reader/Pages").capture_state()

func restore_reader(state: Dictionary) -> void:
	if _correction_reader:
		_correction_details.restore_paging(state)
		return
	get_node(WORK + "Reader/Pages").restore_state(state)

func focus_entry(id: String) -> bool:
	for child in get_node(WORK + "Inventory/Area/Content").get_children():
		var entry := child as LOOT_ENTRY_SCRIPT
		if entry != null and entry.entry_id == id and entry.restore_focus():
			return true
	return false

func focus_miniature() -> void:
	get_node(WORK + "Appearance/Columns/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature").grab_focus()

func focus_portrait() -> void:
	get_node(WORK + "Appearance/Columns/PortraitPanel/Inset/Content/PortraitButtons/ChangePortrait").grab_focus()

## Local correction text stays separate from accepted Actor data.
func configure_draft(values: Dictionary, active: bool) -> void:
	var changed_mode := _editing != active
	_draft = values.duplicate(true)
	_editing = active
	if not active:
		_correction_reader = false
		get_node("CorrectionDialog").visible = false
	if changed_mode:
		_inline_key = []
	_queue_layout()

func sync_draft_field(key: String, text: String) -> void:
	_draft[key] = text
	for path in ["IdentityEditors", "HealthEditors/Inset/Fields", "ArmorEditors/Fields"]:
		var form: CORRECTION_FORM_SCRIPT = get_node(IDENTITY + path)
		form.sync_field(key, text)
	_correction_details.form.sync_field(key, text)
	if _phone or _tablet:
		_queue_layout()

func focus_correction(route: String) -> bool:
	for lane in ["Primary", "Secondary"]:
		for child in get_node(WORK + "Encounter/" + lane + "Slot/" + lane + "/Area/FocusInset/Content").get_children():
			var card := child as CARD_SCRIPT
			if card != null and card.entry_id == route and card.restore_focus():
				return true
			for authored in child.get_children():
				var form := authored as CORRECTION_FORM_SCRIPT
				if form != null and form.entry_id == route and form.restore_focus():
					return true
	return false

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	# Compose visible accepted state once per native frame. Hidden sheets wait
	# until shown instead of scheduling a full layout for each configuration.
	if _layout_pending:
		_layout()
	_fit_identity()
	# Refresh accepted reference text once after the coalesced layout has settled.
	if _reference_pending:
		_reference_pending = false
		_refresh_reference()
	_update_decorations()
	_fit_phone_entries()
	_update_pager_labels()
	if not _correction_focus.is_empty() and not _layout_pending:
		if _correction_focus == "first":
			if _correction_reader:
				_correction_details.focus_first()
			else:
				(get_node(IDENTITY + "IdentityEditors") as CORRECTION_FORM_SCRIPT).restore_focus()
		elif _correction_focus == "edit" and get_node("Inset/Layout/Body/Workspace/Tabs/Edit").is_visible_in_tree():
			get_node("Inset/Layout/Body/Workspace/Tabs/Edit").grab_focus()
		_correction_focus = ""
	if _return_focus_frames > 0:
		_return_focus_frames -= 1
		if _return_focus_frames == 0:
			_restore_return_focus()

func _save_corrections() -> void:
	save_requested.emit()

func _cancel_corrections() -> void:
	cancel_requested.emit()

func _core_corrections() -> void:
	correction_entry_requested.emit("core")

func correction_pending(pending: bool) -> void:
	_correction_busy = pending
	get_node("Inset/Layout/Body/Workspace/Tabs/Edit").disabled = pending or not bool(_data.get("corrections_available", false))
	_correction_details.set_details_pending(pending)
	for path in ["IdentityEditors", "HealthEditors/Inset/Fields", "ArmorEditors/Fields"]:
		var form: CORRECTION_FORM_SCRIPT = get_node(IDENTITY + path)
		form.set_fields_pending(pending)
	for lane in ["Primary", "Secondary"]:
		for panel in get_node(WORK + "Encounter/" + lane + "Slot/" + lane + "/Area/FocusInset/Content").get_children():
			for child in panel.get_children():
				var form := child as CORRECTION_FORM_SCRIPT
				if form != null:
					form.set_fields_pending(pending)
	for action in ["Core", "Cancel", "Save"]:
		get_node("Inset/Layout/Footer/" + action).disabled = pending

func _default_seth_attacks(attacks: Array) -> bool:
	if attacks.size() != 2:
		return false
	var expected: Array = preload(ROOT + "logic/creature_definition.gd").CORE_DEFINITIONS["seth-goblin"].attacks
	for index in range(attacks.size()):
		var stored: Dictionary = attacks[index]
		var attack: Dictionary = stored.duplicate(true)
		attack.erase("correction_entry_id")
		if str(attack.get("rules", "")).is_empty():
			attack.erase("rules")
		if attack != expected[index]:
			return false
	return true

func _layout_frame() -> void:
	var outer := 8 if _phone else 16 if _tablet else 32
	var left := 12 if _phone else 18 if _tablet else 32
	var right := 12 if _phone else 58 if _tablet else 80
	var top := 8 if _phone else 16 if _tablet else 24
	var bottom := 4 if _phone else 8 if _tablet else 12
	for path in ["Canvas", "Wash"]:
		var control: Control = get_node(path)
		control.offset_left = outer
		control.offset_top = outer + (6 if path == "Wash" else 0)
		control.offset_right = -outer
		control.offset_bottom = -outer - (6 if path == "Wash" else 0)
	get_node("Inset").add_theme_constant_override("margin_left", outer + left)
	get_node("Inset").add_theme_constant_override("margin_right", outer + right)
	get_node("Inset").add_theme_constant_override("margin_top", outer + 6 + top)
	get_node("Inset").add_theme_constant_override("margin_bottom", outer + 6 + bottom)
	get_node("Inset/Layout").add_theme_constant_override("separation", 4 if _phone else 12 if _tablet else 16)
	get_node("Inset/Layout/Body").add_theme_constant_override("separation", 16 if _phone else 18 if _tablet else 32)
	var width := size.x - 2 * outer - left - right
	var identity: Control = get_node(IDENTITY_PANEL)
	identity.custom_minimum_size = Vector2(218 if _phone else 264 if _tablet else width * 0.29, 0)
	var divider: StyleBoxFlat = identity_frame.duplicate()
	divider.content_margin_right = 13 if _phone else 15 if _tablet else 29
	identity.add_theme_stylebox_override("panel", divider)
	get_node("Inset/Layout/Body/Workspace").add_theme_constant_override("separation", 0)
	get_node(WORK + "Encounter").add_theme_constant_override("separation", 18 if _tablet else 28)
	get_node("Inset/Layout/Footer").custom_minimum_size = Vector2(0, 44 if _phone else 48 if _tablet else 56)
	get_node("Inset/Layout/Footer").add_theme_constant_override("separation", 8 if _phone or _tablet else 12)
	var source := _source()
	var citation := _locale.text(str(source.get("title", "")))
	var locator := str(source.get("page", ""))
	if locator.begins_with("p.") or locator.begins_with("pp."):
		citation += "  ·  " + _locale.text(locator)
	get_node("Inset/Layout/Footer/SourceNote/Citation").text = citation
	get_node("Inset/Layout/Footer/SourceNote/Citation").add_theme_font_size_override("font_size", 16)
	get_node("Inset/Layout/Footer/Status").add_theme_font_size_override("font_size", 14 if _phone else 15 if _tablet else 17)
	get_node("Ribbon").visible = not _phone
	get_node("Ribbon").position = Vector2(size.x - outer - (40 if _tablet else 60), outer)
	get_node("Ribbon").size = Vector2(20,68) if _tablet else Vector2(28,100)
	_configure_heading(get_node(WORK + "InventoryHeading"), "Inventory" if _library else "Carried loot", true)
	get_node(WORK + "ChapterGap").visible = false
	get_node(WORK + "Section").add_theme_constant_override("separation", 4)

func _layout_identity(metadata: Dictionary) -> void:
	get_node(IDENTITY + "NameGap").custom_minimum_size = Vector2(get_node(IDENTITY + "NameGap").custom_minimum_size.x, 2 if _phone else 4 if _tablet else 6)
	get_node(IDENTITY + "PortraitGap").custom_minimum_size = Vector2(get_node(IDENTITY + "PortraitGap").custom_minimum_size.x, 4 if _phone else 16 if _tablet else 20)
	get_node(IDENTITY + "HealthGap").custom_minimum_size = Vector2(get_node(IDENTITY + "HealthGap").custom_minimum_size.x, 4 if _phone else 8 if _tablet else 12)
	get_node(IDENTITY + "Portrait").custom_minimum_size = Vector2(get_node(IDENTITY + "Portrait").custom_minimum_size.x, 0)
	var hp: Button = get_node(IDENTITY + "Health")
	hp.custom_minimum_size = Vector2(hp.custom_minimum_size.x, 48 if _phone else 66 if _tablet else 76)
	hp.disabled = _library or not _can_edit or not bool(_data.get("health_available", false))
	var value := str(metadata.get("hit_points_formula", _data.get("hit_points", "—")) if _library else _draft.get("hit_points", _data.get("hit_points", "—")))
	var maximum := str(_draft.get("maximum_hit_points", _data.get("maximum_hit_points", "—")))
	hp.accessibility_name = _locale.text("Hit points") + " " + value + ("" if _library else " / " + maximum + ". " + _locale.text("Core values" if _editing else "Apply damage or Heal"))
	var row := (hp.get_node("Inset/Row") as HBoxContainer)
	row.add_theme_constant_override("separation", 4 if _phone else 8 if _tablet else 12)
	(row.get_node("Icon") as TextureRect).custom_minimum_size = Vector2(24,24) if _tablet else Vector2(28,28)
	(row.get_node("Icon") as TextureRect).visible = not _phone
	(row.get_node("Captions/Title") as Label).text = _locale.text("Hit points")
	(row.get_node("Captions/Subtitle") as Label).text = _locale.text("Published starting information" if _library else "Current / maximum")
	(row.get_node("Captions/Title") as Label).add_theme_font_size_override("font_size", 15 if _phone else 17 if _tablet else 20)
	(row.get_node("Captions/Subtitle") as Label).add_theme_font_size_override("font_size", 12 if _phone else 14 if _tablet else 16)
	(row.get_node("Value") as Label).text = value
	(row.get_node("Value") as Label).add_theme_font_size_override("font_size", 25 if _phone else 28 if _tablet else 34)
	(row.get_node("Maximum") as Label).text = "/ " + maximum
	(row.get_node("Maximum") as Label).visible = not _library
	(row.get_node("Maximum") as Label).add_theme_font_size_override("font_size", 14 if _phone else 16 if _tablet else 18)
	(row.get_node("Adjust") as Label).visible = not _library and _can_edit
	for edge in ["left", "right"]:
		(hp.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_" + edge, 7 if _phone else 9 if _tablet else 13)
	for edge in ["top", "bottom"]:
		(hp.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_" + edge, 5 if _phone else 9 if _tablet else 11)
	var health := HEALTH.new()
	var fraction := 1.0
	if not _library:
		fraction = 0.0
		var shown := health.integer(value)
		var shown_maximum := health.integer(maximum)
		if bool(shown.get("ok", false)) and bool(shown_maximum.get("ok", false)) and int(shown_maximum.get("value", 0)) > 0:
			fraction = clampf(float(shown.get("value", 0)) / float(shown_maximum.get("value", 1)), 0.0, 1.0)
	get_node(IDENTITY + "Health/Indicator").anchor_right = fraction
	get_node(IDENTITY + "Condition").visible = not _library and (health.is_dead(_data) or not health.valid(_data))
	get_node(IDENTITY + "Condition").text = _locale.text("Dead" if health.is_dead(_data) else "HP needs correction")
	get_node(IDENTITY + "Condition").add_theme_font_size_override("font_size", 12 if _phone else 18)
	var armor: Dictionary = _data.get("armor", {})
	var reduction := str(_draft.get("armor:reduction", armor.get("reduction", "")))
	var protection := "—" if reduction.is_empty() else "−" + reduction
	if int(armor.get("shield_reduction", 0)) > 0:
		protection += " · " + _locale.text("Shield") + " −" + str(armor.shield_reduction)
	if int(armor.get("defence_penalty", 0)) != 0:
		protection += " · " + _locale.text("Defence penalty +%d") % int(armor.defence_penalty)
	_layout_vital("Armor", _locale.text(str(_draft.get("armor:name", armor.get("name", "Protection")))), protection, preload("res://rookframe/ui/icons/character/armor.svg"), _library or _rolls_disabled() or reduction.is_empty())
	var morale: Dictionary = _data.get("morale", {})
	get_node(IDENTITY + "Vitals/Morale").visible = str(morale.get("kind", "")) != "none" and not morale.is_empty()
	_layout_vital("Morale", _locale.text("Morale"), str(_draft.get("morale", morale.get("value", 0))) if str(morale.get("kind", "")) == "fixed" else _locale.text("Special"), preload("res://rookframe/ui/icons/character/presence.svg"), _library or _rolls_disabled() or str(morale.get("kind", "")) != "fixed")
	get_node(IDENTITY + "Vitals").custom_minimum_size = Vector2(get_node(IDENTITY + "Vitals").custom_minimum_size.x, 63.3 if _phone else 97.5 if _tablet else 96.1)
	get_node(IDENTITY + "Vitals/Space").visible = false
	get_node(IDENTITY + "VitalsRule").visible = not _phone
	get_node(IDENTITY + "MiniatureSummary").visible = not _phone
	get_node(IDENTITY + "MiniatureSpace").visible = not _phone
	get_node(IDENTITY + "MiniatureSpace").custom_minimum_size = Vector2(0, 8 if _tablet else 24)
	get_node(IDENTITY + "MiniatureSummary").custom_minimum_size = Vector2(get_node(IDENTITY + "MiniatureSummary").custom_minimum_size.x, 63.5 if _tablet else 71)
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Caption").text = _locale.text("Tabletop miniature")
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Caption").add_theme_font_size_override("font_size", 14 if _tablet else 16)
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Value").add_theme_font_size_override("font_size", 17 if _tablet else 20)
	get_node(IDENTITY + "MiniatureSummary/Row/Action").text = _locale.text("Appearance") + " →"
	get_node(IDENTITY + "MiniatureSummary/Row/Action").add_theme_font_size_override("font_size", 14 if _tablet else 16)
	get_node(IDENTITY + "MiniatureSummary/Row").offset_left = 12
	get_node(IDENTITY + "MiniatureSummary/Row").offset_right = -12
	get_node(IDENTITY + "MiniatureSummary/Row").add_theme_constant_override("separation", 8 if _tablet else 12)
	get_node(IDENTITY + "MiniatureSummary/Row/Action").add_theme_color_override("font_color", Color(0.682353,0.729412,0.745098,1))
	_label_style(row.get_node("Captions/Title"), "HealthTitle")
	_label_style(row.get_node("Captions/Subtitle"), "HealthCaption")
	_label_style(row.get_node("Value"), "HealthValue")

func _layout_vital(key: String, caption: String, value: String, icon: Texture2D, disabled: bool) -> void:
	var button: Button = get_node(IDENTITY + "Vitals/" + key)
	button.disabled = disabled
	button.accessibility_name = caption + ": " + value
	(button.get_node("Row/Icon") as TextureRect).visible = not _phone
	(button.get_node("Row/Icon") as TextureRect).texture = icon
	(button.get_node("Row/Icon") as TextureRect).custom_minimum_size = Vector2(22, 22) if _tablet else Vector2(26, 26)
	(button.get_node("Row/Arrow") as Label).visible = not _library and not _phone
	(button.get_node("Row/Copy/Caption") as Label).text = caption + (" ↗" if _phone and not _library else "")
	(button.get_node("Row/Copy/Value") as Label).text = value
	(button.get_node("Row/Copy/Caption") as Label).add_theme_font_size_override("font_size", 14 if _phone else 15 if _tablet else 18)
	(button.get_node("Row/Copy/Value") as Label).add_theme_font_size_override("font_size", 21 if _phone else 23 if _tablet else 28)
	(button.get_node("Row") as HBoxContainer).add_theme_constant_override("separation", 4 if _phone else 6 if _tablet else 12)
	var row: HBoxContainer = button.get_node("Row")
	row.offset_left = 12
	row.offset_right = -12
	row.offset_top = 10 if _phone else 16 if _tablet else 20
	row.offset_bottom = -10 if _phone else -16 if _tablet else -20
	(button.get_node("Row/Copy") as Control).size_flags_horizontal = 3 if _phone or _tablet else 0
	(button.get_node("Row/Copy/Caption") as Label).autowrap_mode = 3 if _phone or _tablet else 0
	_label_style(button.get_node("Row/Copy/Caption"), "VitalCaption")
	_label_style(button.get_node("Row/Copy/Value"), "VitalValue")
	(button.get_node("Row/Arrow") as Label).add_theme_font_size_override("font_size", 14 if _phone else 18)
	(button.get_node("Row/Arrow") as Label).add_theme_color_override("font_color", Color(0.682353,0.729412,0.745098,1))
	button.size_flags_horizontal = 3
	button.custom_minimum_size = Vector2(44, button.custom_minimum_size.y)

func _update_decorations() -> void:
	var footer: Control = get_node("Inset/Layout/Footer")
	var sheet_rect: Rect2 = get_global_rect()
	var footer_rect: Rect2 = footer.get_global_rect()
	get_node("FooterRule").visible = footer.is_visible_in_tree()
	get_node("FooterRule").position = Vector2(footer_rect.position.x - sheet_rect.position.x, footer_rect.position.y - sheet_rect.position.y)
	get_node("FooterRule").size = Vector2(footer.size.x, 1)
	var tabs: Control = get_node("Inset/Layout/Body/Workspace/Tabs")
	var tabs_rect: Rect2 = tabs.get_global_rect()
	get_node("ChapterRule").visible = false
	get_node("ChapterRule").position = Vector2(tabs_rect.position.x - sheet_rect.position.x, tabs_rect.position.y - sheet_rect.position.y + tabs.size.y - 1)
	get_node("ChapterRule").size = Vector2(tabs.size.x, 1)

func _update_pager_labels() -> void:
	var font_size := 14 if _phone else 17
	var refresh_font := _pager_font_size != font_size
	_pager_font_size = font_size
	for path in ["Encounter/PrimarySlot/Primary", "Encounter/SecondarySlot/Secondary", "Inventory", "Reader/Pages"]:
		get_node(WORK + path + "/PagerRule").visible = get_node(WORK + path + "/Pager").visible
		var label: Label = get_node(WORK + path + "/Pager/Range")
		if refresh_font:
			label.add_theme_font_size_override("font_size", font_size)
		var pager: HBoxContainer = get_node(WORK + path + "/Pager")
		pager.custom_minimum_size = Vector2(0,46)
		pager.offset_top = -46
		pager.add_theme_constant_override("separation", 4 if _phone else 8)
		for action in ["Previous", "Next"]:
			var button: Button = pager.get_node(action)
			_chrome.icon_action(button, "chevron-left" if action == "Previous" else "chevron-right")
		var state := label.text.split(" · ")[-1]
		var context := _locale.text(str(_groups[_section].title)) if path == "Encounter/PrimarySlot/Primary" and _phone and not _groups.is_empty() else _locale.text("Inventory") if path == "Inventory" else _locale.text("Reference") if path == "Reader/Pages" else _locale.text("Creature chapter: Encounter")
		label.text = context + " · " + state if _phone else state

func _fit_phone_entries() -> void:
	if not _phone or _chapter != 0 or _reader:
		return
	var pages: Control = get_node(WORK + "Encounter/PrimarySlot/Primary")
	var height := pages.size.y - 46
	if height <= 0:
		return
	var content: VBoxContainer = get_node(WORK + "Encounter/PrimarySlot/Primary/Area/FocusInset/Content")
	var article_height := 0.0
	var has_article := false
	for node in content.get_children():
		var child: Control = node
		if not str(child.name).begins_with("EntryPageGap"):
			article_height = child.get_combined_minimum_size().y
			has_article = true
			continue
		if not has_article:
			continue
		# Small complete articles each own a bounded phone page. Long prose keeps
		# the public component's measured line paging; no text is dropped.
		var gap := maxf(0, height - article_height) if article_height <= height else 0.0
		# The final spacer also ensures the public pager reserves its 44px row.
		var difference := child.custom_minimum_size.y - gap
		if difference > 0.1 or difference < -0.1:
			child.custom_minimum_size = Vector2(child.custom_minimum_size.x, gap)

## Keep the approved portrait/core usable. Only overflowing identity uses the
## Character-style full-text reader; accepted strings are never shortened.
func _fit_identity() -> void:
	if _editing and not _phone and not _tablet:
		_fit_inline_core()
		return
	if not get_node(IDENTITY_PANEL).is_visible_in_tree():
		return
	var column: Control = get_node(IDENTITY)
	if column.size.x < 1:
		return
	var title: Label = get_node(IDENTITY + "Name")
	var classification: Label = get_node(IDENTITY + "Classification")
	# Hidden labels still measure the complete text at the settled native width.
	title.size = Vector2(column.size.x, title.size.y)
	classification.size = Vector2(column.size.x, classification.size.y)
	# Shape hidden full text after a width/font change before reading its minimum.
	title.get_line_count()
	classification.get_line_count()
	var portrait: Control = get_node(IDENTITY + "Portrait")
	var opener: Button = get_node(IDENTITY + "IdentityDetails")
	var available: float = size.y - (88 if _phone else 128 if _tablet else 184)
	var other_height := 0.0
	for child in column.get_children():
		if child is Control:
			var control: Control = child
			if control.visible and str(control.name) not in ["Name", "Classification", "Portrait", "IdentityDetails", "NameGap"]:
				other_height += ceili(control.get_combined_minimum_size().y)
	var portrait_height := 60.0 if _phone else 160.0
	var name_gap := 2 if _phone else 4 if _tablet else 6
	var full_height := title.get_combined_minimum_size().y + classification.get_combined_minimum_size().y + name_gap
	_identity_overflow = other_height + portrait_height + full_height > available + 1
	title.visible = not _identity_overflow
	classification.visible = not _identity_overflow
	get_node(IDENTITY + "NameGap").visible = not _identity_overflow
	opener.visible = _identity_overflow
	get_node(IDENTITY + "IdentityDetails/Copy/Name").text = title.text
	get_node(IDENTITY + "IdentityDetails/Copy/Name").add_theme_font_size_override("font_size", 23 if _phone else 29 if _tablet else 40)
	get_node(IDENTITY + "IdentityDetails/Copy/Caption").text = _locale.text("Full identity") + " ›"
	get_node(IDENTITY + "IdentityDetails/Copy/Caption").add_theme_font_size_override("font_size", 14 if _phone else 16 if _tablet else 20)
	opener.accessibility_name = title.text + ". " + classification.text + ". " + _locale.text("Full identity")
	opener.custom_minimum_size = Vector2(0, maxf(44, get_node(IDENTITY + "IdentityDetails/Copy").get_combined_minimum_size().y))
	var identity_height := opener.custom_minimum_size.y if _identity_overflow else full_height
	var target := int(maxf(0, available - other_height - identity_height))
	var difference := target - portrait.custom_minimum_size.y
	if difference > 0.1 or difference < -0.1:
		portrait.custom_minimum_size = Vector2(0, target)

func _capture_reference_page() -> void:
	if not _reference_route.is_empty() and _reader:
		var state := reader_state()
		if int(state.get("page", 0)) > 0 or _reference_pages.has(_reference_route):
			_reference_pages[_reference_route] = state

func _identity_values() -> Dictionary:
	return {"name": str(get_node(IDENTITY + "Name").text), "classification": str(get_node(IDENTITY + "Classification").text)}

func show_identity() -> void:
	_capture_reference_page()
	open_reader("Full identity")
	_reference_route = "identity"
	_focus_identity = true
	_reference_values = _identity_values()
	_append_reference(reader_content(), {"name": "Name", "text": _reference_values.name})
	_append_reference(reader_content(), {"name": "Classification", "text": _reference_values.classification if not str(_reference_values.classification).is_empty() else _locale.text("Not recorded")})
	var page: Dictionary = _reference_pages.get("identity", {})
	restore_reader(page)

func _refresh_reference() -> void:
	if not _reader or _reference_route.is_empty():
		return
	var values := _identity_values() if _reference_route == "identity" else _source()
	if values == _reference_values:
		return
	# Only changed accepted reference text rebuilds this bounded article.
	# The native pager remains the same Control and keeps keyboard focus.
	var focused: Control = null
	for path in ["Back", "Pages/Pager/Previous", "Pages/Pager/Next", "Publication"]:
		var candidate: Control = get_node(WORK + "Reader/" + path)
		if candidate.has_focus():
			focused = candidate
	if _reference_route == "identity":
		show_identity()
	else:
		show_source()
	if focused != null and is_instance_valid(focused) and focused.is_visible_in_tree():
		focused.grab_focus()

func _correction_typed(field: String, text: String) -> void:
	correction_changed.emit(field, text)

func correction_keys(route: String) -> Array:
	var keys: Array = []
	var printed := PROJECTION.new().printed_routes(_data)
	for key in _draft.keys():
		var field := str(key)
		if route == "core":
			if not field.begins_with("attack:") and not field.begins_with("rule:") and not field.begins_with("printed:") and field != "rules":
				keys.append(field)
		elif field == route or field.begins_with(route + ":") or str(printed.get(field, "")) == route:
			keys.append(field)
	# The approved entry order is Name, complete prose, then supported mechanics.
	var ordered: Array = []
	if route != "core":
		for member in ["name", "rules", "text"]:
			var key: String = route + ":" + str(member)
			if keys.has(key):
				ordered.append(key)
	for key in keys:
		if not ordered.has(key):
			ordered.append(key)
	return ordered

func _configure_inline_core() -> void:
	var inline := _editing and not _phone and not _tablet
	for path in ["IdentityEditors", "HealthEditors", "ArmorEditors"]:
		get_node(IDENTITY + path).visible = inline
	get_node(IDENTITY + "Health").visible = not inline
	get_node(IDENTITY + "Vitals").visible = not inline
	if not inline:
		return
	for path in ["Name", "NameGap", "Classification", "IdentityDetails"]:
		get_node(IDENTITY + path).visible = false
	(get_node(IDENTITY + "IdentityEditors") as CORRECTION_FORM_SCRIPT).configure(["name", "classification"], _draft, _locale, false)
	(get_node(IDENTITY + "HealthEditors/Inset/Fields") as CORRECTION_FORM_SCRIPT).configure(["hit_points", "maximum_hit_points"], _draft, _locale, false)
	var armor_keys: Array = []
	for key in ["armor:reduction", "armor:name", "morale", "armor:shield_reduction", "armor:defence_penalty"]:
		if _draft.has(key):
			armor_keys.append(key)
	(get_node(IDENTITY + "ArmorEditors/Fields") as CORRECTION_FORM_SCRIPT).configure(armor_keys, _draft, _locale, false)

func _sync_inline_fields() -> void:
	for lane in ["Primary", "Secondary"]:
		for panel in get_node(WORK + "Encounter/" + lane + "Slot/" + lane + "/Area/FocusInset/Content").get_children():
			for child in panel.get_children():
				var form := child as CORRECTION_FORM_SCRIPT
				if form != null:
					for key in _draft.keys():
						form.sync_field(str(key), str(_draft.get(str(key), "")))

func _fit_inline_core() -> void:
	var column: Control = get_node(IDENTITY)
	var other_height := 0.0
	for child in column.get_children():
		var control: Control = child
		if control.visible and str(control.name) != "Portrait":
			other_height += ceili(control.get_combined_minimum_size().y)
	var available: float = size.y - (88 if _phone else 128 if _tablet else 184)
	var portrait: Control = get_node(IDENTITY + "Portrait")
	var height := minf(510, maxf(0, available - other_height))
	var difference := portrait.custom_minimum_size.y - height
	if difference > 0.1 or difference < -0.1:
		portrait.custom_minimum_size = Vector2(0, height)

func begin_corrections() -> void:
	_return_focus_frames = 0
	if size.x > 1300:
		_correction_focus = "first"
	else:
		correction_entry_requested.emit("core")

func open_correction(title: String, route: String, identity: String, available: bool) -> void:
	var opening := not _correction_reader
	_correction_reader = true
	_reader = true
	_reference_route = ""
	_roll_reader = false
	_return_correction = identity
	_focus_card = null
	_focus_source = false
	_focus_identity = false
	_correction_details.configure(correction_keys(route) if available else [], _draft, _locale, _phone, identity, title)
	_update_visibility()
	if opening:
		_correction_focus = "first"

func show_correction_error(field: String, message: String) -> void:
	_correction_details.show_error(field, message)

func _update_correction_host() -> void:
	var phone_host: Control = get_node(WORK + "CorrectionSlot")
	var target: Control = phone_host if _phone else get_node("CorrectionDialog/Surface/Inset")
	if target != _correction_parent:
		_correction_parent.remove_child(_correction_details)
		target.add_child(_correction_details)
		_correction_parent = target
	_correction_details.configure_density(_phone)
	_correction_details.visible = _correction_reader
	phone_host.visible = _correction_reader and _phone
	get_node("CorrectionScrim").visible = _correction_reader and not _phone
	get_node("CorrectionDialog").present(_correction_reader and not _phone and is_visible_in_tree(), size)
	get_node("Inset/Layout/Footer").visible = not (_correction_reader and _phone)

func finish_corrections() -> void:
	_correction_reader = false
	_return_focus_frames = 0
	_correction_focus = "edit"
	_update_visibility()

func _label_style(label: Label, role: String) -> void:
	label.theme_type_variation = "SilkCreature" + role + ("Phone" if _phone else "Tablet" if _tablet else "Desktop")
