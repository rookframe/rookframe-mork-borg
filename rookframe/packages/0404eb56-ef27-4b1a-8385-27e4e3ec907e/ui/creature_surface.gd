extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
## Live SDK Actor adapter. Rules, loot and Appearance retain separate boundaries.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SHEET = preload(ROOT + "ui/creature_sheet_surface.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const ITEMS = preload(ROOT + "logic/creature_actions.gd")
const EQUIPMENT = preload(ROOT + "logic/equipment.gd")
const MINIATURES = preload(ROOT + "logic/miniature_actions.gd")
const FIELD = preload(ROOT + "ui/sheet_entry_field.tscn")
const FIELD_SCRIPT = preload(ROOT + "ui/sheet_entry_field.gd")
const BUTTON = preload(ROOT + "ui/sheet_text_button.tscn")
const SEARCH = preload("res://rookframe/ui/components/forms/task_text_field.tscn")
const SEARCH_SCRIPT = preload("res://rookframe/ui/components/forms/text_field.gd")
@export var navigation: Resource
@onready var sheet: SHEET = get_node("Sheet")
var locale := I18N.new()
var actor: SDK.Actor
var _items: Array = []
var _detail := ""
var _new_item: Dictionary = {}
var _fields: Array[FIELD_SCRIPT] = []
var _detail_pages: Dictionary = {}
var _busy := false
var _portrait_pending := false
var _portrait_epoch := 0
var _portrait_image := PackedByteArray()
var _portrait_texture: Texture2D
var _portrait_error := ""
var _portrait_feedback := ""
var _refresh_pending := false
var _detail_pending := false
var _edit_item := false
var _corrections_available := false
var _health_available := false
var _rolls_available := false
var _nav: Dictionary = {}
var _catalogue_query := ""
var _catalogue_buttons: Array[Button] = []
var _catalogue_names: Array[String] = []
var _catalogue_empty: Label
signal correction_requested
signal health_adjustment_requested
signal gameplay_roll_requested(part: String, id: String)

func ready() -> void:
	if sdk == null:
		return
	locale.bind(sdk)
	sheet.close_requested.connect(_close)
	sheet.entry_requested.connect(_entry)
	sheet.inventory_add_requested.connect(_catalogue)
	sheet.reader_closed.connect(_reader_closed)
	sheet.chapter_changed.connect(_chapter_changed)
	sheet.publication_requested.connect(_publication)
	sheet.miniature_requested.connect(_choose_miniature)
	sheet.miniature_clear_requested.connect(_clear_miniature)
	sheet.portrait_requested.connect(_choose_portrait)
	sheet.portrait_reset_requested.connect(_reset_portrait)
	sheet.edit_requested.connect(_correct)
	sheet.health_requested.connect(_health)
	sheet.roll_requested.connect(_roll)
	get_node("MiniatureWorkflow").closed.connect(_picker_closed)
	get_node("Unavailable/Inset/Content/Close").pressed.connect(_close)
	closed.connect(_closed)
	sdk.world_changed.connect(_world_changed)

func opened(id: SDK.ActorId) -> void:
	_end_portrait()
	_portrait_feedback = ""
	_remember()
	_detail = ""
	_edit_item = false
	_new_item = {}
	_catalogue_query = ""
	_fields.clear()
	get_node("MiniatureWorkflow").visible = false
	var result := sdk.actors.read(id)
	if not result.ok or result.actor == null:
		actor = null
		_unavailable(result.message)
		return
	var data: Dictionary = result.actor.data
	if str(data.get("schema", "")) != "mork-borg-adversary/v1":
		actor = null
		_unavailable("Private Creature data is unavailable.")
		return
	actor = result.actor
	_nav = navigation.read(sdk.context().session_id, actor.id.value)
	_detail_pages = _nav.get("details", {})
	sheet.restore_navigation(_nav)
	get_node("Unavailable").visible = false
	sheet.visible = true
	_refresh()

func owner() -> bool:
	return actor != null and actor.access_level == "Owner"

func current_data() -> Dictionary:
	var data: Dictionary = actor.data if actor != null else {}
	return CREATURES.new().stat_block(data)

func _world_changed() -> void:
	_refresh_pending = true

func _process(_delta: float) -> void:
	if _refresh_pending and not _busy and actor != null:
		_refresh_pending = false
		var result := sdk.actors.read(actor.id)
		if not result.ok or result.actor == null:
			_remember()
			actor = null
			_unavailable(result.message)
		else:
			var data: Dictionary = result.actor.data
			if str(data.get("schema", "")) != "mork-borg-adversary/v1":
				_remember()
				actor = null
				_unavailable("Private Creature data is unavailable.")
			else:
				actor = result.actor
				_refresh()
	if _detail_pending and not _busy:
		_detail_pending = false
		_render_detail()

func _refresh() -> void:
	if actor == null:
		return
	if not owner() and get_node("MiniatureWorkflow").visible:
		get_node("MiniatureWorkflow").visible = false
		sheet.visible = true
	var data := current_data()
	_items = ITEMS.new(sdk, actor.id).inventory(data)
	data["inventory"] = _items
	# Dedicated follow-ups enable these parts after their accepted domain actions exist.
	data["corrections_available"] = _corrections_available
	data["health_available"] = _health_available
	data["rolls_available"] = _rolls_available
	sheet.configure(data, locale, false, owner() and not _busy, _portrait(data))
	sdk.windows.set_title(str(data.get("name", "Creature")))
	sheet.status("Creature sheet · Owner" if owner() else "Creature sheet · Viewer")
	if not _portrait_error.is_empty():
		sheet.status(_portrait_error)
	elif not _portrait_feedback.is_empty():
		sheet.status(_portrait_feedback)
	if not _detail.is_empty():
		if not owner():
			_edit_item = false
			if _detail in ["catalogue", "custom"]:
				_detail = ""
				sheet.back()
		if _detail.begins_with("item:") and not _fields.is_empty() and owner() and _edit_item:
			var item := _item(_detail.trim_prefix("item:"))
			if item.is_empty():
				_detail_pending = true
			else:
				for field in _fields:
					field.refresh_value(str(item.get(field._field, "")))
		elif _detail not in ["custom", "catalogue"]:
			_detail_pending = true
	_refresh_appearance.call_deferred()
	_remember()

func _unavailable(message: String) -> void:
	sheet.visible = false
	get_node("MiniatureWorkflow").visible = false
	get_node("Unavailable").visible = true
	get_node("Unavailable/Inset/Content/Message").text = locale.text(message if not message.is_empty() else "Private Creature data is unavailable.")
	get_node("Unavailable/Inset/Content/Close").text = locale.text("Close")

func _entry(id: String) -> void:
	_open_detail("item:" + id)

func _catalogue() -> void:
	if owner() and not _busy:
		_open_detail("catalogue")

func _custom() -> void:
	if owner() and not _busy:
		_new_item = {}
		_open_detail("custom")

func _open_detail(route: String) -> void:
	_capture_detail()
	_detail = route
	_edit_item = false
	_fields.clear()
	_detail_pending = true

func _render_detail() -> void:
	if _detail.is_empty() or actor == null:
		return
	var page: Dictionary = _detail_pages.get(_detail, {})
	if not _fields.is_empty():
		page = sheet.reader_state()
	_fields.clear()
	var return_entry := _detail.trim_prefix("item:") if _detail.begins_with("item:") else ""
	sheet.open_reader("Inventory", return_entry)
	if _detail == "catalogue":
		_text("Add equipment from the core catalogue or create custom loot.")
		var search: SEARCH_SCRIPT = SEARCH.instantiate()
		sheet.reader_content().add_child(search)
		search.label_text = locale.text("Search equipment")
		search.compact = sheet.size.x <= 900
		search.value = _catalogue_query
		search.value_changed.connect(_filter_catalogue)
		_option("Create custom item", _custom, owner())
		_catalogue_buttons.clear()
		_catalogue_names.clear()
		for item in EQUIPMENT.new().entries():
			_catalogue_names.append(str(item.get("name", "Equipment")))
			_catalogue_buttons.append(_option(locale.text(str(item.get("name", "Equipment"))) + " · " + str(item.get("price", "")), _add_equipment.bind(str(item.get("source_item_id", ""))), owner()))
		_catalogue_empty = _text("No matching equipment.")
		_filter_catalogue(_catalogue_query)
	elif _detail == "custom":
		_text("Custom loot")
		for key in ["name", "kind", "quantity", "uses", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
			_item_field(str(key), str(_new_item.get(key, "Equipment" if key == "kind" else "1" if key == "quantity" else "0" if key in ["uses", "range_feet", "armor_tier"] else "")), false)
		_option("Add custom item", _add_custom, owner())
	elif _detail.begins_with("item:"):
		var item := _item(return_entry)
		if item.is_empty():
			_text("This item was removed. Return to Inventory to see the current items.")
		else:
			_text(str(item.get("name", "Item")))
			_text(str(item.get("rules", "")))
			for key in ["kind", "quantity", "uses", "damage", "range_feet", "armor_tier", "reduction", "price", "weight", "source"]:
				if item.has(key):
					_text(locale.text(str(key).replace("_", " ").capitalize()) + ": " + str(item.get(key, "")))
			for key in ["name", "quantity", "uses", "kind", "damage", "range_feet", "armor_tier", "reduction", "rules"]:
				if key == "uses" and item.has("dose_pool") or key not in ["name", "quantity", "uses"] and not bool(item.get("custom", false)):
					continue
				if _edit_item and owner():
					_item_field(str(key), str(item.get(key, "")), true)

			if owner():
				_option("Finish item editing" if _edit_item else "Edit item", _edit_loot, not _busy)
				_option("Remove item", _remove_item, not _busy)
	sheet.restore_reader(page)

func _text(text: String) -> Label:
	var label := Label.new()
	label.text = locale.text(text)
	label.autowrap_mode = 3
	label.add_theme_font_size_override("font_size", 13 if sheet.size.x <= 900 else 18)
	sheet.reader_content().add_child(label)
	return label

func _filter_catalogue(query: String) -> void:
	_catalogue_query = query
	var count := 0
	for index in range(_catalogue_buttons.size()):
		var button := _catalogue_buttons[index]
		button.visible = query.to_lower() in _catalogue_names[index].to_lower() or query.to_lower() in button.text.to_lower()
		if button.visible:
			count += 1
	if is_instance_valid(_catalogue_empty):
		_catalogue_empty.visible = count == 0

func _option(title: String, action: Callable, enabled: bool) -> Button:
	var button := BUTTON.instantiate()
	button.text = locale.text(title)
	button.custom_minimum_size = Vector2(44, 44)
	button.disabled = not enabled or _busy
	button.pressed.connect(action)
	sheet.reader_content().add_child(button)
	return button

func _item_field(key: String, value: String, independent: bool) -> void:
	var field: FIELD_SCRIPT = FIELD.instantiate()
	sheet.reader_content().add_child(field)
	field.configure(key, locale.text(key.replace("_", " ").capitalize()), value, key == "rules", independent)
	field.configure_layout(sheet.size.x <= 900)
	field.get_node("Save").text = locale.text("Save") + " " + locale.text(key.capitalize())
	field.submitted.connect(_save_field)
	field.changed.connect(_custom_typed)
	_fields.append(field)

func _custom_typed(key: String, value: String) -> void:
	if _detail == "custom":
		_new_item[key] = value

func _item(id: String) -> Dictionary:
	for raw in _items:
		var item: Dictionary = raw
		if str(item.get("inventory_id", "")) == id:
			return item
	return {}

func _edit_loot() -> void:
	if not owner() or _busy:
		return
	_capture_detail()
	_edit_item = not _edit_item
	_detail_pending = true

func _add_equipment(id: String) -> void:
	await _mutate("add", [id])

func _add_custom() -> void:
	await _mutate("custom", [_new_item.duplicate(true)])

func _save_field(key: String, value: String) -> void:
	await _mutate("field", [_detail.trim_prefix("item:"), key, value])

func _remove_item() -> void:
	await _mutate("remove", [_detail.trim_prefix("item:")])

func _mutate(operation: String, arguments: Array) -> void:
	if not owner() or _busy:
		return
	var id := actor.id.value
	var actions := ITEMS.new(sdk, actor.id)
	_busy = true
	sheet.status("Saving Inventory…")
	var result := SDK.ActorResult.new({"ok": false, "message": "Unknown Inventory edit."})
	if operation == "add":
		result = await actions.add_equipment(str(arguments[0]))
	elif operation == "custom":
		var values: Dictionary = arguments[0]
		result = await actions.add_custom(values)
	elif operation == "field":
		result = await actions.change_item(str(arguments[0]), str(arguments[1]), str(arguments[2]))
	elif operation == "remove":
		result = await actions.remove_item(str(arguments[0]))
	_busy = false
	if actor == null or actor.id.value != id:
		_refresh()
		return
	if result.ok:
		actor = result.actor
		if operation != "field":
			_detail = ""
			_edit_item = false
		_refresh()
		if operation != "field":
			sheet.back()
		sheet.status("Inventory saved.")
	else:
		sheet.status(result.message)
		if operation in ["field", "custom"]:
			var key := str(arguments[1]) if operation == "field" else actions.invalid_field
			for field in _fields:
				if field._field == key:
					field.show_error(locale.text(result.message))

func _choose_miniature() -> void:
	if not owner() or _busy:
		return
	sheet.visible = false
	var data := current_data()
	var saved: Dictionary = data.get("preferred_miniature", {})
	get_node("MiniatureWorkflow").open(sdk, locale, actor.id, "", saved)
	get_node("MiniatureWorkflow/Actions/Back").text = locale.text("Cancel")

func _picker_closed(_saved: bool) -> void:
	sheet.visible = true
	_refresh_pending = true
	sheet.focus_miniature()

func _clear_miniature() -> void:
	if not owner() or _busy:
		return
	_busy = true
	var id := actor.id.value
	var result := await MINIATURES.new(sdk).set_actor(actor.id, {})
	_busy = false
	if actor != null and actor.id.value == id:
		if result.ok:
			actor = result.actor
		_refresh()
		if not result.ok:
			sheet.status(result.message)

func _portrait(data: Dictionary) -> Texture2D:
	var image: PackedByteArray = data.get("portrait", PackedByteArray()) if typeof(data.get("portrait", PackedByteArray())) == typeof(PackedByteArray()) else PackedByteArray()
	if image != _portrait_image:
		_portrait_image = image
		_portrait_texture = null
		_portrait_error = ""
		if not image.is_empty():
			var decoded := sdk.portraits.decode(image)
			if decoded.ok:
				_portrait_texture = decoded.texture
			else:
				_portrait_error = decoded.message
	if image.is_empty():
		_portrait_error = ""
	if data.has("portrait") and typeof(data.portrait) != typeof(PackedByteArray()):
		_portrait_error = "Portrait is unavailable. Choose a replacement."
	return _portrait_texture

func _choose_portrait() -> void:
	if not owner() or _busy:
		return
	var id := actor.id
	var epoch := _portrait_epoch
	_portrait_pending = true
	_portrait_feedback = ""
	_busy = true
	_refresh()
	sheet.status("Choosing portrait…")
	var selected := await sdk.portraits.choose()
	if epoch != _portrait_epoch or actor == null or actor.id.value != id.value:
		return
	if not selected.ok:
		_portrait_pending = false
		_busy = false
		_refresh_pending = true
		_portrait_feedback = selected.message if selected.code != "cancelled" else ""
		_refresh()
		sheet.focus_portrait.call_deferred()
		return
	await _save_portrait(id, selected.image, epoch)

func _reset_portrait() -> void:
	if not owner() or _busy:
		return
	_portrait_pending = true
	_portrait_feedback = ""
	_busy = true
	_refresh()
	await _save_portrait(actor.id, PackedByteArray(), _portrait_epoch)

func _save_portrait(id: SDK.ActorId, image: PackedByteArray, epoch: int) -> void:
	sheet.status("Saving portrait…")
	var result := await ITEMS.new(sdk, id).set_portrait(image)
	if epoch != _portrait_epoch or actor == null or actor.id.value != id.value:
		return
	_portrait_pending = false
	_busy = false
	if result.ok:
		actor = result.actor
	_portrait_feedback = "Appearance updated." if result.ok else result.message
	_refresh_pending = true
	_refresh()
	sheet.focus_portrait.call_deferred()

func _end_portrait() -> void:
	_portrait_epoch += 1
	if _portrait_pending:
		_busy = false
	_portrait_pending = false

func _refresh_appearance() -> void:
	if actor == null or sdk == null:
		return
	var data := current_data()
	var reference: Dictionary = data.get("preferred_miniature", {})
	var found := sdk.content.read(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))))
	sheet.miniature(found.content_entry.localized_title if found.ok else locale.text("Saved Miniature unavailable. Choose a replacement."), found.content_entry.package_title if found.ok else "", not reference.is_empty())
	if not reference.is_empty() and sheet.miniature_preview_target().is_visible_in_tree():
		var result := sdk.content.preview_miniature(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))), sheet.miniature_preview_target())
		if not result.ok:
			sheet.status(result.message)

func _publication(url: String) -> void:
	var result := await sdk.browser.open(url)
	if not result.ok:
		sheet.status(result.message)

func _capture_detail() -> void:
	if not _detail.is_empty():
		_detail_pages[_detail] = sheet.reader_state()

func _remember() -> void:
	if actor == null or navigation == null or sdk == null:
		return
	_capture_detail()
	_nav = sheet.capture_navigation()
	_nav["details"] = _detail_pages.duplicate(true)
	navigation.remember(actor.id.value, _nav)

func _reader_closed() -> void:
	_capture_detail()
	_detail = ""
	_edit_item = false
	_fields.clear()
	_remember()

func _chapter_changed(_chapter: int) -> void:
	_capture_detail()
	_detail = ""
	_fields.clear()
	_remember()
	_refresh_appearance()

func capture_reconnect_state() -> Dictionary:
	_remember()
	return _nav.duplicate(true)

func restore_reconnect_state(state: Dictionary) -> void:
	_nav = state.duplicate(true)
	_detail_pages = _nav.get("details", {})
	sheet.restore_navigation(_nav)
	_remember()

func _closed() -> void:
	_end_portrait()
	_remember()
	get_node("MiniatureWorkflow").visible = false
	sheet.visible = true
	_detail = ""
	_edit_item = false
	_new_item = {}
	_fields.clear()

func _close() -> void:
	_closed()
	sdk.windows.close(load(ROOT + "ui/creature_surface.tres"))

func _correct() -> void:
	correction_requested.emit()
func _health() -> void:
	health_adjustment_requested.emit()
func _roll(part: String, id: String) -> void:
	gameplay_roll_requested.emit(part, id)

func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and not _busy and event.is_action_pressed("ui_cancel"):
		if get_node("MiniatureWorkflow").visible:
			get_node("MiniatureWorkflow")._cancel()
		else:
			_close()
		accept_event()

## Dependent rule adapters opt in only after their accepted actions are installed.
func set_sheet_actions(corrections: bool, health: bool, rolls: bool) -> void:
	_corrections_available = corrections
	_health_available = health
	_rolls_available = rolls
	_refresh()

func accept_actor(value: SDK.Actor) -> void:
	if actor != null and value != null and actor.id.value == value.id.value:
		actor = value
		_refresh()

func request_refresh() -> void:
	_refresh_pending = true

func operation_pending() -> bool:
	return _busy
