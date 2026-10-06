extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const I18N = preload(ROOT + "ui/localization.gd")
const PORTRAIT_CACHE = preload(ROOT + "ui/creature_portrait_cache.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const CONTENT = preload(ROOT + "logic/creature_content.gd")
const LIBRARY = preload(ROOT + "ui/creature_library.gd")
var i18n := I18N.new()
var _definition: SDK.ContentReference
var _busy := false
var _portrait_epoch := 0
var _appearance_session := ""
var _world: Dictionary = {}
var _world_error := ""
var _portrait_cache := PORTRAIT_CACHE.new()

@onready var _miniature_picker := get_node(^"MiniatureWorkflow")

func ready() -> void:
	if sdk == null:
		return
	i18n.bind(sdk)
	var sheet = get_node("Sheet")
	sheet.create_requested.connect(_queue_create)
	sheet.close_requested.connect(_close)
	sheet.miniature_requested.connect(_choose)
	sheet.miniature_clear_requested.connect(_clear)
	sheet.portrait_requested.connect(_choose_portrait)
	sheet.portrait_reset_requested.connect(_reset_portrait)
	sheet.publication_requested.connect(_publication)
	sheet.chapter_changed.connect(_chapter_changed)
	_miniature_picker.closed.connect(_miniature_closed)
	if not sdk.world_changed.is_connected(_refresh):
		sdk.world_changed.connect(_refresh)
	closed.connect(_closed)

func opened_definition(definition: SDK.ContentReference) -> void:
	_end_appearance()
	_definition = definition
	if _appearance_session != sdk.context().session_id:
		_portrait_cache.clear()
	_appearance_session = sdk.context().session_id
	_world = {}
	get_node("Sheet").visible = true
	_miniature_picker.discard()
	_refresh()

func _refresh() -> void:
	if _definition == null or sdk == null:
		return
	if sdk.context().session_id != _appearance_session:
		_end_appearance()
		get_node("Sheet").status("This session has ended.")
		return
	_read_defaults()
	var found := sdk.content.read(_definition)
	if not found.ok:
		get_node("Sheet").status(found.message)
		return
	var source = CREATURES.new()
	source.resource_name = _definition.local_id
	var data: Dictionary = source.create_data({})
	var metadata := CONTENT.new().details(_definition.local_id)
	for key in ["classification", "rule_groups", "reference", "source"]:
		data[key] = metadata.get(key, data.get(key))
	data.name = found.content_entry.localized_title
	get_node("Sheet").configure(data, i18n, true, not _busy and _world_error.is_empty() and sdk.context().is_gm and found.content_entry.available, _portrait())
	if not _world_error.is_empty():
		get_node("Sheet").status(_world_error)
	elif not _portrait_cache.message.is_empty():
		get_node("Sheet").status(_portrait_cache.message)
	_refresh_appearance.call_deferred()

func _refresh_appearance() -> void:
	if _definition == null or sdk == null or not _world_error.is_empty():
		return
	var reference := _miniature()
	var content := sdk.content.read(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))))
	var sheet = get_node("Sheet")
	sheet.miniature(content.content_entry.localized_title if content.ok else i18n.text("Saved Miniature unavailable. Choose a replacement."), content.content_entry.package_title if content.ok else "", not reference.is_empty())
	if not reference.is_empty():
		# Both authored targets retain the selected Miniature independently of
		# which chapter/form factor currently displays them.
		var content_reference := SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", "")))
		var result := sdk.content.preview_miniature(content_reference, sheet.miniature_preview_target())
		var summary := sdk.content.preview_miniature(content_reference, sheet.miniature_summary_preview_target())
		if not result.ok:
			sheet.status(result.message)
		elif not summary.ok:
			sheet.status(summary.message)

func _miniature() -> Dictionary:
	var defaults: Dictionary = _world.get("creature_miniatures", {})
	var id := str(_definition.local_id)
	if defaults.has(id):
		var reference: Dictionary = defaults.get(id, {})
		return reference.duplicate(true)
	return CREATURES.new().default_miniature(id)

func _queue_create() -> void:
	# Leave the shared sheet's signal stack before the live window reloads it.
	# https://docs.godotengine.org/en/stable/classes/class_callable.html#class-callable-method-call-deferred
	_create.call_deferred()

func _create() -> void:
	if _busy or not _can_edit():
		return
	var definition := _definition.local_id
	var epoch := _portrait_epoch
	_busy = true
	_refresh()
	var result := await LIBRARY.new(sdk).create(_definition, null, Vector2(0, 0), false)
	if not _appearance_current(definition, epoch):
		return
	_busy = false
	get_node("Sheet").status("Actor created." if result.ok else result.message)
	_refresh()
	if result.ok and _can_edit():
		sdk.windows.open_actor(preload(ROOT + "ui/creature_surface.tres"), result.actor.id)

func _choose() -> void:
	if _busy or not _can_edit():
		return
	var picker := _miniature_picker
	var result := sdk.windows.push(self, picker, i18n.text("Choose Miniature"))
	if not result.ok:
		get_node("Sheet").status(result.message)
		return
	picker.open(sdk, i18n, null, _definition.local_id, _miniature())

func _miniature_closed() -> void:
	get_node("Sheet").status("")
	_refresh()
	get_node("Sheet").focus_miniature.call_deferred()

func _closed() -> void:
	_end_appearance()
	_miniature_picker.discard()

func _portrait() -> Texture2D:
	var defaults: Dictionary = _world.get("creature_portraits", {})
	var value: Variant = defaults.get(str(_definition.local_id), "")
	return _portrait_cache.resolve(value, sdk.portraits)

func _choose_portrait() -> void:
	if _busy or not _can_edit():
		return
	var definition := _definition.local_id
	var expected := _default_portrait_choice()
	var epoch := _portrait_epoch
	_busy = true
	_refresh()
	get_node("Sheet").status("Choosing portrait…")
	var selected := await sdk.portraits.choose()
	if not _appearance_current(definition, epoch):
		return
	if not selected.ok:
		_busy = false
		if selected.code == "cancelled":
			get_node("Sheet").status("")
		_refresh()
		get_node("Sheet").focus_portrait.call_deferred()
		if selected.code != "cancelled":
			get_node("Sheet").status(selected.message)
		return
	if not _can_edit():
		_end_appearance()
		get_node("Sheet").status("Appearance is no longer editable.")
		_refresh()
		return
	await _save_portrait(definition, selected.path, expected, epoch)

func _reset_portrait() -> void:
	if _busy or not _can_edit():
		return
	var expected := _default_portrait_choice()
	_busy = true
	_refresh()
	await _save_portrait(_definition.local_id, "", expected, _portrait_epoch)

func _save_portrait(definition: String, path: String, expected: Dictionary, epoch: int) -> void:
	get_node("Sheet").status("Saving portrait…")
	var result := await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": definition, "path": path, "expected": expected.path, "expected_revision": expected.revision})
	if not _appearance_current(definition, epoch):
		return
	_busy = false
	_refresh()
	var outcome: Dictionary = result.value if result.ok else {}
	get_node("Sheet").status(str(outcome.get("message", "")) if result.ok else result.message)
	get_node("Sheet").focus_portrait.call_deferred()

func _end_appearance() -> void:
	_portrait_epoch += 1
	_busy = false

func _clear() -> void:
	if _busy or not _can_edit():
		return
	var definition := _definition.local_id
	var epoch := _portrait_epoch
	_busy = true
	_refresh()
	get_node("Sheet").status("Saving Miniature…")
	var result := await sdk.system_actions.submit("miniature.default", {"definition": definition, "package_id": "", "local_id": ""})
	if not _appearance_current(definition, epoch):
		return
	var outcome: Dictionary = result.value if result.ok else {}
	_busy = false
	_refresh()
	get_node("Sheet").status(result.message if not result.ok else str(outcome.get("message", "")))
	get_node("Sheet").focus_miniature.call_deferred()

func _publication(url: String) -> void:
	var result := await sdk.browser.open(url)
	if not result.ok:
		get_node("Sheet").status(result.message)

func _close() -> void:
	_end_appearance()
	var surface := SDK.ExtensionSurface.new()
	surface.scene = load(ROOT + "ui/creature_definition_sheet.tscn")
	sdk.windows.close(surface)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and _miniature_picker.visible and event.is_action_pressed("ui_cancel"):
		_miniature_picker._cancel()
		accept_event()

func _chapter_changed(_chapter: int) -> void:
	_refresh_appearance()

func _default_portrait_choice() -> Dictionary:
	var defaults: Dictionary = _world.get("creature_portraits", {})
	var revisions: Dictionary = _world.get("creature_portrait_revisions", {})
	return {"path": str(defaults.get(str(_definition.local_id), "")), "revision": int(revisions.get(str(_definition.local_id), 0))}

func _read_defaults() -> void:
	var saved := sdk.world_data.read()
	_world_error = ""
	if not saved.ok:
		_world_error = saved.message
		return
	if saved.value != null and typeof(saved.value) != TYPE_DICTIONARY:
		_world_error = "Appearance defaults are unavailable."
		return
	var world: Dictionary = {} if saved.value == null else saved.value.duplicate(true)
	if not _valid_defaults(world, _definition.local_id):
		_world_error = "Appearance defaults are unavailable."
		return
	_world = world.duplicate(true)

func _valid_defaults(world: Dictionary, id: String) -> bool:
	for key in ["creature_miniatures", "creature_portraits", "creature_portrait_revisions"]:
		if not world.has(key):
			continue
		var values: Variant = world.get(key)
		if typeof(values) != TYPE_DICTIONARY:
			return false
		var choices: Dictionary = values
		if not choices.has(id):
			continue
		var choice: Variant = choices.get(id)
		if key == "creature_miniatures" and typeof(choice) != TYPE_DICTIONARY:
			return false
		if key == "creature_portraits" and typeof(choice) != TYPE_STRING:
			return false
		if key == "creature_portrait_revisions" and typeof(choice) != TYPE_INT:
			return false
	return true

func _can_edit() -> bool:
	if _definition == null or not sdk.context().is_gm or sdk.context().session_id != _appearance_session:
		return false
	_read_defaults()
	if not _world_error.is_empty():
		get_node("Sheet").status(_world_error)
		return false
	var found := sdk.content.read(_definition)
	return found.ok and found.content_entry.available

func _appearance_current(definition: String, epoch: int) -> bool:
	return epoch == _portrait_epoch and _definition != null and _definition.local_id == definition and sdk.context().session_id == _appearance_session
