extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

## This task captures its Actor and exact scroll once. HUD selection is unrelated.
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const FAVORITES = preload(ROOT + "logic/actor_favorites.gd")
var _actor: SDK.ActorId
var _opened := false
@onready var _panel = get_node("Layout/Body/Panel")
@onready var _primary: Button = get_node("Layout/Actions/Primary")

func ready() -> void:
	get_node("Layout/Actions/Close").pressed.connect(_close)
	_primary.pressed.connect(_submit)
	_panel.action_created.connect(_action_created)
	_panel.navigate_requested.connect(_navigate)
	_panel.workflow_changed.connect(_workflow_changed)
	closed.connect(_closed)
	if sdk != null:
		get_node("Layout/Actions/Close").text = sdk.translations.text("Cancel")

func opened_task(actor: SDK.ActorId, task: Dictionary) -> void:
	if _opened or sdk == null:
		return
	_opened = true
	_actor = actor
	var current := sdk.actors.read(actor)
	if not current.ok or current.actor.access_level != "Owner":
		_close()
		return
	get_node("Layout/Actor").text = str(current.actor.data.get("name", "Character"))
	if task.get("daily", false):
		_panel.configure_morning(current.actor, sdk)
		return
	var source := FAVORITES.new().find(current.actor.data, actor.value, [], str(task.get("key", "")))
	if source.is_empty() or source.category != "Powers" or str(source.item) != str(task.get("item", "")) or str(source.source) != str(task.get("source", "")) or not source.available:
		_close()
		return
	_panel.configure_tabletop(current.actor, sdk, str(source.item), str(task.get("rook", "")))

func _action_created(action: Node) -> void:
	add_child(action)

func _workflow_changed(_route: String, title: String, can_submit: bool, busy: bool) -> void:
	get_node("Layout/Title").text = sdk.translations.text(title)
	_primary.text = sdk.translations.text("Waiting…" if busy else _panel.primary_text())
	_primary.disabled = busy or not can_submit
	get_node("Layout/Actions/Close").text = sdk.translations.text("Close" if _panel.primary_text() == "Done" else "Cancel")

func _submit() -> void:
	await _panel.submit()

func _navigate(_route: String, _item: String) -> void:
	_close()

func _close() -> void:
	if sdk != null:
		var surface := SDK.ExtensionSurface.new()
		surface.scene = load(ROOT + "ui/hud_power_window.tscn")
		sdk.windows.close(surface)

func _closed() -> void:
	_panel.close_action()
