extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
var _created_actor_id := ""
var _created_actor_data: Dictionary = {}
@onready var _creator := get_node(^"CharacterCreator")
@onready var _view := get_node(^"CharacterCreator/View")
@onready var _restart_dialog := get_node(^"RestartDialog")

func ready() -> void:
	if sdk == null:
		return
	_creator.primary_changed.connect(_view.present_primary)
	_creator.status_changed.connect(_view.set_status)
	_creator.character_created.connect(_created)
	_view.primary_requested.connect(_primary)
	_view.back_requested.connect(_creator.back)
	_view.restart_requested.connect(_restart)
	_view.close_requested.connect(_close)
	_restart_dialog.confirmed.connect(_creator.start_over)
	visibility_changed.connect(_reopened)
	var definitions := sdk.content.list(SDK.ContentKind.Value.ACTOR_DEFINITION)
	if not definitions.ok:
		_view.set_status(definitions.message, true)
		return
	var default_definition: SDK.ContentEntry
	for entry in definitions.items:
		if entry.reference.local_id == "classless-character":
			default_definition = entry
	var miniatures := sdk.content.list(SDK.ContentKind.Value.MINIATURE)
	var available: Array[SDK.ContentEntry] = []
	if miniatures.ok:
		available = miniatures.items
	_creator.configure(definitions.items, default_definition, available, false, sdk)
	_creator.begin()

func _primary() -> void:
	if not _created_actor_id.is_empty():
		_open_created()
	else:
		_creator.primary()

func _reopened() -> void:
	if is_visible_in_tree() and sdk != null and not _creator.is_active() and _created_actor_id.is_empty():
		_creator.begin()

func capture_reconnect_state() -> Variant:
	return {"created_actor_id": _created_actor_id, "created_actor_data": _created_actor_data.duplicate(true)} if not _created_actor_id.is_empty() else _creator.capture_reconnect_state()

func restore_reconnect_state(state: Dictionary) -> void:
	_created_actor_id = str(state.get("created_actor_id", ""))
	if _created_actor_id.is_empty():
		_creator.restore_reconnect_state(state)
		return
	_creator.discard()
	var retained: Dictionary = state.get("created_actor_data", {})
	_created_actor_data = retained.duplicate(true)
	_view.present_creation("create-review", _created_actor_data, false)
	_view.set_status(sdk.translations.text("Character created."))
	_view.present_primary(sdk.translations.text("Open character"), false)
	_view.set_back_enabled(false)

func _restart() -> void:
	if _restart_dialog.visible or not _creator.is_active():
		return
	_restart_dialog.heading = sdk.translations.text("Start over")
	_restart_dialog.description = sdk.translations.text("Discard this unfinished Character and start again?")
	_restart_dialog.confirm_label = sdk.translations.text("Start over")
	_restart_dialog.cancel_label = sdk.translations.text("Cancel")
	_restart_dialog.open_dialog()

func _created(actor: SDK.Actor) -> void:
	_created_actor_id = actor.id.value
	_created_actor_data = actor.data.duplicate(true)
	_open_created()

func _open_created() -> void:
	var result := sdk.windows.open_actor(preload(ROOT + "ui/character_surface.tres"), SDK.ActorId.new(_created_actor_id))
	if not result.ok:
		_view.set_status(result.message, true)
		_view.present_primary(sdk.translations.text("Open character"), false)
		return
	_close()
	_created_actor_id = ""
	_created_actor_data = {}

func _close() -> void:
	var surface := SDK.ExtensionSurface.new()
	surface.scene = load(ROOT + "ui/character_creation_window.tscn")
	sdk.windows.close(surface)

func _exit_tree() -> void:
	if _creator != null:
		_creator.discard()
