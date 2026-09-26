extends "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/sdk/window.gd"

const I18N = preload("res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/ui/localization.gd")
var i18n := I18N.new()
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const RULES = preload(ROOT + "logic/encounter_authority.gd")
const VIEW = preload(ROOT + "ui/encounter_view.gd")
const LOCAL_STATE = preload(ROOT + "ui/encounter_local.gd")
var _local: LOCAL_STATE
var _state: Dictionary = {}
var _selected: Dictionary = {}
var _roll_id := ""
var _pending_rook := ""
var _tabletop_rook := ""
var _busy := false
var _closed := false
@onready var _outcome: Label = get_node(^"Layout/Body/Content/Outcome")
@onready var _primary_button: Button = get_node(^"Layout/Footer/TrailingSlot/Navigation/Primary")
@onready var _previous_button: Button = get_node(^"Layout/Footer/TrailingSlot/Navigation/Previous")

func ready() -> void:
	i18n.bind(sdk)
	localize(i18n)
	if sdk == null:
		return
	_local = VIEW.new().local_state(self)
	sdk.windows.set_title("Encounter")
	closed.connect(_on_closed)
	visibility_changed.connect(_visibility_changed)
	sdk.world_changed.connect(refresh)
	var current := sdk.rooks.selected()
	_tabletop_rook = "" if current == null else current.value
	sdk.rooks.selection_changed.connect(_tabletop_selection)
	_local.updated.connect(refresh)
	item_rect_changed.connect(_bounds_changed)
	_local.panel_changed(is_visible_in_tree())
	(get_node(^"Layout/Body/Content/Sides/Players") as Button).pressed.connect(_side.bind("pc"))
	(get_node(^"Layout/Body/Content/Sides/Monsters") as Button).pressed.connect(_side.bind("enemy"))
	(get_node(^"Layout/Body/Content/Sides/Roll") as Button).pressed.connect(_roll.bind("group"))
	(get_node(^"Layout/Body/Content/Selected/Actions/Reaction") as Button).pressed.connect(_roll.bind("reaction"))
	(get_node(^"Layout/Body/Content/Selected/Actions/Morale") as Button).pressed.connect(_roll.bind("morale"))
	(get_node(^"Layout/Body/Content/Options/Round/Set") as Button).pressed.connect(_correct)
	(get_node(^"Layout/Body/Content/Options/Round/Value") as LineEdit).gui_input.connect(_options_input)
	(get_node(^"Layout/Body/Content/Options/End") as Button).pressed.connect(_edit.bind({"kind": "end"}))
	_previous_button.pressed.connect(_edit.bind({"kind": "previous"}))
	_primary_button.pressed.connect(_primary)
	get_node(^"Poll").timeout.connect(_poll)
	refresh()

func refresh() -> void:
	if sdk == null or _closed:
		return
	var snapshot: Dictionary = VIEW.new().snapshot(sdk)
	var task_state = get_node(^"Layout/TaskState")
	task_state.visible = snapshot.has("error")
	get_node(^"Layout/Body").visible = not snapshot.has("error")
	get_node(^"Layout/Footer").visible = not snapshot.has("error")
	if snapshot.has("error"):
		task_state.state = 3
		task_state.title = _t("Encounter unavailable")
		task_state.description = str(snapshot.error)
		return
	_state = snapshot
	var rows: Array = _state.rows
	var pending := _busy or not _roll_id.is_empty()
	var empty_label := get_node(^"Layout/Body/Content/Empty") as Label
	empty_label.visible = rows.is_empty()
	(get_node(^"Layout/Body/Content/Sides") as Control).visible = not rows.is_empty()
	(get_node(^"Layout/Body/Content/Sides/Players") as Button).set_pressed_no_signal(_state.active and _state.current == "pc")
	(get_node(^"Layout/Body/Content/Sides/Monsters") as Button).set_pressed_no_signal(_state.active and str(_state.current) in ["enemy", "first"])
	for name in ["Players", "Monsters", "Roll"]:
		(get_node("Layout/Body/Content/Sides/" + name) as Button).disabled = pending or not _state.is_gm
	_selected = {}
	for raw in rows:
		var row: Dictionary = raw
		if row.rook == (_pending_rook if not _roll_id.is_empty() else _local.selected_rook):
			_selected = row
	if _selected.is_empty() and not rows.is_empty():
		_selected = rows[0]
	(get_node(^"Layout/Body/Content/Selected") as Control).visible = not _selected.is_empty()
	if not _selected.is_empty():
		(get_node(^"Layout/Body/Content/Selected/Identity/Name") as Label).text = str(_selected.label)
		(get_node(^"Layout/Body/Content/Selected/Identity/Kind") as Label).text = str(_selected.kind)
		(get_node(^"Layout/Body/Content/Selected/Identity/Kind") as Label).visible = not str(_selected.kind).is_empty()
		VIEW.new().show_preview(sdk, get_node(^"Layout/Body/Content/Selected/Preview"), _selected)
		(get_node(^"Layout/Body/Content/Selected/Actions") as Control).visible = _state.is_gm and _selected.side == "enemy"
		for name in ["Reaction", "Morale"]:
			(get_node("Layout/Body/Content/Selected/Actions/" + name) as Button).disabled = pending or not _selected.available
	var options := get_node(^"Layout/Body/Content/Options") as Control
	var opening := _local.options and not options.visible
	options.visible = _local.options and _state.is_gm and _state.active
	var round_value := get_node(^"Layout/Body/Content/Options/Round/Value") as LineEdit
	if not round_value.has_focus():
		round_value.text = str(maxi(1, int(_state.round)))
	if opening and options.visible:
		_focus_round()
	get_node(^"Layout/Footer").visible = bool(_state.is_gm)
	_primary_button.text = _t("Next") if _state.active else _t("Begin")
	_primary_button.disabled = pending or rows.is_empty()
	_previous_button.disabled = pending or not _state.active or (_state.round == 1 and _state.current == RULES.new().phases(_state)[0])
	(get_node(^"Layout/Body/Content/Options/Round/Set") as Button).disabled = pending
	(get_node(^"Layout/Body/Content/Options/End") as Button).disabled = pending

func _primary() -> void:
	if _state.active:
		await _edit({"kind": "next"})
	else:
		await _roll("group")

func _side(side: String) -> void:
	await _edit({"kind": "correct", "round": maxi(1, int(_state.round)), "current": side})

func _correct() -> void:
	var value := str((get_node(^"Layout/Body/Content/Options/Round/Value") as LineEdit).text)
	if not value.is_valid_int():
		_show_outcome("Enter a round number.", "error")
		_focus_round()
		return
	await _edit({"kind": "correct", "round": int(value), "current": str(_state.current)})
	if _outcome.visible:
		_focus_round()

func _focus_round() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if _closed or not _local.options or not is_visible_in_tree():
		return
	var value := get_node(^"Layout/Body/Content/Options/Round/Value") as LineEdit
	value.grab_focus()
	(get_node(^"Layout/Body") as ScrollContainer).ensure_control_visible(value)

func _edit(input: Dictionary) -> void:
	if _busy or _closed or not _roll_id.is_empty():
		return
	_busy = true
	var request := input.duplicate(true)
	request["revision"] = int(_state.get("revision", 0))
	refresh()
	var result := await sdk.system_actions.submit("encounter.edit", request)
	_busy = false
	if _closed:
		return
	if not result.ok or str(result.value.get("state", "error")) == "error":
		_show_outcome(result.message if not result.ok else str(result.value.message), "error")
	else:
		_outcome.visible = false
		if str(request.kind) == "end":
			_local.hide_options()
	refresh()

func _roll(kind: String) -> void:
	if _busy or not _roll_id.is_empty() or _closed:
		return
	_busy = true
	_pending_rook = str(_selected.get("rook", ""))
	_roll_id = sdk.dice.new_request_id()
	refresh()
	var result := await sdk.system_actions.submit("encounter.roll", {"id": _roll_id, "revision": int(_state.revision), "kind": kind, "actor": str(_selected.get("actor", ""))})
	_busy = false
	await _accept(result)
	if _closed:
		await _cancel()

func _poll() -> void:
	if _busy or _roll_id.is_empty() or _closed:
		return
	_busy = true
	var result := await sdk.system_actions.submit("encounter.advance", {"id": _roll_id})
	_busy = false
	await _accept(result)

func _accept(result: SDK.DataResult) -> void:
	if not result.ok:
		await _cancel()
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
	_local.panel_changed(false)
	await _cancel()

func _cancel() -> void:
	if not _roll_id.is_empty():
		await sdk.system_actions.submit("encounter.cancel", {"id": _roll_id})
		_roll_id = ""
		_show_outcome("Throw ended.", "ended")

func _visibility_changed() -> void:
	_local.panel_changed(is_visible_in_tree())
	if is_visible_in_tree():
		sdk.windows.set_title("Encounter")
		_closed = false
		refresh()

func _tabletop_selection() -> void:
	var current := sdk.rooks.selected()
	var id := "" if current == null else current.value
	var changed := id != _tabletop_rook
	_tabletop_rook = id
	if changed and not id.is_empty() and is_visible_in_tree():
		sdk.windows.close(VIEW.new().surface(sdk))

func _show_outcome(message: String, state: String) -> void:
	_outcome.text = _t(message)
	_outcome.visible = not message.is_empty()
	_outcome.theme_type_variation = "RookframeError" if state == "error" else "RookframePending" if state == "pending" else "RookframeStatus"

func _options_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		(get_node(^"Layout/Body/Content/Options/Round/Value") as LineEdit).accept_event()
		_local.hide_options()
		refresh()
		_primary_button.grab_focus()

func _process(_delta: float) -> void:
	if is_visible_in_tree():
		_bounds_changed()

func _bounds_changed() -> void:
	if is_visible_in_tree():
		_local.panel_bounds(get_global_rect())


func _t(source: String) -> String:
	return i18n.text(source)


var _localized := false

func localize(locale: I18N) -> void:
	if _localized:
		return
	_localized = true
	i18n = locale
	get_node(^"Layout/Body/Content/Empty").text = _t("Select a Rook and tap swords to add it.")
	get_node(^"Layout/Body/Content/Options/End").text = _t("End encounter")
	get_node(^"Layout/Body/Content/Options/Round/Label").text = _t("Round")
	get_node(^"Layout/Body/Content/Options/Round/Set").text = _t("Set")
	get_node(^"Layout/Body/Content/Options/Round/Value").accessibility_name = _t("Round")
	get_node(^"Layout/Body/Content/Selected/Actions/Morale").text = _t("Morale")
	get_node(^"Layout/Body/Content/Selected/Actions/Reaction").text = _t("Reaction")
	get_node(^"Layout/Body/Content/Sides/Monsters").text = _t("Monsters")
	get_node(^"Layout/Body/Content/Sides/Players").text = _t("Players")
	get_node(^"Layout/Body/Content/Sides/Roll").accessibility_name = _t("Roll initiative")
	get_node(^"Layout/Body/Content/Sides/Roll").tooltip_text = _t("Roll initiative")
