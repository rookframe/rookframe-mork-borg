extends MarginContainer

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const I18N = preload(ROOT + "ui/localization.gd")

signal closed
signal selected(reference: Dictionary)
var sdk: SDK
var i18n: I18N
var _saved: Dictionary = {}
@onready var browser := get_node(^"Picker")

func _ready() -> void:
	browser.choose_requested.connect(_choose)
	browser.cancel_requested.connect(_cancel)
	browser.close_requested.connect(_cancel)
	browser.retry_requested.connect(_load)
	browser.preview_requested.connect(_preview)

func open(facade: SDK, locale: I18N, saved: Dictionary) -> void:
	sdk = facade
	i18n = locale
	_saved = saved.duplicate(true)
	_load()
	browser.focus_search()

func _load() -> void:
	browser.set_state("loading")
	var result := sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	if not result.ok:
		browser.set_state("error", i18n.text("Could not load Miniatures. Try again."))
		return
	var entries: Array[Dictionary] = []
	for entry in result.items:
		entries.append({"id": entry.reference.package_id + "/" + entry.reference.local_id,
			"title": entry.localized_title, "package": entry.package_title,
			"package_id": entry.reference.package_id, "local_id": entry.reference.local_id, "available": entry.available})
	var id := str(_saved.get("package_id", "")) + "/" + str(_saved.get("local_id", ""))
	if not _saved.is_empty():
		var current := sdk.content.read(SDK.ContentReference.new(str(_saved.get("package_id", "")), str(_saved.get("local_id", ""))))
		if current.ok:
			id = current.content_entry.reference.package_id + "/" + current.content_entry.reference.local_id
		var found := false
		for entry in entries:
			if str(entry.id) == id:
				found = true
		if not found:
			entries.append({"id": id, "title": str(_saved.get("title", i18n.text("Unavailable"))), "package": "", "available": false})
	var labels: Dictionary = {}
	for pair in [["search", "Search by name or Package"], ["retry", "Try again"], ["unavailable", "Unavailable"], ["cancel", "Cancel"], ["choose", "Choose"], ["title", "Choose a miniature"], ["previous", "Previous"], ["next", "Next"], ["selection", "Selected miniature"]]:
		labels[pair[0]] = i18n.text(pair[1])
	labels["find"] = i18n.text("Find miniature")
	labels["library"] = i18n.text("Character creation")
	labels["empty_preview"] = i18n.text("No miniature assigned")
	labels["no_match"] = i18n.text("No matching Miniatures.")
	labels["empty"] = i18n.text("No Miniatures in this World.")
	browser.configure(entries, id, labels)

func _preview(entry: Dictionary, target: Control) -> void:
	sdk.content.preview_miniature(SDK.ContentReference.new(str(entry.package_id), str(entry.local_id)), target)

func _choose(entry: Dictionary) -> void:
	selected.emit({"package_id": str(entry.package_id), "local_id": str(entry.local_id), "title": str(entry.title)})
	sdk.windows.pop(self)

func _cancel() -> void:
	sdk.windows.pop(self)
