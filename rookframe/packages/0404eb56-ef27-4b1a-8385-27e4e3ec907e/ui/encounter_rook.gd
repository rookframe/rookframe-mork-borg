extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const LOCAL = preload(ROOT + "ui/encounter_local.tres")
var _busy := false

func ready() -> void:
	if sdk == null:
		return
	sdk.world_changed.connect(refresh)
	sdk.rooks.selection_changed.connect(refresh)
	get_node(^"Toggle").pressed.connect(_toggle)
	refresh()

func refresh() -> void:
	var selected := sdk.rooks.selected()
	visible = sdk.context().is_gm and selected != null
	if not visible:
		return
	var rook := sdk.rooks.read(selected)
	visible = rook.ok
	if not visible:
		return
	var result := sdk.world_data.read()
	var world: Dictionary = result.value if result.ok and result.value != null else {}
	var encounter: Dictionary = world.get("encounter", {})
	var entries: Array = encounter.get("entries", [])
	var included := false
	for raw in entries:
		var entry: Dictionary = raw
		included = included or str(entry.rook) == selected.value
	var button: Button = get_node(^"Toggle")
	button.set_pressed_no_signal(included)
	visible = included or rook.rook.actor != null
	button.disabled = _busy or not result.ok
	button.tooltip_text = "Remove from combat" if included else "Add to combat"
	button.accessibility_name = button.tooltip_text
	get_node(^"Check").visible = included

func _toggle() -> void:
	if _busy:
		return
	var selected := sdk.rooks.selected()
	var saved := sdk.world_data.read()
	if selected == null or not saved.ok:
		return
	var world: Dictionary = {} if saved.value == null else saved.value
	var encounter: Dictionary = world.get("encounter", {"revision": 0, "entries": []})
	var included := false
	for raw in encounter.entries:
		var entry: Dictionary = raw
		included = included or str(entry.rook) == selected.value
	_busy = true
	refresh()
	var result := await sdk.system_actions.submit("encounter.edit", {"revision": int(encounter.revision), "kind": "remove" if included else "add", "rook": selected.value})
	_busy = false
	if not result.ok or str(result.value.get("state", "error")) == "error":
		var message := SDK.FeedbackMessage.new()
		message.title = "Encounter"
		message.message = result.message if not result.ok else str(result.value.message)
		sdk.feedback.error(message)
	else:
		LOCAL.select_rook(selected.value)
	refresh()
