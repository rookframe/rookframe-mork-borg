extends Control
## Shared authored Full-viewport composition. Domain adapters own mutations/rolls.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const CONTENT = preload(ROOT + "logic/creature_content.gd")
const CARD = preload(ROOT + "ui/creature_rule_card.tscn")
const CARD_SCRIPT = preload(ROOT + "ui/creature_rule_card.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const APPEARANCE = preload(ROOT + "ui/creature_sheet_appearance.gd")
signal chapter_changed(chapter: int)
signal entry_requested(id: String)
signal inventory_add_requested
signal reader_closed
signal close_requested
signal create_requested
signal edit_requested
signal miniature_requested
signal miniature_clear_requested
signal portrait_requested
signal portrait_reset_requested
signal publication_requested(url: String)
signal roll_requested(part: String, id: String)
signal health_requested
const WORK := "Inset/Layout/Body/Workspace/"
const IDENTITY := "Inset/Layout/Body/Identity/"
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

func _ready() -> void:
	for index in range(3):
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][index]).pressed.connect(show_chapter.bind(index))
	get_node(WORK + "Tabs/Source").pressed.connect(show_source)
	get_node(WORK + "InventoryAdd").pressed.connect(_inventory_add)
	get_node(WORK + "Reader/Back").pressed.connect(back)
	get_node(WORK + "Reader/Publication").pressed.connect(_publication)
	get_node("Inset/Layout/Footer/Close").pressed.connect(_close)
	get_node("Inset/Layout/Footer/Create").pressed.connect(_create)
	get_node("Inset/Layout/Footer/Edit").pressed.connect(_edit)
	get_node(IDENTITY + "Health").pressed.connect(_health)
	get_node(IDENTITY + "Vitals/Armor").pressed.connect(_roll_armor)
	get_node(IDENTITY + "Vitals/Morale").pressed.connect(_roll_morale)
	get_node(WORK + "Section").item_selected.connect(_section_selected)
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
	_phone = size.x <= 900
	_tablet = not _phone and size.x <= 1400
	for edge in ["left", "right", "top", "bottom"]:
		get_node("Inset").add_theme_constant_override("margin_" + edge, 12 if _phone else 24 if _tablet else 32)
	get_node("Inset/Layout").add_theme_constant_override("separation", 6 if _phone else 12)
	get_node("Inset/Layout/Body").add_theme_constant_override("separation", 18 if _phone else 24 if _tablet else 32)
	(get_node(IDENTITY) as Control).add_theme_constant_override("separation", 5 if _phone else 12)
	(get_node(IDENTITY) as Control).size_flags_stretch_ratio = 0.85 if _phone else 1.0
	(get_node(WORK) as Control).size_flags_stretch_ratio = 2.15 if _phone else 2.0
	var name := str(_data.get("name", "Creature"))
	var metadata := CONTENT.new().details(str(_data.get("definition_id", "")))
	if _library and name.contains(","):
		name = name.split(",")[0]
	get_node(IDENTITY + "Name").text = _locale.text(name)
	get_node(IDENTITY + "Name").add_theme_font_size_override("font_size", 24 if _phone else 32 if _tablet else 46)
	get_node(IDENTITY + "Classification").text = _locale.text(str(_data.get("classification", metadata.get("classification", ""))))
	get_node(IDENTITY + "Classification").add_theme_font_size_override("font_size", 10 if _phone else 12 if _tablet else 16)
	get_node(IDENTITY + "Portrait").texture = _texture
	get_node(IDENTITY + "Health").text = _locale.text("Hit points") + "  " + str(metadata.get("hit_points_formula", _data.get("hit_points", "—")) if _library else _data.get("hit_points", "—")) + ("" if _library else " / " + str(_data.get("maximum_hit_points", "—")))
	get_node(IDENTITY + "Health").custom_minimum_size = Vector2(0, 44 if _phone else 62)
	get_node(IDENTITY + "Health").add_theme_font_size_override("font_size", 16 if _phone else 23 if _tablet else 28)
	get_node(IDENTITY + "Health").disabled = _library or not _can_edit or not bool(_data.get("health_available", false))
	var armor: Dictionary = _data.get("armor", {})
	var protection := "—" if str(armor.get("reduction", "")).is_empty() else "−" + str(armor.reduction)
	if int(armor.get("shield_reduction", 0)) > 0:
		protection += " · " + _locale.text("Shield") + " −" + str(armor.shield_reduction)
	if int(armor.get("defence_penalty", 0)) != 0:
		protection += "\n" + _locale.text("Defence penalty +%d") % int(armor.defence_penalty)
	get_node(IDENTITY + "Vitals/Armor").text = _locale.text(str(armor.get("name", "Protection"))) + "\n" + protection
	get_node(IDENTITY + "Vitals/Armor").tooltip_text = _locale.text("Protection") + ": " + _locale.text(str(armor.get("name", "Protection"))) + "\n" + protection
	var morale: Dictionary = _data.get("morale", {})
	get_node(IDENTITY + "Vitals/Morale").text = _locale.text("Morale") + "\n" + (str(morale.get("value", 0)) if str(morale.get("kind", "")) == "fixed" else _locale.text("Special") if str(morale.get("kind", "")) == "special" else "—")
	for key in ["Armor", "Morale"]:
		var button = get_node(IDENTITY + "Vitals/" + key)
		button.custom_minimum_size = Vector2(0, 44 if _phone else 62)
		button.add_theme_font_size_override("font_size", 11 if _phone else 14 if _tablet else 18)
		button.disabled = _library or _rolls_disabled() or (str(armor.get("reduction", "")).is_empty() if key == "Armor" else str(morale.get("kind", "")) != "fixed")
	for title in ["Encounter", "Inventory", "Appearance"]:
		get_node(WORK + "Tabs/" + title).text = _locale.text(title)
		get_node(WORK + "Tabs/" + title).add_theme_font_size_override("font_size", 11 if _phone else 14 if _tablet else 18)
	get_node(WORK + "Tabs/Source").text = "" if _phone else _locale.text("Source")
	get_node(WORK + "Tabs/Source").icon = preload("res://rookframe/ui/icons/character/book.svg")
	get_node(WORK + "Tabs/Source").accessibility_name = _locale.text("Published source")
	get_node(WORK + "Tabs/Source").tooltip_text = _locale.text("Published source")
	get_node(WORK + "Tabs/Source").add_theme_constant_override("icon_max_width", 20)
	get_node("Inset/Layout/Footer/Create").visible = _library
	get_node("Inset/Layout/Footer/Create").disabled = not _can_edit
	get_node("Inset/Layout/Footer/Create").text = _locale.text("Create Actor")
	get_node("Inset/Layout/Footer/Edit").visible = not _library and _can_edit
	get_node("Inset/Layout/Footer/Edit").text = _locale.text("Edit sheet")
	get_node("Inset/Layout/Footer/Edit").disabled = not bool(_data.get("corrections_available", false))
	get_node(WORK + "InventoryAdd").text = _locale.text("Add Item")
	get_node(WORK + "InventoryAdd").disabled = not _can_edit
	get_node("Inset/Layout/Footer/Close").text = _locale.text("Close")
	get_node(WORK + "Reader/Back").text = _locale.text("Back to creature")
	get_node(WORK + "Reader/Publication").text = _locale.text("Open publication")
	(get_node(WORK + "Appearance") as APPEARANCE).configure(_locale, _texture, _library, _can_edit, _phone, _tablet)
	for button in ["ChangePortrait", "ClearPortrait"]:
		get_node(WORK + "Appearance/PortraitPanel/Inset/Content/PortraitButtons/" + button).disabled = not _data.get("portrait_editable", _can_edit)
	_build_groups(metadata)
	_render_encounter()
	_render_inventory()
	_update_visibility()

func _build_groups(metadata: Dictionary) -> void:
	_groups.clear()
	var attacks: Array = _data.get("attacks", [])
	var attack_entries: Array = []
	for raw in attacks:
		var attack: Dictionary = raw
		attack_entries.append({"id": str(attack.get("id", "")), "name": str(attack.get("name", "Attack")), "text": str(attack.get("rules", "")), "dice": str(attack.get("dice", "")), "attack_dr": attack.get("attack_dr", null), "attack": true})
	if attack_entries.is_empty():
		attack_entries.append({"id": "no-attacks", "name": "Attacks", "text": "No attacks recorded."})
	_groups.append({"title": "Attacks", "lane": "primary", "entries": attack_entries})
	var armor: Dictionary = _data.get("armor", {})
	if armor.has("shield_reduction") or armor.has("defence_penalty"):
		var protection := _locale.text(str(armor.get("name", "Protection"))) + "\n" + _locale.text("Damage reduction") + ": " + ("—" if str(armor.get("reduction", "")).is_empty() else "−" + str(armor.reduction))
		if armor.has("shield_reduction"):
			protection += "\n" + _locale.text("Shield reduction") + ": −" + str(armor.shield_reduction)
		if armor.has("defence_penalty"):
			protection += "\n" + _locale.text("Defence penalty +%d") % int(armor.defence_penalty)
		_groups.append({"title": "Protection", "lane": "secondary", "entries": [{"id": "protection", "name": "Protection", "text": protection}]})
	var authored: Array = _data.get("rule_groups", metadata.get("rule_groups", []) if _library else [])
	for raw in authored:
		var group: Dictionary = raw
		_groups.append(group.duplicate(true))
	# Live corrections remain the sole accepted free rules text. Preserve unknown/custom rules.
	if authored.is_empty() and not str(_data.get("rules", "")).is_empty():
		_groups.append({"title": "Special rules", "lane": "secondary", "entries": [{"id": "rules", "name": "Special rules", "text": str(_data.rules)}]})
	var reference: Array = _data.get("reference", metadata.get("reference", []))
	if not reference.is_empty():
		_groups.append({"title": "Reference", "lane": "secondary", "entries": reference})
	var selector = get_node(WORK + "Section")
	selector.clear()
	for group in _groups:
		selector.add_item(_locale.text(str(group.title)))
	_section = mini(_section, maxi(0, _groups.size() - 1))
	selector.select(_section)

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

func _render_encounter() -> void:
	for lane in ["Primary", "Secondary"]:
		var pages = get_node(WORK + "Encounter/" + lane)
		var state: Dictionary = pages.capture_state()
		_clear(pages.get_node("Area/Content"))
		for index in range(_groups.size()):
			var group := _groups[index]
			if _phone and index != _section or not _phone and str(group.get("lane", "primary")) != lane.to_lower():
				continue
			_append(pages.get_node("Area/Content"), {"name": group.title, "text": ""})
			var entries: Array = group.entries
			for raw in entries:
				var entry: Dictionary = raw
				var actions: Array = []
				if entry.get("attack", false):
					if not _library and entry.get("attack_dr") != null:
						actions.append({"name": "Attack", "part": "attack", "dice": "d20 / DR" + str(entry.attack_dr), "disabled": _rolls_disabled()})
					if _library:
						entry = entry.duplicate(true)
						entry.text = (_locale.text("Attack") + " d20 / DR" + str(entry.attack_dr) + "\n" if entry.get("attack_dr") != null else "") + _locale.text("Damage") + " " + str(entry.dice) + ("\n" + str(entry.text) if not str(entry.text).is_empty() else "")
					else:
						actions.append({"name": "Damage", "part": "damage", "dice": str(entry.dice), "disabled": _rolls_disabled()})
				if not _library:
					if entry.has("own_test"):
						actions.append({"name": str(entry.name), "part": str(entry.own_test), "disabled": _rolls_disabled()})
					var rolls: Array = entry.get("rolls", [])
					for raw_roll in rolls:
						var roll: Dictionary = raw_roll
						actions.append({"name": str(roll.name), "part": "printed:" + str(roll.id), "dice": str(roll.dice), "disabled": _rolls_disabled()})
				_append(pages.get_node("Area/Content"), entry, actions)
		pages.restore_state(state)
	get_node(WORK + "Encounter/Secondary").visible = not _phone

func _rolls_disabled() -> bool:
	return not _can_edit or not bool(_data.get("rolls_available", false)) or int(_data.get("hit_points", 0)) <= 0 or _data.get("editing", false)

func _render_inventory() -> void:
	var pages = get_node(WORK + "Inventory")
	var state: Dictionary = pages.capture_state()
	var content = pages.get_node("Area/Content")
	_clear(content)
	var items: Array = _data.get("inventory", [])
	if items.is_empty():
		_append(content, {"name": "Inventory", "text": "No starting loot is authored for this creature." if _library else "No carried loot."})
	for raw in items:
		var item: Dictionary = raw
		_append(content, {"id": str(item.get("inventory_id", "")), "name": str(item.get("name", "Item")), "text": str(item.get("quantity", 1)) + " × " + _locale.text(str(item.get("kind", "Item"))) + ("\n" + _locale.text(str(item.get("rules", ""))) if _library and not str(item.get("rules", "")).is_empty() else "")}, [{"name": "Details", "part": "details"}])
	pages.restore_state(state)

func _requested(part: String, id: String, opener: CARD_SCRIPT) -> void:
	if part == "details":
		entry_requested.emit(id)
		if not _library:
			return
		var items: Array = _data.get("inventory", [])
		for raw in items:
			var item: Dictionary = raw
			if str(item.get("inventory_id", "")) == id:
				show_entry(item, opener)
	else:
		roll_requested.emit(part, id)

func show_entry(entry: Dictionary, opener: CARD_SCRIPT = null) -> void:
	_return_entry = str(entry.get("inventory_id", ""))
	_focus_card = opener
	_focus_source = false
	_reader = true
	var content = get_node(WORK + "Reader/Pages/Area/Content")
	_clear(content)
	_append_reference(content, {"name": str(entry.get("name", "Item")), "text": str(entry.get("rules", ""))})
	for key in ["kind", "quantity", "damage", "armor_tier", "defence_penalty", "uses", "weight", "price"]:
		if entry.has(key):
			_append_reference(content, {"name": key.capitalize(), "text": str(entry[key])})
	(get_node(WORK + "Reader/Publication") as Control).visible = false
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func _source() -> Dictionary:
	var metadata: Dictionary = CONTENT.new().details(str(_data.get("definition_id", "")))
	var source: Dictionary = _data.get("source", metadata.get("source", {}))
	return source

func show_source() -> void:
	_return_entry = ""
	_focus_card = null
	_focus_source = true
	_reader = true
	var content = get_node(WORK + "Reader/Pages/Area/Content")
	_clear(content)
	var source: Dictionary = _source()
	_append_reference(content, {"name": "Published source", "text": str(source.get("title", "")) + "\n" + str(source.get("page", "")) + "\n" + str(source.get("author", ""))})
	_append_reference(content, {"name": "Attribution", "text": "MÖRK BORG is © Ockult Örtmästare Games & Stockholm Kartell. Mechanical facts are restated; study artwork is not official book art."})
	(get_node(WORK + "Reader/Publication") as Control).visible = not str(source.get("url", "")).is_empty()
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func back() -> void:
	_reader = false
	_update_visibility()
	_restore_return_focus.call_deferred()
	reader_closed.emit()

func _restore_return_focus() -> void:
	if _focus_source:
		get_node(WORK + "Tabs/Source").grab_focus()
	elif is_instance_valid(_focus_card) and _focus_card.restore_focus():
		pass
	elif not _return_entry.is_empty() and focus_entry(_return_entry):
		pass
	else:
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][_chapter]).grab_focus()

func show_chapter(chapter: int) -> void:
	_chapter = clampi(chapter, 0, 2)
	_reader = false
	_update_visibility()
	chapter_changed.emit(_chapter)

func _update_visibility() -> void:
	(get_node(IDENTITY) as Control).visible = not (_phone and (_chapter == 2 or _reader))
	get_node(WORK + "Tabs").visible = not _reader
	get_node(WORK + "Section").visible = _phone and _chapter == 0 and not _reader
	get_node(WORK + "InventoryAdd").visible = _chapter == 1 and not _reader and not _library and _can_edit
	get_node(WORK + "Encounter").visible = _chapter == 0 and not _reader
	get_node(WORK + "Inventory").visible = _chapter == 1 and not _reader
	get_node(WORK + "Appearance").visible = _chapter == 2 and not _reader
	get_node(WORK + "Reader").visible = _reader
	for index in range(3):
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][index]).set_pressed_no_signal(index == _chapter)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel") and _reader:
		back()
		accept_event()

func status(message: String) -> void:
	get_node("Inset/Layout/Footer/Status").text = _locale.text(message)

func miniature(title: String, package: String, assigned: bool) -> void:
	(get_node(WORK + "Appearance") as APPEARANCE).miniature(_locale, title, package, assigned)

func miniature_preview_target() -> Control:
	return get_node(WORK + "Appearance/MiniaturePanel/Inset/Content/MiniaturePreview")

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
	_section = index
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
	var pages: Dictionary = {}
	for key in ["Encounter/Primary", "Encounter/Secondary", "Inventory", "Reader/Pages"]:
		pages[key] = get_node(WORK + key).capture_state()
	return {"chapter": _chapter, "section": _section, "pages": pages}

func restore_navigation(state: Dictionary) -> void:
	_chapter = clampi(int(state.get("chapter", 0)), 0, 2)
	_section = maxi(0, int(state.get("section", 0)))
	_reader = false
	var pages: Dictionary = state.get("pages", {})
	for key in ["Encounter/Primary", "Encounter/Secondary", "Inventory", "Reader/Pages"]:
		var value: Dictionary = pages.get(key, {})
		get_node(WORK + key).restore_state(value)
	_queue_layout()

func open_reader(title: String, return_entry: String = "") -> void:
	_focus_card = null
	_focus_source = false
	_return_entry = return_entry
	_reader = true
	_clear(reader_content())
	_append_reference(reader_content(), {"name": title, "text": ""})
	(get_node(WORK + "Reader/Publication") as Control).visible = false
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func reader_content() -> Control:
	return get_node(WORK + "Reader/Pages/Area/Content") as Control

func reader_state() -> Dictionary:
	return get_node(WORK + "Reader/Pages").capture_state()

func restore_reader(state: Dictionary) -> void:
	get_node(WORK + "Reader/Pages").restore_state(state)

func focus_entry(id: String) -> bool:
	for child in get_node(WORK + "Inventory/Area/Content").get_children():
		var card := child as CARD_SCRIPT
		if card != null and card.entry_id == id and card.restore_focus():
			return true
	return false

func focus_miniature() -> void:
	get_node(WORK + "Appearance/MiniaturePanel/Inset/Content/MiniatureButtons/ChangeMiniature").grab_focus()
