extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const VIEW = preload(ROOT + "ui/encounter_view.gd")
const ROW = preload(ROOT + "ui/encounter_row.tscn")
var _state: Dictionary = {}
var _selected := ""
var _roll_id := ""
var _busy := false
var _closed := false
var _actor_ids: Array[String] = []
@onready var _body: VBoxContainer = get_node(^"Layout/Body/Content")
@onready var _details: VBoxContainer = get_node(^"Layout/Body/Content/Selected")
@onready var _outcome: Label = get_node(^"Layout/Outcome")

func ready() -> void:
	if sdk == null:
		return
	closed.connect(_on_closed)
	visibility_changed.connect(_visibility_changed)
	sdk.world_changed.connect(refresh)
	get_node(^"Layout/Body/Content/Tools/Mode").item_selected.connect(_mode)
	get_node(^"Layout/Body/Content/Tools/RollGroup").pressed.connect(_roll.bind("group"))
	get_node(^"Layout/Body/Content/Add/Row/Add").pressed.connect(_add)
	get_node(^"Layout/Body/Content/Selected/Actions/Individual").pressed.connect(_roll.bind("individual"))
	get_node(^"Layout/Body/Content/Selected/Actions/Reaction").pressed.connect(_roll.bind("reaction"))
	get_node(^"Layout/Body/Content/Selected/Actions/Morale").pressed.connect(_roll.bind("morale"))
	get_node(^"Layout/Body/Content/Selected/Score/Save").pressed.connect(_score)
	get_node(^"Layout/Body/Content/Selected/Round/Set").pressed.connect(_correct)
	get_node(^"Layout/Body/Content/Selected/Position/Up").pressed.connect(_move.bind(-1))
	get_node(^"Layout/Body/Content/Selected/Position/Down").pressed.connect(_move.bind(1))
	get_node(^"Layout/Body/Content/Selected/Position/Remove").pressed.connect(_remove)
	get_node(^"Layout/Footer/Previous").pressed.connect(_previous)
	get_node(^"Layout/Footer/Primary").pressed.connect(_primary)
	get_node(^"Layout/Footer/End").pressed.connect(_end)
	var timer := Timer.new()
	timer.wait_time = 0.5
	timer.timeout.connect(_poll)
	timer.autostart = true
	add_child(timer)
	refresh()

func refresh() -> void:
	if sdk == null or _closed:
		return
	var snapshot: Dictionary = VIEW.new().snapshot(sdk)
	if snapshot.has("error"):
		_show_outcome(str(snapshot.error), "error")
		return
	_state = snapshot
	var gm: bool = _state.is_gm
	var rows: Array = _state.rows
	get_node(^"Layout/Heading").text = "ROUND %d" % int(_state.round) if _state.active else "ENCOUNTER"
	for control in [get_node(^"Layout/Body/Content/Tools"), get_node(^"Layout/Body/Content/Add"), get_node(^"Layout/Body/Content/Rules")]:
		control.visible = gm
	get_node(^"Layout/Footer").visible = gm
	get_node(^"Layout/Body/Content/Empty").visible = rows.is_empty()
	get_node(^"Layout/Body/Content/Tools/Mode").select(0 if _state.mode == "group" else 1)
	get_node(^"Layout/Body/Content/Tools/RollGroup").disabled = _busy or not _roll_id.is_empty() or rows.is_empty()
	get_node(^"Layout/Body/Content/Tools/RollGroup").visible = _state.mode == "group"
	var roster := get_node(^"Layout/Body/Content/Roster")
	for child in roster.get_children():
		roster.remove_child(child)
		child.queue_free()
	for raw_row in rows:
		var row: Dictionary = raw_row
		var preview: Texture2D = row.preview
		var label: String = row.label
		var button: Button = ROW.instantiate()
		roster.add_child(button)
		(button.get_node("Layout/Preview") as TextureRect).texture = preview
		(button.get_node("Layout/Name") as Label).text = label
		(button.get_node("Layout/Score") as Label).text = ("CURRENT · " if row.active else "") + ("—" if row.initiative == null else str(row.initiative))
		button.name = str(row.actor)
		button.accessibility_name = label + (", current turn" if row.active else "")
		button.tooltip_text = label
		button.set_pressed_no_signal(row.actor == _selected)
		button.pressed.connect(_select.bind(str(row.actor)))
	_show_selection()
	get_node(^"Layout/Footer/Primary").text = "Waiting…" if not _roll_id.is_empty() else "Next turn" if _state.active else "Begin"
	get_node(^"Layout/Footer/Primary").disabled = _busy or not _roll_id.is_empty() or rows.is_empty()
	get_node(^"Layout/Footer/Previous").disabled = _busy or not _state.active
	get_node(^"Layout/Footer/End").disabled = _busy or not _state.active
	if gm:
		_refresh_choices()

func _refresh_choices() -> void:
	var list := sdk.actors.list()
	if not list.ok:
		return
	var choice: OptionButton = get_node(^"Layout/Body/Content/Add/Actor")
	var previous := _actor_ids[choice.selected] if choice.selected >= 0 and choice.selected < _actor_ids.size() else ""
	choice.clear()
	_actor_ids.clear()
	var rows: Array = _state.rows
	for actor in list.items:
		var included := false
		for raw_entry in rows:
			var entry: Dictionary = raw_entry
			included = included or entry.actor == actor.id.value
		if included:
			continue
		_actor_ids.append(actor.id.value)
		var data: Dictionary = actor.data
		choice.add_item(str(data.get("name", "Actor")))
		if actor.id.value == previous:
			choice.select(_actor_ids.size() - 1)
	get_node(^"Layout/Body/Content/Add/Row/Add").disabled = _busy or _actor_ids.is_empty()

func _select(actor: String) -> void:
	_selected = actor
	_show_selection()
	get_node(^"Layout/Body/Content/Selected/Score/Value").text = ""
	get_node(^"Layout/Body/Content/Selected/Round/Value").text = str(maxi(1, int(_state.round)))
	get_node(^"Layout/Body/Content/Selected/Actions/Individual").grab_focus()

func _add() -> void:
	var choice: OptionButton = get_node(^"Layout/Body/Content/Add/Actor")
	if choice.selected < 0 or choice.selected >= _actor_ids.size():
		return
	_selected = _actor_ids[choice.selected]
	await _edit({"kind": "add", "actor": _selected, "side": "pc" if get_node(^"Layout/Body/Content/Add/Row/Side").selected == 0 else "enemy"})

func _score() -> void:
	var value := str(get_node(^"Layout/Body/Content/Selected/Score/Value").text)
	if not value.is_valid_int():
		_show_outcome("Enter a whole initiative score.", "error")
		return
	await _edit({"kind": "initiative", "actor": _selected, "value": int(value)})

func _correct() -> void:
	var value := str(get_node(^"Layout/Body/Content/Selected/Round/Value").text)
	if not value.is_valid_int():
		_show_outcome("Enter a round number.", "error")
		return
	await _edit({"kind": "correct", "round": int(value), "current": _selected})

func _primary() -> void:
	await _edit({"kind": "next" if _state.active else "begin"})

func _edit(input: Dictionary) -> void:
	if _busy or _closed:
		return
	_busy = true
	input["revision"] = int(_state.get("revision", 0))
	refresh()
	var result := await sdk.system_actions.submit("encounter.edit", input)
	_busy = false
	if _closed:
		return
	_show_result(result)
	refresh()

func _roll(kind: String) -> void:
	if _busy or not _roll_id.is_empty() or _closed:
		return
	_busy = true
	_roll_id = sdk.dice.new_request_id()
	refresh()
	var result := await sdk.system_actions.submit("encounter.roll", {"id": _roll_id, "revision": int(_state.revision), "kind": kind, "actor": _selected})
	_busy = false
	_accept(result)
	if _closed:
		await _cancel()

func _poll() -> void:
	if _busy or _roll_id.is_empty() or _closed:
		return
	_busy = true
	var result := await sdk.system_actions.submit("encounter.advance", {"id": _roll_id})
	_busy = false
	_accept(result)

func _accept(result: SDK.DataResult) -> void:
	if not result.ok:
		if not _closed:
			_show_outcome(result.message, "error")
		return
	var value: Dictionary = result.value
	if str(value.get("state", "error")) != "pending":
		_roll_id = ""
	if not _closed:
		_show_outcome(str(value.get("message", "")), str(value.get("state", "error")))
		refresh()

func _on_closed() -> void:
	_closed = true
	await _cancel()

func _cancel() -> void:
	if not _roll_id.is_empty():
		await sdk.system_actions.submit("encounter.cancel", {"id": _roll_id})
		_roll_id = ""

func _mode(index: int) -> void:
	await _edit({"kind": "mode", "mode": "group" if index == 0 else "individual"})

func _move(direction: int) -> void:
	await _edit({"kind": "move", "actor": _selected, "direction": direction})

func _remove() -> void:
	await _edit({"kind": "remove", "actor": _selected})

func _previous() -> void:
	await _edit({"kind": "previous"})

func _end() -> void:
	await _edit({"kind": "end"})

func _visibility_changed() -> void:
	if is_visible_in_tree():
		_closed = false
		refresh()

func _show_selection() -> void:
	var rows: Array = _state.get("rows", [])
	var selected: Dictionary = {}
	for raw in rows:
		var row: Dictionary = raw
		if row.actor == _selected:
			selected = row
	for child in get_node(^"Layout/Body/Content/Roster").get_children():
		var button := child as Button
		button.set_pressed_no_signal(str(button.name) == _selected)
	_details.visible = bool(_state.get("is_gm", false)) and not selected.is_empty()
	if not selected.is_empty():
		get_node(^"Layout/Body/Content/Selected/Name").text = str(selected.label)

func _show_outcome(message: String, state: String) -> void:
	_outcome.text = message
	_outcome.theme_type_variation = "RookframeError" if state == "error" else "RookframePending" if state == "pending" else "RookframeSuccess" if state == "resolved" else "RookframeStatus"

func _show_result(result: SDK.DataResult) -> void:
	if result.ok:
		_show_outcome(str(result.value.get("message", "")), str(result.value.get("state", "error")))
	else:
		_show_outcome(result.message, "error")
