extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
var _restart_requested := false
var _created_actor: SDK.Actor
@onready var _creator := get_node(^"CharacterCreator")
@onready var _view := get_node(^"CharacterCreator/View")

func ready() -> void:
	if sdk == null:
		return
	_creator.primary_changed.connect(_view.set_primary)
	_creator.status_changed.connect(_view.set_status)
	_creator.character_created.connect(_created)
	_view.primary_requested.connect(_primary)
	_view.back_requested.connect(_creator.back)
	_view.restart_requested.connect(_restart)
	_view.close_requested.connect(_close)
	sdk.feedback.action_selected.connect(_restart_answered)
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
	_creator.configure(definitions.items, default_definition, miniatures.items if miniatures.ok else [], false, sdk)
	_creator.begin()

func _primary() -> void:
	if _created_actor != null:
		_open_created()
	else:
		_creator.primary()

func _reopened() -> void:
	if is_visible_in_tree() and sdk != null and not _creator.is_active() and _created_actor == null:
		_creator.begin()

func capture_reconnect_state() -> Variant:
	return _creator.capture_reconnect_state()

func restore_reconnect_state(state: Dictionary) -> void:
	_creator.restore_reconnect_state(state)

func _restart() -> void:
	if _restart_requested or not _creator.is_active():
		return
	_restart_requested = true
	var message := SDK.FeedbackMessage.new()
	message.title = sdk.translations.text("Start over")
	message.message = sdk.translations.text("Discard this unfinished Character and start again?")
	for option in [["restart-character", "Start over"], ["keep-character", "Cancel"]]:
		var action := SDK.FeedbackAction.new()
		action.id = option[0]
		action.title = sdk.translations.text(option[1])
		message.actions.append(action)
	sdk.feedback.confirm(message)

func _restart_answered(action: String) -> void:
	if not _restart_requested or not action in ["restart-character", "keep-character"]:
		return
	_restart_requested = false
	if action == "restart-character":
		_creator.start_over()

func _created(actor: SDK.Actor) -> void:
	_created_actor = actor
	_open_created()

func _open_created() -> void:
	var entry: SDK.WindowButton = load(ROOT + "ui/window_button_desktop.tres") if sdk.presentation_experience().is_desktop else load(ROOT + "ui/window_button.tres")
	var result := sdk.windows.open_actor(entry.window, _created_actor.id)
	if not result.ok:
		_view.set_status(result.message, true)
		_view.set_primary(sdk.translations.text("Open character"), false)
		return
	_close()
	_created_actor = null

func _close() -> void:
	var surface := SDK.ExtensionSurface.new()
	surface.scene = load(ROOT + "ui/character_creation_window.tscn")
	sdk.windows.close(surface)

func _exit_tree() -> void:
	if _creator != null:
		_creator.discard()
