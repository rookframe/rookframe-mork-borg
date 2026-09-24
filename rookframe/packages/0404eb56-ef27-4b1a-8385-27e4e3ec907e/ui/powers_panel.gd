extends VBoxContainer
const ROOT := "res://rookframe/packages/0404eb56-ef27-4b1a-8385-27e4e3ec907e/"
const SDK = preload(ROOT + "sdk/package_sdk_facade.gd")
const POWERS = preload(ROOT + "logic/powers.gd")
const ITEMS = preload(ROOT + "logic/character_actions.gd")
const ACTION = preload(ROOT + "logic/power_action.gd")
const ROW = preload(ROOT + "ui/power_row.tscn")
const TARGETS = preload(ROOT + "ui/attack_targets.gd")
signal action_created(action: ACTION)
signal navigate_requested(route: String, item: String)
signal workflow_changed(route: String, title: String, can_submit: bool, busy: bool)
var _sdk: SDK
var _actor: SDK.Actor
var _item := ""
var _power: Dictionary = {}
var _action: ACTION
var _source_rook: SDK.RookId
var _target_pending := false
var _target_reading := false
var _update_pending := false

func _ready() -> void:
	resized.connect(_layout)
	get_node(^"Browse/Back").pressed.connect(_back)
	get_node(^"Daily/Roll").pressed.connect(_daily)
	get_node(^"Cast/Columns/Targets/Content/Change").pressed.connect(_choose_targets)

func configure(actor: SDK.Actor, facade: SDK, item: String) -> void:
	_actor = actor
	_sdk = facade
	_item = item
	if not _sdk.targeting.changed.is_connected(_targets_changed):
		_sdk.targeting.changed.connect(_targets_changed)
	if not _sdk.world_changed.is_connected(_world_changed):
		_sdk.world_changed.connect(_world_changed)
	var data: Dictionary = actor.data
	var inventory := ITEMS.new(_sdk, actor.id).inventory(data)
	_power = {}
	for raw in inventory:
		var entry: Dictionary = raw
		if str(entry.inventory_id) == item:
			_power = POWERS.new().definition(str(entry.get("source_item_id", "")))
	if _source_rook == null:
		_source_rook = _sdk.rooks.selected()
	if item.is_empty():
		_list(inventory)
	_target_pending = true
	_render()

func _list(items: Array) -> void:
	var list := get_node(^"Scrolls")
	for child in list.get_children():
		list.remove_child(child)
		child.queue_free()
	for raw in items:
		var item: Dictionary = raw
		var power := POWERS.new().definition(str(item.get("source_item_id", "")))
		var quantity: int = item.get("quantity", 0)
		if power.is_empty() or quantity < 1:
			continue
		var row := ROW.instantiate()
		list.add_child(row)
		(row.get_node(^"Copy/Name") as Label).text = str(power.name)
		(row.get_node(^"Copy/Rules") as Label).text = str(power.rules)
		(row.get_node(^"Copy/Handling") as Label).text = str(power.handling) if power.playable else "Not playable yet · " + str(power.handling)
		(row.get_node(^"Cast") as Button).disabled = _actor.access_level != "Owner" or not power.playable or (_action != null and _action.pending)
		(row.get_node(^"Cast") as Button).pressed.connect(_open_cast.bind(str(item.inventory_id)))
	get_node(^"Empty").visible = list.get_child_count() == 0

func _render() -> void:
	var data: Dictionary = _actor.data
	var state := _action.state if _action != null else "ready"
	var casting := not _item.is_empty()
	var terminal := casting and state in ["resolved", "ended"]
	get_node(^"Browse").visible = not casting
	get_node(^"Scrolls").visible = not casting
	get_node(^"Daily").visible = not casting
	get_node(^"Daily/Roll").disabled = _actor.access_level != "Owner" or (_action != null and _action.pending)
	get_node(^"Metrics").visible = not terminal
	get_node(^"Cast").visible = casting and not terminal
	get_node(^"Empty").visible = not casting and get_node(^"Scrolls").get_child_count() == 0
	var abilities: Dictionary = data.get("abilities", {})
	var ability: Dictionary = abilities.get("Presence", {})
	var presence: int = ability.get("modifier", 0)
	get_node(^"Metrics/Uses/Content/Value").text = str(data.get("power_uses", 0))
	get_node(^"Metrics/Presence/Content/Value").text = "%+d" % presence
	get_node(^"Metrics/Difficulty/Content/Value").text = "DR10" if str(data.get("class_id", "")) == "gutterborn-scum" else "DR12"
	get_node(^"Cast/Columns/Power/Content/Copy").text = str(_power.get("rules", "This scroll is unavailable."))
	var mode := str(_power.get("target_mode", ""))
	var reach: int = _power.get("range_feet", 0)
	get_node(^"Cast/Columns/Power/Content/Range").text = "Area · 30 ft" if mode == "area" else ("Self" if mode == "self" else "Range · %d ft" % reach)
	get_node(^"Cast/Columns/Targets").visible = mode != "self"
	get_node(^"Cast/Columns/Targets/Content/Change").disabled = state == "pending"
	get_node(^"Cast/Options").visible = state in ["ready", "error"]
	if _action != null:
		var text := _action.message
		if state == "resolved":
			text = "Power %s: GM determines the outcome. The casting workflow has ended. See the Action Log; use ordinary dice and sheet edits." % ("critical" if text.contains("Power critical:") else "fumble") if text.contains("GM determines the outcome") else "Resolved. See the Action Log for rolled quantities and manual handling."
		_status(text, state == "error")
	var title := str(_power.get("name", "Cast a Power")) if casting else "Powers & scrolls"
	if terminal:
		title = "Action ended" if state == "ended" else ("GM judgment required" if _action.message.contains("GM determines the outcome") else "Power resolved")
	workflow_changed.emit("cast" if casting else "powers", title, casting and state in ["ready", "error", "targets"] and _actor.access_level == "Owner" and _power.get("playable", false), state == "pending")
	_layout()

func submit() -> void:
	if _action != null and _action.state == "targets":
		await _action.confirm_targets()
		return
	if _action != null and _action.pending:
		return
	var text: String = get_node(^"Cast/Options/Modifier").value.strip_edges()
	if not text.is_valid_int():
		_status("Enter a whole-number situational modifier.", true)
		return
	var input := {"source": _actor.id.value, "rook": _source_rook.value if _source_rook != null else "", "item": _item, "eligible": get_node(^"Cast/Options/Eligible").button_pressed, "modifier": int(text)}
	_new_action()
	await _action.start(input)

func primary_text() -> String:
	return "Confirm targets" if _action != null and _action.state == "targets" else "Roll casting test"

func _daily() -> void:
	if _action != null and _action.pending:
		return
	_new_action()
	_action.daily = true
	await _action.start({"source": _actor.id.value, "morning_confirmed": true})

func _new_action() -> void:
	if _action != null:
		_action.retire()
	var action := ACTION.new(_sdk)
	action_created.emit(action)
	_action = action
	_action.changed.connect(_changed)

func _changed() -> void:
	_update_pending = true

func _world_changed() -> void:
	_update_pending = true

func _process(_delta: float) -> void:
	if _update_pending:
		_update_pending = false
		var latest := _sdk.actors.read(_actor.id)
		if latest.ok:
			_actor = latest.actor
		if _item.is_empty():
			_list(ITEMS.new(_sdk, _actor.id).inventory(_actor.data))
		_render()
	if _target_pending and not _target_reading and not _power.is_empty():
		_target_pending = false
		_target_reading = true
		var reach: float = _power.get("area_feet", _power.get("range_feet", 0))
		var summary := await TARGETS.new().describe(_sdk, _source_rook, reach)
		_target_reading = false
		if is_inside_tree():
			get_node(^"Cast/Columns/Targets/Content/Copy").text = summary

func _choose_targets() -> void:
	var result := _sdk.targeting.choose()
	if not result.ok:
		_status(result.message, true)

func _targets_changed(_snapshot: SDK.TargetSnapshot) -> void:
	_target_pending = true

func _open_cast(item: String) -> void:
	navigate_requested.emit("cast", item)

func _back() -> void:
	navigate_requested.emit("character", "")

func close_action() -> void:
	if _action != null:
		_action.cancel()

func _exit_tree() -> void:
	close_action()

func _status(text: String, error: bool = false) -> void:
	get_node(^"Outcome").text = text
	get_node(^"Outcome").visible = not text.is_empty()
	get_node(^"Outcome").theme_type_variation = "RookframeError" if error else "RookframeMeta"

func _layout() -> void:
	get_node(^"Cast/Columns").vertical = size.x < 600
