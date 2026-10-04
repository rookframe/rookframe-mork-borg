extends Control
## Shared authored Full-viewport composition. Domain adapters own mutations/rolls.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const CONTENT = preload(ROOT + "logic/creature_content.gd")
const CARD = preload(ROOT + "ui/creature_rule_card.tscn")
const I18N = preload(ROOT + "ui/localization.gd")
signal chapter_changed(chapter: int)
signal entry_requested(id: String)
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
var _locale: RefCounted = I18N.new()
var _library := true
var _can_edit := false
var _phone := false
var _tablet := false
var _chapter := 0
var _section := 0
var _reader := false
var _focus: Control
var _texture: Texture2D
var _groups: Array[Dictionary] = []
var _layout_pending := false
var _pages: Dictionary = {}

func _ready() -> void:
	for index in range(3):
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][index]).pressed.connect(func(): show_chapter(index))
	get_node(WORK + "Tabs/Source").pressed.connect(show_source)
	get_node(WORK + "Reader/Back").pressed.connect(back)
	get_node(WORK + "Reader/Publication").pressed.connect(func(): publication_requested.emit(str(_source().get("url", ""))))
	get_node("Inset/Layout/Footer/Close").pressed.connect(func(): close_requested.emit())
	get_node("Inset/Layout/Footer/Create").pressed.connect(func(): create_requested.emit())
	get_node("Inset/Layout/Footer/Edit").pressed.connect(func(): edit_requested.emit())
	get_node(IDENTITY + "Health").pressed.connect(func(): health_requested.emit())
	get_node(IDENTITY + "Vitals/Armor").pressed.connect(func(): roll_requested.emit("armor", ""))
	get_node(IDENTITY + "Vitals/Morale").pressed.connect(func(): roll_requested.emit("morale", ""))
	get_node(WORK + "Section").item_selected.connect(func(index: int): _section = index; _render_encounter())
	var appearance = get_node(WORK + "Appearance")
	appearance.miniature_requested.connect(func(): miniature_requested.emit())
	appearance.miniature_clear_requested.connect(func(): miniature_clear_requested.emit())
	appearance.portrait_requested.connect(func(): portrait_requested.emit())
	appearance.portrait_reset_requested.connect(func(): portrait_reset_requested.emit())
	resized.connect(_queue_layout)
	_queue_layout()

func configure(data: Dictionary, locale: RefCounted, library: bool = true, can_edit: bool = false, texture: Texture2D = null) -> void:
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
	get_node(IDENTITY).add_theme_constant_override("separation", 5 if _phone else 12)
	get_node(IDENTITY).size_flags_stretch_ratio = 0.85 if _phone else 1.0
	get_node(WORK).size_flags_stretch_ratio = 2.15 if _phone else 2.0
	var name := str(_data.get("name", "Creature"))
	var metadata := CONTENT.new().details(str(_data.get("definition_id", "")))
	if _library and name.contains(","):
		name = name.split(",")[0]
	get_node(IDENTITY + "Name").text = _locale.text(name)
	get_node(IDENTITY + "Name").add_theme_font_size_override("font_size", 24 if _phone else 32 if _tablet else 46)
	get_node(IDENTITY + "Classification").text = _locale.text(str(_data.get("classification", metadata.get("classification", ""))))
	get_node(IDENTITY + "Classification").add_theme_font_size_override("font_size", 10 if _phone else 12 if _tablet else 16)
	get_node(IDENTITY + "Portrait").texture = _texture
	get_node(IDENTITY + "Health").text = _locale.text("Hit points") + "  " + str(metadata.get("hit_points_formula", _data.get("hit_points", 0))) + ("" if _library else " / " + str(_data.get("maximum_hit_points", 0)))
	get_node(IDENTITY + "Health").custom_minimum_size.y = 44 if _phone else 62
	get_node(IDENTITY + "Health").add_theme_font_size_override("font_size", 16 if _phone else 23 if _tablet else 28)
	get_node(IDENTITY + "Health").disabled = _library or not _can_edit
	var armor: Dictionary = _data.get("armor", {})
	get_node(IDENTITY + "Vitals/Armor").text = _locale.text(str(armor.get("name", "No armor"))) + "\n" + ("—" if str(armor.get("reduction", "")).is_empty() else "−" + str(armor.reduction))
	var morale: Dictionary = _data.get("morale", {})
	get_node(IDENTITY + "Vitals/Morale").text = _locale.text("Morale") + "\n" + (str(morale.get("value", 0)) if str(morale.get("kind", "")) == "fixed" else _locale.text("Special") if str(morale.get("kind", "")) == "special" else "—")
	for key in ["Armor", "Morale"]:
		var button = get_node(IDENTITY + "Vitals/" + key)
		button.custom_minimum_size.y = 44 if _phone else 62
		button.add_theme_font_size_override("font_size", 11 if _phone else 14 if _tablet else 18)
		button.disabled = _library or not _can_edit or int(_data.get("hit_points", 0)) <= 0 or _data.get("editing", false) or (str(armor.get("reduction", "")).is_empty() if key == "Armor" else str(morale.get("kind", "")) != "fixed")
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
	get_node("Inset/Layout/Footer/Close").text = _locale.text("Close")
	get_node(WORK + "Reader/Back").text = _locale.text("Back to creature")
	get_node(WORK + "Reader/Publication").text = _locale.text("Open publication")
	get_node(WORK + "Appearance").configure(_locale, _texture, _library, _can_edit, _phone, _tablet)
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
	_groups.append({"title": "Attacks", "lane": "primary", "entries": attack_entries})
	var authored: Array = _data.get("rule_groups", metadata.get("rule_groups", []))
	for raw in authored:
		_groups.append(raw.duplicate(true))
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
	var card = CARD.instantiate()
	host.add_child(card)
	card.configure(entry, _locale, _phone, _tablet, actions)
	card.requested.connect(_requested)

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
			for entry in group.entries:
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
					for roll in entry.get("rolls", []):
						actions.append({"name": str(roll.name), "part": "printed:" + str(roll.id), "dice": str(roll.dice), "disabled": _rolls_disabled()})
				_append(pages.get_node("Area/Content"), entry, actions)
		pages.restore_state(state)
	get_node(WORK + "Encounter/Secondary").visible = not _phone

func _rolls_disabled() -> bool:
	return not _can_edit or int(_data.get("hit_points", 0)) <= 0 or _data.get("editing", false)

func _render_inventory() -> void:
	var pages = get_node(WORK + "Inventory")
	var state: Dictionary = pages.capture_state()
	var content = pages.get_node("Area/Content")
	_clear(content)
	var items: Array = _data.get("inventory", [])
	if items.is_empty():
		_append(content, {"name": "Inventory", "text": "No starting loot is authored for this creature." if _library else "No carried loot."})
	for item in items:
		_append(content, {"id": str(item.get("inventory_id", "")), "name": str(item.get("name", "Item")), "text": str(item.get("quantity", 1)) + " × " + _locale.text(str(item.get("kind", "Item"))) + ("\n" + _locale.text(str(item.get("rules", ""))) if not str(item.get("rules", "")).is_empty() else "")}, [{"name": "Details", "part": "details"}])
	pages.restore_state(state)

func _requested(part: String, id: String) -> void:
	if part == "details":
		entry_requested.emit(id)
		if not _library:
			return
		for item in _data.get("inventory", []):
			if str(item.get("inventory_id", "")) == id:
				show_entry(item)
	else:
		roll_requested.emit(part, id)

func show_entry(entry: Dictionary) -> void:
	_focus = get_viewport().gui_get_focus_owner()
	_reader = true
	var content = get_node(WORK + "Reader/Pages/Area/Content")
	_clear(content)
	_append(content, {"name": str(entry.get("name", "Item")), "text": str(entry.get("rules", ""))})
	for key in ["kind", "quantity", "damage", "armor_tier", "defence_penalty", "uses", "weight", "price"]:
		if entry.has(key):
			_append(content, {"name": key.capitalize(), "text": str(entry[key])})
	get_node(WORK + "Reader/Publication").visible = false
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func _source() -> Dictionary:
	return _data.get("source", CONTENT.new().details(str(_data.get("definition_id", ""))).get("source", {}))

func show_source() -> void:
	_focus = get_viewport().gui_get_focus_owner()
	_reader = true
	var content = get_node(WORK + "Reader/Pages/Area/Content")
	_clear(content)
	var source := _source()
	_append(content, {"name": "Published source", "text": str(source.get("title", "")) + "\n" + str(source.get("page", "")) + "\n" + str(source.get("author", ""))})
	_append(content, {"name": "Attribution", "text": "MÖRK BORG is © Ockult Örtmästare Games & Stockholm Kartell. Mechanical facts are restated; study artwork is not official book art."})
	get_node(WORK + "Reader/Publication").visible = not str(source.get("url", "")).is_empty()
	get_node(WORK + "Reader/Pages").restore_state({})
	_update_visibility()
	get_node(WORK + "Reader/Back").grab_focus()

func back() -> void:
	_reader = false
	_update_visibility()
	if is_instance_valid(_focus) and _focus.is_visible_in_tree():
		_focus.grab_focus()
	else:
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][_chapter]).grab_focus()

func show_chapter(chapter: int) -> void:
	_chapter = clampi(chapter, 0, 2)
	_reader = false
	_update_visibility()
	chapter_changed.emit(_chapter)

func _update_visibility() -> void:
	get_node(IDENTITY).visible = not (_phone and (_chapter == 2 or _reader))
	get_node(WORK + "Tabs").visible = not _reader
	get_node(WORK + "Section").visible = _phone and _chapter == 0 and not _reader
	get_node(WORK + "Encounter").visible = _chapter == 0 and not _reader
	get_node(WORK + "Inventory").visible = _chapter == 1 and not _reader
	get_node(WORK + "Appearance").visible = _chapter == 2 and not _reader
	get_node(WORK + "Reader").visible = _reader
	for index in range(3):
		get_node(WORK + "Tabs/" + ["Encounter", "Inventory", "Appearance"][index]).set_pressed_no_signal(index == _chapter)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel") and _reader:
		back()
		get_viewport().set_input_as_handled()

func status(message: String) -> void:
	get_node("Inset/Layout/Footer/Status").text = _locale.text(message)

func miniature(title: String, package: String, assigned: bool) -> void:
	get_node(WORK + "Appearance").miniature(_locale, title, package, assigned)

func miniature_preview_target() -> Control:
	return get_node(WORK + "Appearance/MiniaturePanel/Inset/Content/MiniaturePreview")
