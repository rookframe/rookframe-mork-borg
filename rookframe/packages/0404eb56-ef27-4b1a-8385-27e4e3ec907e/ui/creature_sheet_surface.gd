extends Control
## Shared authored Full-viewport composition. Domain adapters own mutations/rolls.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const PROJECTION = preload(ROOT + "logic/creature_projection.gd")
const CONTENT = preload(ROOT + "logic/creature_content.gd")
const CARD = preload(ROOT + "ui/creature_rule_card.tscn")
const CARD_SCRIPT = preload(ROOT + "ui/creature_rule_card.gd")
const LOOT_ENTRY = preload(ROOT + "ui/creature_loot_entry.tscn")
const LOOT_ENTRY_SCRIPT = preload(ROOT + "ui/creature_loot_entry.gd")
const SECTION_HEADING = preload(ROOT + "ui/creature_section_heading.tscn")
const I18N = preload(ROOT + "ui/localization.gd")
const APPEARANCE = preload(ROOT + "ui/creature_sheet_appearance.gd")
const OWN = preload(ROOT + "logic/creature_own_tests.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const HEALTH_EDITOR = preload(ROOT + "ui/creature_health_editor.tscn")
const HEALTH_EDITOR_SCRIPT = preload(ROOT + "ui/creature_health_editor.gd")
@export var canvas_frame: StyleBoxFlat
@export var identity_frame: StyleBoxFlat
@export var section_frame: StyleBoxFlat
@export var chapter_normal: StyleBoxFlat
@export var chapter_selected: StyleBoxFlat
@export var desktop_source_icon_alignment: HorizontalAlignment
@export var touch_source_icon_alignment: HorizontalAlignment
@export var source_frame: StyleBoxFlat
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
const WORK := "Inset/Layout/Body/Workspace/"
const IDENTITY := "Inset/Layout/Body/Identity/Column/"
const IDENTITY_PANEL := "Inset/Layout/Body/Identity"
const SECTION_BUTTON = preload(ROOT + "ui/creature_section_button.tscn")
var _data: Dictionary = {}
var _locale: I18N = I18N.new()
var _library := true
var _can_edit := false
var _phone := false
var _tablet := false
var _chapter := 0
var _section := 0
var _reader := false
var _focus_card = null
var _focus_source := false
var _return_entry := ""
var _texture: Texture2D
var _groups: Array[Dictionary] = []
var _layout_pending := false
var _pages: Dictionary = {}
var _encounter_keys: Dictionary = {}
var _reference_route := ""
var _reference_pages: Dictionary = {}
var _reference_values: Dictionary = {}
var _focus_identity := false
var _identity_overflow := false
var _pager_font_size := 0
var _draft: Dictionary = {}
var _editing := false
var _return_correction := ""
var _return_focus_frames := 0
var _health_reader := false
var _roll_reader := false
var _return_roll := ""

func _ready() -> void:
	for path in ["Encounter/Primary", "Encounter/Secondary", "Inventory", "Reader/Pages"]:
		var pager: HBoxContainer = get_node(WORK + path + "/Pager")
		# Preserve the public component and its connected controls; only their
		# authored visual order changes to range, previous, next.
		for action in ["Previous", "Next"]:
			var button: Button = pager.get_node(action)
			pager.remove_child(button)
			pager.add_child(button)
	for index in range(3):
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][index]).pressed.connect(show_chapter.bind(index))
	get_node(WORK + "Tabs/Source").pressed.connect(show_source)
	get_node(WORK + "InventoryHeading/Row/Add").pressed.connect(_inventory_add)
	get_node(WORK + "Reader/Back").pressed.connect(back)
	get_node(WORK + "Reader/Publication").pressed.connect(_publication)
	get_node("Inset/Layout/Footer/Close").pressed.connect(_close)
	get_node("Inset/Layout/Footer/Create").pressed.connect(_create)
	get_node("Inset/Layout/Footer/Edit").pressed.connect(_edit)
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
	_queue_layout()

func default_portrait(definition: String) -> Texture2D:
	var id := str(CONTENT.new().details(definition).get("portrait", ""))
	# Authored AtlasTexture frames exclude transparent margins without cropping the subject.
	var portraits := {"seth-goblin": preload(ROOT + "ui/portraits/seth-goblin-framed.tres"), "lich": preload(ROOT + "ui/portraits/lich-framed.tres"), "bone-bowyer": preload(ROOT + "ui/portraits/bone-bowyer-framed.tres")}
	return portraits.get(id, preload("res://rookframe/ui/icons/character/character.svg"))

func _queue_layout() -> void:
	if _layout_pending or not is_node_ready():
		return
	_layout_pending = true
	_layout.call_deferred()

func _layout() -> void:
	_layout_pending = false
	_capture_encounter_pages()
	_phone = size.x <= 900
	_tablet = not _phone and size.x <= 1400
	_layout_frame()
	var name := str(_data.get("name", "Creature"))
	var metadata := CONTENT.new().details(str(_data.get("definition_id", "")))
	if _library and name.contains(","):
		name = name.split(",")[0]
	get_node(IDENTITY + "Name").text = _locale.text(str(_draft.get("name", name)) if _editing else name)
	get_node(IDENTITY + "Name").add_theme_font_size_override("font_size", 22 if _phone else 29 if _tablet else 34)
	var classification: String = _data.get("classification", metadata.get("classification", ""))
	if _editing:
		classification = str(_draft.get("classification", ""))
	get_node(IDENTITY + "Classification").text = _locale.text(classification)
	get_node(IDENTITY + "Classification").add_theme_font_size_override("font_size", 9 if _phone else 11 if _tablet else 13)
	get_node(IDENTITY + "Portrait").texture = _texture
	_layout_identity(metadata)
	_layout_chapters()
	get_node("Inset/Layout/Footer/Create").visible = _library
	get_node("Inset/Layout/Footer/Create").disabled = not _can_edit
	get_node("Inset/Layout/Footer/Create").text = _locale.text("Create Actor")
	get_node("Inset/Layout/Footer/Edit").visible = not _library and _can_edit and not _editing
	get_node("Inset/Layout/Footer/Edit").text = _locale.text("Edit sheet")
	get_node("Inset/Layout/Footer/Edit").disabled = not bool(_data.get("corrections_available", false))
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
	(get_node(WORK + "Appearance") as APPEARANCE).configure(_locale, _texture, _library, _can_edit, _phone, _tablet, get_node(IDENTITY + "Name").text)
	for button in ["ChangePortrait", "ClearPortrait"]:
		get_node(WORK + "Appearance/Columns/PortraitPanel/Inset/Content/PortraitButtons/" + button).disabled = not _data.get("portrait_editable", _can_edit)
	_build_groups(metadata)
	_render_encounter()
	_render_inventory()
	_update_visibility()
	_refresh_reference()

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
		button.add_theme_font_size_override("font_size", 11)
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
	card.configure(entry, _locale, _phone, _tablet)
	card.configure_actions(actions, _locale, _phone)
	card.requested.connect(_requested.bind(card))

func _append_reference(host: Node, entry: Dictionary) -> void:
	var card: CARD_SCRIPT = CARD.instantiate()
	host.add_child(card)
	card.configure(entry, _locale, _phone, _tablet)

func _append_heading(host: Node, title: String) -> void:
	var heading: PanelContainer = SECTION_HEADING.instantiate()
	host.add_child(heading)
	_configure_heading(heading, title)

func _configure_heading(heading: PanelContainer, title: String) -> void:
	heading.custom_minimum_size = Vector2(heading.custom_minimum_size.x, 38 if _tablet else 44)
	var frame: StyleBoxFlat = section_frame.duplicate()
	frame.content_margin_left = 6 if _phone or _tablet else 12
	frame.content_margin_right = frame.content_margin_left
	frame.content_margin_top = 6 if _phone or _tablet else 8
	frame.content_margin_bottom = frame.content_margin_top
	heading.add_theme_stylebox_override("panel", frame)
	(heading.get_node("Row") as Control).add_theme_constant_override("separation", 6 if _phone or _tablet else 10)
	var label: Label = heading.get_node("Row/Title")
	label.text = _locale.text(title)
	label.add_theme_font_size_override("font_size", 13 if _phone or _tablet else 17)
	var icon: TextureRect = heading.get_node("Row/Icon")
	icon.custom_minimum_size = Vector2(20, 20) if _tablet else Vector2(24, 24)
	icon.visible = not _phone
	var icons := {"Attacks": preload("res://rookframe/ui/icons/character/sword.svg"), "Attacks & powers": preload("res://rookframe/ui/icons/character/sword.svg"), "Defence": preload("res://rookframe/ui/icons/character/shield.svg"), "Protection": preload("res://rookframe/ui/icons/character/shield.svg"), "Own tests": preload("res://rookframe/ui/icons/character/shield.svg"), "Inventory": preload("res://rookframe/ui/icons/character/bag.svg"), "Carried loot": preload("res://rookframe/ui/icons/character/bag.svg")}
	icon.texture = icons.get(title, preload("res://rookframe/ui/icons/character/quill.svg"))

func _capture_encounter_pages() -> void:
	for lane in ["Primary", "Secondary"]:
		if not _encounter_keys.has(lane):
			continue
		if _phone and lane == "Secondary":
			continue
		var keys: Dictionary = _encounter_keys
		var page_key := str(keys.get(lane, ""))
		_pages[page_key] = get_node(WORK + "Encounter/" + lane).capture_state()

func _render_encounter() -> void:
	for lane in ["Primary", "Secondary"]:
		var pages = get_node(WORK + "Encounter/" + lane)
		var page_key: String = "phone:" + str(_groups[_section].title) + ":" + str(_groups[_section].get("lane", "primary")) if _phone and not _groups.is_empty() else lane
		var state: Dictionary = _pages.get(page_key, {})
		_encounter_keys[lane] = page_key
		_clear(pages.get_node("Area/Content"))
		for index in range(_groups.size()):
			var group := _groups[index]
			if _phone and index != _section or not _phone and str(group.get("lane", "primary")) != lane.to_lower():
				continue
			if not _phone:
				if pages.get_node("Area/Content").get_child_count() > 0:
					var gap := Control.new()
					gap.custom_minimum_size = Vector2(gap.custom_minimum_size.x, 16 if _tablet else 22)
					pages.get_node("Area/Content").add_child(gap)
				_append_heading(pages.get_node("Area/Content"), str(group.title))
			var entries: Array = group.entries
			for raw in entries:
				var entry: Dictionary = raw
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
				_append(pages.get_node("Area/Content"), entry, actions)
				if _phone:
					var gap := Control.new()
					gap.name = "EntryPageGap" + str(pages.get_node("Area/Content").get_child_count())
					pages.get_node("Area/Content").add_child(gap)
		pages.restore_state(state)
	get_node(WORK + "Encounter/Secondary").visible = not _phone

func _rolls_disabled() -> bool:
	return not _can_edit or not bool(_data.get("rolls_available", false)) or not HEALTH.new().can_roll(_data) or _data.get("editing", false) or _data.get("roll_pending", false)

func _render_inventory() -> void:
	var pages = get_node(WORK + "Inventory")
	var state: Dictionary = pages.capture_state()
	var content = pages.get_node("Area/Content")
	_clear(content)
	var items: Array = _data.get("inventory", [])
	if items.is_empty():
		_append_reference(content, {"name": "", "text": "No starting loot is authored for this creature." if _library else "No carried loot."})
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
	_health_reader = false
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
	_health_reader = false
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
	get_node(WORK + "Reader/Pages").restore_state(_reference_pages.get("source", {}))
	_reference_values = _source().duplicate(true)
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func back() -> void:
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
			get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][_chapter]).grab_focus()
	elif _roll_reader:
		_roll_reader = false
		if _return_roll == "armor" or _return_roll == "morale":
			get_node(IDENTITY + "Vitals/" + ("Armor" if _return_roll == "armor" else "Morale")).grab_focus()
		elif not focus_roll(_return_entry):
			get_node(WORK + "Tabs/Encounter").grab_focus()
	elif _health_reader:
		get_node(IDENTITY + "Health").grab_focus()
		_health_reader = false
	elif _focus_source:
		get_node(WORK + "Tabs/Source").grab_focus()
	elif _return_correction == "core" and get_node("Inset/Layout/Footer/Core").is_visible_in_tree():
		get_node("Inset/Layout/Footer/Core").grab_focus()
	elif is_instance_valid(_focus_card) and _focus_card.restore_focus():
		pass
	elif not _return_correction.is_empty() and focus_correction(_return_correction):
		pass
	elif not _return_entry.is_empty() and focus_entry(_return_entry):
		pass
	else:
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][_chapter]).grab_focus()

func show_chapter(chapter: int) -> void:
	_capture_reference_page()
	_reference_route = ""
	_focus_identity = false
	_chapter = clampi(chapter, 0, 2)
	_reader = false
	_health_reader = false
	_roll_reader = false
	_update_visibility()
	chapter_changed.emit(_chapter)

func _update_visibility() -> void:
	(get_node(IDENTITY_PANEL) as Control).visible = _editing or (_health_reader or _roll_reader) and _reader or not (_phone and (_chapter == 2 or _reader))
	get_node(WORK + "Tabs").visible = not _reader
	get_node(WORK + "ChapterGap").visible = not _reader
	get_node(WORK + "Section").visible = _phone and _chapter == 0 and not _reader
	get_node(WORK + "InventoryHeading").visible = _chapter == 1 and not _reader
	get_node(WORK + "InventoryHeading/Row/Add").visible = _chapter == 1 and not _reader and not _library and _can_edit
	get_node(WORK + "Encounter").visible = _chapter == 0 and not _reader
	get_node(WORK + "Inventory").visible = _chapter == 1 and not _reader
	get_node(WORK + "Appearance").visible = _chapter == 2 and not _reader
	get_node(WORK + "Reader").visible = _reader
	for index in range(3):
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][index]).set_pressed_no_signal(index == _chapter)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel") and (_reader or _editing):
		if _editing:
			cancel_requested.emit()
		else:
			back()
		accept_event()

func status(message: String) -> void:
	get_node("Inset/Layout/Footer/Status").text = _locale.text(message)
	get_node("Inset/Layout/Footer/Context").visible = message.is_empty()
	get_node("Inset/Layout/Footer/ContextIcon").visible = message.is_empty()

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
	for key in ["Encounter/Primary", "Encounter/Secondary", "Inventory", "Reader/Pages"]:
		pages[key] = get_node(WORK + key).capture_state()
	return {"chapter": _chapter, "section": _section, "pages": pages, "encounter_pages": _pages.duplicate(true), "reference_pages": _reference_pages.duplicate(true)}

func restore_navigation(state: Dictionary) -> void:
	_pages = state.get("encounter_pages", {}).duplicate(true)
	_encounter_keys = {}
	_reference_pages = state.get("reference_pages", {}).duplicate(true)
	_reference_route = ""
	_focus_identity = false
	_return_entry = ""
	_return_correction = ""
	_return_focus_frames = 0
	_chapter = clampi(int(state.get("chapter", 0)), 0, 2)
	_section = maxi(0, int(state.get("section", 0)))
	_reader = false
	var pages: Dictionary = state.get("pages", {})
	for key in ["Encounter/Primary", "Encounter/Secondary", "Inventory", "Reader/Pages"]:
		var value: Dictionary = pages.get(key, {})
		get_node(WORK + key).restore_state(value)
	_queue_layout()

func open_reader(title: String, return_entry: String = "", correction_route: String = "") -> void:
	_capture_reference_page()
	_reference_route = ""
	_focus_identity = false
	_health_reader = false
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
	get_node(WORK + "Reader/Back").grab_focus()

func open_health_reader() -> HEALTH_EDITOR_SCRIPT:
	open_reader("Hit points")
	_health_reader = true
	var editor: HEALTH_EDITOR_SCRIPT = HEALTH_EDITOR.instantiate()
	get_node(WORK + "Reader/Pages/Area/Content").add_child(editor)
	_update_visibility()
	return editor

func open_roll_reader(title: String, part: String, entry: String) -> void:
	open_reader(title, entry)
	_roll_reader = true
	_return_roll = part
	_update_visibility()

func focus_roll(id: String) -> bool:
	for lane in ["Primary", "Secondary"]:
		for child in get_node(WORK + "Encounter/" + lane + "/Area/Content").get_children():
			var card := child as CARD_SCRIPT
			if card != null and card.entry_id == id and card.restore_focus(_return_roll):
				return true
	return false

func reader_content() -> Control:
	return get_node(WORK + "Reader/Pages/Area/Content") as Control

func reader_state() -> Dictionary:
	return get_node(WORK + "Reader/Pages").capture_state()

func restore_reader(state: Dictionary) -> void:
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
	_draft = values.duplicate(true)
	_editing = active
	_queue_layout()

func sync_draft_field(key: String, text: String) -> void:
	_draft[key] = text
	_queue_layout()

func focus_correction(route: String) -> bool:
	for lane in ["Primary", "Secondary"]:
		for child in get_node(WORK + "Encounter/" + lane + "/Area/Content").get_children():
			var card := child as CARD_SCRIPT
			if card != null and card.entry_id == route and card.restore_focus():
				return true
	return false

func _process(_delta: float) -> void:
	if not is_visible_in_tree():
		return
	_fit_identity()
	_update_decorations()
	_fit_phone_entries()
	_update_pager_labels()
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
	var border := 3 if _phone else 1
	var horizontal := 10 if _phone else 18 if _tablet else 32
	get_node("Inset").add_theme_constant_override("margin_left", horizontal + border)
	get_node("Inset").add_theme_constant_override("margin_right", horizontal + border)
	get_node("Inset").add_theme_constant_override("margin_top", (8 if _phone else 16 if _tablet else 24) + border)
	get_node("Inset").add_theme_constant_override("margin_bottom", border)
	get_node("Inset/Layout").add_theme_constant_override("separation", 6 if _phone else 12 if _tablet else 20)
	get_node("Inset/Layout/Body").add_theme_constant_override("separation", 14 if _phone else 20 if _tablet else 32)
	var frame: StyleBoxFlat = canvas_frame.duplicate()
	frame.set_border_width_all(border)
	get_node("Canvas").add_theme_stylebox_override("panel", frame)
	var identity: Control = get_node(IDENTITY_PANEL)
	identity.custom_minimum_size = Vector2(202 if _phone else 340 if _tablet else int((size.x - 98) / 3.0), identity.custom_minimum_size.y)
	var divider: StyleBoxFlat = identity_frame.duplicate()
	divider.content_margin_right = 13 if _phone else 19 if _tablet else 29
	identity.add_theme_stylebox_override("panel", divider)
	(get_node(WORK) as Control).add_theme_constant_override("separation", 0)
	get_node(WORK + "Encounter").add_theme_constant_override("separation", 18 if _tablet else 28)
	get_node("Inset/Layout/Footer").custom_minimum_size = Vector2(get_node("Inset/Layout/Footer").custom_minimum_size.x, 44)
	get_node("Inset/Layout/Footer/Brand").visible = not _phone
	get_node("Inset/Layout/Footer/BrandIcon").visible = not _phone
	get_node("Inset/Layout/Footer/BrandGap").visible = not _phone
	get_node("Inset/Layout/Footer").add_theme_constant_override("separation", 6 if _phone else 10)
	get_node("Inset/Layout/Footer/Context").text = _locale.text("Published starting information" if _library else "Resolve consequences at the table.")
	get_node("Inset/Layout/Footer/Context").add_theme_font_size_override("font_size", 10 if _phone else 12)
	for action in ["Close", "Edit", "Create"]:
		var button: Button = get_node("Inset/Layout/Footer/" + action)
		button.add_theme_font_size_override("font_size", 10 if _phone else 11)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_color_override("font_color", Color(0.603922, 0.647059, 0.65098, 1))
	var heading: PanelContainer = get_node(WORK + "InventoryHeading")
	_configure_heading(heading, "Inventory" if _library else "Carried loot")
	# The fixed workspace gap belongs after the chapter rail, not every child.
	get_node(WORK + "ChapterGap").custom_minimum_size = Vector2(get_node(WORK + "ChapterGap").custom_minimum_size.x, 0 if _phone else 14 if _tablet else 18)

func _layout_identity(metadata: Dictionary) -> void:
	get_node(IDENTITY + "NameGap").custom_minimum_size = Vector2(get_node(IDENTITY + "NameGap").custom_minimum_size.x, 3 if _phone else 6 if _tablet else 7)
	get_node(IDENTITY + "PortraitGap").custom_minimum_size = Vector2(get_node(IDENTITY + "PortraitGap").custom_minimum_size.x, 3 if _phone else 15 if _tablet else 23)
	get_node(IDENTITY + "HealthGap").custom_minimum_size = Vector2(get_node(IDENTITY + "HealthGap").custom_minimum_size.x, 4 if _phone else 10 if _tablet else 14)
	get_node(IDENTITY + "Portrait").custom_minimum_size = Vector2(get_node(IDENTITY + "Portrait").custom_minimum_size.x, 148 if _phone else 430 if _tablet else 510)
	var hp: Button = get_node(IDENTITY + "Health")
	hp.custom_minimum_size = Vector2(hp.custom_minimum_size.x, 48 if _phone else 60 if _tablet else 66)
	hp.disabled = _library or not _can_edit or not bool(_data.get("health_available", false))
	var value := str(metadata.get("hit_points_formula", _data.get("hit_points", "—")) if _library else _draft.get("hit_points", _data.get("hit_points", "—")))
	var maximum := str(_draft.get("maximum_hit_points", _data.get("maximum_hit_points", "—")))
	hp.accessibility_name = _locale.text("Hit points") + " " + value + ("" if _library else " / " + maximum + ". " + _locale.text("Core values" if _editing else "Apply damage or Heal"))
	var row := (hp.get_node("Inset/Row") as HBoxContainer)
	row.add_theme_constant_override("separation", 4 if _phone else 10)
	(row.get_node("Icon") as TextureRect).visible = not _phone
	(row.get_node("Captions/Title") as Label).text = _locale.text("Hit points")
	(row.get_node("Captions/Subtitle") as Label).text = _locale.text("Published starting information" if _library else "Current / maximum")
	(row.get_node("Captions/Title") as Label).add_theme_font_size_override("font_size", 10 if _phone else 12 if _tablet else 13)
	(row.get_node("Captions/Subtitle") as Label).add_theme_font_size_override("font_size", 8 if _phone else 10)
	(row.get_node("Value") as Label).text = value
	(row.get_node("Value") as Label).add_theme_font_size_override("font_size", 24 if _phone else 28 if _tablet else 30)
	(row.get_node("Maximum") as Label).text = "/ " + maximum
	(row.get_node("Maximum") as Label).visible = not _library
	(row.get_node("Maximum") as Label).add_theme_font_size_override("font_size", 10 if _phone else 13)
	(row.get_node("Adjust") as Label).visible = not _library and _can_edit
	for edge in ["left", "right"]:
		(hp.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_" + edge, 7 if _phone else 12)
	for edge in ["top", "bottom"]:
		(hp.get_node("Inset") as MarginContainer).add_theme_constant_override("margin_" + edge, 4 if _phone else 8)
	var health := HEALTH.new()
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
	get_node(IDENTITY + "Vitals").custom_minimum_size = Vector2(get_node(IDENTITY + "Vitals").custom_minimum_size.x, 52 if _phone else 65 if _tablet else 73.5)
	get_node(IDENTITY + "Vitals/Space").visible = not _phone
	get_node(IDENTITY + "VitalsRule").visible = not _phone
	get_node(IDENTITY + "MiniatureSummary").visible = not _phone
	get_node(IDENTITY + "MiniatureSummary").custom_minimum_size = Vector2(get_node(IDENTITY + "MiniatureSummary").custom_minimum_size.x, 54 if _tablet else 56)
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Caption").text = _locale.text("Tabletop miniature")
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Caption").add_theme_font_size_override("font_size", 10 if _tablet else 11)
	get_node(IDENTITY + "MiniatureSummary/Row/Copy/Value").add_theme_font_size_override("font_size", 12 if _tablet else 14)
	get_node(IDENTITY + "MiniatureSummary/Row/Action").text = _locale.text("Appearance") + " →"
	get_node(IDENTITY + "MiniatureSummary/Row/Action").add_theme_font_size_override("font_size", 10 if _tablet else 12)

func _layout_vital(key: String, caption: String, value: String, icon: Texture2D, disabled: bool) -> void:
	var button: Button = get_node(IDENTITY + "Vitals/" + key)
	button.disabled = disabled
	button.accessibility_name = caption + ": " + value
	(button.get_node("Row/Icon") as TextureRect).visible = not _phone
	(button.get_node("Row/Icon") as TextureRect).texture = icon
	(button.get_node("Row/Icon") as TextureRect).custom_minimum_size = Vector2(20, 20) if _tablet else Vector2(22, 22)
	(button.get_node("Row/Arrow") as Label).visible = not _library
	(button.get_node("Row/Copy/Caption") as Label).text = caption
	(button.get_node("Row/Copy/Value") as Label).text = value
	(button.get_node("Row/Copy/Caption") as Label).add_theme_font_size_override("font_size", 9 if _phone else 10 if _tablet else 12)
	(button.get_node("Row/Copy/Value") as Label).add_theme_font_size_override("font_size", 16 if _phone else 21 if _tablet else 24)
	(button.get_node("Row") as HBoxContainer).add_theme_constant_override("separation", 3 if _phone else 5 if _tablet else 8)
	button.size_flags_horizontal = 3 if _phone else 1
	button.custom_minimum_size = Vector2(44 if _phone else (button.get_node("Row") as HBoxContainer).get_combined_minimum_size().x, button.custom_minimum_size.y)

func _style_chapter(button: Button, section: bool = false) -> void:
	button.clip_text = false
	var normal: StyleBoxFlat = chapter_normal.duplicate()
	var selected: StyleBoxFlat = chapter_selected.duplicate()
	for style in [normal, selected]:
		style.content_margin_left = 3 if section else 8 if _phone or _tablet else 16
		style.content_margin_right = style.content_margin_left
		style.content_margin_top = 3 if _phone else 5 if _tablet else 6
		style.content_margin_bottom = style.content_margin_top
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("pressed", selected)
	button.add_theme_color_override("font_pressed_color", Color(0.266667, 0.913725, 0.913725, 1))

func _layout_chapters() -> void:
	for title in ["Encounter", "Inventory", "Appearance"]:
		var button: Button = get_node(WORK + "Tabs/" + title)
		button.text = _locale.text(title)
		button.custom_minimum_size = Vector2(44, 40 if _phone else 44 if _tablet else 52)
		button.add_theme_font_size_override("font_size", 13 if _phone else 14 if _tablet else 17)
		_style_chapter(button)
	var appearance: Button = get_node(WORK + "Tabs/Appearance")
	appearance.icon = preload("res://rookframe/ui/icons/character/character.svg")
	appearance.add_theme_constant_override("h_separation", 8)
	appearance.add_theme_constant_override("icon_max_width", 18 if _phone else 20 if _tablet else 24)
	appearance.add_theme_color_override("icon_normal_color", Color(0.266667, 0.913725, 0.913725, 1))
	appearance.add_theme_color_override("icon_pressed_color", Color(0.266667, 0.913725, 0.913725, 1))
	var source: Button = get_node(WORK + "Tabs/Source")
	source.text = "" if _phone or _tablet else _locale.text("Source")
	source.icon_alignment = touch_source_icon_alignment if _phone or _tablet else desktop_source_icon_alignment
	var frame: StyleBoxFlat = source_frame.duplicate()
	frame.content_margin_bottom = 8 if _phone or _tablet else 6
	source.add_theme_stylebox_override("normal", frame)
	source.icon = preload("res://rookframe/ui/icons/character/book.svg")
	source.accessibility_name = _locale.text("Published source")
	source.tooltip_text = _locale.text("Published source")
	source.custom_minimum_size = Vector2(44, 40 if _phone else 44 if _tablet else 52)
	source.add_theme_constant_override("h_separation", 8)
	source.add_theme_constant_override("icon_max_width", 20)
	source.add_theme_color_override("icon_normal_color", Color(0.266667, 0.913725, 0.913725, 1))
	source.add_theme_font_size_override("font_size", 12)

func _update_decorations() -> void:
	var footer: Control = get_node("Inset/Layout/Footer")
	var sheet_rect: Rect2 = get_global_rect()
	var footer_rect: Rect2 = footer.get_global_rect()
	get_node("FooterRule").position = Vector2(footer_rect.position.x - sheet_rect.position.x, footer_rect.position.y - sheet_rect.position.y)
	get_node("FooterRule").size = Vector2(footer.size.x, 1)
	var tabs: Control = get_node(WORK + "Tabs")
	var tabs_rect: Rect2 = tabs.get_global_rect()
	get_node("ChapterRule").visible = tabs.is_visible_in_tree()
	get_node("ChapterRule").position = Vector2(tabs_rect.position.x - sheet_rect.position.x, tabs_rect.position.y - sheet_rect.position.y + tabs.size.y - 1)
	get_node("ChapterRule").size = Vector2(tabs.size.x, 1)

func _update_pager_labels() -> void:
	var font_size := 10 if _phone else 12
	var refresh_font := _pager_font_size != font_size
	_pager_font_size = font_size
	for path in ["Encounter/Primary", "Encounter/Secondary", "Inventory", "Reader/Pages"]:
		get_node(WORK + path + "/PagerRule").visible = get_node(WORK + path + "/Pager").visible
		var label: Label = get_node(WORK + path + "/Pager/Range")
		if refresh_font:
			label.add_theme_font_size_override("font_size", font_size)
		var state := label.text.split(" · ")[-1]
		var context := _locale.text(str(_groups[_section].title)) if path == "Encounter/Primary" and _phone and not _groups.is_empty() else _locale.text("Inventory") if path == "Inventory" else _locale.text("Reference") if path == "Reader/Pages" else _locale.text("Encounter")
		label.text = context + " · " + state

func _fit_phone_entries() -> void:
	if not _phone or _chapter != 0 or _reader:
		return
	var pages: Control = get_node(WORK + "Encounter/Primary")
	var height := pages.size.y - 44
	if height <= 0:
		return
	var content: VBoxContainer = get_node(WORK + "Encounter/Primary/Area/Content")
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
	if not get_node(IDENTITY_PANEL).is_visible_in_tree():
		return
	var column: Control = get_node(IDENTITY)
	if column.size.x < 1:
		return
	var title: Label = get_node(IDENTITY + "Name")
	var classification: Label = get_node(IDENTITY + "Classification")
	# Hidden labels still measure the complete text at the settled native width.
	title.size.x = column.size.x
	classification.size.x = column.size.x
	var portrait: Control = get_node(IDENTITY + "Portrait")
	var opener: Button = get_node(IDENTITY + "IdentityDetails")
	var available := size.y - (11 if _phone else 17 if _tablet else 25) - (53 if _phone else 57 if _tablet else 65)
	var other_height := 0.0
	for child in column.get_children():
		if child is Control and child.visible and child not in [title, classification, portrait, opener, get_node(IDENTITY + "NameGap")]:
			other_height += child.get_combined_minimum_size().y
	var portrait_height := 148.0 if _phone else 430.0 if _tablet else 510.0
	var name_gap := 3 if _phone else 6 if _tablet else 7
	var full_height := title.get_combined_minimum_size().y + classification.get_combined_minimum_size().y + name_gap
	_identity_overflow = other_height + portrait_height + full_height > available + 1
	title.visible = not _identity_overflow
	classification.visible = not _identity_overflow
	get_node(IDENTITY + "NameGap").visible = not _identity_overflow
	opener.visible = _identity_overflow
	get_node(IDENTITY + "IdentityDetails/Copy/Name").text = title.text
	get_node(IDENTITY + "IdentityDetails/Copy/Name").add_theme_font_size_override("font_size", 22 if _phone else 29 if _tablet else 34)
	get_node(IDENTITY + "IdentityDetails/Copy/Caption").text = _locale.text("Full identity") + " ›"
	get_node(IDENTITY + "IdentityDetails/Copy/Caption").add_theme_font_size_override("font_size", 9 if _phone else 11 if _tablet else 13)
	opener.accessibility_name = title.text + ". " + classification.text + ". " + _locale.text("Full identity")
	opener.custom_minimum_size.y = maxf(44, get_node(IDENTITY + "IdentityDetails/Copy").get_combined_minimum_size().y)
	var identity_height := opener.custom_minimum_size.y if _identity_overflow else full_height
	var target := minf(portrait_height, maxf(0, available - other_height - identity_height))
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
	restore_reader(_reference_pages.get("identity", {}))

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
