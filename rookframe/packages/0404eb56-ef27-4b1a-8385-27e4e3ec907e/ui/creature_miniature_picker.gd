extends MarginContainer
## Immediate Appearance choice in a retained SDK child surface.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const ACTIONS = preload(ROOT + "logic/miniature_actions.gd")
const NONE_PREVIEW = preload(ROOT + "ui/creature_miniature_none.tscn")
signal closed
var sdk: SDK
var i18n: I18N
var _actor: SDK.ActorId
var _definition := ""
var _saved: Dictionary = {}
var _session := ""
var _epoch := 0
var _active := false
var _busy := false
@onready var browser := get_node(^"Picker")

func _ready() -> void:
	browser.choose_requested.connect(_choose)
	browser.cancel_requested.connect(_cancel)
	browser.close_requested.connect(_cancel)
	browser.retry_requested.connect(_load)
	browser.preview_requested.connect(_preview)
	closed.connect(discard)

func open(facade: SDK, locale: I18N, actor: SDK.ActorId, definition: String, saved: Dictionary) -> void:
	discard()
	sdk = facade
	i18n = locale
	_actor = actor
	_definition = definition
	_saved = saved.duplicate(true)
	_session = sdk.context().session_id
	_active = true
	if not sdk.world_changed.is_connected(_world_changed):
		sdk.world_changed.connect(_world_changed)
	_load()
	browser.focus_search()

func discard() -> void:
	_epoch += 1
	_active = false
	_busy = false

func _allowed() -> bool:
	if sdk.context().session_id != _session:
		return false
	if _actor == null:
		var definition := sdk.content.read(SDK.ContentReference.new(sdk.package_id(), _definition))
		return sdk.context().is_gm and definition.ok and definition.content_entry.available
	var found := sdk.actors.read(_actor)
	return found.ok and found.actor != null and found.actor.access_level == "Owner"

func _world_changed() -> void:
	if _active and not _allowed():
		discard()
		browser.set_state("error", i18n.text("Appearance is no longer editable. Close this picker."))

func _load() -> void:
	if not _active or _busy:
		return
	if not _allowed():
		_world_changed()
		return
	browser.set_state("loading", i18n.text("Loading Miniatures…"))
	var result := sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	if not result.ok:
		browser.set_state("error", result.message)
		return
	var entries: Array[Dictionary] = [{"id": "none", "title": i18n.text("None"), "package": "", "available": true}]
	for entry in result.items:
		entries.append({"id": entry.reference.package_id + "/" + entry.reference.local_id,
			"title": entry.localized_title, "package": entry.package_title,
			"package_id": entry.reference.package_id, "local_id": entry.reference.local_id, "available": entry.available})
	var id := "none" if _saved.is_empty() else str(_saved.get("package_id", "")) + "/" + str(_saved.get("local_id", ""))
	var found := _saved.is_empty()
	for entry in entries:
		if str(entry.id) == id:
			found = true
	if not found:
		entries.append({"id": id, "title": str(_saved.get("title", i18n.text("Saved Miniature unavailable"))), "package": "", "available": false})
	var labels: Dictionary = {}
	for pair in [["search", "Name or Package"], ["retry", "Try again"], ["unavailable", "Unavailable"], ["cancel", "Cancel"], ["choose", "Use Miniature"], ["title", "Tabletop miniature"], ["previous", "Previous"], ["next", "Next"], ["selection", "Selected miniature"], ["saved_unavailable", "Saved Miniature unavailable. Choose a replacement."], ["preview_unavailable", "Preview unavailable."]]:
		labels[pair[0]] = i18n.text(pair[1])
	if _actor == null:
		var found_definition := sdk.content.read(SDK.ContentReference.new(sdk.package_id(), _definition))
		labels["library"] = found_definition.content_entry.localized_title if found_definition.ok else ""
	else:
		var found_actor := sdk.actors.read(_actor)
		var owner: SDK.Actor = found_actor.actor
		var data: Dictionary = owner.data if found_actor.ok and owner != null else {}
		labels["library"] = str(data.get("name", ""))
	labels["none_copy"] = i18n.text("No saved miniature")
	labels["find"] = i18n.text("Find miniature")
	labels["empty_preview"] = i18n.text("No miniature assigned")
	labels["close"] = i18n.text("Close miniature browser")
	labels["count"] = i18n.text("%d miniatures")
	labels["range"] = i18n.text("%d–%d of %d")
	labels["loading"] = i18n.text("Loading Miniatures…")
	labels["loading_copy"] = i18n.text("Your selection will stay with you.")
	labels["error"] = i18n.text("Could not finish Miniature choice.")
	labels["error_copy"] = i18n.text("Try again, or cancel to return to the sheet.")
	labels["no_match"] = i18n.text("No matching Miniatures.")
	labels["no_match_copy"] = i18n.text("Try another name or Package.")
	labels["empty"] = i18n.text("No Miniatures in this World.")
	labels["empty_copy"] = i18n.text("Add a Miniature Package to this World.")
	labels["selected"] = i18n.text("Selected")
	labels["none"] = i18n.text("None")
	labels["hint"] = i18n.text("For new Actors only. Existing Actors and Rooks keep their appearance." if _actor == null else "Saved for this creature. Existing Rooks keep their current miniature.")
	browser.configure(entries, id, labels)

func _preview(entry: Dictionary, target: Control) -> void:
	if str(entry.get("id", "")) == "none":
		var empty := NONE_PREVIEW.instantiate()
		empty.text = i18n.text("No Miniature")
		target.add_child(empty)
	else:
		sdk.content.preview_miniature(SDK.ContentReference.new(str(entry.package_id), str(entry.local_id)), target)

func _choose(entry: Dictionary) -> void:
	if not _active or _busy or not _allowed():
		_world_changed()
		return
	var reference: Dictionary = {} if str(entry.id) == "none" else {"package_id": str(entry.package_id), "local_id": str(entry.local_id)}
	_saved = reference.duplicate(true)
	var epoch := _epoch
	_busy = true
	browser.set_state("loading", i18n.text("Saving Miniature…"))
	var message := ""
	if _actor == null:
		var result := await sdk.system_actions.submit("miniature.default", {"definition": _definition, "package_id": reference.get("package_id", ""), "local_id": reference.get("local_id", "")})
		if not result.ok:
			message = result.message
		elif str(result.value.get("state", "error")) != "resolved":
			message = str(result.value.get("message", "Could not save. Try again."))
	else:
		var result := await ACTIONS.new(sdk).set_actor(_actor, reference)
		if not result.ok:
			message = result.message
	if epoch != _epoch or not _active:
		return
	_busy = false
	if not _allowed():
		_world_changed()
		return
	if not message.is_empty():
		browser.set_state("error", message)
		return
	_cancel()

func _cancel() -> void:
	var result := sdk.windows.pop(self)
	if not result.ok:
		browser.set_state("error", result.message)
