extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
## Live SDK Actor adapter. Rules, loot and Appearance retain separate boundaries.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const DRAFT = preload(ROOT + "ui/sheet_draft.gd")
const PROJECTION = preload(ROOT + "logic/creature_projection.gd")
const SHEET = preload(ROOT + "ui/creature_sheet_surface.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const HEALTH = preload(ROOT + "logic/creature_health.gd")
const HEALTH_EDITOR_SCRIPT = preload(ROOT + "ui/creature_health_editor.gd")
const REQUEST = preload(ROOT + "logic/action_request.gd")
const ROLL_WORKFLOW = preload(ROOT + "ui/creature_roll_workflow.gd")
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
@onready var _roll_workflow: ROLL_WORKFLOW = get_node("RollWorkflow")
var locale := I18N.new()
var actor: SDK.Actor
var _accepted: Dictionary = {}
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
var _corrections_available := true
var _draft := DRAFT.new()
var _projection := PROJECTION.new()
var _correction_identity := ""
var _correction_feedback := ""
var _correction_epoch := 0
var _draft_refresh_pending := false
var _render_pending := false
var _validation: Dictionary = {}
var _health_available := true
var _health_editor: HEALTH_EDITOR_SCRIPT
var _health_pending := false
var _health_epoch := 0
var _health_feedback := ""
var _health_attempt: Dictionary = {}
var _rolls_available := true
var _roll_feedback := ""
var _roll_refresh_pending := false
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
	_roll_workflow.configure(sdk, self)
	_roll_workflow.changed.connect(_roll_changed)
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
	sheet.correction_entry_requested.connect(_open_correction)
	sheet.save_requested.connect(_save_sheet)
	sheet.cancel_requested.connect(_cancel_edit)
	sheet.health_requested.connect(_health)
	sheet.roll_requested.connect(_roll)
	get_node("MiniatureWorkflow").closed.connect(_picker_closed)
	get_node("Unavailable/Inset/Content/Close").pressed.connect(_close)
	closed.connect(_closed)
	sdk.world_changed.connect(_world_changed)

func opened(id: SDK.ActorId) -> void:
	_end_portrait()
	_end_health()
	_roll_workflow.opened(id.value)
	_portrait_feedback = ""
	_correction_epoch += 1
	_correction_feedback = ""
	_remember()
	_draft.discard()
	_validation = {}
	_detail = ""
	if _roll_workflow.has_action and _roll_workflow.source == id.value:
		_detail = "roll"
		_detail_pending = true
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
	return _accepted.duplicate(true) if actor != null else {}

func _world_changed() -> void:
	_refresh_pending = true

func _process(_delta: float) -> void:
	_roll_workflow.display_active = is_visible_in_tree()
	if _roll_refresh_pending:
		_roll_refresh_pending = false
		_roll_feedback = _roll_workflow.summary()
		_render_pending = true
		if actor != null and actor.id.value == _roll_workflow.source and _detail == "roll":
			_detail_pending = true
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
	if _draft_refresh_pending and not _busy and actor != null:
		_draft_refresh_pending = false
		var accepted := current_data()
		if _draft.refresh(_projection.fields(accepted), _projection.identities(accepted)):
			_detail_pending = true
		sheet.configure_draft(_draft.values(), _draft.active)
		if _detail.begins_with("correction:"):
			if not _correction_current(_detail.trim_prefix("correction:")):
				_detail_pending = true
			else:
				for field in _fields:
					field.sync_draft_value(_draft.value(field._field))
	if _render_pending and (not _busy or _portrait_pending or _health_pending):
		_render_pending = false
		_render_accepted()
	if _detail_pending and not _busy:
		_detail_pending = false
		_render_detail()

func _refresh() -> void:
	if actor == null:
		return
	var current: Dictionary = actor.data
	_accepted = CREATURES.new().stat_block(current)
	_draft_refresh_pending = _draft.active
	_render_pending = true

## All native composition refreshes coalesce into one subsequent process frame.
func _render_accepted() -> void:
	if actor == null:
		return
	if not owner() and get_node("MiniatureWorkflow").visible:
		get_node("MiniatureWorkflow").visible = false
		sheet.visible = true
	var data := current_data()
	if not owner():
		_draft.discard()
		_validation = {}
	data["editing"] = _draft.active
	sheet.configure_draft(_draft.values() if _draft.active else {}, _draft.active)
	_items = ITEMS.new(sdk, actor.id).inventory(data)
	data["inventory"] = _items
	# Dedicated follow-ups enable these parts after their accepted domain actions exist.
	data["corrections_available"] = _corrections_available
	data["health_available"] = _health_available
	data["rolls_available"] = _rolls_available
	data["roll_pending"] = _roll_live()
	data["corrections_available"] = _corrections_available and not _roll_live()
	data["health_available"] = _health_available and not _roll_live()
	sheet.configure(data, locale, false, owner() and not _busy, _portrait(data))
	sdk.windows.set_title(str(data.get("name", "Creature")))
	sheet.status("Creature sheet · Owner" if owner() else "Creature sheet · Viewer")
	if _portrait_pending:
		sheet.status(_portrait_feedback)
	elif not _roll_feedback.is_empty() and _detail == "roll":
		sheet.status(_roll_feedback)
	elif not _health_feedback.is_empty():
		sheet.status(_health_feedback)
	elif not _correction_feedback.is_empty():
		sheet.status(_correction_feedback)
	elif not _portrait_error.is_empty():
		sheet.status(_portrait_error)
	elif not _portrait_feedback.is_empty():
		sheet.status(_portrait_feedback)
	if not _detail.is_empty():
		if not owner():
			_edit_item = false
			if _detail in ["catalogue", "custom"]:
				_detail = ""
				sheet.back()
		if _detail.begins_with("correction:") and not _fields.is_empty() and _draft.active:
			var route := _detail.trim_prefix("correction:")
			if not _correction_current(route):
				_detail_pending = true
			else:
				for field in _fields:
					field.sync_draft_value(_draft.value(field._field))
		elif _detail.begins_with("item:") and not _fields.is_empty() and owner() and _edit_item:
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
	_roll_workflow.abandon()
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
	if _detail == "roll" and route != "roll":
		_leave_roll()
	_capture_detail()
	_detail = route
	_edit_item = false
	_fields.clear()
	_detail_pending = true

func _render_detail() -> void:
	if _detail == "roll":
		_render_roll()
		return
	if _detail == "health":
		_render_health()
		return
	if _detail.begins_with("correction:"):
		_render_correction()
		return
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

func _item_field(key: String, value: String, independent: bool, title: String = "", multiline: bool = false) -> void:
	var field: FIELD_SCRIPT = FIELD.instantiate()
	sheet.reader_content().add_child(field)
	field.configure(key, locale.text(title if not title.is_empty() else key.replace("_", " ").capitalize()), value, multiline or key == "rules", independent)
	field.configure_layout(sheet.size.x <= 900)
	field.get_node("Save").text = locale.text("Save") + " " + locale.text(key.capitalize())
	field.submitted.connect(_save_field)
	field.changed.connect(_custom_typed)
	_fields.append(field)

func _custom_typed(key: String, value: String) -> void:
	if _detail == "custom":
		_new_item[key] = value
	elif _detail.begins_with("correction:"):
		_draft_typed(key, value)

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
	_health_feedback = ""
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
	_health_feedback = ""
	var id := actor.id
	var epoch := _portrait_epoch
	_portrait_pending = true
	_portrait_feedback = ""
	_correction_feedback = ""
	_portrait_feedback = "Choosing portrait…"
	_busy = true
	_refresh()
	sheet.status(_portrait_feedback)
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
	_health_feedback = ""
	_portrait_pending = true
	_portrait_feedback = ""
	_correction_feedback = ""
	_busy = true
	_refresh()
	await _save_portrait(actor.id, PackedByteArray(), _portrait_epoch)

func _save_portrait(id: SDK.ActorId, image: PackedByteArray, epoch: int) -> void:
	_portrait_feedback = "Saving portrait…"
	sheet.status(_portrait_feedback)
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
	if _detail == "roll":
		_leave_roll()
	_capture_detail()
	_detail = ""
	_edit_item = false
	_fields.clear()
	_remember()

func _chapter_changed(_chapter: int) -> void:
	if _detail == "roll":
		_leave_roll()
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
	_roll_workflow.closed()
	_end_portrait()
	_end_health()
	_correction_epoch += 1
	_correction_feedback = ""
	_remember()
	_draft.discard()
	_validation = {}
	sheet.configure_draft({}, false)
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
	if not owner() or _busy or _draft.active or _roll_live():
		return
	_health_feedback = ""
	_portrait_feedback = ""
	_busy = true
	var id := actor.id.value
	var epoch := _correction_epoch
	sheet.status("Preparing corrections…")
	var result := await ITEMS.new(sdk, actor.id).prepare_corrections()
	_busy = false
	if actor == null or actor.id.value != id or epoch != _correction_epoch:
		return
	if not result.ok:
		sheet.status(result.message)
		return
	actor = result.actor
	var data: Dictionary = result.actor.data
	_draft.begin(_projection.fields(data), _projection.identities(data))
	_validation = {}
	_correction_feedback = ""
	_detail = ""
	sheet.back()
	_refresh()
	_open_correction("core")
	correction_requested.emit()
func _health() -> void:
	if not owner() or _busy or _roll_live():
		return
	if _draft.active:
		_open_correction("core")
	else:
		_health_feedback = ""
		_health_attempt = {}
		_portrait_feedback = ""
		_correction_feedback = ""
		_health_editor = null
		_open_detail("health")
		health_adjustment_requested.emit()
func _roll(part: String, id: String) -> void:
	if not can_roll():
		return
	_roll_feedback = ""
	_detail = "roll"
	_detail_pending = true
	_render_pending = true
	gameplay_roll_requested.emit(part, id)
	await _roll_workflow.start(actor.id.value, part, id)

## Accepted HP and transient presentation guards are shared with own-test followups.
func is_dead() -> bool:
	return HEALTH.new().is_dead(current_data())

func can_roll() -> bool:
	return owner() and not _busy and not _draft.active and not _roll_live() and HEALTH.new().can_roll(current_data())

func _roll_live() -> bool:
	return _roll_workflow.pending

func _roll_changed() -> void:
	_roll_refresh_pending = true

func _render_roll() -> void:
	if not _roll_workflow.has_action or actor == null or actor.id.value != _roll_workflow.source:
		return
	var choice: Dictionary = _roll_workflow.snapshot.get("choice", {})
	sheet.open_roll_reader(str(choice.get("label", "Creature roll")), str(choice.get("part", "")), str(choice.get("entry", "")))
	_text(str(choice.get("name", "")))
	if choice.has("formula"):
		_text(locale.text("Formula") + ": " + str(choice.formula))
	_text(_roll_workflow.summary())
	if _roll_workflow.pending:
		_text("Back cancels unfinished dice. Close preserves a running Roll.")
	else:
		_option("Done", sheet.back, true)

func _leave_roll() -> void:
	var unfinished := _roll_live()
	_roll_workflow.abandon()
	if unfinished:
		_roll_feedback = _roll_workflow.message
		sheet.status(_roll_feedback)

func _render_health() -> void:
	if not is_instance_valid(_health_editor):
		_health_editor = sheet.open_health_reader()
		_health_editor.configure(locale, sheet.size.x <= 900)
		_health_editor.adjustment_requested.connect(_adjust_health)
		_health_editor.correction_requested.connect(_correct)
	_health_editor.refresh(current_data(), owner(), _health_pending)

func _adjust_health(operation: String, amount: String) -> void:
	if not owner() or _busy or _draft.active or _detail != "health":
		return
	var id := actor.id
	var epoch := _health_epoch
	var actions := ITEMS.new(sdk, id)
	var request := REQUEST.new(sdk, self)
	if str(_health_attempt.get("operation", "")) != operation or str(_health_attempt.get("amount", "")) != amount:
		_health_attempt = {"id": sdk.dice.new_request_id(), "operation": operation, "amount": amount}
	var action_id := str(_health_attempt.get("id", ""))
	_busy = true
	_health_pending = true
	_health_feedback = "Saving HP…"
	_refresh()
	_health_editor.refresh(current_data(), owner(), true)
	var result := await actions.adjust_health(action_id, operation, amount, request)
	if epoch != _health_epoch or actor == null or actor.id.value != id.value:
		return
	_busy = false
	_health_pending = false
	if result.ok:
		_health_attempt = {}
		actor = result.actor
		_detail = ""
		sheet.back()
	_health_feedback = "Hit points updated." if result.ok else result.message
	_refresh_pending = true
	_refresh()
	if not result.ok and is_instance_valid(_health_editor):
		_health_editor.refresh(current_data(), owner(), false)
		_health_editor.show_error(result.message, actions.invalid_field)

func _end_health() -> void:
	_health_epoch += 1
	if _health_pending:
		_busy = false
	_health_pending = false
	_health_editor = null
	_health_feedback = ""
	_health_attempt = {}

func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and not _busy and event.is_action_pressed("ui_cancel"):
		if get_node("MiniatureWorkflow").visible:
			get_node("MiniatureWorkflow")._cancel()
		elif _draft.active:
			_cancel_edit()
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
	return _busy or _roll_live()

## Follow-up HP/roll adapters must use accepted current_data(), and guard this mode.
func editing_sheet() -> bool:
	return _draft.active

func draft_value(field: String) -> String:
	return _draft.value(field)

func change_draft(field: String, text: String) -> void:
	_draft_typed(field, text)

func _draft_typed(field: String, text: String) -> void:
	if not _draft.active or _busy:
		return
	_draft.change(field, text)
	_validation = {}
	_correction_feedback = ""
	sheet.sync_draft_field(field, text)
	for control in _fields:
		if control._field == field and _detail.begins_with("correction:"):
			control.sync_draft_value(text)

func _open_correction(route: String) -> void:
	if not _draft.active or not owner() or _busy:
		return
	_capture_detail()
	_correction_identity = str(_draft.identities().get(route, route))
	_open_detail("correction:" + route)

func _correction_current(route: String) -> bool:
	return _draft.active and (route == "core" or route == "rules" and _draft.values().has("rules") or _correction_identity == str(_draft.identities().get(route, "")))

func _render_correction() -> void:
	if actor == null:
		return
	var route := _detail.trim_prefix("correction:")
	var page: Dictionary = _detail_pages.get(_detail, {})
	if not _fields.is_empty():
		page = sheet.reader_state()
	_fields.clear()
	sheet.open_reader("Core values" if route == "core" else "Creature rules" if route.begins_with("rule") else "Attack", "", _correction_identity)
	if not _correction_current(route):
		_text("This entry was removed or replaced. Its obsolete corrections were discarded.")
	else:
		var values := _draft.values()
		var printed := _projection.printed_routes(current_data())
		for key in values.keys():
			var field := str(key)
			if route == "core":
				if field.begins_with("attack:") or field.begins_with("rule:") or field.begins_with("printed:") or field == "rules":
					continue
			elif field != route and not field.begins_with(route + ":") and str(printed.get(field, "")) != route:
				continue
			var member := str(field.split(":")[-1])
			var title := _projection.title(field if route == "core" else member)
			if field.begins_with("printed:"):
				title = "Printed dice formula"
			_item_field(field, _draft.value(field), false, title, member in ["rules", "text"])
	sheet.restore_reader(page)
	if str(_validation.get("route", "")) == route:
		for field in _fields:
			if field._field == str(_validation.get("field", "")):
				field.show_error(locale.text(str(_validation.get("message", ""))))

func _save_sheet() -> void:
	if not _draft.active or not owner() or _busy:
		return
	_correction_pending(true)
	var id := actor.id.value
	var epoch := _correction_epoch
	sheet.status("Saving sheet…")
	var actions := ITEMS.new(sdk, actor.id)
	var result := await actions.correct_many(_draft.changes(), _draft.identities())
	_correction_pending(false)
	if actor == null or actor.id.value != id or epoch != _correction_epoch:
		return
	if result.ok:
		_draft.discard()
		_validation = {}
		actor = result.actor
		if _detail.begins_with("correction:"):
			_detail = ""
			_fields.clear()
			sheet.back()
		_refresh()
		_correction_feedback = "Sheet saved."
		sheet.status(_correction_feedback)
	else:
		# Refresh accepted untouched fields even when validation or Authority rejects Save.
		request_refresh()
		_correction_feedback = result.message
		sheet.status(_correction_feedback)
		var field := actions.invalid_field
		if not field.is_empty():
			var parts := field.split(":")
			var route := str(_projection.printed_routes(current_data()).get(field, "")) if field.begins_with("printed:") else parts[0] + ":" + parts[1] if parts.size() == 3 else "rules" if field == "rules" else "core"
			_validation = {"route": route, "field": field, "message": result.message}
			_open_correction(route)

func _cancel_edit() -> void:
	if _busy or not _draft.active:
		return
	_draft.discard()
	_validation = {}
	_correction_feedback = ""
	if _detail.begins_with("correction:"):
		_detail = ""
		_fields.clear()
		sheet.back()
	var result := sdk.actors.read(actor.id)
	if result.ok and result.actor != null:
		actor = result.actor
	_refresh()
	sheet.status("")

func _correction_pending(pending: bool) -> void:
	_busy = pending
	sheet.correction_pending(pending)
	for field in _fields:
		field.get_node("Value").editable = not pending
		field.get_node("Text").editable = not pending
