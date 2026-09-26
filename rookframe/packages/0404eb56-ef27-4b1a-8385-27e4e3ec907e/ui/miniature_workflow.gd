extends VBoxContainer
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const I18N = preload(ROOT + "ui/localization.gd")
const ACTIONS = preload(ROOT + "logic/miniature_actions.gd")
signal closed(saved: bool)
var sdk: SDK
var i18n := I18N.new()
var _actor: SDK.ActorId
var _definition := ""
var _busy := false
var _saved: Dictionary = {}
@onready var browser = get_node(^"Browser")

func _ready() -> void:
	browser.selection_changed.connect(_selected)
	browser.preview_requested.connect(_preview)
	browser.retry_requested.connect(_load)
	get_node(^"Actions/Back").pressed.connect(_cancel)
	get_node(^"Actions/Apply").pressed.connect(_apply)

func open(facade: SDK, locale: I18N, actor: SDK.ActorId, definition: String, saved: Dictionary) -> void:
	sdk = facade
	i18n = locale
	_actor = actor
	_definition = definition
	_saved = saved.duplicate(true)
	visible = true
	get_node(^"Title").text = _t("Miniature for new Actors" if actor == null else "Miniature for this Creature")
	get_node(^"Actions/Back").text = _t("Back")
	get_node(^"Actions/Apply").text = _t("Use Miniature")
	_load()
	browser.focus_search()

func _load() -> void:
	browser.set_state("loading", _t("Loading Miniatures…"))
	get_node(^"Actions/Apply").disabled = true
	get_node(^"Status").text = ""
	var result := sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	if not result.ok:
		browser.set_state("error", _t("Could not load Miniatures. Try again."))
		return
	var entries: Array[Dictionary] = []
	for entry in result.items:
		entries.append({"id": entry.reference.package_id + "/" + entry.reference.local_id,
			"title": entry.localized_title, "package": entry.package_title if not entry.package_title.is_empty() else entry.reference.package_id,
			"package_id": entry.reference.package_id, "local_id": entry.reference.local_id, "available": entry.available})
	var id := str(_saved.get("package_id", "")) + "/" + str(_saved.get("local_id", ""))
	browser.configure(entries, id, {"search": _t("Search Miniatures"), "retry": _t("Try again"), "unavailable": _t("Unavailable"), "empty": _t("Add a Miniature Package to this World."), "no_match": _t("No matching Miniatures.")})
	_selected(browser.selection())
	if not _saved.is_empty() and browser.selection().is_empty():
		get_node(^"Status").text = _t("Saved Miniature unavailable. Choose a replacement.")

func _preview(entry: Dictionary, target: Control) -> void:
	var result := sdk.content.preview_miniature(SDK.ContentReference.new(str(entry.package_id), str(entry.local_id)), target)
	if not result.ok:
		get_node(^"Status").text = _t("Miniature preview unavailable.")

func _selected(entry: Dictionary) -> void:
	get_node(^"Actions/Apply").disabled = _busy or entry.is_empty()

func _apply() -> void:
	if _busy or browser.selection().is_empty():
		return
	var entry: Dictionary = browser.selection()
	var reference := {"package_id": str(entry.package_id), "local_id": str(entry.local_id)}
	_busy = true
	get_node(^"Actions/Apply").disabled = true
	get_node(^"Actions/Back").disabled = true
	get_node(^"Status").text = _t("Saving Miniature…")
	var message := ""
	if _actor == null:
		var result := await sdk.system_actions.submit("miniature.default", {"definition": _definition, "package_id": reference.package_id, "local_id": reference.local_id})
		if not result.ok:
			message = result.message
		elif str(result.value.get("state", "error")) != "resolved":
			message = str(result.value.get("message", "Could not save. Try again."))
	else:
		var result := await ACTIONS.new(sdk).set_actor(_actor, reference)
		if not result.ok:
			message = result.message
	_busy = false
	get_node(^"Actions/Back").disabled = false
	_selected(browser.selection())
	if not message.is_empty():
		get_node(^"Status").text = _t(message)
		return
	visible = false
	closed.emit(true)

func _cancel() -> void:
	if not _busy:
		visible = false
		closed.emit(false)

func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel") and not _busy:
		_cancel()
		accept_event()

func _t(source: String) -> String:
	return i18n.text(source)
