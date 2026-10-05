extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const I18N = preload(ROOT + "ui/localization.gd")
const CREATURES = preload(ROOT + "logic/creature_definition.gd")
const CONTENT = preload(ROOT + "logic/creature_content.gd")
const LIBRARY = preload(ROOT + "ui/creature_library.gd")
var i18n := I18N.new()
var _definition: SDK.ContentReference
var _busy := false
var _portrait_pending := false
var _portrait_epoch := 0
var _portrait_image := PackedByteArray()
var _portrait_texture: Texture2D
var _portrait_error := ""

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
	get_node("MiniatureWorkflow").closed.connect(_miniature_closed)
	if not sdk.world_changed.is_connected(_refresh):
		sdk.world_changed.connect(_refresh)
	closed.connect(_end_portrait)

func opened_definition(definition: SDK.ContentReference) -> void:
	_end_portrait()
	_definition = definition
	get_node("Sheet").visible = true
	get_node("MiniatureWorkflow").visible = false
	_refresh()

func _refresh() -> void:
	if _definition == null or sdk == null:
		return
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
	get_node("Sheet").configure(data, i18n, true, not _busy and sdk.context().is_gm and found.content_entry.available, _portrait())
	if not _portrait_error.is_empty():
		get_node("Sheet").status(_portrait_error)
	_refresh_appearance.call_deferred()

func _refresh_appearance() -> void:
	if _definition == null or sdk == null:
		return
	var reference := _miniature()
	var content := sdk.content.read(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))))
	var sheet = get_node("Sheet")
	sheet.miniature(content.content_entry.localized_title if content.ok else i18n.text("Saved Miniature unavailable. Choose a replacement."), content.content_entry.package_title if content.ok else "", not reference.is_empty())
	if not reference.is_empty() and sheet.miniature_preview_target().is_visible_in_tree():
		var result := sdk.content.preview_miniature(SDK.ContentReference.new(str(reference.get("package_id", "")), str(reference.get("local_id", ""))), sheet.miniature_preview_target())
		if not result.ok:
			sheet.status(result.message)

func _miniature() -> Dictionary:
	var saved := sdk.world_data.read()
	var data: Dictionary = saved.value.duplicate(true) if saved.ok and typeof(saved.value) == TYPE_DICTIONARY else {}
	var defaults: Dictionary = data.get("creature_miniatures", {})
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
	if _busy or _definition == null:
		return
	_busy = true
	_refresh()
	var result := await LIBRARY.new(sdk).create(_definition)
	_busy = false
	get_node("Sheet").status("Actor created." if result.ok else result.message)
	_refresh()

func _choose() -> void:
	if _busy or not sdk.context().is_gm:
		return
	get_node("Sheet").visible = false
	get_node("MiniatureWorkflow").open(sdk, i18n, null, _definition.local_id, _miniature())
	get_node("MiniatureWorkflow/Actions/Back").text = i18n.text("Cancel")

func _miniature_closed(_saved: bool) -> void:
	get_node("Sheet").visible = true
	_refresh()
	get_node("Sheet").focus_miniature()

func _portrait() -> Texture2D:
	var saved := sdk.world_data.read()
	var world: Dictionary = saved.value if saved.ok and typeof(saved.value) == TYPE_DICTIONARY else {}
	var defaults: Dictionary = world.get("creature_portraits", {}) if typeof(world.get("creature_portraits", {})) == TYPE_DICTIONARY else {}
	var id := str(_definition.local_id)
	var value: Variant = defaults.get(id, PackedByteArray())
	var image: PackedByteArray = value if typeof(value) == typeof(PackedByteArray()) else PackedByteArray()
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
	if typeof(value) != typeof(PackedByteArray()):
		_portrait_error = "Portrait is unavailable. Choose a replacement."
	return _portrait_texture

func _choose_portrait() -> void:
	if _busy or _definition == null or not sdk.context().is_gm:
		return
	var definition := _definition.local_id
	var epoch := _portrait_epoch
	_portrait_pending = true
	_busy = true
	_refresh()
	get_node("Sheet").status("Choosing portrait…")
	var selected := await sdk.portraits.choose()
	if epoch != _portrait_epoch or _definition == null or _definition.local_id != definition:
		return
	if not selected.ok:
		_portrait_pending = false
		_busy = false
		_refresh()
		get_node("Sheet").focus_portrait.call_deferred()
		if selected.code != "cancelled":
			get_node("Sheet").status(selected.message)
		return
	await _save_portrait(definition, selected.image, epoch)

func _reset_portrait() -> void:
	if _busy or _definition == null or not sdk.context().is_gm:
		return
	_portrait_pending = true
	_busy = true
	_refresh()
	await _save_portrait(_definition.local_id, PackedByteArray(), _portrait_epoch)

func _save_portrait(definition: String, image: PackedByteArray, epoch: int) -> void:
	get_node("Sheet").status("Saving portrait…")
	var result := await sdk.system_actions.submit("creature-appearance.default-portrait", {"definition": definition, "image": image})
	if epoch != _portrait_epoch or _definition == null or _definition.local_id != definition:
		return
	_portrait_pending = false
	_busy = false
	_refresh()
	var outcome: Dictionary = result.value if result.ok else {}
	get_node("Sheet").status(str(outcome.get("message", "")) if result.ok else result.message)
	get_node("Sheet").focus_portrait.call_deferred()

func _end_portrait() -> void:
	_portrait_epoch += 1
	if _portrait_pending:
		_busy = false
	_portrait_pending = false

func _clear() -> void:
	if _busy or not sdk.context().is_gm:
		return
	_busy = true
	_refresh()
	var result := await sdk.system_actions.submit("miniature.default", {"definition": _definition.local_id, "package_id": "", "local_id": ""})
	var outcome: Dictionary = result.value if result.ok else {}
	get_node("Sheet").status(result.message if not result.ok else str(outcome.get("message", "")))
	_busy = false
	_refresh()

func _publication(url: String) -> void:
	var result := await sdk.browser.open(url)
	if not result.ok:
		get_node("Sheet").status(result.message)

func _close() -> void:
	_end_portrait()
	var surface := SDK.ExtensionSurface.new()
	surface.scene = load(ROOT + "ui/creature_definition_sheet.tscn")
	sdk.windows.close(surface)

func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and get_node("MiniatureWorkflow").visible and event.is_action_pressed("ui_cancel"):
		get_node("MiniatureWorkflow")._cancel()
		accept_event()

func _chapter_changed(_chapter: int) -> void:
	_refresh_appearance()
