extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

## The managed task owns its initiating Actor independently of HUD selection.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const RECOVERY = preload(ROOT + "logic/recovery_rules.gd")
var _actor: SDK.ActorId
@onready var _panel = get_node(^"Layout/Body/Panel")
@onready var _primary: Button = get_node(^"Layout/Actions/Primary")

func ready() -> void:
	get_node(^"Layout/Actions/Close").pressed.connect(_close)
	_primary.pressed.connect(_submit)
	_panel.action_created.connect(_action_created)
	_panel.navigate_requested.connect(_navigate)
	_panel.workflow_changed.connect(_workflow_changed)
	closed.connect(_closed)
	if sdk != null:
		get_node(^"Layout/Actions/Close").text = sdk.translations.text("Cancel")

func opened_task(actor: SDK.ActorId, task: Dictionary) -> void:
	if sdk == null or _panel.has_live_action():
		return
	var current := sdk.actors.read(actor)
	if not current.ok:
		_close()
		return
	var key := str(task.get("recovery", ""))
	if not RECOVERY.new().available(current.actor, sdk, key):
		_close()
		return
	_actor = actor
	get_node(^"Layout/Actor").text = str(current.actor.data.get("name", "Character"))
	_panel.configure_tabletop(current.actor, sdk, key)

func _action_created(action: Node) -> void:
	add_child(action)

func _workflow_changed(_route: String, title: String, can_submit: bool, busy: bool) -> void:
	get_node(^"Layout/Title").text = sdk.translations.text(title)
	_primary.text = sdk.translations.text("Waiting…" if busy else _panel.primary_text())
	_primary.disabled = busy or not can_submit
	get_node(^"Layout/Actions/Close").text = sdk.translations.text("Close" if _panel.primary_text() == "Done" else "Cancel")

func _submit() -> void:
	await _panel.submit()

func _navigate(_route: String, _item: String) -> void:
	_close()

func _close() -> void:
	if sdk != null:
		var surface := SDK.ExtensionSurface.new()
		surface.scene = load(ROOT + "ui/hud_recovery_window.tscn")
		sdk.windows.close(surface)

func _closed() -> void:
	_panel.close_action()
